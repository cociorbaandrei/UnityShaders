Shader "Skuld/Effects/Clouds"
{
	Properties
	{
		_CloudColor("Cloud Color", Color)=(1, 1, 1, 1)
		_Brightness("Brightness",Range(0,1)) = 0
		_Speed ("Cloud Speed", Range(0,10)) = 1
		_Coverage ("Cloud Coverage", Range(0,1)) = 1
		[Toggle] _ApplyFog ("Apply Fog", Float) = 1
		_MainTex1 ("Layer 1", 2D) = "white" {}
		_MainTex2 ("Layer 2", 2D) = "white" {}
		_MainTex3 ("Layer 3", 2D) = "white" {}
		_MainTex4 ("Layer 4", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent-1"}
		LOD 100

		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
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
			};

			fixed4 _CloudColor;
			float _Brightness;
			sampler2D _MainTex1;
			float4 _MainTex1_ST;
			sampler2D _MainTex2;
			float4 _MainTex2_ST;
			sampler2D _MainTex3;
			float4 _MainTex3_ST;
			sampler2D _MainTex4;
			float4 _MainTex4_ST;
			float _ApplyFog;
			float _Speed;
			float _Coverage;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex1);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture

				float2 uv1 = i.uv;
				fixed4 col1 = tex2D(_MainTex1, uv1);
				
				float2 uv2 = i.uv;
				uv2.x += _Time*_Speed;
				fixed4 col2 = tex2D(_MainTex2, uv2);
				
				float2 uv3 = i.uv;
				uv3.y += _Time*_Speed;
				fixed4 col3 = tex2D(_MainTex3, uv3);
				
				float2 uv4 = i.uv;
				uv4.x -= _Time*_Speed;
				uv4.y -= _Time*_Speed;
				fixed4 col4 = tex2D(_MainTex4, uv4);

				float alpha = saturate(col1.a + col2.a + col3.a + col4.a);
				fixed4 col = (col1 + col2 + col3 + col4) / 4;
				col = ( col * col.a) + ( _CloudColor * (1-col.a));
				col = col*_Brightness;
				col.a = min(alpha,_Coverage);
				// apply fog
				if ( _ApplyFog > 0 ) {
					UNITY_APPLY_FOG(i.fogCoord, col);
				}
				return col;
			}
			ENDCG
		}
	}
}
