package objects.core;

import core.utils.TTFAtlas;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

enum abstract FrameStyle(String) to String
{
    var line = "┌┐└┘─│";
    var bold = "┏┓┗┛━┃";
    var text = "++++-|";
    var double = "╔╗╚╝═║";
    var block = "██████";
}

enum abstract FillStyle(String) to String
{
    var block = "█";
    var semigrid = "▓";
    var halfgrid = "▒";
    var grid = "░";
}

typedef CursorState =
{
    var visible:Bool;
    var x:Int;
    var y:Int;
    var savedX:Int;
    var savedY:Int;
    var reversed:Bool;
    var cursorColor:FlxColor;
    var cursorBackColor:FlxColor;
}

typedef CellState =
{
    var color:FlxColor;
    var backColor:FlxColor;
    var dirty:Bool;
    var reversed:Bool;
}

enum TermOp
{
    Char(c:String);
    SetCursor(x:Int, y:Int);
}

class Terminal extends FlxTypedSpriteGroup<FlxSprite>
{
    var buffer:Array<Array<String>> = [];
    var bufferState:Array<Array<CellState>> = [];
    var stdin:Array<TermOp> = [];
    
    var font:FlxBitmapFont;
    
    var terminalWidth:Int = 0;
    var terminalHeight:Int = 0;
    
    var charWidth:Int = 32;
    var charHeight:Int = 32;
    
    var charCost:Float = 1;
    var accumulator:Float = 0;
    
    var numCols:Int = 0;
    var numRows:Int = 0;
    
    var needsRedraw:Bool = true;
    
    var cellRect:Rectangle = new Rectangle();
    var glyphMatrix:Matrix = new Matrix();
    var glyphTint:ColorTransform = new ColorTransform();
    
    var cursor:FlxSprite;
    var blinkTimer:Float = 0;
    
    public var blinkRate:Float = 0.5;
    public var cursorChar(default, set):String = "_";
    
    var currentCursor:CursorState = {
        visible: true,
        x: 0,
        y: 0,
        savedX: 0,
        savedY: 0,
        reversed: false,
        cursorColor: FlxColor.WHITE,
        cursorBackColor: FlxColor.BLACK,
    };
    
    public var speed:Int = 800;
    public var useInterrupt:Bool = false;
    public var interruptKey:FlxKey = FlxKey.ENTER;
    public var isInterrupted(default, set):Bool = false;
    public var autoRollUp:Bool = false;
    
    var canvas:FlxSprite;
    
    public function new(width:Int, height:Int, fontPath:String, fontSize:Int)
    {
        super();
        
        final letters:String = "\u0001"
            + "☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼ !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{¦}~⌂ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■□";
            
        var atlas = TTFAtlas.build(fontPath, fontSize, letters);
        
        this.charWidth = atlas.cellW;
        this.charHeight = atlas.cellH;
        
        this.terminalWidth = width;
        this.terminalHeight = height;
        
        this.font = atlas.font;
        numCols = Std.int(width / charWidth);
        numRows = Std.int(height / charHeight);
        
        for (y in 0...numRows)
        {
            var row:Array<String> = [];
            var stateRow:Array<CellState> = [];
            for (x in 0...numCols)
            {
                row.push(" ");
                stateRow.push({
                    color: currentCursor.cursorColor,
                    backColor: currentCursor.cursorBackColor,
                    dirty: true,
                    reversed: false,
                });
            }
            buffer.push(row);
            bufferState.push(stateRow);
        }
        
        canvas = new FlxSprite();
        canvas.makeGraphic(numCols * charWidth, numRows * charHeight, FlxColor.BLACK, true);
        canvas.updateHitbox();
        add(canvas);
        
        cursor = new FlxSprite();
        buildCursorGraphic();
        add(cursor);
    }
    
    function buildCursorGraphic():Void
    {
        cursor.makeGraphic(charWidth, charHeight, FlxColor.TRANSPARENT, true);
        
        var glyph = font.getCharFrame(cursorChar.charCodeAt(0));
        if (glyph == null)
            return;
            
        glyphMatrix.identity();
        glyphMatrix.translate(-glyph.frame.x, -glyph.frame.y);
        cellRect.setTo(0, 0, charWidth, charHeight);
        cursor.pixels.draw(font.parent.bitmap, glyphMatrix, null, null, cellRect);
        cursor.dirty = true;
    }
    
    function updateCursor(elapsed:Float):Void
    {
        blinkTimer += elapsed;
        
        var lit:Bool = (blinkTimer % (blinkRate * 2)) < blinkRate;
        cursor.visible = currentCursor.visible && lit;
        
        cursor.setPosition(canvas.x + currentCursor.x * charWidth, canvas.y + currentCursor.y * charHeight);
        cursor.color = currentCursor.cursorColor;
    }
    
    public function putChar(x:Int, y:Int, char:String):Void
    {
        if (x < 0 || y < 0 || x >= numCols || y >= numRows)
            return;
            
        buffer[y][x] = char;
        
        var state:CellState = bufferState[y][x];
        state.color = currentCursor.cursorColor;
        state.backColor = currentCursor.cursorBackColor;
        state.reversed = currentCursor.reversed;
        state.dirty = true;
        
        needsRedraw = true;
    }
    
    function drawCell(cx:Int, cy:Int):Void
    {
        var state:CellState = bufferState[cy][cx];
        
        var fg:FlxColor = state.reversed ? state.backColor : state.color;
        var bg:FlxColor = state.reversed ? state.color : state.backColor;
        
        var left:Int = cx * charWidth;
        var top:Int = cy * charHeight;
        cellRect.setTo(left, top, charWidth, charHeight);
        
        canvas.pixels.fillRect(cellRect, bg);
        
        var glyph = font.getCharFrame(buffer[cy][cx].charCodeAt(0));
        if (glyph != null)
        {
            glyphMatrix.identity();
            glyphMatrix.translate(left - glyph.frame.x, top - glyph.frame.y);
            
            glyphTint.redMultiplier = fg.redFloat;
            glyphTint.greenMultiplier = fg.greenFloat;
            glyphTint.blueMultiplier = fg.blueFloat;
            glyphTint.alphaMultiplier = fg.alphaFloat;
            
            canvas.pixels.draw(font.parent.bitmap, glyphMatrix, glyphTint, null, cellRect);
        }
        
        state.dirty = false;
    }
    
    function updateDirtyGlyphs():Void
    {
        canvas.pixels.lock();
        for (cy in 0...numRows)
        {
            for (cx in 0...numCols)
            {
                if (bufferState[cy][cx].dirty)
                    drawCell(cx, cy);
            }
        }
        canvas.pixels.unlock();
        
        canvas.dirty = true;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        processStdin(elapsed);
        
        if (needsRedraw)
        {
            updateDirtyGlyphs();
            needsRedraw = false;
        }
        
        updateCursor(elapsed);
    }
    
    function processStdin(elapsed:Float)
    {
        if (needsRedraw)
        {
            updateDirtyGlyphs();
            needsRedraw = false;
        }
        
        if (useInterrupt && isInterrupted)
            return;
        if (stdin.length <= 0)
            return;
            
        var fb:Float = speed * elapsed + accumulator;
        var consumed:Int = 0;
        
        while (fb >= charCost && consumed < stdin.length)
        {
            var op:TermOp = stdin[consumed];
            consumed++;
            fb -= charCost;
            
            switch (op)
            {
                case Char("\x08"):
                    currentCursor.x = Std.int(Math.max(currentCursor.x - 1, 0));
                    
                case Char("\n"):
                    currentCursor.x = 0;
                    advanceLine();
                    
                case Char("\t"):
                    currentCursor.x += 4;
                    if (currentCursor.x >= numCols)
                    {
                        currentCursor.x = 0;
                        advanceLine();
                    }
                    
                case Char(c):
                    putChar(currentCursor.x, currentCursor.y, c);
                    currentCursor.x++;
                    if (currentCursor.x >= numCols)
                    {
                        currentCursor.x = 0;
                        advanceLine();
                    }
                    
                case SetCursor(x, y):
                    if (x >= 0 && y >= 0 && x < numCols && y < numRows)
                    {
                        currentCursor.x = x;
                        currentCursor.y = y;
                    }
            }
        }
        
        stdin.splice(0, consumed);
        accumulator = (stdin.length == 0) ? 0 : fb;
    }
    
    function advanceLine():Void
    {
        currentCursor.y++;
        if (currentCursor.y >= numRows)
        {
            currentCursor.y = numRows - 1;
            rollup(1);
        }
    }
    
    function rollup(lines:Int):Void
    {
        if (!autoRollUp)
            return;
            
        final row:Int = buffer.length;
        final col:Int = buffer[0].length;
        final lines:Int = Math.round(Math.min(lines, row - 1));
        
        buffer.splice(0, lines);
        bufferState.splice(0, lines);
        
        for (r in row - lines...row)
        {
            buffer[r] = [];
            bufferState[r] = [];
            for (c in 0...col)
            {
                buffer[r][c] = " ";
                bufferState[r][c] = createCell(currentCursor.cursorColor, currentCursor.cursorBackColor, currentCursor.reversed, true);
            }
        }
        
        for (y in 0...buffer.length)
            for (x in 0...col)
                bufferState[y][x].dirty = true;
                
        needsRedraw = true;
    }
    
    inline function createCell(color:FlxColor, backColor:FlxColor, reversed:Bool = false, dirty:Bool = false):CellState
        return {
            color: color,
            backColor: backColor,
            reversed: reversed,
            dirty: dirty,
        };
        
    public function print(text:String, x:Int = -1, y:Int = -1):Void
    {
        if (x >= 0 && y >= 0)
            stdin.push(SetCursor(x, y));
            
        for (i in 0...text.length)
            stdin.push(Char(text.charAt(i)));
    }
    
    function set_isInterrupted(value:Bool):Bool
    {
        return isInterrupted = value;
    }
    
    function set_cursorChar(value:String):String
    {
        cursorChar = value;
        if (cursor != null)
            buildCursorGraphic();
        return value;
    }
}
