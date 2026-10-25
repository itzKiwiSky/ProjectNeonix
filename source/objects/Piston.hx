package objects;

import flixel.util.FlxColor;
import flixel.FlxSprite;

class Piston extends LevelActor
{
    public function new()
    {
        super();
        
        var base:FlxSprite = new FlxSprite();
        base.makeGraphic(64, 48, FlxColor.RED);
        base.updateHitbox();
        add(base);
    }
}
