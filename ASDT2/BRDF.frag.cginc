sampler2D _NormalTex;
sampler2D _NormalTex_ST;
float _NormalScale;
float _Reflectiveness;
float _Smoothness;
int _ReflectType;

float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}

void applyNormalMap(inout PIO o) {
	float3 binormal;

	float3 tangentSpaceNormal = UnpackScaleNormal(tex2D(_NormalTex, o.uv), _NormalScale);

	binormal = CreateBinormal(o.worldNormal, o.worldTangent.xyz, o.worldTangent.w);


	o.worldNormal = normalize(
		tangentSpaceNormal.x * o.worldTangent +
		tangentSpaceNormal.y * binormal +
		tangentSpaceNormal.z * o.worldNormal
	);
}

float3 BoxProjection(
	float3 direction, float3 position,
	float4 cubemapPosition, float3 boxMin, float3 boxMax
) {

	if (cubemapPosition.w > 0) {
		float3 factors =
			((direction > 0 ? boxMax : boxMin) - position) / direction;
		float scalar = min(min(factors.x, factors.y), factors.z);
		direction = direction * scalar + (position - cubemapPosition);
	}

	return direction;
}

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
	if ( smooth > 0.0f) {
		col.rgb = cubemapReflection(col.rgb, i, smooth, ref);
	}
#endif
	return col;
}


fixed4 frag(PIO process, uint isFrontFace : SV_IsFrontFace) : SV_Target
{
	//get the uv coordinates and set the base color.
	fixed4 color = tex2D(_MainTex, process.uv) * _Color;
	float finalAlpha = color.a;

	if (_NormalScale > 0) {
		applyNormalMap(process);
	}
	
	#ifdef MODE_TCUT
		clip(color.a - _TCut);
	#endif

	process = adjustProcess(process, isFrontFace);
	color = applyFresnel(process, color);

	//if the mask is set to glow, apply it after lights, else apply it before lightighting it.
	if (_MaskGlow) {
		color = applyLight(process, color);
		color = applyReflectionProbe(color, process, _Smoothness, _Reflectiveness);
		color = applyMaskLayer(process, color);
	}
	else 
	{
		color = applyMaskLayer(process, color);
		color = applyLight(process, color);
		color = applyReflectionProbe(color, process, _Smoothness, _Reflectiveness);
	}

	color = saturate(color);
	#if defined(MODE_TCUT) || defined(MODE_OPAQUE)
		color.a = 1;
	#else 
		color.a = finalAlpha;
	#endif
	return color;
}