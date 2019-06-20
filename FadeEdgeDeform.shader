Shader "Skuld/Fade, Deform and Edge"
{
	Properties {
		_MainTex("Base (RGB)", 2D) = "gray" {}
		
		_Color("Fade Color", Color)=(1, 1, 1, 1)
		_RimValue("Fade value", Range(0, 5)) = 0.5
		_minTrans("Min Translucancy", Range(0, 1)) = 0.0
		_maxTrans("Max Translucancy", Range(0, 1)) = 1.0

		_BorderColor("Border Color", Color)=(1, 1, 1, 1)
		_FRimValue("Border value", Range(0, 1)) = 0.5
		
		[Toggle] _fadeByDistance("Fade By Distance", Float) = 0
		[Toggle] _invert("inverted", Float) = 0
		_Radius("Fade Radius", Float)=100	
	}

	SubShader {
		Tags { "RenderType"="Clipping" "Queue"="Transparent" }
		
		CGPROGRAM
		
		/*this is how you control the lighting and alpha. tags does nothing. */
		//#pragma surface surf NoLighting alpha
		#pragma surface surf NoLighting alpha:fade fadeTransition
		#pragma target 3.0

        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
		fixed4 _Color;
		fixed4 _BorderColor;
		fixed _RimValue;
		fixed _FRimValue;
		fixed _minTrans;
		fixed _maxTrans;
		uniform float _Radius;

		struct Input
		{
			float2 uv_MainTex;
			float3 viewDir;
			float3 worldNormal;
			float3 worldPos;
			float4 screenPos;
		};

		uniform float3 _SectionPlane;
		uniform float3 _SectionPoint;
		uniform sampler2D _Curves;
		fixed _fadeByDistance;
		fixed _invert;
		
		inline float fadeTransition(float3 posWorld)
		{
			float dist = saturate( .5 - ( length( _WorldSpaceCameraPos - posWorld ) / (_Radius * 2 ) ) );
			return dist;
		}

		void surf(Input IN, inout SurfaceOutput o)
		{
			half4 c = tex2D(_MainTex, IN.uv_MainTex);
			//o.Albedo = c.rgb;
			//o.Metallic = _Metallic;
            //o.Smoothness = _Glossiness;
			o.Alpha = c.a;

			float3 normal = normalize(IN.worldNormal);
			float3 dir = normalize(IN.viewDir);
			float val = abs(dot(dir, normal));

			if ( val < _FRimValue ) {
				//rim
				o.Albedo = _BorderColor;
				o.Alpha = _BorderColor[3];
			} else {
				//fade
				o.Albedo = c.rgb * _Color;
				float3 normal = normalize(IN.worldNormal);
				float3 dir = normalize(IN.viewDir);
				float val = 1 - (abs(dot(dir, normal)));
				float rim = val * _RimValue;
				o.Alpha = c.a * rim;
				o.Alpha = o.Alpha * ( _maxTrans - _minTrans ) + _minTrans;
			}

			//distort
			if (_fadeByDistance){
				float fade = fadeTransition(IN.worldPos);
				//o.Albedo *= fade.rgb;
				o.Alpha *= ( _invert ) ? 1.0 - fade : fade;
			}
		}

		fixed4 LightingNoLighting(SurfaceOutput s, fixed3 lightDir, fixed atten) {
            return fixed4(s.Albedo, s.Alpha);
        }

		ENDCG
	} 
	FallBack "Diffuse"
}