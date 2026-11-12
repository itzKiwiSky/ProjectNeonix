package states.substates;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxSubState;

class GameOverSubstate extends FlxSubState
{
    public function new()
    {
        super(0x33000000);
    }
    
    override function create()
    {
        super.create();
        
        var gameOverText:FlxText = new FlxText();
        gameOverText.size = 50;
        gameOverText.font = "assets/embed/fonts/nexa_bold.otf";
        gameOverText.text = "Game Over!";
        
        gameOverText.screenCenter(X);
        gameOverText.y = 200;
        
        add(gameOverText);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}
