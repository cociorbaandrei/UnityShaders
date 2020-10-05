#if UNITY_EDITOR
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Linq;

public class SkuldsAvatarShaderEditor : ShaderGUI
{
    MaterialEditor materialEditor;
    MaterialProperty[] properties;
    Material material;
    GUIStyle skuldHeader = null;


    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.materialEditor = materialEditor;
        this.properties = properties;
        this.material = materialEditor.target as Material;
        if (skuldHeader == null)
        {
            skuldHeader = EditorStyles.foldout;
            skuldHeader.fontStyle = FontStyle.Bold;
            skuldHeader.fontSize = 14;
            skuldHeader.normal.textColor = new Color(.25f, 0, .5f);
            skuldHeader.margin.bottom = 5;
            skuldHeader.margin.top = 5;
        }

        BaseOptions();
        DetailOptions();
        BRDFOptions();
        LightOptions();
        RenderOptions();
        FeatureMapCreator();
    }



    bool BRDFGroup = false;
    public enum ReflectType { Lerp, Multiply, Add }
    void BRDFOptions()
    {
        BRDFGroup = EditorGUILayout.Foldout(BRDFGroup, "Features", skuldHeader);
        if (BRDFGroup)
        {

            //SSRH
            EditorGUILayout.LabelField("Feature Texture Map:", EditorStyles.boldLabel);
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty features = FindProperty("_FeatureTex", properties);
            materialEditor.TextureProperty(features, "Texture:");

            MaterialProperty specular = FindProperty("_Specular", properties);
            materialEditor.RangeProperty(specular, "Specular Scale:");
            MaterialProperty smoothness = FindProperty("_Smoothness", properties);
            materialEditor.RangeProperty(smoothness, "Smoothness Scale:");
            MaterialProperty reflect = FindProperty("_Reflectiveness", properties);
            materialEditor.RangeProperty(reflect, "Reflective Scale:");
            MaterialProperty height = FindProperty("_Height", properties);
            materialEditor.RangeProperty(height, "Height Scale:");
            EditorGUILayout.HelpBox("The feature texture is an rgba texture with the following mapping: specular, smoothness, reflective, and height.", MessageType.Info);
            EditorGUILayout.EndVertical();

            //normals
            EditorGUILayout.LabelField("Normals:", EditorStyles.boldLabel);
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty normals = FindProperty("_NormalTex", properties);
            materialEditor.TextureProperty(normals, "Texture:");
            MaterialProperty normalScale = FindProperty("_NormalScale", properties);
            materialEditor.RangeProperty(normalScale, "Scale:");
            EditorGUILayout.EndVertical();

            EditorGUILayout.LabelField("Specular Extended:", EditorStyles.boldLabel);
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty specColor = FindProperty("_SpecularColor", properties);
            materialEditor.ColorProperty(specColor, "Color:");
            MaterialProperty specSize = FindProperty("_SpecularSize", properties);
            materialEditor.RangeProperty(specSize, "Size:");
            MaterialProperty specRef = FindProperty("_SpecularReflection", properties);
            materialEditor.RangeProperty(specRef, "Reflection Balance:");
            EditorGUILayout.EndVertical();

            EditorGUILayout.LabelField("Fresnel:", EditorStyles.boldLabel);
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty color = FindProperty("_FresnelColor", properties);
            materialEditor.ColorProperty(color, "Color:");
            MaterialProperty retract = FindProperty("_FresnelRetract", properties);
            materialEditor.RangeProperty(retract, "Retract:");
            EditorGUILayout.EndVertical();

            EditorGUILayout.LabelField("Other:", EditorStyles.boldLabel);
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            CreatePopupFromProperty("Reflection Type:", "_ReflectType", typeof(ReflectType));
            EditorGUILayout.EndVertical();
        }
    }

    bool featureMapGroup = false;
    public static Texture2D specTex;
    public static Texture2D smoothTex;
    public static Texture2D reflectTex;
    public static Texture2D heightTex;
    public static Texture2D resultTex;
    void FeatureMapCreator()
    {
        featureMapGroup = EditorGUILayout.Foldout(featureMapGroup, "Create Feature Map", skuldHeader);
        if (featureMapGroup)
        {
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            specTex = (Texture2D)EditorGUILayout.ObjectField("Specular Texture:", specTex, typeof(Texture2D),true);
            smoothTex = (Texture2D)EditorGUILayout.ObjectField("Smooth Texture:", smoothTex, typeof(Texture2D), true);
            reflectTex = (Texture2D)EditorGUILayout.ObjectField("Reflection Texture:", reflectTex, typeof(Texture2D), true);
            heightTex = (Texture2D)EditorGUILayout.ObjectField("Height Texture:", heightTex, typeof(Texture2D), true);
            resultTex = (Texture2D)EditorGUILayout.ObjectField("Feature Texture (Create a transparent texture):", resultTex, typeof(Texture2D), true);
            EditorGUILayout.HelpBox("These textures need to be grayscale, if not, only the red channel will be used.\n Warning: Result texture is required, and will be written to. Create an empty image at the desired resolution and place it result slot.", MessageType.Info);
            EditorGUILayout.EndVertical();
            if ( GUILayout.Button("Apply to Feature Texture") )
            {
                MakeFeatureTexture();
            }
        }
    }

    float GetValue(int i, Texture2D tex)
    {
        int ix = i % resultTex.width;
        int iy = i / resultTex.width;
        int x = (int)(((float)ix / (float)resultTex.width) * resultTex.width);
        int y = (int)(((float)iy / (float)resultTex.height) * resultTex.height);
        if (tex)
        {
            Color col = tex.GetPixel(x, y);
            return col.r;
        } else
        {
            return 1.0f;
        }
    }

    void MakeFeatureTexture()
    {
        if (resultTex == null)
        {
            Debug.LogError("Cannot create texture, no result texture specified.");
        }
        Color[] colors = resultTex.GetPixels();
        for ( int i = 0; i < colors.Length; i++)
        {
            Color color = new Color(
                GetValue(i, specTex),
                GetValue(i, smoothTex),
                GetValue(i, reflectTex),
                GetValue(i, heightTex)
            );
            colors[i] = color;
        }
        Texture2D outputTex = new Texture2D(resultTex.width, resultTex.height, TextureFormat.RGBAFloat,false);
        outputTex.SetPixels(colors);
        outputTex.Apply();
        System.IO.File.WriteAllBytes(
            UnityEditor.AssetDatabase.GetAssetPath(resultTex),
            outputTex.EncodeToPNG()
        );
        EditorUtility.SetDirty(resultTex);
        Debug.Log("Saved Features Texture");
    }




    bool DetailGroup = false;
    void DetailOptions()
    {
        DetailGroup = EditorGUILayout.Foldout(DetailGroup, "Detail Layer", skuldHeader);
        if (DetailGroup)
        {
            bool enabledDetails = CreateToggleFromProperty("Enabled:", "_DetailLayer");
            if (enabledDetails)
            {
                EditorGUILayout.BeginVertical(EditorStyles.textArea);
                bool unlit = CreateToggleFromProperty("Unlit:", "_DetailUnlit");
                MaterialProperty tex = FindProperty("_DetailTex", properties);
                materialEditor.TextureProperty(tex, "Texture:");
                MaterialProperty color = FindProperty("_DetailColor", properties);
                materialEditor.ColorProperty(color, "Color:");
                MaterialProperty hue = FindProperty("_DetailHue", properties);
                materialEditor.RangeProperty(hue, "Hue:");
                MaterialProperty saturation = FindProperty("_DetailSaturation", properties);
                materialEditor.RangeProperty(saturation, "Saturation:");
                MaterialProperty value = FindProperty("_DetailValue", properties);
                materialEditor.RangeProperty(value, "Value:");
                EditorGUILayout.EndVertical();
                bool glow = CreateToggleFromProperty("Glow:", "_DetailGlow");
                if (glow)
                {
                    EditorGUILayout.BeginVertical(EditorStyles.textArea);
                    MaterialProperty glowColor = FindProperty("_DetailGlowColor", properties);
                    materialEditor.ColorProperty(glowColor, "Color:");
                    CreateToggleFromProperty("Rainbow Effect:", "_DetailRainbow");
                    MaterialProperty glowSpeed = FindProperty("_DetailGlowSpeed", properties);
                    materialEditor.RangeProperty(glowSpeed, "Speed:");
                    MaterialProperty glowSharpness = FindProperty("_DetailGlowSharpness", properties);
                    materialEditor.RangeProperty(glowSharpness, "Sharpness:");
                    EditorGUILayout.EndVertical();
                }
            }
        }
     }



    bool lightGroup = false;
    void LightOptions()
    {
        lightGroup = EditorGUILayout.Foldout(lightGroup, "Lighting", skuldHeader);
        if (lightGroup)
        {
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty range = FindProperty("_ShadeRange", properties);
            materialEditor.RangeProperty(range, "Range:");
            MaterialProperty softness = FindProperty("_ShadeSoftness", properties);
            materialEditor.RangeProperty(softness, "Softness:");
            MaterialProperty pivot = FindProperty("_ShadePivot", properties);
            materialEditor.RangeProperty(pivot, "Center:");
            MaterialProperty min = FindProperty("_ShadeMin", properties);
            materialEditor.RangeProperty(min, "Minimum:");
            MaterialProperty max = FindProperty("_ShadeMax", properties);
            materialEditor.RangeProperty(max, "Maximum:");
            EditorGUILayout.EndVertical();
        }
    }



    bool baseGroup = false;
    void BaseOptions()
    {
        baseGroup = EditorGUILayout.Foldout(baseGroup, "Base Texture and Color", skuldHeader);
        if (baseGroup)
        {
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty tex = FindProperty("_MainTex", properties);
            materialEditor.TextureProperty(tex, "Texture:");
            MaterialProperty color = FindProperty("_Color", properties);
            materialEditor.ColorProperty(color, "Color:");
            MaterialProperty hue = FindProperty("_Hue", properties);
            materialEditor.RangeProperty(hue, "Hue:");
            MaterialProperty saturation = FindProperty("_Saturation", properties);
            materialEditor.RangeProperty(saturation, "Saturation:");
            MaterialProperty value = FindProperty("_Value", properties);
            materialEditor.RangeProperty(value, "Value:");
            EditorGUILayout.EndVertical();
        }
    }



    bool renderGroup = false;
    public enum RenderType { Opaque, Transparent, TransparentCutout, Background, Overlay, TreeOpaque, TreeTransparentCutout, TreeBillboard, Grass, GrassBillboard };
    void RenderOptions()
    {
        renderGroup = EditorGUILayout.Foldout( renderGroup, "Rendering", skuldHeader);
        if (renderGroup)
        {
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            //render Type:
            RenderType renderType = (RenderType)CreatePopupFromProperty("Render Type:", "_RenderType", typeof(RenderType));
            if (renderType == RenderType.TransparentCutout)
            {
                MaterialProperty tCut = FindProperty("_TCut", properties);
                materialEditor.RangeProperty(tCut, "Transparent Cutout:");
            }
            material.SetOverrideTag("RenderType", renderType.ToString());
            //blending,etc:
            CreatePopupFromProperty("Source Blend:", "_SrcBlend", typeof(UnityEngine.Rendering.BlendMode));
            CreatePopupFromProperty("Destination Blend:", "_DstBlend", typeof(UnityEngine.Rendering.BlendMode));
            CreatePopupFromProperty("Cull Mode:", "_CullMode", typeof(UnityEngine.Rendering.CullMode));
            bool zWrite = CreateToggleFromProperty("Enable Z-write:", "_ZWrite");
            materialEditor.RenderQueueField();
            EditorGUILayout.EndVertical();
        }
    }

    bool CreateToggleFromProperty(string label, string property )
    {
        MaterialProperty prop = FindProperty(property, properties);
        bool value = (prop.floatValue != 0.0f) ? true : false;
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label(label);
        value = EditorGUILayout.Toggle(value);
        material.SetInt( property, (value) ? 1 : 0);
        EditorGUILayout.EndHorizontal();
        return value;
    }

    int CreatePopupFromProperty(string label, string property, System.Type type)
    {
        int value = 0;
        System.Array enumValues = System.Enum.GetValues(type);
        string[] values = new string[enumValues.Length];
        for ( int i = 0; i < enumValues.Length; i++)
        {
            values[i] = enumValues.GetValue(i).ToString();
        }

        MaterialProperty prop = FindProperty(property, properties);
        value = (int)prop.floatValue;
        value = EditorGUILayout.Popup(label,value,values);
        material.SetInt(property,value);
        return value;
    }
}
#endif