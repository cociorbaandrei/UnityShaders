#pragma once
float GetShadowMaskAttenuation(float2 uv) {
	float attenuation = 1;
#if defined (SHADOWS_SHADOWMASK)
	float4 mask = tex2D(_CameraGBufferTexture4, uv+process.uvOffset);
	attenuation = saturate(dot(mask, unity_OcclusionMaskSelector));
#endif
	return attenuation;
}