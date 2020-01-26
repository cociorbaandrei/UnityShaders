Shader "Skuld/Basics/LightmappedDualTextureTransparent"
{
	Properties
	{
		_Color ("Base Color",Color) = (1,1,1,1)
		_Brightness ("Layer Brightness", Range(0,10) ) = 1.0
		_LMBrightness ("Layer Added Lightmap Brightness", Range(-1,1) ) = 0

		_Tex1 ("Layer 1 Texture", 2D) = "white" {}
		[Toggle]_Unlit1("Layer 1 Unlit",Float) = 0
		_NormalTex1("Layer 1 Normal Map", 2D) = "black" {}
		_NormalScale1("Layer 1 Normal Amount", Range(0,1)) = 1.0
		_Smoothness1("Layer 1 Smoothness", Range(0,1)) = .5

		[space]
		_Tex2 ("Layer 2 Texture", 2D) = "white" {}
		[Toggle]_Unlit2("Layer 2 Unlit",Float) = 0
		[Toggle]_Glow2("Layer 2 Glow",Float) = 0
		_GlowSpeed("Layer 2 Glow Speed",Range(1,1000)) = 1
		_GlowSpread("Layer 2 Glow Spread",Range(1,10)) = 1
		_GlowSharpness("Layer 2 Glow Sharpness",Range(0,1)) = 0
		_GlowColor ("Layer 2 Glow Color",Color) = (1,1,1,1)
		[KeywordEnum(X,Y,Z)] _GlowDirection("Layer 2 Glow Direction",Float) = 0
		

		[space]
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 1                 // "One"
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 0            // "Zero"
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"
		[Toggle] _ZWrite("Z-Write",Float) = 1
		[Toggle] _DisableLightmap("Disable Lightmap",Float) = 0
		[Toggle] _DisableNormalmap("Disable Normalmap",Float) = 0
		[Toggle] _DisableReflectionProbe("Disable Reflection Probe",Float) = 0
		[Toggle] _DisableReflectionProbeBlending("Disable Reflection Probe Blending",Float) = 0
		[Toggle] _DisableFog("Disable Fog",Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent-400"}
		LOD 10

		Blend[_SrcBlend][_DstBlend]
        Cull[_CullMode]
		Lighting Off
		SeparateSpecular Off
		ZWrite [_ZWrite]

		//layer 1
		Pass
		{
			Tags { "LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#define LAYER_1
			#define TRANSPARENT

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "SharedFX.cginc"

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
			#pragma multi_compile_fog
			#pragma multi_compile_fwdadd_fullshadows
			#define BASIC_FWD_ADD
			#define LAYER_1
			#define TRANSPARENT

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "SharedFX.cginc"

			ENDCG
		}
			
		Pass {
			Tags { "LightMode" = "ShadowCaster"}

			CGPROGRAM
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			
			#pragma fragment shadowFrag
			
			#pragma multi_compile_fwdadd_fullshadows
			#define TRANSPARENT

			#include "SharedFX.cginc"

			ENDCG
		}
	}
}
