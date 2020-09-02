Shader "Skuld/Animation/Scrolling Texture Multi-Layer"
{
	Properties
	{	
		_Color ("Color", Color) = (1,1,1,1)

		_MainTex0 ("Layer 0", 2D) = "black" {}
		_Speed0 ("Layer 0 Scroll Speed", Float ) = 1
		_MainTex1 ("Layer 1", 2D) = "black" {}
		_Speed1 ("Layer 1 Scroll Speed", Float ) = 1
		_MainTex2 ("Layer 2", 2D) = "black" {}
		_Speed2 ("Layer 2 Scroll Speed", Float ) = 1
		_MainTex3 ("Layer 3", 2D) = "black" {}
		_Speed3 ("Layer 3 Scroll Speed", Float ) = 1
		_MainTex4 ("Layer 4", 2D) = "black" {}
		_Speed4 ("Layer 4 Scroll Speed", Float ) = 1
		_MainTex5 ("Layer 5", 2D) = "black" {}
		_Speed5 ("Layer 5 Scroll Speed", Float ) = 1
		_MainTex6 ("Layer 6", 2D) = "black" {}
		_Speed6 ("Layer 6 Scroll Speed", Float ) = 1
		_MainTex7 ("Layer 7", 2D) = "black" {}
		_Speed7 ("Layer 7 Scroll Speed", Float ) = 1
		_MainTex8 ("Layer 8", 2D) = "black" {}
		_Speed8 ("Layer 8 Scroll Speed", Float ) = 1
		_MainTex9 ("Layer 9", 2D) = "black" {}
		_Speed9 ("Layer 9 Scroll Speed", Float ) = 1

		[space]
		[KeywordEnum(Horizontal,Vertical)] _Direction ("Direction",Float) = 0

		[space]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"
		[Toggle] _ZWrite("Z-Write",Float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}

        Cull[_CullMode]
		Lighting Off
		SeparateSpecular Off
		ZWrite [_ZWrite]


		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			
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

			fixed4 _Color;
			fixed _Direction;

			sampler2D _MainTex0;
			float4 _MainTex0_ST;
			float _Speed0;
			sampler2D _MainTex1;
			float4 _MainTex1_ST;
			float _Speed1;
			sampler2D _MainTex2;
			float4 _MainTex2_ST;
			float _Speed2;
			sampler2D _MainTex3;
			float4 _MainTex3_ST;
			float _Speed3;
			sampler2D _MainTex4;
			float4 _MainTex4_ST;
			float _Speed4;
			sampler2D _MainTex5;
			float4 _MainTex5_ST;
			float _Speed5;
			sampler2D _MainTex6;
			float4 _MainTex6_ST;
			float _Speed6;
			sampler2D _MainTex7;
			float4 _MainTex7_ST;
			float _Speed7;
			sampler2D _MainTex8;
			float4 _MainTex8_ST;
			float _Speed8;
			sampler2D _MainTex9;
			float4 _MainTex9_ST;
			float _Speed9;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex0);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			float4 final;
			float2 uv;
			float4 col;
			float ia;
				
			float4 frag (v2f i) : SV_Target
			{
				final = _Color;

				uv = i.uv;
				if ( _Direction == 0 ){
					uv[0] += _Time * _Speed0;
				} else {
					uv[1] += _Time * _Speed0;
				}
				col = tex2D(_MainTex0, uv);
				ia = 1-col.a;
				final.rgb = (ia * final.rgb) + (col.a * col.rgb);

				uv = i.uv;
				if ( _Direction == 0 ){
					uv[0] += _Time * _Speed1;
				} else {
					uv[1] += _Time * _Speed1;
				}
				col = tex2D(_MainTex1, uv);
				ia = 1-col.a;
				final.rgb = (ia * final.rgb) + (col.a * col.rgb);

				uv = i.uv;
				if ( _Direction == 0 ){
					uv[0] += _Time * _Speed2;
				} else {
					uv[1] += _Time * _Speed2;
				}
				col = tex2D(_MainTex2, uv);
				ia = 1-col.a;
				final.rgb = (ia * final.rgb) + (col.a * col.rgb);

				uv = i.uv;
				if ( _Direction == 0 ){
					uv[0] += _Time * _Speed3;
				} else {
					uv[1] += _Time * _Speed3;
				}
				col = tex2D(_MainTex3, uv);
				ia = 1-col.a;
				final.rgb = (ia * final.rgb) + (col.a * col.rgb);

				uv = i.uv;
				if ( _Direction == 0 ){
					uv[0] += _Time * _Speed4;
				} else {
					uv[1] += _Time * _Speed4;
				}
				col = tex2D(_MainTex4, uv);
				ia = 1-col.a;
				final.rgb = (ia * final.rgb) + (col.a * col.rgb);

				uv = i.uv;
				if ( _Direction == 0 ){
					uv[0] += _Time * _Speed5;
				} else {
					uv[1] += _Time * _Speed5;
				}
				col = tex2D(_MainTex5, uv);
				ia = 1-col.a;
				final.rgb = (ia * final.rgb) + (col.a * col.rgb);

				uv = i.uv;
				if ( _Direction == 0 ){
					uv[0] += _Time * _Speed6;
				} else {
					uv[1] += _Time * _Speed6;
				}
				col = tex2D(_MainTex6, uv);
				ia = 1-col.a;
				final.rgb = (ia * final.rgb) + (col.a * col.rgb);

				uv = i.uv;
				if ( _Direction == 0 ){
					uv[0] += _Time * _Speed7;
				} else {
					uv[1] += _Time * _Speed7;
				}
				col = tex2D(_MainTex7, uv);
				ia = 1-col.a;
				final.rgb = (ia * final.rgb) + (col.a * col.rgb);

				uv = i.uv;
				if ( _Direction == 0 ){
					uv[0] += _Time * _Speed8;
				} else {
					uv[1] += _Time * _Speed8;
				}
				col = tex2D(_MainTex8, uv);
				ia = 1-col.a;
				final.rgb = (ia * final.rgb) + (col.a * col.rgb);

				uv = i.uv;
				if ( _Direction == 0 ){
					uv[0] += _Time * _Speed9;
				} else {
					uv[1] += _Time * _Speed9;
				}
				col = tex2D(_MainTex9, uv);
				ia = 1-col.a;
				final.rgb = (ia * final.rgb) + (col.a * col.rgb);

				return final;
			}
			ENDCG
		}
	}
}
