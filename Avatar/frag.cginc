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
	color = applyFresnel(process, color);

	//if the mask is set to glow, apply it after lights, else apply it before lightighting it.
	if (_DetailUnlit) {
		color = applyLight(process, color);
		#if !UNITY_PASS_FORWARDADD
			color = applyDetailLayer(process, color);
		#endif
		//skip detail layer if foward add?
		color = applyReflectionProbe(color, process, _Smoothness, _Reflectiveness);
		color = applySpecular(process, color);
	}
	else 
	{
		color = applyDetailLayer(process, color);
		color = applyReflectionProbe(color, process, _Smoothness, _Reflectiveness);
		color = applyLight(process, color);
		color = applySpecular(process, color);
	}

	color = saturate(color);
	if (_RenderType == 0) {
		color.a = 1;
	}
	else {
		color.a = finalAlpha;
	}

	return color;
}