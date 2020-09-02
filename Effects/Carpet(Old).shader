Shader "Skuld/Effects/Carpet(Old)"
{
	Properties
	{
		_CarpetColor ("Color",Color) = (1,0,0,1)
		_MainTex ("Texture", 2D) = "white" {}
		_Height ("Height",float) = 1
		[KeywordEnum(XAxis, YAxis, ZAxis, Normal)] _Direction ("Direction",int) = 0
		_Size( "Fuzzy Square Size", float ) = 0
		_XRand ("X Randomness", float) = 1
		_YRand ("Y Randomness", float) = 1
		_Radius ("Radius",range(0,.5)) = .5
		_CMin ("Minimum Brightness",range(0,1)) = 0
		_LBright ("Lightmap Increase",range(0,1)) = 0
		_MaxInstances ("Number of Layers",range(1,32)) = 0
		[Toggle(_)] _DisableLightMaps ("Disable Light Maps",float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest"}
		LOD 100
		Cull Off
		AlphaTest Greater .1

		Pass
		{
			CGPROGRAM
			#pragma target 4.5
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			// make fog work
			#pragma multi_compile_instancing

			#include "UnityPBSLighting.cginc"
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float2 lmuv : TEXCOORD1;
				float4 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 lmuv : TEXCOORD1;
				float3 pixelPos : TEXCOORD2;
				float4 vertex : SV_POSITION;
				float3 normal: NORMAL;
				float4 extras : TEXCOORD8;
				float3 worldNormal : TEXCOORD7;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			// sampler2D unity_Lightmap;
			// half4 unity_LightmapST;
            float4 _CarpetColor;
			float _Height;
			float _Size;
			float _XRand;
			float _YRand;
			float _Radius;
			float _CMin;
			int _Direction;
			int _MaxInstances;
			float _LBright;
			bool _DisableLightMaps;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = v.vertex;
				o.pixelPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = normalize( v.normal );
				o.worldNormal = normalize( UnityObjectToWorldNormal( o.normal ));
				//o.lmuv = v.lmuv;
				o.lmuv = v.lmuv.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				return o;
			}
			
			[instance(32)]
			[maxvertexcount(3)]
			void geom (triangle v2f input[3], inout TriangleStream<v2f> tristream, uint instanceID : SV_GSInstanceID){
				int i = 0;
				v2f vert;

				if ( instanceID < _MaxInstances){
					for ( i = 0; i < 3; i++ ){
						vert = input[i];
						switch(_Direction){
							case 0:
								vert.vertex.x += instanceID * _Height/10000;
								break;
							case 1:
								vert.vertex.y += instanceID * _Height/10000;
								break;
							case 2:
								vert.vertex.z += instanceID * _Height/10000;
								break;
							case 3: 
								vert.vertex.xyz += instanceID * ( vert.normal * _Height/32 );
								break;
						}
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
				col *= _CarpetColor;
				if (!_DisableLightMaps){
					fixed3 lmcol = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,i.lmuv));
					lmcol *= 1 - _LBright;
					lmcol += _LBright;
					col.rgb *= lmcol;
				}

				
				float2 cut;
				float2 offset;
				float range = 1-(i.extras[0] / _MaxInstances);
				float iRange = i.extras[0] / (_MaxInstances-1);
				col.rgb *=  iRange * (1-_CMin) + _CMin;

				//might want to make these selectable.
				cut.x = i.pixelPos.x;
				cut.y = i.pixelPos.z;

				offset.x = cos(cut.x *_XRand) * _Radius * iRange;
				offset.y = cos(cut.y *_YRand) * _Radius * iRange;

				cut.x = cos( cut.x / _Size );
				if ( cut.x < -range + offset.x || cut.x > range + offset.x ){
					clip(-1);
				}
				
				cut.y = cos( cut.y / _Size );
				if ( cut.y < -range + offset.y || cut.y > range + offset.y ){
					clip(-1);
				}

				return col;
			}
			ENDCG
		}
	}
}
