package states;

import objects.PulseBlock;
import flixel.tweens.FlxTween;
import core.Conductor;
import flixel.sound.FlxSound;
import objects.LevelActor;
import flixel.group.FlxGroup.FlxTypedGroup;
import core.Timeline;
import objects.Player;
import flixel.FlxSprite;
import core.MusicSyncedState;
import flixel.FlxG;

class PlayState extends MusicSyncedState
{
    var player:Player;
    var platform:FlxSprite;
    
    var timeline:Timeline;
    
    public static var currentSong:String = "";
    
    var levelActors:FlxTypedGroup<LevelActor>;
    
    // test //
    var events:Array<TimelineEvent> = [
        {
            time: 4000,
            object: "pulse_square",
            lead: 750,
            params: {
                x: FlxG.random.int(64, 1000),
                y: 600,
                outro: 500,
                attackSpeed: 500,
                duration: 1250
            }
        },
        {
            time: 5000,
            object: "pulse_square",
            lead: 750,
            params: {
                x: FlxG.random.int(64, 1000),
                y: 600,
                outro: 500,
                attackSpeed: 500,
                duration: 1250
            }
        },
        {
            time: 6000,
            object: "pulse_square",
            lead: 750,
            params: {
                x: FlxG.random.int(64, 1000),
                y: 600,
                outro: 500,
                attackSpeed: 500,
                duration: 1250
            }
        },
    ];
    
    override public function create()
    {
        persistentDraw = persistentUpdate = true;
        
        FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
        
        FlxG.debugger.drawDebug = true;
        
        timeline = new Timeline(events);
        
        FlxG.sound.cache("assets/music/life_is_game_kay.ogg");
        
        player = new Player();
        player.screenCenter();
        
        platform = new FlxSprite();
        platform.makeGraphic(FlxG.width - 128, 48, 0xFFFFFFFF);
        platform.updateHitbox();
        platform.immovable = true;
        platform.y = FlxG.height - 28;
        platform.screenCenter(X);
        
        levelActors = new FlxTypedGroup<LevelActor>();
        
        add(player);
        add(platform);
        add(levelActors);
        
        FlxG.sound.playMusic("assets/music/life_is_game_kay.ogg");
        
        super.create();
    }
    
    override public function update(elapsed:Float)
    {
        Conductor.songPosition = FlxG.sound.music.time;
        FlxG.watch.add(FlxG.sound.music, "time", "music time");
        
        super.update(elapsed);
        
        FlxG.collide(player, platform);
        
        timeline.update(Conductor.songPosition, (e:TimelineEvent) ->
        {
            switch (e.object)
            {
                case "pulse_square":
                    trace("pulse");
                    levelActors.add(new PulseBlock(e.params.x, e.params.y, e.time, e.lead, e.params.attackSpeed, e.params.duration, e.params.outro));
            }
        });
        
        levelActors.forEachAlive(a ->
        {
            if (a.hits(player))
                trace("hit!");
        });
        
        player.updatePlayer(elapsed);
    }
    
    override function onBeatHit() {}
}
