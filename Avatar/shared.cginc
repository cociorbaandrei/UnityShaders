#pragma once
#define BINORMAL_PER_FRAGMENT

//general IO with Semantics
struct IO
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
	uint id : SV_VertexID;
	float4 tangent : TANGENT;
#if defined(LIGHTMAP_ON)
	float2 lmuv : TEXCOORD1;
#endif
};

//processed IO to be used by submethods
struct PIO
{
	float4 pos : SV_POSITION; //the Position relative to the screen
	float3 normal : NORMAL; //The normal in screen space.
	float2 uv : TEXCOORD0; //uv coordinates
	float2 detailUV : DETAILUV;
	float2 normalUV : NORMALUV;
	float2 featureUV : FEATUREUV;
	float2 uvOffset : PARALLAX;
	float4 objectPosition : POSITION2; //The position relative to the mesh origin.
	float3 worldNormal : TEXCOORD2; //The normal in world space.
	float3 worldPosition : TEXCOORD3; //the position relative to world origin.
	float3 viewDirection : TEXCOORD4; //The direction the camera is looking at the mesh.
	float4 tangent : TEXCOORD5;//for bump mapping.
	float4 worldTangent : TANGENT1;  //more bump mapping.
	float3 binormal : TEXCOORD6; //also for bump mapping.
	float4 extras : TEXCOORD8;
#if defined(VERTEXLIGHT_ON)
	float3 vcolor : VCOLOR;
#endif
#if defined(LIGHTMAP_ON)
	float2 lmuv : TEXCOORD1;
#endif

#if !defined(UNITY_PASS_SHADOWCASTER)
	SHADOW_COORDS(7)
#endif
};

int _RenderType;
float _LMBrightness;

//Base Layer paramters
sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _DetailTex;
float4 _DetailTex_ST;
sampler2D _FeatureTex;
float4 _FeatureTex_ST;
sampler2D _NormalTex;
float4 _NormalTex_ST;

float4 _Color;
float _TCut;

sampler2D _CameraGBufferTexture0;
sampler2D _CameraGBufferTexture1;
sampler2D _CameraGBufferTexture2;
sampler2D _CameraGBufferTexture4;

#if defined (SHADOWS_SCREEN)
//sampler2D _ShadowMapTexture;
#endif

PIO adjustProcess(PIO process, uint isFrontFace)
{
	if (!isFrontFace){
		process.normal = -process.normal;
		process.worldNormal = -process.worldNormal;
	}
	//get the camera position to calculate view direction and then get the direction from the camera to the pixel.
	//process.viewDirection = normalize(process.worldPosition - _WorldSpaceCameraPos);

	return process;
}

#if !UNITY_PASS_SHADOWCASTER
#include "ApplyFeatureMap.cginc"
#include "vertexLights.cginc"
#include "HSV.cginc"
#include "detailLayer.cginc"
#include "glow.cginc"
#include "shadows.cginc"
#include "toon.cginc"
#include "applyLight.cginc"
#include "normals.cginc"
#include "specular.cginc"
#include "reflections.cginc"
#include "height.cginc"
#include "vert.cginc"
#include "frag.cginc"
#else 
#include "vert.cginc"
#include "shadowFrag.cginc"
#endif
