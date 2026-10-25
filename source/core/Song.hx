package core;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

typedef SongMeta =
{
    var bpm:Float;
    var scrollSpeed:Float;
    var songStartOffset:Float;
    var title:String;
    var songID:String;
    var artist:String;
    var songEnding:Float;
    var laneCount:Int;
}

class Song
{
    var bpm:Float = 100;
    var scrollSpeed:Float = 1.7;
    var startSongOffset:Float = 0;
    var songMetaData:SongMeta = {
        bpm: 100,
        scrollSpeed: 1,
        songStartOffset: 0,
        title: "",
        songID: "",
        artist: "",
        songEnding: -1,
        laneCount: 2,
    };
    
    public var isSongLoaded:Bool = false;
    
    // public var notes:Array<NoteStruct> = [];
    
    public function new() {}
    
    public function loadSong(id:String)
    {
        var jsonData:Dynamic = Json.parse(File.getContent("assets/data/" + id + ".json"));
        songMetaData.bpm = jsonData.meta.bpm;
    }
}
