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
    public var lane:Int = 0; // non serializable
    
    var baseColor:FlxColor = FlxColor.WHITE;
    
    public var eventSelected(default, null):Bool = false;
    
    static inline var SELECTED_COLOR:FlxColor = 0xFFFFE030;
    
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
        baseColor = c;
        applyColors();
    }
    
    public function setSelected(v:Bool)
    {
        eventSelected = v;
        applyColors();
    }
    
    function applyColors()
    {
        var c = eventSelected ? SELECTED_COLOR : baseColor;
        var dim = eventSelected ? 0.6 : 0.4;
        
        warn.color = c;
        warn.alpha = dim;
        attack.color = c;
        attack.alpha = 1;
        outro.color = c;
        outro.alpha = dim;
    }
    
    public function addTo(group:FlxTypedSpriteGroup<FlxSprite>)
    {
        group.add(warn);
        group.add(attack);
        group.add(outro);
    }
}
