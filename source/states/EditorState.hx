package states;

import core.utils.Paths;
import ui.GameUINumericStepper;
import haxe.io.Path;
import core.LevelRuntime;
import core.managers.EffectManager;
import ui.GameUIInputText;
import ui.GameUICheckbox;
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
import core.managers.ActorManager;
import core.level.Level;
import flixel.math.FlxMath;
import core.Conductor;
import flixel.FlxG;
import flixel.text.FlxText;
import core.MusicSyncedState;
import core.managers.Timeline.TimelineEvent;
import ui.GameUIEventController.EngineUIEvent;

typedef EditorPlaytestSession =
{
    var levelData:LevelData;
    var currentLevelDir:String;
    var loadedMusicPath:String;
    var cursorMusicTime:Float;
    var musicTime:Float;
    var musicVolume:Float;
    var musicWasPlaying:Bool;
    var musicAsset:Null<Sound>;
    var selectedEvent:Null<TimelineEvent>;
    var selectedEvents:Array<TimelineEvent>;
}

class EditorState extends MusicSyncedState implements EngineUIEvent
{
    public static var playtestSession:Null<EditorPlaytestSession>;
    
    var timeText:FlxText;
    
    var runtime:LevelRuntime; // atores em janela de tempo + efeitos: o mesmo código do jogo
    var cursorMusicTime:Float = 0; // the music cursor, the truth source
    var music:Null<FlxSound>;
    var musicAsset:Null<Sound>;
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
    var boxConfig:GameUIBox;
    
    var loadedMusicPath:String = "";
    
    var eventWidgets:Array<FlxSprite> = [];
    var eventWidgetBaseYs:Map<FlxSprite, Float> = [];
    var levelDataWidgets:Array<FlxSprite> = [];
    
    public var selectedEvent(default, null):Null<TimelineEvent>;
    
    var selectedEvents:Array<TimelineEvent> = [];
    
    var isEventUIDirty:Bool = false; // set if the ui need to be rebuilt
    
    var lastCopiedEvents:Array<TimelineEvent> = [];
    var eventPanelScroll:Float = 0;
    var eventPanelContentHeight:Float = 0;
    
    var currentLevelDir:String = ""; // pasta do level aberto; vazio enquanto não foi salvo ou aberto
    
    var rootFields:Array<FieldDef> = [
        {
            key: "time",
            label: "Time",
            kind: FieldKind.Number,
            target: FieldTarget.Root,
            step: 10
        },
        {
            key: "lead",
            label: "Lead",
            kind: FieldKind.Number,
            target: FieldTarget.Root,
            step: 10,
            defaultValue: 0
        }
    ];
    
    override function create()
    {
        persistentDraw = persistentUpdate = true;
        
        cameraWorldConfig();
        
        hudCam = new FlxCamera();
        hudCam.bgColor = FlxColor.TRANSPARENT;
        
        editorGameCamera = FlxG.camera; // a câmera padrão passa a ser a do jogo
        editorGameCamera.bgColor = FlxColor.BLACK;
        
        FlxG.cameras.add(hudCam, false);
        
        ActorManager.init();
        ActorManager.randomizePositions = false; // as opções Random X/Y também valem no preview
        
        FlxG.cameras.setDefaultDrawTarget(editorGameCamera, true);
        
        ActorManager.defaultCamera = editorGameCamera;
        
        // FlxG.debugger.drawDebug = true;
        
        createPreviewSprites();
        
        // os efeitos precisam existir antes de qualquer load: é o que registra bg_color, camera_zoom...
        runtime = new LevelRuntime(background, platformSprite, editorGameCamera);
        add(runtime.active);
        
        editorTimeline = new EditorTimeline();
        editorTimeline.cameras = [hudCam];
        add(editorTimeline);
        
        // timeline for editor //
        if (playtestSession == null)
            resetEditor();
        else
        {
            var session = playtestSession;
            playtestSession = null;
            restorePlaytestSession(session);
        }
        
        // for debug //
        timeText = new FlxText();
        timeText.size = 18;
        timeText.setPosition(10, FlxG.height - 30);
        timeText.cameras = [hudCam];
        add(timeText);
        
        createEventUI();
        createLevelConfigUI();
        
        rebuildLevelUI();
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
    }
    
    function createLevelConfigUI()
    {
        boxConfig = new GameUIBox(0, 0, 480, FlxG.height - 128);
        boxConfig.screenCenter();
        setUICamera(boxConfig, hudCam);
        boxConfig.visible = boxConfig.active = false; // abre pelo botão "Level settings"
        add(boxConfig);
    }
    
    // invisível não basta: o box continuaria recebendo clique
    function toggleLevelSettings()
    {
        var open = !boxConfig.visible;
        boxConfig.visible = boxConfig.active = open;
    }
    
    function addLevelWidget(w:FlxSprite)
    {
        setUICamera(w, hudCam);
        boxConfig.add(w);
        levelDataWidgets.push(w);
    }
    
    function clearLevelUI()
    {
        for (w in levelDataWidgets)
        {
            boxConfig.remove(w, true);
            if (Std.isOfType(w, GameUIInputText) && GameUIInputText.focusOn == cast(w, GameUIInputText))
                GameUIInputText.focusOn = null;
            w.destroy();
        }
        levelDataWidgets = [];
    }
    
    // recria o painel a partir do levelData; chame depois de carregar ou criar um level
    function rebuildLevelUI()
    {
        clearLevelUI();
        
        // level antigo sem cores no meta: elas viram explícitas, assim o arquivo salvo já carrega o estado inicial
        var meta:LevelMetaData = levelData.meta;
        meta.backgroundColor = meta.backgroundColor ?? LevelRuntime.DEFAULT_BG.copy();
        meta.platformColor = meta.platformColor ?? LevelRuntime.DEFAULT_PLATFORM.copy();
        meta.actorsColor = meta.actorsColor ?? LevelRuntime.DEFAULT_ACTORS.copy();
        meta.songStarting = meta.songStarting ?? 0;
        meta.songEnding = meta.songEnding ?? -1;
        runtime.applyMeta();
        
        var rowY:Float = 16;
        addLabeledInputText(rowY, "Title", meta.title, (t:String) -> levelData.meta.title = t);
        rowY += 36;
        addLabeledInputText(rowY, "Artist", meta.artist, (t:String) -> levelData.meta.artist = t);
        rowY += 36;
        addLabeledInputText(rowY, "Song", meta.songFilename, (t:String) ->
        {
            levelData.meta.songFilename = t;
            loadSongFromMeta(); // só troca quando o nome existe; enquanto você digita, falha em silêncio
        });
        rowY += 36;
        addLabeledNumericStepper(rowY, "BPM", 1, meta.bpm, 0, 999, 2, (v:Float) ->
        {
            levelData.meta.bpm = v;
            if (v > 0)
                Conductor.changeBPM(v);
        });
        rowY += 52;
        addLabeledNumericStepper(rowY, "Song start (ms)", 100, meta.songStarting, 0, 9999999, 0, (v:Float) -> levelData.meta.songStarting = v);
        rowY += 36;
        addLabeledNumericStepper(rowY, "Song end (ms)", 100, meta.songEnding, -9999999, 9999999, 0, (v:Float) -> levelData.meta.songEnding = v);
        rowY += 52;
        addColorRow("Background", meta.backgroundColor, rowY);
        rowY += 36;
        addColorRow("Platform", meta.platformColor, rowY);
        rowY += 36;
        addColorRow("Actors", meta.actorsColor, rowY);
    }
    
    function addLabeledInputText(posY:Float, text:String = "", initial:String = "", changed:String->Void)
    {
        addLevelWidget(new FlxText(8, posY, 100, text, 18));
        
        var input:GameUIInputText = new GameUIInputText(120, posY + 4, 220, null, 14);
        input.text = initial ?? "";
        input.onChange = (old:String, cur:String) -> changed(cur); // depois de preencher o texto, senão dispara na criação
        addLevelWidget(input);
    }
    
    function addLabeledNumericStepper(posY:Float, text:String = "", step:Float, defValue:Float, min:Float, max:Float, decimals:Int, onChange:Float->Void)
    {
        addLevelWidget(new FlxText(8, posY, 256, text, 18));
        
        var numeric:GameUINumericStepper = new GameUINumericStepper(200, posY + 4, step, defValue, min, max, decimals);
        numeric.onValueChange = () -> onChange(numeric.value);
        addLevelWidget(numeric);
    }
    
    // uma cor RGB com um quadradinho de prévia; altera o array do próprio meta
    function addColorRow(label:String, rgb:Array<Int>, rowY:Float)
    {
        addLevelWidget(new FlxText(8, rowY, 110, label, 16));
        
        var swatch:FlxSprite = new FlxSprite(112, rowY);
        swatch.makeGraphic(28, 28, FlxColor.WHITE);
        inline function refresh()
            swatch.color = FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]);
            
        refresh();
        addLevelWidget(swatch);
        
        var channelNames:Array<String> = ["R", "G", "B"];
        for (i in 0...3)
        {
            var channelIndex:Int = i;
            var x0:Float = 148 + i * 104;
            addLevelWidget(new FlxText(x0, rowY + 5, 24, channelNames[i], 14));
            
            var numeric:GameUINumericStepper = new GameUINumericStepper(x0 + 24, rowY, 1, rgb[channelIndex], 0, 255, 0);
            numeric.onValueChange = () ->
            {
                rgb[channelIndex] = Std.int(FlxMath.bound(numeric.value, 0, 255));
                refresh();
                runtime.applyMeta();
            };
            addLevelWidget(numeric);
        }
    }
    
    inline function setUICamera(obj:FlxBasic, camera:FlxCamera)
        obj.cameras = [camera];
        
    inline function pauseSong()
        if (music != null)
            music.pause();
            
    inline function stopSong()
        if (music != null)
            music.stop();
            
    function replaceMusic(sound:Sound)
    {
        destroyMusic();
        musicAsset = sound;
        music = FlxG.sound.create(sound);
    }
    
    function destroyMusic()
    {
        if (music != null)
        {
            music.stop();
            music.destroy();
            music = null;
        }
        musicAsset = null;
    }
    
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
            dialog.onSelect.add((path:String) -> saveLevel(path));
            dialog.browse(FileDialogType.SAVE, "json", null, "Save Level");
        });
        
        space = padding + btnSaveLevel.x + btnSaveLevel.width;
        
        btnLoadSong = new GameUIButton(space, 8, "Load song", () ->
        {
            var dialog:FileDialog = new FileDialog();
            dialog.onSelect.add((path:String) ->
            {
                loadedMusicPath = path;
                levelData.meta.songFilename = ""; // música nova: o Save vai copiar para audio.ogg
                replaceMusic(loadAudio(path));
                rebuildLevelUI(); // o campo Song passa a mostrar vazio
            });
            
            dialog.browse(FileDialogType.OPEN, "ogg", null, "Load audio");
        });
        
        space = padding + btnLoadSong.x + btnLoadSong.width;
        
        var btnCreateLevel:GameUIButton = new GameUIButton(space, 8, "Create level", () -> createEmptyLevel());
        
        space = padding + btnCreateLevel.x + btnCreateLevel.width;
        var btnLevelSettings:GameUIButton = new GameUIButton(space, 8, "Level settings", () -> toggleLevelSettings());
        
        space = padding + btnLevelSettings.x + btnLevelSettings.width;
        var btnPlayLevel:GameUIButton = new GameUIButton(space, 8, "Playtest", startPlaytest);
        
        setUICamera(btnLoadLevel, hudCam);
        setUICamera(btnSaveLevel, hudCam);
        setUICamera(btnLoadSong, hudCam);
        setUICamera(btnCreateLevel, hudCam);
        setUICamera(btnLevelSettings, hudCam);
        setUICamera(btnPlayLevel, hudCam);
        
        add(btnLoadLevel);
        add(btnSaveLevel);
        add(btnLoadSong);
        add(btnCreateLevel);
        add(btnLevelSettings);
        add(btnPlayLevel);
    }
    
    function startPlaytest()
    {
        playtestSession = {
            levelData: levelData,
            currentLevelDir: currentLevelDir,
            loadedMusicPath: loadedMusicPath,
            cursorMusicTime: cursorMusicTime,
            musicTime: music == null ? cursorMusicTime : music.time,
            musicVolume: music == null ? 1 : music.volume,
            musicWasPlaying: music != null && music.playing,
            musicAsset: musicAsset,
            selectedEvent: selectedEvent,
            selectedEvents: selectedEvents.copy()
        };
        
        if (music != null)
        {
            music.pause();
            music.destroy();
            music = null;
        }
        
        FlxG.switchState(() -> new PlayState(levelData, musicAsset, cursorMusicTime));
    }
    
    function restorePlaytestSession(session:EditorPlaytestSession)
    {
        levelData = session.levelData;
        currentLevelDir = session.currentLevelDir;
        loadedMusicPath = session.loadedMusicPath;
        cursorMusicTime = session.cursorMusicTime;
        musicAsset = session.musicAsset;
        music = musicAsset == null ? null : FlxG.sound.create(musicAsset);
        
        runtime.load(levelData);
        Conductor.changeBPM(levelData.meta.bpm ?? 110);
        
        if (levelData.meta.backgroundID > 0)
            updateBackground(levelData.meta.backgroundID);
            
        var laneOverrides:Array<Null<Int>> = levelData.editorMeta == null ? null : levelData.editorMeta.eventLanes;
        editorTimeline.setEvents(levelData.events, laneOverrides);
        editorTimeline.cursorMusicTime = cursorMusicTime;
        Conductor.songPosition = cursorMusicTime;
        selectEvents(session.selectedEvents ?? (session.selectedEvent == null ? [] : [session.selectedEvent]), session.selectedEvent);
        
        if (music != null)
        {
            music.volume = session.musicVolume;
            if (session.musicWasPlaying)
                music.play(true, session.musicTime);
            else
                music.time = session.musicTime;
        }
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
        platformSprite.color = 0xFFFFFFFF;
        
        background = new FlxSprite();
        background.loadGraphic("assets/images/backgrounds/game_bg07.png");
        background.setGraphicSize(FlxG.width * 1.2, FlxG.height * 1.2);
        background.scrollFactor.set(0.75, 0.75);
        background.updateHitbox();
        background.screenCenter();
        background.color = 0xFF6784D3;
        
        add(background);
        add(platformSprite);
    }
    
    override function update(elapsed:Float)
    {
        if (music != null && music.playing)
            cursorMusicTime = music.time;
            
        editorTimeline.cursorMusicTime = cursorMusicTime;
        Conductor.songPosition = cursorMusicTime;
        
        var mouseHud = FlxG.mouse.getViewPosition(hudCam);
        var mouseHudX:Float = mouseHud.x;
        var mouseHudY:Float = mouseHud.y;
        
        var overTimeline = mouseHudY >= editorTimeline.y;
        var scrollLanes = overTimeline && FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel != 0;
        if (scrollLanes)
            editorTimeline.scrollLanes(-FlxG.mouse.wheel);
            
        var overEventPanel = boxCurrentSelectedEvent != null
            && boxCurrentSelectedEvent.visible
            && mouseHudX >= boxCurrentSelectedEvent.x
            && mouseHudX <= boxCurrentSelectedEvent.x + boxCurrentSelectedEvent.bg.width
            && mouseHudY >= boxCurrentSelectedEvent.y
            && mouseHudY <= boxCurrentSelectedEvent.y + boxCurrentSelectedEvent.bg.height;
        if (overEventPanel && !scrollLanes && FlxG.mouse.wheel != 0)
        {
            eventPanelScroll = FlxMath.bound(eventPanelScroll - FlxG.mouse.wheel * 32, 0, Math.max(0, eventPanelContentHeight - boxCurrentSelectedEvent.bg.height + 8));
            applyEventPanelScroll();
        }
        
        // arrows and wheel, move the time //
        var wheel = scrollLanes || overEventPanel ? 0 : FlxG.mouse.wheel;
        var dir:Float = (FlxG.keys.pressed.RIGHT || wheel > 0 ? 1 : 0) - (FlxG.keys.pressed.LEFT || wheel < 0 ? 1 : 0);
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
                music.play(true, cursorMusicTime);
        }
        
        // atalhos não valem enquanto você digita num campo de texto //
        if (GameUIInputText.focusOn == null)
        {
            if (FlxG.keys.justPressed.N)
                createEventAtCursor();
            if (FlxG.keys.justPressed.DELETE)
                deleteSelected();
            if (FlxG.keys.justPressed.C && selectedEvents.length > 0)
                lastCopiedEvents = [for (e in selectedEvents) cloneEvent(e)];
            if (FlxG.keys.justPressed.V)
                createEventCopyAtCursor();
            if (FlxG.keys.justPressed.X)
                createExactEventCopy();
            if (FlxG.keys.justPressed.T)
                moveSelectedEventsToCursor();
            if (FlxG.keys.justPressed.END)
                goToLastEvent();
            if (FlxG.keys.justPressed.UP)
                for (e in selectedEvents)
                    editorTimeline.moveEventToLane(e, -1);
            if (FlxG.keys.justPressed.DOWN)
                for (e in selectedEvents)
                    editorTimeline.moveEventToLane(e, 1);
        }
        
        // select event //
        if (FlxG.mouse.justPressed && mouseHudY >= editorTimeline.y)
        {
            var hit = editorTimeline.eventAt(mouseHudX, mouseHudY);
            if (FlxG.keys.pressed.CONTROL)
            {
                if (hit == null)
                    selectEvents([]);
                else
                {
                    var selection = selectedEvents.copy();
                    if (selection.indexOf(hit) >= 0)
                        selection.remove(hit);
                    else
                        selection.push(hit);
                    selectEvents(selection, hit);
                }
            }
            else if (hit != null)
                selectEvents([hit], hit);
        }
        
        if (isEventUIDirty && boxCurrentSelectedEvent != null)
            rebuildEventUI();
            
        runtime.update(cursorMusicTime); // janela de atores + efeitos, igual ao jogo
        
        timeText.text = 'CurrentTime:${Math.round(cursorMusicTime)} | step: $curStep | playing: ${music != null && music.playing} | Copied events: ${lastCopiedEvents.length}';
        
        super.update(elapsed);
    }
    
    // the only way to move on the time //
    function setSongTime(time:Float)
    {
        if (music == null)
            return;
            
        cursorMusicTime = FlxMath.bound(time, 0, music.length);
        
        if (music.playing)
            music.time = cursorMusicTime;
            
        music.time = cursorMusicTime;
        Conductor.songPosition = cursorMusicTime;
    }
    
    function goToLastEvent()
    {
        if (levelData.events.length == 0)
            return;
            
        var lastEventTime:Float = levelData.events[0].time;
        for (event in levelData.events)
            if (event.time > lastEventTime)
                lastEventTime = event.time;
                
        setSongTime(lastEventTime);
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
        
        pushEvents([e]);
    }
    
    function pushEvents(events:Array<TimelineEvent>)
    {
        if (events.length == 0)
            return;
            
        for (e in events)
        {
            levelData.events.push(e);
            editorTimeline.addEvent(e, false);
            rebuildActor(e);
        }
        editorTimeline.relayout();
        selectEvents(events, events[events.length - 1]);
        onEventsChanged();
    }
    
    inline function cloneEvent(e:TimelineEvent):TimelineEvent
        return Json.parse(Json.stringify(e));
        
    function createExactEventCopy()
    {
        if (lastCopiedEvents.length == 0)
            return;
            
        pushEvents([for (e in lastCopiedEvents) cloneEvent(e)]);
    }
    
    function moveSelectedEventsToCursor()
    {
        if (selectedEvents.length == 0)
            return;
            
        for (e in selectedEvents)
        {
            e.time = cursorMusicTime;
            rebuildActor(e);
        }
        editorTimeline.relayout();
        onEventsChanged();
    }
    
    function createEventCopyAtCursor()
    {
        if (lastCopiedEvents.length == 0)
            return;
            
        var earliestTime:Float = lastCopiedEvents[0].time;
        for (e in lastCopiedEvents)
            if (e.time < earliestTime)
                earliestTime = e.time;
                
        var offset = snapTime(cursorMusicTime) - earliestTime;
        var copies:Array<TimelineEvent> = [];
        for (source in lastCopiedEvents)
        {
            var copy = cloneEvent(source);
            copy.time += offset;
            copies.push(copy);
        }
        pushEvents(copies);
    }
    
    function deleteSelected()
    {
        if (selectedEvents.length == 0)
            return;
            
        for (e in selectedEvents.copy())
        {
            removeActorOf(e);
            editorTimeline.removeEvent(e);
            levelData.events.remove(e);
        }
        selectEvents([]);
        onEventsChanged();
    }
    
    // o runtime é dono dos atores e dos efeitos; o editor só avisa quando o dado muda
    function rebuildActor(e:TimelineEvent)
        runtime.rebuildActor(e);
        
    function removeActorOf(e:TimelineEvent)
        runtime.removeActorOf(e);
        
    function onEventsChanged()
        runtime.eventsChanged();
        
    function resetEditor()
    {
        // if there's any music playing, stop now //
        stopSong();
        
        // we set the level data as empty level
        levelData = Level.emptyLevel();
        runtime.load(levelData);
        
        // clear the selected one //
        selectEvents([]);
        cursorMusicTime = 0;
        
        // we clear the song preloaded cuz we destroy it too //
        loadedMusicPath = "";
        
        destroyMusic();
        
        // and update the timeline to remove all the sprites//
        editorTimeline.destroyEventSprites();
        
        // predefined bpm //
        Conductor.changeBPM(100);
    }
    
    inline function loadAudio(path:String):Sound
        return Sound.fromFile(path);
        
    // carregar e criar um level vazio passam pelo mesmo caminho
    function applyLevel(data:LevelData, levelDir:String = "")
    {
        resetEditor();
        
        currentLevelDir = levelDir;
        levelData = data;
        runtime.load(levelData);
        Conductor.changeBPM(levelData.meta.bpm ?? 110);
        
        var bgID:Int = levelData.meta.backgroundID;
        if (bgID > 0)
            updateBackground(bgID);
            
        var laneOverrides:Array<Null<Int>> = levelData.editorMeta == null ? null : levelData.editorMeta.eventLanes;
        editorTimeline.setEvents(levelData.events, laneOverrides);
        
        trace(currentLevelDir);
        
        if (!loadSongFromMeta() && levelDir != "")
        {
            var ref = Paths.songRef(levelData.meta.songFilename);
            trace('Música não encontrada: ref="$ref", procurei em "${Paths.resolve(ref, levelDir)}"');
        }
        
        rebuildLevelUI();
    }
    
    inline function loadLevel(path:String)
        applyLevel(Level.loadJsonData(path), Path.directory(path));
        
    inline function createEmptyLevel()
        applyLevel(Level.emptyLevel());
        
    function updateBackground(id:Int)
    {
        background.loadGraphic('assets/images/backgrounds/game_bg${StringTools.lpad(Std.string(id), "0", 2)}.png');
        background.setGraphicSize(FlxG.width * 1.2, FlxG.height * 1.2);
        background.updateHitbox();
        background.screenCenter();
    }
    
    function saveLevel(path:String)
    {
        if (!StringTools.endsWith(path, ".json"))
            path += ".json";
            
        // a música viaja junto com o level: copia para a pasta e aponta o meta para ela
        var hasScheme = Paths.split(levelData.meta.songFilename ?? "").scheme != null;
        if (loadedMusicPath != "" && !hasScheme)
        {
            var target = Path.join([Path.directory(path), "audio.ogg"]);
            if (Path.normalize(loadedMusicPath) != Path.normalize(target))
                File.copy(loadedMusicPath, target);
            levelData.meta.songFilename = "audio.ogg";
        }
        
        if (levelData.editorMeta == null)
            levelData.editorMeta = Level.emptyEditorMetadata();
        levelData.editorMeta.eventLanes = editorTimeline.getLaneOverrides();
        
        currentLevelDir = Path.directory(path);
        trace(currentLevelDir);
        File.saveContent(path, Json.stringify(levelData, null, "    "));
    }
    
    function rebuildEventUI()
    {
        isEventUIDirty = false;
        clearEventUI();
        eventPanelScroll = 0;
        
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
        eventWidgetBaseYs = [];
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
        if (v == null && holder != null && f.key == "useRandomX")
            v = Reflect.field(holder, "randomX");
        else if (v == null && holder != null && f.key == "useRandomY")
            v = Reflect.field(holder, "randomY");
        return v ?? f.defaultValue;
    }
    
    function setValue(f:FieldDef, value:Dynamic)
    {
        for (e in selectedEvents)
        {
            var holder:Dynamic = f.target == FieldTarget.Root ? e : e.params;
            if (holder == null && f.target != FieldTarget.Root)
            {
                holder = {};
                e.params = holder;
            }
            if (holder != null)
            {
                Reflect.setField(holder, f.key, value);
                if (f.key == "property" && e.object == "transform_actor")
                {
                    if (value == "scale_x" || value == "scale_y")
                    {
                        var currentValue:Dynamic = Reflect.field(holder, "value");
                        if (currentValue == null
                            || ((Std.isOfType(currentValue, Int) || Std.isOfType(currentValue, Float)) && currentValue <= 0))
                            Reflect.setField(holder, "value", 0.01);
                    }
                    isEventUIDirty = true;
                }
                rebuildActor(e); // o ator guarda cópias dos valores
            }
        }
        for (e in selectedEvents)
            editorTimeline.refreshEvent(e);
        editorTimeline.relayout(); // time, duration ou outro mudam a largura e a linha
        onEventsChanged();
    }
    
    function createFieldWidgets()
    {
        var ROW_HEIGHT:Float = 32;
        var rowY:Float = 8 + ROW_HEIGHT + 8; // abaixo do dropdown
        
        var fields = rootFields.copy();
        if (ActorManager.categoryOf(selectedEvent.object) == EventCategory.Obstacle)
        {
            fields.push({
                key: "id",
                label: "Actor ID",
                kind: FieldKind.Text,
                target: FieldTarget.Root,
                defaultValue: ""
            });
            fields.push({
                key: "persistent",
                label: "Until killed by event",
                kind: FieldKind.Checkbox,
                target: FieldTarget.Root,
                defaultValue: false
            });
        }
        if (selectionHasType(selectedEvent.object))
            fields = fields.concat(ActorManager.fieldsOf(selectedEvent.object));
            
        for (f in fields)
        {
            switch (f.kind)
            {
                case Number:
                    addNumberRow(f, rowY);
                case Checkbox:
                    var box:GameUICheckbox = new GameUICheckbox(8, rowY, f.label, null, (checked:Bool) -> setValue(f, checked));
                    box.checked = getValue(f) == true;
                    addWidget(box);
                case DropdownString:
                    final options:Array<String> = f.options ?? EffectManager.easingNames();
                    var boxW:Float = boxCurrentSelectedEvent.bg.width;
                    addWidget(new FlxText(8, rowY, 80, f.label, 14));
                    var dropdown:GameUIDropdownMenu = new GameUIDropdownMenu(boxW - 108, rowY, options, (idx:Int, name:String) -> setValue(f, name));
                    
                    var selected:Dynamic = getValue(f);
                    var selectedName:String = selected == null ? "" : Std.string(selected);
                    if (options.indexOf(selectedName) < 0)
                        selectedName = options.indexOf("linear") >= 0 ? "linear" : (options.length > 0 ? options[0] : "");
                    dropdown.selectedLabel = selectedName;
                    addWidget(dropdown);
                case Text:
                    addTextRow(f, rowY);
            }
            rowY += ROW_HEIGHT;
        }
        eventPanelContentHeight = rowY;
        applyEventPanelScroll();
    }
    
    function applyEventPanelScroll()
    {
        if (boxCurrentSelectedEvent == null)
            return;
        var panelBottom:Float = boxCurrentSelectedEvent.bg.height;
        for (w in eventWidgets)
        {
            var baseY:Null<Float> = eventWidgetBaseYs.get(w);
            if (baseY == null)
                baseY = w.y - boxCurrentSelectedEvent.y;
            if (baseY < 40)
            {
                w.y = boxCurrentSelectedEvent.y + baseY;
                w.visible = w.y <= boxCurrentSelectedEvent.y + panelBottom;
            }
            else
            {
                w.y = boxCurrentSelectedEvent.y + baseY - eventPanelScroll;
                w.visible = w.y + w.height >= boxCurrentSelectedEvent.y + 40 && w.y <= boxCurrentSelectedEvent.y + panelBottom;
            }
        }
    }
    
    function addTextRow(f:FieldDef, rowY:Float)
    {
        var boxW:Float = boxCurrentSelectedEvent.bg.width;
        var ev:TimelineEvent = selectedEvent;
        
        addWidget(new FlxText(8, rowY, 88, f.label, 14));
        
        var input:GameUIInputText = new GameUIInputText(96, rowY, Std.int(boxW - 104), Std.string(getValue(f) ?? ""), 12);
        input.onChange = (old:String, value:String) ->
        {
            if (selectedEvent == ev)
                setValue(f, value);
        };
        addWidget(input);
    }
    
    function addNumberRow(f:FieldDef, rowY:Float)
    {
        var boxW:Float = boxCurrentSelectedEvent.bg.width;
        var ev:TimelineEvent = selectedEvent;
        
        addWidget(new FlxText(8, rowY, 80, f.label, 14));
        
        // argumentos: x, y, step, valor inicial, min, max, casas decimais
        var min:Float = f.min ?? 0;
        if (ev.object == "transform_actor" && f.key == "value")
        {
            var property:Dynamic = ev.params == null ? null : Reflect.field(ev.params, "property");
            if (property == "scale_x" || property == "scale_y")
                min = 0.01;
        }
        var stepper:GameUINumericStepper = new GameUINumericStepper(boxW - 108, rowY, f.step ?? 10, getValue(f) ?? 0, min, f.max ?? 999999, f.decimals ?? 0);
        stepper.onValueChange = () ->
        {
            if (selectedEvent == ev) // o painel pode já ter mudado de evento quando o callback dispara
                setValue(f, stepper.value);
        };
        addWidget(stepper);
    }
    
    function addWidget(w:FlxSprite)
    {
        setUICamera(w, hudCam);
        eventWidgetBaseYs.set(w, w.y - boxCurrentSelectedEvent.y);
        boxCurrentSelectedEvent.add(w);
        eventWidgets.push(w);
    }
    
    function createTypeDropdown()
    {
        var dd:GameUIDropdownMenu = new GameUIDropdownMenu(8, 8, ActorManager.getActorNames(), (idx:Int, name:String) -> changeEventType(name), 140);
        var sameType = selectionHasType(selectedEvent.object);
        dd.selectedLabel = sameType ? selectedEvent.object : null;
        if (!sameType)
            dd.text = "Multiple types";
        addWidget(dd);
    }
    
    function selectionHasType(type:String):Bool
    {
        if (selectedEvents.length == 0)
            return false;
            
        for (e in selectedEvents)
            if (e.object != type)
                return false;
        return true;
    }
    
    function changeEventType(newType:String)
    {
        if (selectedEvent == null || selectedEvents.length == 0)
            return;
            
        for (e in selectedEvents)
        {
            if (e.object == newType)
                continue;
                
            var old:Dynamic = e.params;
            var fresh:Dynamic = ActorManager.defaultParams(newType);
            
            // keep the data that has equal fields
            if (old != null)
                for (k in Reflect.fields(fresh))
                    if (Reflect.hasField(old, k))
                        Reflect.setField(fresh, k, Reflect.field(old, k));
                        
            e.object = newType;
            e.params = fresh;
            if (ActorManager.categoryOf(newType) == EventCategory.Map)
                e.lead = 0;
                
            rebuildActor(e);
            editorTimeline.refreshEvent(e);
        }
        onEventsChanged();
        isEventUIDirty = true;
    }
    
    function selectEvents(events:Array<TimelineEvent>, ?primary:Null<TimelineEvent>)
    {
        selectedEvents = events.copy();
        selectedEvent = primary != null
            && selectedEvents.indexOf(primary) >= 0 ? primary : (selectedEvents.length > 0 ? selectedEvents[selectedEvents.length - 1] : null);
        isEventUIDirty = true;
        if (editorTimeline != null)
            editorTimeline.setSelected(selectedEvents);
    }
    
    override public function destroy()
    {
        if (playtestSession == null)
            destroyMusic();
        super.destroy();
    }
    
    // carrega a música que o meta aponta; devolve se achou
    function loadSongFromMeta():Bool
    {
        var ref = Paths.songRef(levelData.meta.songFilename);
        var sound = Paths.loadSong(ref, currentLevelDir);
        if (sound == null)
            return false;
            
        replaceMusic(sound);
        
        // arquivo em disco: o Save sabe copiar; builtin e embed ficam só como referência
        loadedMusicPath = Paths.split(ref).scheme == null ? Path.join([currentLevelDir, ref]) : "";
        return true;
    }
    
    public function UIEvent(id:String, sender:Dynamic) {}
}
