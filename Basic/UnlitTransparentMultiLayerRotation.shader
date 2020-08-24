Shader "Skuld/Basics/Unlit Transparent Multi Layer Rotate"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_SubTex ("Texture", 2D) = "white" {}
		_Color ("Color",Color) = (1,1,1,1)
		_RotSpeed ("Rotation Speed", float) = 10
		
		[space]
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 1                 // "One"
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 0            // "Zero"
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"
		[Toggle] _ZWrite("Z-Write",Float) = 1
	}
    SubShader
    {
		Tags { "RenderType"="Transparent" "Queue"="Transparent"}
		LOD 10

		Blend[_SrcBlend][_DstBlend]
        //BlendOp[_BlendOp]
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
			sampler2D _SubTex;
			float4 _SubTex_ST;
			fixed4 _Color;
			float _RotSpeed;

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

			float2 rotate2(float2 inCoords, float rot)
			{
				float sinRot;
				float cosRot;
				sincos(rot, sinRot, cosRot);
				return mul(float2x2(cosRot, -sinRot, sinRot, cosRot),inCoords);
			}

            fixed4 frag (v2f i) : SV_Target
            {
				float rotAmt = _Time * _RotSpeed;
                // sample the texture
				float2 uv1 = rotate2(i.uv-.5f,rotAmt) + .5f;
				float2 uv2 = rotate2(i.uv-.5f,-rotAmt) + .5f;
                fixed4 col1 = tex2D(_MainTex, uv1);
				col1.rgb += cos(rotAmt*2);
				fixed4 col2 = tex2D(_SubTex, uv2);
				col2.g *= sin(rotAmt)/2 + .5f;
				fixed4 col;
				col.rgb = col2.rgb * col2.a + col1.rgb*col1.a;
				col.a = saturate(col1.a + col2.a);
				col *= _Color;
                return col;
            }
            ENDCG
        }
    }
}
