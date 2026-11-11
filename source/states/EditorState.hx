package states;

import ui.GameUINumericStepper;
import core.Paths;
import haxe.io.Path;
import core.LevelRuntime;
import core.EffectManager;
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
import core.ActorManager;
import core.level.Level;
import flixel.math.FlxMath;
import core.Conductor;
import flixel.FlxG;
import flixel.text.FlxText;
import core.MusicSyncedState;
import core.Timeline.TimelineEvent;
import ui.GameUIEventController.EngineUIEvent;

class EditorState extends MusicSyncedState implements EngineUIEvent
{
    var timeText:FlxText;
    
    var runtime:LevelRuntime; // atores em janela de tempo + efeitos: o mesmo código do jogo
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
    var boxConfig:GameUIBox;
    
    var loadedMusicPath:String = "";
    
    var eventWidgets:Array<FlxSprite> = [];
    var levelDataWidgets:Array<FlxSprite> = [];
    
    public var selectedEvent(default, set):TimelineEvent;
    
    var isEventUIDirty:Bool = false; // set if the ui need to be rebuilt
    
    var lastCopiedEvent:Null<TimelineEvent> = null;
    
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
        
        // FlxG.debugger.drawDebug = true;
        
        createPreviewSprites();
        
        // os efeitos precisam existir antes de qualquer load: é o que registra bg_color, camera_zoom...
        runtime = new LevelRuntime(background, platformSprite, editorGameCamera);
        add(runtime.active);
        
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
        addLevelWidget(new FlxText(8, posY, 100, text, 18));
        
        var numeric:GameUINumericStepper = new GameUINumericStepper(128, posY + 4, step, defValue, min, max, decimals);
        numeric.onValueChange = () -> onChange(numeric.value);
        addLevelWidget(numeric);
    }
    
    // uma cor RGB com um quadradinho de prévia; altera o array do próprio meta
    function addColorRow(label:String, rgb:Array<Int>, rowY:Float)
    {
        addLevelWidget(new FlxText(8, rowY, 110, label, 16));
        
        var swatch:FlxSprite = new FlxSprite(124, rowY);
        swatch.makeGraphic(24, 24, FlxColor.WHITE);
        inline function refresh()
            swatch.color = FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]);
            
        refresh();
        addLevelWidget(swatch);
        
        for (i in 0...3)
        {
            var x0:Float = 160 + i * 104;
            var value:FlxText = new FlxText(x0 + 30, rowY, 40, Std.string(rgb[i]), 14);
            value.alignment = FlxTextAlign.CENTER;
            
            function change(delta:Int)
            {
                rgb[i] = Std.int(FlxMath.bound(rgb[i] + delta, 0, 255));
                value.text = Std.string(rgb[i]);
                refresh();
                runtime.applyMeta();
            }
            
            addLevelWidget(new GameUIButton(x0, rowY, "-", () -> change(-5), 28, 24));
            addLevelWidget(value);
            addLevelWidget(new GameUIButton(x0 + 72, rowY, "+", () -> change(5), 28, 24));
        }
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
                if (FlxG.sound.music != null)
                    FlxG.sound.music.destroy();
                FlxG.sound.music = loadAudio(path);
                rebuildLevelUI(); // o campo Song passa a mostrar vazio
            });
            
            dialog.browse(FileDialogType.OPEN, "ogg", null, "Load audio");
        });
        
        space = padding + btnLoadSong.x + btnLoadSong.width;
        
        var btnCreateLevel:GameUIButton = new GameUIButton(space, 8, "Create level", () -> createEmptyLevel());
        
        space = padding + btnCreateLevel.x + btnCreateLevel.width;
        var btnLevelSettings:GameUIButton = new GameUIButton(space, 8, "Level settings", () -> toggleLevelSettings());
        
        space = padding + btnLevelSettings.x + btnLevelSettings.width;
        var btnPlayLevel:GameUIButton = new GameUIButton(space, 8, "Playtest", () -> {
            // PlayState.levelPath = currentLevelDir;
        });
        
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
        var music:FlxSound = FlxG.sound.music;
        if (music != null && music.playing)
            cursorMusicTime = music.time;
            
        editorTimeline.cursorMusicTime = cursorMusicTime;
        Conductor.songPosition = cursorMusicTime;
        
        // arrows and wheel, move the time //
        var dir:Float = (FlxG.keys.pressed.RIGHT || FlxG.mouse.wheel > 0 ? 1 : 0) - (FlxG.keys.pressed.LEFT || FlxG.mouse.wheel < 0 ? 1 : 0);
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
            
        runtime.update(cursorMusicTime); // janela de atores + efeitos, igual ao jogo
        
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
        selectedEvent = null;
        cursorMusicTime = 0;
        
        // we clear the song preloaded cuz we destroy it too //
        loadedMusicPath = "";
        
        if (FlxG.sound.music != null)
        {
            FlxG.sound.music.destroy();
            FlxG.sound.music = null;
        }
        
        // and update the timeline to remove all the sprites//
        editorTimeline.destroyEventSprites();
        
        // predefined bpm //
        Conductor.changeBPM(100);
    }
    
    inline function loadAudio(path:String)
    {
        var rawSoundData:Sound = Sound.fromFile(path);
        var snd:FlxSound = FlxG.sound.create(rawSoundData);
        return snd;
    }
    
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
            
        editorTimeline.setEvents(levelData.events);
        
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
        
        currentLevelDir = Path.directory(path);
        trace(currentLevelDir);
        File.saveContent(path, Json.stringify(levelData, null, "    "));
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
        if (v == null && holder != null && f.key == "useRandomX")
            v = Reflect.field(holder, "randomX");
        else if (v == null && holder != null && f.key == "useRandomY")
            v = Reflect.field(holder, "randomY");
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
                    box.checked = getValue(f) == true;
                    addWidget(box);
                case DropdownString:
                    final easings:Array<String> = EffectManager.easingNames();
                    var boxW:Float = boxCurrentSelectedEvent.bg.width;
                    addWidget(new FlxText(8, rowY, 80, f.label, 14));
                    var easingType:GameUIDropdownMenu = new GameUIDropdownMenu(boxW - 108, rowY, easings, (idx:Int, name:String) -> setValue(f, name));
                    
                    var selected:Dynamic = getValue(f);
                    var selectedName:String = selected == null ? "" : Std.string(selected);
                    if (easings.indexOf(selectedName) < 0)
                        selectedName = easings.indexOf("linear") >= 0 ? "linear" : (easings.length > 0 ? easings[0] : "");
                    easingType.selectedLabel = selectedName;
                    addWidget(easingType);
            }
            rowY += ROW_HEIGHT;
        }
    }
    
    function addNumberRow(f:FieldDef, rowY:Float)
    {
        var boxW:Float = boxCurrentSelectedEvent.bg.width;
        var ev:TimelineEvent = selectedEvent;
        
        addWidget(new FlxText(8, rowY, 80, f.label, 14));
        
        // argumentos: x, y, step, valor inicial, min, max, casas decimais
        var stepper:GameUINumericStepper = new GameUINumericStepper(boxW - 108, rowY, f.step ?? 10, getValue(f) ?? 0, f.min ?? 0, f.max ?? 999999, f.decimals ?? 0);
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
    
    // carrega a música que o meta aponta; devolve se achou
    function loadSongFromMeta():Bool
    {
        var ref = Paths.songRef(levelData.meta.songFilename);
        var sound = Paths.loadSong(ref, currentLevelDir);
        if (sound == null)
            return false;
            
        if (FlxG.sound.music != null)
            FlxG.sound.music.destroy();
        FlxG.sound.music = FlxG.sound.create(sound);
        
        // arquivo em disco: o Save sabe copiar; builtin e embed ficam só como referência
        loadedMusicPath = Paths.split(ref).scheme == null ? Path.join([currentLevelDir, ref]) : "";
        return true;
    }
    
    public function UIEvent(id:String, sender:Dynamic) {}
}
