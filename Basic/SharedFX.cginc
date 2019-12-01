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
fixed4 _Color;
bool _DisableLightmap;
bool _DisableFog;
float _Brightness;
float _LMBrightness;
float _TCut;
float attenuation;
int _GlowDirection;
float _GlowSpeed;
float _GlowSpread;
float _GlowSharpness;

sampler2D _Tex1;
float4 _Tex1_ST;
bool _Unlit1;

sampler2D _Tex2;
float4 _Tex2_ST;
bool _Unlit2;
bool _Glow2;
fixed4 _GlowColor;

v2f vert (appdata v)
{
	v2f o;
	o.position = UnityObjectToClipPos(v.position);
	o.normal = v.normal;
	o.objectPosition = v.position;
	o.uv = TRANSFORM_TEX(v.uv, _Tex1);
	o.lmuv = v.lmuv.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	UNITY_TRANSFER_FOG(o,o.position);
	o.worldPosition = mul( unity_ObjectToWorld, v.position);
	o.worldNormal = normalize( UnityObjectToWorldNormal( v.normal ));
	return o;
}
			
fixed4 frag (v2f i, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	//base Color:
	float4 tex1Col = tex2D(_Tex1, i.uv);// sample the texture first, to determine cut, to save effort.
	float4 tex2Col = tex2D(_Tex2, i.uv);// sample the texture first, to determine cut, to save effort.
	
	float a = ( tex1Col.a + tex2Col.a ) / 2;
#ifdef MODE_TCUT
	clip(textureCol.a - _TCut);
#endif
	//float4 col = textureCol * _Color;

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

	float finalBrightness = saturate( attenuation * lightBright ) * a;
#else
	float lightBright = dot(_WorldSpaceLightPos0, i.worldNormal);
	float finalBrightness = saturate( lightBright );
#endif

	lightCol.rgb = _LightColor0.rgb * finalBrightness;

#ifdef BASIC_FWD_ADD
	//foward pass, just blend light with texture.
	if (!_Unlit1){
		tex1Col.rgb = tex1Col.rgb * lightCol.rgb;
	} else {
		tex1Col = 0;
	}
	if (!_Unlit2){
		tex2Col.rgb = tex2Col.rgb * lightCol.rgb;
	} else {
		tex2Col = 0;
	} 
#else 
	//base pass get and add lightmap:
	float3 lightmapCol = DecodeLightmap( UNITY_SAMPLE_TEX2D( unity_Lightmap, i.lmuv ) );
	if (!_DisableLightmap){
		lightmapCol = lightmapCol + _LMBrightness;
	} else {
		lightmapCol = _LMBrightness;
	}
	//combine lightmap and texture with the light, then blend.
	if (!_Unlit1){
		tex1Col.rgb = saturate(tex1Col.rgb + lightCol.rgb ) * saturate( lightmapCol.rgb + lightCol.rgb);
	}
	if (!_Unlit2){
		tex2Col.rgb = saturate(tex2Col.rgb + lightCol.rgb ) * saturate( lightmapCol.rgb + lightCol.rgb);
	}
#endif

	//glow layer 2
	if (_Glow2){
		float glowAmt;
		float d = _Time * _GlowSpeed;
		switch(_GlowDirection){
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
		if (_GlowSharpness > 0 ) {
			d = d / _GlowSpread;
			glowAmt = (cos(d) * .5) + .5;
			float s = 1/_GlowSharpness;
			glowAmt *= s;
			s--;
			glowAmt -= s;
			glowAmt = max(0,glowAmt);
		}
		float iGlowAmt = 1-glowAmt;
		tex2Col.rgb = ( iGlowAmt * tex2Col.rgb ) + ( glowAmt * _GlowColor.rgb);
	}
	//blend it all together.
	float ia = 1-tex2Col.a;
	float4 col;
	col.rgb = ( tex1Col.rgb * ia ) + (tex2Col.rgb * tex2Col.a);
	col.rgb *= _Color;

#ifndef BASIC_FWD_ADD
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