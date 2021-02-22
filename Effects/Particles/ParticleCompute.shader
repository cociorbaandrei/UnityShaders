/*
data should be:
[0][0] Position of Vertex 1
[0][512] Direction/Velocity of Vertex 1
*/
Shader "Skuld/Effects/GPU Particles/Compute"
{
    Properties
    {
		[hdr]_MainTex ("Default Shape", 2D) = "white" {}
		_Scale("Scale of Default Shape",float) = 100
		[hdr]_Buffer("Computer Input Texture:",2D) = "Gray" {}
		_Reset("reset",int) = 0
		_Vertices("Number of Vertices in Default Shape", int) = 0
		_Speed("Speed of Simulation",float) = .1
		_Range("Range of gravity",float) = 10
		_Strength("Strength of gravity",float) = 1
		_Decelleration("Rate of Deceleration",float ) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
		cull Back

        Pass
        {
			Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
			#pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile _ VERTEXLIGHT_ON

            #include "UnityCG.cginc"
			#include "shared.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _MainTex_TexelSize;
			float _Scale;
			sampler2D _Buffer;
			float4 _Buffer_ST;
			float4 _Buffer_TexelSize;
			int _Reset;
			uint _Vertices;
			float _Speed;
			float _Range;
			float _Strength;
			float _Decelleration;

			//for global use
			float speed;

            v2f vert (appdata v)
            {
                v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				if (any(_ScreenParams.xy != abs(_Buffer_TexelSize.zw)))
				{
					o.vertex = 0;
				}
				o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

			float4 AddInfluence(float4 influence,float4 position,float4 trajectory) 
			{
				float3 gravity = normalize(influence.xyz - position.xyz);
				float G = length(gravity);
				G = _Range - G;
				G = max(0, G);
				G *= G;
				float weight = G * _Strength * speed;
				gravity *= weight;
				
				trajectory.xyz += gravity;
				
				//velocity for the output color
				trajectory.w = G;

				return trajectory;
			}

			float4 CalculateTrajectory(v2f i) {
				float4 position = tex2D(_Buffer, float2(i.uv.x, i.uv.y - .5f));
				float4 trajectory = tex2D(_Buffer, i.uv);
				float3 gravity = float4(normalize(float3(0, 0, 0) - position.xyz), 0);

				//determine amount to slow by (Distance from a gravitational source).
				float4 defaultPos = unity_ObjectToWorld._14_24_34_44;
				defaultPos.y+=1;
				trajectory = AddInfluence(defaultPos, position, trajectory);
#ifdef VERTEXLIGHT_ON
				for (int i = 0; i < 4; i++)
				{
					if (unity_LightColor[i].w > 0) {
						float4 lightPos = float4(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i], 1);						
						trajectory = AddInfluence(lightPos, position, trajectory);
					}
				}
#endif
				//Decelleration
				trajectory.xyz *= 1 - (_Decelleration * speed);
				return trajectory;
			}

			float4 frag (v2f i) : SV_Target
            {
				float4 col = float4(0,0,0,1);
				UNITY_BRANCH
				if ( _Reset > 0 ){
					//set the initial velocity
					UNITY_BRANCH
					if (i.uv.y > .5f) {
						col = float4(10, 0, 0, .1f);
						col.xy = rotate2(col.xy, (_Time.z * 10) + ((i.uv.y * 10) + i.uv.x) * 1666);
						col.yz = rotate2(col.yz, (_Time.z * 10) + ((i.uv.y * 10) - i.uv.x) * 1666);
					}
					else {
						uint index = UVToIndex(i.uv, _Buffer_TexelSize);
						index = index % _Vertices;
						float2 uv = IndexToUV(index, _MainTex_TexelSize);
						float4 position = tex2D(_MainTex, uv );
						position *= _Scale;
						position.z += _Scale/200.0f;
						position = mul(unity_ObjectToWorld, position);
						col = position;
					}
				}
				else {
					//compute direction/velocity change
					UNITY_BRANCH
					speed = _Speed * (unity_DeltaTime.x / 100.0f);
					if (i.uv.y > .5f) {
						col = CalculateTrajectory(i);
					}
					//compute position change.
					else {
						float4 position = tex2D(_Buffer, i.uv);
						float4 trajectory = tex2D(_Buffer, float2(i.uv.x, i.uv.y + .5f));
						position.xyz += trajectory.xyz * speed;
						col = position;
					}
				}

                return col;
            }
            ENDCG
        }
    }
}
