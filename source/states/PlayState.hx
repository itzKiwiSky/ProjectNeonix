package states;

import objects.core.Player;
import states.substates.GameOverSubstate;
import core.shaders.GrayscaleShader;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.filters.ShaderFilter;
import core.shaders.GlowShader;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import openfl.media.Sound;
import haxe.io.Path;
import core.Paths;
import core.ActorManager;
import core.Conductor;
import core.LevelRuntime;
import core.MusicSyncedState;
import core.level.Level;
import core.level.Level.LevelData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import ui.GameUIButton;

class PlayState extends MusicSyncedState
{
    public static var levelPath:String = "assets/data/retro_blast.json"; // quem abrir o PlayState escolhe a fase aqui
    
    var playtestData:Null<LevelData>;
    var playtestMode:Bool = false;
    var gameplayStopped:Bool = false;
    var music:Null<FlxSound>;
    var playtestMusicAsset:Null<Sound>;
    var player:Player;
    var platformSprite:FlxSprite;
    var background:FlxSprite;
    var runtime:LevelRuntime;
    var gameCam:FlxCamera;
    var hudCam:FlxCamera;
    var returnButton:GameUIButton;
    var cameraMotionTime:Float = 0;
    
    static inline var CAMERA_SWAY_X:Float = 7;
    static inline var CAMERA_SWAY_Y:Float = 4;
    
    var grayscale:GrayscaleShader;

    public function new(?playtestData:LevelData, ?playtestMusicAsset:Sound)
    {
        super();
        this.playtestData = playtestData;
        this.playtestMusicAsset = playtestMusicAsset;
        playtestMode = playtestData != null;
    }
    
    override public function create()
    {
        persistentDraw = persistentUpdate = true;
        
        ActorManager.init();
        ActorManager.randomizePositions = true; // o jogo sempre respeita Random X/Y
        
        FlxG.worldBounds.set(-FlxG.width * 0.5, -FlxG.height * 0.5, FlxG.width * 2, FlxG.height * 1.5);
        // FlxG.debugger.drawDebug = true
        
        gameCam = new FlxCamera();
        FlxG.cameras.add(gameCam);
        FlxG.cameras.setDefaultDrawTarget(gameCam, true);
        if (playtestMode)
        {
            hudCam = new FlxCamera();
            hudCam.bgColor = FlxColor.TRANSPARENT;
            FlxG.cameras.add(hudCam, false);
        }
        
        platformSprite = new FlxSprite();
        platformSprite.loadGraphic("assets/images/game/platform.png");
        platformSprite.updateHitbox();
        platformSprite.y = (FlxG.height - platformSprite.height * 0.5) + 64;
        platformSprite.immovable = true;
        platformSprite.screenCenter(X);
        
        background = new FlxSprite();
        background.makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
        background.updateHitbox();
        background.scrollFactor.set(0.5, 0.5);
        background.screenCenter();
        
        player = new Player();
        player.screenCenter();
        
        // os efeitos precisam existir antes do load, é o que registra bg_color, camera_zoom...
        runtime = new LevelRuntime(background, platformSprite, gameCam);
        
        add(background);
        add(player);
        add(platformSprite);
        add(runtime.active);

        if (playtestMode)
        {
            returnButton = new GameUIButton(8, 8, "Back to editor", returnToEditor, 144, 28);
            returnButton.cameras = [hudCam];
            returnButton.bg.cameras = [hudCam];
            returnButton.text.cameras = [hudCam];
            returnButton.broadcastButtonEvent = false;
            add(returnButton);
        }
        
        reloadLevelData();
        
        gameCam.setScrollBoundsRect(FlxG.worldBounds.x, FlxG.worldBounds.y, FlxG.worldBounds.width, FlxG.worldBounds.height, true);
        gameCam.follow(player, FlxCameraFollowStyle.TOPDOWN, 0.5);
        var bloomShader = new GlowShader(4.0, 2.5, 0.65);
        grayscale = new GrayscaleShader();
        // gameCam.filters = [new ShaderFilter(bloomShader), new ShaderFilter(grayscale)];
        // grayscale.strength = 0;
        
        player.onKill = () ->
        {
            if (playtestMode)
            {
                gameplayStopped = true;
                player.active = false;
                runtime.active.active = false;
                if (music != null)
                    music.stop();
                return;
            }

            if (music == null)
            {
                openSubState(new GameOverSubstate());
                return;
            }

            FlxTween.tween(music, {pitch: 0}, 2, {
                ease: FlxEase.sineOut,
                type: ONESHOT,
            }).onComplete = (t:FlxTween) ->
                openSubState(new GameOverSubstate());
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
    
    function reloadLevelData()
    {
        var level:LevelData = playtestData == null ? Level.loadJsonData(levelPath) : playtestData;
        runtime.load(level);
        Conductor.changeBPM(level.meta.bpm ?? 110);
        
        if (level.meta.backgroundID > 0)
            updateBackground(level.meta.backgroundID);

        if (playtestMode)
        {
            if (playtestMusicAsset != null)
            {
                music = FlxG.sound.create(playtestMusicAsset);
                music.volume = 0.2;
                music.play();
            }
            return;
        }
        
        var ref:String = Paths.songRef(level.meta.songFilename);
        var sound:Sound = Paths.loadSong(ref, Path.directory(levelPath));
        if (sound != null)
        {
            music = FlxG.sound.create(sound);
            music.volume = 0.2;
            music.play();
        }
    }
    
    override public function update(elapsed:Float)
    {
        if (playtestMode && gameplayStopped)
        {
            super.update(elapsed);
            return;
        }

        if (music != null)
        {
            Conductor.songPosition = music.time;
            FlxG.watch.add(music, "time", "music time");
        }
        else
            Conductor.songPosition = 0;
        
        runtime.update(Conductor.songPosition);
        
        gameCam.targetOffset.set(Math.sin(elapsed * 0.45) * CAMERA_SWAY_X, Math.sin(elapsed * 0.32) * CAMERA_SWAY_Y);
        
        super.update(elapsed);
        
        FlxG.collide(player.hitbox, platformSprite);
        
        runtime.collide(player.hitbox);
        
        if (runtime.hits(player.hitbox))
            player.testHit();
            
        if (FlxG.keys.justPressed.SEVEN)
        {
            if (music != null)
                music.stop();
            if (playtestMode)
                returnToEditor();
            else
                FlxG.switchState(() -> new EditorState());
        }
        
        player.updatePlayer(elapsed);
    }

    function returnToEditor()
    {
        destroyMusic();
        FlxG.switchState(() -> new EditorState());
    }

    function destroyMusic()
    {
        if (music != null)
        {
            music.stop();
            music.destroy();
            music = null;
        }
    }

    override public function destroy()
    {
        destroyMusic();
        super.destroy();
    }
    
    override function onBeatHit() {}
}
