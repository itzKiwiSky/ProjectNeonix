package objects;

import core.ActorManager;
import core.Conductor;
import core.LevelActor;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

typedef BulletConfig =
{
    var count:Int; // balas por rajada
    var interval:Float; // ms entre rajadas
    var speed:Float; // px por segundo
    var angle:Float; // ângulo inicial em graus (0 = direita)
    var spread:Float; // abertura total em graus (360 = círculo)
    var life:Float; // ms que cada bala dura
}

class BulletEmitter extends LevelActor
{
    static inline var BODY_SIZE:Int = 48;
    static inline var MAX_BULLETS:Int = 512; // trava de segurança do pool
    
    var cfg:BulletConfig;
    var volleys:Int;
    var bullets:Array<Bullet> = [];
    var body:FlxSprite;
    
    public function new(x:Float, y:Float, time:Float, warningTime:Float, duration:Float, outroDuration:Float, cfg:BulletConfig)
    {
        super(x, y, time, warningTime, duration, outroDuration);
        
        cx = x;
        cy = y;
        
        cfg.count = Std.int(Math.max(1, cfg.count));
        cfg.interval = Math.max(1, cfg.interval);
        this.cfg = cfg;
        
        volleys = Std.int(Math.max(1, Math.floor(duration / cfg.interval)));
        volleys = Std.int(Math.min(volleys, Math.floor(MAX_BULLETS / cfg.count)));
        
        // o corpo do emissor
        body = new FlxSprite();
        body.makeGraphic(BODY_SIZE, BODY_SIZE, FlxColor.TRANSPARENT, true);
        FlxSpriteUtil.drawCircle(body, -1, -1, BODY_SIZE * 0.5, FlxColor.WHITE);
        add(body);
        body.setPosition(cx - BODY_SIZE * 0.5, cy - BODY_SIZE * 0.5); // depois do add: o grupo soma a posição dele
        body.visible = false;
        
        // todas as balas já existem; daqui pra frente só reposiciona e esconde
        for (v in 0...volleys)
        {
            for (i in 0...cfg.count)
            {
                var b = new Bullet(v, i);
                add(b);
                bullets.push(b);
            }
        }
    }
    
    public static function selfRegister():Void
    {
        ActorManager.registerActor("bullet_emitter", e -> new BulletEmitter(ActorManager.posX(e), ActorManager.posY(e), e.time, e.lead, ActorManager.num(e, "duration", 2000), ActorManager.num(e, "outro", 300), {
            count: Std.int(ActorManager.num(e, "count", 8)),
            interval: ActorManager.num(e, "interval", 250),
            speed: ActorManager.num(e, "speed", 300),
            angle: ActorManager.num(e, "angle", 0),
            spread: ActorManager.num(e, "spread", 360),
            life: ActorManager.num(e, "life", 3000)
        }), Obstacle, [
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
                key: "duration",
                label: "Duration",
                kind: Number,
                step: 250,
                defaultValue: 2000
            },
            {
                key: "outro",
                label: "Outro",
                kind: Number,
                step: 100,
                defaultValue: 300
            },
            {
                key: "count",
                label: "Count",
                kind: Number,
                step: 1,
                defaultValue: 8
            },
            {
                key: "interval",
                label: "Interval",
                kind: Number,
                step: 50,
                defaultValue: 250
            },
            {
                key: "speed",
                label: "Speed",
                kind: Number,
                step: 25,
                defaultValue: 300
            },
            {
                key: "angle",
                label: "Angle",
                kind: Number,
                step: 15,
                defaultValue: 0
            },
            {
                key: "spread",
                label: "Spread",
                kind: Number,
                step: 15,
                defaultValue: 360
            },
            {
                key: "life",
                label: "Life",
                kind: Number,
                step: 250,
                defaultValue: 3000
            }
        ]);
    }
    
    // o emissor vive até a última bala sumir
    override public function lifeEnd():Float
    {
        var lastShot = time + (volleys - 1) * cfg.interval;
        return Math.max(super.lifeEnd(), lastShot + cfg.life);
    }
    
    function angleOf(index:Int):Float
    {
        if (cfg.spread >= 360)
            return cfg.angle + (360 / cfg.count) * index; // círculo: as pontas se encontrariam
        if (cfg.count == 1)
            return cfg.angle;
        return cfg.angle - cfg.spread * 0.5 + (cfg.spread / (cfg.count - 1)) * index;
    }
    
    function updateBullets(now:Float)
    {
        for (b in bullets)
        {
            var age = now - (time + b.volley * cfg.interval);
            b.visible = age >= 0 && age < cfg.life;
            if (!b.visible)
                continue;
                
            var rad = angleOf(b.index) * Math.PI / 180;
            var dist = cfg.speed * age / 1000;
            b.setPosition(cx + Math.cos(rad) * dist - Bullet.SIZE * 0.5, cy + Math.sin(rad) * dist - Bullet.SIZE * 0.5);
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed); // troca de fase e ganchos
        updateBullets(Conductor.songPosition);
    }
    
    // corpo do emissor
    inline function setBodyScale(s:Float)
        body.scale.set(s, s);
        
    override function onWaiting()
        body.visible = false;
        
    override function onWarning()
    {
        body.visible = true;
        body.alpha = 0.5;
    }
    
    override function onActive()
    {
        body.visible = true;
        body.alpha = 1;
        setBodyScale(1);
    }
    
    override function onOutro()
    {
        body.visible = true;
        body.alpha = 1;
    }
    
    override function onDead()
        body.visible = false;
        
    override function onWarningUpdate()
        setBodyScale(FlxEase.backOut(progress(currentTime, time - warningTime, 200)));
        
    override function onOutroUpdate()
        setBodyScale(1 - FlxEase.quadOut(progress(currentTime, time + duration, outroDuration)));
        
    // círculo contra círculo, contando só as balas visíveis
    override public function hits(obj:FlxBasic):Bool
    {
        var o:FlxObject = cast obj;
        var px = o.x + o.width * 0.5;
        var py = o.y + o.height * 0.5;
        var r = Bullet.SIZE * 0.5 + Math.min(o.width, o.height) * 0.4;
        
        for (b in bullets)
        {
            if (!b.visible)
                continue;
            var dx = b.x + Bullet.SIZE * 0.5 - px;
            var dy = b.y + Bullet.SIZE * 0.5 - py;
            if (dx * dx + dy * dy < r * r)
                return true;
        }
        return false;
    }
}
