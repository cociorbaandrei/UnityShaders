Shader "Skuld/Animated Texture"
{
	Properties {
		_MainTex("Animation Texture (Remember when building your map, first frame is bottome left)", 2D) = "black" {}
		_Color("Transparency Color", Color)=(1, 1, 1, 1)
		_TransRange("Range",range(0.0,1.0)) = .1
		_UTiles("Columns", Int) = 1
		_VTiles("Rows", Int) = 1
		_Frames("Total Frames", Int) = 1
		_FrameTime("Length of Time to Show Each Frame in Seconds",float) = 1.0
	}

	SubShader {
		Tags { "RenderType"="Clipping" "Queue"="Transparent" }
		Cull Off

		CGPROGRAM
		
		/*this is how you control the lighting and alpha. tags does nothing. */
		//#pragma surface surf NoLighting alpha
		#pragma surface surf NoLighting alpha:fade fadeTransition
		#pragma target 3.0
	
		sampler2D _MainTex;
		int _UTiles;
		int _VTiles;
		int _Frames;
		float _FrameTime;
		float4 _Color;
		float _TransRange;
			
		struct Input
		{
			float2 uv_MainTex;
			float3 viewDir;
			float3 worldNormal;
			float3 worldPos;
			float4 screenPos;
		};

		void surf(Input IN, inout SurfaceOutput o)
		{
			float2 uvs = IN.uv_MainTex;
			int TInt = _Time * 20 / _FrameTime;
			int frame = TInt % _Frames;
			//uvs[1] = frame/uvs[1];
			//
			float uStep = uvs[0] / _UTiles;
			uvs[0] = uStep + ( ( 1.0 / _UTiles ) * ( frame % _UTiles ) );

			int row = frame / _VTiles;
			float vStep = uvs[1] / _VTiles;
			uvs[1] = vStep + row * (1.0/_VTiles);

			float4 c = tex2D(_MainTex, uvs);
			o.Albedo = c.rgb;
			if ( c[0] > _Color[0]-_TransRange && c[0] < _Color[0]+_TransRange &&
				c[1] > _Color[1]-_TransRange && c[1] < _Color[1]+_TransRange &&
				c[2] > _Color[2]-_TransRange && c[2] < _Color[2]+_TransRange
			){
				o.Alpha = 0.0;
			} else {
				o.Alpha = c.a;
			}
			
		}

		fixed4 LightingNoLighting(SurfaceOutput s, fixed3 lightDir, fixed atten) {
			return fixed4(s.Albedo, s.Alpha);
		}

		ENDCG
	} 
	FallBack "Diffuse"
}