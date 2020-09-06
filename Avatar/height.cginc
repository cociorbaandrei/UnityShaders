#pragma once
float GetParallaxHeight(float2 uv) {
	return tex2D(_FeatureTex, uv).a * _Height;
}

void applyHeight(inout PIO o) {
	float2 uvOffset = 0;
	float2 uvDelta = -o.viewDirection * .001;

	float stepHeight = 1;
	float surfaceHeight = 1 - GetParallaxHeight(o.featureUV);

	for ( int i = 1; i < 10 && stepHeight > surfaceHeight; i++ ) {
		uvOffset -= uvDelta;
		stepHeight -= .001;
		surfaceHeight = 1- GetParallaxHeight(o.featureUV + uvOffset);
	}
	o.uvOffset = uvOffset;
}