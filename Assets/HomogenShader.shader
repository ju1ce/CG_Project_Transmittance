Shader "Project/HomogenShader"            //calculate tansmittance in a homogenous cube
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Density("Density", float) = 1.0
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

            float4 _Color;
            float _Density;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1));
                o.hitPos = v.vertex;
                return o;
            }

            

            void frag(v2f i, out fixed4 color : SV_Target)
            {
                //get starting position and direction of ray

                float3 pos = i.hitPos;
                float3 rd = normalize(i.ro - pos);

                //calculate the distance the ray has travelled through the cube, assuming a 1,1,1 cube at pos 0,0,0

                float distx = (pos.x + 0.5);
                if (rd.x < 0)
                    distx = 1 - distx;
                distx /= abs(rd.x);
                
                float disty = (pos.y + 0.5);
                if (rd.y < 0)
                    disty = 1 - disty;
                disty /= abs(rd.y);

                float distz = (pos.z + 0.5);
                if (rd.z < 0)
                    distz = 1 - distz;
                distz /= abs(rd.z);
                
                float dist = min(distx,min(disty,distz));

                //apply the transmittance to the alpha channel
                color = _Color;
                color.a = 1- exp(-dist * _Density);

            }
            ENDCG
        }
    }
}
