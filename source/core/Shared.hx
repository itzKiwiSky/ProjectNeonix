package core;

import flixel.tweens.FlxEase;

class Shared
{
    public static final easingFunctions:Map<String, Float->Float> = [
        "backIn" => FlxEase.backIn,
        "backInOut" => FlxEase.backInOut,
        "backOut" => FlxEase.backOut,
        "bounceIn" => FlxEase.bounceIn,
        "bounceInOut" => FlxEase.bounceInOut,
        "bounceOut" => FlxEase.bounceOut,
        "circIn" => FlxEase.circIn,
        "circInOut" => FlxEase.circInOut,
        "circOut" => FlxEase.circOut,
        "cubeIn" => FlxEase.cubeIn,
        "cubeInOut" => FlxEase.cubeInOut,
        "cubeOut" => FlxEase.cubeOut,
        "elasticIn" => FlxEase.elasticIn,
        "elasticInOut" => FlxEase.elasticInOut,
        "elasticOut" => FlxEase.elasticOut,
        "expoIn" => FlxEase.expoIn,
        "expoInOut" => FlxEase.expoInOut,
        "expoOut" => FlxEase.expoOut,
        "linear" => FlxEase.linear,
        "quadIn" => FlxEase.quadIn,
        "quadInOut" => FlxEase.quadInOut,
        "quadOut" => FlxEase.quadOut,
        "quartIn" => FlxEase.quartIn,
        "quartInOut" => FlxEase.quartInOut,
        "quartOut" => FlxEase.quartOut,
        "quintIn" => FlxEase.quintIn,
        "quintInOut" => FlxEase.quintInOut,
        "quintOut" => FlxEase.quintOut,
        "sineIn" => FlxEase.sineIn,
        "sineInOut" => FlxEase.sineInOut,
        "sineOut" => FlxEase.sineOut,
        "smoothStepIn" => FlxEase.smoothStepIn,
        "smoothStepInOut" => FlxEase.smoothStepInOut,
        "smoothStepOut" => FlxEase.smoothStepOut,
        "smootherStepIn" => FlxEase.smootherStepIn,
        "smootherStepInOut" => FlxEase.smootherStepInOut,
        "smootherStepOut" => FlxEase.smootherStepOut
    ];
}
