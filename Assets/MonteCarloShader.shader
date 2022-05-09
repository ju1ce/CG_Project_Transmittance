Shader "Project/MonteCarloShader"           //calculate emission and absorptionwith monte carlo in homogeneus cube
{
    Properties
    {
        //_LightColor("LightColor", Color) = (1,1,1,1)
        _VolumeColor("VolumeColor", Color) = (1,1,1,1)
        _Volume("Volume", 3D) = "white" {}
        _Density("Density", float) = 1.0
        _Stepsize("StepSize", float) = 0.1
        _MaxSteps("MaxSteps", int) = 100
        //_light_pow("LightPower", float) = 0.1
    }
        SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

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

            float4 _LightColor;
            float4 _VolumeColor;
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
                o.uv = v.uv;
                return o;
            }

            //random function, thanks to https://www.ronja-tutorials.com/post/024-white-noise/
            // 
            //get a scalar random value from a 3d value
            float rand(float3 value, float seed) {
                //make value smaller to avoid artefacts
                float3 smallValue = sin(value);
                //get scalar value from 3d vector
                float random = dot(smallValue, float3(12.9898, 78.233, 37.719));
                //make value more random by making it bigger and then taking the factional part
                random = frac(sin(random*12.23) * 1438.5453 * (seed+1.754));
                return random;
            }

            float4 sampleTexture(float3 pos)
            {
                if (max(abs(pos.x), max(abs(pos.y), abs(pos.z))) >= 0.5f)        //check bounds of cube
                {
                    return float4(0, 0, 0, 0);
                }
                float4 sampledColor = tex3D(_Volume, pos + float3(0.5f, 0.5f, 0.5f));
                return sampledColor;
            }

            float4 BlendUnder(float4 color, float4 newColor)
            {
                color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
                color.a += (1.0 - color.a) * newColor.a;
                return color;
            }

            float3 _light_pos;
            float _light_pow;

            void frag(v2f i, out float4 color : SV_Target)
            {
                _Density = 1 / _Density;

                _light_pos = mul(unity_WorldToObject, float4(_light_pos, 1));

                //get starting position and direction of ray

                float3 pos = i.hitPos;
                float3 rd = normalize(pos - i.ro);

                //pos = i.ro + rd*0.1;

                //add some randomness to prevent aliasing
                //pos = pos - rd * _Stepsize*rand(pos,0.0);

                color = float4(0, 0, 0, 0);

                float surf_rad = 0.0;               //variable to calculate reduction in surface radiance
                float3 emit_rad = float3(0, 0, 0);  //variable to store emitted radiance
                //float3 scatt_rad = float3(0, 0, 0); //variable to store in-scattered radiance

                for (int i = 0; i < _MaxSteps; i++)
                {
                    float3 cur_pos = pos;
                    for(int j = 0; j < 10; j++)
                    {

                        float random = -log(rand(cur_pos, sin(i+j))) * _Density;
                    
                        float3 sample_pos = cur_pos + rd * random;

                    //color = float4(sample_pos.x, sample_pos.y, sample_pos.z))

                        if (max(abs(sample_pos.x), max(abs(sample_pos.y), abs(sample_pos.z))) < 0.5f)
                        {
                            float color_sample = sampleTexture(sample_pos).a;
                            //float color_sample = 0.5-length(sample_pos); 

                            float random_null = rand(sample_pos, cos(i + j));
                            if (color_sample > random_null)
                            {
                                surf_rad += color_sample;
                                break;
                            }
                            else
                            {
                                cur_pos = sample_pos;
                            }
                        }

                    }
                }

                color.rgb = _VolumeColor;
                color.a = surf_rad / _MaxSteps;

                //apply the transmittance to the alpha channel
                //color = _Color;
                //color.a = (dist/_MaxSteps);
            }
            ENDCG
        }
    }
}
