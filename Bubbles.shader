Shader "Skuld/Bubbles"
{
	Properties{

	}
	SubShader {
        // Draw ourselves after all opaque geometry
        Tags { "Queue" = "Transparent" }

        // Grab the screen behind the object into _BackgroundTexture
        GrabPass
        {
            "_Background"
        }
		Pass
        {
            CGPROGRAM
            #pragma vertex vert
			#pragma geometry geom
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct IO
            {
				float2 uv : TEXCOORD0;
				float4 position : SV_POSITION;
                float4 grabPosition : TEXCOORD3;
				float4 objectPosition: TEXCOORD4;
				float4 worldPosition : TEXCOORD5;
				float3 normal : NORMAL;
            };

			struct APPInput
			{
				float4 position : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};
			
            sampler2D _Background;

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

            IO vert(APPInput vertex) {
                IO output;
				output.objectPosition = vertex.position;
                output.position = vertex.position;

				float4 grabPosition = vertex.position;
				output.normal = vertex.normal;
				output.worldPosition = mul(unity_ObjectToWorld,vertex.position);
				output.uv = vertex.uv;
                return output;
            }

            half4 frag(IO vertex) : SV_Target
            {
				float3 viewDirection = normalize(vertex.worldPosition - _WorldSpaceCameraPos);
                half4 baseColor = tex2Dproj(_Background, vertex.grabPosition);
				float4 bubbleColor = float4(1, .8, .8, 1);
				float offset = sin(_Time*5)+1;
				float shift = dot( (vertex.uv.x-offset), (vertex.uv.y-offset)) * 2880 + (_Time*1000);
				bubbleColor = shiftColor(bubbleColor,shift);
				
				//apply bubble edge:
				float value = -dot(viewDirection, vertex.normal)*2 + .5; 
				bubbleColor *= value;

				baseColor.rgb*=bubbleColor.rgb;
                return baseColor;
            }
			[maxvertexcount(3)]

			void geom (triangle IO tri[3], inout TriangleStream<IO> triangles ){
				for ( int i = 0; i < 3; i++ ){
					IO vertex = tri[i];
					float wobbleX = sin(_Time*26) / 15 + 1;
					float wobbleY = cos(_Time*42) / 17 + 1;
					float wobbleZ = sin(_Time*27) / 11 + 1;
					float3 position = tri[i].position;
					position.x *= wobbleX;
					position.y *= wobbleY;
					position.z *= wobbleZ;
					vertex.position = UnityObjectToClipPos( position );

					float4 grabPosition = tri[i].position;
					grabPosition /= 1.5;
					grabPosition = UnityObjectToClipPos(grabPosition);
					vertex.grabPosition = ComputeGrabScreenPos(grabPosition);
					triangles.Append(vertex);
				}
			}
            ENDCG
        }
    } 
}