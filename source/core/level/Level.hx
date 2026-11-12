package core.level;

import sys.io.File;
import haxe.Json;
import core.managers.Timeline.TimelineEvent;

typedef LevelMetaData =
{
    var title:String;
    var artist:String;
    var songFilename:String;
    var backgroundID:Int;
    var backgroundColor:Array<Int>;
    var platformColor:Array<Int>;
    var actorsColor:Array<Int>;
    var bpm:Float;
    var songEnding:Float;
}

typedef EditorMeta =
{
    var audioPath:String;
    var lastSavedTime:Float;
    var ?eventLanes:Array<Null<Int>>;
}

typedef LevelData =
{
    var meta:LevelMetaData;
    var events:Array<TimelineEvent>;
    var ?editorMeta:EditorMeta;
}

class Level
{
    public static function emptyLevel()
    {
        return {
            meta: {
                title: "",
                artist: "",
                songFilename: "",
                backgroundID: 2,
                backgroundColor: [62, 118, 158],
                platformColor: [186, 211, 230],
                actorsColor: [255, 255, 255],
                bpm: 100.0,
                songEnding: -1.0,
            },
            events: [],
            editorMeta: emptyEditorMetadata(),
        };
    }
    
    public static function emptyEditorMetadata():EditorMeta
    {
        return {
            audioPath: "",
            lastSavedTime: 0,
            eventLanes: [],
        }
    }
    
    public static function loadJsonData(filename:String):LevelData
    {
        final data:LevelData = Json.parse(File.getContent(filename));
        return data;
    }
}
