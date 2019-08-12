﻿/*
This is a basic surface shader version of ASDT, 
it is meant to be able to run on anything unity translates it for.
Namely the Occulus Quest, Android and other lower end machines.
For something that is more scalable and runs better on higher end machines
use ASDT2.
*/
Shader "Skuld/Advanced Shading and Dual Texture Light"
{
	Properties {
		[space]
		_Spread("Edge Softness", Range(0,1)) = 0
		_Pivot("Shade Center",Range(0,1)) = .5
		_SRange("Shade Range",Range(0,1)) = 1.0
		_Max("Max Brightness", Range(0,1)) = 1.0
		_Min("Min Brightness",Range(0,1)) = 0.0

		[space]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 1                 // "One"
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 0            // "Zero"
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend Operation", Float) = 0                 // "Add"
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 2                     // "Back"
		[Toggle] _ZWrite("Z-Write",Float) = 1

		[space]
		_MainTex("Base Layer", 2D) = "gray" {}
		_TCut("Transparent Cutout",Range(0,1)) = 1
		_Color("Fresnel Color", Color)=(1, 1, 1, 1)
		_RimValue("Fresnel Retract", Range(0,10)) = 0.5

		[space]
		_SubTex("Mask Layer", 2D) = "black" {}
		[Toggle] _TGlow("Mask Glow", Float) = 0
		_TGlowColor("Glow Color", Color)=(1, 1, 1, 1)
		[Toggle] _TRainbow("Rainbow Effect", Float) = 0
		_TSpeed("Glow Speed",Range(0,10)) = 1
		_TSharpness("Glow Sharpness",Range(1,200)) = 1.0
	}

	SubShader {
		Tags { "RenderType"="TransparentCutout" "Queue"="Geometry+1"}

		//RenderType[_Mode]
        Blend[_SrcBlend][_DstBlend]
        BlendOp[_BlendOp]
        Cull[_CullMode]
		AlphaTest Greater[_TCut] //cut amount
		Lighting Off
		SeparateSpecular Off
		ZWrite [_ZWrite]

		CGPROGRAM
		#include "UnityLightingCommon.cginc"
			
		/*this is how you control the lighting and alpha. tags does nothing. */
		//Alpha cutout:
		#pragma surface surf Flat novertexlights alphatest:_Cutoff fullforwardshadows addshadow
		//Pure Alpha:
		//#pragma surface surf Flat alphatest:_Cutoff
		//Opaque:
		//#pragma surface surf Flat
		#pragma target 5.0

		struct Input
		{
			float2 uv_MainTex;
			float3 viewDir;
			float3 worldNormal;
			float3 worldPos;
			float4 screenPos;
		};

		sampler2D _MainTex;
		float4 _Color;
		float _TCut;
		float _Spread;
		float _Pivot;
		float _Max;
		float _Min;
		float _SRange;
		float _RimValue;
		
		sampler2D _SubTex;
		fixed _TGlow;
		float _TSpeed;
		float4 _TGlowColor;
		float _TSharpness;
		fixed _TRainbow;
		float3 rColor;
		int rState = 0;
		Input IN2;
						
		void applyTattoo(inout SurfaceOutput o)
		{
			float2 uv = IN2.uv_MainTex;
			float4 t = tex2D(_SubTex, uv);
			float ad = 1 - t.a;
			if ( _TGlow ){
				int time = ( _Time * (_TSpeed*1000) );
				float gp = ( time % 120 ) / 100.0f - .1;

				float igv = (gp - uv[1]);
				if (igv < 0 ) igv = 0 - igv;
				igv = igv * _TSharpness;
				if (igv > 1 ) igv = 1;
				if (igv < 0 ) igv = 0;
				float gv = 1-igv;
				if (_TRainbow){
					int rt = _Time * 7000;
					float tc = ( rt ) % 300 / 100.0f;
					rColor[0] = 1.0 - tc;
					rColor[1] = tc;
					rColor[2] = tc - 1.0;
					if (rColor[0] < -1.0) rColor[0] = 0 - rColor[0] - 1;
					if (rColor[1] > 1.0) rColor[1] = 1.0 - ( rColor[1] - 1.0 );
					if (rColor[2] > 1.0) rColor[2] = 1.0 - ( rColor[2] - 1.0 );
					if (rColor[0] < 0.0) rColor[0] = 0;
					if (rColor[1] < 0.0) rColor[1] = 0;
					if (rColor[2] < 0.0) rColor[2] = 0;
					_TGlowColor.r = rColor[0];
					_TGlowColor.g = rColor[1];
					_TGlowColor.b = rColor[2];
				}
				t.rgb = (t.rgb * igv) + (_TGlowColor.rgb * gv);
			}
			o.Albedo = ( o.Albedo * ad ) + (t * t.a);
			o.Specular = (1.0,1.0,1.0,1.0);
		}

		void surf(Input IN, inout SurfaceOutput o)
		{
			IN2 = IN;

			float2 uv = IN.uv_MainTex;
			float4 c = tex2D(_MainTex, uv);

			//Fresnel
			float3 normal = normalize(IN.worldNormal);
			float3 dir = normalize(IN.viewDir);
			float val = abs(dot(dir, normal));
			float rim = 1 - val * _RimValue;
			if (rim < 0.0 ) rim = 0.0;
			rim *= _Color.a;
			float orim = 1 - rim;
			o.Albedo = (_Color * rim) + (c * orim);

			//make sure the end alpha is alpha.
			if (c.a < _TCut) discard;
			o.Alpha = c.a;
		}
		
		half4 LightingFlat_GI( inout SurfaceOutput s, UnityGIInput data, inout UnityGI gi )
		{
			return 1.0;
		}

		fixed4 LightingFlat(SurfaceOutput o, fixed3 lightDir, fixed atten) {
			//if it's not meant to glow, calculate before shading.
			if (!_TGlow) {
				applyTattoo( o );
			}

			//the allowed attenuation range
			float sRange = _SRange * atten;
			
			//the basic light value based on distance, normal and direction.
			//get the ambient direction & light amount
			float4 ambientDir = float4(Unity_SafeNormalize(unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz), 1.0);
			float ambValue = dot(o.Normal, ambientDir);
			//get the non ambient amount
			half nonAmbValue = dot (o.Normal, lightDir);
			//take whichever produces more.
			half value = max(ambValue,nonAmbValue);
			

			//spread causes the hard animation edge, pivot is where the edge occurs
			if (_Spread > 0){
				value -= _Pivot;				//spread the value from the pivot
				value = value * ( 1 /_Spread );	//spread them to create a hard edge
				value += _Pivot;				//move the value back to the pivot
			} else { //if the spread is 0, so we don't divide by 0, let's just split compare.
				if (value < _Pivot ) value = 0;
				if (value >= _Pivot ) value = 1;
			}
			//before applying the attenuation, we need to clamp it from 0-1
			if (value < 0) value = 0;
			if (value > 1) value = 1;

			//apply the attenuation
			value = value * sRange;

			//raise by allowed range
			value += (atten-sRange);

			//constrain to visual min/max 
			//This is for completely black or fully bright areas.
			value = saturate(value);
			
			half3 ambColor = ShadeSH9(ambientDir);
			half3 lightColor = ambColor + _LightColor0.rgb;
			lightColor = min(lightColor, normalize(lightColor));
			o.Albedo = o.Albedo * value * lightColor;

			//trigger another pass to handle 2nd layer, if marked to glow.
			if (_TGlow) {
				applyTattoo( o );
			}
			
			return fixed4(o.Albedo, o.Alpha);
		}
		ENDCG
	} 
}