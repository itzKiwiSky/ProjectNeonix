package core;

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
    
    public function new() {}
    
    public function setKeys(k:Array<Keyframe>)
    {
        keys = k;
        keys.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
    }
    
    public function valueAt(now:Float):Float
    {
        var from = base;
        var result = base;
        for (k in keys)
        {
            if (k.time > now)
                break;
                
            var t = k.duration <= 0 ? 1 : Math.min(1, (now - k.time) / k.duration);
            result = from + (k.value - from) * FlxEase.quadOut(t);
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
}

// N canais numéricos + uma função que usa os valores a cada frame
class TrackEffect extends Effect
{
    var channels:Array<ChannelDef>;
    var tracks:Array<Track> = [];
    var values:Array<Float> = [];
    var onApply:Array<Float>->Void;
    
    public function new(id:String, channels:Array<ChannelDef>, onApply:Array<Float>->Void)
    {
        super(id);
        this.channels = channels;
        this.onApply = onApply;
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
            list.push({
                key: c.key,
                label: c.label,
                kind: FieldKind.Number,
                step: c.step,
                min: c.min,
                decimals: c.decimals,
                defaultValue: c.def
            });
        list.push({
            key: "duration",
            label: "Fade",
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
            for (i in 0...channels.length)
                keys[i].push({time: e.time, duration: d, value: Effect.param(e, channels[i].key, channels[i].def)});
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
    public static function colorEffect(id:String, sprite:FlxSprite):TrackEffect
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
            
        return new TrackEffect(id, [ch("r", "Red"), ch("g", "Green"), ch("b", "Blue")], v -> sprite.color = FlxColor.fromRGB(c(v[0]), c(v[1]), c(v[2])));
    }
}
