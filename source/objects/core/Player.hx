package objects.core;

import core.save.UserPreferences;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxPieDial;
import flixel.addons.display.FlxPieDial.FlxPieDialShape;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

class Player extends FlxTypedSpriteGroup<FlxSprite>
{
    var playerSprite:FlxSprite;
    var playerFadeSprite:FlxSprite;
    
    public var hitbox:FlxSprite;
    
    var dialHealth:DamageDial;
    
    public var health:Int = 6;
    public var maxHealth:Int = 6;
    
    var wasHit:Bool = false;
    var hitCooldown:Float = 1.5;
    var cooldown:Float = 0; // 0: o jogador não nasce todo branco
    
    var playerSpeed:Float = 350;
    var playerSize:Int = 48;
    
    var isKilled:Bool = false;
    
    public var playerSkin:Int = 0;
    
    public var onKill:Void->Void;
    
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
        
        // frames = maxHealth: o frame N mostra N/maxHealth do quadrado preenchido, o frame 0 é o cheio
        dialHealth = new DamageDial(0, 0, Math.floor(playerSize / 2), FlxColor.BLACK, maxHealth, SQUARE, false, 0);
        add(dialHealth);
        updateHealthDial(); // vida cheia: o dial começa invisível
        
        playerFadeSprite = new FlxSprite();
        playerFadeSprite.makeGraphic(1, 1, FlxColor.WHITE);
        playerFadeSprite.setGraphicSize(hitbox.width, hitbox.height);
        playerFadeSprite.updateHitbox();
        playerFadeSprite.alpha = 0;
        add(playerFadeSprite);
    }
    
    public function updatePlayer(elapsed:Float)
    {
        hitbox.velocity.x = 0;
        
        if (hitbox.isTouching(DOWN) && FlxG.keys.anyPressed([UP, SPACE, Z, W]))
            hitbox.velocity.y = -400;
            
        var dir:Float = (FlxG.keys.anyPressed([D, RIGHT]) ? 1 : 0) - (FlxG.keys.anyPressed([A, LEFT]) ? 1 : 0);
        
        hitbox.velocity.x = dir * playerSpeed;
        
        playerSprite.setPosition(hitbox.x, hitbox.y);
        playerFadeSprite.setPosition(hitbox.x, hitbox.y);
        dialHealth.setPosition(hitbox.x, hitbox.y);
        
        if (cooldown > 0)
            cooldown -= elapsed;
            
        if (wasHit && cooldown <= 0)
            wasHit = false;
            
        playerFadeSprite.alpha = FlxEase.linear(Math.max(0, cooldown) / hitCooldown);
        
        // update graphic //
        
        if (!hitbox.isTouching(DOWN))
            playerSprite.angle += (dir * 360) * elapsed;
        else
        {
            var angle:Float = Math.ffloor(playerSprite.angle % 360);
            playerSprite.angle = 90 * Math.round(angle / 90);
        }
        
        if (health <= 0 && !isKilled)
        {
            isKilled = true;
            if (onKill != null)
                onKill();
        }
        
        playerFadeSprite.angle = playerSprite.angle;
        dialHealth.angle = playerSprite.angle;
    }
    
    public function testHit()
    {
        if (wasHit || health <= 0)
            return;
            
        wasHit = true;
        cooldown = hitCooldown;
        health--;
        
        updateHealthDial();
    }
    
    // o único lugar que mexe no dial; chame de novo se a vida mudar por outro caminho (cura, restart)
    function updateHealthDial()
        dialHealth.setDamage(maxHealth - health, maxHealth);
}

// dial de dano: preenche conforme a vida cai
private class DamageDial extends FlxPieDial
{
    // 0 = invisível; 1..max-1 = fatia crescente; max = quadrado inteiro (o frame 0 da biblioteca é o cheio)
    public function setDamage(damage:Int, max:Int)
    {
        var d:Int = Std.int(FlxMath.bound(damage, 0, max));
        visible = d > 0;
        animation.frameIndex = (d >= max) ? 0 : d;
    }
    
    // o construtor da biblioteca faz amount = 1.0, que mandava o frame para fora do intervalo e gerava o aviso
    override function set_amount(f:Float):Float
    {
        @:bypassAccessor amount = FlxMath.bound(f, 0, 1);
        return amount;
    }
}
