package objects;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class Spike extends FlxTypedSpriteGroup<FlxSprite>
{
    var spikeSprite:FlxSprite;
    
    public var spikeHitbox:FlxSprite;
    
    public var raise:Float = 0; // 0 = escondido, 1 = em pé; quem manda é a piscina
    
    public function new(x:Float, y:Float)
    {
        super(x, y);
        
        spikeSprite = new FlxSprite();
        spikeSprite.loadGraphic("assets/images/game/spike.png");
        spikeSprite.setGraphicSize(96, 96);
        spikeSprite.updateHitbox();
        add(spikeSprite);
        
        spikeHitbox = new FlxSprite();
        spikeHitbox.makeGraphic(1, 1);
        spikeHitbox.setGraphicSize(32, 48);
        spikeHitbox.updateHitbox();
        spikeHitbox.setPosition(spikeSprite.width * 0.5 - spikeHitbox.width * 0.5, (spikeSprite.height * 0.5 - spikeHitbox.height * 0.5) + 16);
        add(spikeHitbox);
        
        spikeHitbox.visible = false;
    }
}
