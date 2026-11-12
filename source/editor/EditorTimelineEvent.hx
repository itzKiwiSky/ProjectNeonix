package editor;

import core.managers.Timeline.TimelineEvent;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class EditorTimelineEvent
{
    public var event:TimelineEvent;
    public var warn:FlxSprite;
    public var attack:FlxSprite;
    public var outro:FlxSprite;
    public var nameLabel:FlxText;
    public var naturalNameWidth(default, null):Float;
    public var lane:Int = 0;
    public var laneIsManual:Bool = false;
    
    var baseColor:FlxColor = FlxColor.WHITE;
    
    public var eventSelected(default, null):Bool = false;
    
    static inline var SELECTED_COLOR:FlxColor = 0xFFFFE030;
    
    public function new(event:TimelineEvent)
    {
        this.event = event;
        warn = makeBar();
        attack = makeBar();
        outro = makeBar();
        nameLabel = new FlxText(0, 0, 0, displayName(event.object), 10);
        nameLabel.wordWrap = false;
        nameLabel.color = FlxColor.WHITE;
        naturalNameWidth = nameLabel.width;
    }
    
    public function refreshName()
    {
        nameLabel.fieldWidth = 0;
        nameLabel.text = displayName(event.object);
        naturalNameWidth = nameLabel.width;
    }
    
    inline static function displayName(name:String):String
        return name.split("_").join(" ");
        
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
        group.add(nameLabel);
    }
}
