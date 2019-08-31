Shader "Skuld/Geometry Fun 5"
{
	Properties {
		_PixelSize("Pixel Size",Range(0,.1)) = .1

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
			#pragma fragment fraggf 

			#pragma multi_compile

			#include "../ASDT2/ASDT2.Globals.cginc"
			#include "../ASDT2/ASDT2.FowardBase.cginc"
			
			float _Step;
			float _Spread;
			float _Verticies;
			float _PixelSize;
			float2 rotate2(float2 inCoords, float rot)
			{
				float sinRot;
				float cosRot;
				sincos(rot, sinRot, cosRot);
				return mul(float2x2(cosRot, -sinRot, sinRot, cosRot),inCoords);
			}

			void processVert(inout TriangleStream<PIO> tristream, PIO vert, int i ){
				//adjust the transform
				int id = vert.extras.x;
				float4 position = vert.objectPosition;
				position *= (.3f + (i/32.0f));
				vert.extras.y = i;
				int offset = id*i*666 + _Time * 10000;
				offset = offset % 1000;
				position.y -= ( float(offset) / 1000.0f );

				//create a pixel at the transform.
				vert.position = UnityObjectToClipPos(position);
				tristream.Append(vert);

				position.x += _PixelSize;
				vert.position = UnityObjectToClipPos(position);
				tristream.Append(vert);

				position.x -= _PixelSize;
				position.y += _PixelSize;
				vert.position = UnityObjectToClipPos(position);
				tristream.Append(vert);

				position.x += _PixelSize;
				vert.position = UnityObjectToClipPos(position);
				tristream.Append(vert);

				tristream.RestartStrip();			
			}

			[instance(32)]
			[maxvertexcount(12)]
			void geom (triangle PIO input[3], inout TriangleStream<PIO> tristream, uint instanceID : SV_GSInstanceID){
				float jx,jy,jz;
				int i = 0;

				processVert( tristream, input[0], instanceID );
				processVert( tristream, input[1], instanceID );
				processVert( tristream, input[2], instanceID );
			}
			fixed4 fraggf( PIO process, uint isFrontFace : SV_IsFrontFace ) : SV_Target
			{
				//get the uv coordinates and set the base color.
				fixed4 color = fixed4(1,0,0,1);
				process = adjustProcess(process, isFrontFace);
				color = shiftColor(color, process.extras.x * process.extras.y);
				return color;
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