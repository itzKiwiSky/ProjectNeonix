package core.save;

import flixel.FlxG;

class SaveUtils
{
    public static function bind(path:String, ?defaults:Dynamic):Void
    {
        FlxG.save.bind(path);

        if (defaults != null)
            applyDefaults(defaults);
    }

    public static function applyDefaults(defaults:Dynamic):Void
    {
        var data = FlxG.save.data;
        var changed = false;

        for (field in Reflect.fields(defaults))
        {
            if (Reflect.field(data, field) == null)
            {
                Reflect.setField(data, field, Reflect.field(defaults, field));
                changed = true;
            }
        }

        if (changed)
            FlxG.save.flush();
    }
}
