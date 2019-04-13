#ifndef HERO_INPUT_INCLUDED
#define HERO_INPUT_INCLUDED


//---------------------------------------
// 所有Keyword
// USE_DIFFUSE_WARP



#define USING_NORMAL_MAP 1
#define USING_TANGENT_TO_WORLD 1
#define USING_DIFFUSE_WARP defined(USE_DIFFUSE_WARP)
#define USING_SPECULAR_WARP defined(USE_SPECULAR_WARP)

#define USING_ALPHATEST defined(_CUSTOM_ALPHATEST_ON)
#define USING_ALPHA_REMULTIPLY defined(_ALPHAPREMULTIPLY_ON)

//---------------------------------------
// 所有变量声明

#if USING_ALPHATEST
half        _Cutoff;
#endif

half4       _Color;					// 作用于颜色贴图
sampler2D   _MainTex;				// 基础颜色贴图(ColorMap)

sampler2D	_TintByBaseMask;

sampler2D	_DiffuseMask;			// 未知mask

sampler3D	_ColorWarp;
fixed		_ColorWarpBlendToOne;

sampler2D	_BumpMap;
half		_BumpScale;

sampler2D	_SelfIllumMask;			// 自发光

sampler2D	_MetalnessMask;			// 金属度Mask

#if USING_DIFFUSE_WARP
sampler2D	_DiffuseWarp;
#endif
sampler2D	_DiffuseWarpMask;

half3		_SpecularColor;
half		_SpecularScale;
sampler2D   _SpecularMask;				// 高光mask
sampler2D   _SpecularExponentMask;		// 
half		_SpecularExponentIntensity;

#if USING_SPECULAR_WARP
sampler2D	_SpecularWarp;
#endif

half3		_RimLightColor;
sampler2D	_RimMask;
half		_RimLightScale;

sampler2D	_FresnelWarpColor;
sampler2D	_FresnelWarpRim;
sampler2D	_FresnelWarpSpec;

sampler2D	_Translucency;		// 用来控制半透的部分

samplerCUBE	_CubeMap;



//---------------------------------------
// 顶点输入

struct VertexInput
{
	float4 vertex   : POSITION;
	half3 normal    : NORMAL;
	float2 uv0      : TEXCOORD0;
	float2 uv1      : TEXCOORD1;		// Lightmap专用uv
#if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
	float2 uv2      : TEXCOORD2;
#endif
#if USING_TANGENT_TO_WORLD
	half4 tangent   : TANGENT;
#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

// 获得UV
float2 GetInputTexUVCoords(VertexInput v)
{
	float2 texcoord;
	texcoord.xy = v.uv0;
	return texcoord;
}

// 用于AlphaTest的透明数据
half GetInputAlphaTestValue(float2 uv)
{
	return tex2D(_MainTex, uv).a;
}

// 普通颜色贴图
half3 GetInputAlbedo(float2 texcoords)
{
	half3 albedo = tex2D(_MainTex, texcoords.xy).rgb;


	albedo = _Color.rgb * albedo;

	// 用于做效果的，可以先忽略
	/*
	#if _DETAIL
	#if (SHADER_TARGET < 30)
	// SM20: instruction count limitation
	// SM20: no detail mask
	half mask = 1;
	#else
	half mask = DetailMask(texcoords.xy);
	#endif
	half3 detailAlbedo = tex2D (_DetailAlbedoMap, texcoords.zw).rgb;
	#if _DETAIL_MULX2
	albedo *= LerpWhiteTo (detailAlbedo * unity_ColorSpaceDouble.rgb, mask);
	#elif _DETAIL_MUL
	albedo *= LerpWhiteTo (detailAlbedo, mask);
	#elif _DETAIL_ADD
	albedo += detailAlbedo * mask;
	#elif _DETAIL_LERP
	albedo = lerp (albedo, detailAlbedo, mask);
	#endif
	#endif
	*/
	return albedo;
}


fixed GetInputTintByBaseMask(float2 texcoords)
{
	return tex2D(_TintByBaseMask, texcoords).r;
}

#if USING_NORMAL_MAP

half3 GetInputNormalInTangentSpace(float2 texcoords)
{
	// 注意：UnpackScaleNormal函数限制，_BumpScale只起效在SHADER_TARGET >= 30
	half3 normalTangent = UnpackScaleNormal(tex2D(_BumpMap, texcoords.xy), _BumpScale);
	return normalTangent;
}

#endif // USING_NORMAL_MAP


#if USING_DIFFUSE_WARP

inline half3 GetInputDiffuseWarp(fixed NdotL, fixed diffuseWarpMask)
{
	return tex2D(_DiffuseWarp, fixed2(NdotL, diffuseWarpMask)).rgb;
}

#endif // USING_DIFFUSE_WARP


// 获得Diffuse Warp Mask
// 两个用途：
// 1.Diffuse Warp的采样UV中的V
// 2.Fresnel Color Warp 采样中的强度
inline fixed GetInputDiffuseWarpMask(float2 texcoords)
{
	return tex2D(_DiffuseWarpMask, texcoords).r;
}

inline fixed GetInputMetalnessMask(float2 texcoords)
{
	return tex2D(_MetalnessMask, texcoords).r;
}

// 获得Specular Mask
inline fixed GetInputSpecularMask(float2 texcoords)
{
#ifdef UNITY_COLORSPACE_GAMMA
	return GammaToLinearSpaceExact(tex2D(_SpecularMask, texcoords).r);

#else
	return tex2D(_SpecularMask, texcoords).r;
#endif
}

inline half3 GetInputSpecularColor(float2 texcoords)
{
	return _SpecularScale * lerp(GetInputAlbedo(texcoords) + GetInputMetalnessMask(texcoords), _SpecularColor, GetInputTintByBaseMask(texcoords)) * GetInputSpecularMask(texcoords);
}



// 获得Specular Exponent
inline half GetInputSpecularExponent(float2 texcoords)
{
	return tex2D(_SpecularExponentMask, texcoords).r * _SpecularExponentIntensity;
}

inline fixed GetInputSpecularExponentMask(float2 texcoords)
{
	return tex2D(_SpecularExponentMask, texcoords).r;
}

#if USING_SPECULAR_WARP

inline half3 GetInputSpecularWarp(fixed RdotL_or_NdotH, fixed specularExponentMask)
{
	return tex2D(_SpecularWarp, fixed2(RdotL_or_NdotH, specularExponentMask)).rgb;
}

#endif // USING_SPECULAR_WARP


inline half GetInputRimLightIntensity(float2 texcoords)
{
	return tex2D(_RimMask, texcoords).r * _RimLightScale * (1.0 - GetInputMetalnessMask(texcoords));
}

inline half3 GetInputRimLightColor(float2 texcoords)
{
	return _RimLightColor * GetInputRimLightIntensity(texcoords);
}




half3 GetInputSelfIllum(float2 uv, half3 albedo)
{
	return tex2D(_SelfIllumMask, uv).r * albedo;
}

half3 GetInputCubeMap(half3 worldReflect, fixed roughness)
{
	return texCUBElod(_CubeMap, float4(worldReflect, roughness * 8));
}


#endif // HERO_INPUT_INCLUDED