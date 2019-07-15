Shader "Skuld/Advance Shading + Dual Texture 2"
{
	Properties {
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 1                 // "One"
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 0            // "Zero"
		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend Operation", Float) = 0                 // "Add"
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"
		[Toggle] _ZWrite("Z-Write",Float) = 1

        [space]
		[space]
		_MainTex("Tattoo (RGB)", 2D) = "black" {}
		_TCut("Transparent Cutout",Range(0,1)) = 1
		_FresnelColor("Fresnel Color", Color)=(1, 1, 1, 1)
		_Retract("Fresnel Retract", Range(0,10)) = 0.5

        [space]
		[space]
		_ShadeRange("Shade Range",Range(0,1)) = 1.0
		_ShadeSoftness("Edge Softness", Range(0,1)) = 0
		_ShadePivot("Center",Range(0,1)) = .5
		_ShadeMax("Max Brightness", Range(0,1)) = 1.0
		_ShadeMin("Min Brightness",Range(0,1)) = 0.0

	}

	SubShader {
		Tags { "RenderType"="TransparentCutout" "Queue"="Geometry+1"}

        Blend[_SrcBlend][_DstBlend]
        BlendOp[_BlendOp]
        Cull[_CullMode]
		AlphaTest Greater[_TCut] //cut amount
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
			#pragma fragment frag novertexlights nolighting

			#pragma multi_compile_prepassfinal

			#include "ASDT2.Globals.cginc"
			#include "ASDT2.FowardBase.cginc"

			ENDCG
		}

		Pass {
			Tags { "LightMode" = "ForwardAdd"}
			Blend One One

			CGPROGRAM
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "AutoLight.cginc"
			#include "UnityPBSLighting.cginc"
			
			#pragma target 5.0
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_fwdadd_fullshadows

			#include "ASDT2.Globals.cginc"
			#include "ASDT2.FowardAdd.cginc"

			ENDCG
		}
	} 
	//FallBack "Diffuse"
}