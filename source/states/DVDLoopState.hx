package states;

import flixel.text.FlxText;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.PNGEncoderOptions;
import sys.FileSystem;
import sys.io.File;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.geom.Matrix;

class DVDLoopState extends FlxState
{
    var logo:FlxSprite;
    var bg:FlxSprite;
    
    // estado atual (tudo inteiro, então não tem drift de float)
    var px:Int = 0;
    var py:Int = 0;
    var vx:Int = 3;
    var vy:Int = 2;
    
    // estado inicial guardado pra comparar
    final startX:Int = 0;
    final startY:Int = 0;
    final startVX:Int = 3;
    final startVY:Int = 2;
    
    var maxX:Int;
    var maxY:Int;
    var frames:Int = 0;
    var frameIndex:Int = 0;
    
    var exportRect:Rectangle;
    var exportFrame:FlxSprite;
    
    var recording:Bool = true;
    var frameCount:FlxText;
    
    override function create()
    {
        super.create();
        
        bg = new FlxSprite();
        bg.loadGraphic("assets/images/meme/foxy.png");
        bg.setGraphicSize(FlxG.width, FlxG.height);
        bg.updateHitbox();
        bg.screenCenter();
        // add(bg);
        
        logo = new FlxSprite();
        logo.loadGraphic("assets/images/meme/spinning_foxy.png");
        logo.frames = FlxAtlasFrames.fromSparrow("assets/images/meme/spinning_foxy.png", "assets/images/meme/spinning_foxy.xml");
        logo.animation.addByPrefix("spin", "spinning_foxy", 30, true);
        logo.scale.set(0.5, 0.5);
        logo.updateHitbox();
        logo.animation.play("spin");
        add(logo);
        
        exportRect = new Rectangle((FlxG.width - 640) / 2, (FlxG.height - 200) / 2, 640, 200);
        
        exportFrame = new FlxSprite(exportRect.x, exportRect.y);
        exportFrame.makeGraphic(640, 200, FlxColor.TRANSPARENT, true);
        FlxSpriteUtil.drawRect(exportFrame, 1, 1, 638, 198, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.RED});
        add(exportFrame); // depois do logo, pra ficar por cima
        
        maxX = Std.int(exportRect.width - logo.width);
        maxY = Std.int(exportRect.height - logo.height);
        
        function gcd(a:Int, b:Int):Int
            return b == 0 ? a : gcd(b, a % b);
            
        function period(max:Int, v:Int):Int
        {
            var g = gcd(v, 2 * max);
            return Std.int(2 * max / g);
        }
        
        // no create(), depois de calcular maxX/maxY:
        var tx = period(maxX, vx);
        var ty = period(maxY, vy);
        trace('loop esperado: ${tx * ty / gcd(tx, ty)} frames');
        
        logo.setPosition(exportRect.x + px, exportRect.y + py);
        
        frameCount = new FlxText();
        frameCount.size = 20;
        frameCount.text = "";
        
        add(frameCount);
    }
    
    override function draw()
    {
        super.draw();
        if (recording)
            if (frames % 5 == 0)
                saveFrame();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        // 1 update = 1 passo. O elapsed nem é usado de propósito.
        px += vx;
        py += vy;
        
        // reflete em vez de só clampar, assim o movimento
        // continua sendo uma "volta" perfeita e o ciclo sempre fecha
        if (px < 0)
        {
            px = -px;
            
            vx = -vx;
        }
        if (px > maxX)
        {
            px = maxX - (px - maxX);
            vx = -vx;
        }
        if (py < 0)
        {
            py = -py;
            vy = -vy;
        }
        if (py > maxY)
        {
            py = maxY - (py - maxY);
            vy = -vy;
        }
        
        logo.setPosition(exportRect.x + px, exportRect.y + py);
        frames++;
        frameCount.text = 'frame: $frames';
        
        if (px == startX && py == startY && vx == startVX && vy == startVY)
        {
            trace('Loop fechou em $frames frames (${frames / FlxG.updateFramerate}s)');
            recording = false;
            frames = 0;
        }
    }
    
    function saveFrame():Void
    {
        #if sys
        if (!FileSystem.exists("frames"))
            FileSystem.createDirectory("frames");
            
        var bmp = new BitmapData(Std.int(exportRect.width), Std.int(exportRect.height), true, 0);
        bmp.draw(FlxG.game, new Matrix(1, 0, 0, 1, -exportRect.x, -exportRect.y));
        
        var bytes = bmp.encode(new Rectangle(0, 0, bmp.width, bmp.height), new PNGEncoderOptions());
        var name = StringTools.lpad(Std.string(frameIndex), "0", 4);
        File.saveBytes('frames/frame_$name.png', bytes);
        
        bmp.dispose();
        frameIndex++;
        #end
    }
}
