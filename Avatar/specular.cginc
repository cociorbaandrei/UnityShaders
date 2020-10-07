float4 _SpecularColor;
float4 _FresnelColor;
float _FresnelRetract;
float _SpecularSize;
float _SpecularReflection;

float4 applyFresnel(PIO process, float4 inColor) {
#if defined(UNITY_PASS_FORWARDADD)
	//foward add lighting and details from pixel lights.
	float3 direction = normalize(_WorldSpaceLightPos0.xyz - process.worldPosition.xyz);
	float alpha = (dot(direction, process.worldNormal) + 1.0f) / 2.0f;
	alpha = max(0, alpha);
#else
	//Calculate light probes from foward base.
	float3 ambientDirection = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz; //do not normalize
	float alpha = (dot(ambientDirection, process.worldNormal.xyz) + 1.0f) / 2.0f;

	float directAlpha = (dot(normalize(_WorldSpaceLightPos0.xyz), process.worldNormal.xyz) + 1.0f) / 2.0f;
	alpha = max(0, alpha) + max(0, directAlpha);
#endif

	float val = saturate(-dot(process.viewDirection, process.worldNormal));
	float rim = 1 - val * _FresnelRetract;
	rim = max(0, rim);
	rim *= _FresnelColor.a * alpha * _Specular;
	float orim = 1 - rim;
	float4 color;
	inColor.rgb = (_FresnelColor * rim) + (inColor * orim);
	return inColor;
}

float SpecDot(float3 lightDir, float3 reflectDir,float attenuation) {
	float res = dot(lightDir, reflectDir);
	res -= 1 - _SpecularSize;
	res *= 1 / _SpecularSize;
	res = min(_ShadeMax, res);
	res = max(0, res);
	res *= res; //should behave similar to light attenuation. So make it quadratic.
	res *= _Specular;//apply effect amount.
	res *= attenuation;
	return res;
}

float4 applySpecular(PIO o, float4 color) 
{
	UNITY_LIGHT_ATTENUATION(attenuation, o, o.worldPosition);
	float3 reflectDir = reflect(o.viewDirection, o.worldNormal);
	float3 direction = float3(0, 0, 0);

	//set the starting color from reflection
	Unity_GlossyEnvironmentData envData;
	envData.roughness = 0;
	envData.reflUVW = normalize(reflectDir);

	float3 refColor = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
	float spec0interpolationStrength = unity_SpecCube0_BoxMin.w;
	float3 result = _SpecularColor;

	switch (_ReflectType) {
		default:
		case 0:
			result = lerp(result, refColor, _SpecularReflection);
			break;
		case 1:
			result = result * refColor * _SpecularReflection;
			break;
		case 2:
			result = result + (refColor * _SpecularReflection);
			break;
	}
	
	#if defined(UNITY_PASS_FORWARDADD)
		direction = -normalize(o.worldPosition.xyz - _WorldSpaceLightPos0.xyz);
	#else
		direction = normalize(_WorldSpaceLightPos0.xyz);
	#endif

	//apply light colors
	float d = SpecDot(direction, normalize(reflectDir), attenuation);
	float3 lightColor = _LightColor0.rgb * d;
	#if defined(UNITY_PASS_FORWARDBASE)
		float3 ambientDirection = normalize(unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz);
		d = SpecDot(ambientDirection, normalize(reflectDir), attenuation);
		lightColor += max(0,ShadeSH9(float4(0, 0, 0, 1))) * d;
	#endif

	//add the color of the light causing spec.
	result *= lightColor;

	color.rgb += result;

	return color;
}