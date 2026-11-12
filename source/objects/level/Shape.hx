package objects.level;

import flixel.FlxG;
import core.managers.ActorManager;
import core.managers.ActorManager.EventCategory;
import core.managers.ActorManager.FieldKind;
import core.LevelActor;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

// retângulo ou círculo animado por trilhas: x, y, scale, angle, alpha
class Shape extends LevelActor
{
    static inline var GHOST_ALPHA:Float = 0.35; // no aviso a forma aparece fraca
    
    var body:FlxSprite;
    var baseX:Float;
    var baseY:Float;
    var baseW:Float;
    var baseH:Float;
    var circle:Bool;
    
    // o estado calculado no frame; o hits usa o mesmo que o desenho
    var curX:Float;
    var curY:Float;
    var curScale:Float = 1;
    var curAngle:Float = 0;
    
    var frameDX:Float = 0; // quanto a forma andou neste frame, para carregar quem está em cima
    var frameDY:Float = 0;
    
    public function new(x:Float, y:Float, w:Int, h:Int, circle:Bool, isSolid:Bool, time:Float, warningTime:Float, duration:Float, outroDuration:Float)
    {
        // o ator fica em (0, 0) e a forma usa coordenadas absolutas
        super(0, 0, time, warningTime, duration, outroDuration);
        
        this.circle = circle;
        baseX = curX = x;
        baseY = curY = y;
        baseW = w;
        baseH = circle ? w : h;
        
        // branca: a cor vem do actorsColor, como os outros atores
        body = new FlxSprite();
        body.makeGraphic(w, Std.int(baseH), FlxColor.TRANSPARENT, true);
        if (circle)
            FlxSpriteUtil.drawCircle(body, -1, -1, w * 0.5, FlxColor.WHITE);
        else
            FlxSpriteUtil.drawRoundRect(body, 0, 0, w, baseH, 16, 16, FlxColor.WHITE);
        body.visible = false;
        add(body);
        
        this.solid = isSolid && !circle; // o Flixel só separa retângulos
        body.immovable = true;
        body.setPosition(x - w * 0.5, y - baseH * 0.5);
    }
    
    function apply(phaseAlpha:Float)
    {
        curX = channel("x", baseX);
        curY = channel("y", baseY);
        curScale = channel("scale", 1);
        curAngle = channel("angle", 0);
        
        body.visible = true;
        body.alpha = phaseAlpha * FlxMath.bound(channel("alpha", 1), 0, 1);
        body.scale.set(curScale, curScale);
        body.updateHitbox(); // o retângulo de colisão acompanha a escala
        body.angle = curAngle;
        var nx = curX - body.width * 0.5;
        var ny = curY - body.height * 0.5;
        frameDX = nx - body.x;
        frameDY = ny - body.y;
        body.setPosition(nx, ny);
    }
    
    override function onWaiting()
        body.visible = false;
        
    override function onDead()
        body.visible = false;
        
    override function onWarningUpdate()
        apply(GHOST_ALPHA);
        
    override function onActiveUpdate()
        apply(1);
        
    override function onOutroUpdate()
        apply(1 - FlxEase.quadIn(progress(currentTime, time + duration, outroDuration)));
        
    // o jogador é tratado como um círculo; a forma pode estar girada e escalada
    override function hits(obj:FlxBasic):Bool
    {
        if (solid)
            return false; // sólido não machuca
            
        var o:FlxObject = Std.downcast(obj, FlxObject);
        if (phase != Active || o == null)
            return false;
            
        var r = Math.min(o.width, o.height) * 0.4;
        var dx = o.x + o.width * 0.5 - curX;
        var dy = o.y + o.height * 0.5 - curY;
        
        // leva o jogador para o espaço da forma, desfazendo a rotação
        var rad = -curAngle * Math.PI / 180;
        var lx = dx * Math.cos(rad) - dy * Math.sin(rad);
        var ly = dx * Math.sin(rad) + dy * Math.cos(rad);
        
        if (circle)
        {
            var rr = baseW * 0.5 * curScale + r;
            return lx * lx + ly * ly <= rr * rr;
        }
        
        var hw = baseW * 0.5 * curScale;
        var hh = baseH * 0.5 * curScale;
        var ex = lx - FlxMath.bound(lx, -hw, hw); // distância até o ponto do retângulo mais perto
        var ey = ly - FlxMath.bound(ly, -hh, hh);
        return ex * ex + ey * ey <= r * r;
    }
    
    override function collide(obj:FlxObject):Bool
    {
        if (!solid || phase != Active)
            return false;
            
        if (!FlxG.collide(obj, body))
            return false;
            
        // em cima da forma: ela leva o jogador junto (o Flixel não faz isso sozinho)
        if (obj.isTouching(DOWN) && obj.y + obj.height <= body.y + 4)
        {
            obj.x += frameDX;
            obj.y += frameDY;
        }
        return true;
    }
    
    public static function selfRegister()
    {
        ActorManager.registerActor("shape", e -> new Shape(ActorManager.num(e, "x", 640), ActorManager.num(e, "y", 360), Std.int(ActorManager.num(e, "w", 96)), Std.int(ActorManager.num(e, "h", 96)), e.params != null
            && Reflect.field(e.params, "circle") == true, e.params != null
            && Reflect.field(e.params, "solid") == true, e.time, e.lead ?? 750, ActorManager.num(e, "duration", 4000), ActorManager.num(e, "outro", 300)), EventCategory.Obstacle, [
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
                key: "solid",
                label: "Solid",
                kind: FieldKind.Checkbox,
                defaultValue: false
            },
            {
                key: "w",
                label: "Width",
                kind: FieldKind.Number,
                step: 8,
                defaultValue: 96
            },
            {
                key: "h",
                label: "Height",
                kind: FieldKind.Number,
                step: 8,
                defaultValue: 96
            },
            {
                key: "circle",
                label: "Circle",
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
}
