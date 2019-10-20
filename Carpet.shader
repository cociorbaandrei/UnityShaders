// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable

Shader "Skuld/Carpet"
{
	Properties
	{
		_Count ("Layers",range(0,32)) = 32
		_Color ("Color",Color) = (1,0,0,1)
		_MainTex ("Texture", 2D) = "white" {}
		_Height ("Height",float) = 1
		_Rotation ("Rotation Amount", range(0,6.3)) = .1
		_Radius ("Radius",range(0,.5)) = .5
			
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
			#pragma multi_compile_fwdbase

			#include "UnityPBSLighting.cginc"
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float2 lmuv : TEXCOORD1;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 lmuv : TEXCOORD1;
				float4 vertex : SV_POSITION;
				float4 extras : TEXCOORD8;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			// sampler2D unity_Lightmap;
			// half4 unity_LightmapST;
            float4 _Color;
			float _Height;
			float _Rotation;
			float _Radius;
			int _Count;
			
			v2f vert (appdata v)
			{
				v2f o;
				//o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex = v.vertex;

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.lmuv = v.lmuv;
				return o;
			}
			
			[instance(32)]
			[maxvertexcount(3)]
			void geom (triangle v2f input[3], inout TriangleStream<v2f> tristream, uint instanceID : SV_GSInstanceID){
				if (instanceID < _Count ){
					int i = 0;
					v2f vert;

					for ( i = 0; i < 3; i++ ){
						vert = input[i];
						vert.vertex.z += instanceID * _Height/10000;
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
				fixed3 lmcol = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,i.lmuv));
				col.rgb *= lmcol;
				//s is the instanceID scaled float value.
				float s = ( i.extras[0] ) / _Count;
				col *= _Color * s;
				float u = ( ( i.uv[0] * 100 ) % 100) / 100;
				float v = ( ( i.uv[1] * 100 ) % 100) / 100;
				float uc = ( s * cos(i.uv[0]*_Rotation)*_Radius)+.5;
				float vc = ( s * sin(i.uv[1]*i.uv[0]*_Rotation)*_Radius)+.5;
				float is = 1-s;
				float umin = uc - is;
				float umax = uc + is;
				float vmin = vc - is;
				float vmax = vc + is;

				//clip the carpet here based on UV.
				if ( u < umin || u > umax ||
					v < vmin || v > vmax ){
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
