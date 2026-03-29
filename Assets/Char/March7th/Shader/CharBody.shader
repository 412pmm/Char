Shader "CustomChar/CharBody"
{
    Properties
    {
        [KeywordEnum(Game, MMD)] _Model("Model Type", Float) = 0
        [HSRMaterialIDSelector] _SingleMaterialID("Material ID", Float) = -1
        
        [HeaderFoldout(Options)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", Float) = 0 // 默认Off
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendColor("Src Blend (RGB)", Float) = 1 // 默认 One
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendColor("Dst Blend (RGB)", Float) = 0 // 默认 Zero
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendAlpha("Src Blend (A)", Float) = 0   // 默认 Zero
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendAlpha("Dst Blend (A)", Float) = 0   // 默认 Zero
        [Toggle] _AlphaTest("Alpha Test", Float) = 0
        [If(_ALPHATEST_ON)] [Indent] _AlphaTestThreshold("Threshold", Range(0, 1)) = 0.5
        
        [HeaderFoldout(Outline)]
        [Toggle] _UseSmoothNormal("Use Smooth Normal", Int) = 0
        _ModelScale("ModelScale", Float) = 1
        _OutlineWidth("Width", Range(0,4)) = 1
        _OutlineZOffset("Z Offset", Float) = 0
        [HSRMaterialIDProperty(_OutlineColor, 0)] _OutlineColor0("Ourline Color", Color) = (0,0,0,1)
        [HSRMaterialIDProperty(_OutlineColor, 1)] _OutlineColor1("Ourline Color", Color) = (0,0,0,1)
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Geometry+30" // 身体默认+30，放在最后渲染
            "UniversalMaterialType"="ComplexLit"
        }
        
        Pass
        {
            Name "BodyOutline"
            
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }
            
            // Stencil
            Stencil
            {
                Ref 1
                WriteMask 1
                Comp Always
                Pass Replace
                Fail Keep
            }
            
            Cull Front
            ZTest LEqual
            ZWrite On
            
            Blend 0 [_SrcBlendColor] [_DstBlendColor], [_SrcBlendAlpha] [_DstBlendAlpha]
            
            ColorMask RGBA 0
            
            HLSLPROGRAM
            #pragma vertex BodyOutlineVertex
            #pragma fragment BodyOutlineFragment
            #pragma multi_compile_fog

            #pragma shader_feature_local _MODEL_GAME _MODEL_MMD
            #pragma shader_feature_local_vertex _USESMOOTHNORMAL_ON
            
            #include "CharBodyCore.hlsl"
            ENDHLSL
        }
    }
}
