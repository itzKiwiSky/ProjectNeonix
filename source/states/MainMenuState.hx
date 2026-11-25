package states;

import flixel.util.FlxGradient;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import core.Conductor;
import flixel.FlxG;
import flixel.FlxSprite;
import core.MusicSyncedState;

class MainMenuState extends MusicSyncedState
{
    var logo:FlxSprite;
    var logoFX:FlxSprite;
    
    var logoScale:Float = 0.25;
    var logoScaleFX:Float = 0.25;
    var logoAlpha:Float = 0;
    var updateEffect:Bool = false;
    var logoEffectSprites:FlxTypedGroup<FlxSprite>;
    var beats:Int = 0;
    
    var sun:FlxSprite;
    
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
        sun.y = 100;
        
        add(sun);
        
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
            FlxG.sound.music.play();
        }
        
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
    }
    
    override function onBeatHit()
    {
        inline function creatFXSprite()
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
                creatFXSprite();
                logoScale = 0.29;
            }
        }
        else
        {
            creatFXSprite();
            logoScale = 0.27;
        }
    }
}
