#pragma target 3.5

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
	float3 binormal : BINORMAL0;
	float4 tangent : TANGENT;

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
float _Brightness;
float _LMBrightness;
float _TCut;
float attenuation;
			
sampler2D _NormalTex;
sampler2D _NormalTex_ST;
float _NormalScale;
float _Smoothness;

float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}

v2f applyNormalMap( v2f o ){
	float3 tangentSpaceNormal =
		UnpackScaleNormal(tex2D(_NormalTex, o.uv), _NormalScale);
		o.binormal = CreateBinormal(o.worldNormal, o.tangent.xyz, o.tangent.w);


	o.worldNormal = normalize(
		tangentSpaceNormal.x * o.tangent +
		tangentSpaceNormal.y * o.binormal +
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
float3 cubemapReflection( v2f o )
{
	float3 reflectDir = reflect(o.viewDirection, o.normal );
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
	o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	o.viewDirection = normalize( _WorldSpaceCameraPos.xyz - o.worldPosition );
	return o;
}
			
fixed4 frag (v2f i, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	//base Color:
	float4 textureCol = tex2D(_MainTex, i.uv);// sample the texture first, to determine cut, to save effort.
	if ( !_DisableReflectionProbe){
		textureCol.rgb += cubemapReflection(i);
	}
	float a = textureCol.a;
#ifdef MODE_TCUT
	clip(textureCol.a - _TCut);
#endif
	float4 col = textureCol * _Color;

	//prepare for light:
	if ( !isFrontFace ){
		i.normal = -i.normal;
		i.worldNormal = -i.worldNormal;
	}
	if (!_DisableNormalmap){
		i = applyNormalMap(i);
	}

	//lights:
	float4 lightCol;
#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
	float3 lightDir = normalize( _WorldSpaceLightPos0 - i.worldPosition );
	float lightBright = dot(lightDir, i.worldNormal);

	UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPosition);

	float finalBrightness = saturate( attenuation * lightBright ) * a;
#else
	float3 lightDir = normalize( _WorldSpaceLightPos0 - i.worldPosition );
	float lightBright = dot(lightDir, i.worldNormal);
	float finalBrightness = saturate( lightBright );
#endif

	lightCol.rgb = _LightColor0.rgb * finalBrightness;

#ifdef BASIC_FWD_ADD
	//foward pass, just blend light with texture.
	col.rgb = col.rgb * lightCol.rgb;
#else 
	//base pass get and add lightmap:
	float3 lightmapCol = DecodeLightmap( UNITY_SAMPLE_TEX2D( unity_Lightmap, i.lmuv ) );
	if (!_DisableLightmap){
		lightmapCol = lightmapCol + _LMBrightness;
	} else {
		lightmapCol = _LMBrightness;
	}
	//combine lightmap and texture with the light, then blend.
	col.rgb = saturate(col.rgb + lightCol.rgb ) * saturate( lightmapCol.rgb + lightCol.rgb);

	//adjust over all brightness and clamp for our base color:
	col.rgb *=_Brightness;
	col = saturate(col);
#endif

	//always last, apply fog:
	if (!_DisableFog){
		UNITY_APPLY_FOG(i.fogCoord, col);
	}
#ifdef TRANSPARENT
	col.a = a * _Color.a;
#else
	col.a = 1;
#endif
	return col;
}

fixed4 shadowFrag (v2f i, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	return 0;
}