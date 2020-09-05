#pragma once
//Mask Layer Paramters
int _DetailLayer;
int _DetailUnlit;
int _DetailGlow;

float4 _DetailColor;
float4 _DetailGlowColor;
float _DetailRainbow;
float _DetailGlowSpeed;
float _DetailGlowSharpness;
float _DetailHue;
float _DetailSaturation;
float _DetailValue;

float4 applyDetailLayer(PIO process, float4 inColor)
{
	if (_DetailLayer != 1) {
		return inColor;
	}
	float4 outColor = inColor;
	float2 uv = process.detailUV;
	float4 maskColor = tex2D(_DetailTex, uv + process.uvOffset) * _DetailColor;
	maskColor = HSV( maskColor, _DetailHue, _DetailSaturation, _DetailValue );
	float alphaDifference = 1 - maskColor.a;
	float3 rainbowColor;

	if (_DetailGlow == 1) {
		uint time = (_Time * (_DetailGlowSpeed * 1000));
		float gp = (time % 120) / 100.0f - .1;

		float gv = (gp - uv[1]);
		gv = abs(gv);
		gv *= _DetailGlowSharpness;
		gv = saturate(gv);
		gv = 1 - gv;
		gv *= _DetailGlowColor.a;
		if (_DetailRainbow) {
			int rt = _Time * 7000;
			_DetailGlowColor.rgb = normalize(shiftColor(float3(1, 0, 0), rt));
		}
		maskColor.rgb = lerp(maskColor.rgb, _DetailGlowColor.rgb, gv);
	}
	outColor.rgb = (outColor.rgb * alphaDifference) + (maskColor.rgb * maskColor.a);

	return outColor;
}