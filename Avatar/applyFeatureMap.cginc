//features1
float _Specular;
float _Smoothness;
float _Reflectiveness;
float _Height;
int _ReflectType;

void ApplyFeatureMap(PIO process) {
	float4 features = tex2D(_FeatureTex, process.featureUV + process.uvOffset);
	_Specular *= features.r;
	_Smoothness *= features.g;
	_Reflectiveness *= features.b;
	_Height *= features.a;
}