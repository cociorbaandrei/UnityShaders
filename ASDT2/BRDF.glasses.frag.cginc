#include "utils.rotate2.cginc"

float _Tinting;
float _EffectAmount;

float4 applyEffect(inout PIO process, float4 color)
{
	process.worldNormal.xy = rotate2(process.worldNormal.xy, _Time.w);
	float3 effect;
	effect.r = sin(_Time.z + process.uv.x * 10);
	effect.r += cos(_Time.z - process.uv.y * 10);
	effect.g = sin(_Time.z + process.uv.y * 10);
	effect.g += cos(_Time.z - process.uv.x * 10);
	effect.b = cos(_Time.z + process.uv.x * 10 + process.uv.y * 10);
	effect.b += sin(_Time.z - process.uv.x * 10 - process.uv.y * 10);
	effect *= _EffectAmount;
	color.rgb += effect;
	return color;
}


//keep in mind to always add lights. But multiply the sum to the final color. 
//This method applies ambient light from directional and lightprobes.
fixed4 glassesEffect(PIO process, fixed4 color) {
	/************************
	* Brightness / toon edge:
	************************/
#if defined(UNITY_PASS_FORWARDADD)
	//foward add lighting and details from pixel lights.
	float3 direction = normalize(_WorldSpaceLightPos0.xyz - process.worldPosition.xyz);
	float brightness = ToonDot(direction, process.worldNormal);
#else
	//Calculate light probes from foward base.
	float3 ambientDirection = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz; //do not normalize
	float brightness = ToonDot(ambientDirection, process.worldNormal.xyz);
	//needs to also consider L2 harmonics
	/*
	ambientDirection = unity_SHBr.xyz + unity_SHBg.xyz + unity_SHBb.xyz; //do not normalize
	brightness += ToonDot(ambientDirection, process.worldNormal.xyz);
	*/
	//just add the directional light.
	float directBrightness = ToonDot(normalize(_WorldSpaceLightPos0.xyz), process.worldNormal.xyz);
#endif

	UNITY_LIGHT_ATTENUATION(attenuation, process, process.worldPosition);

	/************************
	* Color:
	************************/
#if defined(UNITY_PASS_FORWARDADD)
	//get directional color:
	float3 lightColor = _LightColor0.rgb * brightness * attenuation;
	color.rgb *= lightColor;
	color.a = 0;

	/*************************
	* Glasses Alpha Effect
	*************************/
	float a = (lightColor.r + lightColor.g + lightColor.b) / 3 * brightness*attenuation;
	a = saturate(color.a);
	a *= _Tinting;
	color.a *= a;
#else
	float3 lightColor;

	//ambient color (lightprobes):
	float3 probeColor = max(0, ShadeSH9(float4(0, 0, 0, 1)));
	probeColor *= brightness;
	lightColor = probeColor;

	//direct color
	float3 directColor = max(0, _LightColor0.rgb);
	directColor *= directBrightness;
	if (attenuation > 0) { //this is because sometimes the direct light breaks and doesn't have an attenuation of 1.0 when it should.
		directColor *= attenuation;
	}
	lightColor += directColor;

#ifdef VERTEXLIGHT_ON
	lightColor += max(0, process.vcolor);
#endif
	color.rgb *= lightColor;

	/*************************
	* Glasses Alpha Effect
	*************************/
	float a = (probeColor.r + probeColor.g + probeColor.b) / 3 * brightness;
	a += (directColor.r + directColor.g + directColor.b) / 3 * directBrightness * attenuation;
	a = saturate(color.a);
	a *= _Tinting;
	color.a *= a;
#endif

	return color;
}

fixed4 glassesFrag(PIO process, uint isFrontFace : SV_IsFrontFace) : SV_Target
{
	//get the uv coordinates and set the base color.
	fixed4 color = tex2D(_MainTex, process.uv) * _Color;

	float3 worldNormal = process.worldNormal;
	color = applyEffect(process, color);

	if (_NormalScale > 0) {
		applyNormalMap(process);
	}
	
	#ifdef MODE_TCUT
		clip(color.a - _TCut);
	#endif

	process = adjustProcess(process, isFrontFace);
	color = applyFresnel(process, color);
	color = glassesEffect(process, color);
	process.worldNormal = worldNormal;
	color = applyReflectionProbe(color, process, _Smoothness, _Reflectiveness);

	#if defined(MODE_TCUT) || defined(MODE_OPAQUE)
		color.a = 1;
	#endif
		
	return saturate(color);
}