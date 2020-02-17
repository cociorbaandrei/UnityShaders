Shader "Skuld/Fuckingfuckityfuck"
{
	Properties {
		_MainTex("Base (RGB)", 2D) = "gray" {}
	}
	SubShader
	{

		Tags { "Queue"="Geometry+10" }
		Zwrite On
		ColorMask 0


		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0

			sampler2D _MainTex;
			struct v2f
			{
				float4 position : SV_POSITION;
			};

			struct appdata
			{
				float4 position : POSITION;
			};
			
			v2f vert ( appdata v) {
				v2f o;
				o.position = UnityObjectToClipPos(v.position);
				return o;
			}

			fixed4 frag() : SV_Target{
				_MainTex[0]++;
				return fixed4(1,1,1,1);
			}
			ENDCG
		}
	}
}
