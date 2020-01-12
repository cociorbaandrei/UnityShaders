#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Linq;

public class BakeCenterToColorEditor : EditorWindow
{
    string assetName = "BakedMesh";
    Mesh source;

    [MenuItem("Window/Skuld/Bake Center To Color")]
    static void InitWindow()
    {
        BakeCenterToColorEditor window = (BakeCenterToColorEditor)EditorWindow.GetWindow(typeof(BakeCenterToColorEditor));
        window.Show();
    }

    //faces stuff
    int[] face;

    void resetFace()
    {
        face = new int[6];
        for ( int i = 0; i < 6; i++)
        {
            face[i] = -1;
        }
    }

    void addIndexToFace( int index)
    {
        for ( int i = 0; i < 6; i++)
        {
            if (face[i] == -1)
            {
                face[i] = index;
                return;
            } 
            if ( face[i] == index ) {
                return;
            }
        }
        Debug.Log("ERROR: Face array full.");
    }

    void OnGUI()
    {
        assetName = GUILayout.TextField(assetName);
        source = (Mesh)EditorGUILayout.ObjectField(source, typeof(Mesh));


        if (GUILayout.Button("Bake") && assetName != string.Empty)
        {
            Mesh mesh = new Mesh();
            mesh.indexFormat = source.indexFormat;
            mesh.vertices = source.vertices;
            mesh.triangles = source.triangles;
            mesh.normals = source.normals;
            mesh.tangents = source.tangents;
            mesh.uv = source.uv;
            mesh.bounds = source.bounds;
            mesh.bindposes = source.bindposes;
            mesh.boneWeights = source.boneWeights;


            Vector3 center = Vector3.zero;
            Color[] c = new Color[mesh.vertices.Length];

            Debug.Log("Number of triangles: " + mesh.triangles.Length );
            Debug.Log("Number of verticies: " + mesh.vertices.Length );

            Debug.Log(mesh.triangles[0]);

            resetFace();
            for (int i = 0; i < mesh.triangles.Length; i++)
            {
                center.x += mesh.vertices[ mesh.triangles[ i ] ].x;
                center.y += mesh.vertices[ mesh.triangles[ i ] ].y;
                center.z += mesh.vertices[ mesh.triangles[ i ] ].z;


                if (i % 12 == 11)
                {
                    center /= 12;

                    for (int j = 0; j < 12; j++)
                    {
                        int index = mesh.triangles[i - j];
                        addIndexToFace(index);
                        c[index] = new Color(center.x, center.y, center.z);
                        
                    }
                    
                    resetFace();
                    center = Vector3.zero;
                }
            }
            mesh.colors = c;

            AssetDatabase.CreateAsset(mesh, "Assets/Scripts/" + assetName + ".asset");
            AssetDatabase.SaveAssets();
        }
    }
}
#endif