package objects.level;

import core.utils.Collision;
import flixel.util.FlxSpriteUtil;
import core.LevelActor;
import core.managers.ActorManager;
import core.managers.ActorManager.EventCategory;
import core.managers.ActorManager.FieldKind;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

class Sawblade extends LevelActor
{
    static inline var BASE_SIZE:Int = 128;
    static inline var HITBOX_SIZE:Int = 96;
    
    var sawSprite:FlxSprite;
    var sawHitbox:FlxSprite;
    var startX:Float;
    var startY:Float;
    var endX:Float;
    var endY:Float;
    var speed:Float;
    
    public function new(x:Float, y:Float, endX:Float, endY:Float, speed:Float, time:Float, warningTime:Float, duration:Float, outroDuration:Float)
    {
        super(0, 0, time, warningTime, duration, outroDuration);
        startX = cx = x;
        startY = cy = y;
        this.endX = endX;
        this.endY = endY;
        this.speed = Math.max(1, speed);
        
        sawSprite = new FlxSprite();
        sawSprite.loadGraphic("assets/images/game/sawblade.png");
        sawSprite.setGraphicSize(BASE_SIZE, BASE_SIZE);
        sawSprite.updateHitbox();
        sawSprite.visible = false;
        add(sawSprite);
        
        sawHitbox = new FlxSprite();
        sawHitbox.makeGraphic(HITBOX_SIZE, HITBOX_SIZE, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawCircle(sawHitbox, -1, -1, HITBOX_SIZE);
        sawHitbox.updateHitbox();
        sawHitbox.visible = true;
        sawHitbox.alpha = 0;
        add(sawHitbox);
        
        syncSprites();
    }
    
    public static function selfRegister():Void
    {
        ActorManager.registerActor("sawblade", e -> new Sawblade(ActorManager.posX(e), ActorManager.num(e, "y", FlxG.height * 0.5), ActorManager.num(e, "endX", FlxG.width - BASE_SIZE * 0.5), ActorManager.num(e, "endY", FlxG.height * 0.5), ActorManager.num(e, "speed", 300), e.time, e.lead ?? 750, ActorManager.num(e, "duration", 4000), ActorManager.num(e, "outro", 300)), EventCategory.Obstacle, [
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
                label: "Start X",
                kind: FieldKind.Number,
                defaultValue: 128
            },
            {
                key: "y",
                label: "Start Y",
                kind: FieldKind.Number,
                defaultValue: 360
            },
            {
                key: "endX",
                label: "End X",
                kind: FieldKind.Number,
                defaultValue: 1152
            },
            {
                key: "endY",
                label: "End Y",
                kind: FieldKind.Number,
                defaultValue: 360
            },
            {
                key: "speed",
                label: "Speed (px/s)",
                kind: FieldKind.Number,
                step: 25,
                defaultValue: 300
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
    
    inline function syncSprites():Void
    {
        sawSprite.updateHitbox();
        sawSprite.setPosition(cx - sawSprite.width * 0.5, cy - sawSprite.height * 0.5);
        
        sawHitbox.updateHitbox();
        sawHitbox.setPosition(cx - sawHitbox.width * 0.5, cy - sawHitbox.height * 0.5);
    }
    
    function moveAt(now:Float):Void
    {
        var dx:Float = endX - startX;
        var dy:Float = endY - startY;
        var distance:Float = Math.sqrt(dx * dx + dy * dy);
        var travelTime:Float = distance / speed * 1000;
        var t:Float = progress(now, time, travelTime);
        cx = startX + dx * t;
        cy = startY + dy * t;
        sawSprite.angle = (now - time) * 0.36;
        syncSprites();
    }
    
    override function onWaiting()
    {
        sawSprite.visible = false;
        sawHitbox.visible = false;
    }
    
    override function onWarning()
    {
        cx = startX;
        cy = startY;
        sawSprite.visible = true;
        sawSprite.alpha = 0.5;
        sawHitbox.visible = true;
        syncSprites();
    }
    
    override function onActive()
    {
        sawSprite.visible = true;
        sawSprite.alpha = 1;
        sawHitbox.visible = true;
    }
    
    override function onOutro()
    {
        sawSprite.visible = true;
        sawHitbox.visible = true;
    }
    
    override function onDead()
    {
        sawSprite.visible = false;
        sawHitbox.visible = false;
    }
    
    override function onWaitingUpdate() {}
    
    override function onWarningUpdate()
    {
        cx = startX;
        cy = startY;
        syncSprites();
    }
    
    override function onActiveUpdate()
        moveAt(currentTime);
        
    override function onOutroUpdate()
        sawSprite.alpha = 1 - FlxEase.quadIn(progress(currentTime, outroStartTime, outroDuration));
        
    override function hits(obj:FlxBasic):Bool
    {
        var playerRect:CollisionShapeRect = Collision.rectShapeFromFlxSprite(cast obj);
        var rad:Float = HITBOX_SIZE * 0.5 * Math.max(timelineScaleX, timelineScaleY);
        var circHitbox:CollisionShapeCircle = Collision.createCircleShape(0, 0, rad);
        
        if (!sawSprite.visible)
            return false;
            
        circHitbox.x = sawHitbox.x + HITBOX_SIZE * 0.5;
        circHitbox.y = sawHitbox.y + HITBOX_SIZE * 0.5;
        if (Collision.rectCircle(playerRect, circHitbox))
            return true;
        return false;
    }
}
