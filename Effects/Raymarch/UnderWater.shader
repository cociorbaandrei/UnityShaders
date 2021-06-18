// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Skuld/Effects/Ray Marching/Underwater"
{
	Properties {
		_MainTex("Ground",2D) = "black" {}
		_CubeTex("Walls",2D) = "black" {}
		_Horizon("Horizon falloff",Float) = 1
        [hdr]_WColorA("WaterColor A",Color) = (0,0,1,1)
        [hdr]_WColorB("WaterColor A",Color) = (0,1,1,1)

		//spheres (bubbles)
		_Steps("Iterations",Range(0,1000)) = 100
		_Size("Grid Size",Range(0,10)) = 1
		_Radius("Sphere Radius",Range(0,1)) = 0.1
	}

	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		LOD 100
		Cull back		

		pass {	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float4 position : SV_POSITION;
			};

			struct appdata
			{
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _CubeTex;
			float4 _CubeTex_ST;

            float _Horizon;
            float4 _WColorA;
            float4 _WColorB;

			v2f vert ( appdata v) {
				v2f o;
				o.position = UnityObjectToClipPos(v.position);
				o.worldPos = mul(unity_ObjectToWorld, v.position).xyz;
				o.uv = TRANSFORM_TEX(v.uv,_MainTex);
				return o;
			}
			/*
			BEGIN SPHERES 
			*/
			float _Radius;
			float _Steps;
			float _Size;
			struct DEOutPut {
				float distance;
				float3 normal;
			};
			float sphereDistance(float3 position, float3 center)
			{
				return length(position - center) - _Radius;
			}

			DEOutPut DE(float3 inPosition, v2f input, float i)
			{
				float s2 = _Size / 2.0f;
				float3 position = inPosition;
				int2 offset;
				offset.x = position.x / _Size;
				offset.y = position.z / _Size;
				position.y -= _Time.x - sin(offset.x) - cos(offset.y);
				position.x += sin(offset.y) * _Size;
				position.z += sin(offset.x) * _Size;
				//position.y -= _Time.x + sin(inPosition.x)/5;
				//position.x += sin(inPosition.z*3)/5;
				//position.z += sin(inPosition.x*4)/5;
				position = frac(position / _Size) * _Size;
				float3 center;
				center.z = _Size / 2;
				center.x = _Size / 2;
				center.y = _Size / 2;
				float distance = sphereDistance(position, center);
				
				DEOutPut output;
				output.distance = distance;
				output.normal = normalize(position-center);
				return output;
			}
			/*
			END STUFF FOR SPHERES.
			*/

			float4 frag(v2f input ): SV_Target
			{
				float4 output;
                float4 baseColor;
                float3 position = _WorldSpaceCameraPos.xyz;
				float4 center = mul(unity_ObjectToWorld, float4(0, 0, 0, 1.0));

				float3 direction = normalize( input.worldPos - _WorldSpaceCameraPos.xyz );
				//float4 color = tex2D(_MainTex, input.uv);

                if ( direction.y < 0) {
                    float xrun = direction.x/-direction.y;
                    float zrun = direction.z/-direction.y;
                    //float bottom = mul(unity_ObjectToWorld,float3(0,0,0)).y;
					float bottom = center.y;
                    float gdist = position.y - bottom;
                    position.x += gdist * xrun;
                    position.z += gdist * zrun;
                    position.y = bottom;
					output = tex2D(_MainTex, position.xz/8);
					float d = sin(position.x * 3 + _Time.y + sin(_Time.y+position.z * 2 + sin(position.x*5-_Time.y)));
					output.rgb += d*.1f;
				} else {
                    position += direction * 1000;
                    float depth = saturate(input.worldPos.y*_Horizon);
                    baseColor = lerp(_WColorA,_WColorB,depth);
    				output = baseColor;
                }
				//fog
                float4 clipPos = UnityWorldToClipPos(position);
                float zDepth = clipPos.z / clipPos.w;
				float f = saturate( (1 - zDepth*2)-.1f );
				output = lerp(output, float4(0, 0, .05f, 1), f);

				//determine Bubble.
				float4 bubble = float4(0,0,0,0);
				position = input.worldPos;
				for (int i = 0; i < _Steps; i++)
				{
					DEOutPut de = DE(position, input, i);
					if (de.distance > 0.001) {
						position += direction * de.distance;
						continue;
					}
					if (position.y < 0) {
						break;
					}
					float a = (dot(de.normal, direction)+1);
					float4 clipPos = UnityWorldToClipPos(position);
					float zDepth = clipPos.z / clipPos.w;
					bubble = float4(1, 1, 1, a*zDepth);
					//float4 clipPos = UnityWorldToClipPos(position);
					//output.depth = clipPos.z / clipPos.w;
					break;	
				}
				output = lerp(output, bubble, bubble.a);

				//special layer
				float4 cube = tex2D(_CubeTex, input.uv);
				cube.rgb *= .5f;
				cube.a *= .9f;
				output = lerp(output, cube, cube.a);

				return output;
			}
			ENDCG
		}
	}
}