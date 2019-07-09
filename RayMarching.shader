Shader "Skuld/Ray Marching Fun"
{
	Properties {
		_MainTex("Noise Texture", 2D) = "gray" {}
		_AmbOcc ("Ambient Occlusion", Range(0, 5)) = 1.0
		_Steps("Iterations",Range(0,1000)) = 100
		_Size("Grid Size",Range(0,10) ) = 1
		_Radius("Sphere Radius",Range(0,1) ) = 0.1
		_MinDist("Minimum Distance",Range(0,1)) = .01
	}

	SubShader {
		Tags { "RenderType"="Transparent" "Queue"="Transparent-1" }
		LOD 100
		Cull Off
		ZWrite Off

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
			float _Radius;
			float _Steps;
			float _Size;
			float _MinDist;
			float _AmbOcc;

			v2f vert ( appdata v) {
				v2f o;
				o.position = UnityObjectToClipPos(v.position);
				o.worldPos = mul(unity_ObjectToWorld, v.position).xyz;
				o.uv = TRANSFORM_TEX(v.uv,_MainTex);
				return o;
			}

			float sphereDistance ( float3 position, float center )
			{
				return length(position - center) - _Radius;
			}

			float DE(float3 position )
			{
				//position = fmod(position + float3(500, 500, 500), _Size);
				position = frac(position / _Size) * _Size;
				float3 center = float3(_Size/2, _Size/2, _Size/2);
				float distance = sphereDistance(position, center);
				return distance;
			}

			fixed4 shiftColor( fixed4 inColor, float shift )
			{
				float r = shift * 3.1415926535897932384626433832795 / 180;
				float u = cos(r);
				float w = sin(r);
				
				fixed4 ret;
				ret.r = (.299+.701 * u+.168 * w)*inColor.r
					+ (.587-.587 * u+.330 * w)*inColor.g
					+ (.114-.114 * u-.497 * w)*inColor.b;
				ret.g = (.299-.299 * u-.328 * w)*inColor.r
					+ (.587+.413 * u+.035 * w)*inColor.g
					+ (.114-.114 * u+.292 * w)*inColor.b;
				ret.b = (.299-.3 * u+1.25 * w)*inColor.r
					+ (.587-.588 * u-1.05 * w)*inColor.g
					+ (.114+.886 * u-.203 * w)*inColor.b;	
				ret[3] = inColor[3];
				return ret;
			}

			fixed4 raymarch (float3 position, float3 direction, float2 uv)
			{
				fixed4 color = tex2D(_MainTex, uv);
				fixed4 noColor = (0,0,0,0);

				for (int i = 0; i < _Steps; i++)
				{
					float distance = DE(position);
					if (distance <= 0.0001) {
						return shiftColor( color * saturate(pow(1- i / _Steps, _AmbOcc)), i*10 );
					}
					position += direction * distance;
				}
				return noColor;
			}

			fixed4 frag(v2f input ) : SV_Target
			{
				float2 uv = input.uv;
				uv[0] = uv[0]+sin(_Time*40);
				if (uv[0] < 0.0) uv[0]++;
				if (uv[0] > 1.0) uv[0]--;
				uv[1] = uv[1]+cos(_Time*40);
				if (uv[1] < 0.0) uv[1]++;
				if (uv[1] > 1.0) uv[1]--;
				
				float3 direction = normalize( input.worldPos - _WorldSpaceCameraPos.xyz );
				
				return raymarch ( _WorldSpaceCameraPos.xyz, direction, uv);
			}
			ENDCG
		}
	}
}