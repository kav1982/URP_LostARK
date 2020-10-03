#ifndef BIOUM_SHADOW_CASTER_PASS_INCLUDED
#define BIOUM_SHADOW_CASTER_PASS_INCLUDED

#include "../Shader/ShaderLibrary/Common.hlsl"

struct Attributes
{
    half3 positionOS   : POSITION;
    half3 normalOS     : NORMAL;
    half2 texcoord     : TEXCOORD0;
    half4 color     : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    half4 positionCS   : SV_POSITION;
#if ENABLE_ALPHATEST
    half2 uv           : TEXCOORD0;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

half4 BioumClipSpaceShadowCasterPos(half3 positionOS, half3 normalOS, half4 vColor)
{
    half3 positionWS = TransformObjectToWorld(positionOS);
#if ENABLE_WIND
    wPos.xz += GrassAnimationWithWind(vColor.rgb, positionWS);
#endif

    if (unity_LightShadowBias.z != 0.0)
    {
        half3 normalWS = TransformObjectToWorldNormal(normalOS);
        half3 lightPosWS = normalize(UnityWorldSpaceLightDir(positionWS.xyz));

        // apply normal offset bias (inset position along the normal)
        // bias needs to be scaled by sine between normal and light direction
        // (http://the-witness.net/news/2013/09/shadow-mapping-summary-part-1/)
        //
        // unity_LightShadowBias.z contains user-specified normal offset amount
        // scaled by world space texel size.

        half shadowCos = dot(normalWS, lightPosWS);
        half shadowSine = sqrt(1 - shadowCos * shadowCos);
        half normalBias = unity_LightShadowBias.z * shadowSine;

        positionWS -= normalWS * normalBias;
    }

    return TransformWorldToHClip(positionWS);
}

Varyings ShadowCasterVert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    half4 positionCS = BioumClipSpaceShadowCasterPos(input.positionOS, input.normalOS, input.color);
    output.positionCS = UnityApplyLinearShadowBias(positionCS);

#if _ALPHATEST
    output.uv = GetBaseUV(input.texcoord);
#endif
    
    return output;
}

half4 ShadowCasterFrag(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    ClipLOD(input.positionCS.xy, unity_LODFade.x);

#if _ALPHATEST
    half alpha = tex2D(_MainTex, input.uv).a;
    half cutout = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
    clip(alpha - cutout);
#endif

    return 0;
}

#endif
