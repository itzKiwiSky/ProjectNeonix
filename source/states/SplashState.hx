package states;

import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.FlxState;

class SplashState extends FlxState
{
    var haxeLogo:FlxSprite;
    
    override function create()
    {
        super.create();
        haxeLogo = new FlxSprite();
        haxeLogo.loadGraphic("assets/images/boot/haxeflixel.png");
        haxeLogo.scale.set(0.35, 0.35);
        haxeLogo.updateHitbox();
        haxeLogo.screenCenter(X);
        haxeLogo.y = 500;
        haxeLogo.angle -= 20;
        haxeLogo.alpha = 0;
        add(haxeLogo);
        
        FlxTween.tween(haxeLogo, {angle: 0, alpha: 1, y: (FlxG.height - haxeLogo.height) / 2}, 2, {
            ease: FlxEase.backOut,
            onComplete: (t:FlxTween) ->
            {
                FlxTimer.wait(0.5, () ->
                {
                    FlxTween.tween(haxeLogo, {angle: 45, alpha: 0, y: 700}, 2, {
                        ease: FlxEase.backIn,
                        onComplete: (t:FlxTween) -> {}
                    });
                });
            }
        });
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}
