Shader "Skuld/Deprecated/Basics/Unlit Opaque"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color",Color) = (1,1,1,1)
		
		[space]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"
		[Toggle] _ZWrite("Z-Write",Float) = 1
	}
    SubShader
    {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		LOD 10

        Cull[_CullMode]
		Lighting Off
		SeparateSpecular Off
		ZWrite [_ZWrite]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile

            #include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
				col *= _Color;
                return col;
            }
            ENDCG
        }
    }
}
