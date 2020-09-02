Shader "Skuld/Deprecated/Basics/Lightmapped"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color",Color) = (1,1,1,1)
		_Brightness ("Brightness", Range(0,10) ) = 1.0
		_LMBrightness ("Added Lightmap Brightness", Range(-1,1) ) = 0
		_NormalTex("Normal Map", 2D) = "black" {}
		_NormalScale("Normal Amount", Range(0,1)) = 1.0
		_Smoothness("Smoothness", Range(0,1)) = 0
		_Reflectiveness("Reflectiveness",Range(0,1)) = 1
		[KeywordEnum(Lerp,Multiply,Additive)] _ReflectType("Reflection Type",Float) = 0

		[space]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"
		[Toggle] _ZWrite("Z-Write",Float) = 1
		[Toggle] _DisableLightmap("Disable Lightmap",Float) = 0
		[Toggle] _DisableNormalmap("Disable Normalmap",Float) = 0
		[Toggle] _DisableReflectionProbe("Disable Reflection Probe",Float) = 0
		[Toggle] _DisableReflectionProbeBlending("Disable Reflection Probe Blending",Float) = 0
		[Toggle] _DisableLightProbes("Disable Lightprobe Sampling",Float) = 1
		[Toggle] _DisableFog("Disable Fog",Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		LOD 10

        Cull[_CullMode]
		Lighting Off
		SeparateSpecular Off
		ZWrite [_ZWrite]

		Pass
		{
			Lighting On

			Tags { "LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma multi_compile_fwdbase
			
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
			
			#pragma fragment shadowFrag
			
			#pragma multi_compile_fwdadd_fullshadows

			#include "shared.cginc"

			ENDCG
		}
	}
}
