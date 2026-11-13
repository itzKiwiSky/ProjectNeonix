package objects.level;

import flixel.tweens.FlxEase;
import flixel.FlxG;
import flixel.FlxSprite;
import core.managers.ActorManager;
import core.managers.ActorManager.EventCategory;
import core.managers.ActorManager.FieldKind;
import flixel.FlxBasic;
import core.LevelActor;

class FallingBlock extends LevelActor
{
    var warningSprite:FlxSprite;
    var movingBlock:FlxSprite;
    var stopY:Float;
    var warningBaseScaleX:Float;
    var warningBaseScaleY:Float;
    var blockBaseScale:Float;
    
    static inline final sizeBase:Int = 128;
    static inline final WARNING_ANIMATION_MS:Float = 200;
    static inline final START_Y:Float = -sizeBase * 0.5;
    
    public function new(x:Float, stopY:Float, time:Float = 0, warningTime:Float = 1000, fallDuration:Float = 500, outroDuration:Float = 200)
    {
        super(x, stopY, time, warningTime, fallDuration, outroDuration);
        this.cx = x;
        this.cy = START_Y;
        this.stopY = stopY;
        
        warningSprite = new FlxSprite();
        warningSprite.loadGraphic("assets/images/game/warning.png");
        warningSprite.setGraphicSize(sizeBase, FlxG.height);
        warningBaseScaleX = warningSprite.scale.x;
        warningBaseScaleY = warningSprite.scale.y;
        warningSprite.updateHitbox();
        warningSprite.alpha = 0.5;
        warningSprite.visible = false;
        add(warningSprite);
        setWarningScale(0);
        
        movingBlock = new FlxSprite();
        movingBlock.loadGraphic("assets/images/game/movable_block.png");
        movingBlock.setGraphicSize(sizeBase, sizeBase);
        blockBaseScale = movingBlock.scale.x;
        movingBlock.updateHitbox();
        movingBlock.visible = false;
        add(movingBlock);
        syncBlock();
    }
    
    public static function selfRegister():Void
    {
        ActorManager.registerActor("falling_block", e -> new FallingBlock(ActorManager.posX(e), ActorManager.num(e, "stopY", FlxG.height - sizeBase * 0.5), e.time, e.lead ?? 750, ActorManager.num(e, "duration", 500), ActorManager.num(e, "outro", 200)), EventCategory.Obstacle, [
            {
                key: "x",
                label: "X",
                kind: FieldKind.Number,
                defaultValue: 640
            },
            {
                key: "useRandomX",
                label: "Random X",
                kind: Checkbox,
                defaultValue: false
            },
            {
                key: "stopY",
                label: "Stop Y",
                kind: FieldKind.Number,
                defaultValue: FlxG.height - sizeBase * 0.5
            },
            {
                key: "duration",
                label: "Fall duration",
                kind: FieldKind.Number,
                step: 100,
                defaultValue: 500
            },
            {
                key: "outro",
                label: "Outro",
                kind: FieldKind.Number,
                step: 100,
                defaultValue: 200
            }
        ]);
    }
    
    override function onWaiting()
    {
        warningSprite.visible = false;
        movingBlock.visible = false;
    }
    
    override function onWarning()
    {
        warningSprite.visible = true;
        movingBlock.visible = false;
        setWarningScale(0);
    }
    
    override function onActive()
    {
        warningSprite.visible = false;
        movingBlock.visible = true;
        movingBlock.alpha = 1;
        cy = START_Y;
        setBlockScale(1);
    }
    
    inline function syncBlock():Void
    {
        movingBlock.updateHitbox();
        movingBlock.setPosition(cx - movingBlock.width * 0.5, cy - movingBlock.height * 0.5);
    }
    
    function setBlockScale(value:Float)
    {
        movingBlock.scale.set(blockBaseScale * value, blockBaseScale * value);
        syncBlock();
    }
    
    function setWarningScale(value:Float)
    {
        warningSprite.scale.set(warningBaseScaleX * value, FlxG.height);
        warningSprite.updateHitbox();
        warningSprite.setPosition(cx - warningSprite.width * 0.5, (FlxG.height - warningSprite.height) * 0.5);
    }
    
    override function onOutro()
    {
        cy = stopY;
        movingBlock.alpha = 1;
        setBlockScale(1);
    }
    
    override function onDead()
    {
        warningSprite.visible = false;
        movingBlock.visible = false;
    }
    
    override function onWarningUpdate()
    {
        var animationLength = Math.min(warningTime, WARNING_ANIMATION_MS);
        var t = progress(currentTime, time - warningTime, animationLength);
        setWarningScale(FlxEase.backOut(t));
    }
    
    override function onActiveUpdate()
    {
        var t = progress(currentTime, time, duration);
        cy = START_Y + (stopY - START_Y) * FlxEase.bounceOut(t);
        syncBlock();
    }
    
    override function onOutroUpdate()
    {
        var t = progress(currentTime, time + duration, outroDuration);
        var scale = 1 - FlxEase.quadIn(t);
        movingBlock.alpha = scale;
        setBlockScale(scale);
    }
    
    override function hits(obj:FlxBasic):Bool
    {
        return phase == Active && FlxG.overlap(obj, movingBlock);
    }
}
