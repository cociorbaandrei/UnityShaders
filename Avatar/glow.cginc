#pragma once
int _Glow;
sampler2D _GlowTex;
float4 _GlowTex_SV;
float4 _GlowColor;
float _GlowSpeed;
float _GlowSqueeze;
float _GlowSharpness;
int _GlowRainbow;
float _GlowAmount;
float _GlowDirection;

//just to make sure there's no repeat code:
float4 getGlowAmount(PIO process, float4 col, float mask ) {
	float glowAmt = 1;
	float d = _Time.x * _GlowSpeed;
	switch (_GlowDirection) {
	case 0:
		d += process.worldPosition.x * _GlowSqueeze;
		break;
	case 1:
		d += process.worldPosition.y * _GlowSqueeze;
		break;
	case 2:
		d += process.worldPosition.z * _GlowSqueeze;
		break;
	case 3:
		d += process.uv.x * _GlowSqueeze;
		break;
	case 4:
		d += process.uv.y * _GlowSqueeze;
		break;
	}
	glowAmt = cos(d) * _GlowSharpness;
	glowAmt += 1 - _GlowSharpness;
	glowAmt = saturate(glowAmt);
	glowAmt *= _GlowAmount;
	glowAmt *= mask;

	return glowAmt;
}

float4 applyGlowForward(PIO process, float4 col) {
	if (_Glow != 1) {
		return col;
	}
	float4 mask = tex2D(_GlowTex, process.uv + process.uvOffset);

	float glowAmt = getGlowAmount(process, col, mask.a);

	col.rgb *= 1 - glowAmt;

	return col;
}

float4 applyGlow(PIO process, float4 col) {
	if (_Glow != 1) {
		return col;
	}
	float4 mask = tex2D(_GlowTex, process.uv + process.uvOffset);

	float3 glowCol = mask.rgb;
	if (_GlowRainbow == 1) {
		glowCol *= normalize(shiftColor(float3(1, 0, 0), _Time.y * 360));
	}
	else {
		glowCol *= _GlowColor.rgb;
	}

	float glowAmt = getGlowAmount(process, col, mask.a);

	col.rgb = lerp(col.rgb, glowCol, glowAmt);

	return col;
}
