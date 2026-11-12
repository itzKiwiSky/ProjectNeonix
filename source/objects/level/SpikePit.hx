package objects.level;

import objects.composition.Spike;
import core.ActorManager;
import core.LevelActor;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;

class SpikePit extends LevelActor
{
    static inline var SPIKE_SIZE:Int = 96;
    static inline var PEEK:Float = 0.25; // quanto os espinhos aparecem durante o aviso
    static inline var RISE_MS:Float = 150; // tempo para sair do aviso e entrar na onda
    static inline var DANGER:Float = 0.3; // acima disso o espinho machuca
    
    var spikes:Array<Spike> = [];
    var floorY:Float; // y dos espinhos quando estão totalmente em pé
    var waveSpeed:Float; // ciclos por segundo
    var waveIntensity:Float; // 0 = sempre em pé, 1 = as ondas descem até o chão
    
    inline function wave(low:Float, high:Float, time:Float, f:Float->Float)
        return FlxMath.lerp(low, high, (f(time) + 1) * 0.5);
        
    public function new(y:Float, time:Float, warningTime:Float, duration:Float, outroDuration:Float, waveSpeed:Float, waveIntensity:Float)
    {
        // o ator fica em (0, 0) e os espinhos usam coordenadas absolutas: grupo dentro de grupo soma as posições
        super(0, 0, time, warningTime, duration, outroDuration);
        
        floorY = y;
        this.waveSpeed = waveSpeed;
        this.waveIntensity = FlxMath.bound(waveIntensity, 0, 1);
        
        var count:Int = Math.ceil(FlxG.width / SPIKE_SIZE) + 1;
        for (i in 0...count)
        {
            var s:Spike = new Spike(i * SPIKE_SIZE, floorY + SPIKE_SIZE);
            add(s);
            spikes.push(s);
        }
        
        setAll(0);
    }
    
    public static function selfRegister():Void
    {
        ActorManager.registerActor("spike_pit", e -> new SpikePit(ActorManager.num(e, "y", FlxG.height - SPIKE_SIZE), e.time, e.lead ?? 750, ActorManager.num(e, "duration", 3000), ActorManager.num(e, "outro", 300), ActorManager.num(e, "waveSpeed", 0.5), ActorManager.num(e, "waveIntensity", 0.5)), Obstacle, [
            {
                key: "y",
                label: "Y",
                kind: Number,
                defaultValue: 624
            },
            {
                key: "duration",
                label: "Duration",
                kind: Number,
                step: 250,
                defaultValue: 3000
            },
            {
                key: "outro",
                label: "Outro",
                kind: Number,
                step: 100,
                defaultValue: 300
            },
            {
                key: "waveSpeed",
                label: "Wave speed",
                kind: Number,
                step: 0.1,
                decimals: 1,
                defaultValue: 0.5
            },
            {
                key: "waveIntensity",
                label: "Wave amount",
                kind: Number,
                step: 0.1,
                decimals: 2,
                defaultValue: 0.5
            }
        ]);
    }
    
    // a altura de um espinho no tempo `now`; cada um tem uma fase diferente, daí a onda
    function waveAt(index:Int, now:Float):Float
    {
        var phase:Float = (now - time) / 1000 * waveSpeed * Math.PI * 2 + index * 0.6;
        return wave(1 - waveIntensity, 1, phase, Math.sin);
    }
    
    function setSpike(s:Spike, r:Float)
    {
        s.raise = FlxMath.bound(r, 0, 1);
        s.y = floorY + (1 - s.raise) * SPIKE_SIZE;
        s.visible = s.raise > 0.01;
    }
    
    function setAll(r:Float)
    {
        for (s in spikes)
            setSpike(s, r);
    }
    
    override function onWaiting()
        setAll(0);
        
    override function onDead()
        setAll(0);
        
    override function onWarningUpdate()
        setAll(PEEK * FlxEase.quadOut(progress(currentTime, time - warningTime, warningTime)));
        
    override function onActiveUpdate()
    {
        var rise:Float = FlxEase.backOut(progress(currentTime, time, RISE_MS));
        for (i in 0...spikes.length)
            setSpike(spikes[i], FlxMath.lerp(PEEK, waveAt(i, currentTime), rise));
    }
    
    override function onOutroUpdate()
    {
        var p:Float = FlxEase.quadIn(progress(currentTime, time + duration, outroDuration));
        var endTime:Float = time + duration; // parte da altura que cada espinho tinha ao fim da fase ativa
        for (i in 0...spikes.length)
            setSpike(spikes[i], FlxMath.lerp(waveAt(i, endTime), 0, p));
    }
    
    // só machuca enquanto está de fato em pé, mesmo no início da retirada
    override function hits(obj:FlxBasic):Bool
    {
        if (phase != Active && phase != Outro)
            return false;
            
        for (s in spikes)
            if (s.raise > DANGER && s.spikeHitbox.overlaps(obj))
                return true;
        return false;
    }
}
