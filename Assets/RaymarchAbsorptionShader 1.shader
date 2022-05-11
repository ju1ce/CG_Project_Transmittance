Shader "Project/RaymarchAbsorptionShader"           //calculate absorption through a medium using the raymarching method
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Volume("Volume", 3D) = "white" {}
        _Density("Density", float) = 1.0
        _Stepsize("StepSize", float) = 0.1
        _MaxSteps("MaxSteps", int) = 100
    }
        SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        //Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };

            float4 _Color;
            float _Density;
            int _MaxSteps;
            float _Stepsize;

            sampler3D _Volume;
            float4 _Volume_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1));
                o.hitPos = v.vertex;
                return o;
            }

            //random function, thanks to https://www.ronja-tutorials.com/post/024-white-noise/
            // 
            //get a scalar random value from a 3d value
            float rand(float3 value) {
                //make value smaller to avoid artefacts
                float3 smallValue = sin(value);
                //get scalar value from 3d vector
                float random = dot(smallValue, float3(12.9898, 37.233, 73.719));
                //make value more random by making it bigger and then taking the factional part
                random = frac(sin(34232*random)*24351);
                return random;
            }

            float hash13(float3 p3)
            {
                p3 = frac(p3 * 1031);
                p3 += dot(p3, p3.zyx + 31.32);
                return frac((p3.x + p3.y) * p3.z);
            }

            float sphere(float3 pos, float r)
            {
                return length(pos) - r;
            }

            float cube(float3 pos, float x, float y, float z)
            {
                return max(abs(pos.x) - x, max(abs(pos.y) - y, abs(pos.z) - z));
            }

            float sampleTexture(float3 pos)
            {
                if (max(abs(pos.x), max(abs(pos.y), abs(pos.z))) >= 0.5f)        //check bounds of cube
                {
                    return 0;
                }
                float4 sampledColor = tex3D(_Volume, pos + float3(0.5f, 0.5f, 0.5f));
                return -sampledColor.a + 0.4;
            }

            float4 sampleTexture2(float3 pos)
            {
                if (max(abs(pos.x), max(abs(pos.y), abs(pos.z))) >= 0.5f)        //check bounds of cube
                {
                    return float4(0,0,0,0);
                }
                float4 sampledColor = tex3D(_Volume, pos + float3(0.5f, 0.5f, 0.5f),0 ,0);
                return sampledColor;
            }

            //returns whether point is inside medium
            float medium(float3 pos)
            {
                if (sampleTexture(pos) < 0.0)
                    return 1.0;
                return 0.0;
            }

            void frag(v2f i, out float4 color : SV_Target)
            {
                //get starting position and direction of ray

                float3 pos = i.hitPos;
                float3 rd = normalize(pos - i.ro);

                //pos = i.ro + rd*0.1;

                float dist = 0;
                
                float rnd = hash13(pos);
                //float newrnd = 0.5;
                if (isnan(rnd))
                {
                    rnd = 0;
                }
                /*
                for(int j = 0; j < 255;j++)
                {
                    if (j / 255.0 > rnd)
                    {
                        newrnd = float(j) / 255.0;
                        break;
                    }
                }
                */
                //rnd = newrnd;

                color = float4(0, 0, 0, 1);
                //return;

                //add some randomness to prevent aliasing
                pos = pos - rd *(rnd+0.1) * _Stepsize;// hash13(pos)* (1 + sin(_Time.z));

                float total_weight = 0;

                for (int i = 0; i < _MaxSteps; i++)
                {
                    pos = pos + rd * _Stepsize;
                    float4 color_sample = sampleTexture2(pos);
                    
                    //color.rgb += color_sample.rgb * (exp(-dist * _Density)) * color_sample.a;
                    total_weight += (exp(-dist * _Density)) * color_sample.a;

                    dist += color_sample.a * _Stepsize;

                }

                //apply the transmittance to the alpha channel
                //color.rgb = float3(1,1,1);
                color = _Color;
                //color /= total_weight;
                color.a = 1 - exp(-dist * _Density);
            }
            ENDCG
        }
    }
}
