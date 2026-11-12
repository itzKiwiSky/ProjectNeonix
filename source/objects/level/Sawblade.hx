package objects.level;

import flixel.FlxBasic;
import core.LevelActor;

class Sawblade extends LevelActor
{
    public function new(x:Float, y:Float, speed:Float)
    {
        super();
    }
    
    public static function selfRegister() {}
    
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
