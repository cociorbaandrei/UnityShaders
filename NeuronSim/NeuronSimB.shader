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
			float speed;

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

			int clampedIndex(int index) {
				int dim = _Depth + _Depth + 1;
				int dim3 = dim * dim * dim;
				if (index >= dim3) index -= dim3;
				if (index < 1) index += dim3;
				return index;
			}

			float2 getUV(int index) 
			{
				index += 31;
				float2 uv = 0;
				int dim = _MainTex_TexelSize.z;
				uv.y = floor(index / dim);
				index -= uv.y * dim;
				uv.x = floor(index);
				uv /= _MainTex_TexelSize.z;
				return uv;
			}

			float3 getPosition(int index) {
				index -= 1;

				float3 pos = 0;
				int dim = _Depth + _Depth + 1;
				pos.y = floor(index / dim / dim);
				index -= pos.y * dim * dim;
				pos.z = floor(index / dim);
				index -= pos.z * dim;
				pos.x = floor(index);
				pos *= _Space;
				pos -= (_Space * _Depth);
				return pos;
			}

			bool isExcited(float3 pos) {
				bool excited = false;
				for (int i = 0; i < 4; i++)
				{
					if (unity_LightColor[i].w > 1) {
						float4 lightPos = float4(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i], 1);
						float3 objectLightPos = mul(unity_WorldToObject, lightPos).xyz / 10.0f;
						if (length(pos - objectLightPos) < _Size) {
							excited = true;
						}
					}
				}
				return excited;
			}


			fixed4 CheckNeighbor(int index, bool excited, fixed4 col) {
				index = clampedIndex(index);

				float3 pos = getPosition(index);
				float2 uv = getUV(index);
				fixed4 nCol = tex2D(_MainTex, uv);
				bool nExcited = isExcited(pos);

				if (excited) {
					if (nExcited) {
						return col;
					} else {
						if (nCol.b > speed) {
							if (col.b < 1.0f) {
								col.b += speed;
								col.r += speed;
								col.g += speed;
							}
						}
					}
				}
				else {
					if (col.b > nCol.b ) {
						if (nCol.b < 1.0f) {
							if (col.b > speed ) {
								col.b -= speed;
								col.r -= speed;
								col.g -= speed;
							}
						}
					}
					else {
						if (nCol.b > speed) {
							if (col.b < 1.0f) {
								col.b += speed;
							}
						}
					}
				}
				return col;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				speed = 1.0f / 256.0f;
				fixed4 col = 1;
				int index = getIndex(i.uv);
				float dim = _Depth + _Depth + 1;
				dim = dim * dim * dim;

				if (_Reset) 
				{
					col = (float)index / dim / 4;
					if (index <= 1) {
						col.rgb = float3(1,0,0);
					}
					if (index >= dim) {
						col.rgb = float3(0,1,1);
					}
				} else {
					col = saturate(tex2D(_MainTex, i.uv));
					float3 objectPosition = getPosition(index);
					bool excited = isExcited(objectPosition);
					if (excited) {
						col.g = 1;
						col.r = 0;
					}
					
					col = CheckNeighbor(index - 1, excited, col);
					col = CheckNeighbor(index + 1, excited, col);
					col = CheckNeighbor(index - 11, excited, col);
					col = CheckNeighbor(index + 11, excited, col);
					col = CheckNeighbor(index - 121, excited, col);
					col = CheckNeighbor(index + 121, excited, col);

					col = saturate(col);
					if (isnan(col.b)) {
						col.r = 1;
						col.b = 0;
						col.g = 0;
					}
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
