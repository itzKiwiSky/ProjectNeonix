package;

import states.PlayState;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
    var game:FlxGame;
    var screenWidth:Int = 1280;
    var screenHeight:Int = 720;
    var updateFrameRate:Int = 60;
    
    public function new()
    {
        super();
        game = new FlxGame(screenWidth, screenHeight, PlayState, updateFrameRate, updateFrameRate, true, false);
        
        addChild(game);
    }
}
