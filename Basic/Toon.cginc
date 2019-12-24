#pragma target 3.5

struct appdata
{
	float4 position : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

struct v2f
{
	float4 position : SV_POSITION;
	float4 objectPosition : POSTION0;
	float3 worldPosition : POSTION1;

	float3 normal : NORMAL;
	float3 worldNormal : NORMAL1;
	float3 viewDirection : NORMAL2;

	float2 uv : TEXCOORD0;
};

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _DetailTex;
float4 _DetailTex_ST;

sampler2D _Ramp;
float4 _Ramp_ST;
fixed4 _Color;
float _TCut;
float attenuation;
			
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
	UNITY_TRANSFER_FOG(o,o.position);
	o.worldPosition = mul( unity_ObjectToWorld, v.position);
	o.worldNormal = normalize( UnityObjectToWorldNormal( v.normal ));
	o.viewDirection = normalize( _WorldSpaceCameraPos.xyz - o.worldPosition );
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

	//apply the detail texture:
	float4 detailCol = tex2D(_DetailTex, i.uv);
	
	col.rgb = ( col.rgb * (1-detailCol.a) ) + (detailCol.a * detailCol.rgb);


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

	//toon ramp
	lightBright = saturate(tex2D(_Ramp,float2(saturate(lightBright),0)));

	float finalBrightness = saturate( attenuation * lightBright ) * a;
#else
	float lightBright = dot(_WorldSpaceLightPos0, i.worldNormal);
	float finalBrightness = saturate( lightBright );
	finalBrightness = saturate(tex2D(_Ramp,float2(finalBrightness,0)));
#endif

	lightCol.rgb = _LightColor0.rgb * finalBrightness;

#ifdef BASIC_FWD_ADD
	//foward pass, just blend light with texture.
	col.rgb = col.rgb * lightCol.rgb;
#else 
	float3 shColor = max(0,ShadeSH9(float4(i.worldNormal,1)));
	col.rgb = col.rgb * ( lightCol.rgb + shColor);
#endif

	//adjust over all brightness and clamp for our base color:
	col = saturate(col);

	//always last, apply fog:
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