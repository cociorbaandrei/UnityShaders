#include "vertexLights.cginc"
#pragma target 3.5
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members _ERange)
#pragma exclude_renderers d3d11
#define BINORMAL_PER_FRAGMENT

struct appdata
{
	float4 position : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
	float2 lmuv : TEXCOORD1;
#ifdef _NORMALMAP
	float4 tangent : TANGENT;
#endif
};

struct v2f
{
	float4 position : SV_POSITION;
	float4 objectPosition : POSTION0;
	float3 worldPosition : POSTION1;

	float3 normal : NORMAL;
	float3 worldNormal : NORMAL1;
	float3 viewDirection : NORMAL2;
#ifdef _NORMALMAP
	float4 tangent : TANGENT;
	float4 worldTangent : TANGENT1;
#endif

	float2 uv : TEXCOORD0;
#ifdef _LIGHTMAPPED
	float2 lmuv : TEXCOORD1;
#endif
#if defined(_DUALTEXTURE) || defined(_EMISSION)
	float2 uv2 : TEXCOORD2;
#endif
#if defined(VERTEXLIGHT_ON)
	float3 vcolor : VCOLOR;
#endif
};

sampler2D _MainTex;
float4 _MainTex_ST;
fixed4 _Color;
float _Brightness;
float _LMBrightness;
float _TCut;
float attenuation;

#if defined(_DUALTEXTURE) || defined(_EMISSION)
sampler2D _Tex2;
float4 _Tex2_ST;
float _SmoothnessL2;
float _ReflectivenessL2;
#endif
#ifdef _EMISSION
float4 _EPosition;
float _ERange;
float4 _ESamples;
#endif

//glowy shit
#ifdef _GLOW
float4 _GlowColor;
int _GlowDirection;
float _GlowSpeed;
float _GlowSpread;
float _GlowSharpness;
#endif

sampler2D _NormalTex;
sampler2D _NormalTex_ST;
float _NormalScale;
float _Smoothness;
float _Reflectiveness;
int _ReflectType;

//variables for use by fragment shader:
float4 lightColor;
float initAlpha;

#ifdef _NORMALMAP
float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}

v2f applyNormalMap( v2f o ){
	float3 binormal;

	float3 tangentSpaceNormal = UnpackScaleNormal(tex2D(_NormalTex, o.uv), _NormalScale);

	binormal = CreateBinormal(o.worldNormal, o.worldTangent.xyz, o.worldTangent.w);


	o.worldNormal = normalize(
		tangentSpaceNormal.x * o.worldTangent +
		tangentSpaceNormal.y * binormal +
		tangentSpaceNormal.z * o.worldNormal
	);
	return o;
}
#endif

float3 BoxProjection (
	float3 direction, float3 position,
	float4 cubemapPosition, float3 boxMin, float3 boxMax
) {

	if (cubemapPosition.w > 0) {
		float3 factors =
			((direction > 0 ? boxMax : boxMin) - position) / direction;
		float scalar = min(min(factors.x, factors.y), factors.z);
		direction = direction * scalar + (position - cubemapPosition);
	}

	return direction;
}

//a simple reflection Probe Sampler, original provided by d4rkpl4y3r
float3 cubemapReflection( float3 color, v2f o, float smooth, float ref)
{
	float3 reflectDir = reflect(-o.viewDirection, o.worldNormal );
    Unity_GlossyEnvironmentData envData;
    envData.roughness = 1 - smooth;
    envData.reflUVW = normalize(reflectDir);

	float3 result = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
#ifdef _REFLECTION_PROBE_BLENDING
	float spec0interpolationStrength = unity_SpecCube0_BoxMin.w;
	UNITY_BRANCH
	if(spec0interpolationStrength < 0.999)
	{
		envData.reflUVW = BoxProjection(reflectDir, o.worldPosition,
			unity_SpecCube1_ProbePosition,
			unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
		result = lerp(Unity_GlossyEnvironment(
				UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
				unity_SpecCube1_HDR, envData
			),result, spec0interpolationStrength);
	}
#endif

	//apply the amount the reflective surface is allowed to affect:
	result *= ref;

	switch (_ReflectType) {
		default:
		case 0:
			result = lerp(color, result, smooth);
			break;
		case 1:
			result = result * color;
			break;
		case 2:
			result = result + color;
			break;
	}
	return result;
}

/*
Begin vert, frag
*/
v2f vert (appdata v)
{
	v2f o;
	o.position = UnityObjectToClipPos(v.position);
	o.normal = v.normal;
	o.objectPosition = v.position;
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
#if defined(_DUALTEXTURE) || defined(_EMISSION)
	o.uv2 = TRANSFORM_TEX(v.uv, _Tex2);
#endif
#ifdef _LIGHTMAPPED
	o.lmuv = v.lmuv.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
	o.worldPosition = mul( unity_ObjectToWorld, v.position);
	o.worldNormal = normalize( UnityObjectToWorldNormal( v.normal ));
	o.viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.worldPosition);//This Should be done in the fragmentation shader. For now pass world pos. But just in case.
#ifdef _NORMALMAP
	o.tangent = v.tangent;
	o.worldTangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
#endif

#ifdef VERTEXLIGHT_ON
	o.vcolor = Shade4PointLightsFixed(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb,
		unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, o.worldPosition, o.worldNormal
	);
#endif
	return o;
}

/************************************************************
	Fragment Methods.
************************************************************/
float4 ApplyLighting(float4 col, inout v2f i)
{
#ifdef BASIC_FWD_ADD
	//foward pass, just blend light with texture.
	col.rgb = col.rgb * lightColor.rgb;
#else 
	//combine lightmap and texture with the light, then blend.
	col.rgb = col.rgb * lightColor.rgb;

	//adjust over all brightness and clamp for our base color:
	col.rgb *= _Brightness;
	col = saturate(col);
#endif
	return col;
}

float4 ApplyShadows(float4 col, inout  v2f i) {
	#if defined(SHADOWS_SCREEN)
		float2 suv = i.position.xy / i.position.w;
		#if defined(UNITY_NO_SCREENSPACE_SHADOWS)
			#if defined(SHADOWS_NATIVE)
				fixed4 shadowCol = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, i.position);
				col *= shadowCol;
			#else
				float4 dist = SAMPLE_DEPTH_TEXTURE(_ShadowMapTexture, suv);
			#endif
		#endif
	#endif
	return col;
}

float4 FinalizeColor(float4 col, inout v2f i)
{
#ifdef _MODE_TRANSPARENT
	col.a = initAlpha * _Color.a;
#else
	col.a = 1;
#endif
	return col;
}

void CalculateLightColor(inout v2f i, bool isFrontFace) {
	//prepare for light:
	if (!isFrontFace) {
		i.normal = -i.normal;
		i.worldNormal = -i.worldNormal;
	}
#ifdef _NORMALMAP
	i = applyNormalMap(i);
#endif

	//lights:
#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
	float3 lightDir = normalize(_WorldSpaceLightPos0 - i.worldPosition);
	float lightBright = dot(lightDir, i.worldNormal);

	UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPosition);

	float finalBrightness = saturate(attenuation * lightBright) * initAlpha;
#else
	float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
	float lightBright = dot(lightDir, i.worldNormal);
	float finalBrightness = saturate(lightBright);
#endif
	lightColor.rgb = _LightColor0.rgb * finalBrightness;

#ifndef BASIC_FWD_ADD
	//base pass get and add lightmap:
#ifdef _LIGHTMAPPED
	float3 lightmapCol = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lmuv));
	lightmapCol = lightmapCol + _LMBrightness;
#else
	float3 lightmapCol = 1 + _LMBrightness;
#endif
	lightColor.rgb += lightmapCol.rgb;

	//if using lightprobes, apply lightprobes:
#ifdef _LIGHTPROBES
	lightColor.rgb += ShadeSH9(float4(i.worldNormal, 1)).rgb;
#endif
#endif
}

float4 ApplyReflectionProbe(float4 col, inout v2f i, float smooth, float ref) {
	if (smooth == 0.0f) return col;
	#ifndef BASIC_FWD_ADD
	//Reflects 2nd to last
	col.rgb = cubemapReflection(col.rgb, i, smooth, ref);
	#endif
	return col;
}

#ifdef _GLOW
float4 ApplyGlow(float4 col, inout v2f i ) {
	float glowAmt = 0;
	float d = _Time * _GlowSpeed;
	switch (_GlowDirection) {
		case 0:
			d += i.worldPosition.x;
			break;
		case 1:
			d += i.worldPosition.y;
			break;
		case 2:
			d += i.worldPosition.z;
			break;
	}
	if (_GlowSharpness > 0) {
		d = d / _GlowSpread;
		glowAmt = (cos(d) * .5) + .5;
		float s = 1 / _GlowSharpness;
		glowAmt *= s;
		s--;
		glowAmt -= s;
		glowAmt = max(0, glowAmt);
	}
	float iGlowAmt = 1 - glowAmt;
	col.rgb = (iGlowAmt * col.rgb) + (glowAmt * _GlowColor.rgb);
	return col;
}
#endif

/************************************************************
	Main Fragment method.
************************************************************/
fixed4 frag (v2f i, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	i.viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.worldPosition);
	//base Color:
	float4 col = tex2D(_MainTex, i.uv);// sample the texture first, to determine cut, to save effort.
#ifdef _MODE_CUTOUT
	clip(col.a - _TCut);
#endif
	initAlpha = col.a;//initial alpha value before anything messes with the color.
	//this does all the logic to determine what the lighting will be on this pass. includes: 
	// normalMap, lightMap, lightProbes
	CalculateLightColor(i, isFrontFace);

	col *= _Color; //apply base color.
#if defined(UNITY_PASS_FORWARDBASE)
//Apply Emissive vertex Lights
#ifdef VERTEXLIGHT_ON
	float4 texCol = tex2D(_MainTex, i.uv);
	float3 vcolor = i.vcolor * texCol.rgb;
	col.rgb += vcolor;
#endif
#ifdef _REFLECTIONS
	col = ApplyReflectionProbe(col, i, _Smoothness, _Reflectiveness );//applies the reflection probe.
#endif
#endif

#ifndef _UNLITL1
	col = ApplyShadows(col, i);//apply shadows
	col = ApplyLighting(col, i);//applies the calculated lighting
#endif
	col = FinalizeColor(col, i);//applies the final alpha values.



#if defined(UNITY_PASS_FORWARDBASE)
	/****************************
	* Dual Texture (2nd layer)
	****************************/
#ifdef _DUALTEXTURE
	fixed4 col2 = tex2D(_Tex2, i.uv2);
	float ia = 1 - col2.a;
	float initAlpha2 = col2.a;
#ifndef _UNLITL2
	col2 = ApplyShadows(col2, i);//apply shadows
	col2 = ApplyLighting(col2, i);//applies the calculated lighting
#endif
#ifdef _REFLECTIONS
	col2 = ApplyReflectionProbe(col2, i, _SmoothnessL2, _ReflectivenessL2);//applies the reflection probe.
#endif
#ifdef _GLOW
	col2 = ApplyGlow(col2, i);
#endif
	col = (col * ia) + (col2 * initAlpha2);
#endif

	//Emission is like a foward add light.
#ifdef _EMISSION
	float xstep = 1.0f / _ESamples.x;
	float ystep = 1.0f / _ESamples.y;
	float xstart = xstep / 2;
	float ystart = ystep / 2;
	
	float3 ecol = float3(0, 0, 0);
	for ( float x = xstart; x < 1.0f; x += xstep ) {
		for ( float y = ystart; y < 1.0f; y += ystep ) {
			ecol += tex2D(_Tex2, float2(x, y)).rgb;
		}
	}
	ecol /= _ESamples.x * _ESamples.y;
	ecol *= tex2D(_MainTex, i.uv).rgb;
	ecol *= _Color;
	//ecol *= _SmoothnessL2;
	float4 edir = float4( _EPosition.xyz - i.worldPosition, 1 );
	float b = dot(i.worldNormal, edir);
	b /= 2;
	b += .5f;

	float l = length(i.worldPosition - _EPosition) / 100.0f;
	float r = _ERange / 100.0f;
	float a = saturate( (r - l) / r );
	a *= a;

	ecol.rgb *= b;
	ecol.rgb *= a;
	ecol.rgb *= _SmoothnessL2;

	col.rgb += ecol.rgb;
#endif
#endif
#if defined(UNITY_PASS_FORWARDADD)
	col.rgb *= initAlpha;
#endif

	return col;
}

fixed4 shadowFrag (v2f i, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	return 0;
}