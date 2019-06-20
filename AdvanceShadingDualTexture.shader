Shader "Skuld/Advanced Shading and Dual Texture"
{
	Properties {
		_MainTex("Base (RGB)", 2D) = "gray" {}
		_SubTex("Base (RGB)", 2D) = "gray" {}
		
		_Color("Fresnel Color", Color)=(1, 1, 1, 1)
		_RimValue("Fresnel Retract", Range(0,10)) = 0.5

		_Spread("Edge Sharpness", Range(0,10)) = .5
		_Pivot("Shade Center",Range(-1,1)) = 0
		_Max("Max Brightness", Range(0,1)) = 1.0
		_Min("Min Brightness",Range(0,1)) = 0.0
	}

	SubShader {
		Tags { "RenderType"="Geometry" "Queue"="Geometry+1" }
		
		CGPROGRAM
		
		/*this is how you control the lighting and alpha. tags does nothing. */
		//#pragma surface surf NoLighting alpha
		#pragma surface surf Flat 
		#pragma target 3.0

        sampler2D _MainTex;
		sampler2D _SubTex;
        float _Glossiness;
        float _Metallic;
		float4 _Color;
		float _Spread;
		float _Pivot;
		float _Max;
		float _Min;
		float _RimValue;
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

		fixed4 LightingFlat(SurfaceOutput s, fixed3 lightDir, fixed atten) {
			half value = dot (s.Normal, lightDir);

			value = value * ( _Spread ) + _Pivot;
			if ( value < _Min ) value = _Min;
			if ( value > _Max ) value = _Max;

			s.Albedo = s.Albedo * value;
            return fixed4(s.Albedo, s.Alpha);
        }

		void surf(Input IN, inout SurfaceOutput o)
		{
			float4 c = tex2D(_MainTex, IN.uv_MainTex);
			//o.Metallic = _Metallic;
            //o.Smoothness = _Glossiness;
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
			//o.Albedo = (c * orim);
			//o.Alpha = c.a;
			//o.Alpha = o.Alpha * ( _maxTrans - _minTrans ) + _minTrans;
		}
		
		ENDCG
	} 
	FallBack "Diffuse"
}