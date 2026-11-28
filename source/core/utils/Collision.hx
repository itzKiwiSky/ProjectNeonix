package core.utils;

import echo.Shape;
import echo.shape.Circle;
import echo.shape.Polygon;
import echo.shape.Rect;
import flixel.FlxSprite;

class Collision
{
    public static function spriteSprite(first:FlxSprite, second:FlxSprite):Bool
    {
        var a:Rect = rectFromSprite(first);
        var b:Rect = rectFromSprite(second);
        var overlaps:Bool = a.overlaps(b);
        a.put();
        b.put();
        return overlaps;
    }

    public static function circleSprite(x:Float, y:Float, radius:Float, sprite:FlxSprite):Bool
    {
        if (radius <= 0)
            return false;

        var circle:Circle = Circle.get(x, y, radius);
        var rect:Rect = rectFromSprite(sprite);
        var overlaps:Bool = circle.overlaps(rect);
        circle.put();
        rect.put();
        return overlaps;
    }

    public static function ellipseSprite(x:Float, y:Float, radiusX:Float, radiusY:Float, rotation:Float, sprite:FlxSprite):Bool
    {
        if (radiusX <= 0 || radiusY <= 0)
            return false;

        var ellipse:Shape;
        if (Math.abs(radiusX - radiusY) < 0.001)
            ellipse = Circle.get(x, y, radiusX);
        else
            ellipse = Polygon.get(x, y, 32, 1, rotation, radiusX, radiusY);

        var rect:Rect = rectFromSprite(sprite);
        var overlaps:Bool = ellipse.overlaps(rect);
        ellipse.put();
        rect.put();
        return overlaps;
    }

    static inline function rectFromSprite(sprite:FlxSprite):Rect
        return Rect.get(sprite.x + sprite.width * 0.5, sprite.y + sprite.height * 0.5, sprite.width, sprite.height, sprite.angle);
}
