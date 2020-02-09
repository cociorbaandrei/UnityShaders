Shader "Skuld/Geometry Fun 5"
{
	Properties {
		_PixelSize("Pixel Size",Range(0,.1)) = .1
		_FallSpeed("Fall Speed",float) = 10
		_NoiseRange("Noise Range",float) = .1
		_NoiseSpeed("Noise Speed",float ) = 2
		_Height("Height",float) = 1.0
		_LightCode("Light Code",float) = 0

		[space]
		_ShadeRange("Shade Range",Range(0,1)) = 1.0
		_ShadeSoftness("Edge Softness", Range(0,1)) = 0
		_ShadePivot("Center",Range(0,1)) = .5
		_ShadeMax("Max Brightness", Range(0,1)) = 1.0
		_ShadeMin("Min Brightness",Range(0,1)) = 0.0

		[space]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"
		[Toggle] _ZWrite("Z-Write",Float) = 1
	}

	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}

        Cull[_CullMode]
		Lighting Off
		SeparateSpecular Off
		ZWrite [_ZWrite]

		Pass {
			Tags { "LightMode" = "ForwardBase"}
			CGPROGRAM
			
			#pragma target 5.0
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#pragma multi_compile

			#include "UnityCG.cginc"


			float _Step;
			float _Spread;
			float _Verticies;
			float _PixelSize;
			float _FallSpeed;
			float _NoiseRange;
			float _NoiseSpeed;
			float _Height;
			float _LightCode;

			//general IO with Semantics
			struct IO
			{
				float4 position : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				uint id : SV_VertexID;
				float4 tangent : TANGENT;
			};

			//processed IO to be used by submethods
			struct PIO
			{
				float4 position : SV_POSITION; //the Position relative to the screen
				float3 normal : NORMAL; //The normal in screen space.
				float2 uv : TEXCOORD0; //uv coordinates
				float4 objectPosition : TEXCOORD1; //The position relative to the mesh origin.
				float3 worldNormal : TEXCOORD2; //The normal in world space.
				float3 worldPosition : TEXCOORD3; //the position relative to world origin.
				float3 viewDirection : TEXCOORD4; //The direction the camera is looking at the mesh.
				float4 tangent : TEXCOORD5;//for bump mapping.
				float3 binormal : TEXCOORD6; //also for bump mapping.
				float4 extras : TEXCOORD8;
			};

			PIO vert ( IO vertex ){
				PIO process;
				process.uv = vertex.uv;//TRANSFORM_TEX( vertex.uv, _MainTex );
				process.normal = normalize( vertex.normal );
				process.objectPosition = vertex.position;
				process.position = UnityObjectToClipPos(vertex.position);
				//reverse the draw position for the screen back to the world position for calculating view Direction.
				process.worldPosition = mul(unity_ObjectToWorld,vertex.position);
				process.worldNormal = normalize( UnityObjectToWorldNormal( process.normal ));
				process.extras.x = vertex.id;

				half4 color;

				return process;
			}

			fixed4 shiftColor( fixed4 inColor, float shift )
			{
				float r = shift * 0.01745329251994329576923690768489;
				float u = cos(r);
				float w = sin(r);
				fixed4 ret;
				ret.r = (.299+.701 * u+.168 * w)*inColor.r
					+ (.587-.587 * u+.330 * w)*inColor.g
					+ (.114-.114 * u-.497 * w)*inColor.b;
				ret.g = (.299-.299 * u-.328 * w)*inColor.r
					+ (.587+.413 * u+.035 * w)*inColor.g
					+ (.114-.114 * u+.292 * w)*inColor.b;
				ret.b = (.299-.3 * u+1.25 * w)*inColor.r
					+ (.587-.588 * u-1.05 * w)*inColor.g
					+ (.114+.886 * u-.203 * w)*inColor.b;	
				ret[3] = inColor[3];
				ret.a = 1;
				return ret;
			}

			float2 rotate2(float2 inCoords, float rot)
			{
				float sinRot;
				float cosRot;
				sincos(rot, sinRot, cosRot);
				return mul(float2x2(cosRot, -sinRot, sinRot, cosRot),inCoords);
			}

			float3x3 GenerateLookAtMatrix(float3 origin, float3 target) {
				float3 zaxis = normalize(origin - target);
				float3 xaxis = normalize(float3(zaxis.z, 0, -zaxis.x));
				float3 yaxis = cross(zaxis, xaxis);
				return transpose(float3x3(xaxis, yaxis, zaxis));
			}

			void MakePixel(inout TriangleStream<PIO> tristream, PIO vert, float3 position){
				//need it to be visually center for both eyes, so we offset it from it's stereo convergence.
				float3 centerEye = _WorldSpaceCameraPos;
				#ifdef USING_STEREO_MATRICES
				centerEye = .5 * (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]);
				#endif

				float3x3 cameraMatrix = GenerateLookAtMatrix(position,centerEye);

				//create a pixel at the transform.
				float3 finalPos = position;
				finalPos -= cameraMatrix._11_21_31*_PixelSize;
				finalPos -= cameraMatrix._12_22_32*_PixelSize;
				vert.position = UnityWorldToClipPos(finalPos);
				tristream.Append(vert);

				finalPos = position;
				finalPos += cameraMatrix._11_21_31*_PixelSize;
				finalPos -= cameraMatrix._12_22_32*_PixelSize;
				vert.position = UnityWorldToClipPos(finalPos);
				tristream.Append(vert);

				finalPos = position;
				finalPos -= cameraMatrix._11_21_31*_PixelSize;
				finalPos += cameraMatrix._12_22_32*_PixelSize;
				vert.position = UnityWorldToClipPos(finalPos);
				tristream.Append(vert);

				finalPos = position;
				finalPos += cameraMatrix._11_21_31*_PixelSize;
				finalPos += cameraMatrix._12_22_32*_PixelSize;
				vert.position = UnityWorldToClipPos(finalPos);
				tristream.Append(vert);

				tristream.RestartStrip();		
			}
			float4 ExplodePosition( inout PIO vert, int i){
				float4 position = mul(unity_ObjectToWorld,vert.objectPosition);
				
				//some adjustments to vert
				int id = vert.extras.x;
				vert.extras.y = i;

				//initial position:
				position.xz = position.xz + ( ( position.xz - unity_ObjectToWorld._14_34 ) * (i/96.0f) );
				position.y = unity_ObjectToWorld._24;

				//y position:
				int offset = id * i * 666 + _Time * _FallSpeed;
				offset = offset % 1000;
				position.y -= ( float(offset) / 1000.0f ) * _Height;

				return position;
			}

			float4 GetLightPosition()
			{
				for(int i = 0; i < 4; i++)
				{
					if(unity_LightColor[i].w != _LightCode)
						continue;
					float4 p;
					p.x = unity_4LightPosX0[i];
					p.y = unity_4LightPosY0[i];
					p.z = unity_4LightPosZ0[i];
					p.w = 5 * rsqrt(unity_4LightAtten0[i]);//range = success
					return p;
				}
				float4 p = float4(0,0,0,0);
				return p;//0 = error
			}

			float3 DodgeLight( float3 position ){
				float3 output = position;

				float4 lightPos = GetLightPosition();
				if (lightPos.w > 0){
					if ( position.y > lightPos.y ){
						float3 diff = output - lightPos.xyz;
						float len = length(diff);
						if ( len < lightPos.w ){
							output += normalize(diff) * (lightPos.w - len);
						}
					} else {
						float2 diff = output.xz - lightPos.xz;
						float len = length(diff);
						if ( len < lightPos.w ){
							output.xz += normalize(diff) * (lightPos.w - len);
						}
					}
				}

				return output;
			}

			void processVert(inout TriangleStream<PIO> tristream, PIO vert, int i ){
				//blow it up.
				float4 position = ExplodePosition(vert, i);

				//applyNoise
				position.xz += rotate2(float2(_NoiseRange,0), _Time * i * _NoiseSpeed);
				
				//DodgeLight
				position.xyz = DodgeLight(position.xyz);

				//turn point into a pixel
				MakePixel(tristream, vert, position);	
			}

			[instance(32)]
			[maxvertexcount(12)]
			void geom (triangle PIO input[3], inout TriangleStream<PIO> tristream, uint instanceID : SV_GSInstanceID){
				float jx,jy,jz;
				int i = 0;
				_FallSpeed*=1000;

				processVert( tristream, input[0], instanceID * 3 );
				processVert( tristream, input[1], instanceID * 3 + 1);
				processVert( tristream, input[2], instanceID * 3 + 2 );
			}

			PIO adjustProcess(PIO process, uint isFrontFace)
			{
				if (!isFrontFace){
					process.normal = -process.normal;
					process.worldNormal = -process.worldNormal;
				}
				//get the camera position to calculate view direction and then get the direction from the camera to the pixel.
				process.viewDirection = normalize(process.worldPosition - _WorldSpaceCameraPos);

				return process;
			}

			fixed4 frag( PIO process, uint isFrontFace : SV_IsFrontFace ) : SV_Target
			{
				//get the uv coordinates and set the base color.
				fixed4 color = fixed4(1,0,0,1);
				process = adjustProcess(process, isFrontFace);
				color = shiftColor(color, process.extras.x * process.extras.y);
				return color;
			}
			ENDCG
		}
	} 
	//FallBack "Diffuse"
}