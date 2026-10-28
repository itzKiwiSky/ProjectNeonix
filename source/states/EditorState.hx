package states;

import flixel.math.FlxMath;
import objects.LevelActor;
import flixel.group.FlxGroup.FlxTypedGroup;
import core.Conductor;
import flixel.FlxG;
import flixel.text.FlxText;
import core.MusicSyncedState;

class EditorState extends MusicSyncedState
{
    var timeText:FlxText;
    var levelActors:FlxTypedGroup<LevelActor>;
    var unspawnedActors:FlxTypedGroup<LevelActor>;
    
    override function create()
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
            
        levelActors = new FlxTypedGroup<LevelActor>();
        unspawnedActors = new FlxTypedGroup<LevelActor>();
        add(levelActors);
        
        timeText = new FlxText();
        timeText.size = 35;
        timeText.setPosition(32, 32);
        add(timeText);
        
        FlxG.sound.playMusic("assets/music/life_is_game_kay.ogg");
        
        Conductor.changeBPM(110);
        
        super.create();
    }
    
    override function update(elapsed:Float)
    {
        Conductor.songPosition = FlxG.sound.music.time;
        
        super.update(elapsed);
        
        timeText.text = 'CurrentTime:${FlxG.sound.music.time} | step: $curStep | state: ${FlxG.sound.music.playing}';
        
        if (FlxG.keys.anyJustPressed([SPACE]))
            if (FlxG.sound.music.playing)
                FlxG.sound.music.pause();
            else
                FlxG.sound.music.play();
                
        if (FlxG.keys.anyPressed([LEFT]))
            if (FlxG.sound.music.time > 0)
                FlxG.sound.music.time -= 1;
        if (FlxG.keys.anyPressed([RIGHT]))
            if (FlxG.sound.music.time < FlxG.sound.music.length)
                FlxG.sound.music.time += 1;
    }
    
    override function onBeatHit()
    {
        super.onBeatHit();
    }
}
