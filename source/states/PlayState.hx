package states;

import objects.ActorManager;
import core.Level;
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
    
    var platformSprite:FlxSprite;
    var background:FlxSprite;
    
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
        
        ActorManager.init();
        
        FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
        
        FlxG.debugger.drawDebug = true;
        
        final level = Level.loadJsonData("game.json");
        
        timeline = new Timeline(level.events);
        
        FlxG.sound.cache("assets/music/life_is_game_kay.ogg");
        
        player = new Player();
        player.screenCenter();
        
        /*
            platform = new FlxSprite();
            platform.makeGraphic(FlxG.width - 128, 48, 0xFFFFFFFF);
            platform.updateHitbox();
            platform.immovable = true;
            platform.y = FlxG.height - 28;
            platform.screenCenter(X);
            platform.visible = false; 
         */
        
        platformSprite = new FlxSprite();
        platformSprite.loadGraphic("assets/images/game/platform.png");
        platformSprite.updateHitbox();
        platformSprite.y = (FlxG.height - platformSprite.height * 0.5) + 64;
        platformSprite.immovable = true;
        platformSprite.screenCenter(X);
        
        background = new FlxSprite();
        background.loadGraphic("assets/images/backgrounds/game_bg07.png");
        background.updateHitbox();
        background.screenCenter();
        background.color = 0xFFA65094;
        
        levelActors = new FlxTypedGroup<LevelActor>();
        
        add(background);
        add(player);
        add(platformSprite);
        add(levelActors);
        
        Conductor.changeBPM(110);
        FlxG.sound.playMusic("assets/music/life_is_game_kay.ogg");
        FlxG.sound.music.volume = 0.2;
        
        super.create();
    }
    
    override public function update(elapsed:Float)
    {
        Conductor.songPosition = FlxG.sound.music.time;
        FlxG.watch.add(FlxG.sound.music, "time", "music time");
        
        super.update(elapsed);
        
        FlxG.collide(player, platformSprite);
        
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
