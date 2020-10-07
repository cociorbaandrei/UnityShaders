#pragma once
//Mask Layer Paramters
int _DetailLayer;
int _DetailUnlit;

float4 _DetailColor;
float _DetailHue;
float _DetailSaturation;
float _DetailValue;


//used by forward add to negate the light from hitting the unlit surface.
float4 applyDetailLayerForward(PIO process, float4 inColor, int apply) {
	if (_DetailLayer + apply != 2) {
		return inColor;
	}
	float4 outColor = inColor;
	float4 maskColor = tex2D(_DetailTex, process.detailUV + process.uvOffset);
	outColor *=  1 - ( maskColor.a * _DetailColor.a );
	return outColor;
}

float4 applyDetailLayer(PIO process, float4 inColor, int apply)
{
	if (_DetailLayer + apply != 2) {
		return inColor;
	}

	float4 outColor = inColor;
	
	float4 maskColor = tex2D(_DetailTex, process.detailUV + process.uvOffset) * _DetailColor;
	maskColor = HSV( maskColor, _DetailHue, _DetailSaturation, _DetailValue );

	outColor.rgb = lerp(outColor.rgb, maskColor.rgb, maskColor.a);

	return outColor;
}