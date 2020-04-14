Shader "Skuld/Basics/Toon"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
		_NormalTex("Texture", 2D) = "white" {}
		_NormalScale("Normal Amount", Range(0,1)) = 1.0
		_Ramp ("Toon Ramp", 2D) = "white" {}
        _DetailTex("Details",2D) = "black" {}
		_Color ("Color",Color) = (1,1,1,1)

		[space]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2   
		[Toggle] _ZWrite("Z-Write",Float) = 1
		[Toggle] _DisableNormalmap("Disable Normalmap",Float) = 0
	}
    SubShader
    {
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}
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
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "Toon.cginc"

            ENDCG
        }
        Pass
        {
		    Tags { "LightMode" = "ForwardAdd"}
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #define BASIC_FWD_ADD

            #include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "Toon.cginc"

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

			#include "Toon.cginc"

			ENDCG
		}
    }
}
