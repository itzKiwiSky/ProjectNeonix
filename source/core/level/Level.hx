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
    var backgroundColor:Array<Int>;
    var platformColor:Array<Int>;
    var actorsColor:Array<Int>;
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
    public static function emptyLevel()
    {
        return {
            meta: {
                title: "",
                artist: "",
                songID: "",
                backgroundID: 5,
                backgroundColor: [62, 118, 158],
                platformColor: [186, 211, 230],
                actorsColor: [255, 255, 255],
                bpm: 100.0,
                songEnding: -1.0,
            },
            events: [],
        };
    }
    
    public static function loadJsonData(filename:String):LevelData
    {
        final data:LevelData = Json.parse(File.getContent(filename));
        return data;
    }
}
