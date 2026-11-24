package core.utils;

import openfl.text.Font;
import openfl.text.TextLineMetrics;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.math.FlxPoint;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFormat;

typedef TTFAtlasResult =
{
    font:FlxBitmapFont,
    cellW:Int,
    cellH:Int
}

class TTFAtlas
{
    // o TextField reserva 2px de margem em volta do texto
    static inline var GUTTER:Int = 2;
    
    public static function build(fontPath:String, size:Int, letters:String):TTFAtlasResult
    {
        var ttf:Font = Assets.getFont(fontPath);
        
        var tf:TextField = new TextField();
        tf.embedFonts = true;
        tf.defaultTextFormat = new TextFormat(ttf.fontName, size, 0xFFFFFF);
        tf.text = "M";
        
        // fonte monoespaçada: o "M" mede a célula inteira
        var m:TextLineMetrics = tf.getLineMetrics(0);
        var cellW:Int = Math.ceil(m.width);
        var cellH:Int = Math.ceil(m.ascent + m.descent);
        
        var atlas:BitmapData = new BitmapData(cellW * 16, cellH * 16, true, 0x00000000);
        var matrix:Matrix = new Matrix();
        
        for (i in 0...letters.length)
        {
            if (i == 0)
                continue; // posição 0 é só a chave falsa (\u0001)
                
            tf.text = letters.charAt(i);
            matrix.identity();
            matrix.translate((i % 16) * cellW - GUTTER, Std.int(i / 16) * cellH - GUTTER);
            atlas.draw(tf, matrix);
        }
        
        var graphic:FlxGraphic = FlxGraphic.fromBitmapData(atlas, false, 'ttf:$fontPath:$size');
        var font:flixel.text.FlxBitmapFont = FlxBitmapFont.fromMonospace(graphic, letters, FlxPoint.get(cellW, cellH));
        
        return {font: font, cellW: cellW, cellH: cellH};
    }
}
