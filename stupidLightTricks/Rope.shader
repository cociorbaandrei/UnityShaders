Shader "Skuld/Rope"
{
	Properties
	{
		_Color("Color", Color)=(1, 1, 1, 1)
		_Code ("Intensity Passcode",int) = 0
		_Droop ("Droop amount",float) = .1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
		Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			float4 _Color;
			int _Code;
			float _Droop;

			float4 GetLightPosition()
			{
				for(int i = 0; i < 4; i++)
				{
					if(unity_LightColor[i].w != _Code)
						continue;
					float4 p;
					p.x = unity_4LightPosX0[i];
					p.y = unity_4LightPosY0[i];
					p.z = unity_4LightPosZ0[i];
					p.w = 1;//1 = success
					return p;
				}
				float4 p = float4(0,0,0,0);
				return p;//0 = error
			}

			inline float angleBetween(fixed2 to, fixed2 from) {
				float dpot = dot(normalize(to), normalize(from) );
				float angle = acos( dpot );
				if ( from.y*to.x < from.x*to.y ){
					angle = -angle;
				}
				return angle;
			}

			float2 rotate2(float2 inCoords, float rot)
			{
				float sinRot;
				float cosRot;
				sincos(rot, sinRot, cosRot);
				return mul(float2x2(cosRot, -sinRot, sinRot, cosRot),inCoords);
			}

			v2f vert (appdata v)
			{
				v2f o;
				float4 lightPos = GetLightPosition();
				
				if ( lightPos.w == 0 ){
					v.vertex = 0;
					o.vertex = UnityObjectToClipPos(v.vertex);
				} else {
					//z-values: 0-20 is what the pipe was made to be. If it's bigger than this, it will fail.
					//unity converts this to 0-.2 locally
					float s = v.vertex.z/.2f;//so this scale is 0-1, based on the object.

					//first calculations in object space:
					float4 olp= lightPos;
					lightPos = mul(unity_WorldToObject, lightPos);
					float len = sqrt( lightPos.x*lightPos.x + lightPos.z*lightPos.z );
					v.vertex.y += s * lightPos.y;
					v.vertex.z = s * len;
					
					//this is easier to do in object space.
					float angle = angleBetween(float2(0,1),lightPos.xz);
					v.vertex.xz = rotate2( v.vertex.xz, angle);
					
					//then calculations in world space:
					v.vertex = mul(unity_ObjectToWorld,v.vertex);
					v.vertex.y -= sin( s * 3.141592653589793238462)*_Droop;

					o.vertex = UnityWorldToClipPos(v.vertex);
				}
				
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// apply fog
				fixed4 col = _Color;
				return col;
			}
			ENDCG
		}
	}
}
