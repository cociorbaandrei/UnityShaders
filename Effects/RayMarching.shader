Shader "Skuld/Effects/Ray Marching Fun (Infinisphere)"
{
	Properties {
		_MainTex("Noise Texture", 2D) = "gray" {}
		_AmbOcc ("Ambient Occlusion", Range(0, 5)) = 1.0
		_Steps("Iterations",Range(0,1000)) = 100
		_Size("Grid Size",Range(0,10) ) = 1
		_Radius("Sphere Radius",Range(0,1) ) = 0.1
		_MinDist("Minimum Distance",Range(0,1)) = .01
		_TCut("Transparent Cutout",Range(0,1)) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 1                 // "One"
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 0            // "Zero"
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend Operation", Float) = 0                 // "Add"
	}

	SubShader {
		Tags { "RenderType"="TransparentCutout" "Queue"="Transparent-1" }
		LOD 100
		Cull front
        Blend[_SrcBlend][_DstBlend]
        BlendOp[_BlendOp]
		

		pass {	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float4 position : SV_POSITION;
			};

			struct appdata
			{
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct fragOutput
			{
				half4 color : SV_TARGET;
				float depth : SV_DEPTH;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Radius;
			float _Steps;
			float _Size;
			float _MinDist;
			float _AmbOcc;
			fixed4 noColor;

			v2f vert ( appdata v) {
				v2f o;
				o.position = UnityObjectToClipPos(v.position);
				o.worldPos = mul(unity_ObjectToWorld, v.position).xyz;
				o.uv = TRANSFORM_TEX(v.uv,_MainTex);
				return o;
			}

			float sphereDistance ( float3 position, float3 center )
			{
				return length(position - center) - _Radius;
			}

			float DE(float3 inPosition, v2f input, float i)
			{
				float3 position = frac(inPosition / _Size) * _Size;
				float3 center;
				center.z = _Size / 2;
				center.x = _Size / 2;
				center.y = _Size / 2;
				center.z = _Size / 2 + sin(_Time * 20 + inPosition.x * 10) / 50;
				center.x = _Size / 2 + sin(_Time * 20 + inPosition.z * 10) / 50;
				center.y = _Size / 2 + cos(_Time * 20 + inPosition.y * 10) / 50;

				float distance = sphereDistance(position, center);
				return distance;
			}
			/*
			fixed4 shadeColor( fixed4 inColor, float shadeAmt ){
				//float shadeAmt = abs(distance) * 5000;
				shadeAmt = abs(shadeAmt);
				if (shadeAmt > 1) shadeAmt = 1;
				if (shadeAmt < 0) shadeAmt = 0;
				fixed4 color = inColor - (inColor * shadeAmt);
				color[3] = 1;
				return color;
			}
			*/
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
				//ret.a = min(1.0, 1.5 * saturate(pow(1- shift / 10 / _Steps, _AmbOcc)));
				return ret;
			}

			fragOutput frag(v2f input )
			{
				fragOutput output;
				noColor = fixed4(0.0, 0.0, 0.0, 0.0);

				float2 uv = input.worldPos.xz / 10.0f;
				uv[0] = uv[0]+sin(_Time*40);
				if (uv[0] < 0.0) uv[0]++;
				if (uv[0] > 1.0) uv[0]--;
				uv[1] = uv[1]+cos(_Time*40);
				if (uv[1] < 0.0) uv[1]++;
				if (uv[1] > 1.0) uv[1]--;
				
				
				float3 direction = normalize( input.worldPos - _WorldSpaceCameraPos.xyz );
				float s = abs(unity_ObjectToWorld._m00/3);
				fixed4 color = tex2D(_MainTex, uv);
				float d = length(unity_ObjectToWorld._14_24_34_44 - _WorldSpaceCameraPos.xyz);
				float3 test = _WorldSpaceCameraPos.xyz + d * direction;
				if (length(unity_ObjectToWorld._14_24_34_44 - test) > s) {
					output.color = noColor;
					output.depth = 0;
					return output;
				}
				float3 position = _WorldSpaceCameraPos.xyz;

				for (int i = 0; i < _Steps; i++)
				{
					if (length(unity_ObjectToWorld._m30_m31_m32 - position) > s) {
						position += direction * _Size;
					}
					else {
						float distance = DE(position, input, i);
						if (distance <= 0.0001) {
							output.color = shiftColor(color * saturate(pow(1 - i / _Steps, _AmbOcc)), i * 10 + input.worldPos.y * 100);
							float4 clipPos = UnityWorldToClipPos(position);
							output.depth = clipPos.z / clipPos.w;
							//output.color = shadeColor( output.color, (clipPos.z * i) / clipPos.w  );
							return output;
						}
						position += direction * distance;
					}
				}
				output.color = noColor;
				output.depth = 0;
				return output;
			}
			/*
			 if !defined(UNITY_REVERSED_Z)
			zDepth = zDepth * 0.5 + 0.5;
			 endif
			output.depth = zDepth;
			*/
			/*
			//recheck these 3, last is fine.
			xdir = unity_ObjectToWorld._m00_m10_m20; //right
			zdir = unity_ObjectToWorld._m01_m11_m21; //top
			ydir = unity_ObjectToWorld._m02_m12_m22; //forward
			center = unity_ObjectToWorld._m03_m13_m23; //center
			*/
			ENDCG
		}
	}
}