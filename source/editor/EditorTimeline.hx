package editor;

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
    
    // recria todas as barras a partir de uma lista de eventos
    public function setEvents(events:Array<TimelineEvent>)
    {
        for (s in eventSprites)
            destroyBars(s);
        eventSprites = [];
        
        for (e in events)
            addEvent(e);
    }
    
    public function addEvent(e:TimelineEvent)
    {
        var s = new EditorTimelineEvent(e);
        s.addTo(this);
        
        // barras criadas depois do `cameras = [hudCam]` não herdam a câmera
        for (b in [s.warn, s.attack, s.outro])
            b.cameras = cameras;
            
        eventSprites.push(s);
    }
    
    public function removeEvent(e:TimelineEvent)
    {
        for (s in eventSprites)
        {
            if (s.event == e)
            {
                destroyBars(s);
                eventSprites.remove(s);
                return;
            }
        }
    }
    
    function destroyBars(s:EditorTimelineEvent)
    {
        for (b in [s.warn, s.attack, s.outro])
        {
            remove(b, true);
            b.destroy();
        }
    }
    
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
            tick.makeGraphic(2, 1, FlxColor.WHITE);
            tick.visible = false;
            tick.origin.set(0, 0);
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
            
            placeBar(s.warn, e.time - lead, lead);
            placeBar(s.attack, e.time, duration, 6);
            placeBar(s.outro, e.time + duration, outro);
        }
    }
    
    function placeBar(bar:FlxSprite, startMs:Float, lenMs:Float, minPx:Float = 0)
    {
        var x = timeToX(startMs);
        var w = Math.max(minPx, lenMs * pixelsPerMs);
        
        bar.visible = w > 0 && x + w >= 0 && x <= FlxG.width;
        bar.x = x;
        bar.y = this.y + 100;
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
            tick.setGraphicSize(2, (beat % 4 == 0) ? 32 : 16);
            tick.color = (beat % 4 == 0) ? FlxColor.MAGENTA : FlxColor.WHITE;
        }
    }
    
    public function timeToX(t:Float):Float
        return FlxG.width * 0.5 + (t - cursorMusicTime) * pixelsPerMs;
        
    public function xToTime(px:Float):Float
        return cursorMusicTime + (px - FlxG.width * 0.5) / pixelsPerMs;
}
