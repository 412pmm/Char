#ifndef _CHAR_OUTLINE_INCLUDE
#define _CHAR_OUTLINE_INCLUDE

struct CharOutlineAttributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 color : COLOR;
    float3 uv7 : TEXCOORD7; // 平滑法线
};

struct CharOutlineVaryings
{
    float4 positionHCS : SV_POSITION;
    float3 positionWS : TEXCOORD1;
};

struct OutlineData
{
    float modelScale;
    float width;
    float zOffset;
};

float3 GetOutlinePositionVS(OutlineData data, float3 positionVS, float3 normalVS, float4 vertexColor)
{
    float3 outlineWidth = data.width * data.modelScale * 0.0588;

    // 模型定点色控制描边
    #if defined(MODEL_GAME)
        outlineWidth *= vertexColor.a;
    #else
        outlineWidth *= 0.5;
    #endif

    float fixScale;
    if (IsPerspectiveProjection())
    {
        // unity_CameraProjection._m11 : cot(FOV/2)
        // 2.414 是 FOV 为 45 度的值
        fixScale = 2.414 / unity_CameraProjection._m11;
    }
    else
    {
        // unity_CameraProjection.m_11 : (1/Size)
        // 1.5996 纯 Magic Number
        fixScale = 1.5996 / unity_CameraProjection._m11;
    }
    fixScale *= -positionVS.z / data.modelScale;
    outlineWidth *= clamp(fixScale * 0.025, 0.04, 0.1);

    normalVS.z = -0.1;
    positionVS += normalize(normalVS) * outlineWidth;
    positionVS.z += data.zOffset * data.modelScale;
    
    return positionVS;
}

CharOutlineVaryings CharOutlineVertex(OutlineData data, CharOutlineAttributes i, VertexPositionInputs vertexInputs, float4 mapST)
{
    CharOutlineVaryings o;
    float3 normalOS = 0;
    #if defined(_USESMOOTHNORMAL_ON)
        normalOS = i.uv7;
    #else
        normalOS = i.normalOS;
    #endif

    float3 normalWS = TransformObjectToWorldNormal(normalOS);
    float3 normalVS = TransformWorldToViewNormal(normalWS);
    float3 positionVS = GetOutlinePositionVS(data, vertexInputs.positionVS, normalVS, i.color);

    o.positionHCS = TransformWViewToHClip(positionVS);
    o.positionWS = TransformViewToWorld(positionVS);
    
    return o;
}

#endif