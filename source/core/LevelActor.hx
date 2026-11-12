package core;

import flixel.FlxG;
import flixel.FlxBasic;
import core.Timeline.TimelineEvent;
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

interface ILevelActor
{
    public function selfRegister():Void;
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
    public var event:TimelineEvent;
    public var currentTime:Float = 0;
    public var useRandomX:Bool = false;
    public var useRandomY:Bool = false;
    
    public var tintByActorsColor:Bool = true; // no LevelActor; a piscina põe false se o spike.png tem cores próprias
    
    public function new(x:Float = 0, y:Float = 0, time:Float = 0, warningTime:Float = 1000, duration:Float = 500, outroDuration:Float = 200)
    {
        super(x, y);
        if (useRandomX)
            x = FlxG.random.int(64, FlxG.width - 128);
            
        if (useRandomY)
            y = FlxG.random.int(64, FlxG.height - 128);
            
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
    
    public function lifeEnd():Float
        return time + duration + outroDuration;
        
    public function isInside(now:Float):Bool
        return now >= time - warningTime && now < lifeEnd();
        
    override function update(elapsed:Float)
    {
        currentTime = Conductor.songPosition;
        var p = phaseAt(currentTime);
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
        
        switch (p)
        {
            case Waiting:
                onWaitingUpdate();
            case Warning:
                onWarningUpdate();
            case Active:
                onActiveUpdate();
            case Outro:
                onOutroUpdate();
            case _:
        }
        
        super.update(elapsed);
    }
    
    inline function progress(now:Float, start:Float, len:Float):Float
        return len <= 0 ? 1 : Math.max(0, Math.min(1, (now - start) / len));
        
    public function hits(obj:FlxBasic):Bool
        return false;
        
    // events //
    public function onWaiting() {}
    
    public function onWarning() {}
    
    public function onActive() {}
    
    public function onOutro() {}
    
    public function onDead() {}
    
    public function onWaitingUpdate() {}
    
    public function onWarningUpdate() {}
    
    public function onActiveUpdate() {}
    
    public function onOutroUpdate() {}
}
