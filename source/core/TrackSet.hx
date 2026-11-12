package core;

import flixel.tweens.FlxEase;

typedef Key =
{
    var t:Float; // ms relativos ao time do evento (pode ser negativo: anima durante o aviso)
    var value:Float;
    var dur:Float; // 0 = salto
    var ease:Float->Float;
}

// as trilhas de um evento: um canal (x, y, scale...) é uma lista de chaves
class TrackSet
{
    // por nome, para o JSON; um nome desconhecido cai em linear
    var tracks:Map<String, Array<Key>> = [];
    
    public function new(data:Dynamic) // o e.tracks do evento; pode ser null
    {
        if (data == null)
            return;
            
        for (name in Reflect.fields(data))
        {
            var raw:Array<Dynamic> = Reflect.field(data, name);
            if (raw == null)
                continue;
                
            var keys:Array<Key> = [];
            for (k in raw)
            {
                var easeName:String = k.ease ?? "linear";
                keys.push({
                    t: k.t ?? 0,
                    value: k.value ?? 0,
                    dur: k.dur ?? 0,
                    ease: Shared.easingFunctions.get(easeName) ?? FlxEase.linear
                });
            }
            keys.sort((a, b) -> a.t < b.t ? -1 : (a.t > b.t ? 1 : 0));
            tracks.set(name, keys);
        }
    }
    
    public function has(name:String):Bool
        return tracks.exists(name);
        
    // valor do canal em `local` ms desde o início do evento; `def` (o valor do params) se não há trilha
    public function valueAt(name:String, local:Float, def:Float):Float
    {
        var keys = tracks.get(name);
        if (keys == null)
            return def;
            
        var from = def;
        var result = def;
        for (k in keys)
        {
            if (k.t > local)
                break;
                
            var t = k.dur <= 0 ? 1 : Math.min(1, (local - k.t) / k.dur);
            result = from + (k.value - from) * k.ease(t);
            from = k.value; // a próxima chave parte do destino desta
        }
        return result;
    }
}
