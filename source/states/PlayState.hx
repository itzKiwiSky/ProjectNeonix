package states;

import flixel.util.FlxColor;
import openfl.media.Sound;
import haxe.io.Path;
import core.Paths;
import core.ActorManager;
import core.Conductor;
import core.LevelRuntime;
import core.MusicSyncedState;
import core.level.Level;
import flixel.FlxG;
import flixel.FlxSprite;
import objects.Player;

class PlayState extends MusicSyncedState
{
    public static var currentSong:String = "";
    public static var levelPath:String = "assets/data/game.json"; // quem abrir o PlayState escolhe a fase aqui
    
    var player:Player;
    var platformSprite:FlxSprite;
    var background:FlxSprite;
    var runtime:LevelRuntime;
    
    override public function create()
    {
        persistentDraw = persistentUpdate = true;
        
        ActorManager.init();
        ActorManager.randomizePositions = true; // o editor desliga; o jogo sempre liga
        
        FlxG.worldBounds.set(0, 0, FlxG.width * 2, FlxG.height * 1.5);
        // FlxG.debugger.drawDebug = true;
        
        platformSprite = new FlxSprite();
        platformSprite.loadGraphic("assets/images/game/platform.png");
        platformSprite.updateHitbox();
        platformSprite.y = (FlxG.height - platformSprite.height * 0.5) + 64;
        platformSprite.immovable = true;
        platformSprite.screenCenter(X);
        
        background = new FlxSprite();
        background.makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
        background.updateHitbox();
        background.screenCenter();
        
        player = new Player();
        player.screenCenter();
        
        // os efeitos precisam existir antes do load, é o que registra bg_color, camera_zoom...
        runtime = new LevelRuntime(background, platformSprite, FlxG.camera);
        
        add(background);
        add(player);
        add(platformSprite);
        add(runtime.active);
        
        // updateBackground(runtime.data.meta.backgroundID);
        
        var level:LevelData = Level.loadJsonData(levelPath);
        runtime.load(level);
        Conductor.changeBPM(level.meta.bpm ?? 110);
        
        updateBackground(level.meta.backgroundID);
        
        var ref:String = Paths.songRef(level.meta.songFilename);
        var sound:Sound = Paths.loadSong(ref, Path.directory(levelPath));
        if (sound != null)
        {
            FlxG.sound.music = FlxG.sound.create(sound);
            FlxG.sound.music.volume = 0.2;
            FlxG.sound.music.play();
        }
        
        super.create();
    }
    
    function updateBackground(id:Int)
    {
        background.loadGraphic('assets/images/backgrounds/game_bg${StringTools.lpad(Std.string(id), "0", 2)}.png');
        background.setGraphicSize(FlxG.width * 1.2, FlxG.height * 1.2);
        background.updateHitbox();
        background.screenCenter();
    }
    
    override public function update(elapsed:Float)
    {
        Conductor.songPosition = FlxG.sound.music.time;
        FlxG.watch.add(FlxG.sound.music, "time", "music time");
        
        runtime.update(Conductor.songPosition);
        
        super.update(elapsed);
        
        FlxG.collide(player.hitbox, platformSprite);
        
        if (runtime.hits(player.hitbox))
            trace("hit!");
            
        if (FlxG.keys.justPressed.SEVEN)
        {
            if (FlxG.sound.music != null)
                FlxG.sound.music.stop();
            FlxG.switchState(() -> new EditorState());
        }
        
        player.updatePlayer(elapsed);
    }
    
    override function onBeatHit() {}
}
