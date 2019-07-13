// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Skuld/Geometry Fun 3"
{
	Properties {
		_MainTex("Noise Texture", 2D) = "gray" {}
		_Step("Step", Range(0,1)) = 1
		_Distance("Distance",float) = 1
		_Spread("Spread", Range(0,1)) = 1
	}

	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry+1" "LightMode" = "ForwardBase"}

		Pass {
			Tags { "LightMode" = "ForwardBase" "RenderType"="Opaque" "Queue"="Geometry+1"}

			Lighting Off
			SeparateSpecular Off
			Cull Off

			CGPROGRAM
			#pragma target 5.0
			#pragma geometry geom
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"

			//#pragma surface surf Flat novertexlights alphatest:_Cutoff finalcolor:final
			#pragma multi_compile_prepassfinal
		
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
			float _Step;
			float _Distance;
			float _Spread;

			float2x2 rotate2(float rot)
			{
				float sinRot;
				float cosRot;
				sincos(rot, sinRot, cosRot);
				return float2x2(cosRot, sinRot, sinRot, cosRot);
			}

			[maxvertexcount(24)]
			[instance(9)]
			void geom (triangle v2f input[3], inout TriangleStream<v2f> tristream, uint instanceID : SV_GSInstanceID){
				float jx,jy,jz;
				int i = 0;

				float angle = float(instanceID) * 0.78539816339744830961566084581988;
				float4 direction;
				direction.x = cos(angle);
				direction.y = sin(angle);
				direction.z = 0;
				direction.w = 1.0;
						
				direction *= _Spread;
				if (instanceID == 0){
					direction *= 0;
				}
				for ( jx = -2; jx < 3; ++jx ){
					for ( jy = -2; jy < 3; ++jy ){
						float4 center = ( input[0].position + input[1].position + input[2].position ) / 3;
						float4 destination = center * _Step * _Distance;

						v2f vert;
						vert.position = input[0].position;
						vert.position -= ( ( input[0].position - center ) * _Step );
						vert.position += destination;
						vert.position += direction;
						vert.uv = input[0].uv;
						vert.normal = input[0].normal;
						vert.position = UnityObjectToClipPos(vert.position);
						tristream.Append(vert);

						vert.position = input[1].position;
						vert.position -= ( ( input[1].position - center ) * _Step );
						vert.position += destination;
						vert.position += direction;
						vert.uv = input[1].uv;
						vert.normal = input[1].normal;
						vert.position = UnityObjectToClipPos(vert.position);
						tristream.Append(vert);

						vert.position = input[2].position;
						vert.position -= ( ( input[2].position - center ) * _Step );
						vert.position += destination;
						vert.position += direction;
						vert.uv = input[2].uv;
						vert.normal = input[2].normal;
						vert.position = UnityObjectToClipPos(vert.position);
						tristream.Append(vert);


						tristream.RestartStrip();
					}
				}
			}

			v2f vert ( appdata v) {
				//for some reason this is required, and all it does is copy everything along.
				v2f o;
				o.position = v.position;
				o.uv = TRANSFORM_TEX(v.uv,_MainTex);
				o.normal = v.normal;
				return o;
			}

			fixed4 frag(v2f input ) : SV_Target
			{
				float3 lightDir = UnityWorldSpaceLightDir (input.position);
				float4 ambientDir = float4(normalize(unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz), 1.0);

				float3 normal = normalize(input.normal);
				float ambValue = dot( normal, ambientDir);
				half nonAmbValue = dot (normal, lightDir);
				half shade = saturate( max(ambValue,nonAmbValue));
				if (shade == 0){
					float4 down = normalize(float4(0,1,0,1));
					shade = saturate(dot(normal,down))*10;
				}
				shade = shade / 2 + 5;

				//lightDir += unity_SHAr + unity_SHAg + unity_SHAb;
				//lightDir = normalize(lightDir);
				float2 uv = input.uv;
				float3 ambLight = ShadeSH9(float4(0,0,0,1));
				float3 nonAmbLight = _LightColor0;
				fixed4 c = tex2D(_MainTex, uv);
				c.rgb = c.rgb * ( ambLight + nonAmbLight ) * shade;
				c.rgb = c.rgb * shade;
				c[3] = 1.0;
				return c;
			}
			ENDCG
		}
	}
}