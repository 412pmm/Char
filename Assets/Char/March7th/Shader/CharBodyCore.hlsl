#ifndef _CHAR_BODY_CORE_INCLUDE
#define _CHAR_BODY_CORE_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "CharOutline.hlsl"

CBUFFER_START(UnityPerMaterial)
    float _OutlineWidth;
    float _OutlineZOffset;
    float _ModelScale;
    float4 _OutlineColor;
CBUFFER_END

float4 _Maps_ST;

CharOutlineVaryings BodyOutlineVertex(CharOutlineAttributes i)
{
    VertexPositionInputs vertexInputs = GetVertexPositionInputs(i.positionOS);
    OutlineData outlineData;
    outlineData.width = _OutlineWidth;
    outlineData.zOffset = _OutlineZOffset;
    outlineData.modelScale = _ModelScale;
    return CharOutlineVertex(outlineData, i, vertexInputs, _Maps_ST);
}

void BodyOutlineFragment(CharOutlineVaryings i, out float4 colorTarget : SV_TARGET0)
{
    colorTarget = float4(_OutlineColor.rgb, 1);
}

#endif
