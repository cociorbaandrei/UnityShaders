#include "utils.rotate2.cginc"
sampler2D _CloudsTex;
sampler2D _StarTex;
sampler2D _StarPos;
sampler2D _CloudsTex_ST;
sampler2D _StarTex_ST;
sampler2D _StarPos_ST;
int _Stars;
float _XScatter;
float _YScatter;
float4 _Bounding;
float _CloudSpeed;
float _CloudStretch;
float _StarSize;

float4 cloudEffect(PIO process, float4 color, float a)
{
	fixed4 clouds;
	float2 clouduv;
	//layer 1
	clouduv = process.uv;
	clouduv.x *= _CloudStretch;
	clouduv.x += _Time.x * _CloudSpeed;
	clouds = tex2D(_CloudsTex, clouduv);
	clouds.rg *= 0;
	clouds *= a;
	color = lerp(color, clouds, clouds.a);
	//layer 2
	clouduv = process.uv;
	clouduv.x *= _CloudStretch;
	clouduv.x -= _Time.x * (_CloudSpeed/2);
	clouds = tex2D(_CloudsTex, clouduv);
	clouds.rb *= 2;
	clouds *= a;
	color = lerp(color, clouds, clouds.a);

	return color;
}

float4 starEffect(PIO process, float4 color) 
{
	float2 staruv;

	float sinRot;
	float cosRot;
	sincos(_Time.z, sinRot, cosRot);
	float2x2 srot = float2x2(cosRot, -sinRot, sinRot, cosRot);

	for (uint i = 0; i < _Stars; i++) {
		float2 pos;
		pos.x = ( i % 64 ) / 64.0f;
		pos.y = floor( i / 64 ) / 64.0f;
		pos += 0.0078125f;
		
		float4 ptex = tex2D(_StarPos, pos);
		float x = (ptex.y * 255.0f + ptex.x) / 255.0f;
		float y = (ptex.w * 255.0f + ptex.z) / 255.0f;

		x *= 1 - (_Bounding.x + _Bounding.z);
		x += _Bounding.x;
		y *= 1 - (_Bounding.y + _Bounding.w);
		y += _Bounding.y;
		float t = max(.1f, sin(_Time.z + i));
		float s = ( _StarSize / t );
		
		staruv;
		staruv.x = (x - process.uv.x);
		staruv.y = (y - process.uv.y);
		staruv = mul(srot, staruv);
		staruv *= s;
		staruv += .5f;
		//staruv = saturate(staruv);
		if (staruv.x > 0 && staruv.x < 1) {
			if (staruv.y > 0 && staruv.y < 1) {

				fixed4 star = tex2D(_StarTex, staruv);
				star.rgb += t;
				star.a *= saturate( 1-( abs(process.uv.y-.5f)*3));
				color += star * star.a;
			}
		}
	}
	

	return color;
}

fixed4 socksFrag(PIO process, uint isFrontFace : SV_IsFrontFace) : SV_Target
{
	//get the uv coordinates and set the base color.
	fixed4 color = tex2D(_MainTex, process.uv) * _Color;
	color = cloudEffect(process, color, 1);

	if (_NormalScale > 0) {
		applyNormalMap(process);
	}

	#ifdef MODE_TCUT
		clip(color.a - _TCut);
	#endif

	process = adjustProcess(process, isFrontFace);
	color = applyFresnel(process, color);
	color = applyLight(process, color);
	color = applyReflectionProbe(color, process, _Smoothness, _Reflectiveness);

	color = cloudEffect(process, color, .25f);
	color = starEffect(process, color);
	#if defined(MODE_TCUT) || defined(MODE_OPAQUE)
		color.a = 1;
	#endif

	return saturate(color);
}