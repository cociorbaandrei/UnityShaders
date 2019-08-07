sampler2D _BumpTex;
sampler2D _BumpTex_ST;
float4 _BumpTex_TexelSize;//for height/bump maps.
float _BumpScale;

struct fragOutput
{
	half4 color : SV_TARGET;
	float depth : SV_DEPTH;
};

float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}

PIO vertfx ( IO vertex ){
	PIO process;
	process.uv = vertex.uv;//TRANSFORM_TEX( vertex.uv, _MainTex );
	process.normal = normalize( vertex.normal );
	process.objectPosition = vertex.position;
	process.position = UnityObjectToClipPos(vertex.position);
	//reverse the draw position for the screen back to the world position for calculating view Direction.
	process.worldPosition = mul(unity_ObjectToWorld,vertex.position);
	process.worldNormal = normalize( UnityObjectToWorldNormal( process.normal ));
	process.extras.x = vertex.id;

	#ifdef BINORMAL_PER_FRAGMENT
		process.tangent = float4(UnityObjectToWorldDir(vertex.tangent.xyz), vertex.tangent.w);
	#else
		process.tangent = float4(UnityObjectToWorldDir(vertex.tangent),1);
		process.binormal = CreateBinormal(process.worldNormal, process.tangent.xyz, vertex.tangent.w);
	#endif

	half4 color;
	return process;
}

PIO adjustNormalsForBump( PIO process ){
	float3 tangentSpaceNormal =
		UnpackScaleNormal(tex2D(_BumpTex, process.uv), _BumpScale);
	#if defined(BINORMAL_PER_FRAGMENT)
		process.binormal = CreateBinormal(process.worldNormal, process.tangent.xyz, process.tangent.w);

	#endif

	process.worldNormal = normalize(
		tangentSpaceNormal.x * process.tangent +
		tangentSpaceNormal.y * process.binormal +
		tangentSpaceNormal.z * process.worldNormal
	);
	return process;
}

#if defined(FORWARDBASE)
fragOutput fragsfx( PIO process, uint isFrontFace : SV_IsFrontFace ) 
{
	fragOutput output;
	
	//adjust the normals for bump mapping.
	process = adjustNormalsForBump(process);
				
	//get the uv coordinates and set the base color.
	fixed4 color = tex2D( _MainTex, process.uv );
	
	process = adjustProcess(process, isFrontFace);
	color = applyFresnel(process, color);

	if ( !_MaskGlow ){
		color = applyMaskLayer(process, color);
	}

	//Apply baselights
	color = applyLight(process, color);

	if ( _MaskGlow ){
		color = applyMaskLayer(process, color);
	}

	float4 clipPos = UnityWorldToClipPos(process.worldPosition);
	output.depth = (clipPos.z / clipPos.w);

	output.color = color;
	return output;
}
#else 
fixed4 fragfxfa( PIO process, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	//adjust the normals for bump mapping.
	process = adjustNormalsForBump(process);

	fixed4 color = tex2D( _MainTex, process.uv );
	clip(color.a - _TCut);

	process = adjustProcess(process, isFrontFace);
	color = applyFresnel(process, color);

	process = adjustProcess(process, 0);
	float3 lightDirection = normalize(process.worldPosition - _WorldSpaceLightPos0.xyz);
	float brightness = saturate(dot(lightDirection,process.normal));// * unity_4LightAtten0;
	brightness = applyToonEdge(process, brightness);
	color.rgb = saturate( color.rgb * _LightColor0.rgb * brightness );

	return color;
}
#endif
