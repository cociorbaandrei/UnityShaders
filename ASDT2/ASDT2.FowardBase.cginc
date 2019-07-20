//keep in mind to always add lights. But multiply the sum to the final color. 
//This method applies ambient light from directional and lightprobes.
fixed4 applyLight(PIO process, fixed4 color){
	/************************
	* Brightness / toon edge:
	************************/
	//Calculate Brightness:
	float3 ambientDirection = normalize(unity_SHAr + unity_SHAg + unity_SHAb);
	float ambientBrightness = saturate(dot(ambientDirection, process.worldNormal));
	float directionalBrightness = saturate(dot(_WorldSpaceLightPos0, process.worldNormal));
	float brightness = max(ambientBrightness, directionalBrightness);
	brightness = applyToonEdge(process, brightness);
	

	/************************
	* Color:
	************************/
	//get ambient color:
	half3 ambientColor = ShadeSH9(float4(0,0,0,1));
	//get directional color:
	half3 directionalColor = _LightColor0.rgb;
	//apply to final color:
	color.rgb *= saturate(directionalColor + ambientColor);
	//apply the brightness:
	color.rgb = saturate(color.rgb * brightness);
	return color;
}

fixed4 frag( PIO process, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	//get the uv coordinates and set the base color.
	fixed4 color = tex2D( _MainTex, process.uv );
	clip(color.a - _TCut);

	process = adjustProcess(process, isFrontFace);
	color = applyFresnel(process, color);

	if ( !_MaskGlow ){
		color = applyMaskLayer(process, color);
	}

	//Apply baselights
	color = applyLight(process, color);

	if ( _MaskGlow ){
		color = applyMaskLayer(process, color);
	}

	return color;
}