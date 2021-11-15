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
		_BubbleSteps("Bubble Iterations",Range(0,1000)) = 100
		_BubbleSize("Bubble Grid Size",Range(0,10)) = 1
		_BubbleRadius("Bubble Sphere Radius",Range(0,1)) = 0.1
		//grass
		_GrassTex("Grass",2D) = "black" {}
		_GrassSteps("Grass Iterations",Range(0,1000)) = 100
		_GrassSize("Grass Grid Size",Range(0,10)) = 1
		_GrassRadius("Grass Dimensions",Vector) = (1,1,1,1)
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
			float _BubbleRadius;
			float _BubbleSteps;
			float _BubbleSize;
			struct DEOutPut {
				float distance;
				float3 normal;
			};

			float4 ApplyFog(float4 color, float3 position){
                float4 clipPos = UnityWorldToClipPos(position);
                float zDepth = clipPos.z / clipPos.w;
				#ifdef UNITY_REVERSED_Z
				zDepth = 1 - zDepth *10-.1f;
				#else
				zDepth = zDepth / 1.2 - .1f;
				#endif
				float f = saturate( zDepth );
				float4 output = lerp(color, float4(0, 0, .05f, 1),f);
				return output;
			}

			float sphereDistance(float3 position, float3 center)
			{
				return length(position - center) - _BubbleRadius;
			}

			DEOutPut DE(float3 inPosition, float i)
			{
				float s2 = _BubbleSize / 2.0f;
				float3 position = inPosition;
				int2 offset;
				offset.x = position.x / _BubbleSize;
				offset.y = position.z / _BubbleSize;
				position.y -= _Time.x*(offset.x%5 + 2) - sin(offset.x) - cos(offset.y);
				position.x += sin(offset.y) * _BubbleSize;
				position.z += sin(offset.x) * _BubbleSize;
				position = frac(position / _BubbleSize) * _BubbleSize;
				float3 center = _BubbleSize / 2;
				float distance = sphereDistance(position, center);
				
				DEOutPut output;
				output.distance = distance;
				output.normal = normalize(position-center);
				return output;
			}

			void MarchBubble(inout float4 color, float3 position, inout float3 direction, inout float zDepth ){
				float4 bubble = float4(0,0,0,0);
				[loop]
				for (int i = 0; i < _BubbleSteps; i++)
				{
					DEOutPut de = DE(position,  i);
					if (de.distance > 0.01) {
						position += direction * de.distance;
						continue;
					}
					if (position.y < 0) {
						break;
					}
					float a = (dot(de.normal, direction)+1);
					a = a / 2 + .5f;
					float4 clipPos = UnityWorldToClipPos(position);
					float bubbleZDepth = clipPos.z / clipPos.w;
					
					bubble = float4(1, 1, 1, a*(bubbleZDepth/10.0f));
					zDepth = bubbleZDepth;
					break;	
				}
				color = lerp(color, bubble, bubble.a);
			}
			/*
			END STUFF FOR SPHERES.
			GRASS
			*/
			float4 _GrassRadius;
			float _GrassSteps;
			float _GrassSize;
			sampler2D _GrassTex;

			float BoxDistance(float3 position){
				float3 d = abs(position) - _GrassRadius;
				float t1 = length(max(d,0));
				float t2 = max(max(d.x, d.y),d.z);
				t2 = min(t2, 0);
				float distance = t1+t2;
				return distance;
			}
			DEOutPut BoxDE(float3 inPosition)
			{
				float3 position = inPosition;
				//why does negative abs here fix this???
				position.xz = frac(-abs(position.xz) / _GrassSize) * _GrassSize;
				position.y = -abs(position.y);
				
				float distance = BoxDistance(position);
				
				DEOutPut output;
				output.distance = distance;
				output.normal = normalize(position-_GrassRadius);

				return output;
			}
			void MarchGrass(inout float4 color, float3 position, inout float3 direction, inout float zDepth ){
				float4 grass = float4(0,0,0,0);
				[loop]
				for (int i = 0; i < _GrassSteps; i++)
				{
					DEOutPut de = BoxDE(position);
					if (de.distance > 0.01) {
						position += direction * de.distance;
						continue;
					}
					if (position.y < 0.01 || position.y > _GrassRadius.y ) {
						break;
					}
					float4 clipPos = UnityWorldToClipPos(position);
					float grassZDepth = clipPos.z / clipPos.w;
					float2 uv = 0;
					uv.x = frac( ( (position.x+position.z) / 2.0f ) / _GrassRadius.x );
					uv.y = frac( position.y / _GrassRadius.y );
					grass = tex2D(_GrassTex, uv);
					if ( grass.a > .01f ) {
						grass = ApplyFog(grass, position);
						zDepth = grassZDepth;
						break;
					}
				}
				color = lerp(color,grass,grass.a);
			}

			/*
			END GRASS
			*/
			float4 frag(v2f input ): SV_Target
			{
				float4 output;
                float4 baseColor;
                float3 position = _WorldSpaceCameraPos.xyz;
				float3 objBottom = unity_ObjectToWorld._m03_m13_m23;
				float3 direction = normalize( input.worldPos - _WorldSpaceCameraPos.xyz );
				float zDepth = 0;
				//float4 color = tex2D(_MainTex, input.uv);

                if ( direction.y < 0) {
                    float xrun = direction.x/-direction.y;
                    float zrun = direction.z/-direction.y;
					float bottom = objBottom.y;
                    float gdist = position.y - bottom;
                    position.x += gdist * xrun;
                    position.z += gdist * zrun;
                    position.y = bottom;
					output = tex2D(_MainTex, position.xz*_MainTex_ST.xy);
					float d = sin(position.x * 3 + _Time.y + sin(_Time.y+position.z * 2 + sin(position.x*5-_Time.y)));
					output.rgb += d*.1f;
				} else {
                    position += direction * 1000;
                    float depth = saturate(input.worldPos.y*_Horizon);
                    baseColor = lerp(_WColorA,_WColorB,depth);
    				output = baseColor;
                }
				output = ApplyFog(output, position);

				MarchGrass(output, input.worldPos.xyz, direction, zDepth);
				MarchBubble(output, input.worldPos.xyz, direction, zDepth);

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