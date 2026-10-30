package core.level;

import sys.io.File;
import haxe.Json;
import core.Timeline.TimelineEvent;

typedef LevelMetaData =
{
    var title:String;
    var artist:String;
    var songID:String;
    var backgroundID:Int;
    var backgroudColor:Array<Int>;
    var platformColor:Array<Int>;
    var bpm:Float;
    var songEnding:Float;
}

typedef LevelData =
{
    var meta:LevelMetaData;
    var events:Array<TimelineEvent>;
}

class Level
{
    public static function loadJsonData(filename:String):LevelData
    {
        final data:LevelData = Json.parse(File.getContent("assets/data/" + filename));
        return data;
    }
}
