Shader "Skuld/Effects/Grab Pass/Test"
{
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
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f
            {
                float4 grabPos : TEXCOORD0;
                float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float4 worldPosition : TEXCOORD5; 
            };

            v2f vert(appdata_base v) {
                v2f o;
				float4 grabPos = v.vertex;
                o.pos = UnityObjectToClipPos(v.vertex);

				grabPos.x /= 2;
				grabPos.y /= 2;
				grabPos = UnityObjectToClipPos(grabPos);
				o.grabPos = ComputeGrabScreenPos(grabPos);
				o.normal = v.normal;
				o.worldPosition = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            sampler2D _Background;

            half4 frag(v2f i) : SV_Target
            {
				float3 viewDirection = normalize(i.worldPosition - _WorldSpaceCameraPos);
				float value = abs(dot(viewDirection,i.normal)); 
                half4 bgcolor = tex2Dproj(_Background, i.grabPos);
				value += .5;
				bgcolor.rgb *= (value * 1.5);
                return bgcolor;
            }
            ENDCG
        }
    } 
}