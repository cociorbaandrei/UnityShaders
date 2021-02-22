uint UVToIndex(float2 uv, float4 texelSize) {
	uint i = 0;
	i += (uint)(uv.y * texelSize.w * texelSize.z);
	i += (uint)(uv.x * texelSize.z);
	return i;
}

float2 IndexToUV(uint index, float4 texelSize) {
	float2 uv;
	uint x = index % (uint)texelSize.z;
	uint y = index / (uint)texelSize.z;
	uv.x = (float)x * texelSize.x;
	uv.y = (float)y * texelSize.y;
	return uv;
}

fixed4 shiftColor(fixed4 inColor, float shift)
{
	float r = shift * 0.01745329251994329576923690768489;
	float u = cos(r);
	float w = sin(r);
	fixed4 ret;
	ret.r = (.299 + .701 * u + .168 * w)*inColor.r
		+ (.587 - .587 * u + .330 * w)*inColor.g
		+ (.114 - .114 * u - .497 * w)*inColor.b;
	ret.g = (.299 - .299 * u - .328 * w)*inColor.r
		+ (.587 + .413 * u + .035 * w)*inColor.g
		+ (.114 - .114 * u + .292 * w)*inColor.b;
	ret.b = (.299 - .3 * u + 1.25 * w)*inColor.r
		+ (.587 - .588 * u - 1.05 * w)*inColor.g
		+ (.114 + .886 * u - .203 * w)*inColor.b;
	ret[3] = inColor[3];
	ret.a = 1;
	return ret;
}

float2 rotate2(float2 inCoords, float rot)
{
	float sinRot;
	float cosRot;
	sincos(rot, sinRot, cosRot);
	return mul(float2x2(cosRot, -sinRot, sinRot, cosRot), inCoords);
}

/*********************************************
* about the generate lookat Matrix:
* _11_21_31 is left
* _12_22_32 is forward
* _13_23_33 is up
*********************************************/
float3x3 GenerateLookAtMatrix(float3 origin, float3 target) {
	float3 zaxis = normalize(origin - target);
	float3 xaxis = normalize(float3(zaxis.z, 0, -zaxis.x));
	float3 yaxis = cross(zaxis, xaxis);
	return transpose(float3x3(xaxis, yaxis, zaxis));
}