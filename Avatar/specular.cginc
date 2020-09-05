float4 _SpecularColor;
float4 _FresnelColor;
float _FresnelRetract;
float _SpecularSize;

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

float4 applySpecular(PIO o, float4 color) 
{
	UNITY_LIGHT_ATTENUATION(attenuation, o, o.worldPosition);
	float3 reflectDir = reflect(-o.viewDirection, o.worldNormal);
	Unity_GlossyEnvironmentData envData;
	envData.roughness = 0;
	envData.reflUVW = normalize(reflectDir);

	float3 result = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
	float spec0interpolationStrength = unity_SpecCube0_BoxMin.w;

	result = lerp(_SpecularColor.rgb, result, _Reflectiveness );
	float3 direction = float3(0, 0, 0);
	#if defined(UNITY_PASS_FORWARDADD)
		direction = -normalize(o.worldPosition.xyz - _WorldSpaceLightPos0.xyz);
	#else
		direction = normalize(_WorldSpaceLightPos0.xyz);
	#endif
	float d = dot(direction, o.worldNormal.xyz);
	d -=1 - _SpecularSize;
	d *= 1 / _SpecularSize;
	d *= 2;
	d = max(0,d);
	d *= attenuation;
	d *= _Specular;
	result *= _LightColor0.rgb;
	color.rgb = lerp(color.rgb, result, d);
	

	return color;
}