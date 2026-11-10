package objects;

import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxG;
import flixel.FlxSprite;

class Player extends FlxTypedSpriteGroup<FlxSprite>
{
    var playerSprite:FlxSprite;
    
    public var hitbox:FlxSprite;
    
    public var health:Int = 5;
    
    var wasHit:Bool = false;
    var hitCooldown:Float = 1.5;
    var cooldown:Float = 1.5;
    
    public var playerSkin:Int = 0;
    
    public function new()
    {
        super();
        
        hitbox = new FlxSprite();
        hitbox.makeGraphic(64, 64, FlxColor.TRANSPARENT);
        hitbox.updateHitbox();
        hitbox.acceleration.y = 900;
        hitbox.maxVelocity.y = 2000;
        
        add(hitbox);
        playerSprite = new FlxSprite();
        playerSprite.makeGraphic(1, 1);
        playerSprite.setGraphicSize(hitbox.width, hitbox.height);
        playerSprite.updateHitbox();
        
        add(playerSprite);
    }
    
    public function updatePlayer(elapsed:Float)
    {
        hitbox.velocity.x = 0;
        
        if (hitbox.isTouching(DOWN) && FlxG.keys.anyPressed([UP, SPACE, Z, W]))
            hitbox.velocity.y = -400;
            
        if (FlxG.keys.anyPressed([A, LEFT]))
            hitbox.velocity.x = -300;
            
        if (FlxG.keys.anyPressed([D, RIGHT]))
            hitbox.velocity.x = 300;
            
        playerSprite.x = hitbox.x;
        playerSprite.y = hitbox.y;
    }
    
    public function onKill() {}
}
