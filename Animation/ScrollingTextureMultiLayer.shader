Shader "Skuld/Scrolling Texture Multi-Layer" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex0 ("Layer 0", 2D) = (0,0,0,0) {}
		_Speed0 ("Layer 0 Scroll Speed", Float ) = 1
		_MainTex1 ("Layer 1", 2D) = (0,0,0,0) {}
		_Speed1 ("Layer 1 Scroll Speed", Float ) = 1
		_MainTex2 ("Layer 2", 2D) = (0,0,0,0) {}
		_Speed2 ("Layer 2 Scroll Speed", Float ) = 1
		_MainTex3 ("Layer 3", 2D) = (0,0,0,0) {}
		_Speed3 ("Layer 3 Scroll Speed", Float ) = 1
		_MainTex4 ("Layer 4", 2D) = (0,0,0,0) {}
		_Speed4 ("Layer 4 Scroll Speed", Float ) = 1
		_MainTex5 ("Layer 5", 2D) = (0,0,0,0) {}
		_Speed5 ("Layer 5 Scroll Speed", Float ) = 1
		_MainTex6 ("Layer 6", 2D) = (0,0,0,0) {}
		_Speed6 ("Layer 6 Scroll Speed", Float ) = 1
		_MainTex7 ("Layer 7", 2D) = (0,0,0,0) {}
		_Speed7 ("Layer 7 Scroll Speed", Float ) = 1
		_MainTex8 ("Layer 8", 2D) = (0,0,0,0) {}
		_Speed8 ("Layer 8 Scroll Speed", Float ) = 1
		_MainTex9 ("Layer 9", 2D) = (0,0,0,0) {}
		_Speed9 ("Layer 9 Scroll Speed", Float ) = 1

		[KeywordEnum(Horizontal,Vertical)] _Direction ("Direction",Float) = 0

		[space]
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 1                 // "One"
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 0            // "Zero"
		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend Operation", Float) = 0                 // "Add"
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"
		[Toggle] _ZWrite("Z-Write",Float) = 1

	}
	SubShader {
		Tags { "RenderType"="Clipping" "Queue"="Transparent" }
		
		Blend[_SrcBlend][_DstBlend]
        BlendOp[_BlendOp]
        Cull[_CullMode]
		Lighting Off
		SeparateSpecular Off
		ZWrite [_ZWrite]

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Fuck alpha:fade fadeTransition

		#pragma target 5.0

		sampler2D _MainTex0;
		float _Speed0;
		sampler2D _MainTex1;
		float _Speed1;
		sampler2D _MainTex2;
		float _Speed2;
		sampler2D _MainTex3;
		float _Speed3;
		sampler2D _MainTex4;
		float _Speed4;
		sampler2D _MainTex5;
		float _Speed5;
		sampler2D _MainTex6;
		float _Speed6;
		sampler2D _MainTex7;
		float _Speed7;
		sampler2D _MainTex8;
		float _Speed8;
		sampler2D _MainTex9;
		float _Speed9;
		fixed4 _Color;
		fixed _Direction;

		struct Input {
			float2 uv_MainTex;
		};


		void surf (Input IN, inout SurfaceOutput o) {
			// Albedo comes from a texture tinted by color
			float2 uv = IN.uv_MainTex0;
			if (_Direction == 0){
				uv[0]+=_Time*_Speed0;
			} else {
				uv[1]+=_Time*_Speed0;
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
