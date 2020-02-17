Shader "Skuld/ScrollingTexture" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Speed ("Scroll Speed", Float ) = 1
		[KeywordEnum(Horizontal,Vertical)] _Direction ("Direction",Float) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry+1" }

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Fuck

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		fixed4 _Color;
		fixed _Direction;
		float _Speed;

		struct Input {
			float2 uv_MainTex;
		};


		void surf (Input IN, inout SurfaceOutput o) {
			// Albedo comes from a texture tinted by color
			float2 uv = IN.uv_MainTex;
			if (_Direction == 0){
				uv[0]+=_Time*_Speed;
			} else {
				uv[1]+=_Time*_Speed;
			}
			fixed4 c = tex2D (_MainTex, uv) * _Color;
			
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Alpha = c.a;
		}

		fixed4 LightingFuck(SurfaceOutput o, fixed3 lightDir, fixed atten) {
			return fixed4(o.Albedo, o.Alpha);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
