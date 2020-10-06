#pragma once
PIO vert( IO v ){
	PIO process;
	process.uv.xy = v.uv.xy;
	process.uv = TRANSFORM_TEX(v.uv, _MainTex);
	process.detailUV = TRANSFORM_TEX(v.uv, _DetailTex);
	process.normalUV = TRANSFORM_TEX(v.uv, _NormalTex);
	process.featureUV = TRANSFORM_TEX(v.uv, _FeatureTex);
	process.normal = normalize( v.normal );
	process.objectPosition = v.vertex;
	process.pos = UnityObjectToClipPos( v.vertex );

	//reverse the draw position for the screen back to the world position for calculating view Direction.
	process.worldPosition = mul( unity_ObjectToWorld, v.vertex ).xyz;
	process.worldNormal = normalize( UnityObjectToWorldNormal( process.normal ) );
	process.extras.x = v.id;
	process.viewDirection = normalize(process.worldPosition - _WorldSpaceCameraPos.xyz);
#if !defined(UNITY_PASS_SHADOWCASTER)
	TRANSFER_SHADOW(process)
#endif
#if defined(LIGHTMAP_ON)
	process.lmuv = v.lmuv.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif

#ifdef VERTEXLIGHT_ON
	process.vcolor = Shade4PointLightsFixed(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb,
		unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, process.worldPosition, process.worldNormal
	);
#endif
	process.tangent = v.tangent;
	process.worldTangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

	return process;
}
