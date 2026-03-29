using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ColorBlitRenderFeature : ScriptableRendererFeature
{
    public Shader m_Shader;
    public float m_Intensity;
    
    Material m_Material;
    // 创建临时纹理
    private RTHandle m_CameraColorCopy;
    
    class ColorBlitPass : ScriptableRenderPass
    {
        // ProfilingSampler 性能分析工具
        private ProfilingSampler m_ProfilingSampler = new ProfilingSampler("ColorBlit");
        Material m_Material;
        private RTHandle m_CameraColorTarget;
        private RTHandle m_CameraColorCopy;
        private float m_Intensity;
        
        // 构造
        public ColorBlitPass(Material material)
        {
            m_Material = material;
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        }

        public void SetTarget(RTHandle cameraColorTarget, RTHandle cameraColorCopy, float intensity)
        {
            m_CameraColorTarget = cameraColorTarget;
            m_CameraColorCopy = cameraColorCopy;
            m_Intensity = intensity;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            // 确保拷贝纹理的描述符与相机纹理一致
            var descriptor = cameraTextureDescriptor;
            descriptor.depthBufferBits = 0; // 不需要深度
            // 分配临时纹理
            RenderingUtils.ReAllocateIfNeeded(ref m_CameraColorCopy, descriptor, FilterMode.Bilinear, TextureWrapMode.Clamp, name:"_CameraColorCopy");
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            // 设置渲染目标
            ConfigureTarget(m_CameraColorTarget);
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cameraData = renderingData.cameraData;
            if (cameraData.camera.cameraType != CameraType.Game)
                return;
            if (m_Material == null)
                return;
            
            // 从缓冲池中获取
            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                // 拷贝当前相机颜色到临时纹理
                Blitter.BlitCameraTexture(cmd, m_CameraColorTarget, m_CameraColorCopy);
                // 设置参数
                m_Material.SetFloat("_Intensity", m_Intensity);
                m_Material.SetTexture("_MainTex", m_CameraColorTarget);
                // 执行全屏Blit处理
                Blitter.BlitCameraTexture(cmd, m_CameraColorCopy, m_CameraColorTarget, m_Material, 0);
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            // 释放回池
            CommandBufferPool.Release(cmd);
        }
        
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    ColorBlitPass m_RenderPass = null;

    /// <inheritdoc/>
    public override void Create()
    {
        m_Material = CoreUtils.CreateEngineMaterial(m_Shader);
        m_RenderPass = new ColorBlitPass(m_Material);
        m_CameraColorCopy = RTHandles.Alloc("_CameraColorCopy");
    }
    
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if(renderingData.cameraData.camera.cameraType == CameraType.Game)
            renderer.EnqueuePass(m_RenderPass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            m_RenderPass.ConfigureInput(ScriptableRenderPassInput.Color);
            m_RenderPass.SetTarget(renderer.cameraColorTargetHandle, m_CameraColorCopy, m_Intensity);
        }
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(m_Material);
        // 释放临时纹理
        m_CameraColorCopy?.Release();
    }
}