Shader "CustomRenderTexture/RenderShader"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Tex("InputTex", 2D) = "white" {}
        _blend_factor("blend factor", float) = 1
    }

        SubShader
    {
       Lighting Off
       Blend One Zero

       Pass
       {
           CGPROGRAM
           #include "UnityCustomRenderTexture.cginc"
           #pragma vertex CustomRenderTextureVertexShader
           #pragma fragment frag
           #pragma target 3.0

           float4      _Color;
           sampler2D   _Tex;

           float _blend_factor;

           float4 frag(v2f_customrendertexture IN) : COLOR
           {
               //float blend_factor = 1;
               //return float4(_blend_factor,0,0,0);
               //return frac(tex2D(_SelfTexture2D,IN.localTexcoord.xy)+0.1);
               float4 prev_col = tex2D(_SelfTexture2D,IN.localTexcoord.xy);

               return (1- _blend_factor) * prev_col + _blend_factor * tex2D(_Tex, IN.localTexcoord.xy);
           }
           ENDCG
           }
    }
}
