#if !defined(MY_LIGHTMAPPING_INCLUDED)
#define MY_LIGHTMAPPING_INCLUDED

#include "UnityPBSLighting.cginc"
#include "UnityMetaPass.cginc"

float4 _Color;

sampler2D _MetallicMap;
float _Metallic;
float _Smoothness;

sampler2D _EmissionMap;
float3 _Emission;

struct VertexData {
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	float2 uv2 : TEXCOORD2;
};

struct Interpolators {
	float4 pos : SV_POSITION;
	float4 uv : TEXCOORD0;
};

float3 GetAlbedo (Interpolators i) {
	float3 albedo = _Color.rgb;
	return albedo;
}

Interpolators MyLightmappingVertexProgram (VertexData v) {
	Interpolators i;
	i.pos = UnityMetaVertexPosition(
		v.vertex, v.uv1, v.uv2, unity_LightmapST, unity_DynamicLightmapST
	);

	//need to make these interpolate
	i.uv.xy = v.uv;
	i.uv.zw = v.uv;
	return i;
}

float4 MyLightmappingFragmentProgram (Interpolators i) : SV_TARGET {
	float oneMinusReflectivity;
	float4 Albedo;
	Albedo.rgb = GetAlbedo(i);

	//float roughness = sin(i.uv.x*10)*sin(i.uv.y*10);
	float roughness = -100;
	Albedo.rgb *= roughness;

	return Albedo;
}

#endif