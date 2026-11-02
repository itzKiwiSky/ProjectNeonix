package editor;

import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.FlxSprite;

class EditorTimelineCursor extends FlxSprite
{
    public function new()
    {
        super();
        makeGraphic(48, 256 + 48, FlxColor.TRANSPARENT);
        updateHitbox();
        FlxSpriteUtil.drawLine(this, width * 0.5, 48, width * 0.5, height, {
            thickness: 2,
            color: FlxColor.WHITE,
        });
        FlxSpriteUtil.drawCircle(this, width * 0.5, width * 0.5, width * 0.5, 0xFFDF66B6);
    }
}
