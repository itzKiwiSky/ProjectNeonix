package objects;

import core.Conductor;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

enum Phase
{
    Waiting;
    Warning;
    Active;
    Outro;
    Dead;
}

class LevelActor extends FlxTypedSpriteGroup<FlxSprite>
{
    public var time:Float = 0;
    public var warningTime:Float = 0;
    public var duration:Float = 0;
    public var outroDuration:Float = 0;
    public var phase:Null<Phase> = null;
    public var cx:Float;
    public var cy:Float;
    
    public function new(x:Float = 0, y:Float = 0, time:Float = 0, warningTime:Float = 1000, duration:Float = 500, outroDuration:Float = 200)
    {
        super(x, y);
        this.time = time;
        this.warningTime = warningTime;
        this.duration = duration;
        this.outroDuration = outroDuration;
    }
    
    function phaseAt(now:Float):Phase
    {
        if (now < time - warningTime)
            return Waiting;
        if (now < time)
            return Warning;
        if (now < time + duration)
            return Active;
        if (now < time + duration + outroDuration)
            return Outro;
        return Dead;
    }
    
    override function update(elapsed:Float)
    {
        var p = phaseAt(Conductor.songPosition);
        if (p != phase)
        {
            phase = p;
            switch (p)
            {
                case Waiting:
                    onWaiting();
                case Warning:
                    onWarning();
                case Active:
                    onActive();
                case Outro:
                    onOutro();
                case Dead:
                    onDead();
            }
        }
        super.update(elapsed);
    }
    
    inline function progress(now:Float, start:Float, len:Float):Float
        return Math.max(0, Math.min(1, (now - start) / len));
        
    public function hits(obj:FlxSprite):Bool
        return false;
        
    public function onWaiting() {}
    
    public function onWarning() {}
    
    public function onActive() {}
    
    public function onOutro() {}
    
    public function onDead() {}
}
