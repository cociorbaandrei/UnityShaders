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
			
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag novertexlights nolighting

			#pragma multi_compile_prepassfinal

			//general IO with Semantics
			struct IO
			{
				float4 position : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float4 worldPosition : TEXCOORD3;
			};

			//processed IO to be used by submethods
			struct PIO
			{
				float4 position;
				float3 worldPosition;
				float3 normal;
				float2 uv;
				float3 viewDirection;
				float4 cameraPosition;
			};

			/*
			struct SVIO
			{
				float2 uv : TEXCOORD0;
				float4 position : SV_POSITION;
				float3 normal : NORMAL;
			};
			*/

			sampler2D _MainTex;
			sampler2D _MainTex_ST;
			float _Retract;
			float4 _FresnelColor;
			float _TCut;

			//shading properties
			float _ShadeRange;
			float _ShadeSoftness;
			float _ShadeMax;
			float _ShadeMin;
			float _ShadePivot;
			
			IO vert ( IO vertex ){
				IO output;
				output.uv = vertex.uv;//TRANSFORM_TEX( vertex.uv, _MainTex );
				output.normal = vertex.normal;
				output.position = UnityObjectToClipPos(vertex.position);
				output.worldPosition = vertex.position;
				return output;
			}

			fixed4 fresnel( PIO process, fixed4 inColor ){
				float val = saturate(-dot(process.viewDirection, process.normal));
				float rim = 1 - val * _Retract;
				if (rim < 0.0 ) rim = 0.0;
				rim *= _FresnelColor.a;
				float orim = 1 - rim;
				fixed4 color;
				color.rgb = (_FresnelColor * rim) + (inColor * orim);
				color.a = inColor.a;
				return color;
			}

			fixed4 applyDirectionalLight( PIO process, fixed4 inColor ){
				float3 color = _LightColor0;
				float brightness = saturate(dot(_WorldSpaceLightPos0, process.normal));

				//I need the ambient color 
				if (brightness <= 0 ){
					color = float3(1,1,1);
				}
				
				//apply ramp:
				if ( _ShadeSoftness > 0 ){
					brightness -= _ShadePivot;
					brightness *= 1/_ShadeSoftness;
					brightness += _ShadePivot;
				} else {
					if (brightness > _ShadePivot){
						brightness = 1;
					} else {
						brightness = 0;
					}
				}
				
				brightness = saturate(brightness);
				//apply range, min and max:
				brightness = brightness * _ShadeRange + (1 - _ShadeRange);
				brightness = max(_ShadeMin,brightness);
				brightness = min(_ShadeMax,brightness);
				inColor.rgb *= brightness;
				inColor.rgb *= color;

				return inColor;
			}

			//applies ambient light from directional and lightprobes.
			fixed4 applyAmbientLight( PIO process, fixed4 inColor){
				float brightness = saturate(ShadeSH9( float4(process.normal,1) ));
				float ambientColor = saturate(ShadeSH9( float4(1,1,1,1) ));
				//apply ramp:
				if ( _ShadeSoftness > 0 ){
					brightness -= _ShadePivot;
					brightness *= 1/_ShadeSoftness;
					brightness += _ShadePivot;
				} else {
					if (brightness > _ShadePivot){
						brightness = 1;
					} else {
						brightness = 0;
					}
				}
				brightness = saturate(brightness);
				//apply range, min and max:
				brightness = brightness * _ShadeRange + (1 - _ShadeRange);
				brightness = max(_ShadeMin,brightness);
				brightness = min(_ShadeMax,brightness);
				inColor.rgb *= brightness;
				inColor.rgb *= ambientColor;
				return inColor;
			}

			fixed4 frag( IO input, uint isFrontFace : SV_IsFrontFace ) : SV_Target
			{
				PIO process;
			
				//get the camera position to calculate view direction.
				process.cameraPosition = float4(_WorldSpaceCameraPos,1);
				//reverse the draw position for the screen back to the world position for calculating view Direction.
				process.worldPosition = input.worldPosition;
				//get the direction from the camera to the pixel.
				process.viewDirection = normalize(input.worldPosition - process.cameraPosition);
				process.normal = normalize(input.normal);
				if (!isFrontFace){
					process.normal = -process.normal;
				}
				process.position = input.position;
				process.uv = input.uv;

				//get the uv coordinates and set the base color.
				float2 uv = input.uv;
				fixed4 color = tex2D( _MainTex, process.uv );

				//Apply Fresnel
				color = fresnel(process, color);

				//Apply baselights
				color = applyAmbientLight(process,color);
				color = applyDirectionalLight(process,color);

				//Apply cut.
				if (color.a <= _TCut){
					color.a = 0;
				}
				return color;
			}

			ENDCG
		}

		/*
		Pass {
			Tags { "LightMode" = "ForwardAdd"}

			CGPROGRAM
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			
			#pragma target 5.0
			#pragma fragment frag
			
			#pragma multi_compile_prepassfinal

			//general IO with Semantics
			struct IO
			{
				float4 position : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float4 worldPosition : TEXCOORD3;
			};

			//processed IO to be used by submethods
			struct PIO
			{
				float4 position;
				float3 worldPosition;
				float3 normal;
				float2 uv;
				float3 viewDirection;
				float4 cameraPosition;
			};

			fixed4 frag( IO input ) : SV_Target
			{
			}
			ENDCG
		}
		*/
	} 
	//FallBack "Diffuse"
}