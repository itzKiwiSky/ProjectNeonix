package core;

import sys.io.File;
import haxe.Json;
import core.Timeline.TimelineEvent;

typedef LevelMetaData =
{
    var title:String;
    var artist:String;
    var songID:String;
    var bpm:Float;
    var songEnding:Float;
    var events:Array<TimelineEvent>;
}

class Level
{
    public inline static function loadJsonData(filename:String):LevelMetaData
    {
        final data:LevelMetaData = Json.parse(File.getContent("assets/data/" + filename));
        return data;
    }
}
