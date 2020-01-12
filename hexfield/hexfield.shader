Shader "Skuld/HexField"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color",Color) = (1,1,1,1)
		_Effect ("Show Effect",Range(-.15,.07)) = 0.0
		_Multiplier ("Mulitplier",float) = 1.0
		_MaxSize ("Max Size",Range(0,1)) = 1.0

		[Toggle] _Rotate("Rotate",Float) = 1
		_RotationSpeed ("Rotation Speed",float) = 1.0

		[Toggle] _Fluctuate("Fluctuate Size",Float) = 1
		_FluctuateRange ("Fluctuate Range",float) = 1.0
		_FluctuateSpeed ("Fluctuate Speed",float) = 1.0
		_FluctuatePivot ("Fluctuate Pivot",Range(0,1)) = 1.0

		[space]
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 1                 // "One"
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 0            // "Zero"
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2
		[Toggle] _ZWrite("Z-Write",Float) = 1
	}
	SubShader
	{
		Tags { "RenderType" = "Transparent" "Queue"="Transparent" }
		LOD 10
		
		Cull[_CullMode]
		Lighting Off
		SeparateSpecular Off
		ZWrite [_ZWrite]
		Blend[_SrcBlend][_DstBlend]

		Pass
		{
			Tags { "LightMode" = "ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float _Multiplier;
			float _Effect;
			float _MaxSize;
			bool _Rotate;
			float _RotationSpeed;
			bool _Fluctuate;
			float _FluctuateRange;
			float _FluctuateSpeed;
			float _FluctuatePivot;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 color: COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};
			
			float2 rotate2(float2 inCoords, float rot)
			{
				float sinRot;
				float cosRot;
				sincos(rot, sinRot, cosRot);
				return mul(float2x2(cosRot, -sinRot, sinRot, cosRot),inCoords);
			}

			v2f vert ( appdata v )
			{
				v2f o;
				float hexsize = 1.0 + ( ( _Effect - v.color.x ) * _Multiplier) ;
				hexsize = max(0,hexsize);
				hexsize = min(_MaxSize,hexsize);
				if ( _Fluctuate ){
					hexsize = hexsize * ( (sin(_Time * _FluctuateSpeed) * _FluctuateRange) + _FluctuatePivot );
				}
				o.vertex = v.color + ( ( v.vertex - v.color ) * hexsize );
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				if ( _Rotate ){
					float rotAmt = _Time * _RotationSpeed;
					o.vertex.zy = rotate2(o.vertex.zy,rotAmt);
				}
				o.vertex = UnityObjectToClipPos(o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
