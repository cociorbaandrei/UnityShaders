Shader "Skuld/Geometry Fun"
{
	Properties {
		_MainTex("Noise Texture", 2D) = "gray" {}
		_Speed("Animation Speed", Range(1,1000)) = 1
		_Size("Spike Size",float) = 1.0
	}

	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry+1"}

		Pass {
			Lighting Off
			SeparateSpecular Off
			Cull Off

			CGPROGRAM
			#pragma target 4.0
			#pragma geometry geom
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			#pragma multi_compile_prepassfinal noshadowmask nodynlightmap nodirlightmap nolightmap
		
			struct appdata
			{
				float4 position : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 position : SV_POSITION;
				float3 normal : NORMAL;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Speed;
			float _Size;

			[maxvertexcount(12)]
			void geom (triangle v2f input[3], inout TriangleStream<v2f> tristream){
				for ( int i = 0; i < 2; i++ ) {
					v2f vert;
					vert.uv = input[i].uv;
					vert.position = UnityObjectToClipPos(input[i].position);//local to world position.			
					vert.normal = input[i].normal;
					tristream.Append(vert);
				}

				v2f vert;
				float3 pos = input[2].position;
				float t = sin(_Time*_Speed);
				pos *= t*_Size + _Size+1;
				vert.uv = input[2].uv;
				vert.normal = input[2].normal;
				vert.position = UnityObjectToClipPos(pos);
					
				tristream.Append(vert);
			}

			v2f vert ( appdata v) {
				//for some reason this is required, and all it does is copy everything along.
				v2f o;
				o.position = v.position;
				o.uv = TRANSFORM_TEX(v.uv,_MainTex);
				return o;
			}

			fixed4 frag(v2f input ) : SV_Target
			{
				float2 uv = input.uv;
				uv[0] = ( ( (uv[0] + _Time) * 1000 ) % 100 ) / 100;
				uv[1] = ( ( (uv[1] * _Time) * 1000 ) % 100 ) / 100;
				//uv[0] = .5;
				//uv[1] = .5;
				fixed4 c = tex2D(_MainTex, uv);
				return c;
			}
			ENDCG
		}
	}
}