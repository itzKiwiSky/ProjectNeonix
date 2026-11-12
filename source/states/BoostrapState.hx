package states;

import core.save.UserPreferences;
import core.save.SaveUtils;
import flixel.FlxG;
import flixel.FlxState;

class BoostrapState extends FlxState
{
    override function create()
    {
        SaveUtils.applyDefaults(UserPreferences);
        FlxG.switchState(() -> new states.PlayState());
    }
}
