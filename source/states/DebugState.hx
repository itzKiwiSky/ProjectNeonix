package states;

import flixel.FlxG;
import objects.core.Terminal;
import flixel.FlxState;

class DebugState extends FlxState
{
    var terminal:Terminal;
    
    override function create()
    {
        terminal = new Terminal(FlxG.width, FlxG.height, 32, 32);
        add(terminal);
        
        terminal.print("Hello World", 1, 1);
        
        super.create();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}
