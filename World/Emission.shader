Shader "Skuld/Deprecated/Basics 2 Emission"
{
	Properties
	{
		[KeywordEnum(Opaque)] _Mode("Shader Type",Float ) = 0
		_Color ("Base Color",Color) = (1,1,1,1)

		_MainTex("Layer 1 Texture", 2D) = "white" {}
		[Toggle(_UNLITL1)] _UnlitLayer1("Layer 1 Unlit",Float) = 0
		_Smoothness("Layer 1 Smoothness", Range(0,1)) = 0
		_Reflectiveness("Layer 1 Reflectiveness",Range(0,1)) = 1

		[Toggle(_EMISSION)] _Emission("====== Emission Mode =====",Float) = 0
		_Tex2 ("Layer 2 Texture", 2D) = "white" {}
		_SmoothnessL2("Emission Amount", Range(0,1)) = 0
		_EPosition("Emission Position",Vector) = (0,0,0,1)
		_ERange("Emission Range",float) = 20
		_ESamples("Samples",Vector) = (10,10,0,0)

		[Toggle(_NORMALMAP)] _Normalmap("===== Normalmap =====",Float) = 0
		[Normal]_NormalTex("Normal Map", 2D) = "black" {}
		_NormalScale("Normal Amount", Range(0,1)) = 1.0

		[Toggle(_REFLECTIONS)] _ReflectionProbe("===== Reflections =====",Float) = 0
		[Toggle(_REFLECTION_PROBE_BLENDING)] _ReflectionProbeBlending("Reflection Probe Blending",Float) = 0
		[KeywordEnum(Lerp,Multiply,Additive)] _ReflectType("Reflection Type",Float) = 0

		[Toggle(_LIGHTMAPPED)] _Lightmaps("===== Lightmap =====",Float) = 0
		_Brightness("Brightness", Range(0,10)) = 1.0
		_LMBrightness("Added Lightmap Brightness", Range(-1,1)) = 0

		[Toggle] _ZWrite("Z-Write",Float) = 1
		[Toggle(_LIGHTPROBES)] _LightProbes("Lightprobe Sampling",Float) = 0

		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		LOD 10

		Cull[_CullMode]
		ZWrite [_ZWrite]

		Pass
		{
			Lighting On

			Tags { "LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile _MODE_OPAQUE
			#pragma shader_feature _EMISSION
			#pragma shader_feature _UNLITL1 
			#pragma shader_feature _UNLITL2
			#pragma shader_feature _GLOW 
			#pragma shader_feature _REFLECTIONS
			#pragma shader_feature _REFLECTION_PROBE_BLENDING
			#pragma shader_feature _LIGHTMAPPED
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _LIGHTPROBES
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma multi_compile_fwdbase
			#pragma multi_compile _ VERTEXLIGHT_ON
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "vertexLights.cginc"
			#include "Shared.cginc"

			ENDCG
		}
		Pass
		{
			Tags { "LightMode" = "ForwardAdd"}
			Blend One One

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_local _MODE_OPAQUE
			#pragma shader_feature _EMISSION
			#pragma shader_feature _UNLITL1 
			#pragma shader_feature _UNLITL2 
			#pragma shader_feature _GLOW 
			#pragma shader_feature _REFLECTIONS
			#pragma shader_feature _REFLECTION_PROBE_BLENDING
			#pragma shader_feature _LIGHTMAPPED
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _LIGHTPROBES
			#pragma multi_compile_fog
			#pragma multi_compile_fwdadd_fullshadows
			#define BASIC_FWD_ADD

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "Shared.cginc"

			ENDCG
		}
			
		Pass {
			Tags { "LightMode" = "ShadowCaster"}

			CGPROGRAM
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			
			#pragma vertex vert
			#pragma fragment shadowFrag
			
			#pragma multi_compile_fwdadd_fullshadows

			#include "shared.cginc"

			ENDCG
		}
	}
}
