Shader "Character/Eye"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Glossiness("光滑度", range(0,1)) = 0.8
	}
	SubShader
	{
		Pass 
		{
			Name "FORWARD_BASE"
			Tags {"RenderType"="Opaque" "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
            #pragma multi_compile_instancing
			#include "CharacterEyePass.cginc"

			struct v2f
			{
				half4 pos : SV_POSITION;
				half4 uv : TEXCOORD0;
				half3 worldNormal : TEXCOORD3;
				half3 normal : TEXCOORD1;
				half3 viewDir : TEXCOORD4;
				half3 worldPos : TEXCOORD2;
				half3 sh : TEXCOORD5;
				half4 _ShadowCoord : TEXCOORD6;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert (appdata_full v)
			{
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o = (v2f)0;
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.worldPos);

				o.normal = v.normal;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.sh = Biou_ShadeSH9(half4(o.worldNormal, 1));

				UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
				
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				fixed4 albedo = tex2D(_MainTex, i.uv.xy);

				half3 worldNormal = UnityObjectToWorldNormal(i.normal);
				FragmentData o = (FragmentData)0;
				o.albedo = albedo.rgb;
				o.worldNormal = worldNormal;
				o.worldView = i.viewDir;
				o.worldPos = i.worldPos;
				o.shOrLightmapUV.xyz = i.sh;
				o.metalAndGloss = half2(0.5, _Glossiness);
				o.reflDir = reflect(-o.worldView, o.worldNormal);

				UNITY_LIGHT_ATTENUATION(atten, i, o.worldPos);
				UnityLight light;
				light.dir = normalize(UnityWorldSpaceLightDir(o.worldPos));
				light.color = _LightColor0.rgb * atten;

				half3 finalColor = Biou_EyeLighting(o, light);

				return half4(finalColor, 1);
			}
			ENDCG
		}
	}
}
