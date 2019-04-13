using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

internal class HeroShaderGUI : ShaderGUI
{
    static class Keyword
    {
        public const string UseDiffuseWrap = "USE_DIFFUSE_WARP";
        public const string UseSpecularWrap = "USE_SPECULAR_WARP";
    }

    static class Uniform
    {
        public static readonly int _DiffuseWarp = Shader.PropertyToID("_DiffuseWarp");
        public static readonly int _SpecularWarp = Shader.PropertyToID("_SpecularWarp");
    }


    public enum BlendMode
    {
        Opaque,
        Cutout,
        Fade,   // Old school alpha-blending mode, fresnel does not affect amount of transparency
        Transparent // Physically plausible transparency mode, implemented as alpha pre-multiply
    }

    private static class Styles
    {
        public static GUIContent[] blendNames = System.Array.ConvertAll(System.Enum.GetNames(typeof(BlendMode)), item => new GUIContent(item));

        public static GUIContent renderingMode = new GUIContent("Rendering Mode");
        public static string advancedText = "Advanced Options";
    }

    MaterialEditor m_MaterialEditor;

    bool m_FirstTimeApply = true;

    MaterialProperty blendMode = null;

    public void FindProperties(MaterialProperty[] props)
    {
        blendMode = FindProperty("_BlendMode", props);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        FindProperties(props); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;

        // Make sure that needed setup (ie keywords/renderqueue) are set up if we're switching some existing
        // material to a standard shader.
        // Do this before any GUI code has been issued to prevent layout issues in subsequent GUILayout statements (case 780071)
        if (m_FirstTimeApply)
        {
            MaterialChanged(material);
            m_FirstTimeApply = false;
        }

        ShaderPropertiesGUI(material);
    }

    public void ShaderPropertiesGUI(Material material)
    {
        // Use default labelWidth
        EditorGUIUtility.labelWidth = 0f;

        // Detect any changes to the material
        EditorGUI.BeginChangeCheck();
        {
            DoGUI_BlendModePopup();
            /*
            // Primary properties
            GUILayout.Label(Styles.primaryMapsText, EditorStyles.boldLabel);
            DoAlbedoArea(material);
            DoSpecularMetallicArea();
            DoNormalArea();
            m_MaterialEditor.TexturePropertySingleLine(Styles.heightMapText, heightMap, heightMap.textureValue != null ? heigtMapScale : null);
            m_MaterialEditor.TexturePropertySingleLine(Styles.occlusionText, occlusionMap, occlusionMap.textureValue != null ? occlusionStrength : null);
            m_MaterialEditor.TexturePropertySingleLine(Styles.detailMaskText, detailMask);
            DoEmissionArea(material);
            EditorGUI.BeginChangeCheck();
            m_MaterialEditor.TextureScaleOffsetProperty(albedoMap);
            if (EditorGUI.EndChangeCheck())
                emissionMap.textureScaleAndOffset = albedoMap.textureScaleAndOffset; // Apply the main texture scale and offset to the emission texture as well, for Enlighten's sake

            EditorGUILayout.Space();

            // Secondary properties
            GUILayout.Label(Styles.secondaryMapsText, EditorStyles.boldLabel);
            m_MaterialEditor.TexturePropertySingleLine(Styles.detailAlbedoText, detailAlbedoMap);
            m_MaterialEditor.TexturePropertySingleLine(Styles.detailNormalMapText, detailNormalMap, detailNormalMapScale);
            m_MaterialEditor.TextureScaleOffsetProperty(detailAlbedoMap);
            m_MaterialEditor.ShaderProperty(uvSetSecondary, Styles.uvSetLabel.text);

            // Third properties
            GUILayout.Label(Styles.forwardText, EditorStyles.boldLabel);
            if (highlights != null)
                m_MaterialEditor.ShaderProperty(highlights, Styles.highlightsText);
            if (reflections != null)
                m_MaterialEditor.ShaderProperty(reflections, Styles.reflectionsText);*/
        }
        if (EditorGUI.EndChangeCheck())
        {
            foreach (var obj in m_MaterialEditor.targets)
                MaterialChanged((Material)obj);
        }

        EditorGUILayout.Space();

        // NB renderqueue editor is not shown on purpose: we want to override it based on blend mode
        GUILayout.Label(Styles.advancedText, EditorStyles.boldLabel);
        m_MaterialEditor.EnableInstancingField();
        m_MaterialEditor.DoubleSidedGIField();
    }

    void DoGUI_BlendModePopup()
    {
        EditorGUI.showMixedValue = blendMode.hasMixedValue;
        var mode = (BlendMode)blendMode.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (BlendMode)EditorGUILayout.Popup(Styles.renderingMode, (int)mode, Styles.blendNames);
        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
            blendMode.floatValue = (float)mode;
        }

        EditorGUI.showMixedValue = false;
    }


    /// <summary>
    /// 统一设置keyword
    /// </summary>
    /// <param name="material"></param>
    static void SetMaterialKeywords(Material material)
    {
        // Note: keywords must be based on Material value not on MaterialProperty due to multi-edit & material animation
        // (MaterialProperty value might come from renderer material property block)

        // 检查是否使用DiffuseWarp
        SetKeyword(material, Keyword.UseDiffuseWrap, material.HasProperty(Uniform._DiffuseWarp) && material.GetTexture(Uniform._DiffuseWarp));

        // 检查是否使用SpecularWrap
        SetKeyword(material, Keyword.UseSpecularWrap, material.HasProperty(Uniform._SpecularWarp) && material.GetTexture(Uniform._SpecularWarp));
    }

    /// <summary>
    /// 材质属性改变时，必需调用一次
    /// </summary>
    /// <param name="material"></param>
    /// <param name="workflowMode"></param>
    static void MaterialChanged(Material material)
    {
        //SetupMaterialWithBlendMode(material, (BlendMode)material.GetFloat("_Mode"));

        SetMaterialKeywords(material);
    }

    #region Tools

    /// <summary>
    /// 设置key workd
    /// </summary>
    /// <param name="m"></param>
    /// <param name="keyword"></param>
    /// <param name="state"></param>
    static void SetKeyword(Material m, string keyword, bool state)
    {
        if (state)
            m.EnableKeyword(keyword);
        else
            m.DisableKeyword(keyword);
    }

    #endregion // Tools
}
