package core;

import flixel.FlxCamera;
import core.ActorManager;
import core.Timeline.TimelineEvent;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

typedef Keyframe =
{
    var time:Float;
    var duration:Float;
    var value:Float;
    var easingType:String;
}

typedef ChannelDef =
{
    var key:String; // nome dentro de params
    var label:String;
    var def:Float; // valor padrão, e o valor antes de qualquer evento
    var ?step:Float;
    var ?min:Float;
    var ?decimals:Int;
}

// um valor numérico que muda ao longo da música
class Track
{
    public var base:Float = 0;
    
    var keys:Array<Keyframe> = [];

    static final easingFunctions:Map<String, Float->Float> = [
        "backIn" => FlxEase.backIn,
        "backInOut" => FlxEase.backInOut,
        "backOut" => FlxEase.backOut,
        "bounceIn" => FlxEase.bounceIn,
        "bounceInOut" => FlxEase.bounceInOut,
        "bounceOut" => FlxEase.bounceOut,
        "circIn" => FlxEase.circIn,
        "circInOut" => FlxEase.circInOut,
        "circOut" => FlxEase.circOut,
        "cubeIn" => FlxEase.cubeIn,
        "cubeInOut" => FlxEase.cubeInOut,
        "cubeOut" => FlxEase.cubeOut,
        "elasticIn" => FlxEase.elasticIn,
        "elasticInOut" => FlxEase.elasticInOut,
        "elasticOut" => FlxEase.elasticOut,
        "expoIn" => FlxEase.expoIn,
        "expoInOut" => FlxEase.expoInOut,
        "expoOut" => FlxEase.expoOut,
        "linear" => FlxEase.linear,
        "quadIn" => FlxEase.quadIn,
        "quadInOut" => FlxEase.quadInOut,
        "quadOut" => FlxEase.quadOut,
        "quartIn" => FlxEase.quartIn,
        "quartInOut" => FlxEase.quartInOut,
        "quartOut" => FlxEase.quartOut,
        "quintIn" => FlxEase.quintIn,
        "quintInOut" => FlxEase.quintInOut,
        "quintOut" => FlxEase.quintOut,
        "sineIn" => FlxEase.sineIn,
        "sineInOut" => FlxEase.sineInOut,
        "sineOut" => FlxEase.sineOut,
        "smoothStepIn" => FlxEase.smoothStepIn,
        "smoothStepInOut" => FlxEase.smoothStepInOut,
        "smoothStepOut" => FlxEase.smoothStepOut,
        "smootherStepIn" => FlxEase.smootherStepIn,
        "smootherStepInOut" => FlxEase.smootherStepInOut,
        "smootherStepOut" => FlxEase.smootherStepOut
    ];
    
    public function new() {}

    public static function easingNames():Array<String>
    {
        var names = [for (name in easingFunctions.keys()) name];
        names.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
        return names;
    }

    inline function progress(now:Float, start:Float, len:Float):Float
        return len <= 0 ? 1 : Math.max(0, Math.min(1, (now - start) / len));
    
    public function setKeys(k:Array<Keyframe>)
    {
        keys = k;
        keys.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
    }

    static function easedProgress(easingType:String, t:Float):Float
    {
        var ease = easingFunctions.get(easingType);
        if (ease == null)
            ease = easingFunctions.get("linear");
        return ease(t);
    }
    
    public function valueAt(now:Float):Float
    {
        var from = base;
        var result = base;
        for (k in keys)
        {
            if (k.time > now)
                break;
                
            var t = progress(now, k.time, k.duration);
            result = from + (k.value - from) * easedProgress(k.easingType, t);
            from = k.value; // o próximo keyframe parte do destino deste (o salto)
        }
        return result;
    }
}

// base de todo efeito
class Effect
{
    public var id(default, null):String;
    
    public function new(id:String)
        this.id = id;
        
    public function fields():Array<FieldDef>
        return [];
        
    public function rebuild(events:Array<TimelineEvent>) {}
    
    public function apply(now:Float) {}
    
    static function param(e:TimelineEvent, key:String, def:Float):Float
    {
        if (e.params == null)
            return def;
        var v:Dynamic = Reflect.field(e.params, key);
        return v == null ? def : v;
    }

    static function stringParam(e:TimelineEvent, key:String, def:String):String
    {
        if (e.params == null)
            return def;
        var v:Dynamic = Reflect.field(e.params, key);
        return Std.isOfType(v, String) ? v : def;
    }
}

// N canais numéricos + uma função que usa os valores a cada frame
class TrackEffect extends Effect
{
    var channels:Array<ChannelDef>;
    var tracks:Array<Track> = [];
    var values:Array<Float> = [];
    var onApply:Array<Float>->Void;
    var supportsEasing:Bool;
    
    public function new(id:String, channels:Array<ChannelDef>, onApply:Array<Float>->Void, supportsEasing:Bool = false)
    {
        super(id);
        this.channels = channels;
        this.onApply = onApply;
        this.supportsEasing = supportsEasing;
        for (c in channels)
        {
            var t = new Track();
            t.base = c.def;
            tracks.push(t);
            values.push(c.def);
        }
    }
    
    // o valor que vale antes de qualquer evento (por exemplo, as cores do level)
    public function setBase(base:Array<Float>)
    {
        for (i in 0...tracks.length)
            tracks[i].base = base[i];
    }
    
    // os campos do painel saem dos canais
    override function fields():Array<FieldDef>
    {
        var list:Array<FieldDef> = [];
        for (c in channels)
        {
            list.push({
                key: c.key,
                label: c.label,
                kind: FieldKind.Number,
                step: c.step,
                min: c.min,
                decimals: c.decimals,
                defaultValue: c.def,
            });
        }
        if (supportsEasing)
            list.push({
                key: "easing",
                label: "Easing",
                kind: FieldKind.DropdownString,
                defaultValue: "linear",
            });
        list.push({
            key: "duration",
            label: "Duration",
            kind: FieldKind.Number,
            step: 100,
            defaultValue: 0 // 0 = salto seco
        });
        return list;
    }
    
    override function rebuild(events:Array<TimelineEvent>)
    {
        var keys:Array<Array<Keyframe>> = [for (c in channels) []];
        for (e in events)
        {
            if (e.object != id)
                continue;
            var d = Effect.param(e, "duration", 0);
            var easingType = supportsEasing ? Effect.stringParam(e, "easing", "linear") : "linear";
            for (i in 0...channels.length)
            {
                var channel = channels[i];
                keys[i].push({
                    time: e.time,
                    duration: d,
                    value: Effect.param(e, channel.key, channel.def),
                    easingType: easingType
                });
            }
        }
        for (i in 0...tracks.length)
            tracks[i].setKeys(keys[i]);
    }
    
    override function apply(now:Float)
    {
        for (i in 0...tracks.length)
            values[i] = tracks[i].valueAt(now);
        onApply(values);
    }
}

class EffectManager
{
    var effects:Array<Effect> = [];
    var byId:Map<String, Effect> = [];
    
    public function new() {}

    public static function easingNames():Array<String>
        return Track.easingNames();
    
    // os efeitos do jogo; editor e jogo chamam isto, então a lista nunca diverge
    public static function createDefault(background:FlxSprite, platform:FlxSprite, camera:FlxCamera, onActorsColor:FlxColor->Void):EffectManager
    {
        var m = new EffectManager();
        m.add(colorEffect("bg_color", background));
        m.add(colorEffect("platform_color", platform));
        m.add(colorEffectFn("actors_color", onActorsColor));
        m.add(new TrackEffect("camera_zoom", [
            {
                key: "zoom",
                label: "Zoom",
                def: 1,
                step: 0.1,
                min: 0.1,
                decimals: 2
            }
        ], v -> camera.zoom = v[0], true));
        m.add(new TrackEffect("camera_angle", [
            {
                key: "angle",
                label: "Angle",
                def: 0,
                step: 5,
                min: -360
            }
        ], v -> camera.angle = v[0], true));
        return m;
    }
    
    public function add(effect:Effect):Effect
    {
        effects.push(effect);
        byId.set(effect.id, effect);
        ActorManager.registerMapEvent(effect.id, effect.fields()); // o editor já enxerga o tipo novo
        return effect;
    }
    
    public function setBase(id:String, base:Array<Float>)
    {
        var e = byId.get(id);
        if (e != null && Std.isOfType(e, TrackEffect))
            cast(e, TrackEffect).setBase(base);
    }
    
    public function rebuild(events:Array<TimelineEvent>)
    {
        for (e in effects)
            e.rebuild(events);
    }
    
    public function apply(now:Float)
    {
        for (e in effects)
            e.apply(now);
    }
    
    // atalho: um efeito de cor (R, G, B) para qualquer sprite
    // cor aplicada por uma função: serve para um sprite, para os atores, para o que for
    public static function colorEffectFn(id:String, apply:FlxColor->Void):TrackEffect
    {
        inline function ch(key:String, label:String):ChannelDef
            return {
                key: key,
                label: label,
                def: 255,
                step: 5,
                min: 0
            };
            
        inline function c(v:Float):Int
            return Std.int(FlxMath.bound(v, 0, 255));
            
        return new TrackEffect(id, [ch("r", "Red"), ch("g", "Green"), ch("b", "Blue")], v -> apply(FlxColor.fromRGB(c(v[0]), c(v[1]), c(v[2]))));
    }
    
    public static function colorEffect(id:String, sprite:FlxSprite):TrackEffect
        return colorEffectFn(id, c -> sprite.color = c);
}
