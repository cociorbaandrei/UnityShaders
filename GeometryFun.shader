Shader "Skuld/Geometry Fun"
{
	Properties {
		_Color("Fresnel Color", Color)=(1, 1, 1, 1)
	}

	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry+1"}

		Pass {
			Lighting Off
			SeparateSpecular Off

			CGPROGRAM
			#pragma target 4.0
			#pragma geometry geom
			#pragma vertex vert
			#pragma fragment frag
			//#pragma surface surf Flat novertexlights alphatest:_Cutoff finalcolor:final
			#pragma multi_compile_prepassfinal noshadowmask nodynlightmap nodirlightmap nolightmap
		
			/***********************
			*	Geometry layer
			***********************/
			struct appdata{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2g{
				float4 objPos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};
 
			struct g2f{
				float4 worldPos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed4 col : COLOR;
			};
			
			struct Varyings
			{
				float4 position : SV_POSITION;
			};

			struct Input
			{
				float2 uv_MainTex;
				float3 viewDir;
				float3 worldNormal;
				float3 worldPos;
				float4 screenPos;
			};

			sampler2D _MainTex;
			float4 _Color;

			[maxvertexcount(12)]
			void geom (triangle v2g input[3], inout TriangleStream<g2f> tristream){
				for ( int i = 0; i < 3; i++ ) {
					g2f tri;
					tri.worldPos = input[i].objPos;
					tri.uv = input[i].uv;
					tri.col = _Color;
					
					tristream.Append(tri);
				}
			}

			void vert (inout appdata v) {
			
			}

			void frag(
				Varyings input,
				out half4 outGBuffer0 : SV_Target0,
				out half4 outGBuffer1 : SV_Target1,
				out half4 outGBuffer2 : SV_Target2,
				out half4 outEmission : SV_Target3
			)
			{
				outGBuffer0 = _Color;
				outGBuffer1 = _Color;
				outGBuffer2 = _Color;
				outEmission = _Color;
			}
			ENDCG
		}
	}
}