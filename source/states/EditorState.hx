package states;

import objects.ActorManager;
import core.Level;
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
    var activeActors:FlxTypedGroup<LevelActor>; // store only the visible ones that will appear on the time //
    var levelActors:FlxTypedGroup<LevelActor>; // store all actors //
    var musicTime:Float = 0;
    
    override function create()
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
            
        ActorManager.init();
        
        activeActors = new FlxTypedGroup<LevelActor>();
        levelActors = new FlxTypedGroup<LevelActor>();
        add(activeActors);
        final level:LevelMetaData = Level.loadJsonData("game.json");
        
        var all:Array<LevelActor> = ActorManager.createAll(level);
        for (a in all)
            levelActors.add(a);
            
        timeText = new FlxText();
        timeText.size = 35;
        timeText.setPosition(32, 32);
        add(timeText);
        
        FlxG.sound.playMusic("assets/music/life_is_game_kay.ogg");
        
        Conductor.changeBPM(110);
        
        super.create();
    }
    
    function loadObjects() {}
    
    override function update(elapsed:Float)
    {
        Conductor.songPosition = FlxG.sound.music.time;
        
        super.update(elapsed);
        
        timeText.text = 'CurrentTime:${FlxG.sound.music.time} | step: $curStep | state: ${FlxG.sound.music.playing}';
        
        if (FlxG.keys.anyJustPressed([SPACE]))
            if (FlxG.sound.music.playing)
            {
                FlxG.sound.music.time = musicTime;
                FlxG.sound.music.pause();
            }
            else
                FlxG.sound.music.play();
                
        if (FlxG.keys.anyPressed([LEFT]))
            if (musicTime > 0)
                musicTime -= 1;
        if (FlxG.keys.anyPressed([RIGHT]))
            if (musicTime < FlxG.sound.music.length)
                musicTime += 1;
    }
    
    override function onBeatHit()
    {
        super.onBeatHit();
    }
    
    function setSongTime(time:Float)
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.time = time;
            
        for (a in levelActors)
        {
            if (a.isInside(time))
                /* entra em activeActors */
                if (!activeActors.members.contains(a))
                    activeActors.add(a);
                else
                    /* sai de activeActors */
                    activeActors.remove(a);
        }
    }
}
