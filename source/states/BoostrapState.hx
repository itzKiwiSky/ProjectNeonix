package states;

import core.save.UserPreferences;
import core.save.SaveUtils;
import flixel.FlxG;
import flixel.FlxState;

class BoostrapState extends FlxState
{
    override function create()
    {
        FlxG.sound.muteKeys = null;
        FlxG.sound.volumeUpKeys = null;
        FlxG.sound.volumeDownKeys = null;
        
        SaveUtils.applyDefaults(UserPreferences);
        FlxG.switchState(() -> new states.PlayState());
    }
}
