Shader "Skuld/Phase In"
{
	Properties {
		[space]
		_Step("Step", Range(0,2)) = 1
		_Spread("Spread", float) = 1
		_Verticies("Verticies",float) = 1

		[space]
		_ShadeRange("Shade Range",Range(0,1)) = 1.0
		_ShadeSoftness("Edge Softness", Range(0,1)) = 0
		_ShadePivot("Center",Range(0,1)) = .5
		_ShadeMax("Max Brightness", Range(0,1)) = 1.0
		_ShadeMin("Min Brightness",Range(0,1)) = 0.0

		[space]
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 1                 // "One"
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 0            // "Zero"
		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend Operation", Float) = 0                 // "Add"
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"
		[Toggle] _ZWrite("Z-Write",Float) = 1

		[space]
		_MainTex("Base Layer", 2D) = "black" {}
		_TCut("Transparent Cutout",Range(0,1)) = 1
		_FresnelColor("Fresnel Color", Color)=(1, 1, 1, 1)
		_FresnelRetract("Fresnel Retract", Range(0,10)) = 0.5

		[space]
		_MaskTex("Mask Layer", 2D) = "black" {}
		[Toggle] _MaskGlow("Mask Glow", Float) = 0
		_MaskGlowColor("Glow Color", Color)=(1, 1, 1, 1)
		[Toggle] _MaskRainbow("Rainbow Effect", Float) = 0
		_MaskGlowSpeed("Glow Speed",Range(0,10)) = 1
		_MaskGlowSharpness("Glow Sharpness",Range(1,200)) = 1.0
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
			#pragma geometry geom
			#pragma fragment frag novertexlights nolighting

			#pragma multi_compile_prepassfinal

			#include "ASDT2/ASDT2.Globals.cginc"
			#include "ASDT2/ASDT2.FowardBase.cginc"
			
			float _Step;
			float _Spread;
			float _Verticies;

			/*
				Now instead of it being it's own stand alone shader. It was better and easier to make this shader
				work inside of the toon shader. This way it will look more part of the character, rather than
				different.
			*/
			[maxvertexcount(3)]
			void geom (triangle PIO input[3], inout TriangleStream<PIO> tristream, uint instanceID : SV_GSInstanceID){
				float jx,jy,jz;
				int i = 0;

				uint id = max(max(input[0].extras.x,input[1].extras.x),input[2].extras.x);
				float idScale = float(id)/float(_Verticies);
				float adjustedStep = min(max( _Step - idScale, 0),1);

				float4 position;

				float4 center = ( input[0].objectPosition + input[1].objectPosition + input[2].objectPosition ) / 3;

				
				float4 destination = center * adjustedStep;
				float4 finalTransform = -( ( position - center ) * adjustedStep ) + destination;

				PIO vert = input[0];
				position = vert.objectPosition;
				position -= ( ( position - center ) * adjustedStep );
				position += destination;
				position.z += adjustedStep*_Spread;
				vert.position = UnityObjectToClipPos(position);
				tristream.Append(vert);

				vert = input[1];
				position = vert.objectPosition;
				position -= ( ( position - center ) * adjustedStep );
				position += destination;
				position.z += adjustedStep*_Spread;
				vert.position = UnityObjectToClipPos(position);
				tristream.Append(vert);

				vert = input[2];
				position = vert.objectPosition;
				position -= ( ( position - center ) * adjustedStep );
				position += destination;
				position.z += adjustedStep*_Spread;
				vert.position = UnityObjectToClipPos(position);
				tristream.Append(vert);

				tristream.RestartStrip();
			}

			ENDCG
		}
		/*
			the forward add lights and shadows had to be removed, or else
			I needed to repeat the geometry manipulation.
			Which is already expensive as it is, so just dropping it.
		*/
	} 
	//FallBack "Diffuse"
}