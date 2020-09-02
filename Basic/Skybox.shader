Shader "Skuld/Deprecated/Basics/Skybox"
{
    Properties
    {
        _Cube ("Cube", CUBE) = "white" {}
		_Rot ("View Direction",Vector) = (0,0,0)
    }
    SubShader { 
		Pass { 
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
        
			struct v2f {
				float4 pos : SV_POSITION;
				float3 uv : TEXCOORD0;
			};

			float2x2 rotate2(float rot)
			{
				float sinRot;
				float cosRot;
				sincos(rot, sinRot, cosRot);
				return float2x2(cosRot, -sinRot, sinRot, cosRot);
			}

			float4 _Rot;
			v2f vert (float4 v : POSITION, float3 n : NORMAL)
			{
				v2f o;				
				o.pos = UnityObjectToClipPos(v);

				float3 viewDir = normalize(ObjSpaceViewDir(v));
				viewDir.xy = mul(rotate2(_Rot.z),viewDir.xy);
				viewDir.xz = mul(rotate2(_Rot.y),viewDir.xz);
				viewDir.zy = mul(rotate2(_Rot.x),viewDir.zy);

				o.uv = reflect(-viewDir, n);
				return o;
			}

			samplerCUBE _Cube;
			half4 frag (v2f i) : SV_Target
			{
				return texCUBE(_Cube, i.uv);
			}
			ENDCG 
		} 
	}
}
