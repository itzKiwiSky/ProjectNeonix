package core.level;

import haxe.Json;
import haxe.io.Path;
import core.managers.Timeline.TimelineEvent;
#if sys
import openfl.filesystem.File as OpenFlFile;
import openfl.filesystem.FileMode;
import openfl.filesystem.FileStream;
#end
import openfl.utils.Assets as OpenFlAssets;

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
    var songStarting:Float;
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
    public inline static function emptyEditorMetadata():EditorMeta
        return {
            audioPath: "",
            lastSavedTime: 0,
            eventLanes: [],
        }
        
    public inline static function emptyLevel():LevelData
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
                songStarting: 0.0,
                songEnding: -1.0,
            },
            events: [],
            editorMeta: emptyEditorMetadata(),
        }
        
    public static function loadJsonData(filename:String, rawJson:Bool = false):LevelData
    {
        var json:String = filename;
        if (!rawJson)
        {
            if (Path.isAbsolute(filename))
            {
                #if sys
                var file:OpenFlFile = new OpenFlFile(filename);
                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.READ);
                json = stream.readUTFBytes(stream.bytesAvailable);
                stream.close();
                #else
                throw 'Cannot load an external level file on this target: "$filename".';
                #end
            }
            else
            {
                if (!OpenFlAssets.exists(filename))
                    throw 'Level asset not found: "$filename".';
                json = OpenFlAssets.getText(filename);
            }
        }

        return Json.parse(json);
    }
}
