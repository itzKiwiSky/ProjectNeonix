package core.shaders;

import flixel.system.FlxAssets.FlxShader;

class GrayscaleShader extends FlxShader
{
    public var strength(get, set):Float;
    
    @:glFragmentSource('
        #pragma header

        uniform float amount;

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
            
            // luminância Rec. 709 (telas sRGB); a antiga 0.299/0.587/0.114 é a Rec. 601
            float gray = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
            
            // 0.0 = cor original, 1.0 = cinza; o alfa passa intacto
            gl_FragColor = vec4(mix(color.rgb, vec3(gray), clamp(amount, 0.0, 1.0)), color.a);
        }
    ')
    public function new(initialAmount:Float = 0.0)
    {
        super();
        strength = initialAmount;
    }
    
    function get_strength():Float
    {
        var v:Array<Float> = data.amount.value;
        return v == null || v.length == 0 ? 0.0 : v[0];
    }
    
    function set_strength(value:Float):Float
    {
        var clamped = Math.max(0.0, Math.min(1.0, value));
        data.amount.value = [clamped];
        return clamped;
    }
}
