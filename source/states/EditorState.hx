package states;

import core.EffectManager;
import core.Timeline;
import ui.GameUIInputText;
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
    
    var lastCopiedEvent:Null<TimelineEvent> = null;
    
    var effects:EffectManager;
    
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
        
        createEffects();
        
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
    
    function createEffects()
    {
        effects = new EffectManager();
        effects.add(EffectManager.colorEffect("bg_color", background));
        effects.add(EffectManager.colorEffect("platform_color", platformSprite));
        effects.add(new TrackEffect("camera_zoom", [
            {
                key: "zoom",
                label: "Zoom",
                def: 1,
                step: 0.1,
                min: 0.1,
                decimals: 2
            }
        ], v -> editorGameCamera.zoom = v[0]));
        effects.add(new TrackEffect("camera_angle", [
            {
                key: "angle",
                label: "Angle",
                def: 0,
                step: 5,
                min: -360
            }
        ], v -> editorGameCamera.angle = v[0]));
    }
    
    // as cores do level; se faltarem no meta, usa as cores originais do preview
    function applyBaseColors()
    {
        var bg:Array<Int> = levelData.meta.backgroundColor ?? [103, 132, 211];
        var plat:Array<Int> = levelData.meta.platformColor ?? [175, 227, 248];
        effects.setBase("bg_color", [bg[0], bg[1], bg[2]]);
        effects.setBase("platform_color", [plat[0], plat[1], plat[2]]);
    }
    
    function createEventUI()
    {
        boxCurrentSelectedEvent = new GameUIBox(FlxG.width - 260, 10, 256, cast(FlxG.height - editorTimeline.height) + 24);
        
        setUICamera(boxCurrentSelectedEvent, hudCam);
        add(boxCurrentSelectedEvent);
        
        boxCurrentSelectedEvent.visible = true;
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
                var data:String = Json.stringify(levelData, null, "    ");
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
        if (music != null && music.playing)
            cursorMusicTime = music.time;
            
        editorTimeline.cursorMusicTime = cursorMusicTime;
        Conductor.songPosition = cursorMusicTime;
        
        // arrows and wheel, move the time //
        var dir = (FlxG.keys.pressed.RIGHT || FlxG.mouse.wheel > 0 ? 1 : 0) - (FlxG.keys.pressed.LEFT || FlxG.mouse.wheel < 0 ? 1 : 0);
        if (dir != 0)
        {
            var speed = 1000; // ms por segundo
            if (FlxG.keys.pressed.SHIFT)
                speed = 5000;
            else if (FlxG.keys.pressed.ALT)
                speed = 500;
            setSongTime(cursorMusicTime + dir * speed * elapsed);
        }
        
        // pause or play //
        if (music != null && FlxG.keys.justPressed.SPACE)
        {
            if (music.playing)
                music.pause();
            else
            {
                music.time = cursorMusicTime;
                music.play();
            }
        }
        
        // atalhos não valem enquanto você digita num campo de texto //
        if (GameUIInputText.focusOn == null)
        {
            if (FlxG.keys.justPressed.N)
                createEventAtCursor();
            if (FlxG.keys.justPressed.DELETE)
                deleteSelected();
            if (FlxG.keys.justPressed.C && selectedEvent != null)
                lastCopiedEvent = cloneEvent(selectedEvent);
            if (FlxG.keys.justPressed.V)
                createEventCopyAtCursor();
        }
        
        // select event //
        if (FlxG.mouse.justPressed && FlxG.mouse.viewY >= editorTimeline.y)
        {
            var hit = editorTimeline.eventAt(FlxG.mouse.viewX, FlxG.mouse.viewY);
            if (hit != null)
                selectedEvent = hit;
        }
        
        if (isEventUIDirty && boxCurrentSelectedEvent != null)
            rebuildEventUI();
            
        refreshActors(cursorMusicTime);
        effects.apply(cursorMusicTime);
        
        timeText.text = 'CurrentTime:${Math.round(cursorMusicTime)} | step: $curStep | playing: ${music != null && music.playing} | Copied event: ${lastCopiedEvent?.object}';
        
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
        final type:String = "pulse_square";
        var e:TimelineEvent = {
            time: snapTime(cursorMusicTime),
            object: type,
            lead: 750,
            params: ActorManager.defaultParams(type)
        };
        
        pushEvents(e);
    }
    
    function pushEvents(e:TimelineEvent)
    {
        levelData.events.push(e);
        editorTimeline.addEvent(e);
        rebuildActor(e);
        selectedEvent = e;
        onEventsChanged();
    }
    
    inline function cloneEvent(e:TimelineEvent):TimelineEvent
        return Json.parse(Json.stringify(e));
        
    function createEventCopyAtCursor()
    {
        if (lastCopiedEvent == null)
            return;
            
        var e = cloneEvent(lastCopiedEvent); // um clone novo a cada colagem
        e.time = snapTime(cursorMusicTime);
        pushEvents(e);
    }
    
    function deleteSelected()
    {
        if (selectedEvent == null)
            return;
            
        removeActorOf(selectedEvent);
        editorTimeline.removeEvent(selectedEvent);
        levelData.events.remove(selectedEvent);
        selectedEvent = null;
        onEventsChanged();
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
        
        applyBaseColors();
        effects.rebuild([]);
        
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
            
        applyBaseColors();
        onEventsChanged();
    }
    
    function onEventsChanged()
        effects.rebuild(levelData.events);
        
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
        
        rebuildActor(selectedEvent);
        editorTimeline.relayout();
    }
    
    function rebuildEventUI()
    {
        isEventUIDirty = false;
        clearEventUI();
        
        if (selectedEvent == null)
            return;
            
        boxCurrentSelectedEvent.visible = true;
        
        createFieldWidgets();
        createTypeDropdown();
    }
    
    function clearEventUI()
    {
        for (w in eventWidgets)
        {
            boxCurrentSelectedEvent.remove(w, true);
            if (Std.isOfType(w, GameUIInputText) && GameUIInputText.focusOn == cast(w, GameUIInputText))
                GameUIInputText.focusOn = null;
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
        onEventsChanged();
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
                    box.checked = getValue(f);
                    addWidget(box);
            }
            rowY += ROW_HEIGHT;
        }
    }
    
    function addNumberRow(f:FieldDef, rowY:Float)
    {
        var step:Float = f.step ?? 10;
        var decimals:Int = f.decimals ?? 0;
        var minValue:Float = f.min ?? 0;
        var boxW:Float = boxCurrentSelectedEvent.bg.width;
        
        inline function show():String
            return Std.string(FlxMath.roundDecimal(getValue(f) ?? 0, decimals));
            
        var label:FlxText = new FlxText(8, rowY, 80, f.label, 14);
        var valueText:FlxText = new FlxText(boxW - 130, rowY, 60, show(), 14);
        valueText.alignment = FlxTextAlign.CENTER;
        
        var minus:GameUIButton = new GameUIButton(boxW - 164, rowY, "-", () ->
        {
            setValue(f, FlxMath.roundDecimal(Math.max(minValue, (getValue(f) ?? 0) - step), decimals));
            valueText.text = show();
        }, 32, 24);
        
        var plus:GameUIButton = new GameUIButton(boxW - 64, rowY, "+", () ->
        {
            setValue(f, FlxMath.roundDecimal((getValue(f) ?? 0) + step, decimals));
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
    
    function createTypeDropdown()
    {
        var dd:GameUIDropdownMenu = new GameUIDropdownMenu(8, 8, ActorManager.getActorNames(), (idx:Int, name:String) -> changeEventType(name), 140);
        dd.selectedLabel = selectedEvent.object;
        addWidget(dd);
    }
    
    function changeEventType(newType:String)
    {
        if (selectedEvent == null || selectedEvent.object == newType)
            return;
            
        var old:Dynamic = selectedEvent.params;
        var fresh:Dynamic = ActorManager.defaultParams(newType);
        
        // keep the data that has equal fields
        if (old != null)
            for (k in Reflect.fields(fresh))
                if (Reflect.hasField(old, k))
                    Reflect.setField(fresh, k, Reflect.field(old, k));
                    
        selectedEvent.object = newType;
        selectedEvent.params = fresh;
        if (ActorManager.categoryOf(newType) == EventCategory.Map)
            selectedEvent.lead = 0;
            
        rebuildActor(selectedEvent);
        editorTimeline.refreshEvent(selectedEvent);
        onEventsChanged();
        isEventUIDirty = true;
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
