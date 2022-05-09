Shader "Unlit/raymarch1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry+1" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1));
                o.hitPos = v.vertex;
                return o;
            }

            float sphere(float3 pos, float r)
            {
                return length(pos) - r;
            }

            float opSmoothUnion(float d1, float d2, float k) {
                float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
                return lerp(d2, d1, h) - k * h * (1.0 - h);
            }

            float scene(float3 pos)
            {
                return opSmoothUnion(sphere(pos + float3(sin(_Time.y)*0.2,0.2,0.2), 0.3), sphere(pos - 0.2, 0.3), 0.3);
            }

            float3 getNorm(float3 pos)
            {
                float d = scene(pos);
                float dx = d - scene(pos + float3(0.01, 0, 0));
                float dy = d - scene(pos + float3(0, 0.01, 0));
                float dz = d - scene(pos + float3(0, 0, 0.01));

                return normalize(float3(dx, dy, dz));
            }

            void frag(v2f i, out fixed4 color : SV_Target, out float depth : SV_Depth)
            {
                float3 pos = i.ro;
                float3 rd = normalize(i.hitPos - pos);

                pos += rd*0.2;

                float d = scene(pos);

                for (int i = 0; i < 100; i++)
                {
                    pos = pos + rd * d;
                    d = scene(pos);
                    if (d < 0.001 || d > 10)
                    {
                        break;
                    }
                }

                if (d > 0.01)
                {
                    discard;
                }

                float3 norm = getNorm(pos);
                float3 light = 0.9 * clamp(dot(norm, float3(1, -1, 1)),0,1) + 0.1 * float3(1,1,1);

                color = fixed4(light, 1);

                float4 tracedClipPos = UnityObjectToClipPos(float4(pos, 1.0));
                depth = tracedClipPos.z / tracedClipPos.w;

                //return col;
            }
            ENDCG
        }
    }
}
