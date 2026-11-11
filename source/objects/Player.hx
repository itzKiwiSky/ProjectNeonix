package objects;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.FlxGraphic;
import flixel.addons.display.FlxPieDial;
import flixel.addons.display.FlxPieDial.FlxPieDialShape;
import core.save.UserPreferences;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class Player extends FlxTypedSpriteGroup<FlxSprite>
{
    var playerSprite:FlxSprite;
    
    public var hitbox:FlxSprite;
    
    var dialHealth:FlxPieDial;
    
    public var health:Int = 6;
    public var maxHealth:Int = 6;
    
    var wasHit:Bool = false;
    var hitCooldown:Float = 1.5;
    var cooldown:Float = 1.5;
    
    var playerSpeed:Float = 350;
    var playerSize:Int = 48;
    
    public var playerSkin:Int = 0;
    
    public function new()
    {
        super();
        
        hitbox = new FlxSprite();
        hitbox.makeGraphic(playerSize, playerSize, FlxColor.TRANSPARENT);
        hitbox.updateHitbox();
        hitbox.acceleration.y = 1100;
        hitbox.maxVelocity.y = 2400;
        
        add(hitbox);
        playerSprite = new FlxSprite();
        playerSprite.loadGraphic('assets/images/skins/char_${UserPreferences.icon}.png');
        playerSprite.setGraphicSize(hitbox.width, hitbox.height);
        playerSprite.updateHitbox();
        
        add(playerSprite);
        
        dialHealth = new FlxPieDial(playerSprite.width * 0.5, playerSprite.height * 0.5, playerSize, FlxColor.BLACK, maxHealth, SQUARE, false, 0);
    }
    
    public function updatePlayer(elapsed:Float)
    {
        hitbox.velocity.x = 0;
        
        if (hitbox.isTouching(DOWN) && FlxG.keys.anyPressed([UP, SPACE, Z, W]))
            hitbox.velocity.y = -400;
            
        var dir:Float = (FlxG.keys.anyPressed([D, RIGHT]) ? 1 : 0) - (FlxG.keys.anyPressed([A, LEFT]) ? 1 : 0);
        
        hitbox.velocity.x = dir * playerSpeed;
        
        playerSprite.x = hitbox.x;
        playerSprite.y = hitbox.y;
        
        // update graphic //
        
        if (!hitbox.isTouching(DOWN))
            playerSprite.angle += (dir * 360) * elapsed;
        else
        {
            var angle:Float = Math.ffloor(playerSprite.angle % 360);
            playerSprite.angle = 90 * Math.round(angle / 90);
        }
    }
    
    public function testHit()
    {
        if (!wasHit)
        {
            wasHit = true;
            cooldown = hitCooldown;
            health--;
        }
    }
    
    function updateSprite()
    {
        // we try take the sprite from the flxdial and apply on the player graphic using flxspriteutils //
    }
    
    public function onKill() {}
}
