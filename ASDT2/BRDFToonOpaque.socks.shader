Shader "Skuld/BRDF Toon Opaque (Socks)"
{
	Properties {
		_CloudStretch("Cloud Width",float) = 5
		_CloudSpeed("Cloud Speed",float) = 2
		_Stars("Number of Stars",int) = 20
		_StarSize("Size of Stars",float) = 100
		_XScatter("X Scatter", Range(0,1)) = 1
		_YScatter("Y Scatter", Range(0,1)) = 1
		_Bounding("Bounding",Vector) = (0,0,0,0)
		[space]
		_ShadeRange("Shade Range",Range(0,1)) = 1.0
		_ShadeSoftness("Edge Softness", Range(0,1)) = 0
		_ShadePivot("Center",Range(0,1)) = .5
		_ShadeMax("Max Brightness", Range(0,1)) = 1.0
		_ShadeMin("Min Brightness",Range(0,1)) = 0.0

		[space]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"
		[Toggle] _ZWrite("Z-Write",Float) = 1

		[space]
		_MainTex("Base Layer", 2D) = "black" {}
		_CloudsTex("clouds", 2D) = "black" {}
		_StarTex("Star", 2D) = "black" {}
		_StarPos("Star Position", 2D) = "black" {} //must be 64x64
		_Color("Base Color",Color) = (1,1,1,1)
		[Normal] _NormalTex("Normal Map", 2D) = "(1,1,1,1)" {}
		_NormalScale("Normal Amount", Range(0,1)) = 1.0
		_FresnelColor("Fresnel Color", Color)=(1, 1, 1, 1)
		_FresnelRetract("Fresnel Retract", Range(0,10)) = 0.5
		_Smoothness("Smoothness", Range(0,1)) = 0
		_Reflectiveness("Reflectiveness",Range(0,1)) = 1
		[KeywordEnum(Lerp,Multiply,Additive)] _ReflectType("Reflection Type",Float) = 0
		_TCut("Transparent Cutout",Range(0,1)) = 1
		
	}

	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}

        Cull[_CullMode]
		Lighting Off
		SeparateSpecular Off
		ZWrite [_ZWrite]

		Pass {
			Tags { "LightMode" = "ForwardBase"}
			CGPROGRAM
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "AutoLight.cginc"
			#include "UnityPBSLighting.cginc"
			
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment socksFrag
			#pragma multi_compile _ SHADOWS_SCREEN
			#pragma multi_compile _ VERTEXLIGHT_ON

			#define MODE_BRDF

			#include "ASDT2.Globals.cginc"
			#include "BRDF.frag.cginc"
			#include "BRDF.socks.frag.cginc"

			ENDCG
		}
		Pass {
			Tags { "LightMode" = "ForwardAdd"}
			Blend One One

			CGPROGRAM
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityPBSLighting.cginc"
			
			#pragma target 5.0
			
			#pragma vertex vert
			#pragma fragment socksFrag
			
			#pragma multi_compile_fwdadd_fullshadows

			#define MODE_BRDF

			#include "ASDT2.Globals.cginc"
			#include "BRDF.frag.cginc"
			#include "BRDF.socks.frag.cginc"

			ENDCG
		}
		Pass {
			Tags { "LightMode" = "ShadowCaster"}

			CGPROGRAM
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "AutoLight.cginc"
			#include "UnityPBSLighting.cginc"
			
			#pragma target 5.0
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_shadowcaster_fullshadows

			#define MODE_BRDF

			#include "ASDT2.Globals.cginc"
			#include "ASDT2.shadows.cginc"

			ENDCG
		}
	} 
	//FallBack "Diffuse"
}