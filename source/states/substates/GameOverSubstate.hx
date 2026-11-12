package states.substates;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxSubState;

class GameOverSubstate extends FlxSubState
{
    var bgSprite:FlxSprite;
    var gameOverText:FlxText;
    
    override function create()
    {
        super.create();
        
        bgSprite = new FlxSprite();
        bgSprite.makeGraphic(1, 1, FlxColor.BLACK);
        bgSprite.setGraphicSize(FlxG.width, FlxG.height);
        bgSprite.updateHitbox();
        bgSprite.screenCenter();
        bgSprite.alpha = 0;
        
        add(bgSprite);
        
        gameOverText = new FlxText();
        gameOverText.size = 50;
        gameOverText.font = "assets/embed/fonts/nexa_bold.otf";
        gameOverText.text = "Game Over!";
        gameOverText.screenCenter(X);
        gameOverText.y = 400;
        gameOverText.alpha = 0;
        
        add(gameOverText);
        
        openTransition();
    }
    
    function openTransition()
    {
        FlxTween.tween(bgSprite, {alpha: 0.6}, 1.1, {
            ease: FlxEase.quadOut,
            onComplete: (t:FlxTween) ->
            {
                FlxTween.tween(gameOverText, {alpha: 1, y: 200}, 1.5, {ease: FlxEase.backOut});
            }
        });
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}
