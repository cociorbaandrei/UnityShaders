Shader "Skuld/Effects/Grab Pass/Glass"
{
	Properties{
		_Depth("Depth", Range(-10,10)) = 1
		_Focal("Focal",Range(-10,10)) = 0
		_Transparency("Transparency",Range(0,1)) = 1
		_Color("Glass Color",color) = (1,1,1,1)
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
			Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct IO
            {
				float2 uv : TEXCOORD0;
				float4 position : SV_POSITION;
				float3 worldNormal : TEXCOORD2;
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
			
			float _Depth;
			float _Focal;
			float4 _Color;
			float _Transparency;
            sampler2D _Background;

            IO vert(APPInput vertex) {
                IO output;
				output.objectPosition = vertex.position;
				output.worldPosition = mul(unity_ObjectToWorld,vertex.position);
				output.uv = vertex.uv;
				output.normal = vertex.normal;
				output.worldNormal = normalize( UnityObjectToWorldNormal( vertex.normal ));

				output.position = UnityObjectToClipPos( vertex.position );

				float4 grabPosition = vertex.position;
				grabPosition = UnityObjectToClipPos(grabPosition);
				output.grabPosition = ComputeGrabScreenPos(grabPosition);

				return output;
            }

            half4 frag(IO vertex) : SV_Target
            {
				float3 viewDirection = normalize(vertex.worldPosition - _WorldSpaceCameraPos);
				float scale = (_Focal-saturate(-dot(viewDirection, vertex.worldNormal))+_Focal) * _Depth;
				float2 uv = vertex.grabPosition.xy / vertex.grabPosition.w;
				float4 offset = ComputeGrabScreenPos(UnityObjectToClipPos(float3(0,0,0)));
				offset.xy /= offset.w;
				uv.xy -= offset.xy;
				uv *= scale;
				uv.xy += offset.xy;
				
				float4 baseColor = tex2D(_Background, uv);
				float ndot = 1-abs(dot(viewDirection, vertex.worldNormal));
				float4 color2 = _Color * ndot * (1-_Transparency);
				baseColor.rgb += color2.rgb;
				
					
                return baseColor;
            }
            ENDCG
        }
    } 
}