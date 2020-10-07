#pragma once
float4 frag(PIO process, uint isFrontFace : SV_IsFrontFace) : SV_Target
{
	applyHeight(process);
	ApplyFeatureMap(process);
	//get the uv coordinates and set the base color.
	float4 color = tex2D(_MainTex, process.uv + process.uvOffset) * _Color;
	float finalAlpha = color.a;
	color = HSV(color, _Hue, _Saturation, _Value);

	if (_NormalScale > 0) {
		applyNormalMap(process);
	}
	
	if (_RenderType == 2) {
		clip(color.a - _TCut);
	}

	process = adjustProcess(process, isFrontFace);

	#ifdef UNITY_PASS_FORWARDBASE
		color = applyReflectionProbe(color, process, _Smoothness, _Reflectiveness);
		color = applyDetailLayer(process, color, 1-_DetailUnlit);

		color = applyFresnel(process, color);
		color = applySpecular(process, color);
		color = applyLight(process, color);

		color = applyDetailLayer(process, color, _DetailUnlit);
		color = applyGlow(process, color);
	#else
		color = applyReflectionProbe(color, process, _Smoothness, _Reflectiveness);
		color = applyDetailLayer(process, color, 1 - _DetailUnlit);

		color = applySpecular(process, color);
		color = applyLight(process, color);

		color = applyDetailLayerForward(process, color, _DetailUnlit);
		color = applyGlowForward(process, color);
	#endif

	color = saturate(color);
	if (_RenderType == 0) {
		color.a = 1;
	}
	else {
		color.a = finalAlpha;
	}

	return color;
}