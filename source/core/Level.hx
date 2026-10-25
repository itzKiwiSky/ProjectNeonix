package core;

import core.Timeline.TimelineEvent;

typedef LeveMetaData =
{
    var title:String;
    var artist:String;
    var songID:String;
    var bpm:Float;
    var songEnding:Float;
    var events:Array<TimelineEvent>;
}

class Level {}
