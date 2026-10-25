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
    
    static inline var BASE_SIZE:Int = 64;
    
    public function new(x:Float = 0, y:Float = 0, time:Float = 0, warningTime:Float = 1000, duration:Float = 500, outroDuration:Float = 200)
    {
        super(x - BASE_SIZE * 0.5, y - BASE_SIZE * 0.5, time, warningTime, duration, outroDuration);
        
        cx = x;
        cy = y;
        
        warningSprite = makeBlock();
        warningSprite.visible = false;
        add(warningSprite);
        
        activeSprite = makeBlock();
        activeSprite.visible = false;
        add(activeSprite);
        
        // updateHitbox();
    }
    
    function makeBlock():FlxSprite
    {
        var s = new FlxSprite();
        s.makeGraphic(64, 64, FlxColor.TRANSPARENT, true);
        FlxSpriteUtil.drawRoundRect(s, 0, 0, 64, 64, 16, 16, FlxColor.MAGENTA);
        s.updateHitbox();
        return s;
    }
    
    function syncActive()
    {
        activeSprite.updateHitbox();
        activeSprite.setPosition(cx - activeSprite.width * 0.5, cy - activeSprite.height * 0.5);
    }
    
    override function onWaiting()
    {
        FlxTween.cancelTweensOf(warningSprite);
        FlxTween.cancelTweensOf(activeSprite);
        FlxTween.cancelTweensOf(activeSprite.scale);
        warningSprite.visible = false;
        activeSprite.visible = false;
    }
    
    override function onWarning()
    {
        FlxTween.cancelTweensOf(warningSprite);
        activeSprite.visible = false;
        warningSprite.visible = true;
        warningSprite.alpha = 0;
        FlxTween.tween(warningSprite, {alpha: 0.5}, warningTime / 1000, {ease: FlxEase.quadOut});
    }
    
    override function onActive()
    {
        FlxTween.cancelTweensOf(warningSprite);
        FlxTween.cancelTweensOf(activeSprite);
        FlxTween.cancelTweensOf(activeSprite.scale);
        
        trace(x, y, warningSprite.x, warningSprite.y, activeSprite.x, activeSprite.y);
        
        warningSprite.visible = false;
        
        activeSprite.visible = true;
        activeSprite.alpha = 1;
        activeSprite.scale.set(0, 0);
        syncActive();
        
        FlxTween.tween(activeSprite.scale, {x: 1, y: 1}, 0.15, {
            ease: FlxEase.backOut,
            onUpdate: (_) -> syncActive()
        });
    }
    
    override function onOutro()
    {
        FlxTween.cancelTweensOf(activeSprite);
        FlxTween.cancelTweensOf(activeSprite.scale);
        
        warningSprite.visible = false;
        activeSprite.visible = true;
        
        FlxTween.tween(activeSprite, {alpha: 0}, outroDuration / 1000, {ease: FlxEase.quadIn});
        FlxTween.tween(activeSprite.scale, {x: 0, y: 0}, outroDuration / 1000, {
            ease: FlxEase.quadIn,
            onUpdate: (_) -> syncActive()
        });
    }
    
    override function onDead()
    {
        FlxTween.cancelTweensOf(warningSprite);
        FlxTween.cancelTweensOf(activeSprite);
        FlxTween.cancelTweensOf(activeSprite.scale);
        super.onDead();
    }
    
    override public function hits(obj:FlxSprite):Bool
        return phase == Active && FlxG.overlap(obj, activeSprite);
}
