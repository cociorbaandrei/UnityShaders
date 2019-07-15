fixed4 frag( PIO process, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	fixed4 color = tex2D( _MainTex, process.uv );
	clip(color.a - _TCut);

	process = adjustProcess(process, isFrontFace);
	color = applyFresnel(process, color);

	process = adjustProcess(process, 0);
	float3 lightDirection = normalize(process.worldPosition - _WorldSpaceLightPos0.xyz);
	float brightness = saturate(dot(lightDirection,process.normal));// * unity_4LightAtten0;
	brightness = applyToonEdge(process, brightness);
	color.rgb = saturate( color.rgb * _LightColor0.rgb * brightness );

	return color;
}