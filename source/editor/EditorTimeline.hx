package editor;

import core.managers.ActorManager;
import core.managers.ActorManager.EventCategory;
import flixel.util.FlxSpriteUtil;
import core.managers.Timeline.TimelineEvent;
import core.Conductor;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class EditorTimeline extends FlxTypedSpriteGroup<FlxSprite>
{
    public var pixelsPerMs:Float = 0.2;
    public var cursorMusicTime:Float = 0;
    
    static inline var MAX_TICKS:Int = 64;
    static inline var LANES_TOP:Float = 48; // onde começam as linhas, abaixo dos traços
    static inline var LANE_HEIGHT:Float = 36; // 32 da barra + 4 de espaço
    static inline var VISIBLE_LANES:Int = 5; // (256 - 48) / 36
    
    var ticks:Array<FlxSprite> = [];
    var eventSprites:Array<EditorTimelineEvent> = [];
    var laneOffset:Int = 0;
    
    public function new()
    {
        super();
        
        var bg:FlxSprite = new FlxSprite();
        bg.makeGraphic(FlxG.width, 256, 0xFF4C1A5A);
        FlxSpriteUtil.drawRect(bg, 0, 0, bg.width, 32, 0xFFA35CB7);
        bg.updateHitbox();
        add(bg);
        createTimelineTicks();
        y = FlxG.height - height;
        bg.alpha = 0.6;
        
        var cursor:EditorTimelineCursor = new EditorTimelineCursor();
        cursor.y -= 16;
        cursor.screenCenter(X);
        add(cursor);
    }
    
    public function destroyEventSprites()
    {
        for (s in eventSprites)
            destroyBars(s);
        eventSprites = [];
    }
    
    public function eventAt(mouseX:Float, mouseY:Float):Null<TimelineEvent>
    {
        var localY = mouseY - (this.y + LANES_TOP);
        var visibleLane = Math.floor(localY / LANE_HEIGHT);
        if (visibleLane < 0 || visibleLane >= VISIBLE_LANES)
            return null;
            
        var lane = laneOffset + Std.int(visibleLane);
        var t = xToTime(mouseX);
        
        // de trás pra frente: o último da lista é o que está desenhado por cima
        var i = eventSprites.length - 1;
        while (i >= 0)
        {
            var s = eventSprites[i];
            var barY = this.y + LANES_TOP + Std.int(visibleLane) * LANE_HEIGHT;
            
            var insideTime = t >= startOf(s.event) && t <= endOf(s.event);
            var insideLane = mouseY >= barY && mouseY <= barY + 32;
            
            if (s.lane == lane && insideTime && insideLane)
                return s.event;
                
            i--;
        }
        return null;
    }
    
    // recria todas as barras a partir de uma lista de eventos
    public function setEvents(events:Array<TimelineEvent>, ?laneOverrides:Array<Null<Int>>)
    {
        destroyEventSprites();
        laneOffset = 0;
        
        for (i in 0...events.length)
        {
            var lane:Null<Int> = laneOverrides != null && i < laneOverrides.length ? laneOverrides[i] : null;
            addEvent(events[i], false, lane);
        }
        
        relayout();
    }
    
    public function addEvent(e:TimelineEvent, doLayout:Bool = true, ?laneOverride:Null<Int>)
    {
        var s = new EditorTimelineEvent(e);
        if (laneOverride != null && laneOverride >= 0)
        {
            s.lane = laneOverride;
            s.laneIsManual = true;
        }
        s.setColors(colorFor(ActorManager.categoryOf(e.object)));
        s.addTo(this);
        
        // barras criadas depois do `cameras = [hudCam]` não herdam a câmera
        for (b in [s.warn, s.attack, s.outro, s.nameLabel])
            b.cameras = cameras;
            
        eventSprites.push(s);
        
        if (doLayout)
            relayout();
    }
    
    public function moveEventToLane(e:TimelineEvent, delta:Int)
    {
        if (delta == 0)
            return;
            
        for (s in eventSprites)
            if (s.event == e)
            {
                var newLane = Std.int(Math.max(0, s.lane + delta));
                if (newLane == s.lane)
                    return;
                    
                s.lane = newLane;
                s.laneIsManual = true;
                relayout();
                ensureLaneVisible(s.lane);
                return;
            }
    }
    
    public function scrollLanes(delta:Int)
        laneOffset = Std.int(Math.max(0, laneOffset + delta));
        
    public function getLaneOverrides():Array<Null<Int>>
        return [for (s in eventSprites) s.laneIsManual ? s.lane : null];
        
    function ensureLaneVisible(lane:Int)
    {
        if (lane < laneOffset)
            laneOffset = lane;
        else if (lane >= laneOffset + VISIBLE_LANES)
            laneOffset = lane - VISIBLE_LANES + 1;
    }
    
    public function removeEvent(e:TimelineEvent)
    {
        for (s in eventSprites)
        {
            if (s.event == e)
            {
                destroyBars(s);
                eventSprites.remove(s);
                relayout();
                return;
            }
        }
    }
    
    public function refreshEvent(e:TimelineEvent)
    {
        for (s in eventSprites)
            if (s.event == e)
            {
                s.setColors(colorFor(ActorManager.categoryOf(e.object)));
                s.refreshName();
            }
        relayout();
    }
    
    function destroyBars(s:EditorTimelineEvent)
    {
        for (b in [s.warn, s.attack, s.outro, s.nameLabel])
        {
            remove(b, true);
            b.destroy();
        }
    }
    
    function colorFor(c:Null<EventCategory>):FlxColor
    {
        if (c == null)
            return 0xFFF13131; // o jogo não reconhece esse object, tem algo errado no JSON
            
        return switch (c)
        {
            case Obstacle: 0xFFAF4FC9;
            case Map: 0xFF30C0FF;
        }
    }
    
    public function setSelected(events:Array<TimelineEvent>)
    {
        for (s in eventSprites)
            s.setSelected(events.indexOf(s.event) >= 0);
    }
    
    // distribui os eventos em linhas para que nenhum fique em cima de outro
    // chame de novo se algum evento mudar de tempo, lead, duration ou outro
    public function relayout()
    {
        var sorted = eventSprites.copy();
        sorted.sort((a, b) ->
        {
            var d = startOf(a.event) - startOf(b.event);
            return d < 0 ? -1 : (d > 0 ? 1 : 0);
        });
        
        var laneEvents:Map<Int, Array<EditorTimelineEvent>> = [];
        for (s in sorted)
            if (s.laneIsManual)
            {
                var events = laneEvents.get(s.lane);
                if (events == null)
                {
                    events = [];
                    laneEvents.set(s.lane, events);
                }
                events.push(s);
            }
            
        for (s in sorted)
        {
            if (s.laneIsManual)
                continue;
                
            var lane = 0;
            while (laneHasOverlap(laneEvents.get(lane), s))
                lane++;
                
            s.lane = lane;
            var events = laneEvents.get(lane);
            if (events == null)
            {
                events = [];
                laneEvents.set(lane, events);
            }
            events.push(s);
        }
    }
    
    function laneHasOverlap(events:Null<Array<EditorTimelineEvent>>, candidate:EditorTimelineEvent):Bool
    {
        if (events == null)
            return false;
            
        var start = startOf(candidate.event);
        var end = endOf(candidate.event);
        for (s in events)
            if (startOf(s.event) < end && endOf(s.event) > start)
                return true;
        return false;
    }
    
    inline function startOf(e:TimelineEvent):Float
        return e.time - (e.lead == null ? 0 : e.lead);
        
    inline function endOf(e:TimelineEvent):Float
        return e.time + param(e, "duration") + param(e, "outro");
        
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        updateTicks();
        updateEvents();
    }
    
    inline function createTimelineTicks():Void
        for (i in 0...MAX_TICKS)
        {
            var tick = new FlxSprite();
            tick.makeGraphic(3, 1, FlxColor.WHITE);
            tick.visible = false;
            tick.origin.set(1, 0);
            add(tick);
            ticks.push(tick);
        }
        
    function updateEvents()
    {
        for (s in eventSprites)
        {
            var e = s.event;
            var lead:Float = e.lead == null ? 0 : e.lead;
            var duration = param(e, "duration");
            var outro = param(e, "outro");
            var visibleLane = s.lane - laneOffset;
            if (visibleLane < 0 || visibleLane >= VISIBLE_LANES)
            {
                s.warn.visible = false;
                s.attack.visible = false;
                s.outro.visible = false;
                s.nameLabel.visible = false;
                continue;
            }
            
            var barY = this.y + LANES_TOP + visibleLane * LANE_HEIGHT;
            
            placeBar(s.warn, e.time - lead, lead, barY);
            placeBar(s.attack, e.time, duration, barY, 6);
            placeBar(s.outro, e.time + duration, outro, barY);
            
            var startX = timeToX(e.time - lead);
            var totalWidth = (lead + duration + outro) * pixelsPerMs;
            var labelFits = totalWidth >= s.naturalNameWidth;
            s.nameLabel.fieldWidth = labelFits ? s.naturalNameWidth : totalWidth;
            s.nameLabel.wordWrap = false;
            s.nameLabel.visible = totalWidth > 0 && startX + totalWidth >= 0 && startX <= FlxG.width;
            s.nameLabel.x = labelFits ? startX + (totalWidth - s.naturalNameWidth) * 0.5 : startX;
            s.nameLabel.y = barY + (32 - s.nameLabel.height) * 0.5;
        }
    }
    
    function placeBar(bar:FlxSprite, startMs:Float, lenMs:Float, barY:Float, minPx:Float = 0)
    {
        var x = timeToX(startMs);
        var w = Math.max(minPx, lenMs * pixelsPerMs);
        
        bar.visible = w > 0 && x + w >= 0 && x <= FlxG.width;
        bar.x = x;
        bar.y = barY;
        bar.scale.set(w, 1);
    }
    
    inline function param(e:TimelineEvent, name:String):Float
    {
        if (e.params == null)
            return 0;
        var v:Dynamic = Reflect.field(e.params, name);
        return v == null ? 0 : v;
    }
    
    function updateTicks():Void
    {
        var beatMs = Conductor.crochet;
        var firstBeat = Math.floor(xToTime(0) / beatMs);
        
        for (i in 0...ticks.length)
        {
            var beat = firstBeat + i;
            var tick = ticks[i];
            var x = timeToX(beat * beatMs);
            
            tick.visible = beat >= 0 && x >= -2 && x <= FlxG.width;
            tick.x = x - 1;
            tick.y = this.y;
            tick.setGraphicSize(3, (beat % 4 == 0) ? 32 : 16);
            tick.color = (beat % 4 == 0) ? FlxColor.CYAN : FlxColor.WHITE;
        }
    }
    
    public function timeToX(t:Float):Float
        return FlxG.width * 0.5 + (t - cursorMusicTime) * pixelsPerMs;
        
    public function xToTime(px:Float):Float
        return cursorMusicTime + (px - FlxG.width * 0.5) / pixelsPerMs;
}

class EditorTimelineCursor extends FlxSprite
{
    public function new()
    {
        super();
        makeGraphic(48, 256 + 48, FlxColor.TRANSPARENT);
        updateHitbox();
        FlxSpriteUtil.drawLine(this, width * 0.5, 48, width * 0.5, height, {
            thickness: 2,
            color: FlxColor.WHITE,
        });
        FlxSpriteUtil.drawCircle(this, width * 0.5, width * 0.5, width * 0.5, 0xFFDF66B6);
    }
}
