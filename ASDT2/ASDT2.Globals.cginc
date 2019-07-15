//general IO with Semantics
struct IO
{
	float4 position : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

//processed IO to be used by submethods
struct PIO
{
	float4 position : SV_POSITION; //the Position relative to the screen
	float3 normal : NORMAL; //The normal in screen space.
	float2 uv : TEXCOORD0; //uv coordinates
	float4 objectPosition : TEXCOORD1; //The position relative to the mesh origin.
	float3 worldNormal : TEXCOORD2; //The normal in world space.
	float3 worldPosition : TEXCOORD3; //the position relative to world origin.
	float3 viewDirection : TEXCOORD4; //The direction the camera is looking at the mesh.
};

struct Light
{
	float brightness;
	half3 color;
};
			
sampler2D _MainTex;
sampler2D _MainTex_ST;
float _Retract;
float4 _FresnelColor;
float _TCut;

//shading properties
float _ShadeRange;
float _ShadeSoftness;
float _ShadeMax;
float _ShadeMin;
float _ShadePivot;

PIO vert ( IO vertex ){
	PIO process;
	process.uv = vertex.uv;//TRANSFORM_TEX( vertex.uv, _MainTex );
	process.normal = normalize( vertex.normal );
	process.objectPosition = vertex.position;
	process.position = UnityObjectToClipPos(vertex.position);
	//reverse the draw position for the screen back to the world position for calculating view Direction.
	process.worldPosition = mul(unity_ObjectToWorld,vertex.position);
	process.worldNormal = normalize( UnityObjectToWorldNormal( process.normal ));

	return process;
}

PIO adjustProcess(PIO process, uint isFrontFace)
{
	if (!isFrontFace){
		process.normal = -process.normal;
	}
	//get the camera position to calculate view direction and then get the direction from the camera to the pixel.
	process.viewDirection = normalize(process.worldPosition - _WorldSpaceCameraPos);

	return process;
}

float applyToonEdge( PIO process, float brightness){
	//the attenuation should be the max amount of color value. 
	//To determine the end color value, All we need to do is determine the brightness.
	UNITY_LIGHT_ATTENUATION(attenuation,process,process.worldPosition);
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
	brightness = brightness * _ShadeRange + (1 - _ShadeRange);
	brightness = max(_ShadeMin,brightness);
	brightness = min(_ShadeMax,brightness);

	brightness = saturate(brightness * attenuation);
	return brightness;
}

fixed4 applyCut( fixed4 color ){
	if (color.a <= _TCut){
		color = -1;
	}
	return color;
}

fixed4 applyFresnel( PIO process, fixed4 inColor ){
	float3 viewDirection = normalize(process.worldPosition - _WorldSpaceCameraPos);
	float val = saturate(-dot(process.viewDirection, process.worldNormal));
	float rim = 1 - val * _Retract;
	rim= max(0,rim);
	rim *= _FresnelColor.a;
	float orim = 1 - rim;
	fixed4 color;
	inColor.rgb = (_FresnelColor * rim) + (inColor * orim);
	return inColor;
}