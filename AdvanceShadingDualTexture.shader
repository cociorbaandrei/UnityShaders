Shader "Skuld/Advanced Shading and Dual Texture"
{
	Properties {
        //[Enum(BlendMode)] _Mode("Rendering Mode", Float) = 0                                     // "Opaque"
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 1                 // "One"
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 0            // "Zero"
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend Operation", Float) = 0                 // "Add"
        [Enum(DepthWrite)] _ZWrite("Depth Write", Float) = 1                                         // "On"
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"

		_MainTex("Base (RGB)", 2D) = "gray" {}
		_Color("Fresnel Color", Color)=(1, 1, 1, 1)
		_RimValue("Fresnel Retract", Range(0,10)) = 0.5

		_Spread("Edge Sharpness", Range(0,10)) = .5
		_Pivot("Shade Center",Range(-1,1)) = 0
		_Max("Max Brightness", Range(0,1)) = 1.0
		_Min("Min Brightness",Range(0,1)) = 0.0

		_SubTex("Tattoo (RGB)", 2D) = "gray" {}
		[Toggle] _TGlow("Tattoo Glow", Float) = 0
		_TGlowColor("Glow Color", Color)=(1, 1, 1, 1)
		[Toggle] _TRainbow("Rainbow", Float) = 0
		_TSpeed("Glow Speed",Range(0,10)) = 1
		_TSharpness("Glow Sharpness",Range(1,200)) = 1.0
	}

	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Transparent" }

		//RenderType[_Mode]
        Blend[_SrcBlend][_DstBlend]
        BlendOp[_BlendOp]
        ZWrite[_ZWrite]
        Cull[_CullMode]

		CGPROGRAM
			
		/*this is how you control the lighting and alpha. tags does nothing. */
		//#pragma surface surf NoLighting alpha
		//#pragma surface surf Flat 
		#pragma surface surf Flat
		#pragma target 3.0
		struct Input
		{
			float2 uv_MainTex;
			float3 viewDir;
			float3 worldNormal;
			float3 worldPos;
			float4 screenPos;
		};
			
		sampler2D _MainTex;
		float4 _Color;
		float _Spread;
		float _Pivot;
		float _Max;
		float _Min;
		float _RimValue;
		
		sampler2D _SubTex;
		fixed _TGlow;
		float _TSpeed;
		float4 _TGlowColor;
		float _TSharpness;
		fixed _TRainbow;
		float3 rColor;
		int rState = 0;
		Input IN2;
						
		void applyTatto(Input IN, inout SurfaceOutput o)
		{
			float2 uv = IN.uv_MainTex;
			float4 t = tex2D(_SubTex, uv);
			float ad = 1 - t.a;
			if ( _TGlow ){
				int time = ( _Time * (_TSpeed*1000) );
				float gp = ( time % 120 ) / 100.0f - .1;

				float igv = (gp - uv[1]);
				if (igv < 0 ) igv = 0 - igv;
				igv = igv * _TSharpness;
				if (igv > 1 ) igv = 1;
				if (igv < 0 ) igv = 0;
				float gv = 1-igv;
				if (_TRainbow){
					int rt = _Time * 7000;
					float tc = ( rt ) % 300 / 100.0f;
					rColor[0] = 1.0 - tc;
					rColor[1] = tc;
					rColor[2] = tc - 1.0;
					if (rColor[0] < -1.0) rColor[0] = 0 - rColor[0] - 1;
					if (rColor[1] > 1.0) rColor[1] = 1.0 - ( rColor[1] - 1.0 );
					if (rColor[2] > 1.0) rColor[2] = 1.0 - ( rColor[2] - 1.0 );
					if (rColor[0] < 0.0) rColor[0] = 0;
					if (rColor[1] < 0.0) rColor[1] = 0;
					if (rColor[2] < 0.0) rColor[2] = 0;
					_TGlowColor.r = rColor[0];
					_TGlowColor.g = rColor[1];
					_TGlowColor.b = rColor[2];
				}
				t.rgb = (t.rgb * igv) + (_TGlowColor.rgb * gv);
			}
			o.Albedo = ( o.Albedo * ad ) + (t * t.a);
		}

		void surf(Input IN, inout SurfaceOutput o)
		{
			IN2 = IN;
			float2 uv = IN.uv_MainTex;
			float4 c = tex2D(_MainTex, uv);
			o.Alpha = c.a;

			//Fresnel
			float3 normal = normalize(IN.worldNormal);
			float3 dir = normalize(IN.viewDir);
			float val = abs(dot(dir, normal));
			float rim = 1 - val * _RimValue;
			if (rim < 0.0 ) rim = 0.0;
			rim *= _Color.a;
			float orim = 1 - rim;
			o.Albedo = (_Color * rim) + (c * orim);
			//applyTatto(IN, o);
		}
		
		fixed4 LightingFlat(SurfaceOutput o, fixed3 lightDir, fixed atten) {
			half value = dot (o.Normal, lightDir);

			value = value * ( _Spread ) + _Pivot;
			if ( value < _Min ) value = _Min;
			if ( value > _Max ) value = _Max;

			o.Albedo = o.Albedo * value;
			applyTatto(IN2,o);
			return fixed4(o.Albedo, o.Alpha);
		}
		ENDCG
	} 
	FallBack "Diffuse"
}