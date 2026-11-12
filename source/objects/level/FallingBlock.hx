package objects.level;

import flixel.FlxSprite;
import core.managers.ActorManager;
import flixel.FlxBasic;
import core.LevelActor;

class FallingBlock extends LevelActor
{
    var warningSprite:FlxSprite;
    
    static inline final sizeBase:Int = 128;
    
    public function new(x:Float, y:Float, fallingSpeed:Float)
    {
        super();
    }
    
    public static function selfRegister()
    {
        // ActorManager.registerActor();
    }
    
    override function onWaiting() {}
    
    override function onWarning() {}
    
    override function onActive() {}
    
    override function onOutro() {}
    
    override function onDead() {}
    
    override function onWaitingUpdate() {}
    
    override function onWarningUpdate() {}
    
    override function onActiveUpdate() {}
    
    override function onOutroUpdate() {}
    
    override function hits(obj:FlxBasic):Bool
    {
        return super.hits(obj);
    }
}
