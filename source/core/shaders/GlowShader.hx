package core.shaders;

import flixel.system.FlxAssets.FlxShader;

class GlowShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header

        uniform float uGlowPower;
        uniform float uGlowStrength;
        uniform vec4 uGlowColor;
        uniform float uContrast;

        void main()
        {
            vec2 uv = openfl_TextureCoordv;
            float p = uGlowPower;

            vec4 c = flixel_texture2D(bitmap, uv);
            c.rgb *= (1.0 + uContrast);
            vec4 oldColor = c;

            float strength = uGlowStrength + 0.5;

            vec4 sum = c;
            sum += flixel_texture2D(bitmap, uv + vec2( 0.0, -p));
            sum += flixel_texture2D(bitmap, uv + vec2(-p,   -p));
            sum += flixel_texture2D(bitmap, uv + vec2(-p,    0.0));
            sum += flixel_texture2D(bitmap, uv + vec2(-p,    p));
            sum += flixel_texture2D(bitmap, uv + vec2( 0.0,  p));
            sum += flixel_texture2D(bitmap, uv + vec2( p,    p));
            sum += flixel_texture2D(bitmap, uv + vec2( p,    0.0));
            sum += flixel_texture2D(bitmap, uv + vec2( p,   -p));
            vec4 blur = sum / 9.0;

            vec4 result;
            result.a   = blur.a + oldColor.a;
            result.rgb = oldColor.rgb / 2.0 + blur.rgb * strength;

            if (oldColor.a < 1.0 && p > 0.0)
            {
                result.a   = blur.a + oldColor.a;
                result.rgb = uGlowColor.rgb * p * 100.0 * (1.0 - oldColor.a)
                           + oldColor.rgb * oldColor.a;
            }
            else if (oldColor.a < 1.0)
            {
                result.a = oldColor.a;
            }

            gl_FragColor = result;
        }
    ')
    public function new(power:Float = 0.002, strength:Float = 0.0, contrast:Float = 0.0, color:Int = 0xFFFFFFFF)
    {
        super();
        trace(data.uGlowPower, data.uGlowColor);
        data.uGlowPower.value = [power];
        data.uGlowStrength.value = [strength];
        data.uContrast.value = [contrast];
        setColor(color);
    }
    
    public function setColor(color:Int):Void
    {
        data.uGlowColor.value = [
            ((color >> 16) & 0xFF) / 255.0,
            ((color >> 8) & 0xFF) / 255.0,
            (color & 0xFF) / 255.0,
            1.0
        ];
    }
}
