#pragma target 3.5
#define BINORMAL_PER_FRAGMENT

struct appdata
{
	float4 position : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
	float2 lmuv : TEXCOORD1;
	float4 tangent : TANGENT;
};

struct v2f
{
	float4 position : SV_POSITION;
	float4 objectPosition : POSTION0;
	float3 worldPosition : POSTION1;

	float3 normal : NORMAL;
	float3 worldNormal : NORMAL1;
	float3 viewDirection : NORMAL2;
	float4 tangent : TANGENT;
	float4 worldTangent : TANGENT1;

	float2 uv : TEXCOORD0;
	float2 lmuv : TEXCOORD1;

	UNITY_FOG_COORDS(2)
};

sampler2D _MainTex;
float4 _MainTex_ST;
fixed4 _Color;
bool _DisableLightmap;
bool _DisableNormalmap;
bool _DisableFog;
bool _DisableReflectionProbe;
bool _DisableReflectionProbeBlending;
bool _DisableLightProbes;
float _Brightness;
float _LMBrightness;
float _TCut;
float attenuation;
			
sampler2D _NormalTex;
sampler2D _NormalTex_ST;
float _NormalScale;
float _Smoothness;
float _Reflectiveness;
int _ReflectType;

//variables for use by fragment shader:
float4 lightColor;
float initAlpha;


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
float3 cubemapReflection( float3 color, v2f o )
{
	float3 reflectDir = reflect(-o.viewDirection, o.worldNormal );
    Unity_GlossyEnvironmentData envData;
    envData.roughness = 1 - _Smoothness;
    envData.reflUVW = normalize(reflectDir);

	float3 result = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
	if (!_DisableReflectionProbeBlending)
	{
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
	}

	//apply the amount the reflective surface is allowed to affect:
	result *= _Reflectiveness;

	switch (_ReflectType) {
		default:
		case 0:
			result = lerp(color, result, _Smoothness);
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
	o.lmuv = v.lmuv.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	UNITY_TRANSFER_FOG(o,o.position);
	o.worldPosition = mul( unity_ObjectToWorld, v.position);
	o.worldNormal = normalize( UnityObjectToWorldNormal( v.normal ));
	o.tangent = v.tangent;
	o.worldTangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
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
	//always last, apply fog:
	if (!_DisableFog) {
		UNITY_APPLY_FOG(i.fogCoord, col);
	}
#ifdef  _MODE_TRANSPARENT
	col.a = initAlpha * _Color.a;
	col = 0;
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
	if (!_DisableNormalmap) {
		i = applyNormalMap(i);
	}

	//lights:
#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
	float3 lightDir = normalize(_WorldSpaceLightPos0 - i.worldPosition);
	float lightBright = dot(lightDir, i.worldNormal);

	UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPosition);

	float finalBrightness = saturate(attenuation * lightBright) * initAlpha;
#else
	float3 lightDir = normalize(_WorldSpaceLightPos0 - i.worldPosition);
	float lightBright = dot(lightDir, i.worldNormal);
	float finalBrightness = saturate(lightBright);
#endif
	lightColor.rgb = _LightColor0.rgb * finalBrightness;

#ifndef BASIC_FWD_ADD
	//base pass get and add lightmap:
	float3 lightmapCol = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lmuv));
	if (!_DisableLightmap) {
		lightmapCol = lightmapCol + _LMBrightness;
	}
	else {
		lightmapCol = 1 + _LMBrightness;
	}
	lightColor.rgb += lightmapCol.rgb;

	//if using lightprobes, apply lightprobes:
	if (!_DisableLightProbes) {
		lightColor.rgb += ShadeSH9(float4(i.worldNormal, 1)).rgb;
	}
#endif
}

float4 ApplyReflectionProbe(float4 col, inout v2f i) {
	#ifndef BASIC_FWD_ADD
		//Reflects 2nd to last
		if (!_DisableReflectionProbe) {
			col.rgb = cubemapReflection(col.rgb, i);
		}
	#endif
	return col;
}

/************************************************************
	Main Fragment method.
************************************************************/
fixed4 frag (v2f i, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	i.viewDirection = normalize( _WorldSpaceCameraPos.xyz - i.worldPosition );
	//base Color:
	float4 col = tex2D(_MainTex, i.uv);// sample the texture first, to determine cut, to save effort.
#ifdef MODE_TCUT
	clip(col.a - _TCut);
#endif
	float initAlpha = col.a;//initial alpha value before anything messes with the color.
	//this does all the logic to determine what the lighting will be on this pass. includes: 
	// normalMap, lightMap, lightProbes
	CalculateLightColor(i, isFrontFace);

	col *= _Color; //apply base color.
	col = ApplyShadows(col, i);//apply shadows
	col = ApplyLighting(col, i);//applies the calculated lighting
	col = ApplyReflectionProbe(col,i);//applies the reflection probe.
	col = FinalizeColor(col, i);//applies fog and final alpha values.
#ifdef DUAL_TEXTURE
	
#endif

	return col;
}

fixed4 shadowFrag (v2f i, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	return 0;
}