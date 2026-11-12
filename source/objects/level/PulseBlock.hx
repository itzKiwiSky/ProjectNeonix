package objects.level;

import core.managers.ActorManager;
import core.LevelActor;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class PulseBlock extends LevelActor
{
    var warningSprite:FlxSprite;
    var activeSprite:FlxSprite;
    var attackSpeed:Float = 0;
    
    static inline var BASE_SIZE:Int = 128;
    
    public function new(x:Float = 0, y:Float = 0, time:Float = 0, warningTime:Float = 1000, attackSpeed:Float = 500, duration:Float = 500, outroDuration:Float = 200)
    {
        super(x - BASE_SIZE * 0.5, y - BASE_SIZE * 0.5, time, warningTime, duration, outroDuration);
        this.attackSpeed = attackSpeed;
        cx = x;
        cy = y;
        
        warningSprite = makeBlock();
        warningSprite.visible = false;
        add(warningSprite);
        
        activeSprite = makeBlock();
        activeSprite.visible = false;
        warningSprite.alpha = 0.5;
        add(activeSprite);
    }
    
    public static function selfRegister():Void
    {
        ActorManager.registerActor("pulse_square", e -> new PulseBlock(ActorManager.posX(e), ActorManager.posY(e), e.time, e.lead, e.params.duration, e.params.outro), Obstacle, [
            {
                key: "useRandomX",
                label: "Random X",
                kind: Checkbox,
                defaultValue: false
            },
            {
                key: "useRandomY",
                label: "Random Y",
                kind: Checkbox,
                defaultValue: false
            },
            {
                key: "x",
                label: "X",
                kind: Number,
                defaultValue: 640
            },
            {
                key: "y",
                label: "Y",
                kind: Number,
                defaultValue: 360
            },
            {
                key: "duration",
                label: "Duration",
                kind: Number,
                step: 250,
                defaultValue: 1250
            },
            {
                key: "outro",
                label: "Outro",
                kind: Number,
                step: 100,
                defaultValue: 500
            }
        ]);
    }
    
    function makeBlock():FlxSprite
    {
        var s = new FlxSprite();
        s.makeGraphic(BASE_SIZE, BASE_SIZE, FlxColor.TRANSPARENT, true);
        FlxSpriteUtil.drawRoundRect(s, 0, 0, BASE_SIZE, BASE_SIZE, 16, 16, FlxColor.WHITE);
        s.updateHitbox();
        return s;
    }
    
    inline function syncActive(obj:FlxSprite):Void
    {
        obj.updateHitbox();
        obj.setPosition(cx - obj.width * 0.5, cy - obj.height * 0.5);
    }
    
    function setScale(s:FlxSprite, v:Float)
    {
        s.scale.set(v, v);
        syncActive(s);
    }
    
    override function onWarningUpdate()
    {
        var t:Float = progress(currentTime, time - warningTime, 200);
        setScale(warningSprite, FlxEase.backOut(t));
    }
    
    override function onActiveUpdate()
    {
        var t:Float = progress(currentTime, time, 150);
        setScale(activeSprite, FlxEase.backOut(t));
    }
    
    override function onOutroUpdate()
    {
        var t:Float = progress(currentTime, time + duration, outroDuration);
        activeSprite.alpha = 1 - FlxEase.quadIn(t);
        setScale(activeSprite, 1 - FlxEase.quadIn(t));
    }
    
    override function onWarning()
    {
        warningSprite.visible = true;
        activeSprite.visible = false;
    }
    
    override function onActive()
    {
        warningSprite.visible = false;
        activeSprite.visible = true;
    }
    
    override function onDead()
    {
        warningSprite.visible = false;
        activeSprite.visible = false;
    }
    
    override public function hits(obj:FlxBasic):Bool
        return phase == Active && FlxG.overlap(obj, activeSprite);
}
