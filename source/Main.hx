package;

import backend.FPSCounter;
import openfl.display.StageScaleMode;
import openfl.Lib;
import states.BoostrapState;
import states.EditorState;
import flixel.FlxG;
import states.PlayState;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
    var game:FlxGame;
    
    public static var screenWidth:Int = 1280;
    public static var screenHeight:Int = 720;
    
    public static var fpsVar:FPSCounter;
    
    var updateFrameRate:Int = 60;
    
    public function new()
    {
        super();
        game = new FlxGame(screenWidth, screenHeight, BoostrapState, updateFrameRate, updateFrameRate, true, false);
        
        addChild(game);
        
        fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
        addChild(fpsVar);
        
        Lib.current.stage.align = "tl";
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
        
        FlxG.game.focusLostFramerate = 60;
        FlxG.autoPause = false;
        FlxG.sound.muteKeys = null;
        FlxG.sound.volumeUpKeys = null;
        FlxG.sound.volumeDownKeys = null;
        
        FlxG.signals.gameResized.add((w:Int, h:Int) ->
        {
            if (FlxG.cameras != null)
                for (cam in FlxG.cameras.list)
                    if (cam != null && cam.filters != null)
                        resetSpriteCache(cam.flashSprite);
                        
            if (FlxG.game != null)
                resetSpriteCache(FlxG.game);
        });
    }
    
    static function resetSpriteCache(sprite:Sprite):Void
    {
        @:privateAccess {
            sprite.__cacheBitmap = null;
            sprite.__cacheBitmapData = null;
        }
    }
    
    public static function main():Void
    {
        Lib.current.addChild(new Main());
    }
}
