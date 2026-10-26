package objects;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class PulseBlock extends LevelActor
{
    var warningSprite:FlxSprite;
    var activeSprite:FlxSprite;
    var attackSpeed:Float = 0;
    
    static inline var BASE_SIZE:Int = 128;
    
    public function new(x:Float = 0, y:Float = 0, time:Float = 0, warningTime:Float = 1000, attackSpeed:Float = 500, duration:Float = 500, outroDuration:Float = 200)
    {
        super(x - BASE_SIZE * 0.5, y - BASE_SIZE * 0.5, time, warningTime, duration, outroDuration);
        this.attackSpeed = attackSpeed;
        cx = x;
        cy = y;
        
        warningSprite = makeBlock();
        warningSprite.visible = false;
        add(warningSprite);
        
        activeSprite = makeBlock();
        activeSprite.visible = false;
        warningSprite.alpha = 0.5;
        add(activeSprite);
    }
    
    function makeBlock():FlxSprite
    {
        var s = new FlxSprite();
        s.makeGraphic(BASE_SIZE, BASE_SIZE, FlxColor.TRANSPARENT, true);
        FlxSpriteUtil.drawRoundRect(s, 0, 0, BASE_SIZE, BASE_SIZE, 16, 16, FlxColor.MAGENTA);
        s.updateHitbox();
        return s;
    }
    
    inline function syncActive(obj:FlxSprite)
    {
        obj.updateHitbox();
        obj.setPosition(cx - obj.width * 0.5, cy - obj.height * 0.5);
    }
    
    function cancelAll()
    {
        FlxTween.cancelTweensOf(warningSprite);
        FlxTween.cancelTweensOf(warningSprite.scale);
        FlxTween.cancelTweensOf(activeSprite);
        FlxTween.cancelTweensOf(activeSprite.scale);
    }
    
    override function onWaiting()
    {
        cancelAll();
        
        warningSprite.visible = false;
        activeSprite.visible = false;
        warningSprite.scale.set(0, 0);
        activeSprite.scale.set(0, 0);
    }
    
    override function onWarning()
    {
        cancelAll();
        
        activeSprite.visible = false;
        activeSprite.scale.set(0, 0);
        
        warningSprite.visible = true;
        warningSprite.scale.set(0, 0);
        warningSprite.alpha = 0.5;
        syncActive(warningSprite);
        
        FlxTween.tween(warningSprite.scale, {x: 1, y: 1}, warningTime / 1000, {
            ease: FlxEase.backOut,
            onUpdate: (_) -> syncActive(warningSprite)
        });
    }
    
    override function onActive()
    {
        cancelAll();
        
        warningSprite.visible = false;
        
        activeSprite.visible = true;
        activeSprite.alpha = 1;
        activeSprite.scale.set(0, 0);
        syncActive(activeSprite);
        
        FlxTween.tween(activeSprite.scale, {x: 1, y: 1}, attackSpeed / 1000, {
            ease: FlxEase.backOut,
            onUpdate: (_) -> syncActive(activeSprite)
        });
    }
    
    override function onOutro()
    {
        cancelAll();
        
        warningSprite.visible = false;
        
        activeSprite.visible = true;
        activeSprite.alpha = 1;
        activeSprite.scale.set(1, 1);
        syncActive(activeSprite);
        
        FlxTween.tween(activeSprite, {alpha: 0}, outroDuration / 1000, {ease: FlxEase.quadIn});
        FlxTween.tween(activeSprite.scale, {x: 0, y: 0}, outroDuration / 1000, {
            ease: FlxEase.quadIn,
            onUpdate: (_) -> syncActive(activeSprite)
        });
    }
    
    override function onDead()
    {
        cancelAll();
        super.onDead();
    }
    
    override public function hits(obj:FlxSprite):Bool
        return phase == Active && FlxG.overlap(obj, activeSprite);
}
