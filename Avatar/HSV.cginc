#pragma once
float _Hue;
float _Saturation;
float _Value;

float3 shiftColor(float3 inColor, float shift)
{
	float r = shift * 0.01745329251994329576923690768489;
	float u = cos(r);
	float w = sin(r);
	float3 ret;
	ret.r = (.299 + .701 * u + .168 * w)*inColor.r
		+ (.587 - .587 * u + .330 * w)*inColor.g
		+ (.114 - .114 * u - .497 * w)*inColor.b;
	ret.g = (.299 - .299 * u - .328 * w)*inColor.r
		+ (.587 + .413 * u + .035 * w)*inColor.g
		+ (.114 - .114 * u + .292 * w)*inColor.b;
	ret.b = (.299 - .3 * u + 1.25 * w)*inColor.r
		+ (.587 - .588 * u - 1.05 * w)*inColor.g
		+ (.114 + .886 * u - .203 * w)*inColor.b;
	//ret[3] = inColor[3];
	return ret;
}

float4 HSV(float4 color, float hue, float sat, float val) {
	color.rgb = shiftColor(color.rgb, hue);
	float avg = (color.r + color.g + color.b) / 3.0f;

	color.rgb = lerp(avg,color.rgb, sat+1);
	color.rgb += val;
	return color;
}