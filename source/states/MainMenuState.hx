package states;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;

typedef MenuItem =
{
    var title:String;
    var iconID:String;
    var onClick:Void->Void;
    var isLocked:Bool;
}

class MainMenuState extends FlxState
{
    var camObj:FlxObject;
    var sun:FlxSprite;
    
    var elements:FlxTypedGroup<FlxSprite>;
    var icons:FlxTypedGroup<FlxSprite>;
    
    var scroll:Float = 0;
    var scrollTarget:Float = 0;
    final scrollSpeed:Float = 10;
    
    var textTitle:FlxText;
    var currentSelectedItem:String = "";
    
    final items:Array<MenuItem> = [
        /*{
                title: "Browse Levels",
                iconID: "editorHubBrowse",
                onClick: function() {},
                isLocked: true
            },
            {
                title: "Downloaded Levels ",
                iconID: "editorHubSaved",
                onClick: function() {},
                isLocked: true
            },
            {
                title: "Level Editor",
                iconID: "selectionEditor",
                onClick: function() {},
                isLocked: true
        },*/
        {
            title: "Normal Levels",
            iconID: "selectionNormal",
            onClick: function() {},
            isLocked: false
        },
        {
            title: "Player Customization",
            iconID: "selectionPlayerEditor",
            onClick: function() {},
            isLocked: false
        },
        {
            title: "Settings",
            iconID: "settingsHub",
            onClick: function() {},
            isLocked: false
        },
        /*{
            title: "Achieviments",
            iconID: "trophieAchieviment",
            onClick: function() {},
            isLocked: true
        }*/
    ];
    
    override function create()
    {
        persistentDraw = persistentUpdate = true;
        camObj = new FlxObject();
        camObj.screenCenter();
        camObj.y = -FlxG.height * 2;
        add(camObj);
        
        textTitle = new FlxText();
        textTitle.font = "assets/embed/fonts/nexa_bold.otf";
        textTitle.size = 22;
        textTitle.text = "Yay";
        textTitle.screenCenter(X);
        textTitle.y = FlxG.height - 90;
        textTitle.antialiasing = true;
        add(textTitle);
        
        sun = new FlxSprite();
        sun.loadGraphic("assets/images/menus/sun.png");
        sun.scale.set(0.5, 0.5);
        sun.updateHitbox();
        sun.screenCenter();
        add(sun);
        
        elements = new FlxTypedGroup<FlxSprite>();
        add(elements);
        
        icons = new FlxTypedGroup<FlxSprite>();
        add(icons);
        
        var sprIcons:FlxSprite = new FlxSprite();
        sprIcons.frames = FlxAtlasFrames.fromSparrow("assets/images/menus/menu_icons.png", "assets/images/menus/menu_icons.xml");
        sprIcons.animation.addByPrefix("errorIcon", "errorIcon", 1, true);
        sprIcons.animation.addByPrefix("exportIcon", "exportIcon", 1, true);
        sprIcons.animation.addByPrefix("importIcon", "importIcon", 1, true);
        sprIcons.animation.addByPrefix("lock", "lock", 1, true);
        sprIcons.animation.addByPrefix("star_rate", "star_rate", 1, true);
        sprIcons.animation.addByPrefix("star_rate_half", "star_rate_half", 1, true);
        sprIcons.animation.addByPrefix("star_rate_hole", "star_rate_hole", 1, true);
        sprIcons.animation.addByPrefix("sucessIcon", "sucessIcon", 1, true);
        sprIcons.animation.addByPrefix("userIcon", "userIcon", 1, true);
        
        for (item in items)
        {
            var spr:FlxSprite = new FlxSprite();
            spr.frames = FlxAtlasFrames.fromSparrow("assets/images/menus/selection_icons.png", "assets/images/menus/selection_icons.xml");
            spr.animation.addByPrefix(item.iconID, item.iconID, 0, true);
            spr.updateHitbox();
            spr.animation.play(item.iconID, true);
            
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
            if (items[Math.floor(scrollTarget)].isLocked)
                sprite.color = 0xff383838;
            else
                sprite.color = selected ? FlxColor.WHITE : 0xFF656565;
        }
        
        if (FlxG.keys.anyJustPressed([D, RIGHT]))
            scrollTarget = Math.min(elements.members.length - 1, scrollTarget + 1);
        else if (FlxG.keys.anyJustPressed([A, LEFT]))
            scrollTarget = Math.max(0, scrollTarget - 1);
        else if (FlxG.keys.justPressed.ENTER)
        {
            // push
        }
        
        textTitle.text = items[Math.floor(scrollTarget)].title;
        textTitle.screenCenter(X);
    }
}
