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
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
	float2 lmuv : TEXCOORD1;
	float4 objectPosition : TEXCOORD6;
	float3 worldPosition : TEXCOORD7;
	float3 worldNormal : TEXCOORD8;
	UNITY_FOG_COORDS(2)
	float4 position : SV_POSITION;
};

sampler2D _MainTex;
float4 _MainTex_ST;
fixed4 _Color;
bool _DisableLightmap;
bool _DisableFog;
float _Brightness;
float _LMBrightness;
float _TCut;
float attenuation;
			
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
	return o;
}
			
fixed4 frag (v2f i, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	//base Color:
	float4 textureCol = tex2D(_MainTex, i.uv);// sample the texture first, to determine cut, to save effort.
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

	//lights:
	float4 lightCol;
#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
	float3 lightDir = normalize( _WorldSpaceLightPos0 - i.worldPosition );
	float lightBright = dot(lightDir, i.worldNormal);

	UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPosition);

	float finalBrightness = saturate( attenuation * lightBright );
#else
	float lightBright = dot(_WorldSpaceLightPos0, i.worldNormal);
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
	col.a = a;
	return col;
}

fixed4 shadowFrag (v2f i, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	return 0;
}