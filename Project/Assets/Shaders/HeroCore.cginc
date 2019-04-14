#ifndef HERO_CORE_INCLUDED
#define HERO_CORE_INCLUDED

#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityGlobalIllumination.cginc"

#include "HeroInput.cginc"



//-------------------------------------------------------------------------------------
// 计算向量归一配对函数
// 决定是在vertex还是pixel里计算归一化
half3 NormalizePerVertex (float3 n) // takes float to avoid overflow
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return normalize(n);
    #else
        return n; // will normalize per-pixel instead
    #endif
}

float3 NormalizePerPixel (float3 n)
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return n;
    #else
        return normalize((float3)n); // takes float to avoid overflow
    #endif
}

//-------------------------------------------------------------------------------------
// 计算世界空间法线

float3 PerPixelWorldNormal(float2 i_tex, float4 tangentToWorld[3])
{
#if USING_TANGENT_TO_WORLD && USING_NORMAL_MAP
    half3 tangent = tangentToWorld[0].xyz;
    half3 binormal = tangentToWorld[1].xyz;
    half3 normal = tangentToWorld[2].xyz;

	// 采样Normal贴图
    half3 normalTangent = GetInputNormalInTangentSpace(i_tex);
    float3 normalWorld = NormalizePerPixel(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
#else
	// 指令都这么少了，不用压榨normalize了
    float3 normalWorld = normalize(tangentToWorld[2].xyz);
#endif
    return normalWorld;
}


//-------------------------------------------------------------------------------------
// 计算sh配对函数
/*half3 ShadeSHPerVertex (half3 normal, half3 ambient)
{
    #if UNITY_SAMPLE_FULL_SH_PER_PIXEL
        // Completely per-pixel
        // nothing to do here
    #elif (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        // Completely per-vertex
        ambient += max(half3(0,0,0), ShadeSH9 (half4(normal, 1.0)));
    #else
        // L2 per-vertex, L0..L1 & gamma-correction per-pixel

        // NOTE: SH data is always in Linear AND calculation is split between vertex & pixel
        // Convert ambient to Linear and do final gamma-correction at the end (per-pixel)
        #ifdef UNITY_COLORSPACE_GAMMA
            ambient = GammaToLinearSpace (ambient);
        #endif
        ambient += SHEvalLinearL2 (half4(normal, 1.0));     // no max since this is only L2 contribution
    #endif

    return ambient;
}

half3 ShadeSHPerPixel (half3 normal, half3 ambient, float3 worldPos)
{
    half3 ambient_contrib = 0.0;

    #if UNITY_SAMPLE_FULL_SH_PER_PIXEL
        // Completely per-pixel
        #if UNITY_LIGHT_PROBE_PROXY_VOLUME
            if (unity_ProbeVolumeParams.x == 1.0)
                ambient_contrib = SHEvalLinearL0L1_SampleProbeVolume(half4(normal, 1.0), worldPos);
            else
                ambient_contrib = SHEvalLinearL0L1(half4(normal, 1.0));
        #else
            ambient_contrib = SHEvalLinearL0L1(half4(normal, 1.0));
        #endif

            ambient_contrib += SHEvalLinearL2(half4(normal, 1.0));

            ambient += max(half3(0, 0, 0), ambient_contrib);

        #ifdef UNITY_COLORSPACE_GAMMA
            ambient = LinearToGammaSpace(ambient);
        #endif
    #elif (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        // Completely per-vertex
        // nothing to do here. Gamma conversion on ambient from SH takes place in the vertex shader, see ShadeSHPerVertex.
    #else
        // L2 per-vertex, L0..L1 & gamma-correction per-pixel
        // Ambient in this case is expected to be always Linear, see ShadeSHPerVertex()
        #if UNITY_LIGHT_PROBE_PROXY_VOLUME
            if (unity_ProbeVolumeParams.x == 1.0)
                ambient_contrib = SHEvalLinearL0L1_SampleProbeVolume (half4(normal, 1.0), worldPos);
            else
                ambient_contrib = SHEvalLinearL0L1 (half4(normal, 1.0));
        #else
            ambient_contrib = SHEvalLinearL0L1 (half4(normal, 1.0));
        #endif

        ambient = max(half3(0, 0, 0), ambient+ambient_contrib);     // include L2 contribution in vertex shader before clamp.
        #ifdef UNITY_COLORSPACE_GAMMA
            ambient = LinearToGammaSpace (ambient);
        #endif
    #endif

    return ambient;
}*/

//-------------------------------------------------------------------------------------
// 预乘Alpha
/*inline half3 PreMultiplyAlpha (half3 diffColor, half alpha, half oneMinusReflectivity, out half outModifiedAlpha)
{
    #if USING_ALPHA_REMULTIPLY
        // NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)

        // Transparency 'removes' from Diffuse component
        diffColor *= alpha;

        #if (SHADER_TARGET < 30)
            // SM2.0: instruction count limitation
            // Instead will sacrifice part of physically based transparency where amount Reflectivity is affecting Transparency
            // SM2.0: uses unmodified alpha
            outModifiedAlpha = alpha;
        #else
            // Reflectivity 'removes' from the rest of components, including Transparency
            // outAlpha = 1-(1-alpha)*(1-reflectivity) = 1-(oneMinusReflectivity - alpha*oneMinusReflectivity) =
            //          = 1-oneMinusReflectivity + alpha*oneMinusReflectivity
            outModifiedAlpha = 1-oneMinusReflectivity + alpha*oneMinusReflectivity;
        #endif
    #else // USING_ALPHA_REMULTIPLY
        outModifiedAlpha = alpha;
    #endif // USING_ALPHA_REMULTIPLY
    return diffColor;
}*/

//-------------------------------------------------------------------------------------
// 构建TBN
/*half3x3 CreateTangentToWorldPerVertex(half3 normal, half3 tangent, half tangentSign)
{
    // For odd-negative scale transforms we need to flip the sign
    half sign = tangentSign * unity_WorldTransformParams.w;
    half3 binormal = cross(normal, tangent) * sign;
    return half3x3(tangent, binormal, normal);
}*/

//-------------------------------------------------------------------------------------
// 处理alpha

half4 OutputForward(half4 output, half alphaFromSurface)
{
#if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
	output.a = alphaFromSurface;
#else
	UNITY_OPAQUE_ALPHA(output.a);
#endif
	return output;
}


//-------------------------------------------------------------------------------------
// 向前渲染的Vertex GI
// LIGHTMAP_ON Unity内置
// UNITY_SHOULD_SAMPLE_SH Unity内置
// VERTEXLIGHT_ON Unity内置
inline half4 VertexGIForward(VertexInput v, float3 posWorld, half3 normalWorld)
{
    half4 ambientOrLightmapUV = 0;
    // Static lightmaps
    #ifdef LIGHTMAP_ON
        ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
        ambientOrLightmapUV.zw = 0;
    // Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
    #elif UNITY_SHOULD_SAMPLE_SH
        #ifdef VERTEXLIGHT_ON
            // Approximated illumination from non-important point lights
            ambientOrLightmapUV.rgb = Shade4PointLights (
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, posWorld, normalWorld);
        #endif

        ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, ambientOrLightmapUV.rgb);
    #endif

    #ifdef DYNAMICLIGHTMAP_ON
        ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif

    return ambientOrLightmapUV;
}

//-------------------------------------------------------------------------------------
// Frag里使用的通用数据结构
struct FragmentCommonData
{
    half3 diffColor;
	half3 specColor;
    // Note: smoothness & oneMinusReflectivity for optimization purposes, mostly for DX9 SM2.0 level.
    // Most of the math is being done on these (1-x) values, and that saves a few precious ALU slots.
    half oneMinusReflectivity, smoothness;
    float3 normalWorld;
    float3 eyeVec;
    half alpha;
    float3 posWorld;			// 像素世界空间位置(主要是阴影使用)

	fixed diffuseWarpMask;		// 有两个用途
	fixed metalnessMask;

#if USING_SPECULAR_WARP
	fixed specularExponentMask;	// 高光系数mask
#else // USING_SPECULAR_WARP
	half specularExponent;		// 高光强度
#endif

	half3 rimLightColor;

#if UNITY_STANDARD_SIMPLE
    half3 reflUVW;
#endif

#if UNITY_STANDARD_SIMPLE
    half3 tangentSpaceNormal;
#endif
};


// parallax transformed texcoord is used to sample occlusion
inline FragmentCommonData FragmentSetup (float2 i_texUV, float3 i_eyeVec, half3 i_viewDirForParallax, float4 tangentToWorld[3])
{
	// 先做AlphaTest
    half alpha = GetInputAlphaTestValue(i_texUV.xy);
    #if USING_ALPHATEST
        clip (alpha - _Cutoff);
    #endif

    FragmentCommonData o = (FragmentCommonData)0;
	o.diffColor = GetInputAlbedo(i_texUV);
	o.specColor = GetInputSpecularColor(i_texUV);
    o.normalWorld = PerPixelWorldNormal(i_texUV, tangentToWorld);
    o.eyeVec = NormalizePerPixel(i_eyeVec);
	o.posWorld = half3(tangentToWorld[0].w, tangentToWorld[1].w, tangentToWorld[2].w);
	o.diffuseWarpMask = GetInputDiffuseWarpMask(i_texUV);
	o.metalnessMask = GetInputMetalnessMask(i_texUV);
#if USING_SPECULAR_WARP
	o.specularExponentMask = GetInputSpecularExponentMask(i_texUV);
#else
	o.specularExponent = GetInputSpecularExponent(i_texUV);
#endif
	o.rimLightColor = GetInputRimLightColor(i_texUV);

    // NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
    o.diffColor = PreMultiplyAlpha (o.diffColor, alpha, o.oneMinusReflectivity, /*out*/ o.alpha);
    return o;
}

//-------------------------------------------------------------------------------------
// BRDF

/*inline half OneMinusReflectivityFromMetallic(half metallic)
{
    // We'll need oneMinusReflectivity, so
    //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
    // store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
    //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
    //                  = alpha - metallic * alpha
    half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}*/


/*inline half3 DiffuseAndSpecularFromMetallic (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
{
	// 电介质的电阻率一般都很高,被称为绝缘体。
	// unity_ColorSpaceDielectricSpec = 里面存的是Unity选用的电介质反射率，alpha通道是1-dielectricSpec
	// unity_ColorSpaceDielectricSpec = 定义了绝缘体的高光颜色和反射率,不完全为0,是一个经验值。
    specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
    oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
    return albedo * oneMinusReflectivity;
}*/

//FragmentCommonData SetupBRDFInput(float2 i_texUV)
//{
//half2 metallicGloss = MetallicGloss(i_tex.xy);
//    half metallic = metallicGloss.x;
//    half smoothness = metallicGloss.y; // this is 1 minus the square root of real roughness m.

//    half oneMinusReflectivity;
//    half3 specColor;
//    half3 diffColor = DiffuseAndSpecularFromMetallic (Albedo(i_tex), metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

//    FragmentCommonData o = (FragmentCommonData)0;
//    o.diffColor = diffColor;
//    o.specColor = specColor;
//    o.oneMinusReflectivity = oneMinusReflectivity;
//    o.smoothness = smoothness;
//    return o;
//}

// ------------------------------------------------------------------
// 光照

// 构建主光源参数
UnityLight MainLight()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

// ------------------------------------------------------------------
// GI
inline UnityGI FragmentGI(FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light)
{
	UnityGIInput d;
	d.light = light;
	d.worldPos = s.posWorld;
	d.worldViewDir = -s.eyeVec;
	d.atten = atten;
#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
	d.ambient = 0;
	d.lightmapUV = i_ambientOrLightmapUV;
#else
	d.ambient = i_ambientOrLightmapUV.rgb;
	d.lightmapUV = 0;
#endif

	d.probeHDR[0] = unity_SpecCube0_HDR;
	d.probeHDR[1] = unity_SpecCube1_HDR;
#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
	d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
#endif
#ifdef UNITY_SPECCUBE_BOX_PROJECTION
	d.boxMax[0] = unity_SpecCube0_BoxMax;
	d.probePosition[0] = unity_SpecCube0_ProbePosition;
	d.boxMax[1] = unity_SpecCube1_BoxMax;
	d.boxMin[1] = unity_SpecCube1_BoxMin;
	d.probePosition[1] = unity_SpecCube1_ProbePosition;
#endif


		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.smoothness, -s.eyeVec, s.normalWorld, s.specColor);
		// Replace the reflUVW if it has been compute in Vertex shader. Note: the compiler will optimize the calcul in UnityGlossyEnvironmentSetup itself
#if UNITY_STANDARD_SIMPLE
		g.reflUVW = s.reflUVW;
#endif
		return UnityGlobalIllumination(d, occlusion, s.normalWorld, g);
}


half4 Dota2Shader(FragmentCommonData s, UnityLight light, UnityIndirect gi)
{
	half3 finalColor;
		
	float3 viewDir = -s.eyeVec;
	float3 normal = s.normalWorld;

	// 半角高光角度：使用入射光线【LightDir】和视线[ViewDir]的中间平均值，即半角向量，
	float3 halfDir = Unity_SafeNormalize(float3(light.dir) + viewDir);

	float NdotH = saturate(dot(normal, halfDir));
	half LdotH = saturate(dot(light.dir, halfDir));
	half NdotV = abs(dot(normal, viewDir));
	half NdotL = saturate(dot(normal, light.dir));
	fixed halfLambert = dot(normal, light.dir) * 0.5 + 0.5;


	// ****** Fresnel ******
	half3 fresnel = Pow5(1.0 - NdotV);
	fresnel.b = 1.0 - fresnel.b;

	// ****** Diffuse lighting ******
	half3 diffuseTerm;
	// Diffuse warp
#if USING_DIFFUSE_WARP
	half3 diffuseWarp = GetInputDiffuseWarp(halfLambert, diffuseWarpMask);
	diffuseTerm = diffuseWarp;
#else // USING_DIFFUSE_WARP
	diffuseTerm = halfLambert;
#endif // USING_DIFFUSE_WARP

	finalColor = s.diffColor * (gi.diffuse + light.color * diffuseTerm);

	// ****** Specular lighting ******
	half3 specularTerm;
	// Specular warp
#if USING_SPECULAR_WARP
	half3 specularWarp = GetInputSpecularWarp(NdotH, s.specularExponentMask);
	specularTerm = specularWarp;
#else // USING_SPECULAR_WARP
	// R = reflect( V, N )
	// 反射光方向向量R可以通过入射方向L（从顶点指向光源）和物体表面法向量L求出。R + L = (2N·L)N
	// R = 2 * N * (NdotL) - L
	// Phong: pow(RdotV, shininess)
	// BlinnPhong:  pow(NdotH, shininess)
	specularTerm = NdotL * pow(NdotH, s.specularExponent);
	// specularTerm * NdotL can be NaN on Metal in some cases, use max() to make sure it's a sane value
	specularTerm = max(0, specularTerm);
#endif // USING_SPECULAR_WARP


	// ****** Specular ******
	half3 specular = (specularTerm * fresnel.b) * (light.color * s.specColor * gi.specular);
	finalColor += specular;


	// ****** Metalness ******
	finalColor = lerp(finalColor, specular, s.metalnessMask);
	
	
	// ****** Rim lighting ******
	half rimTerm;
	rimTerm = fresnel.r * saturate(dot(UNITY_MATRIX_V[1], normal));
	finalColor += rimTerm * s.rimLightColor;


	return half4(finalColor, 1);
}


// ------------------------------------------------------------------
//  Base forward pass (directional light, emission, lightmaps, ...)

// 从vertex输出到frag
struct VertexOutputForwardBase
{
	UNITY_POSITION(pos);
	float2 texUV                          : TEXCOORD0;		// 颜色贴图的uv
	float4 eyeVec                         : TEXCOORD1;    // eyeVec.xyz | fogCoord
	float4 tangentToWorldAndPackedData[3] : TEXCOORD2;    // [3x3:tangentToWorld | worldPos]
	half4 ambientOrLightmapUV             : TEXCOORD5;    // SH or Lightmap UV
	UNITY_LIGHTING_COORDS(6, 7)

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

VertexOutputForwardBase Internal_VertForwardBase(VertexInput v)
{
	// Unity shaderlab 编写头 
	UNITY_SETUP_INSTANCE_ID(v);
	VertexOutputForwardBase o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBase, o);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	// 世界空间位置
	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.tangentToWorldAndPackedData[0].w = posWorld.x;
	o.tangentToWorldAndPackedData[1].w = posWorld.y;
	o.tangentToWorldAndPackedData[2].w = posWorld.z;

	// 裁剪空间顶点位置
	o.pos = UnityObjectToClipPos(v.vertex);

	o.texUV = GetInputTexUVCoords(v);
	o.eyeVec.xyz = NormalizePerVertex(posWorld.xyz - _WorldSpaceCameraPos);
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
#if USING_TANGENT_TO_WORLD
	float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	// TBN
	float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
	o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
	o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
	o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
#else
	o.tangentToWorldAndPackedData[0].xyz = 0;
	o.tangentToWorldAndPackedData[1].xyz = 0;
	o.tangentToWorldAndPackedData[2].xyz = normalWorld;
#endif

	//We need this for shadow receving
	UNITY_TRANSFER_LIGHTING(o, v.uv1);

	o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);

	UNITY_TRANSFER_FOG_COMBINED_WITH_EYE_VEC(o, o.pos);
	return o;
}


half4 Internal_FragForwardBase (VertexOutputForwardBase i)
{
	// Unity内置LOD过渡动画
    UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

	FragmentCommonData s = FragmentSetup(i.texUV, i.eyeVec.xyz, half3(0, 0, 0), i.tangentToWorldAndPackedData);

    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    UnityLight mainLight = MainLight ();
    UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);

    half occlusion = 1;
    UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

    half4 c = Dota2Shader (s, gi.light, gi.indirect);
    c.rgb += GetInputSelfIllum(i.texUV.xy, s.diffColor);

    UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
    UNITY_APPLY_FOG(_unity_fogCoord, c.rgb);
    return OutputForward (c, s.alpha);
}



// ------------------------------------------------------------------
//  Additive forward pass (one light per pass)

struct VertexOutputForwardAdd
{
    UNITY_POSITION(pos);
    float2 texUV                          : TEXCOORD0;
    float4 eyeVec                       : TEXCOORD1;    // eyeVec.xyz | fogCoord
    float4 tangentToWorldAndLightDir[3] : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:lightDir]
    float3 posWorld                     : TEXCOORD5;
    UNITY_LIGHTING_COORDS(6, 7)

    UNITY_VERTEX_OUTPUT_STEREO
};


VertexOutputForwardAdd Internal_VertForwardAdd (VertexInput v)
{
    UNITY_SETUP_INSTANCE_ID(v);
    VertexOutputForwardAdd o;
    UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAdd, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
    o.pos = UnityObjectToClipPos(v.vertex);

    o.texUV = GetInputTexUVCoords(v);
    o.eyeVec.xyz = NormalizePerVertex(posWorld.xyz - _WorldSpaceCameraPos);
    o.posWorld = posWorld.xyz;
    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    #ifdef _TANGENT_TO_WORLD
        float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

        float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
        o.tangentToWorldAndLightDir[0].xyz = tangentToWorld[0];
        o.tangentToWorldAndLightDir[1].xyz = tangentToWorld[1];
        o.tangentToWorldAndLightDir[2].xyz = tangentToWorld[2];
    #else
        o.tangentToWorldAndLightDir[0].xyz = 0;
        o.tangentToWorldAndLightDir[1].xyz = 0;
        o.tangentToWorldAndLightDir[2].xyz = normalWorld;
    #endif
    //We need this for shadow receiving and lighting
    UNITY_TRANSFER_LIGHTING(o, v.uv1);

    float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
    #ifndef USING_DIRECTIONAL_LIGHT
        lightDir = NormalizePerVertexNormal(lightDir);
    #endif
    o.tangentToWorldAndLightDir[0].w = lightDir.x;
    o.tangentToWorldAndLightDir[1].w = lightDir.y;
    o.tangentToWorldAndLightDir[2].w = lightDir.z;

    #ifdef _PARALLAXMAP
        TANGENT_SPACE_ROTATION;
        o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
    #endif

    UNITY_TRANSFER_FOG_COMBINED_WITH_EYE_VEC(o, o.pos);
    return o;
}


#endif // HERO_CORE_INCLUDED