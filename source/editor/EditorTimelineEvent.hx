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
    public var lane:Int = 0; // só do editor, não é serializado
    
    public function new(event:TimelineEvent)
    {
        this.event = event;
        warn = makeBar();
        attack = makeBar();
        outro = makeBar();
    }
    
    static function makeBar():FlxSprite
    {
        var s = new FlxSprite();
        s.makeGraphic(1, 32, FlxColor.WHITE);
        s.origin.set(0, 0); // estica para a direita a partir do x
        s.visible = false;
        return s;
    }
    
    public function setColors(c:FlxColor)
    {
        warn.color = c;
        warn.alpha = 0.4;
        attack.color = c;
        attack.alpha = 1;
        outro.color = c;
        outro.alpha = 0.4;
    }
    
    public function addTo(group:FlxTypedSpriteGroup<FlxSprite>)
    {
        group.add(warn);
        group.add(attack);
        group.add(outro);
    }
}
