package core;

import flixel.FlxObject;
import flixel.FlxG;
import flixel.FlxBasic;
import core.managers.Timeline.TimelineEvent;
import core.Conductor;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

enum Phase
{
    Waiting;
    Warning;
    Active;
    Outro;
    Dead;
}

interface ILevelActor
{
    public function selfRegister():Void;
}

class LevelActor extends FlxTypedSpriteGroup<FlxSprite>
{
    public var time:Float = 0;
    public var warningTime:Float = 0;
    public var duration:Float = 0;
    public var outroDuration:Float = 0;
    public var phase:Null<Phase> = null;
    public var outroStartTime(default, null):Float = 0;
    public var hasTimelineKill(default, null):Bool = false;
    public var cx:Float;
    public var cy:Float;
    public var event(default, set):TimelineEvent;
    public var currentTime:Float = 0;
    public var useRandomX:Bool = false;
    public var useRandomY:Bool = false;
    
    var trackSet:TrackSet = new TrackSet(null);
    var transformEvents:Array<TimelineEvent> = [];
    var actorOriginX:Float;
    var actorOriginY:Float;
    var appliedMoveX:Float = 0;
    var appliedMoveY:Float = 0;
    var appliedRotation:Float = 0;
    var appliedScaleX:Float = 1;
    var appliedScaleY:Float = 1;
    public var timelineMoveX(default, null):Float = 0;
    public var timelineMoveY(default, null):Float = 0;
    public var timelineRotation(default, null):Float = 0;
    public var timelineScaleX(default, null):Float = 1;
    public var timelineScaleY(default, null):Float = 1;
    
    public var tintByActorsColor:Bool = true; // no LevelActor; a piscina põe false se o spike.png tem cores próprias
    
    public function new(x:Float = 0, y:Float = 0, time:Float = 0, warningTime:Float = 1000, duration:Float = 500, outroDuration:Float = 200)
    {
        super(x, y);
        actorOriginX = x;
        actorOriginY = y;
        if (useRandomX)
            x = FlxG.random.int(64, FlxG.width - 128);
            
        if (useRandomY)
            y = FlxG.random.int(64, FlxG.height - 128);
            
        this.time = time;
        this.warningTime = warningTime;
        this.duration = duration;
        this.outroDuration = outroDuration;
        outroStartTime = time + duration;
    }
    
    function phaseAt(now:Float):Phase
    {
        if (hasTimelineKill && now >= outroStartTime)
            return now < outroStartTime + outroDuration ? Outro : Dead;
        if (now < time - warningTime)
            return Waiting;
        if (now < time)
            return Warning;
        if (isPersistent())
            return Active;
        if (now < time + duration)
            return Active;
        if (now < time + duration + outroDuration)
            return Outro;
        return Dead;
    }
    
    public function lifeEnd():Float
    {
        if (hasTimelineKill)
        {
            if (outroStartTime < time)
                return outroStartTime;
            return outroStartTime + outroDuration;
        }
        return isPersistent() ? Math.POSITIVE_INFINITY : time + duration + outroDuration;
    }
        
    public function isInside(now:Float):Bool
    {
        var start:Float = time - warningTime;
        if (hasTimelineKill && outroStartTime < start)
            return false;
        return now >= start && now < lifeEnd();
    }

    inline function isPersistent():Bool
        return event != null && event.persistent == true;

    public function receiveTimelineKill(source:TimelineEvent)
    {
        if (!isPersistent() && source.time >= time + duration)
            return;
        if (hasTimelineKill)
            return;
        hasTimelineKill = true;
        outroStartTime = source.time;
    }
        
    override function update(elapsed:Float)
    {
        undoTimelineTransform();
        currentTime = Conductor.songPosition;
        var p = phaseAt(currentTime);
        if (p != phase)
        {
            phase = p;
            switch (p)
            {
                case Waiting:
                    onWaiting();
                case Warning:
                    onWarning();
                case Active:
                    onActive();
                case Outro:
                    onOutro();
                case Dead:
                    onDead();
            }
        }
        
        switch (p)
        {
            case Waiting:
                onWaitingUpdate();
            case Warning:
                onWarningUpdate();
            case Active:
                onActiveUpdate();
            case Outro:
                onOutroUpdate();
            case _:
        }
        
        super.update(elapsed);
        applyTimelineTransform(currentTime);
    }
    
    inline function progress(now:Float, start:Float, len:Float):Float
        return len <= 0 ? 1 : Math.max(0, Math.min(1, (now - start) / len));
        
    public function hits(obj:FlxBasic):Bool
        return false;
        
    // colisão sólida com um objeto que se move (o jogador); devolve se houve contato
    public function collide(obj:FlxObject):Bool
        return false;
        
    function set_event(e:TimelineEvent):TimelineEvent
    {
        event = e;
        trackSet = new TrackSet(e == null ? null : e.tracks);
        return e;
    }
    
    public inline function channel(name:String, def:Float):Float
        return trackSet.valueAt(name, currentTime - time, def);
        
    // events //
    public function onWaiting() {}
    
    public function onWarning() {}
    
    public function onActive() {}
    
    public function onOutro() {}
    
    public function onDead() {}
    
    public function onWaitingUpdate() {}
    
    public function onWarningUpdate() {}
    
    public function onActiveUpdate() {}
    
    public function onOutroUpdate() {}

    public function resetTimelineEvents() {}

    public function onTimelineEvent(name:String, source:TimelineEvent) {}

    public function resetActorTransforms()
        transformEvents = [];

    public function resetTimelineLifetime()
    {
        hasTimelineKill = false;
        outroStartTime = time + duration;
    }

    public function addTimelineTransform(source:TimelineEvent):Bool
    {
        var property:Dynamic = source.params == null ? null : Reflect.field(source.params, "property");
        var value:Dynamic = source.params == null ? null : Reflect.field(source.params, "value");
        var duration:Dynamic = source.params == null ? null : Reflect.field(source.params, "duration");
        var easing:Dynamic = source.params == null ? null : Reflect.field(source.params, "easing");
        if (!Std.isOfType(property, String) || !isTransformProperty(property))
            return false;
        if (!Std.isOfType(value, Int) && !Std.isOfType(value, Float))
            return false;
        if (property == "scale_x" || property == "scale_y")
            if (value <= 0)
                return false;
        if (duration != null && (!Std.isOfType(duration, Int) && !Std.isOfType(duration, Float)))
            return false;
        if (duration != null && duration < 0)
            return false;
        if (easing != null && !Std.isOfType(easing, String))
            return false;
        transformEvents.push(source);
        return true;
    }

    static inline function isTransformProperty(property:String):Bool
        return property == "move_x" || property == "move_y" || property == "rotate" || property == "scale_x" || property == "scale_y";

    function transformValue(property:String, base:Float, now:Float):Float
    {
        var segmentStart:Float = 0;
        var segmentFrom:Float = base;
        var segmentTo:Float = base;
        var segmentDuration:Float = 0;
        var segmentEase:Float->Float = Shared.easingFunctions.get("linear");

        for (source in transformEvents)
        {
            if (source.time > now)
                break;

            var sourceProperty:String = Reflect.field(source.params, "property");
            if (sourceProperty != property)
                continue;

            var target:Float = Reflect.field(source.params, "value");
            var duration:Float = Reflect.field(source.params, "duration") ?? 0;
            var easingName:String = Reflect.field(source.params, "easing") ?? "linear";
            var ease = Shared.easingFunctions.get(easingName);
            if (ease == null)
                ease = Shared.easingFunctions.get("linear");

            var from:Float = valueOnSegment(source.time, segmentStart, segmentFrom, segmentTo, segmentDuration, segmentEase);
            if (Reflect.field(source.params, "relative") == true)
                target = property == "scale_x" || property == "scale_y" ? from * target : from + target;
            segmentStart = source.time;
            segmentFrom = from;
            segmentTo = target;
            segmentDuration = duration;
            segmentEase = ease;
        }

        return valueOnSegment(now, segmentStart, segmentFrom, segmentTo, segmentDuration, segmentEase);
    }

    inline function valueOnSegment(now:Float, start:Float, from:Float, to:Float, duration:Float, ease:Float->Float):Float
    {
        if (duration <= 0 || now >= start + duration)
            return to;
        return from + (to - from) * ease(Math.max(0, Math.min(1, (now - start) / duration)));
    }

    function undoTimelineTransform()
    {
        if (appliedScaleX != 1 || appliedScaleY != 1 || appliedRotation != 0)
        {
            var pivotX:Float = actorOriginX + appliedMoveX;
            var pivotY:Float = actorOriginY + appliedMoveY;
            transformLeaves(0, 1 / appliedScaleX, 1 / appliedScaleY, pivotX, pivotY);
            transformLeaves(-appliedRotation, 1, 1, pivotX, pivotY);
        }
        if (appliedMoveX != 0)
            x = actorOriginX;
        if (appliedMoveY != 0)
            y = actorOriginY;
    }

    function applyTimelineTransform(now:Float)
    {
        var moveX = transformValue("move_x", 0, now);
        var moveY = transformValue("move_y", 0, now);
        var rotation = transformValue("rotate", 0, now);
        var scaleX = Math.max(0.01, transformValue("scale_x", 1, now));
        var scaleY = Math.max(0.01, transformValue("scale_y", 1, now));

        if (moveX != 0)
            x = actorOriginX + moveX;
        if (moveY != 0)
            y = actorOriginY + moveY;
        if (rotation != 0 || scaleX != 1 || scaleY != 1)
            transformLeaves(rotation, scaleX, scaleY, x, y);
        appliedMoveX = moveX;
        appliedMoveY = moveY;
        appliedRotation = rotation;
        appliedScaleX = scaleX;
        appliedScaleY = scaleY;
        timelineMoveX = moveX;
        timelineMoveY = moveY;
        timelineRotation = rotation;
        timelineScaleX = scaleX;
        timelineScaleY = scaleY;
    }

    function transformLeaves(rotation:Float, scaleX:Float, scaleY:Float, pivotX:Float, pivotY:Float)
    {
        var radians:Float = rotation * Math.PI / 180;
        var cos:Float = Math.cos(radians);
        var sin:Float = Math.sin(radians);
        transformGroup(this, sprite ->
        {
            var centerX:Float = sprite.x + sprite.width * 0.5;
            var centerY:Float = sprite.y + sprite.height * 0.5;
            var dx:Float = centerX - pivotX;
            var dy:Float = centerY - pivotY;
            var rotatedX:Float = pivotX + dx * cos - dy * sin;
            var rotatedY:Float = pivotY + dx * sin + dy * cos;
            var scaledX:Float = pivotX + (rotatedX - pivotX) * scaleX;
            var scaledY:Float = pivotY + (rotatedY - pivotY) * scaleY;

            sprite.angle += rotation;
            sprite.scale.x *= scaleX;
            sprite.scale.y *= scaleY;
            sprite.updateHitbox();
            sprite.setPosition(scaledX - sprite.width * 0.5, scaledY - sprite.height * 0.5);
        });
    }

    function transformGroup(group:FlxTypedSpriteGroup<FlxSprite>, transform:FlxSprite->Void)
    {
        for (sprite in group.members)
        {
            if (sprite == null)
                continue;
            if (Std.isOfType(sprite, FlxTypedSpriteGroup))
                transformGroup(cast sprite, transform);
            else
                transform(sprite);
        }
    }
}
