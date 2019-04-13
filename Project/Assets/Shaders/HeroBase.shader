Shader "Hero/HeroBase"
{
	Properties
	{
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2

		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		_Color("Main Color", Color) = (1,1,1,1)

		_MainTex("Color Map", 2D) = "white" {}

		_TintByBaseMask("Tint By Base Mask", 2D) = "black" {}

		_DiffuseWarpMask("Diffuse Warp Mask", 2D) = "black" {}
		_DiffuseWarp("Diffuse Warp", 2D) = "white" {}

		_ColorWarp("Color Warp", 3D) = "white" {}
		_ColorWarpBlendToOne("Color Warp Intensity", Range(0.0, 1.0)) = 0.0

		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Range(0, 5)) = 1

		_SelfIllumMask("SelfIllum Mask", 2D) = "black" {}

		_MetalnessMask("Metalness Mask", 2D) = "black" {}

		_SpecularColor("Specular Color", Color) = (1,1,1,1)
		_SpecularScale("Specular Scale", Range(0, 5)) = 1
		_SpecularMask("Specular Mask", 2D) = "black" {}
		_SpecularIntensity("Specular Intensity", Range(0.0, 5.0)) = 0.5
		_SpecularExponentMask("Specular Exponent", 2D) = "white" {}
		_SpecularExponentIntensity("Specular Exponent Intensity", Float) = 1.0


		_SpecularWarp("Specular Warp", 2D) = "black" {}


		_RimLightColor("Rim Light Color", Color) = (1,1,1,1)
		_RimMask("Rim Mask", 2D) = "black" {}
		_RimLightScale("Rim Light Scale", Range(0.0, 20.0)) = 1.0

		_FresnelWarpColor("Fresnel Color Warp", 2D) = "black" {}
		_FresnelWarpRim("Fresnel Rim Warp", 2D) = "black" {}
		_FresnelWarpSpec("Fresnel Specular Warp", 2D) = "black" {}

		_Translucency("Translucency Map", 2D) = "white" {}

		_CubeMap("Cube Map", Cube) = "Skybox" {}

		// Blending state
		[HideInInspector] _Mode("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__zw", Float) = 1.0
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		// ------------------------------------------------------------------
		//  Base forward pass (directional light, emission, lightmaps, ...)
		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }

			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]

			CGPROGRAM
			#pragma target 3.0

			#pragma shader_feature _ _CUSTOM_ALPHATEST_ON _CUSTOM_ALPHABLEND_ON _CUSTOM_ALPHAPREMULTIPLY_ON

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile_instancing


			#pragma vertex vertBase
            #pragma fragment fragBase
            #include "HeroCoreForward.cginc"
			ENDCG
		}
	}
}
