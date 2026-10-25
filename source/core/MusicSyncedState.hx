package core;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class MusicSyncedState extends FlxTransitionableState
{
    public static var instance:MusicSyncedState;
    
    var curStep:Int = 0;
    var curBeat:Int = 0;
    
    override function create()
    {
        // FlxTransitionableState.defaultTransIn = new TransitionData(TransitionType.FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), null, null);
        // FlxTransitionableState.defaultTransOut = new TransitionData(TransitionType.FADE, FlxColor.BLACK, 0.6, new FlxPoint(0, 1), null, null);
        // transIn = FlxTransitionableState.defaultTransIn;
        
        super.create();
    }
    
    override function update(elapsed:Float)
    {
        var oldStep = curStep;
        updateCurStep();
        updateBeat();
        
        Conductor.crochet = ((60 / Conductor.bpm) * 1000);
        Conductor.stepCrochet = Conductor.crochet / 4;
        
        if (oldStep != curStep && curStep > 0)
            onStepHit();
            
        super.update(elapsed);
    }
    
    inline function updateBeat():Void
        curBeat = Math.floor(curStep / 4);
        
    inline function updateCurStep():Void
        curStep = Math.floor(Conductor.songPosition / Conductor.stepCrochet);
        
    public function onStepHit():Void
        if (curStep % 4 == 0)
            onBeatHit();
            
    public function onBeatHit():Void {}
    
    public function changeState(?next:Class<flixel.FlxState>)
    {
        if (next == null)
        {
            FlxG.resetState();
            trace('Resetting the current $next.');
            return;
        }
        FlxG.switchState(() -> cast Type.createInstance(next, []));
        trace('Switching to a $next.');
    }
    /*function stageFunc(func:Stage->Void)
        {
            var stage = PlayState.stage;
            if (stage != null && stage.exists && stage.active)
                func(stage);
    }*/
}
