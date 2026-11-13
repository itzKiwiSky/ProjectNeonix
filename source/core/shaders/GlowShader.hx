package core.shaders;

import flixel.system.FlxAssets.FlxShader;

class GlowShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header

        uniform float uGlowSize;
        uniform float uIntensity;
        uniform float uBrightnessThreshold;

        void main()
        {
            vec2 uv = openfl_TextureCoordv;
            vec4 texColor = flixel_texture2D(bitmap, uv);

            vec2 texelSize = uGlowSize / openfl_TextureSize;
            vec4 colorSum = vec4(0.0);

            for (float x = -2.0; x <= 2.0; x += 1.0)
            {
                for (float y = -2.0; y <= 2.0; y += 1.0)
                {
                    vec4 sampleColor = flixel_texture2D(bitmap, uv + vec2(x, y) * texelSize);
                    
                    // Check how bright the pixel is (optional: makes only bright colors glow)
                    float brightness = dot(sampleColor.rgb, vec3(0.299, 0.587, 0.114));
                    if (brightness >= uBrightnessThreshold)
                    {
                        // Multiply RGB by alpha so transparent pixels do not bleed dark edges
                        colorSum += vec4(sampleColor.rgb * sampleColor.a, sampleColor.a);
                    }
                }
            }

            vec4 glow = (colorSum / 25.0) * uIntensity;

            // Camera buffers are usually opaque, so the glow must not depend on transparency.
            gl_FragColor = vec4(texColor.rgb + glow.rgb, texColor.a);
        }
    ')
    public function new(size:Float = 4.0, intensity:Float = 1.5, threshold:Float = 0.0)
    {
        super();
        uGlowSize.value = [size];
        uIntensity.value = [intensity];
        uBrightnessThreshold.value = [threshold];
    }
}
