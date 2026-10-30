package states;

import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.FlxSprite;
import objects.ActorManager;
import core.level.Level;
import flixel.math.FlxMath;
import objects.LevelActor;
import flixel.group.FlxGroup.FlxTypedGroup;
import core.Conductor;
import flixel.FlxG;
import flixel.text.FlxText;
import core.MusicSyncedState;

class EditorState extends MusicSyncedState implements ui.GameUIEventController.EngineUIEvent
{
    var timeText:FlxText;
    var activeActors:FlxTypedGroup<LevelActor>; // só os que estão dentro da janela de tempo
    var levelActors:FlxTypedGroup<LevelActor>; // todos os atores (nunca é adicionado ao state)
    var cursorMusicTime:Float = 0; // o cursor: única fonte de verdade do tempo
    
    var hudCam:FlxCamera;
    var editorGameCamera:FlxCamera;
    
    // decoration objects
    var platformSprite:FlxSprite;
    var background:FlxSprite;
    
    override function create()
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
            
        persistentDraw = persistentUpdate = true;
        
        hudCam = new FlxCamera();
        editorGameCamera = new FlxCamera();
        
        FlxG.cameras.add(hudCam);
        FlxG.cameras.add(editorGameCamera);
        
        ActorManager.init();
        
        activeActors = new FlxTypedGroup<LevelActor>();
        levelActors = new FlxTypedGroup<LevelActor>();
        
        final level:LevelData = Level.loadJsonData("game.json");
        for (a in ActorManager.createAll(level))
            levelActors.add(a);
            
        platformSprite = new FlxSprite();
        platformSprite.loadGraphic("assets/images/game/platform.png");
        platformSprite.updateHitbox();
        platformSprite.y = (FlxG.height - platformSprite.height * 0.5) + 64;
        platformSprite.immovable = true;
        platformSprite.screenCenter(X);
        platformSprite.color = 0xFFAFE3F8;
        
        background = new FlxSprite();
        background.loadGraphic("assets/images/backgrounds/game_bg07.png");
        background.updateHitbox();
        background.screenCenter();
        background.color = 0xFF6784D3;
        
        add(background);
        add(platformSprite);
        add(activeActors);
        
        timeText = new FlxText();
        timeText.size = 35;
        timeText.setPosition(32, 32);
        timeText.camera = hudCam;
        add(timeText);
        
        FlxG.sound.playMusic("assets/music/life_is_game_kay.ogg");
        FlxG.sound.music.pause(); // o editor começa pausado
        
        Conductor.changeBPM(110);
        
        super.create();
    }
    
    override function update(elapsed:Float)
    {
        var music = FlxG.sound.music;
        
        if (music.playing)
            cursorMusicTime = music.time;
            
        // setas: movem o cursor (shift = mais rápido)
        var dir = (FlxG.keys.pressed.RIGHT ? 1 : 0) - (FlxG.keys.pressed.LEFT ? 1 : 0);
        if (dir != 0)
        {
            var speed = FlxG.keys.pressed.SHIFT ? 5000 : 1000; // ms por segundo
            setSongTime(cursorMusicTime + dir * speed * elapsed);
        }
        
        if (FlxG.keys.justPressed.SPACE)
            if (music.playing)
                music.pause();
            else
            {
                music.time = cursorMusicTime;
                music.play();
            }
            
        Conductor.songPosition = cursorMusicTime;
        refreshActors(cursorMusicTime);
        
        super.update(elapsed);
        
        timeText.text = 'CurrentTime:${Math.round(cursorMusicTime)} | step: $curStep | playing: ${music.playing}';
    }
    
    override function onBeatHit() {}
    
    // único caminho para pular no tempo
    function setSongTime(time:Float)
    {
        cursorMusicTime = FlxMath.bound(time, 0, FlxG.sound.music.length);
        
        if (FlxG.sound.music.playing)
            FlxG.sound.music.time = cursorMusicTime;
            
        Conductor.songPosition = cursorMusicTime;
        refreshActors(cursorMusicTime);
    }
    
    // decide quem entra e quem sai de activeActors para o tempo dado
    function refreshActors(time:Float)
    {
        for (a in levelActors)
        {
            if (a.isInside(time))
            {
                if (!activeActors.members.contains(a))
                    activeActors.add(a);
            }
            else if (activeActors.members.contains(a))
            {
                activeActors.remove(a);
                a.phase = null;
            }
        }
    }
    
    public function UIEvent(id:String, sender:Dynamic) {}
}
