#pragma once
//keep in mind to always add lights. But multiply the sum to the final color. 
//This method applies ambient light from directional and lightprobes.
float4 applyLight(PIO process, float4 color) {
	/************************
	* Brightness / toon edge:
	************************/
	//I supply the attenuation to the ToonDot, to be the constant muliplier with dotl calculation, 
	//Before the toon ramp is calculated.
	UNITY_LIGHT_ATTENUATION(attenuation, process, process.worldPosition);
#if defined(UNITY_PASS_FORWARDADD)
	//foward add lighting and details from pixel lights.
	float3 direction = normalize(_WorldSpaceLightPos0.xyz - process.worldPosition.xyz);
	float brightness = ToonDot(direction, process.worldNormal, attenuation);
#else
	//Calculate light probes from foward base.
	float3 ambientDirection = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz; //do not normalize
	float brightness = ToonDot(ambientDirection, process.worldNormal.xyz, 1);
	//just add the directional light.
	float directBrightness = ToonDot(normalize(_WorldSpaceLightPos0.xyz), process.worldNormal.xyz, attenuation);
#endif

	/************************
	* Color:
	************************/
#if defined(UNITY_PASS_FORWARDADD)
	//get directional color:
	float3 lightColor = _LightColor0.rgb * brightness * attenuation;
#else
	float3 lightColor;

	//ambient color (lightprobes):
	if (!isnan(brightness)) {
		float3 probeColor = max( 0, ShadeSH9(float4(0, 0, 0, 1) ) );
		probeColor *= brightness;
		lightColor = probeColor;
	}
	else {
		lightColor = 1;
	}

	//direct color
	if (!isnan(directBrightness)) { //this is because sometimes the direct light breaks and doesn't have an attenuation of 1.0 when it should.
		float3 directColor = max( 0, _LightColor0.rgb);
		directColor *= directBrightness;
		lightColor += directColor;
	}

	#ifdef VERTEXLIGHT_ON
		lightColor += max( 0, process.vcolor);
	#endif
#endif
		lightColor *= ( 1 - _Height);
	//Finally apply shadows and final light color
	color.rgb *= lightColor;

	return color;
}
