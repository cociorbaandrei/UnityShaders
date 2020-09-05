#pragma once
float3 cubemapReflection(float3 color, PIO o, float smooth, float ref)
{
	float3 reflectDir = reflect(-o.viewDirection, o.worldNormal);
	Unity_GlossyEnvironmentData envData;
	envData.roughness = 1 - smooth;
	envData.reflUVW = normalize(reflectDir);

	float3 result = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
	float spec0interpolationStrength = unity_SpecCube0_BoxMin.w;

	UNITY_BRANCH
		if (spec0interpolationStrength < 0.999)
		{
			envData.reflUVW = BoxProjection(reflectDir, o.worldPosition,
				unity_SpecCube1_ProbePosition,
				unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
			result = lerp(Unity_GlossyEnvironment(
				UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
				unity_SpecCube1_HDR, envData
			), result, spec0interpolationStrength);
		}

	//apply the amount the reflective surface is allowed to affect:
	result *= ref;

	switch (_ReflectType) {
	default:
	case 0:
		result = lerp(color, result, smooth);
		break;
	case 1:
		result = result * color;
		break;
	case 2:
		result = result + color;
		break;
	}
	return result;
}

float4 applyReflectionProbe(float4 col, inout PIO i, float smooth, float ref) {
#ifndef UNITY_PASS_FORWARDADD
	//Reflects 2nd to last
	if (smooth > 0.0f) {
		col.rgb = cubemapReflection(col.rgb, i, smooth, ref);
	}
#endif
	return col;
}
