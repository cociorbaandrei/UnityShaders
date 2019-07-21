/*
This looks the same as 2.... but... 
try putting say a heart as the mesh, or static image, Then you'll be rewarded with something fun.
Plus there's no spiking, just the entire mesh growing and shrinking.
*/
Shader "Skuld/Geometry Fun 4"
{
	Properties {
		_MainTex("Noise Texture", 2D) = "gray" {}
		_Speed("Animation Speed", Range(1,1000)) = 1
		_Size("Minimum Size",Range(0,1)) = 1.0
	}

	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry+1"}

		Pass {
			Lighting Off
			SeparateSpecular Off
			Cull Off

			CGPROGRAM
			#pragma target 5.0
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

			float2x2 rotate2(float rot)
			{
				float sinRot;
				float cosRot;
				sincos(rot, sinRot, cosRot);
				return float2x2(cosRot, -sinRot, sinRot, cosRot);
			}

			[maxvertexcount(96)]
			[instance(32)]
			void geom (triangle v2f input[3], inout TriangleStream<v2f> tristream, uint instanceID : SV_GSInstanceID){
				float jx,jy,jz;
				int i = 0;

				float instanceAngle = float(instanceID) * 0.19634954084936207740391521145497;

				for ( jy = 1; jy < 7; ++jy ){
					for ( i = 0; i < 3; ++i ) {
						v2f vert;
						float4 vertPos = input[i].position;
						vert.uv = input[i].uv;

						float t = abs(sin(_Time*_Speed));
						vertPos *= (1 - t*_Size);

						float frameAngle = _Time * 10;
						switch (jy){
							default:
							break;
							case 1:
								vertPos.xy = mul(rotate2(-frameAngle),vertPos.xy);
								vertPos.z += sin( instanceAngle );
								vertPos.x += cos( instanceAngle );
								vertPos.xy = mul(rotate2(frameAngle),vertPos.xy);
							break;
							case 2:
								vertPos.xy = mul(rotate2(frameAngle),vertPos.xy);
								vertPos.z += sin( instanceAngle );
								vertPos.x += cos( instanceAngle );
								vertPos.xy = mul(rotate2(-frameAngle),vertPos.xy);
							break;
							case 3:
								vertPos.yz = mul(rotate2(-frameAngle),vertPos.yz);
								vertPos.z += sin( instanceAngle );
								vertPos.x += cos( instanceAngle );
								vertPos.yz = mul(rotate2(frameAngle),vertPos.yz);
							break;
							case 4:
								vertPos.yz = mul(rotate2(frameAngle),vertPos.yz);
								vertPos.z += sin( instanceAngle );
								vertPos.x += cos( instanceAngle );
								vertPos.yz = mul(rotate2(-frameAngle),vertPos.yz);
							break;
							case 5: 
								vertPos.zx = mul(rotate2(-frameAngle),vertPos.zx);
								vertPos.y += sin( instanceAngle );
								vertPos.x += cos( instanceAngle );
								vertPos.zx = mul(rotate2(frameAngle),vertPos.zx);
							break;
							case 6: 
								vertPos.zx = mul(rotate2(frameAngle),vertPos.zx);
								vertPos.y += sin( instanceAngle );
								vertPos.x += cos( instanceAngle );
								vertPos.zx = mul(rotate2(-frameAngle),vertPos.zx);
							break;
						}
						vert.position = UnityObjectToClipPos(vertPos);//local to world position.			
						vert.normal = input[i].normal;
						tristream.Append(vert);
					}
					tristream.RestartStrip();
				}
			}

			v2f vert ( appdata v) {
				v2f o;
				o.position = v.position;
				o.uv = TRANSFORM_TEX(v.uv,_MainTex);
				return o;
			}

			fixed4 frag(v2f input ) : SV_Target
			{
				float2 uv = input.uv;
				fixed4 c = tex2D(_MainTex, uv);
				return c;
			}
			ENDCG
		}
	}
}