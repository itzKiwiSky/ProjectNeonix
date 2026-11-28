package objects.level;

import core.LevelActor;
import core.managers.ActorManager;
import core.managers.ActorManager.EventCategory;
import core.managers.ActorManager.FieldKind;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class Laser extends LevelActor
{
    static inline var DEFAULT_WIDTH:Int = 64;

    var warningSprite:FlxSprite;
    var activeSprite:FlxSprite;
    var beamWidth:Int;
    var xPosition:Float;

    public function new(x:Float, width:Int, time:Float = 0, warningTime:Float = 1000, duration:Float = 500, outroDuration:Float = 200)
    {
        super(0, 0, time, warningTime, duration, outroDuration);
        xPosition = cx = x;
        cy = FlxG.height * 0.5;
        beamWidth = Std.int(Math.max(1, width));

        warningSprite = makeBeam();
        warningSprite.alpha = 0.5;
        warningSprite.visible = false;
        add(warningSprite);

        activeSprite = makeBeam();
        activeSprite.visible = false;
        add(activeSprite);

        setBeamScale(warningSprite, 0);
        setBeamScale(activeSprite, 1);
    }

    public static function selfRegister():Void
    {
        ActorManager.registerActor("laser", e -> new Laser(
            ActorManager.posX(e),
            Std.int(ActorManager.num(e, "width", DEFAULT_WIDTH)),
            e.time,
            e.lead ?? 1000,
            ActorManager.num(e, "duration", 500),
            ActorManager.num(e, "outro", 200)
        ), EventCategory.Obstacle, [
            {
                key: "x",
                label: "X",
                kind: FieldKind.Number,
                defaultValue: 640
            },
            {
                key: "useRandomX",
                label: "Random X",
                kind: FieldKind.Checkbox,
                defaultValue: false
            },
            {
                key: "width",
                label: "Width",
                kind: FieldKind.Number,
                step: 8,
                min: 1,
                defaultValue: DEFAULT_WIDTH
            },
            {
                key: "duration",
                label: "Duration",
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

    function makeBeam():FlxSprite
    {
        var beam:FlxSprite = new FlxSprite();
        beam.makeGraphic(beamWidth, FlxG.height, FlxColor.TRANSPARENT, true);
        FlxSpriteUtil.drawRect(beam, 0, 0, beamWidth, FlxG.height, FlxColor.WHITE);
        beam.updateHitbox();
        syncBeam(beam);
        return beam;
    }

    inline function syncBeam(beam:FlxSprite):Void
    {
        beam.updateHitbox();
        beam.setPosition(xPosition - beam.width * 0.5, cy - beam.height * 0.5);
    }

    function setBeamScale(beam:FlxSprite, scaleX:Float):Void
    {
        beam.scale.set(scaleX, 1);
        syncBeam(beam);
    }

    override function onWaiting()
    {
        warningSprite.visible = false;
        activeSprite.visible = false;
    }

    override function onWarning()
    {
        warningSprite.visible = true;
        activeSprite.visible = false;
        warningSprite.alpha = 0.5;
        setBeamScale(warningSprite, 0);
    }

    override function onActive()
    {
        warningSprite.visible = false;
        activeSprite.visible = true;
        activeSprite.alpha = 1;
        setBeamScale(activeSprite, 1);
    }

    override function onOutro()
    {
        warningSprite.visible = false;
        activeSprite.visible = true;
        activeSprite.alpha = 1;
    }

    override function onDead()
    {
        warningSprite.visible = false;
        activeSprite.visible = false;
        activeSprite.alpha = 1;
    }

    override function onWarningUpdate()
    {
        var opening:Float = progress(currentTime, time - warningTime, warningTime);
        setBeamScale(warningSprite, FlxEase.sineIn(opening));
    }

    override function onOutroUpdate()
    {
        activeSprite.alpha = 1 - FlxEase.quadIn(progress(currentTime, outroStartTime, outroDuration));
    }

    override function hits(obj:FlxBasic):Bool
        return phase == Active && FlxG.overlap(activeSprite, obj);
}
