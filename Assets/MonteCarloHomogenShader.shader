Shader "Project/MonteCarloHomogenShader"           //calculate in-scattering with monte carlo in homogeneus cube
{
    Properties
    {
        _LightColor("LightColor", Color) = (1,1,1,1)
        _VolumeColor("VolumeColor", Color) = (1,1,1,1)
        _Volume("Volume", 3D) = "white" {}
        _Density("Density", float) = 1.0
        _Stepsize("StepSize", float) = 0.1
        _MaxSteps("MaxSteps", int) = 100
        _light_pow("LightPower", float) = 0.1
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

            float sampleTexture(float3 pos)
            {
                if (max(abs(pos.x), max(abs(pos.y), abs(pos.z))) >= 0.5f)        //check bounds of cube
                {
                    return 0;
                }
                float4 sampledColor = tex3D(_Volume, pos + float3(0.5f, 0.5f, 0.5f));
                return sampledColor.a;
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
                _light_pos = mul(unity_WorldToObject, float4(_light_pos, 1));

                //get starting position and direction of ray

                float3 pos = i.hitPos;
                float3 rd = normalize(pos - i.ro);

                //if (max(abs(i.ro.x), max(abs(i.ro.y), abs(i.ro.z))) <= 0.5f)
                //{
                //    pos = i.ro;
                //}

                float dist = 1;
                
                //add some randomness to prevent aliasing
                //pos = pos - rd * _Stepsize*rand(pos,0.0);

                color = float4(0, 0, 0, 0);

                float surf_rad = 0.0;               //variable to calculate reduction in surface radiance
                float3 emit_rad = float3(0, 0, 0);  //variable to store emitted radiance
                float3 scatt_rad = float3(0, 0, 0); //variable to store in-scattered radiance

                for (int i = 0; i < _MaxSteps; i++)
                {
                    float random = -log(rand(pos, sin(i + _Time.x)))*_Density;
                    float3 sample_pos = pos + rd * random;
                    
                    if (max(abs(sample_pos.x), max(abs(sample_pos.y), abs(sample_pos.z))) <= 0.5f)
                    {
                        float event = rand(pos, 3 * cos(2 * i));
                        if (event > 0.5)                        //in scattering event
                        {
                            dist += 1.0;
                            float random_l = -log(rand(sample_pos, sin(i+_Time.x))) * _Density;

                            float light_dist = length(sample_pos - _light_pos);

                            float3 light_dir = -normalize(sample_pos - _light_pos);         //sample direction and position
                            float3 light_sample_pos = sample_pos + light_dir * random_l;

                            if (light_dist < random_l || max(abs(light_sample_pos.x), max(abs(light_sample_pos.y), abs(light_sample_pos.z))) > 0.5f)        //if sampled length is greater than length to light, we have hit the light. Since density outside cube is 0, we also hit it if the sample is outside cube.
                            {
                                float lightPower = _light_pow / (light_dist * light_dist);      //light power drops with square of distance

                                scatt_rad += (_LightColor.rgb * lightPower) / (4 * 3.14);              //Multiply with the color of light and divide by PDF
                            }
                        }
                        else if (event > 0.1)           //emission event
                        {
                            emit_rad += _VolumeColor.rgb;
                        }

                        surf_rad += 1;  //reduce surface radiance for one point, as we hit the medium. Density has already been acounted for in the sampling
                    }


                }

                dist *= 2;

                color.rgb = scatt_rad/dist + emit_rad / dist;
                color.a = surf_rad / _MaxSteps;

                //apply the transmittance to the alpha channel
                //color = _Color;
                //color.a = (dist/_MaxSteps);
            }
            ENDCG
        }
    }
}
