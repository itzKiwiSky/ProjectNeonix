package editor;

import core.ActorManager;
import core.ActorManager.EventCategory;
import flixel.util.FlxSpriteUtil;
import core.Timeline.TimelineEvent;
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
    static inline var MAX_LANES:Int = 5; // (256 - 48) / 36
    
    var ticks:Array<FlxSprite> = [];
    var eventSprites:Array<EditorTimelineEvent> = [];
    
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
        var t = xToTime(mouseX);
        
        // de trás pra frente: o último da lista é o que está desenhado por cima
        var i = eventSprites.length - 1;
        while (i >= 0)
        {
            var s = eventSprites[i];
            var barY = this.y + LANES_TOP + s.lane * LANE_HEIGHT;
            
            var insideTime = t >= startOf(s.event) && t <= endOf(s.event);
            var insideLane = mouseY >= barY && mouseY <= barY + 32;
            
            if (insideTime && insideLane)
                return s.event;
                
            i--;
        }
        return null;
    }
    
    // recria todas as barras a partir de uma lista de eventos
    public function setEvents(events:Array<TimelineEvent>)
    {
        destroyEventSprites();
        
        for (e in events)
            addEvent(e, false);
            
        relayout();
    }
    
    public function addEvent(e:TimelineEvent, doLayout:Bool = true)
    {
        var s = new EditorTimelineEvent(e);
        s.setColors(colorFor(ActorManager.categoryOf(e.object)));
        s.addTo(this);
        
        // barras criadas depois do `cameras = [hudCam]` não herdam a câmera
        for (b in [s.warn, s.attack, s.outro])
            b.cameras = cameras;
            
        eventSprites.push(s);
        
        if (doLayout)
            relayout();
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
                s.setColors(colorFor(ActorManager.categoryOf(e.object)));
        relayout();
    }
    
    function destroyBars(s:EditorTimelineEvent)
    {
        for (b in [s.warn, s.attack, s.outro])
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
            case Obstacle: FlxColor.MAGENTA;
            case Map: 0xFF30C0FF;
        }
    }
    
    public function setSelected(e:Null<TimelineEvent>)
    {
        for (s in eventSprites)
            s.setSelected(s.event == e);
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
        
        var laneEnds:Array<Float> = []; // até quando cada linha está ocupada
        for (s in sorted)
        {
            var start = startOf(s.event);
            var lane = 0;
            while (lane < laneEnds.length && laneEnds[lane] > start)
                lane++;
                
            if (lane == laneEnds.length)
                laneEnds.push(endOf(s.event));
            else
                laneEnds[lane] = endOf(s.event);
                
            s.lane = Std.int(Math.min(lane, MAX_LANES - 1)); // passou de 5 linhas, as últimas se sobrepõem
        }
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
            var barY = this.y + LANES_TOP + s.lane * LANE_HEIGHT;
            
            placeBar(s.warn, e.time - lead, lead, barY);
            placeBar(s.attack, e.time, duration, barY, 6);
            placeBar(s.outro, e.time + duration, outro, barY);
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
