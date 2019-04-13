using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class AutoCreateDotaMaterial
{
    [MenuItem("Dota2/AutoCreateDotaMaterial", false)]
    public static void CreateDotaMaterial()
    {
        var select_obj = Selection.activeObject;
        if (select_obj == null)
        {
            return ;
        }
        var asset_path = AssetDatabase.GetAssetPath(select_obj);
        var serach_result = AssetDatabase.FindAssets("t:Texture *_color", new string[] { asset_path });
        if(serach_result == null || serach_result.Length <= 0)
        {
            return;
        }
        for(int i = 0; i < serach_result.Length; ++i)
        {
            CreateMaterial(serach_result[i]);
        }


        serach_result = AssetDatabase.FindAssets("t:Model", new string[] { asset_path });
        if (serach_result == null || serach_result.Length <= 0)
        {
            return;
        }
        RemapFBXMaterial(serach_result[0]);
    }

    [MenuItem("Dota2/AutoCreateDotaMaterial", true)]
    public static bool CreateDotaMaterial_Validate()
    {
        var select_obj = Selection.activeObject;
        if(select_obj == null)
        {
            return false;
        }
        var asset_path = AssetDatabase.GetAssetPath(select_obj);
        if(!System.IO.Directory.Exists(asset_path))
        {
            return false;
        }
        return true;
    }


    private static void RemapFBXMaterial(string fbx_guid)
    {
        var fbx_path = AssetDatabase.GUIDToAssetPath(fbx_guid);
        var fbx = AssetDatabase.LoadAssetAtPath<GameObject>(fbx_path);
        if (fbx == null)
        {
            return;
        }

        var importer = ModelImporter.GetAtPath(fbx_path) as ModelImporter;
        if(importer == null)
        {
            return;
        }

    }


    private static void CreateMaterial(string texture_guid)
    {
        var texture_path = AssetDatabase.GUIDToAssetPath(texture_guid);
        var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(texture_path);
        if(texture == null)
        {
            return;
        }
        var name = texture.name;
        var color_index = name.IndexOf("_color");
        var file_name = name.Substring(0, color_index);
        var file_path = System.IO.Path.GetDirectoryName(texture_path);
        var material_file_path = file_path + "/" + file_name + ".mat";

        var material = AssetDatabase.LoadAssetAtPath<Material>(material_file_path);
        if(material != null)
        {
            // 已存在
            AutoSetTexture(file_path + "/" + file_name, material);
            return;
        }

        var shader = Shader.Find("Hero/HeroBase");
        if(shader == null)
        {
            return;
        }
        material = new Material(shader);
        AssetDatabase.CreateAsset(material, material_file_path);

        AutoSetTexture(file_path + "/" + file_name, material);
    }

    private static void SetMaterialTexture(string prefix, Material target_mat, string property, string texture_name)
    {
        if (target_mat.HasProperty(property))
        {
            var texture = AssetDatabase.LoadAssetAtPath<Texture>(prefix + texture_name + ".tga");
            if (texture != null)
            {
                target_mat.SetTexture(property, texture);
            }
        }
    }

    private static void AutoSetTexture(string prefix, Material target_mat)
    {
        SetMaterialTexture(prefix, target_mat, "_MainTex", "_color");
        SetMaterialTexture(prefix, target_mat, "_BumpMap", "_normal");
        SetMaterialTexture(prefix, target_mat, "_RimMask", "_rimMask");
        SetMaterialTexture(prefix, target_mat, "_DiffuseWarp", "_diffuseWarp");
        SetMaterialTexture(prefix, target_mat, "_DiffuseWarpMask", "_diffuseWarpMask");
        SetMaterialTexture(prefix, target_mat, "_TintByBaseMask", "_tintByBaseMask");
        SetMaterialTexture(prefix, target_mat, "_SpecularMask", "_specularMask");
        SetMaterialTexture(prefix, target_mat, "_SpecularWarp", "_specularWarp");
        SetMaterialTexture(prefix, target_mat, "_SpecularExponentMask", "_specularExponent");
        SetMaterialTexture(prefix, target_mat, "_MetalnessMask", "_metalnessMask");
        SetMaterialTexture(prefix, target_mat, "_SelfIllumMask", "_selfIllumMask");
        SetMaterialTexture(prefix, target_mat, "_FresnelWarpColor", "_fresnelWarpColor");
        SetMaterialTexture(prefix, target_mat, "_FresnelWarpRim", "_fresnelWarpRim");
        SetMaterialTexture(prefix, target_mat, "_FresnelWarpSpec", "_fresnelWarpSpec");
        SetMaterialTexture(prefix, target_mat, "_Translucency", "_translucency");
        SetMaterialTexture(prefix, target_mat, "_Translucency", "_translucency");
        SetMaterialTexture(prefix, target_mat, "_CubeMap", "_cubeMap");


    }
}
