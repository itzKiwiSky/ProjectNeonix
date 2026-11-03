package states;

import openfl.media.Sound;
import flixel.sound.FlxSound;
import lime.ui.FileDialogType;
import lime.ui.FileDialog;
import openfl.display.Loader;
import openfl.events.Event;
import openfl.net.FileReference;
import ui.GameUIButton;
import editor.EditorTimeline;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.FlxSprite;
import core.ActorManager;
import core.level.Level;
import flixel.math.FlxMath;
import core.LevelActor;
import flixel.group.FlxGroup.FlxTypedGroup;
import core.Conductor;
import flixel.FlxG;
import flixel.text.FlxText;
import core.MusicSyncedState;
import core.Timeline.TimelineEvent;
import ui.GameUIEventController.EngineUIEvent;

class EditorState extends MusicSyncedState implements EngineUIEvent
{
    var timeText:FlxText;
    
    var activeActors:FlxTypedGroup<LevelActor>; // Only show the objects that are inside the time window
    var levelActors:FlxTypedGroup<LevelActor>; // all level actors
    var cursorMusicTime:Float = 0; // the music cursor, the truth source
    var levelData:LevelData;
    var selectedEvent:TimelineEvent;
    var hudCam:FlxCamera;
    var editorGameCamera:FlxCamera;
    var editorTimeline:EditorTimeline;
    
    // decoration objects
    var platformSprite:FlxSprite;
    var background:FlxSprite;
    
    // ui //
    var btnLoadLevel:GameUIButton;
    
    override function create()
    {
        persistentDraw = persistentUpdate = true;
        
        cameraWorldConfig();
        
        hudCam = new FlxCamera();
        hudCam.bgColor = FlxColor.TRANSPARENT;
        
        editorGameCamera = new FlxCamera();
        editorGameCamera.bgColor = FlxColor.BLACK;
        editorGameCamera.visible = false;
        
        FlxG.cameras.add(editorGameCamera, true);
        FlxG.cameras.add(hudCam, false);
        
        ActorManager.init();
        
        FlxG.cameras.setDefaultDrawTarget(editorGameCamera, true);
        
        activeActors = new FlxTypedGroup<LevelActor>();
        levelActors = new FlxTypedGroup<LevelActor>();
        
        // FlxG.debugger.drawDebug = true;
        
        createPreviewSprites();
        
        // list of all events objects //
        add(activeActors);
        
        // timeline for editor //
        resetEditor();
        
        editorTimeline = new EditorTimeline();
        editorTimeline.setEvents(levelData.events);
        editorTimeline.cameras = [hudCam];
        add(editorTimeline);
        
        // for debug //
        timeText = new FlxText();
        timeText.size = 18;
        timeText.setPosition(10, FlxG.height - 30);
        timeText.cameras = [hudCam];
        add(timeText);
        
        addUI();
        
        super.create();
    }
    
    function addUI()
    {
        btnLoadLevel = new GameUIButton(8, 8, "Load Level", () ->
        {
            openLevelDialog();
        });
        
        add(btnLoadLevel);
    }
    
    function cameraWorldConfig()
    {
        FlxG.worldBounds.set(0, 0, FlxG.width * 2, FlxG.height * 1.5);
    }
    
    // will create the platform and the spritebg //
    function createPreviewSprites()
    {
        platformSprite = new FlxSprite();
        platformSprite.loadGraphic("assets/images/game/platform.png");
        platformSprite.updateHitbox();
        platformSprite.y = (FlxG.height - platformSprite.height * 0.5) + 64;
        platformSprite.immovable = true;
        platformSprite.screenCenter(X);
        platformSprite.color = 0xFFAFE3F8;
        
        background = new FlxSprite();
        background.loadGraphic("assets/images/backgrounds/game_bg07.png");
        background.setGraphicSize(FlxG.width * 1.2, FlxG.height * 1.2);
        background.updateHitbox();
        background.screenCenter();
        background.color = 0xFF6784D3;
        
        add(background);
        add(platformSprite);
    }
    
    override function update(elapsed:Float)
    {
        var music:FlxSound = FlxG.sound.music;
        if (music != null)
            if (music.playing)
                cursorMusicTime = music.time;
                
        editorTimeline.cursorMusicTime = cursorMusicTime;
        
        // arrows, move the time //
        var dir = (FlxG.keys.pressed.RIGHT ? 1 : 0) - (FlxG.keys.pressed.LEFT ? 1 : 0);
        if (dir != 0)
        {
            var speed = FlxG.keys.pressed.SHIFT ? 5000 : 1000; // ms por segundo
            setSongTime(cursorMusicTime + dir * speed * elapsed);
        }
        
        // pause or stop the music //
        if (music != null)
        {
            if (FlxG.keys.justPressed.SPACE)
                if (music.playing)
                    music.pause();
                else
                {
                    music.time = cursorMusicTime;
                    music.play();
                }
                
            // create event //
            if (FlxG.keys.justPressed.N)
                createEventAtCursor();
                
            // destroy event//
            if (FlxG.keys.justPressed.DELETE)
                deleteSelected();
                
            Conductor.songPosition = cursorMusicTime;
            refreshActors(cursorMusicTime);
            timeText.text = 'CurrentTime:${Math.round(cursorMusicTime)} | step: $curStep | playing: ${music.playing}';
        }
        
        super.update(elapsed);
    }
    
    // the only way to move on the time //
    function setSongTime(time:Float)
    {
        if (FlxG.sound.music == null)
            return;
            
        cursorMusicTime = FlxMath.bound(time, 0, FlxG.sound.music.length);
        
        if (FlxG.sound.music.playing)
            FlxG.sound.music.time = cursorMusicTime;
            
        Conductor.songPosition = cursorMusicTime;
    }
    
    // decide who will appear on the activeActors //
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
    
    function snapTime(t:Float):Float
        return Math.round(t / Conductor.stepCrochet) * Conductor.stepCrochet;
        
    function createEventAtCursor()
    {
        var e:TimelineEvent = {
            time: snapTime(cursorMusicTime),
            object: "pulse_square",
            lead: 750,
            params: {
                x: FlxG.width * 0.5,
                y: FlxG.height * 0.5,
                duration: 1250,
                outro: 500
            }
        };
        
        levelData.events.push(e);
        editorTimeline.addEvent(e);
        rebuildActor(e);
        selectedEvent = e;
    }
    
    function deleteSelected()
    {
        if (selectedEvent == null)
            return;
            
        removeActorOf(selectedEvent);
        editorTimeline.removeEvent(selectedEvent);
        levelData.events.remove(selectedEvent);
        selectedEvent = null;
    }
    
    // the actor that hold the values //
    function rebuildActor(e:TimelineEvent)
    {
        removeActorOf(e);
        
        var actor = ActorManager.createActor(e);
        if (actor != null)
            levelActors.add(actor);
    }
    
    function removeActorOf(e:TimelineEvent)
    {
        for (a in levelActors.members)
        {
            if (a != null && a.event == e)
            {
                activeActors.remove(a, true);
                levelActors.remove(a, true);
                a.destroy();
                return;
            }
        }
    }
    
    function openLevelDialog()
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.pause(); // o diálogo congela o jogo, melhor pausar antes
            
        var dialog = new FileDialog();
        dialog.onSelect.add((path:String) -> loadLevel(path));
        dialog.onCancel.add(() -> trace("cancelado"));
        dialog.browse(FileDialogType.OPEN_DIRECTORY, null, null, "Load level");
    }
    
    function resetEditor()
    {
        // if there's any music playing, stop now //
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
            
        levelData = Level.emptyLevel();
        
        // predefined bpm //
        Conductor.changeBPM(100);
        
        // we clear both groups just to make sure no actor will last //
        activeActors.clear();
        levelActors.clear();
        
        // reset colors //
        platformSprite.color = FlxColor.WHITE;
        background.color = FlxColor.WHITE;
    }
    
    // this function will take the params and will load and update the editor state //
    function loadLevel(path:String)
    {
        resetEditor();
        
        trace(path);
        
        levelData = Level.loadJsonData(path + "/data.json");
        Conductor.changeBPM(levelData.meta.bpm ?? 110);
        
        var rawSoundData:Sound = Sound.fromFile(path + "/audio.ogg");
        
        FlxG.sound.music = FlxG.sound.create(rawSoundData);
        FlxG.sound.music.pause(); // o editor começa pausado
        
        editorTimeline.setEvents(levelData.events);
        
        for (a in ActorManager.createAll(levelData))
            levelActors.add(a);
            
        final bgColor:Array<Int> = levelData.meta.backgroundColor;
        background.color = FlxColor.fromRGB(bgColor[0], bgColor[1], bgColor[2]);
        
        final platColor:Array<Int> = levelData.meta.platformColor;
        platformSprite.color = FlxColor.fromRGB(platColor[0], platColor[1], platColor[2]);
    }
    
    public function UIEvent(id:String, sender:Dynamic) {}
}
