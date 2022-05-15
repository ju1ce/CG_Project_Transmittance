Shader "Project/RatioTrackingShader"        
{
    Properties
    {
        //_LightColor("LightColor", Color) = (1,1,1,1)
        _VolumeColor("VolumeColor", Color) = (1,1,1,1)
        _Volume("Volume", 3D) = "white" {}
        _Density("Density", float) = 1.0
        _Majorant("Majorant", float) = 1.0
        _MaxSteps("MaxSteps", int) = 100
        //_light_pow("LightPower", float) = 0.1
    }
        SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Back

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


            //get a scalar random value from a 3d value
            float randSin(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719)) {

                dotDir += float3(1.9898, 7.233, 3.719);

                //make value smaller to avoid artefacts
                float3 smallValue = sin(value);
                //get scalar value from 3d vector
                float random = dot(smallValue, dotDir);
                //make value more random by making it bigger and then taking the factional part
                random = frac(sin(random) * 1438.5453);
                return random;
            }

            float4 sampleTexture(float3 pos)
            {
                if (max(abs(pos.x), max(abs(pos.y), abs(pos.z))) >= 0.5f)        //check bounds of cube
                {
                    return float4(0, 0, 0, 0);
                }
                float4 sampledColor = tex3D(_Volume, pos + float3(0.5f, 0.5f, 0.5f), 0, 0);
                return sampledColor;
            }

            float getDensity(float3 pos)
            {
                //return density for a cube, where transmittance falls linearly from 1 to 0 on x axis
                return -log(pos.x + 0.5);
            }

            float _Majorant;

            void frag(v2f i, out float4 color : SV_Target)
            {
                //_Density = 1 / _Density;

                _Density = getDensity(float3(_Density-0.5,0,0));

                //get starting position and direction of ray

                float3 pos = i.hitPos;
                float3 rd = normalize(pos - i.ro);

                if(unity_OrthoParams.w)                                                             //if camera is orthographic, recalculate ray direction
                    rd = mul(unity_WorldToObject, float4(unity_CameraToWorld._m02_m12_m22, 0));

                color = float4(0, 0, 0, 0);

                float surf_rad = 0.0;               //variable to calculate reduction in surface radiance

                float hit_steps = 0;
                
                _Majorant = 10 + 90 * (pos.y + 0.5);

                float total_steps = 0;      //cost counter

                for (int i = 0; i < _MaxSteps; i++)
                {
                    float T = 1;
                    float3 cur_pos = pos;
                    float3 cur_rd = rd;
                    for(int j = 0; j < 1000; j++)
                    {
                        total_steps += 1.0;

                        float random = -log(1 - randSin(pos, float3(_Time.a, i, j))) / _Majorant;
                    
                        float3 sample_pos = cur_pos + rd * random;

                        //color = float4(sample_pos.x, sample_pos.y, sample_pos.z))

                        if (max(abs(sample_pos.x), max(abs(sample_pos.y), abs(sample_pos.z))) < 0.5f)
                        {
                            float color_sample = getDensity(sample_pos);
                            //float color_sample = _Density;

                            T *= 1 - color_sample / _Majorant;

                            cur_pos = sample_pos;

                        }
                        else
                        {
                            break;
                        }

                    }
                    surf_rad += T;
                }

                color.a = 1;

                //color.r = total_steps / (_MaxSteps * 200);  //calculate cost

                color.rgb = (surf_rad/_MaxSteps);

                //apply the transmittance to the alpha channel
                //color = _Color;
                //color.a = (dist/_MaxSteps);
            }
            ENDCG
        }
    }
}
