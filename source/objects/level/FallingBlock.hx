package objects.level;

import flixel.tweens.FlxEase;
import flixel.FlxG;
import flixel.FlxSprite;
import core.managers.ActorManager;
import flixel.FlxBasic;
import core.LevelActor;

class FallingBlock extends LevelActor
{
    var warningSprite:FlxSprite;
    var movingBlock:FlxSprite;
    
    static inline final sizeBase:Int = 128;
    
    public function new(x:Float, y:Float, time:Float = 0, warningTime:Float = 1000, attackSpeed:Float = 500, outroDuration:Float = 200)
    {
        super(x, y, time, warningTime, attackSpeed, outroDuration);
        warningSprite = new FlxSprite();
        warningSprite.loadGraphic("assets/images/game/warning.png");
        warningSprite.setGraphicSize(sizeBase, FlxG.height);
        warningSprite.updateHitbox();
        add(warningSprite);
        
        movingBlock = new FlxSprite();
        movingBlock.loadGraphic("assets/images/game/movable_block.png");
        movingBlock.setGraphicSize(sizeBase, sizeBase);
        movingBlock.updateHitbox();
        add(movingBlock);
    }
    
    public static function selfRegister()
    {
        // ActorManager.registerActor();
    }
    
    override function onWaiting() {}
    
    override function onWarning()
    {
        warningSprite.visible = true;
        movingBlock.visible = false;
    }
    
    override function onActive()
    {
        warningSprite.visible = false;
        movingBlock.visible = true;
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
    
    override function onOutro() {}
    
    override function onDead()
    {
        warningSprite.visible = false;
        movingBlock.visible = false;
    }
    
    override function onWaitingUpdate() {}
    
    override function onWarningUpdate()
    {
        var t:Float = progress(currentTime, time - warningTime, 200);
        setScale(warningSprite, FlxEase.backOut(t));
    }
    
    override function onActiveUpdate() {}
    
    override function onOutroUpdate() {}
    
    override function hits(obj:FlxBasic):Bool
    {
        return super.hits(obj);
    }
}
