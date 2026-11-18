package objects.level;

import core.managers.ActorManager;
import core.managers.Timeline.TimelineEvent;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import core.LevelActor;

class Laser extends LevelActor
{
    var warningSprite:FlxSprite;
    var activeSprite:FlxSprite;
    var attackSpeed:Float = 0;
    
    public function new(x:Float, size:Int, time:Float = 0, warningTime:Float = 1000, attackSpeed:Float = 500, duration:Float = 500, outroDuration:Float = 200)
    {
        super(x);
        
        this.attackSpeed = attackSpeed;
        cx = x;
        cy = y;
        
        warningSprite = makeBlock(size);
        warningSprite.visible = false;
        add(warningSprite);
        
        activeSprite = makeBlock(size);
        activeSprite.visible = false;
        warningSprite.alpha = 0.5;
        add(activeSprite);
    }
    
    public static function selfRegister()
    {
        // ActorManager.registerActor()
    }
    
    function makeBlock(wid:Int):FlxSprite
    {
        var s = new FlxSprite();
        s.makeGraphic(wid, FlxG.height, FlxColor.TRANSPARENT, true);
        FlxSpriteUtil.drawRect(s, 0, 0, wid, FlxG.height, FlxColor.WHITE);
        s.updateHitbox();
        return s;
    }
    
    inline function syncActive(obj:FlxSprite):Void
    {
        obj.updateHitbox();
        obj.setPosition(cx - obj.width * 0.5, cy - obj.height * 0.5);
    }
    
    function setScale(s:FlxSprite, v:Float)
    {
        s.scale.set(v, v);
        syncActive(s);
    }
    
    override public function resetTimelineEvents() {}
    
    override public function onTimelineEvent(name:String, source:TimelineEvent) {}
}
