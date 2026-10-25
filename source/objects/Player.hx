package objects;

import flixel.FlxG;
import flixel.FlxSprite;

class Player extends FlxSprite
{
    public function new()
    {
        super();
        
        makeGraphic(64, 64, 0xFFFFFFFF);
        updateHitbox();
        acceleration.y = 900;
        maxVelocity.y = 2000;
    }
    
    public function updatePlayer(elapsed:Float)
    {
        velocity.x = 0;
        
        if (isTouching(DOWN) && FlxG.keys.anyPressed([UP, SPACE, Z, W]))
            velocity.y = -400;
            
        if (FlxG.keys.anyPressed([A, LEFT]))
            velocity.x = -300;
            
        if (FlxG.keys.anyPressed([D, RIGHT]))
            velocity.x = 300;
    }
}
