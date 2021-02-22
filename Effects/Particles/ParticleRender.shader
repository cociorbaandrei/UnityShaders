Shader "Skuld/Effects/GPU Particles/Render"
{
    Properties
    {
		_MainTex("Color Texture", 2D) = "white" {}
		[hdr]_Buffer("Compute Input Texture", 2D) = "white" {}
		_Particle("Particle Texture",2D) = "white"{}
		_Vertices("Number of Vertices in Default Shape", int) = 0
		_Size("Particle Size", float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 1                 // "One"
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 0            // "Zero"
		//[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend Operation", Float) = 0                 // "Add"
		[Toggle] _ZWrite("Z-Write",Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		cull Off
		Blend[_SrcBlend][_DstBlend]
		//BlendOp[_BlendOp]
		Lighting Off
		SeparateSpecular Off
		ZWrite[_ZWrite]

        Pass
        {
            CGPROGRAM
			#pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
			#pragma geometry geom
            #pragma multi_compile_instancing
			#pragma multi_compile
			
			#include "shared.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
				uint id : SV_VertexID;
            };

            struct v2f
            {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0; 
				float2 uv2 : TEXCOORD1;
				uint id : VERTEXID;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Buffer;
			float4 _Buffer_ST;
			float4 _Buffer_TexelSize;
			sampler2D _Particle;
			float4 _Particle_ST;
			float _Size;
			uint _Vertices;


            v2f vert (appdata v)
            {
                v2f o;
				o.position = v.position;
				o.uv = v.uv;
				o.id = v.id;
                return o;
            }

			void MakePixel(inout TriangleStream<v2f> tristream, v2f vert, float4 position) {
				//need it to be visually center for both eyes, so we offset it from it's stereo convergence.
				float3 centerEye = _WorldSpaceCameraPos;
#ifdef USING_STEREO_MATRICES
				centerEye = .5 * (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]);
#endif

				float3x3 cameraMatrix = GenerateLookAtMatrix(position, centerEye);

				//create a pixel at the transform.
				float3 finalPos = position.xyz;
				finalPos -= cameraMatrix._11_21_31*_Size;
				finalPos -= cameraMatrix._12_22_32*_Size;
				vert.position = UnityWorldToClipPos(finalPos);
				vert.uv2[0] = 0;
				vert.uv2[1] = 0;
				tristream.Append(vert);

				finalPos = position.xyz;
				finalPos += cameraMatrix._11_21_31*_Size;
				finalPos -= cameraMatrix._12_22_32*_Size;
				vert.position = UnityWorldToClipPos(finalPos);
				vert.uv2[0] = 1;
				vert.uv2[1] = 0;
				tristream.Append(vert);

				finalPos = position.xyz;
				finalPos -= cameraMatrix._11_21_31*_Size;
				finalPos += cameraMatrix._12_22_32*_Size;
				vert.uv2[0] = 0;
				vert.uv2[1] = 1;
				vert.position = UnityWorldToClipPos(finalPos);
				tristream.Append(vert);

				finalPos = position.xyz;
				finalPos += cameraMatrix._11_21_31*_Size;
				finalPos += cameraMatrix._12_22_32*_Size;
				vert.uv2[0] = 1;
				vert.uv2[1] = 1;
				vert.position = UnityWorldToClipPos(finalPos);
				tristream.Append(vert);

				tristream.RestartStrip();
			}

			float4 getPosition(uint index) {
				float2 uv = IndexToUV(index, _Buffer_TexelSize);
				float4 output = tex2Dlod(_Buffer, float4(uv,0,0));
				return output;
			}

			[instance(20)]
			[maxvertexcount(12)]
			void geom(triangle v2f input[3], inout TriangleStream<v2f> tristream, uint instanceID : SV_GSInstanceID) {
				uint index = 0;
				uint offset = (uint)_Vertices * instanceID;
				float4 position = float4(0, 0, 0, 0);

				index = input[0].id + offset;
				position = getPosition(index);
				input[0].id = index;
				MakePixel(tristream, input[0], position);

				index = input[1].id + offset + 1;
				position = getPosition(index);
				input[1].id = index;
				MakePixel(tristream, input[1], position);

				index = input[2].id + offset + 2;
				position = getPosition(index);
				input[2].id = index;
				MakePixel(tristream, input[2], position);
			}

            float4 frag (v2f i) : SV_Target
            {
				int index = i.id;
				float2 uv = IndexToUV(index, _Buffer_TexelSize);
				uv.y += .5f;
				float4 trajectory = tex2Dlod(_Buffer, float4(uv, 0, 0));

				float4 output = float4(0,0,0,0);
                float4 col = tex2D(_MainTex, i.uv);
				float l = length(trajectory.xyz);
				col = shiftColor(col, l*5);

				float4 col2 = tex2D(_Particle, i.uv2);
				output = col * col2;
                return output;
            }
            ENDCG
        }
    }
}
