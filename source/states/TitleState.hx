package states;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxObject;
import flixel.util.FlxGradient;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import core.Conductor;
import flixel.FlxG;
import flixel.FlxSprite;
import core.MusicSyncedState;

class TitleState extends MusicSyncedState
{
    var logo:FlxSprite;
    var logoFX:FlxSprite;
    
    var logoScale:Float = 0.25;
    var logoScaleFX:Float = 0.25;
    var logoAlpha:Float = 0;
    var updateEffect:Bool = false;
    var logoEffectSprites:FlxTypedGroup<FlxSprite>;
    var beats:Int = 0;
    var pressToStart:FlxSprite;
    
    var sun:FlxSprite;
    
    var camObj:FlxObject;
    
    override function create()
    {
        logo = new FlxSprite();
        logoFX = new FlxSprite();
        sun = new FlxSprite();
        logoEffectSprites = new FlxTypedGroup<FlxSprite>();
        
        sun.loadGraphic("assets/images/menus/sun.png");
        sun.scale.set(0.5, 0.5);
        sun.updateHitbox();
        sun.screenCenter(X);
        sun.y = 128;
        add(sun);
        
        pressToStart = new FlxSprite();
        pressToStart.loadGraphic("assets/images/menus/menuText.png");
        pressToStart.scale.set(0.43, 0.43);
        pressToStart.updateHitbox();
        pressToStart.screenCenter(X);
        pressToStart.y = FlxG.height - 128;
        add(pressToStart);
        
        logo.loadGraphic("assets/images/menus/logo_thingy.png");
        logo.scale.set(logoScale, logoScale);
        logo.updateHitbox();
        logo.screenCenter(X);
        logo.y = 90;
        add(logo);
        add(logoEffectSprites);
        
        if (FlxG.sound.music == null)
        {
            FlxG.sound.music = FlxG.sound.create("assets/embed/music/future_base.ogg");
            FlxG.sound.music.persist = true;
            FlxG.sound.music.play();
        }
        
        camObj = new FlxObject();
        camObj.screenCenter();
        add(camObj);
        
        FlxG.camera.follow(camObj, null, 0.4);
        
        Conductor.changeBPM(91);
        
        super.create();
    }
    
    override function update(elapsed:Float)
    {
        if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;
            
        super.update(elapsed);
        
        logoEffectSprites.forEachAlive((s:FlxSprite) ->
        {
            s.scale.x += 1.5 * elapsed;
            s.scale.y += 1.5 * elapsed;
            s.setPosition(logo.x, logo.y);
            s.alpha -= 2.5 * elapsed;
            
            if (s.alpha <= 0)
                s.kill();
        });
        
        logo.scale.set(logoScale, logoScale);
        if (logoScale > 0.25)
            logoScale = FlxMath.lerp(logoScale, 0.25, 0.0745);
            
        if (FlxG.keys.justPressed.ENTER)
        {
            FlxG.camera.flash(FlxColor.WHITE, 1, () ->
            {
                FlxTween.tween(camObj, {y: FlxG.height * 2}, 2, {
                    ease: FlxEase.backIn,
                    onComplete: (t:FlxTween) -> FlxG.switchState(() -> new MainMenuState())
                });
            });
        }
    }
    
    override function onBeatHit()
    {
        inline function createFXSprite()
        {
            var s:FlxSprite = logoEffectSprites.recycle(FlxSprite, () ->
            {
                final obj:FlxSprite = new FlxSprite();
                obj.loadGraphic("assets/images/menus/logo_fx.png");
                obj.scale.set(0.25, 0.25);
                obj.updateHitbox();
                obj.alpha = 1;
                obj.setPosition(logo.x, logo.y);
                return obj;
            });
            
            s.setPosition(logo.x, logo.y);
            s.scale.set(0.25, 0.25);
            s.alpha = 1;
        }
        
        beats++;
        
        if (beats < 16 || beats > 30)
        {
            if (beats % 2 == 0)
            {
                createFXSprite();
                logoScale = 0.29;
            }
        }
        else
        {
            createFXSprite();
            logoScale = 0.27;
        }
    }
}
