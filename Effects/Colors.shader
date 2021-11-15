Shader "Skuld/Colors"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile

            #include "UnityCG.cginc"

            float3 shiftColor(float3 inColor, float shift)
            {
                float r = shift * 0.01745329251994329576923690768489;
                float u = cos(r);
                float w = sin(r);
                float3 ret;
                ret.r = (.299 + .701 * u + .168 * w)*inColor.r
                    + (.587 - .587 * u + .330 * w)*inColor.g
                    + (.114 - .114 * u - .497 * w)*inColor.b;
                ret.g = (.299 - .299 * u - .328 * w)*inColor.r
                    + (.587 + .413 * u + .035 * w)*inColor.g
                    + (.114 - .114 * u + .292 * w)*inColor.b;
                ret.b = (.299 - .3 * u + 1.25 * w)*inColor.r
                    + (.587 - .588 * u - 1.05 * w)*inColor.g
                    + (.114 + .886 * u - .203 * w)*inColor.b;
                return ret;
            }

            float4 HSV(float4 color, float hue, float sat, float val) {
                color.rgb = shiftColor(color.rgb, hue);
                float avg = (color.r + color.g + color.b) / 3.0f;

                color.rgb = lerp(avg,color.rgb, sat+1);
                color.rgb += val;
                return color;
            }

            float4 Contrast(float4 color, float con) {
                color.rgb -= .5f;
                color.rgb *= con;
                color.rgb += .5f;
                return color;
            }

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = float4(1,0,0,0);
                float t = _Time.x;
                col.rgb = shiftColor(col.rgb,cos(t + (i.uv.x))*75);
                col.rgb = shiftColor(col.rgb,cos(t*1.33 + (i.uv.y))*360);
                col.rgb = shiftColor(col.rgb,sin(t*1.21 - (i.uv.x))*99);
                col.rgb = shiftColor(col.rgb,cos(t*1.94 - (i.uv.y))*280);
                float n1 = cos(i.uv.x*10+t)/2-.25f;
                float n2 = sin(i.uv.y*10+t*1.11)/2;
                float n3 = cos(i.uv.x*10-t*2.11)/2+.25f;
                float n4 = sin(i.uv.y*10-t*3)*5-.5f;
                col.rgb*= (n1+n2+n3+n4)/2;
                float n5 = sin(i.uv.y*100-t*30)*5-5;
                float n6 = sin(i.uv.x*100-t*40)*5-3;
                float n7 = sin(i.uv.y*100+t*10)*5-5;
                float n8 = sin(i.uv.x*100+t*20)*5-4;
                col.rgb+=max(n5*n6+n7*n8,0)/100;
                return col;
            }
            ENDCG
        }
    }
}
