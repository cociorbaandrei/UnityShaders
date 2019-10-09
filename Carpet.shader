Shader "Skuld/Carpet"
{
	Properties
	{
		_Color ("Color",Color) = (1,0,0,1)
		_MainTex ("Texture", 2D) = "white" {}
		_Height ("Height",float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="TransparentCutout" "Queue"="Geometry"}
		LOD 100
		Cull Off
		AlphaTest Greater .1

		Pass
		{
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float4 extras : TEXCOORD8;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float _Height;
			
			v2f vert (appdata v)
			{
				v2f o;
				//o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex = v.vertex;

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			[instance(32)]
			[maxvertexcount(3)]
			void geom (triangle v2f input[3], inout TriangleStream<v2f> tristream, uint instanceID : SV_GSInstanceID){
				int i = 0;
				v2f vert;

				if ( instanceID > 0 ){
					for ( i = 0; i < 3; i++ ){
						float s = ( 32-instanceID ) / 32;
						vert = input[i];
						vert.vertex.z += instanceID * _Height/10000;
						vert.extras[0] = instanceID;
						vert.vertex = UnityObjectToClipPos(vert.vertex);
						tristream.Append(vert);
					}
					tristream.RestartStrip();
				} else {
					for ( i = 0; i < 3; i++){
						vert = input[i];
						vert.extras[0] = instanceID;
						vert.vertex = UnityObjectToClipPos(vert.vertex);
						tristream.Append(vert);
					}
				}
			}

			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				//s is the instanceID scaled float value.
				float s = ( i.extras[0] ) / 32;
				col *= _Color * s;
				float u = ( ( i.uv[0] * 100 ) % 100) / 100;
				float v = ( ( i.uv[1] * 100 ) % 100) / 100;
				float min = s / 2;
				float max = 1 - min;

				//clip the carpet here based on UV.
				if ( u < min || u > max ||
					v < min || v > max ){
					clip(-1);
				}

				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
