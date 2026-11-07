package states;

import ui.GameUICheckbox;
import ui.GameUINumericStepper;
import ui.GameUIDropdownMenu;
import haxe.Json;
import sys.io.File;
import ui.GameUIBox;
import flixel.FlxBasic;
import openfl.media.Sound;
import flixel.sound.FlxSound;
import lime.ui.FileDialogType;
import lime.ui.FileDialog;
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
    var hudCam:FlxCamera;
    var editorGameCamera:FlxCamera;
    var editorTimeline:EditorTimeline;
    
    // decoration objects
    var platformSprite:FlxSprite;
    var background:FlxSprite;
    
    // ui //
    var btnLoadLevel:GameUIButton;
    var btnSaveLevel:GameUIButton;
    var btnLoadSong:GameUIButton;
    
    var boxCurrentSelectedEvent:GameUIBox;
    
    var loadedMusicPath:String = "";
    
    var eventWidgets:Array<FlxSprite> = [];
    
    public var selectedEvent(default, set):TimelineEvent;
    
    var isEventUIDirty:Bool = false; // set if the ui need to be rebuilt
    
    var rootFields:Array<FieldDef> = [
        {
            key: "time",
            label: "Time",
            kind: FieldKind.Number,
            target: FieldTarget.Root,
            step: 50
        },
        {
            key: "lead",
            label: "Lead",
            kind: FieldKind.Number,
            target: FieldTarget.Root,
            step: 50,
            defaultValue: 0
        }
    ];
    
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
        ActorManager.randomizePositions = false;
        
        FlxG.cameras.setDefaultDrawTarget(editorGameCamera, true);
        
        activeActors = new FlxTypedGroup<LevelActor>();
        levelActors = new FlxTypedGroup<LevelActor>();
        
        // FlxG.debugger.drawDebug = true;
        
        createPreviewSprites();
        
        // list of all events objects //
        add(activeActors);
        
        editorTimeline = new EditorTimeline();
        editorTimeline.cameras = [hudCam];
        add(editorTimeline);
        
        // timeline for editor //
        resetEditor();
        
        // for debug //
        timeText = new FlxText();
        timeText.size = 18;
        timeText.setPosition(10, FlxG.height - 30);
        timeText.cameras = [hudCam];
        add(timeText);
        
        createEventUI();
        
        rebuildEventUI();
        addUI();
        
        super.create();
    }
    
    function createEventUI()
    {
        boxCurrentSelectedEvent = new GameUIBox(FlxG.width - 260, 10, 256, cast(FlxG.height - editorTimeline.height) + 24);
        
        setUICamera(boxCurrentSelectedEvent, hudCam);
        add(boxCurrentSelectedEvent);
        
        boxCurrentSelectedEvent.visible = true;
        var eventType:GameUIDropdownMenu = new GameUIDropdownMenu(8, 8, ActorManager.getActorNames(), (idx:Int, data:String) -> {});
        
        setUICamera(eventType, hudCam);
        boxCurrentSelectedEvent.add(eventType);
    }
    
    inline function setUICamera(obj:FlxBasic, camera:FlxCamera)
        obj.cameras = [camera];
        
    inline function pauseSong()
        if (FlxG.sound.music != null)
            FlxG.sound.music.pause();
            
    inline function stopSong()
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
            
    function addUI()
    {
        var padding:Float = 8;
        var space:Float = padding;
        
        btnLoadLevel = new GameUIButton(space, 8, "Load Level", () ->
        {
            pauseSong();
            var dialog:FileDialog = new FileDialog();
            dialog.onSelect.add((path:String) -> loadLevel(path));
            dialog.browse(FileDialogType.OPEN, "json", null, "Load Level");
        });
        
        space = padding + btnLoadLevel.x + btnLoadLevel.width;
        
        btnSaveLevel = new GameUIButton(space, 8, "Save Level", () ->
        {
            pauseSong();
            var dialog:FileDialog = new FileDialog();
            dialog.onSelect.add((path:String) ->
            {
                var data:String = Json.stringify(levelData);
                File.saveContent(path, data);
            });
            dialog.browse(FileDialogType.SAVE, "json", null, "Save Level");
        });
        
        space = padding + btnSaveLevel.x + btnSaveLevel.width;
        
        btnLoadSong = new GameUIButton(space, 8, "Load song", () ->
        {
            var dialog:FileDialog = new FileDialog();
            dialog.onSelect.add((path:String) ->
            {
                loadedMusicPath = path;
                FlxG.sound.music = loadAudio(loadedMusicPath);
            });
            
            dialog.browse(FileDialogType.OPEN, "ogg", null, "Load audio");
        });
        
        setUICamera(btnLoadLevel, hudCam);
        setUICamera(btnSaveLevel, hudCam);
        setUICamera(btnLoadSong, hudCam);
        
        add(btnLoadLevel);
        add(btnSaveLevel);
        add(btnLoadSong);
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
                
            if (isEventUIDirty && boxCurrentSelectedEvent != null)
                rebuildEventUI();
                
            // select event //
            if (FlxG.mouse.justPressed && FlxG.mouse.viewY >= editorTimeline.y)
            {
                var hit = editorTimeline.eventAt(FlxG.mouse.viewX, FlxG.mouse.viewY);
                if (hit != null)
                {
                    selectedEvent = hit;
                    isEventUIDirty = true;
                    trace("evento selecionado " + hit.object);
                }
            }
            
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
    
    inline function snapTime(t:Float):Float
        return Math.round(t / Conductor.stepCrochet) * Conductor.stepCrochet;
        
    function createEventAtCursor()
    {
        var type:String = "pulse_square";
        var e:TimelineEvent = {
            time: snapTime(cursorMusicTime),
            object: type,
            lead: 750,
            params: ActorManager.defaultParams(type)
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
    
    function resetEditor()
    {
        // if there's any music playing, stop now //
        stopSong();
        
        // we set the level data as empty level
        levelData = Level.emptyLevel();
        
        // clear the selected one //
        selectedEvent = null;
        
        // we clear the song preloaded cuz we destroy it too //
        loadedMusicPath = "";
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.destroy();
            
        // and update the timeline to remove all the sprites//
        editorTimeline.destroyEventSprites();
        
        // predefined bpm //
        Conductor.changeBPM(100);
        
        // we clear both groups just to make sure no actor will last //
        activeActors.clear();
        levelActors.clear();
        
        // reset colors //
        platformSprite.color = FlxColor.WHITE;
        background.color = FlxColor.WHITE;
    }
    
    inline function loadAudio(path:String)
    {
        var rawSoundData:Sound = Sound.fromFile(path);
        var snd:FlxSound = FlxG.sound.create(rawSoundData);
        return snd;
    }
    
    // this function will take the params and will load and update the editor state //
    function loadLevel(path:String)
    {
        resetEditor();
        
        levelData = Level.loadJsonData(path);
        Conductor.changeBPM(levelData.meta.bpm ?? 110);
        
        editorTimeline.setEvents(levelData.events);
        
        if (levelData?.editorMeta?.audioPath != null && levelData?.editorMeta?.audioPath != "")
        {
            loadedMusicPath = levelData?.editorMeta?.audioPath;
            FlxG.sound.music = loadAudio(loadedMusicPath);
        }
        
        for (a in ActorManager.createAll(levelData))
            levelActors.add(a);
            
        final bgColor:Array<Int> = levelData.meta.backgroundColor;
        background.color = FlxColor.fromRGB(bgColor[0], bgColor[1], bgColor[2]);
        
        final platColor:Array<Int> = levelData.meta.platformColor;
        platformSprite.color = FlxColor.fromRGB(platColor[0], platColor[1], platColor[2]);
    }
    
    function getParam(key:String):Dynamic
    {
        if (selectedEvent == null || selectedEvent.params == null)
            return null;
        return Reflect.field(selectedEvent.params, key);
    }
    
    function setParam(key:String, value:Dynamic)
    {
        if (selectedEvent == null)
            return;
        if (selectedEvent.params == null)
            selectedEvent.params = {};
            
        Reflect.setField(selectedEvent.params, key, value);
        
        rebuildActor(selectedEvent); // o ator guarda cópias dos valores
        editorTimeline.relayout(); // duration ou outro podem ter mudado a largura
    }
    
    function rebuildEventUI()
    {
        clearEventUI();
        
        // sem evento selecionado, o painel fica vazio
        if (selectedEvent == null)
            return;
            
        boxCurrentSelectedEvent.visible = true;
        
        createFieldWidgets();
        
        isEventUIDirty = false;
    }
    
    function clearEventUI()
    {
        for (w in eventWidgets)
        {
            boxCurrentSelectedEvent.remove(w, true);
            w.destroy();
        }
        eventWidgets = [];
        boxCurrentSelectedEvent.visible = false;
    }
    
    function holderOf(f:FieldDef):Dynamic
    {
        if (selectedEvent == null)
            return null;
        if (f.target == FieldTarget.Root)
            return selectedEvent;
        if (selectedEvent.params == null)
            selectedEvent.params = {};
        return selectedEvent.params;
    }
    
    function getValue(f:FieldDef):Dynamic
    {
        var holder = holderOf(f);
        var v:Dynamic = holder == null ? null : Reflect.field(holder, f.key);
        return v ?? f.defaultValue;
    }
    
    function setValue(f:FieldDef, value:Dynamic)
    {
        var holder = holderOf(f);
        if (holder == null)
            return;
            
        Reflect.setField(holder, f.key, value);
        
        rebuildActor(selectedEvent); // o ator guarda cópias dos valores
        editorTimeline.relayout(); // time, duration ou outro mudam a largura e a linha
    }
    
    function createFieldWidgets()
    {
        var ROW_HEIGHT:Float = 32;
        var rowY:Float = 8 + ROW_HEIGHT + 8; // abaixo do dropdown
        
        for (f in rootFields.concat(ActorManager.fieldsOf(selectedEvent.object)))
        {
            switch (f.kind)
            {
                case Number:
                    addNumberRow(f, rowY);
                case Checkbox:
                    var box:GameUICheckbox = new GameUICheckbox(8, rowY, f.label, null, (checked:Bool) -> setValue(f, checked));
                    addWidget(box);
            }
            rowY += ROW_HEIGHT;
        }
    }
    
    function addNumberRow(f:FieldDef, rowY:Float)
    {
        var step:Float = f.step ?? 10;
        var boxW:Float = boxCurrentSelectedEvent.bg.width;
        
        inline function show():String
            return Std.string(Math.round(getValue(f) ?? 0));
            
        var label:FlxText = new FlxText(8, rowY, 80, f.label, 14);
        var valueText:FlxText = new FlxText(boxW - 130, rowY, 60, show(), 14);
        valueText.alignment = FlxTextAlign.CENTER;
        
        var minus:GameUIButton = new GameUIButton(boxW - 164, rowY, "-", () ->
        {
            setValue(f, Math.max(0, (getValue(f) ?? 0) - step));
            valueText.text = show();
        }, 32, 24);
        
        var plus:GameUIButton = new GameUIButton(boxW - 64, rowY, "+", () ->
        {
            setValue(f, (getValue(f) ?? 0) + step);
            valueText.text = show();
        }, 32, 24);
        
        addWidget(label);
        addWidget(valueText);
        addWidget(minus);
        addWidget(plus);
    }
    
    function addWidget(w:FlxSprite)
    {
        setUICamera(w, hudCam);
        boxCurrentSelectedEvent.add(w);
        eventWidgets.push(w);
    }
    
    function set_selectedEvent(v:TimelineEvent):TimelineEvent
    {
        selectedEvent = v;
        isEventUIDirty = true;
        if (editorTimeline != null)
            editorTimeline.setSelected(v);
        return v;
    }
    
    public function UIEvent(id:String, sender:Dynamic) {}
}
