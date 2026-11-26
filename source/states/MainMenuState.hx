package states;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;

class MainMenuState extends FlxState
{
    var camObj:FlxObject;
    var sun:FlxSprite;
    
    var elements:FlxTypedGroup<FlxSprite>;
    
    var scroll:Float = 0;
    var scrollTarget:Float = 0;
    final scrollSpeed:Float = 10;
    
    override function create()
    {
        persistentDraw = persistentUpdate = true;
        camObj = new FlxObject();
        camObj.screenCenter();
        camObj.y = -FlxG.height * 2;
        add(camObj);
        
        sun = new FlxSprite();
        sun.loadGraphic("assets/images/menus/sun.png");
        sun.scale.set(0.5, 0.5);
        sun.updateHitbox();
        sun.screenCenter();
        add(sun);
        
        elements = new FlxTypedGroup<FlxSprite>();
        add(elements);
        
        final names:Array<String> = [
            "editorHubBrowse",
            "editorHubEditor",
            "editorHubSaved",
            "selectionEditor",
            "selectionNormal",
            "selectionPlayerEditor",
        ];
        
        for (name in names)
        {
            var spr:FlxSprite = new FlxSprite();
            spr.frames = FlxAtlasFrames.fromSparrow("assets/images/menus/selection_icons.png", "assets/images/menus/selection_icons.xml");
            spr.animation.addByPrefix(name, name, 0, true);
            spr.updateHitbox();
            spr.animation.play(name, true);
            elements.add(spr);
        }
        
        FlxG.camera.follow(camObj, null, 0.4);
        
        FlxTween.tween(camObj, {y: FlxG.height * 0.5}, 1.5, {
            ease: FlxEase.backOut,
        });
        
        super.create();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        scroll += (scrollTarget - scroll) * elapsed * scrollSpeed;
        
        for (i in 0...elements.members.length)
        {
            var sprite:FlxSprite = elements.members[i];
            var dist:Float = i - scroll;
            var spacing:Float = 300;
            
            var x:Float = (FlxG.width - sprite.width) * 0.5 + dist * spacing;
            var scale:Float = 0.5 - Math.min(Math.abs(dist) * 0.15, 0.05);
            
            var selected:Bool = Math.floor(scroll + 0.5) == i;
            
            sprite.x = x;
            sprite.screenCenter(Y);
            sprite.scale.set(scale, scale);
        }
        
        if (FlxG.keys.anyJustPressed([D, RIGHT]))
            scrollTarget = Math.min(elements.members.length - 1, scrollTarget + 1);
        else if (FlxG.keys.anyJustPressed([A, LEFT]))
            scrollTarget = Math.max(0, scrollTarget - 1);
        else if (FlxG.keys.justPressed.ENTER)
        {
            // push
        }
    }
}
