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
	//the (,1) has to be done to get a proper value. Because we only want the directional brightness, we need to equate it assuming an intensity of 1. Giving us a value of 0 to 2.
	float d = dot(float4(direction, 1), float4(normal, 1)); //0 to 2.
	d /= 2; //0 to 1
	d = saturate(d);
	float e = d - _ShadePivot; //-.5,.5
	if (_ShadeSoftness > 0) {
		e *= 1 / _ShadeSoftness;
		e += _ShadePivot;
		e = saturate(e); //0 to 1.
	}
	else {
		e = saturate(floor(e + 1));//0 or 1.
	}
	float brightness = e;
#if UNITY_PASS_FORWARDADD
	//forward add needs a baseline of 0. No range is applied.
	brightness += _ShadePivot;
#else
	//Range only makes sense in the base pass.
	brightness *= _ShadeRange;
	brightness += 1 - _ShadeRange;
	brightness = max(_ShadeMin, brightness);
	brightness = min(_ShadeMax, brightness);
#endif

#if UNITY_COLORSPACE_LINEAR
	brightness = GammaToLinearSpaceExact(brightness);
#endif
	// 10/5/2020:
	// I had moved this to before the light was calculated, but the problem with that was
	// It destroyed distance calculation. Attenuation is the offset by distance and shadows.
	// so it should probably always be applied after, not before.
	brightness *= attenuation;
	return brightness;
}

float4 applyCut(float4 color) {
	if (color.a <= _TCut) {
		color = -1;
	}
	return color;
}