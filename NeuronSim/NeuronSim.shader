Shader "Skuld/Experiments/Neuron Simulator Renderer"
{
    Properties
    {
		_MainTex("Texture", 2D) = "gray" {}
		_Depth("Simulation Depth",int) = 20
		_Space("Space Between Spheres",float) = 1.0
		_Size("Neuron Size",float) = .1
		[Toggle] _Reset("Reset",int) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 1                 // "One"
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 0            // "Zero"
		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend Operation", Float) = 0                 // "Add"
	}
    SubShader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
		LOD 100
		Cull Front
		Blend[_SrcBlend][_DstBlend]
		BlendOp[_BlendOp]

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

			struct appdata
			{
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 worldPos : WORLDPOSITION;
				float4 position : SV_POSITION;
				float4 objectPos : OBJECTPOSITION;
			};

			struct fragOutput
			{
				half4 color : SV_TARGET;
				float depth : SV_DEPTH;
			};

			struct rmReturn
			{
				float3 position;
				float3 localPosition;
				fixed4 color;
				float depth;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _MainTex_TexelSize;
			int _Depth;
			float _Size;
			float _Space;

			v2f vert(appdata v)
			{
				v2f o;
				o.position = UnityObjectToClipPos(v.position);
				o.objectPos = v.position;
				o.worldPos = mul(unity_ObjectToWorld, v.position).xyz;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}


			fixed4 shade(fixed4 col, float4 pos, float4 normal) {
				fixed3 lightColor = _LightColor0.rgb;
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float lightBright = dot(lightDir.xyz, normal.xyz);
				lightColor *= max(0,lightBright);
				normal.w = 1;
				lightColor += ShadeSH9(normal).rgb;
				col.rgb *= lightColor;
				return col;
			}

			float sphereDistance(float3 position)
			{
				float distance = length(position) - _Size / 2;
				return distance;
			}

			int posToIndex(float3 position) {
				//place position within grid of indicies.
				float3 mat = position;
				mat+= _Space*_Depth + (_Space/2);
				mat /= _Space;

				//calculate the actual index from position
				int rowSize = _Depth * 2 + 1;
				int index = (int)mat.y * rowSize * rowSize;
				index += (int)mat.z * rowSize;
				index += (int)mat.x;
				return index;
			}

			float3 getColor(int index) {
				int row = floor(index / _MainTex_TexelSize.z);
				int col = index - (row * (int)_MainTex_TexelSize.z);
				float2 uv = float2( (float)col / _MainTex_TexelSize.z, (float)row / _MainTex_TexelSize.z);
				half4 output = tex2D(_MainTex, uv);
				return output.rgb;
			}

			rmReturn RayMarch( v2f i)
			{
				rmReturn rmr;
				float4 cameraPosition = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
				float3 direction = normalize(i.objectPos - cameraPosition.xyz);
				float marched = 0;
				rmr.position = 0;
				rmr.localPosition = 0;
				rmr.color = 0;
				rmr.depth = 0;
				for (int x = 0; x < 100; x++) {
					float3 position = cameraPosition.xyz + direction * marched;

					float3 localPosition = position - clamp(round(position / _Space), -_Depth, _Depth)*_Space;

					float distance = sphereDistance(localPosition);
					if (distance <= .00001) {
						rmr.position = position;
						rmr.localPosition = localPosition;
						rmr.color = 1;
						rmr.depth = 1;
						return rmr;
					}
					marched += distance;
				}
				return rmr;
			}

			fragOutput frag(v2f i)
			{
				rmReturn rmr = RayMarch( i );

				fragOutput o;
				if (rmr.color.a > 0) {
					int index = posToIndex(rmr.position);

					o.color.rgb = getColor(index);
					o.color.a = 1;

					float4 clipPos = UnityObjectToClipPos(rmr.position);
					o.depth = clipPos.z / clipPos.w;
					float4 worldPosition = mul(unity_ObjectToWorld, float4(rmr.position, 1));
					float4 worldNormal = normalize(mul(unity_ObjectToWorld, float4(rmr.localPosition, 0)));
					o.color = shade(o.color, worldPosition, worldNormal);
				}
				else {
					o.color = 0;
					o.depth = 0;
				}
				
				return o;
			}
			ENDCG
		}
    }
}
