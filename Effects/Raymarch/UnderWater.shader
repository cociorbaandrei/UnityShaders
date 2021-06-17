Shader "Skuld/Effects/Ray Marching/Underwater"
{
	Properties {
        _MainTex("Ground",2D) = "black" {}
		_Steps("Iterations",Range(0,1000)) = 100
		_TCut("Transparent Cutout",Range(0,1)) = 1
        _Horizon("Horizon falloff",Float) = 1
        [hdr]_WColorA("WaterColor A",Color) = (0,0,1,1)
        [hdr]_WColorB("WaterColor A",Color) = (0,1,1,1)
	}

	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		LOD 100
		Cull back		

		pass {	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float4 position : SV_POSITION;
			};

			struct appdata
			{
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Steps;

            float _Horizon;
            float4 _WColorA;
            float4 _WColorB;

			v2f vert ( appdata v) {
				v2f o;
				o.position = UnityObjectToClipPos(v.position);
				o.worldPos = mul(unity_ObjectToWorld, v.position).xyz;
				o.uv = TRANSFORM_TEX(v.uv,_MainTex);
				return o;
			}

			float4 frag(v2f input ): SV_Target
			{
				float4 output;
                float4 baseColor;
                float3 position = _WorldSpaceCameraPos.xyz;
				
				float3 direction = normalize( input.worldPos - _WorldSpaceCameraPos.xyz );
				//float4 color = tex2D(_MainTex, input.uv);			

                if ( direction.y < 0) {
                    output = float4(0,1,0,1);
                    float xrun = direction.x/-direction.y;
                    float zrun = direction.z/-direction.y;
                    //float bottom = mul(unity_ObjectToWorld,float3(0,0,0)).y;
                    float bottom = unity_ObjectToWorld._m31;
                    float gdist = position.y - bottom;
                    position.x += gdist * xrun;
                    position.z += gdist * zrun;
                    position.y = bottom;
                    output.r = fmod(position.x,1.0f);
                    output.b = fmod(position.z,1.0f);
				} else {
                    position += direction * 1000;
                    float depth = saturate(input.worldPos.y*_Horizon);
                    baseColor = lerp(_WColorA,_WColorB,depth);
    				output = baseColor;
                }
                /*
                float4 clipPos = UnityWorldToClipPos(position);
                float zDepth = clipPos.z / clipPos.w;
                 if !defined(UNITY_REVERSED_Z)
                zDepth = zDepth * 0.5 + 0.5;
                 endif
                */
				/*
                xdir = unity_ObjectToWorld._m00_m01_m02; //left
				zdir = unity_ObjectToWorld._m10_m11_m12; //front
				ydir = unity_ObjectToWorld._m20_m21_m22; //bottom
				center = unity_ObjectToWorld._m30_m31_m32; //bottom
				*/
                //output.depth = zDepth;
				/*
				output.r = unity_ObjectToWorld._m30;
				output.g = unity_ObjectToWorld._m31;
				output.b = unity_ObjectToWorld._m32;
				*/
				return output;
			}
			ENDCG
		}
	}
}