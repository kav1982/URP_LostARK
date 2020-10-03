#ifndef PBR_CORE
#define PBR_CORE

#include "UnityStandardCore.cginc"

#define Biou_TRANSFER_FOG(fogCoord, outpos) UNITY_CALC_FOG_FACTOR((outpos).z); fogCoord = unityFogFactor
#define Biou_APPLY_FOG_COLOR(coord,col,fogCol) UNITY_FOG_LERP_COLOR(col,fogCol,(coord).x)


struct FragmentData
{
	half3 albedo;
	half3 worldNormal;
	half3 worldTangent;
	half3 worldPos;
	half3 worldView;
	half2 metalAndGloss;
	half3 reflDir;
	half AO;
	half4 shOrLightmapUV;
};

half3 Biou_ShadeSH9 (half4 normal)
{
	// Linear + constant polynomial terms
	half3 res = SHEvalLinearL0L1 (normal);

	// Quadratic polynomials
	res += SHEvalLinearL2 (normal);

	return res;
}

half3 Biou_DecodeHDR(half4 data, half4 data_HDR)
{
	return DecodeHDR(data, data_HDR);
}


//gi start
UnityGI Biou_GIBase(UnityGIInput data, FragmentData s)
{
	UnityGI o_gi;
	ResetUnityGI(o_gi);

	#if USE_OUTSIDE_BAKE
		o_gi.light.dir = g_MainLightDir;
		o_gi.light.color = data.ambient;
		o_gi.indirect.diffuse = data.ambient;
	#else
		#if LIGHTMAP_ON
			// Baked lightmaps
			half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lightmapUV.xy);
			half3 bakedColor = Biou_DecodeLightmap(bakedColorTex);

			#if DIRLIGHTMAP_COMBINED
				half4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, data.lightmapUV.xy);
				o_gi.indirect.diffuse = bakedColor;///DecodeDirectionalLightmap (bakedColor, bakedDirTex, s.worldNormal);
				o_gi.light.dir = normalize(bakedDirTex * 2 - 1);
				o_gi.light.color = bakedColor;
			#else // not directional lightmap
				o_gi.indirect.diffuse = bakedColor;
			#endif
		#else
			o_gi.light = data.light;
			o_gi.indirect.diffuse = data.ambient;
		#endif
	#endif

	return o_gi;
}
half3 Biou_GIIndirectSpecular(Unity_GlossyEnvironmentData glossIn)
{
	glossIn.roughness *= (1.7 - 0.7 * glossIn.roughness);
	half mip = perceptualRoughnessToMipmapLevel(glossIn.roughness);
    half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, glossIn.reflUVW, mip);

	half3 specular = Biou_DecodeHDR(rgbm, unity_SpecCube0_HDR);
	//#ifdef UNITY_COLORSPACE_GAMMA
	//	specular = SRGBToLinear(specular);
	//#endif
	return specular;
}


inline half3 Biou_EyeLighting(FragmentData s, UnityLight light)
{
	//#ifdef UNITY_COLORSPACE_GAMMA
	//	s.albedo = SRGBToLinear(s.albedo);
	//	light.color = SRGBToLinear(light.color);
	//#endif

	half3 color = s.albedo;

	half3 specDir = normalize(light.dir + s.worldView * 2);
	half spec = saturate(dot(s.worldNormal, specDir));
	spec *= spec;
	spec *= spec;
	spec *= spec;
	spec = smoothstep(0.98, 0.99, spec);
	color += half3(spec, spec, spec) * 4;

	half ndotl = dot(s.worldNormal, light.dir) * 0.5 + 0.5;
	color *= ndotl;

	half rim = 1 - saturate(dot(s.worldView, s.worldNormal));

	Unity_GlossyEnvironmentData g;
	g.reflUVW = s.reflDir;
	g.roughness = 1 - s.metalAndGloss.y;
	half3 indirectSpecular = Biou_GIIndirectSpecular(g);
	rim *= rim;
	color += indirectSpecular * (rim + 0.1);

	rim *= rim;
	half3 rimColor = rim * indirectSpecular;
	color += rimColor;

	//#if defined(UNITY_COLORSPACE_GAMMA) && !defined(BIOU_FORWARDADD)
	//	color = LinearToSRGB(color);
	//#endif

	return color;
}

#endif // PBR_CORE
