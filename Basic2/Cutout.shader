Shader "Skuld/Basics 2 (Transparent Cutout)"
{
	Properties
	{
		[KeywordEnum(Cutout)] _Mode("Shader Type",Float ) = 0
		_Color ("Base Color",Color) = (1,1,1,1)

		_MainTex("Layer 1 Texture", 2D) = "white" {}
		_TCut("Transparent Cutout",Range(0,1)) = .5
		[Toggle(_UNLITL1)] _UnlitLayer1("Layer 1 Unlit",Float) = 0
		_Smoothness("Layer 1 Smoothness", Range(0,1)) = 0
		_Reflectiveness("Layer 1 Reflectiveness",Range(0,1)) = 1

		[Toggle(_DUALTEXTURE)] _DualTexture("====== Dual Texture Mode =====",Float) = 0
		_Tex2 ("Layer 2 Texture", 2D) = "white" {}
		[Toggle(_UNLITL2)]_UnlitLayer2 ("Layer 2 Unlit",Float) = 0
		_SmoothnessL2("Layer 2 Smoothness", Range(0,1)) = 0
		_ReflectivenessL2("Layer 2 Reflectiveness",Range(0,1)) = 1

		[Toggle(_GLOW)]_GlowLayer2 ("Layer 2 Glow",Float) = 0
		_GlowSpeed ("Layer 2 Glow Speed",Range(1,1000)) = 1
		_GlowSpread ("Layer 2 Glow Spread",Range(1,10)) = 1
		_GlowSharpness("Layer 2 Glow Sharpness",Range(0,1)) = 0
		_GlowColor ("Layer 2 Glow Color",Color) = (1,1,1,1)
		[KeywordEnum(X,Y,Z)] _GlowDirection("Layer 2 Glow Direction",Float) = 0

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
		Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest"}
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
			// make fog work
			#pragma multi_compile _MODE_CUTOUT
			#pragma shader_feature _DUALTEXTURE
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
			/*
			The problem with GPU Instancing:
			In your vertex shader, UNITY_VERTEX_INPUT_INSTANCE_ID is declared in your input struct, UNITY_SETUP_INSTANCE_ID is used before accessing any instanced property, and UNITY_TRANSFER_INSTANCED_ID is called in order to feed the fragment shader input.
			In your fragment shader, UNITY_VERTEX_INPUT_INSTANCE_ID is declared in your input struct, and UNITY_SETUP_INSTANCE_ID is used before accessing any instanced property.
			*/
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
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
			#pragma shader_feature _DUALTEXTURE
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
