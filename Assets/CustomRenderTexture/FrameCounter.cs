using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class FrameCounter : MonoBehaviour
{
    public Material mat;
    public Material ogMat;
    public Camera cam;

    public int count = 0;

    private int iteration = 0;
    private int countPerIter = 1000000;

    float startTime;

    float majorant = 10;
    float density = 0.1f;

    // Start is called before the first frame update
    void Start()
    {
        count = -100;
        startTime = Time.time;
    }

    // Update is called once per frame
    void Update()
    {
        if (iteration < 100)
        {
            count++;
            if (count > 0)
            {
                mat.SetFloat("_blend_factor", 1.0f / count);
                //Capture("nf_delta_d05_m001_i" + iteration + "_" + (count - 1) * 10);      //code to capture an image every frame
            }
            else
            {
                mat.SetFloat("_blend_factor", 1.0f);
                //ogMat.SetFloat("_Majorant", majorant);        //code to change material properties
                //ogMat.SetFloat("_Density", density);
                startTime = Time.time;
            }

            if (count >= countPerIter)
            {
                //Capture("ground_truth_i" + iteration + "_" + (count - 1) * 10);               //Code to capture finished image
                //StreamWriter writer = new StreamWriter("D:\\Unity\\images\\.txt", true);

                //writer.WriteLine("steps: 1000 majorant: " + majorant + " density: " + density + " time: " + (Time.time - startTime));

                //writer.Close();

                Debug.Log((Time.time - startTime) +  " for 10000 samples");

                startTime = Time.time;
                count = -100;
                iteration++;

                /*
                if (iteration > 5)
                {
                    iteration = 0;
                    majorant += 10;
                    if (majorant >= 100)
                    {
                        majorant = 10;
                        density += 0.1f;
                    }
                }
                */
            }
        }

    }

    void Capture(string name)
    {
        RenderTexture activeRenderTexture = RenderTexture.active;
        RenderTexture.active = cam.targetTexture;

        cam.Render();

        Texture2D image = new Texture2D(cam.targetTexture.width, cam.targetTexture.height);
        image.ReadPixels(new Rect(0, 0, cam.targetTexture.width, cam.targetTexture.height), 0, 0);
        image.Apply();
        RenderTexture.active = activeRenderTexture;

        byte[] bytes = image.EncodeToPNG();
        Destroy(image);

        File.WriteAllBytes("D:\\Unity\\images\\" + name + ".png", bytes);
    }
}
