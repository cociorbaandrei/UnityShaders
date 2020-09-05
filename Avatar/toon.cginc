#pragma once
//shading properties
float _ShadeRange;
float _ShadeSoftness;
float _ShadeMax;
float _ShadeMin;
float _ShadePivot;

float ToonDot(float3 direction, float3 normal, float attenuation)
{
	//The inputs on this should not be normalize, because for something with
	//spherical harmonics, it will be destroyed. If need be, normalize
	//before passing to this method.
	//dotal can be from -1 to 1, so do this math to bring it to a range of 0 to 1
	float d = (dot(direction, normal) + 1) / 2;
	d *= attenuation;
	float m = (dot(direction, normalize(direction)) + 1) / 2;
	float e = _ShadePivot - d;
	if (_ShadeSoftness > 0) {
		e *= 1 / _ShadeSoftness;
		e = saturate(e);
	}
	else {
		e = saturate(floor(e + 1));
	}
#if defined(UNITY_PASS_FORWARDADD)
	float brightness = 1 - (e * _ShadeRange);
#else
	float brightness = m - (e * _ShadeRange);
#endif

	brightness = max(_ShadeMin, brightness);
	brightness = min(_ShadeMax, brightness);

#if UNITY_COLORSPACE_LINEAR
	brightness = GammaToLinearSpaceExact(brightness);
#endif
	//d = min(_ShadeMax, d);
	return brightness;
}

float4 applyCut(float4 color) {
	if (color.a <= _TCut) {
		color = -1;
	}
	return color;
}