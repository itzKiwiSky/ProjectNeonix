package objects.level;

import flixel.FlxSprite;
import core.LevelActor;

class Piston extends LevelActor
{
    var warningSprite:FlxSprite;
    var movingBlock:FlxSprite;
    
    static inline final sizeBase:Int = 128;
    static inline final WARNING_ANIMATION_MS:Float = 200;
    static inline final START_Y:Float = -sizeBase * 0.5;
    
    public function new()
    {
        super();
    }
    
    public static function selfRegister() {}
}
