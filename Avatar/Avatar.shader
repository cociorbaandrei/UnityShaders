Shader "Skuld/Avatar Shader"
{
	Properties {
		[space]
		_ShadeRange("Shade Range",Range(0,1)) = 1.0
		_ShadeSoftness("Edge Softness", Range(0,1)) = 0
		_ShadePivot("Center",Range(0,1)) = .5
		_ShadeMax("Max Brightness", Range(0,2)) = 9999.0
		_ShadeMin("Min Brightness",Range(0,1)) = 0.0


		[space]
		_MainTex("Base Layer", 2D) = "black" {}
		_Color("Base Color",Color) = (1,1,1,1)
		_Hue("Hue",Range(-180,180)) = 0
		_Saturation("Saturation",Range(-1,10)) = 1
		_Value("Value",Range(-1,2)) = 0
		//hsv should go here.

		[space]//specular, normals, smoothness and normals (Needs Height)
		[Normal] _NormalTex("Normal Map", 2D) = "bump" {}
		_FeatureTex("Feature Map", 2D) = "white" {}
		_NormalScale("Normal Amount", Range(0,1)) = 1.0
		_FresnelColor("Fresnel Color", Color)=(0, 0, 0, 0)
		_FresnelRetract("Fresnel Retract", Range(0,10)) = 1.5
		_SpecularColor("Specular Color", Color) = (1, 1, 1, 1)
		_Specular("Specular", Range(0,1)) = 0
		_SpecularSize("Specular Size",Range(.001,1)) = .1
		_SpecularReflection("Specular Reflection",Range(0,1)) = .5
		_Smoothness("Smoothness", Range(0,1)) = 0
		_Reflectiveness("Reflectiveness",Range(0,1)) = 1
		_Height("Height",Range(0,1)) = 0
		_ReflectType("Reflection Type",Int) = 0
		
		[space]
		_DetailLayer("Enable Detail Layer",Int) = 0
		_DetailTex("Detail Layer", 2D) = "black" {}
		_DetailColor("Detail Color", Color) = (1, 1, 1, 1)
		_DetailUnlit("Detail Unlit", Int) = 0

		_DetailGlow("Detail Glow", Int) = 0
		_DetailGlowColor("Glow Color", Color) = (1, 1, 1, 1)
		_DetailRainbow("Rainbow Effect", Int) = 0
		_DetailGlowSpeed("Glow Speed",Range(0,10)) = 1
		_DetailGlowSharpness("Glow Sharpness",Range(1,200)) = 1.0

		_DetailHue("Hue",Range(-180,180)) = 0
		_DetailSaturation("Saturation",Range(-1,10)) = 1
		_DetailValue("Value",Range(-1,2)) = 0

		[space]
		_RenderType("Render Type",Int) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Int) = 1                 // "One"
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Int) = 0            // "Zero"
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 2                     // "Back"
		_ZWrite("Z-Write",Int) = 1
		_TCut("Transparent Cutout",Range(0,1)) = 1
	}
	CustomEditor "SkuldsAvatarShaderEditor"

	SubShader {
		Tags { }//defined by Custom Editor now.

        Blend[_SrcBlend][_DstBlend]
        Cull[_CullMode]
		AlphaTest Greater[_TCut] //cut amount
		Lighting Off
		SeparateSpecular On
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
			#pragma fragment frag
			#pragma multi_compile _ SHADOWS_SCREEN
			#pragma multi_compile _ VERTEXLIGHT_ON

			#include "shared.cginc"

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
			#pragma fragment frag
			
			#pragma multi_compile_fwdadd_fullshadows

			#include "shared.cginc"

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

			#include "shared.cginc"

			ENDCG
		}
	} 
	//FallBack "Diffuse"
}