package core.utils;

import flixel.math.FlxMath;
import flixel.FlxSprite;

typedef CollisionShapeRect =
{
    var x:Float;
    var y:Float;
    var width:Float;
    var height:Float;
}

typedef CollisionShapeCircle =
{
    var x:Float;
    var y:Float;
    var radius:Float;
}

typedef CollisionShapePoint =
{
    var x:Float;
    var y:Float;
}

class Collision
{
    public inline static function rectShapeFromFlxSprite(sprite:FlxSprite):CollisionShapeRect
        return {
            x: sprite.x,
            y: sprite.y,
            width: sprite.width,
            height: sprite.height
        }
        
    public inline static function createCircleShape(x:Float = 0, y:Float = 0, radius:Float = 2):CollisionShapeCircle
        return {
            x: x,
            y: y,
            radius: radius
        }
        
    public static function rectCircle(rect:CollisionShapeRect, circle:CollisionShapeCircle):Bool
    {
        if (circle.radius <= 0)
            return false;

        var closestX = FlxMath.bound(circle.x, rect.x, rect.x + rect.width);
        var closestY = FlxMath.bound(circle.y, rect.y, rect.y + rect.height);
        var dx = circle.x - closestX;
        var dy = circle.y - closestY;
        return dx * dx + dy * dy < circle.radius * circle.radius;
    }

    public static function circleCircle(first:CollisionShapeCircle, second:CollisionShapeCircle):Bool
    {
        if (first.radius <= 0 || second.radius <= 0)
            return false;

        var dx = first.x - second.x;
        var dy = first.y - second.y;
        var radiusSum = first.radius + second.radius;
        return dx * dx + dy * dy < radiusSum * radiusSum;
    }
}
