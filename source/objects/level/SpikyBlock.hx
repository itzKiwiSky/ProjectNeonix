package objects.level;

import core.LevelActor;
import core.managers.ActorManager;
import core.managers.ActorManager.EventCategory;
import core.managers.ActorManager.FieldKind;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;

class SpikyBlock extends LevelActor
{
    var block:FlxSprite;
    var canDamage:Bool;
    
    public function new(x:Float, y:Float, time:Float = 0, warningTime:Float = 0, duration:Float = 4000, outroDuration:Float = 300, canDamage:Bool = false)
    {
        super(x, y, time, warningTime, duration, outroDuration);
        this.cx = x;
        this.cy = y;
        this.canDamage = canDamage;
        
        block = new FlxSprite();
        block.loadGraphic("assets/images/game/block_spiky.png");
        block.setGraphicSize(128, 128);
        block.updateHitbox();
        block.setPosition(cx - block.width * 0.5, cy - block.height * 0.5);
        block.visible = false;
        add(block);
    }
    
    public static function selfRegister():Void
    {
        ActorManager.registerActor("block_spike", e ->
        {
            if (e.persistent == null)
                e.persistent = true;
            return new SpikyBlock(ActorManager.posX(e), ActorManager.posY(e), e.time, e.lead ?? 0, ActorManager.num(e, "duration", 4000), ActorManager.num(e, "outro", 300), e.params != null
                && Reflect.field(e.params, "alive") == true);
        }, EventCategory.Obstacle, [
                {
                    key: "useRandomX",
                    label: "Random X",
                    kind: FieldKind.Checkbox,
                    defaultValue: false
                },
                {
                    key: "useRandomY",
                    label: "Random Y",
                    kind: FieldKind.Checkbox,
                    defaultValue: false
                },
                {
                    key: "x",
                    label: "X",
                    kind: FieldKind.Number,
                    defaultValue: 640
                },
                {
                    key: "y",
                    label: "Y",
                    kind: FieldKind.Number,
                    defaultValue: 360
                },
                {
                    key: "alive",
                    label: "Alive",
                    kind: FieldKind.Checkbox,
                    defaultValue: false
                },
                {
                    key: "duration",
                    label: "Duration",
                    kind: FieldKind.Number,
                    step: 250,
                    defaultValue: 4000
                },
                {
                    key: "outro",
                    label: "Outro",
                    kind: FieldKind.Number,
                    step: 100,
                    defaultValue: 300
                }
        ]);
    }
    
    override function onWaiting()
    {
        block.visible = false;
        block.alpha = 1;
    }
    
    override function onWarning()
    {
        block.visible = true;
        block.alpha = 1;
    }
    
    override function onActive()
    {
        block.visible = true;
        block.alpha = 1;
    }
    
    override function onOutro() {}
    
    override function onDead()
    {
        block.visible = false;
        block.alpha = 1;
    }
    
    override function onOutroUpdate()
    {
        block.alpha = 1 - FlxEase.quadIn(progress(currentTime, outroStartTime, outroDuration));
    }
    
    override function hits(obj:FlxBasic):Bool
        return canDamage && phase == Active && FlxG.overlap(block, obj);
}
