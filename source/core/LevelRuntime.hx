package core;

import core.managers.ActorManager;
import core.managers.EffectManager;
import flixel.FlxObject;
import core.managers.Timeline.TimelineEvent;
import core.level.Level.LevelData;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

class LevelRuntime
{
    // fallbacks para level antigo sem esses campos no meta
    public static final DEFAULT_BG:Array<Int> = [166, 80, 148];
    public static final DEFAULT_PLATFORM:Array<Int> = [255, 255, 255];
    public static final DEFAULT_ACTORS:Array<Int> = [255, 0, 129];
    
    public var data(default, null):LevelData;
    public var effects(default, null):EffectManager;
    public var active(default, null):FlxTypedGroup<LevelActor>; // só quem está dentro da janela de tempo
    public var actorsColor(default, null):FlxColor = FlxColor.WHITE; // a cor do momento, decidida pelo efeito
    
    var all:Array<LevelActor> = [];
    var timelineEvents:Array<TimelineEvent> = [];
    var nextTimelineEvent:Int = 0;
    var currentTime:Float = 0;
    var lastTimelineTime:Null<Float>;
    
    public function new(background:FlxSprite, platform:FlxSprite, camera:FlxCamera)
    {
        active = new FlxTypedGroup<LevelActor>();
        effects = EffectManager.createDefault(background, platform, camera, c -> actorsColor = c);
    }
    
    public function load(data:LevelData)
    {
        clear();
        this.data = data;
        
        for (a in ActorManager.createAll(data))
            all.push(a);
            
        applyMeta();
        eventsChanged();
    }
    
    // lê as cores iniciais do meta; o editor chama de novo quando você muda uma delas
    public function applyMeta()
    {
        var bg:Array<Int> = data.meta.backgroundColor ?? DEFAULT_BG;
        var plat:Array<Int> = data.meta.platformColor ?? DEFAULT_PLATFORM;
        var act:Array<Int> = data.meta.actorsColor ?? DEFAULT_ACTORS;
        effects.setBase("bg_color", [bg[0], bg[1], bg[2]]);
        effects.setBase("platform_color", [plat[0], plat[1], plat[2]]);
        effects.setBase("actors_color", [act[0], act[1], act[2]]);
    }
    
    public function clear()
    {
        active.clear();
        for (a in all)
            a.destroy();
        all = [];
        timelineEvents = [];
        nextTimelineEvent = 0;
        currentTime = 0;
        lastTimelineTime = null;
    }
    
    public function eventsChanged()
    {
        effects.rebuild(data.events);
        timelineEvents = [for (e in data.events) if (e.object == "send_event") e];
        timelineEvents.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
        resetAndReplayTimelineEvents(currentTime);
        lastTimelineTime = currentTime;
    }
        
    public function rebuildActor(e:TimelineEvent)
    {
        removeActorOf(e);
        var actor = ActorManager.createActor(e);
        if (actor != null)
            all.push(actor);
    }
    
    public function removeActorOf(e:TimelineEvent)
    {
        for (a in all)
        {
            if (a.event == e)
            {
                active.remove(a, true);
                all.remove(a);
                a.destroy();
                return;
            }
        }
    }
    
    public function update(now:Float)
    {
        if (data == null)
            return;

        if (lastTimelineTime == null || now < lastTimelineTime)
            resetAndReplayTimelineEvents(now);
        else
            dispatchTimelineEventsThrough(now);
        currentTime = now;
        lastTimelineTime = now;
            
        for (a in all)
        {
            if (a.isInside(now))
            {
                if (!active.members.contains(a))
                    active.add(a);
            }
            else if (active.members.contains(a))
            {
                active.remove(a);
                a.phase = null;
            }
        }
        
        effects.apply(now);
        
        // o grupo só repassa a cor aos sprites quando ela muda, então isso custa quase nada
        for (a in active)
            if (a.tintByActorsColor)
                a.color = actorsColor;
    }

    function resetAndReplayTimelineEvents(now:Float)
    {
        for (a in all)
            a.resetTimelineEvents();
        nextTimelineEvent = 0;
        dispatchTimelineEventsThrough(now);
    }

    function dispatchTimelineEventsThrough(now:Float)
    {
        while (nextTimelineEvent < timelineEvents.length && timelineEvents[nextTimelineEvent].time <= now)
        {
            dispatchTimelineEvent(timelineEvents[nextTimelineEvent]);
            nextTimelineEvent++;
        }
    }

    function dispatchTimelineEvent(source:TimelineEvent)
    {
        var name:Dynamic = source.params == null ? null : Reflect.field(source.params, "name");
        if (!Std.isOfType(name, String) || name == "")
            return;

        var target:Dynamic = source.params == null ? null : Reflect.field(source.params, "target");
        if (target != null && !Std.isOfType(target, String))
        {
            trace('Target inválido no evento de timeline "${name}".');
            return;
        }
        for (a in all)
        {
            if (Std.isOfType(target, String) && target != "" && a.event.id != target)
                continue;
            a.onTimelineEvent(name, source);
        }
    }
    
    public function collide(obj:FlxObject):Bool
    {
        var any:Bool = false;
        for (a in active)
            if (a.alive && a.collide(obj))
                any = true;
        return any;
    }
    
    public function hits(obj:FlxBasic):Bool
    {
        for (a in active)
            if (a.alive && a.hits(obj))
                return true;
        return false;
    }
}
