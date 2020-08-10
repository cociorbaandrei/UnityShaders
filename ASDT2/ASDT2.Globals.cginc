#pragma once
//general IO with Semantics
struct IO
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
	uint id : SV_VertexID;
	float4 tangent : TANGENT;
};

//processed IO to be used by submethods
struct PIO
{
	float4 pos : SV_POSITION; //the Position relative to the screen
	float3 normal : NORMAL; //The normal in screen space.
	float2 uv : TEXCOORD0; //uv coordinates
	float4 objectPosition : TEXCOORD1; //The position relative to the mesh origin.
	float3 worldNormal : TEXCOORD2; //The normal in world space.
	float3 worldPosition : TEXCOORD3; //the position relative to world origin.
	float3 viewDirection : TEXCOORD4; //The direction the camera is looking at the mesh.
	float4 tangent : TEXCOORD5;//for bump mapping.
	float3 binormal : TEXCOORD6; //also for bump mapping.
	float4 extras : TEXCOORD8;
#if defined(VERTEXLIGHT_ON)
	float3 vcolor : VCOLOR;
#endif
#if !defined(UNITY_PASS_SHADOWCASTER)
	SHADOW_COORDS(7)
#endif
};

struct Light
{
	float brightness;
	half3 color;
};

//shading properties
float _ShadeRange;
float _ShadeSoftness;
float _ShadeMax;
float _ShadeMin;
float _ShadePivot;

//Base Layer paramters
sampler2D _MainTex;
sampler2D _MainTex_ST;
float4 _FresnelColor;
float4 _Color;
float _FresnelRetract;
float _TCut;

//Mask Layer Paramters
sampler2D _MaskTex;
sampler2D _MaskTex_ST;
float _MaskGlow;
float4 _MaskGlowColor;
float _MaskRainbow;
float _MaskGlowSpeed;
float _MaskGlowSharpness;

PIO vert( IO v ){
	PIO process;
	process.uv = v.uv;//TRANSFORM_TEX( v.uv, _MainTex );
	process.normal = normalize( v.normal );
	process.objectPosition = v.vertex;
	process.pos = UnityObjectToClipPos( v.vertex );

	//reverse the draw position for the screen back to the world position for calculating view Direction.
	process.worldPosition = mul( unity_ObjectToWorld, v.vertex ).xyz;
	process.worldNormal = normalize( UnityObjectToWorldNormal( process.normal ) );
	process.extras.x = v.id;
#if !defined(UNITY_PASS_SHADOWCASTER)
	TRANSFER_SHADOW(process)
#endif

#ifdef VERTEXLIGHT_ON
	process.vcolor = Shade4PointLights(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb,
		unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, process.worldPosition, process.worldNormal
	);
	// According to d4rk, the impementation of this by unity is wrong. 
	//This will need a custom implementation of the line calculating atten.
	// float4 atten = 1.0 / (1.0 + lengthSq * lightAttenSq);
	// float4 atten2 = saturate(1 - (lengthSq * lightAttenSq / 25));
	// atten = min(atten, atten2 * atten2);
#endif

	return process;
}

PIO adjustProcess(PIO process, uint isFrontFace)
{
	if (!isFrontFace){
		process.normal = -process.normal;
		process.worldNormal = -process.worldNormal;
	}
	//get the camera position to calculate view direction and then get the direction from the camera to the pixel.
	process.viewDirection = normalize(process.worldPosition - _WorldSpaceCameraPos);

	return process;
}

float ToonDot(float3 direction, float3 normal) 
{
	//The inputs on this should not be normalize, because for something with
	//spherical harmonics, it will be destroyed. If need be, normalize
	//before passing to this method.
	//dotal can be from -1 to 1, so do this math to bring it to a range of 0 to 1
	float d = (dot( direction, normal ) + 1) / 2;
	float m = (dot(direction, normalize(direction)) + 1) / 2;
	float e = _ShadePivot - d;
	if (_ShadeSoftness > 0) {
		e *= 1 / _ShadeSoftness;
		e = saturate(e);
	}
	else {
		e = saturate(floor(e+1));
	}
#if defined(UNITY_PASS_FORWARDADD)
	float brightness = 1 - (e * _ShadeRange);
#else
	float brightness = m - (e * _ShadeRange);
#endif
	
	brightness = max(_ShadeMin, brightness);
	
#if UNITY_COLORSPACE_LINEAR
	brightness = GammaToLinearSpaceExact(brightness);
#endif
	//d = min(_ShadeMax, d);
	return brightness;
}

float applyToonEdge( PIO process, float brightness)
{
	//apply faux ramp:
	if ( _ShadeSoftness > 0 ){
		brightness -= _ShadePivot;
		brightness *= 1/_ShadeSoftness;
		brightness += _ShadePivot;
	} else {
		if (brightness > _ShadePivot){
			brightness = 1;
		} else {
			brightness = 0;
		}
	}

	//apply range, min and max:
	brightness = max(_ShadeMin,brightness);
	brightness = brightness * _ShadeRange + (1 - _ShadeRange);
	brightness = min(_ShadeMax,brightness);

	brightness = saturate(brightness);
	return brightness;
}

fixed4 applyCut( fixed4 color ){
	if (color.a <= _TCut){
		color = -1;
	}
	return color;
}

fixed4 applyFresnel( PIO process, fixed4 inColor ){
#if defined(UNITY_PASS_FORWARDADD)
	//foward add lighting and details from pixel lights.
	float3 direction = normalize(_WorldSpaceLightPos0.xyz - process.worldPosition.xyz);
	float alpha = ( dot(direction, process.worldNormal) + 1.0f ) / 2.0f;
	alpha = max(0, alpha);
#else
	//Calculate light probes from foward base.
	float3 ambientDirection = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz; //do not normalize
	float alpha = ( dot(ambientDirection, process.worldNormal.xyz) + 1.0f ) / 2.0f;

	float directAlpha = ( dot(normalize(_WorldSpaceLightPos0.xyz), process.worldNormal.xyz) + 1.0f ) / 2.0f;
	alpha = max(0, alpha) + max(0, directAlpha);
#endif

	float val = saturate(-dot(process.viewDirection, process.worldNormal));
	float rim = 1 - val * _FresnelRetract;
	rim = max(0,rim);
	rim *= _FresnelColor.a * alpha;
	float orim = 1 - rim;
	fixed4 color;
	inColor.rgb = (_FresnelColor * rim) + (inColor * orim);
	return inColor;
}

fixed4 shiftColor( fixed4 inColor, float shift )
{
	float r = shift * 0.01745329251994329576923690768489;
	float u = cos(r);
	float w = sin(r);
	fixed4 ret;
	ret.r = (.299+.701 * u+.168 * w)*inColor.r
		+ (.587-.587 * u+.330 * w)*inColor.g
		+ (.114-.114 * u-.497 * w)*inColor.b;
	ret.g = (.299-.299 * u-.328 * w)*inColor.r
		+ (.587+.413 * u+.035 * w)*inColor.g
		+ (.114-.114 * u+.292 * w)*inColor.b;
	ret.b = (.299-.3 * u+1.25 * w)*inColor.r
		+ (.587-.588 * u-1.05 * w)*inColor.g
		+ (.114+.886 * u-.203 * w)*inColor.b;	
	ret[3] = inColor[3];
	ret.a = 1;
	return ret;
}

fixed4 applyMaskLayer( PIO process, fixed4 inColor )
{
	fixed4 outColor = inColor;
	float2 uv = process.uv;
	float4 maskColor = tex2D(_MaskTex, uv);
	float alphaDifference = 1 - maskColor.a;
	float3 rainbowColor;

	if ( _MaskGlow ){
		int time = ( _Time * (_MaskGlowSpeed*1000) );
		float gp = ( time % 120 ) / 100.0f - .1;

		float igv = (gp - uv[1]);
		if (igv < 0 ) igv = 0 - igv;
		igv = igv * _MaskGlowSharpness;
		if (igv > 1 ) igv = 1;
		if (igv < 0 ) igv = 0;
		float gv = 1-igv;
		if (_MaskRainbow){
			int rt = _Time * 7000;
			_MaskGlowColor = normalize(shiftColor(half4(1,0,0,1),rt));
		}
		maskColor.rgb = (maskColor.rgb * igv) + (_MaskGlowColor.rgb * gv);
	}
	outColor.rgb = ( outColor.rgb * alphaDifference ) + (maskColor.rgb * maskColor.a);

	return outColor;
}

//keep in mind to always add lights. But multiply the sum to the final color. 
//This method applies ambient light from directional and lightprobes.
fixed4 applyLight(PIO process, fixed4 color) {
	/************************
	* Brightness / toon edge:
	************************/
#if defined(UNITY_PASS_FORWARDADD)
	//foward add lighting and details from pixel lights.
	float3 direction = normalize(_WorldSpaceLightPos0.xyz - process.worldPosition.xyz);
	float brightness = ToonDot(direction, process.worldNormal);
#else
	//Calculate light probes from foward base.
	float3 ambientDirection = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz; //do not normalize
	float brightness = ToonDot(ambientDirection, process.worldNormal.xyz);
	//needs to also consider L2 harmonics
	/*
	ambientDirection = unity_SHBr.xyz + unity_SHBg.xyz + unity_SHBb.xyz; //do not normalize
	brightness += ToonDot(ambientDirection, process.worldNormal.xyz);
	*/
	//just add the directional light.
	brightness += ToonDot(normalize(_WorldSpaceLightPos0.xyz), process.worldNormal.xyz);
#endif

	UNITY_LIGHT_ATTENUATION(attenuation, process, process.worldPosition);

	/************************
	* Color:
	************************/
#if defined(UNITY_PASS_FORWARDADD)
	//get directional color:
	half3 lightColor = _LightColor0.rgb * brightness * attenuation;
	color.rgb *= lightColor;
#else
	//ambient color (lightprobes):
	half3 lightColor = max( 0, ShadeSH9(float4(0, 0, 0, 1) ) );
	lightColor += max( 0, _LightColor0.rgb * attenuation);
#ifdef VERTEXLIGHT_ON
	lightColor += max( 0, process.vcolor);
#endif
	//add directional color, and apply brightness:
	if (brightness > 0) {
		color.rgb *= lightColor * brightness;
	}
	else 
	{ 
		//There is no lightprobes, so just take the light color which supplies ambient brightness
		color.rgb *= lightColor;
	}
#endif

	return color;
}