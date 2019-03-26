---
title: 使用Shader Reflection搭建简单的Effect框架
date: 2019-03-26 09:46:30
tags: [Shader, HLSL, C++, Rendering, Effect]
categories: Tech
---
本文可以看作是一个学习笔记，对Shader Reflection进行简单的介绍，并通过代码展示如何使用它来搭建简单的“Effect"框架。

<!--more-->


# Shader Reflection 

## 基本概念
> 官方文档中的介绍：[ID3D11ShaderReflection Interface ](https://docs.microsoft.com/en-us/windows/desktop/api/d3d11shader/nn-d3d11shader-id3d11shaderreflection)

通过这一系列的API，我们可以很轻松的知道shader字节码中的结构，注意这里强调的是shader字节码，而非HLSL。因为[`In computer graphics, a shader is a type of computer program`](https://en.wikipedia.org/wiki/Shader),这其实就跟代码和编译后的二进制可执行文件的区别是一样的。遥想之前和别人争论UE4的材质编辑器是不是shader时，如果当时我能清晰的理解定义的话就能够说服他了。咳咳，扯的有点远了。简单点来讲就是，Shader Reflection提供了对我们写在HLSL代码中的Constant Buffer、Shader Resource、Sampler等信息的描述。

## 使用说明

### 创建Shader Reflection 对象
```C++
    // ...
   RE_D3D_ThrowIfFailed(
            device->CreateVertexShader(
                in_shaderBufferBlob->GetBufferPointer(),
                in_shaderBufferBlob->GetBufferSize(),
                NULL,
                m_shader.ReleaseAndGetAddressOf()
            )
        );

    ComPtr<ID3D11ShaderReflection> shaderReflection;
        RE_D3D_ThrowIfFailed(
            D3DReflect(
                in_shaderBufferBlob->GetBufferPointer(),
                in_shaderBufferBlob->GetBufferSize(),
                IID_PPV_ARGS(shaderReflection.ReleaseAndGetAddressOf())
            )
        );

    HandleShaderRefelction(shaderReflection.Get());

    // ...
```
创建方式非常直接明了，只需要shader字节码即可，即run time compiled还是pre compiled的都行。

### 使用示例

```c++
    ID3D11ShaderReflectionConstantBuffer *shaderReflectionConstantBuffer = nullptr;;
    shaderReflectionConstantBuffer = in_shaderReflection->GetConstantBufferByIndex(constantBufferIndex);
```

Shader Reflection中包含了多种类型的反射类型，比如 shaderReflectionConstantBuffer、ID3D11ShaderReflectionVariable等。我们需要做的就是去访问它提供的这些个对象，然后获取它们的描述然后记录下来，并填充我们C++中的对应shader的类就行了。

## 学习动机 
学习Shader Reflection的主要原因是因为，之前直接照着教程使用FX框架，很容易就变成了抄代码，并没了解整个框架的具体流程。这其实这是学习任何框架、引擎等自成体系的东西的公有弊端。很容易把它们当成工具来学习，而忽略了它们的工作原理。而且这些东西的高度封装性也很容易让人不知道从何处开始剖析。所以我学着RasterTek的教程中，一个HLSL对应一个C++类来开始重新学习一些东西。但这太痛苦了，也就是说一处改动可能要修改两部分代码，并且还要保证它们完全一致。那么有没有什么好的方法，既能了解运作原理又能减轻编写负担呢。我寻找了一些资料，最终这个Shader Relection进入了我的视线，并学习构建了一个简单的Effect框架。


# 自制“Effect”框架

根据前文中提到的，Shader Reflection提供了对shader内容的描述。所以通过这些信息我们完全可以在C++中动态构建一个类来做好相应数据之间的映射，从而避免每一个hlsl对应一个C++类。那么下面就介绍通常使用的几个类型把。


## 常用的几个类型
一般来说我们在C++代码中需要关心的就是Constant Buffer、Shader Resource View的等，Shader Reflection识别出这些对象便可以记录到的C++类中。

### Variable
Variable类实际上就是Constant Buffer中的被使用的成员，注意这里我们所说的是被使用的。之所以这么说，是因为在HLSL代码在编译时会被优化，有些没有使用的变量是不会写入到shader中的。
```C++
    struct VariableProxy
    {
        std::size_t ByteOffset;                 // 在整个Constant Buffer中的字节偏移
        std::size_t SizeInBytes;                // 字节大小
        unsigned int OwningConstantBufferIndex; 
    };              
```
+ `unsigned int VariableProxy::OwningConstantBufferIndex`
  指的时拥有这个变量的Constant Buffer的索引，一般来说就是我们在写HLSL时，指定的寄存器的序号，如果没指定就是书写顺序。

{% fold 读取方式 %}
```C++
    // ...

    ID3D11ShaderReflectionConstantBuffer *shaderReflectionConstantBuffer = nullptr;;
    shaderReflectionConstantBuffer = in_shaderReflection->GetConstantBufferByInde(constantBufferIndex）;

    D3D11_SHADER_BUFFER_DESC shaderBufferDesc;
    shaderReflectionConstantBuffer->GetDesc(&shaderBufferDesc);
    
    // ...

    for (UINT variableIndex = 0; variableIndex < shaderBufferDesc.Variables; ++variableIndex)
    {
        ID3D11ShaderReflectionVariable *shaderReflectionVariable =
            shaderReflectionConstantBuffer->GetVariableByIndex(variableIndex);

        D3D11_SHADER_VARIABLE_DESC shaderVariableDesc;
        shaderReflectionVariable->GetDesc(&shaderVariableDesc);

        auto variableProxy = std::make_shared<VariableProxy>();
        variableProxy->OwningConstantBufferIndex = constantBufferIndex;
        variableProxy->ByteOffset = shaderVariableDesc.StartOffset;
        variableProxy->SizeInBytes = shaderVariableDesc.Size;

        m_variableLookup.insert(std::make_pair(shaderVariableDesc.Name, variableProxy));
        constantBufferProxy->Variables.push_back(variableProxy);
    }     

    // ...
```
{% endfold %}

通过shaderReflection对象我们可以用Constant Buffer的索引，依次访问它拥有的所有变量，并记录下来。这个过程中我们最关心的就是定义中的那三个成员属性，并且之后我们可以使用名字或者索引来直接设置变量的值。比如:
```C++
    auto worldTransformMatrix = renderObject->GetTransform().GetTransformMatrix();
    auto worldInverseMatrix = MathHelper::InverseWithoutTranslation(worldTransformMatrix);
    m_vertexShader->SetMatrix4x4("worldMatrix", worldTransformMatrix);
    m_vertexShader->SetMatrix4x4("viewMatrix", currentCamera.GetViewMatrix());
    m_vertexShader->SetMatrix4x4("projectionMatrix", currentCamera.GetProjectionMatrix());
    m_vertexShader->SetMatrix4x4("noTransflationWorldInvrseMatrix", worldInverseMatrix);
```
这样就方便了很多，也和FX框架的使用方式比较靠近了。

### Constant Buffer
```c++
    struct ConstantBufferProxy
    {
        unsigned int Index;                                     // Constant Buffer的索引           
        std::string Name;                                       // HLSL定义Contant Buffer时使用的名字
        std::size_t SizeInBytes;                                
        unsigned int  SlotIndex;
        ComPtr<ID3D11Buffer> ConstantBuffer;                       
        std::unique_ptr<unsigned char[]> LocalDataBuffer;       
        std::vector<std::shared_ptr<VariableProxy>> Variables;
        D3D_CBUFFER_TYPE Type;
        bool Dirty = false;
    };
```
+ `ComPtr<ID3D11Buffer> ConstantBufferProxy::ConstantBuffer` 
    用来给GPU传数据的缓冲对象，为了方便每一个Proxy里面放一个。如果用`Map`方式的话，可以按大小和类型来只分配一个ID3D11Buffer供多个地方使用。
+ `std::unique_ptr<unsigned char[]> ConstantBufferProxy::LocalDataBuffer` 
    每次写入数据实际上时先写到该变量对应的内存中，然后通过统一写到ID3D11Buffer中然后提交给GPU。

+ `std::vector<std::shared_ptr<VariableProxy>> ConstantBufferProxy::Variables`
    记录了这个Constant Buffer中真正用到的Variable。之所以是std::shared_ptr是因为在后面会建立一个Variable Name到其的查找表。

{% fold 读取方式 %}
```c++
        // ...

        m_numConstantBuffers = shaderDesc.ConstantBuffers;
        m_constantBuffers.reserve(m_numConstantBuffers);
        for (UINT constantBufferIndex = 0; constantBufferIndex < m_numConstantBuffers; ++constantBufferIndex)
        {
            auto constantBufferProxy = std::make_shared<ConstantBufferProxy>();

            ID3D11ShaderReflectionConstantBuffer *shaderReflectionConstantBuffer = nullptr;;
            shaderReflectionConstantBuffer = in_shaderReflection->GetConstantBufferByIndex(constantBufferIndex);

            D3D11_SHADER_BUFFER_DESC shaderBufferDesc;
            shaderReflectionConstantBuffer->GetDesc(&shaderBufferDesc);

            D3D11_SHADER_INPUT_BIND_DESC shaderInputBindDesc;
            in_shaderReflection->GetResourceBindingDescByName(shaderBufferDesc.Name, &shaderInputBindDesc);

            // Record data that we concerned.
            constantBufferProxy->Index = constantBufferIndex;
            constantBufferProxy->Name = shaderInputBindDesc.Name;
            constantBufferProxy->SizeInBytes = shaderBufferDesc.Size;
            constantBufferProxy->SlotIndex = shaderInputBindDesc.BindPoint;
            constantBufferProxy->Type = shaderBufferDesc.Type;

            D3D11_BUFFER_DESC newBuffDesc;
            newBuffDesc.Usage = D3D11_USAGE_DYNAMIC;
            newBuffDesc.ByteWidth = std::max<UINT>(shaderBufferDesc.Size, 16);
            newBuffDesc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
            newBuffDesc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
            newBuffDesc.MiscFlags = NULL;
            newBuffDesc.StructureByteStride = 0;
            RE_D3D_ThrowIfFailed(device->CreateBuffer(&newBuffDesc, NULL, constantBufferProxy->ConstantBuffer.ReleaseAndGetAddressOf()));

            constantBufferProxy->LocalDataBuffer = std::make_unique<unsigned char[]>(newBuffDesc.ByteWidth);
            ZeroMemory(constantBufferProxy->LocalDataBuffer.get(), newBuffDesc.ByteWidth);

            // ... Variable Part.

            // Collect it to look up table.
            m_constantBuffers.push_back(constantBufferProxy);
            m_constantBufferLookup.insert(std::make_pair(shaderInputBindDesc.Name, constantBufferProxy));;
        }

        // ...
```
{% endfold %}
   
代码有点长，但是其实也只是做了记录我们所需要的数据和申请资源的工作。

### Shader Resource View 和 Sampler

``` C++ 
    struct ShaderResourceViewProxy
    {
        unsigned int Index;
        unsigned int SlotIndex;
    };
    
    struct SamplerProxy
    {
        unsigned int Index;
        unsigned int SlotIndex = 0;
    };
```
这两个一般都是成对出现的，需要注意的是诸如HLSL中的Texture2D、Texture3D等统一对应的是C++的ID3DShaderResourceView，以及SamplerState、SamplerComparisonState对应的是C++中的ID3D11SamplerState。即我们在C++中是可以统一它们。

{% fold 获取方式 %}
```
    D3D11_SHADER_DESC shaderDesc;
    RE_D3D_ThrowIfFailed(in_shaderReflection->GetDesc(&shaderDesc));

    auto numBoundResources = shaderDesc.BoundResources;
    for (UINT resourceIndex = 0; resourceIndex < numBoundResources; ++resourceIndex)
    {

        D3D11_SHADER_INPUT_BIND_DESC shaderInputBindDesc;
        in_shaderReflection->GetResourceBindingDesc(resourceIndex, &shaderInputBindDesc);

        switch (shaderInputBindDesc.Type)
        {
        case D3D_SIT_TEXTURE:
        {
            auto shaderResourceViewProxy = std::make_shared<ShaderResourceViewProxy>();
            shaderResourceViewProxy->SlotIndex = shaderInputBindDesc.BindPoint;
            shaderResourceViewProxy->Index = static_cast<unsigned int>(m_shaderResourceViews.size());

            m_shaderResourceViewLookup.insert(std::make_pair(shaderInputBindDesc.Name, shaderResourceViewProxy));
            m_shaderResourceViews.push_back(shaderResourceViewProxy);
        }
        break;
        case D3D_SIT_SAMPLER:
        {
            auto samplerProxy = std::make_shared<SamplerProxy>();
            samplerProxy->SlotIndex = shaderInputBindDesc.BindPoint;
            samplerProxy->Index = static_cast<unsigned int>(m_samplers.size());

            m_samplerLookup.insert(std::make_pair(shaderInputBindDesc.Name, samplerProxy));
            m_samplers.push_back(samplerProxy);
        }
        break;
        case D3D_SIT_CBUFFER:
        case D3D_SIT_TBUFFER:
        case D3D_SIT_UAV_RWTYPED:
        case D3D_SIT_STRUCTURED:
        case D3D_SIT_UAV_RWSTRUCTURED:
        case D3D_SIT_BYTEADDRESS:
        case D3D_SIT_UAV_RWBYTEADDRESS:
        case D3D_SIT_UAV_APPEND_STRUCTURED:
        case D3D_SIT_UAV_CONSUME_STRUCTURED:
        case D3D_SIT_UAV_RWSTRUCTURED_WITH_COUNTER:
        default:
            break;
        }
    }
```
{% endfold %}

通过这部分的代码可以发现`D3D_SIT_TEXTURE`、`D3D_SIT_SAMPLER`等都是统一被当作了输入，这个和UE4中材质实例概念感觉就有点相似了。

### Input Layout
这个是Vertex Shader独有的，也是可以从Shader Reflection中取到结构描述的。虽然一般来说，我们写HLSL的时候都会统一输入的顶点数据的结构。但是既然能从shader中获取并自动创建，为什么不偷个懒呢:P。

{% fold 解析InputLayout %}
```c++
  void VertexShader::CreateInputLayout(ID3DBlob *in_shaderBufferBlob, ID3D11ShaderReflection * in_shaderReflection)
    {
        auto device = Engine::Get()->GetRenderer()->GetDevice();

        D3D11_SHADER_DESC shaderDesc;
        in_shaderReflection->GetDesc(&shaderDesc);

        std::vector<D3D11_INPUT_ELEMENT_DESC> inputElementDescs;
        for (UINT i = 0; i < shaderDesc.InputParameters; i++)
        {
            D3D11_SIGNATURE_PARAMETER_DESC signatureParameterDesc;
            in_shaderReflection->GetInputParameterDesc(i, &signatureParameterDesc);

            D3D11_INPUT_ELEMENT_DESC inputElementDesc;
            inputElementDesc.SemanticName = signatureParameterDesc.SemanticName;
            inputElementDesc.SemanticIndex = signatureParameterDesc.SemanticIndex;
            inputElementDesc.InputSlot = 0;
            inputElementDesc.AlignedByteOffset = D3D11_APPEND_ALIGNED_ELEMENT;
            inputElementDesc.InputSlotClass = D3D11_INPUT_PER_VERTEX_DATA;
            inputElementDesc.InstanceDataStepRate = 0;

            if (signatureParameterDesc.Mask == 1)
            {
                if (signatureParameterDesc.ComponentType == D3D_REGISTER_COMPONENT_UINT32)
                {
                    inputElementDesc.Format = DXGI_FORMAT_R32_UINT;
                }
                else if (signatureParameterDesc.ComponentType == D3D_REGISTER_COMPONENT_SINT32)
                {
                    inputElementDesc.Format = DXGI_FORMAT_R32_SINT;
                }
                else if (signatureParameterDesc.ComponentType == D3D_REGISTER_COMPONENT_FLOAT32)
                {
                    inputElementDesc.Format = DXGI_FORMAT_R32_FLOAT;
                }
            }
            else if (signatureParameterDesc.Mask <= 3)
            {
                if (signatureParameterDesc.ComponentType == D3D_REGISTER_COMPONENT_UINT32)
                {
                    inputElementDesc.Format = DXGI_FORMAT_R32G32_UINT;
                }
                else if (signatureParameterDesc.ComponentType == D3D_REGISTER_COMPONENT_SINT32)
                {
                    inputElementDesc.Format = DXGI_FORMAT_R32G32_SINT;
                }
                else if (signatureParameterDesc.ComponentType == D3D_REGISTER_COMPONENT_FLOAT32)
                {
                    inputElementDesc.Format = DXGI_FORMAT_R32G32_FLOAT;
                }
            }

            else if (signatureParameterDesc.Mask <= 7)
            {
                if (signatureParameterDesc.ComponentType == D3D_REGISTER_COMPONENT_UINT32)
                {
                    inputElementDesc.Format = DXGI_FORMAT_R32G32B32_UINT;
                }
                else if (signatureParameterDesc.ComponentType == D3D_REGISTER_COMPONENT_SINT32)
                {
                    inputElementDesc.Format = DXGI_FORMAT_R32G32B32_SINT;
                }
                else if (signatureParameterDesc.ComponentType == D3D_REGISTER_COMPONENT_FLOAT32)
                {
                    inputElementDesc.Format = DXGI_FORMAT_R32G32B32_FLOAT;
                }
            }
            else if (signatureParameterDesc.Mask <= 15)
            {
                if (signatureParameterDesc.ComponentType == D3D_REGISTER_COMPONENT_UINT32)
                {
                    inputElementDesc.Format = DXGI_FORMAT_R32G32B32A32_UINT;
                }
                else if (signatureParameterDesc.ComponentType == D3D_REGISTER_COMPONENT_SINT32)
                {
                    inputElementDesc.Format = DXGI_FORMAT_R32G32B32A32_SINT;
                }
                else if (signatureParameterDesc.ComponentType == D3D_REGISTER_COMPONENT_FLOAT32)
                {
                    inputElementDesc.Format = DXGI_FORMAT_R32G32B32A32_FLOAT;
                }
            }

            inputElementDescs.push_back(inputElementDesc);
        }

        RE_D3D_ThrowIfFailed(
            device->CreateInputLayout(
                inputElementDescs.data(),
                static_cast<UINT>(inputElementDescs.size()),
                in_shaderBufferBlob->GetBufferPointer(),
                in_shaderBufferBlob->GetBufferSize(),
                m_inputLayout.ReleaseAndGetAddressOf()
            )
        );
    }
```
{% endfold %}

这部分代码就更长了，因为它涉及到大量的掩码检测和类型判断。不管是手写Input Layout还是从shader中自动获取，我都需要注意的是输入的顶点数据要和其保持一致。而在DirectX 12中就更加严格了，包括C++声明的Root Constants也都需要保证一致。

## “Effect”框架结构
好了上面代码基本上说明了怎么从Shader Reflection中获取我们想要的数据信息。我们接下来要做的就是如何去存储这些个数据以及怎么使用它们。我用了BaseShader、BasePass、BaseEffect来组成我们的框架。

### BaseShader
    
{% fold 类定义 %}
``` c++
class BaseShader
    {
    public:
        BaseShader() = default;
        virtual ~BaseShader() = default;
        BaseShader(const BaseShader &) = delete;
        BaseShader(BaseShader &&) = delete;
        BaseShader &operator=(const BaseShader&) = delete;

    public:
        // 第一部分----------------------------------------------------------------------------------------
        void LoadCompiledShader(const std::wstring &in_filepath);
        virtual void CompileShaderFromFile(const std::wstring &in_filepath, const std::string &in_entryName) = 0;
        virtual void CreateShaderFromBlob(ID3DBlob *in_blob) = 0;
        // 第一部分----------------------------------------------------------------------------------------

        // 第二部分----------------------------------------------------------------------------------------
        virtual void Bind() = 0;
        void UploadAllConstantBufferData();
        void UploadConstantBufferData(unsigned int in_index);
        void UploadConstantBufferData(const std::string &in_bufferName);
        // 第二部分----------------------------------------------------------------------------------------

        // 第三部分----------------------------------------------------------------------------------------
        bool SetData(const std::string &in_name, const void* in_data, unsigned int in_sizeInBytes);
        bool SetInt(const std::string &in_name, int in_value);
        bool SetFloat(const std::string &in_name, float in_value);
        bool SetFloat2(const std::string &in_name, const XMFLOAT2 in_value);
        bool SetFloat3(const std::string &in_name, const XMFLOAT3 in_value);
        bool SetFloat4(const std::string &in_name, const XMFLOAT4 in_value);
        bool SetFloat4x4(const std::string &in_name, const XMFLOAT4X4 in_value);
        bool XM_CALLCONV SetVector3(const std::string &in_name, FXMVECTOR in_value);
        bool XM_CALLCONV SetVector4(const std::string &in_name, FXMVECTOR in_value);
        bool XM_CALLCONV SetMatrix4x4(const std::string &in_name, FXMMATRIX in_value);
        // 第三部分----------------------------------------------------------------------------------------

    protected:
        // 第四部分----------------------------------------------------------------------------------------
        void HandleShaderRefelction(ID3D11ShaderReflection *in_shaderReflection);

        void OutputCompilingShaderErrorMessage(ID3DBlob* in_errorblob, const std::wstring &in_filepath);
        // 第四部分----------------------------------------------------------------------------------------

    private:
        
        // 第五部分----------------------------------------------------------------------------------------
        const VariableProxy *GetVariableProxy(const std::string &in_name);
        const VariableProxy *GetVariableProxy(const std::string &in_name, std::size_t in_sizeInBytes);

        const ConstantBufferProxy *GetConstantBufferProxy(const std::string &in_name);
        const ConstantBufferProxy *GetConstantBufferProxy(unsigned int in_index);
        inline std::size_t GetNumConstantBuffers() const { return m_numConstantBuffers; }

        const ShaderResourceViewProxy *GetShaderResourceViewProxy(const std::string &in_name);
        const ShaderResourceViewProxy *GetShaderResourceViewProxy(unsigned int in_index);
        inline std::size_t GetNumShaderResourceViews() const { return m_shaderResourceViews.size(); }
        virtual bool SetShaderResourceView(const std::string &in_name, ID3D11ShaderResourceView *in_shaderResourceView) = 0;

        const SamplerProxy *GetSamplerProxy(const std::string &in_name);
        const SamplerProxy *GetSamplerProxy(unsigned int in_index);
        inline std::size_t GetNumSamplers() const { return m_samplers.size(); }
        virtual bool SetSampler(const std::string &in_name, ID3D11SamplerState* in_sampler) = 0;
        // 第五部分----------------------------------------------------------------------------------------
   
    protected:
        std::size_t m_numConstantBuffers;
        std::vector<std::shared_ptr<ConstantBufferProxy>> m_constantBuffers;
        std::vector<std::shared_ptr<ShaderResourceViewProxy>> m_shaderResourceViews;
        std::vector<std::shared_ptr<SamplerProxy>> m_samplers;

        std::unordered_map<std::string, std::shared_ptr<ConstantBufferProxy>> m_constantBufferLookup;
        std::unordered_map<std::string, std::shared_ptr< VariableProxy>> m_variableLookup;
        std::unordered_map<std::string, std::shared_ptr<ShaderResourceViewProxy>> m_shaderResourceViewLookup;
        std::unordered_map<std::string, std::shared_ptr<SamplerProxy>> m_samplerLookup;
    };
    ```
{% endfold %}

类的定义就是这样，虽然很长我们分四个部分来看就好了。我在代码中用分割线标注了，当然我自己的源代码中没有这样的线:p。
+ 第一部分就是从文件中编译或者加载出shader的字节码。
+ 第二部分就是在运行过程中，我们将shader绑定到管线，或者更新Constant Buffer数据是需要的方法。
+ 第三部分就是正如开头介绍使用方式时说的传递Constant Buffer的方法，基本上适配的所有类型。因为不管怎么样我还是有SetData来通吃所有类型:p。
+ 第四部分就是具体处理Shader Reflection来填充诸如m_constantBufferLookup的数据结构的方法。
+ 第五部分提供类内部的快速查找变量的方法，不考虑字符串创建的消耗的话，都是常量时间的读取消耗。因为这个部分会被外部通过第三部分频繁访问。

### BasePass
{% fold BasePass.h %}
```C++
#pragma once

#ifndef __BASE_PASS_H__
#define __BASE_PASS_H__

#include "EngineHeader.h"

#include "Shaders.h"

namespace RE
{
    class RenderObject;

    class BasePass
    {
    public:
        BasePass() = default;
        ~BasePass() = default;
        BasePass(const BasePass &) = delete;
        BasePass(BasePass &&) = delete;
        BasePass& operator=(const BasePass &) = delete;

    public:
        virtual void Initialize() = 0;
        virtual void Render(const std::vector<std::unique_ptr<RenderObject>> &in_renderObjects) {};
        virtual void RenderAsPostProcess(ID3D11ShaderResourceView **in_shaderResourceViews, UINT in_numShaderResourceViews) {};

    protected:
        virtual void BeginPass();
        virtual void ApplyPass();
        virtual void EndPass();

    protected:
        std::unique_ptr<VertexShader> m_vertexShader;
        std::unique_ptr<PixelShader> m_pixelShader;
    };
}

#endif // !__BASE_PASS_H__
```
{% endfold %}

什么是pass呢，我最近在看知乎上的这个问题：[计算机图形里面的RenderingPass（渲染通道）是什么意思？](https://www.zhihu.com/question/305707508/answer/632552118)。里面有不少干货呢！而我暂时理解的pass其实和上面的类结构差不多（暂时只放了VS和PS）。

### BaseEffect
{% fold BaseEffect.h %}
```C++
#pragma once

#ifndef __BASE_EFFECT_H__
#define __BASE_EFFECT_H__

#include "EngineHeader.h"

#include "BasePass.h"
#include "RenderTarget.h"

namespace RE
{
    class BaseEffect
    {
    public:
        BaseEffect() = default;
        virtual ~BaseEffect() = default;
        BaseEffect(const BaseEffect &) = delete;
        BaseEffect(BaseEffect &&) = delete;
        BaseEffect& operator=(const BaseEffect &) = delete;

    public:
        virtual void Initialize();
        virtual void Render(const std::vector<std::unique_ptr<RenderObject>> &in_renderObjects) = 0;
        void RenderFinalRenderTarget(ID3D11ShaderResourceView * in_shaderResourceView);
        ID3D11ShaderResourceView *GetFinalRenderTargetShaderResourceView();

    protected:
        std::unique_ptr<RenderTarget> m_finalRenderTarget;
    };
}

#endif // !__BASE_EFFECT_H__
```
{% endfold %}

想了半天还是觉的叫Effect好些，因为我这里的设计还是不是很靠近FX里面的Technique的。因为我把Effect最终渲染结果和中间结果都放在了各自的RenderTarget中。即是往一个全屏quad上渲染一张贴图。这么做的好处是我可以写出如下的代码：
```C++
        {
            const char* items[] = { "Basic", "Shadow Map", "PBR" };
            static int item_current = 2;
            ImGui::Combo("Effect", &item_current, items, IM_ARRAYSIZE(items));

            if (item_current == 0)
            {
                m_basicEffect->Render(m_renderObjects);
                RenderFinal(m_basicEffect->GetFinalRenderTargetShaderResourceView());
            }
            else if (item_current == 1)
            {
                m_shadowMapEffect->Render(m_renderObjects);
                RenderFinal(m_shadowMapEffect->GetFinalRenderTargetShaderResourceView());
            }
            else if (item_current == 2)
            {
                m_PBRBasicEffect->Render(m_renderObjects);
                RenderFinal(m_PBRBasicEffect->GetFinalRenderTargetShaderResourceView());
            }
        }
```

当然Effect可以有多个Pass比如在Shadow Map Effect中：
```C++
    void ShadowMapEffect::Render(const std::vector<std::unique_ptr<RenderObject>>& in_renderObjects)
    {
        m_depthRenderTarget->BindDSVOnly();
        m_lightViewDepthPass->Render(in_renderObjects);

        ImGui::Begin("Light View Depth");
        ImGui::Image(m_depthRenderTarget->GetShaderResourceViewDS(), ImVec2(512.0f, 512.0f));
        ImGui::End();


        m_shadowMappingRenderTarget->BindRTVAndDSV();
        m_shadowMappingPass->Render(in_renderObjects, m_depthRenderTarget->GetShaderResourceViewDS());

        RenderFinalRenderTarget(m_shadowMappingRenderTarget->GetShaderResourceViewRT(0));
    }
```
可以很轻松地在各个渲染效果中切换，如下图。

![](Snipaste_2019-03-26_13-37-33.png)

# 结语
当前还只是初步的搭建了框架，不过基本的思路已经清晰了，还需要继续完善。接下来把以前抄过的教程代码来慢慢写到新框架来把。