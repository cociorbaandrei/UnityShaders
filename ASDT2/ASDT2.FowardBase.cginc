fixed4 frag(PIO process, uint isFrontFace : SV_IsFrontFace) : SV_Target
{
	//get the uv coordinates and set the base color.
	fixed4 color = tex2D(_MainTex, process.uv) * _Color;


	#ifdef MODE_TCUT
		clip(color.a - _TCut);
	#endif

	process = adjustProcess(process, isFrontFace);
	color = applyFresnel(process, color);

	//if the mask is set to glow, apply it after lights, else apply it before lightighting it.
	if (_MaskGlow) {
		color = applyLight(process, color);
		color = applyMaskLayer(process, color);
	}
	else 
	{
		color = applyMaskLayer(process, color);
		color = applyLight(process, color);
	}

	#if defined(MODE_TCUT) || defined(MODE_OPAQUE)
		color.a = 1;
	#endif
		
	return saturate(color);
}