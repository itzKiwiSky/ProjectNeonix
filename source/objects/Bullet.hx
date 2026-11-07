package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class Bullet extends FlxSprite
{
    public static inline var SIZE:Int = 24;
    
    public var volley:Int = 0; // número da rajada
    public var index:Int = 0; // posição dentro da rajada
    
    public function new(volley:Int, index:Int)
    {
        super();
        this.volley = volley;
        this.index = index;
        
        // um bitmap só para todas as balas, senão cada uma criaria o seu
        var key = "bullet_circle";
        if (!FlxG.bitmap.checkCache(key))
        {
            makeGraphic(SIZE, SIZE, FlxColor.TRANSPARENT, true, key);
            FlxSpriteUtil.drawCircle(this, -1, -1, SIZE * 0.5, FlxColor.MAGENTA);
        }
        else
            loadGraphic(FlxG.bitmap.get(key));
            
        visible = false;
    }
}
