package editor;

import core.Timeline.TimelineEvent;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;

class EditorTimelineEvent
{
    public var event:TimelineEvent;
    public var warn:FlxSprite;
    public var attack:FlxSprite;
    public var outro:FlxSprite;
    
    public function new(event:TimelineEvent)
    {
        this.event = event;
        warn = makeBar(0x66FF0080);
        attack = makeBar(FlxColor.MAGENTA);
        outro = makeBar(0x66FF0080);
    }
    
    static function makeBar(color:FlxColor):FlxSprite
    {
        var s = new FlxSprite();
        s.makeGraphic(1, 32, color);
        s.origin.set(0, 0); // estica para a direita a partir do x
        s.visible = false;
        return s;
    }
    
    public function addTo(group:FlxTypedSpriteGroup<FlxSprite>)
    {
        group.add(warn);
        group.add(attack);
        group.add(outro);
    }
}
