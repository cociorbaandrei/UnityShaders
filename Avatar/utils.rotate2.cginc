float2 rotate2(float2 inCoords, float rot)
{
	float sinRot;
	float cosRot;
	sincos(rot, sinRot, cosRot);
	return mul(float2x2(cosRot, -sinRot, sinRot, cosRot), inCoords);
}