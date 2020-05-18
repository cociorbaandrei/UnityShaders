Shader "Skuld/Experiments/Neuron Simulator Processor"
{
    Properties
    {
		_MainTex("Main Texture", 2D) = "white" {}
		_Depth("Simulation Depth (match the renderer)",int) = 20
		_Space("Space Between Spheres (match the renderer)",float) = 1.0
		_Size("Stimulator Size",float) = .1
		_TestIndex("Test Index",int) = -1

		[Toggle] _Reset("reset",float) = 0
	}
	
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100
		Cull Back

        Pass
        {
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _MainTex_TexelSize;
			bool _Reset;
			int _Depth;
			float _Space;
			float _Size;
			int _TestIndex;

			v2f vert (appdata v)
			{
				v2f o;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				
				if (any(_ScreenParams.xy != abs(_MainTex_TexelSize.zw))) 
				{
					o.vertex = 0;
				}
				else {
					o.vertex = UnityObjectToClipPos(v.vertex);
				}
				return o;
			}

			int getIndex(float2 uv) {
				int i = uv.y * _MainTex_TexelSize.z * _MainTex_TexelSize.z;
				i += uv.x * _MainTex_TexelSize.z;
				i -= 31;
				return i;
			}

			float3 GetPosition(int index) {
				int dim = _Depth + _Depth + 1;
				int dim3 = dim * dim * dim;
				if (index > dim3) index -= dim3;
				if (index < 0) index += dim3;
				float3 pos = 0;
				index -= 1;
				pos.y = floor(index / dim / dim);
				index -= pos.y * dim * dim;
				pos.z = floor(index / dim);
				index -= pos.z * dim;
				pos.x = floor(index);
				pos *= _Space;
				pos -= ( _Space * _Depth );
				return pos;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float speed = 1.0f / 256.0f;
				fixed4 col = 1;
				int index = getIndex(i.uv);
				float dim = _Depth + _Depth + 1;
				dim = dim * dim * dim;

				if (_Reset) 
				{
					col = (float)index / dim;
					if (index <= 1) {
						col.rgb = float3(1,0,0);
					}
					if (index >= dim) {
						col.rgb = float3(0,1,1);
					}
				} else {
					col = tex2D(_MainTex, i.uv);
					float3 objectPosition = GetPosition(index);
					bool added = false;

					for (int i = 0; i < 4; i++)
					{
						if ( unity_LightColor[i].w > 1) {
							float4 lightPos = float4(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i],1);
							float3 objectLightPos = mul(unity_WorldToObject, lightPos ).xyz / 10.0f;
							if (length(objectPosition - objectLightPos) < _Size) {
								col = 1;
								added = true;
							}
						}
					}
					if (!added) {
						//col = CheckNeighbor(index-)
						col.b -= speed;
						col.rg -= speed * 2;
					}
					//col.rg -= speed;
					col = saturate(col);
				}

				if (index == _TestIndex) {
					col = 1;
				}

				return col;
			}
			ENDCG
        }
    }
}
