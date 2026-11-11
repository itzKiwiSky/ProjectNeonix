package core.save;

@:structInit
class UserPreferences
{
    public static var icon:Int = 1;
    public static var mapsBeaten:Map<String, Bool> = [];
    
    public static var achievements:Map<String, Bool> = [];
    
    // settings //
    public static var masterVolume:Float = 0.75;
    public static var musicVolume:Float = 0.5;
    public static var sfxVolume:Float = 0.5;
}
