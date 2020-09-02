Shader "Skuld/Effects/Mask"
{
	SubShader
	{
		Tags { "Queue"="Geometry+10" }
		Zwrite On
		ColorMask 0

		Pass{}
	}
}
