Shader "CustomChar/SimpleOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor("MainColor", COLOR) = (1,1,1,1)
        [Toggle] _UseSmoothNormal("Use Smooth Normal", Int) = 0
        _OutlineColor("OutlineColor", COLOR) = (0,0,0,1)
        _OutlineFactor("OutlineFactor",Range(0,10)) = 0.1
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100
        
        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
            };

            float4 _MainColor;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half4 col = _MainColor;
                return col;
            }
            
            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            Cull Front
            
            Tags
            {
                "LightMode"="SRPDefaultUnlit"
            }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _USESMOOTHNORMAL_ON 

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 uv7 : TEXCOORD7;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
            };

            float4 _OutlineColor;
            float _OutlineFactor;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs vertex_position_inputs = GetVertexPositionInputs(IN.positionOS);
                VertexNormalInputs vertex_normal_inputs = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);

                float3 positionWS = vertex_position_inputs.positionWS;
                _OutlineFactor *= 0.001;
                #ifdef _USESMOOTHNORMAL_ON
                    float3x3 tbn = float3x3(vertex_normal_inputs.tangentWS, vertex_normal_inputs.bitangentWS, vertex_normal_inputs.normalWS);
                    positionWS += mul(IN.uv7.xyz, tbn) * _OutlineFactor;
                #else
                    positionWS += vertex_normal_inputs.normalWS * _OutlineFactor;
                #endif
                OUT.positionHCS = TransformWorldToHClip(positionWS);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half4 col = _OutlineColor;
                return col;
            }
            ENDHLSL
        }
    }
}
