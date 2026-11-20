Shader "BlockOdyssey/ToonToyShader"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo Texture", 2D) = "white" {}
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)

        [Header(Toon Ramp Shading)]
        _RampThreshold("Ramp Threshold", Range(0, 1)) = 0.45
        _RampSmoothness("Ramp Smoothness", Range(0.001, 0.5)) = 0.08
        _ShadowTint("Shadow Color Tint", Color) = (0.55, 0.52, 0.62, 1)

        [Header(Toy Specular Gloss)]
        _Glossiness("Toy Glossiness", Range(8, 256)) = 64
        _SpecularIntensity("Specular Intensity", Range(0, 2)) = 0.8
        _SpecularColor("Specular Tint", Color) = (1, 1, 1, 1)

        [Header(Diorama Rim Light)]
        _RimColor("Rim Edge Color", Color) = (0.7, 0.95, 1.0, 1)
        _RimPower("Rim Power (Tightness)", Range(0.5, 8.0)) = 3.2
        _RimIntensity("Rim Intensity", Range(0, 3)) = 1.25

        [Header(Outline)]
        _OutlineColor("Outline Color", Color) = (0.18, 0.12, 0.08, 1)
        _OutlineWidth("Outline Width", Range(0, 0.04)) = 0.008
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }

        // PASS 1: OUTLINE (Extruded along vertex normals)
        Pass
        {
            Name "Outline"
            Cull Front
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _OutlineColor;
                float _OutlineWidth;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                float3 pos = input.positionOS.xyz + normalize(input.normalOS) * _OutlineWidth;
                output.positionCS = TransformObjectToHClip(pos);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                return _OutlineColor;
            }
            ENDHLSL
        }

        // PASS 2: TOON LIT (Ramp, Specular Gloss & Rim Light)
        Pass
        {
            Name "UniversalForward"
            Tags { "LightMode" = "UniversalForward" }
            Cull Back
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _ShadowTint;
                float _RampThreshold;
                float _RampSmoothness;
                float _Glossiness;
                float _SpecularIntensity;
                float4 _SpecularColor;
                float4 _RimColor;
                float _RimPower;
                float _RimIntensity;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = normalize(GetCameraPositionWS() - input.positionWS);

                // Main directional light
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS));
                float3 lightDirWS = normalize(mainLight.direction);

                // 1. Ramp Toon Lighting (2-tone banded shading)
                float NdotL = dot(normalWS, lightDirWS);
                float ramp = smoothstep(_RampThreshold - _RampSmoothness, _RampThreshold + _RampSmoothness, NdotL * mainLight.shadowAttenuation);
                float3 diffuse = lerp(texColor.rgb * _ShadowTint.rgb, texColor.rgb * mainLight.color, ramp);

                // 2. Toy Specular Gloss (Plastic highlight)
                float3 halfDir = normalize(lightDirWS + viewDirWS);
                float NdotH = saturate(dot(normalWS, halfDir));
                float spec = pow(NdotH, _Glossiness) * _SpecularIntensity * ramp;
                float3 specular = spec * _SpecularColor.rgb * mainLight.color;

                // 3. Smooth Rim Lighting (Glow around silhouettes)
                float NdotV = 1.0 - saturate(dot(normalWS, viewDirWS));
                float rim = pow(NdotV, _RimPower) * _RimIntensity * ramp;
                float3 rimColor = rim * _RimColor.rgb;

                // Ambient light
                float3 ambient = SampleSH(normalWS) * texColor.rgb * 0.45;

                float3 finalColor = diffuse + specular + rimColor + ambient;
                return half4(finalColor, texColor.a);
            }
            ENDHLSL
        }
    }
}
