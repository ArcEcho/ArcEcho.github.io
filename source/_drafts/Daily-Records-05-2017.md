---
title: Daily-Records-05-2017
tags:
---

### 01/05/2017
skn material 可以选择起始的index和vectex来实现多个材质，类似

动画这部分要从原理上来理解，感觉还是有很多东西没有搞清楚，毕竟讲不出这么实现的。感觉把这边原理弄清楚了，对建模工具的使用会更有帮助。


### 04/05/2017
fastdelegate可能和我预想的delegate版本比较类似。可能需要借鉴下然后改变我原本的delegate的写法。

### 05/05/2017
如何导出类静态变量
> [exporting-static-data-in-a-dll](http://stackoverflow.com/questions/2479784/exporting-static-data-in-a-dll) ?
> 百科释义：静态成员，声明为static的类成员或者成员函数便能在类的范围内共同享，我们把这样的成员称做静态成员和静态成员函数。
> 避免声明静态成员变量?
> 静态成员变量时保证成员数据不随实例发生变化
> 静态成员不占用类内存空间
> 静态成员提供了类名访问方式即`A:Sm`的访问方式。
> 一般不要直接访问静态成员？


[Dll和lib的区别](http://www.cnblogs.com/TenosDoIt/p/3203137.html)

C++11 singleton标准做法
```cpp
class Singleton {
public:
  static Singleton& getInstance(){
    static Singleton instance;
    return instance;
  }
};
```

二段构造的取舍?

### 07/05/2017
shader macro究竟如何使用？
> + 在compile shader的时候可以传入一定的预处理宏（preprocessor marco），但是这只限于compile时。

关于InputLayout的处理，
顶点数据可能和shader所需要的input不一样，这个怎么处理呢？

### 08/05/2017
dxgi 到底是做什么的？
> DirectX Graphics Infrastructure

那些dxgi及类似的一些对象后面的数字（DXGI_SWAP_CHAIN_DESC1）是什么意思, 由什么区别？
> [DXGI 1.4 Improvements](https://msdn.microsoft.com/en-us/library/windows/desktop/mt427784%28v=vs.85%29.aspx#direct3d_12_swapchain_changes)
D3D12 D3D12_INFO_QUEUE？

### 09/05/2017
从model viewer做起把，感觉自己过于愚笨。。。

To help manage the lifetime of COM objects, the Windows Runtime Library (WRL)
provides the Microsoft::WRL::ComPtr class (#include <wrl.h>), which can
be thought of as a smart pointer for COM objects. When a ComPtr instance goes out of
scope, it will automatically call Release on the underlying COM object, thereby saving
us from having to manually call Release.

2D  Texture:
+ store 2D image data
+ in advcanced technique callled normal mapping to store information.
> Thats to say demosion of texture is just to indicate how data is aranged and its usage depends on the element format.
 
 Texture cannot store arbitrary kinds of data elements.It can only store certain kinds of data element formats,which are described by DXGI_FORMAT enumaerated type.

 However, GPU resources are not bound directly. Instead, a resource is referenced through
a descriptor object, which can be thought of as lightweight structure that describes the
resource to the GPU. Essentially, it is a level of indirection; given a resource descriptor,
the GPU can get the actual resource data and know the necessary information about it. We
bind resources to the rendering pipeline by specifying the descriptors that will be
referenced in the draw call.
Why go to this extra level of indirection with descriptors? The reason is that GPU
resources are essentially generic chunks of memory. Resources are kept generic so they
can be used at different stages of the rendering pipeline; 

> *A view is a synonym for descriptor. The term “view” was used in previous
versions of Direct3D, and it is still used in some parts of the Direct3D 12 API.
We use both interchangeably in this book; for example, constant buffer view and
constant buffer descriptor mean the same thing.*

descriptor heapWe 
> + A descriptor heap is an array of descriptors;
> + It is the memory backing for all the descriptors of a particular type your application use
> + We can have multiple descriptors referencing the same resource

Descriptors should be created at initialization time. This is because there is some type
checking and validation that occurs, and it is better to do this at initialization time rather
than runtime.
> **The August 2009 SDK documentation says: “Creating a fully-typed resource
restricts the resource to the format it was created with. This enables the runtime
to optimize access […].” Therefore, you should only create a typeless resource if
you really need the flexibility they provide (the ability to reinterpret the data in
multiple ways with multiple views); otherwise, create a fully typed resource.**

IGIESW

[residency](https://msdn.microsoft.com/en-us/library/windows/desktop/mt186622%28v=vs.85%29.aspx)

ID3D12Fence: used to synchronize the GPU and CPU

resource transition state

resource barriers

A few things to note about command list multithreading:
+ 1. Command list are not free-threaded; that is, multiple threads may not share the same command list and call its methods concurrently. So generally, each thread will get itsown command list.
+ 2. Command allocators are not free-threaded; that is, multiple threads may not share the same command allocator and call its methods concurrently. So generally, each thread will get its own command allocator.
+ 3. The command queue is free-threaded, so multiple threads can access the command queue and call its methods concurrently. In particular, each thread can submit their generated command list to the thread queue oncurrently.
+ 4. For performance reasons, the application must specify at initialization time the maximum number of command lists they will record concurrently.


### 10/05/2017
CBV 
SRV
UAV

sample desc & MSAA？？？

root signature

pipeline state object

Debug layer

> The debug layer provides extensive additional parameter and consistency validation (such as validating shader linkage and resource binding, validating parameter consistency, and reporting error descriptions).
The header required to support the debugging layer, D3D12SDKLayers.h, is included by default from d3d12.h.
When the debug layer lists memory leaks, it outputs a list of object interface pointers along with their friendly names. The default friendly name is "<unnamed>". You can set the friendly name by using the ID3D12Object::SetName method. Typically, you should compile these calls out of your production version.
We recommend that you use the debug layer to debug your apps to ensure that they are clean of errors and warnings. The debug layer helps you write Direct3D 12 code. In addition, your productivity can increase when you use the debug layer because you can immediately see the causes of obscure rendering errors or even black screens at their source. The debug layer provides warnings for many issues. For example:
Forgot to set a texture but read from it in your pixel shader.
Output depth but have no depth-stencil state bound.
Texture creation failed with INVALIDARG.
Set the compiler define D3DCOMPILE_DEBUG to tell the HLSL compiler to include debug information into the shader blob.
#define D3DCOMPILE_DEBUG 1
For details of all the debug interfaces and methods, refer to the [Debug Layer Reference](https://msdn.microsoft.com/en-us/library/windows/desktop/dn950151(v=vs.85).aspx).
For overview information on using the debug layer, refer to [Understanding the D3D12 Debug Layer]().


Root descriptors?

triangle list 和 triangle strip

### 11/05/2017
[Create discriptors](https://msdn.microsoft.com/en-us/library/windows/desktop/dn859358(v=vs.85).aspx#index_buffer_view)

index buffer view and vertex buffer view hold the GPU virtual address.

drirectX slot

#### 流水线状态对象
在Direct3D 11中，流水线状态通过一大堆独立无关的对象来操控。比如， input assembler状态、pixel shader状态、rasterizer状态、以及output merger状态都是可以独立修改的。这给图形流水线提供了一个方便而相对高层的表达。但是，这不能很好地映射到现代的硬件上。这主要是因为不同的状态之间经常有相互依赖。比如，很多GPU把pixel shader和output merger状态合并成了单个硬件，但因为Direct3D 11允许分开设置，驱动在状态最终确定前，也就是draw call的时候，是无法提前设置硬件状态的。这会让硬件状态设置产生延迟，也就是额外的开销，造成每帧的draw call变少。

Direct3D 12通过把多个流水线状态统一成一个流水线状态对象（PSO）来解决这个问题。这个对象在建立后就不可改变，表达了所有状态的最终取值。这让硬件和驱动可以立刻把PSO转化成GPU执行所需的硬件原生指令和状态。动态切换PSO的时候，硬件只需要把少量预计算的状态直接拷贝到硬件寄存器，而不用每次都重新计算硬件状态。这意味着可以明显减少draw call的开销，以提高每帧的draw call数量。

#### 命令列表和命令包
在Direct3D 11里，所有的任务提交都是通过immediate context来完成的，它代表了一个通向GPU的命令流。游戏也经常用deferred context来充分利用多线程，但和PSO一样， deferred context也不能完美地映射到硬件，所以deferred context能帮忙的事情也相对较少。

Direct3D 12引入了一种新的任务提交模型。它的基础是新的命令列表（command list），包含了需要在GPU上执行一个特定工作的所有信息。每个命令列表都包含了用哪个PSO，需要哪些texture和buffer资源，以及所有draw call的参数。因为每个命令列表都是自我包含的，而且不继承任何状态，所以驱动可以在多个独立线程里提前预计算好所有需要的GPU指令。唯一需要顺序操作的只有最终通过命令队列（command queue）把命令列表提交给GPU的时候，这部分本身就已经相当高效。

除了命令列表之外，Direct3D 12也引入了第二层任务预计算机制，命令包（bundle）。命令列表是完全自我包含的，典型用法是构造、提交一次、丢弃。与之不同的是，命令包允许状态继承，更方便重用。比如，如果一个游戏要画两个纹理不同的人物模型，方法之一是记录一个命令列表，包含两组相同的draw call。另一种方法是把画单个人物模型命令“记录”到一个命令包里，然后在命令列表上用不同的资源“播放”这个命令包两次。对后者来说，驱动仅需要计算一次相应的指令，然后建立一个只包含两次低开销函数调用的命令列表。

#### 描述库和描述表
Direct3D 11中的资源绑定非常抽象和方便，但很多现代硬件的能力都被浪费了。在Direct3D 11里，游戏建立出资源的“view”对象，然后把这些view绑到流水线中不同shader的“slot”上。Shader在draw的时候就从显式绑定的slot中读取数据。这个模型意味着只要游戏想要换个资源绘制，就必须重新把不同的view绑定到不同的slot上，然后才能绘制。这个开销也可以通过充分利用现代硬件的能力来去除。

Direct3D 12把绑定模型改成符合现代硬件的样子，从而显著提高性能。Direct3D 12不再需要独立的资源view并显式映射到slot，而是提供了一个描述库（descriptor heap），让游戏可以在里面建立各种资源view。这个机制让GPU可以提前把硬件原生的资源描述直接写入内存。要声明哪个资源被某个draw call的流水线用到了，游戏需要在描述库的某个区域设立一个或多个描述表。因为描述库中已经被提前写入硬件相关的描述数据，所以更改描述表来引用不同描述数据的开销相当低。

除了用描述库和表提高性能之外，Direct3D 12还允许资源在shader中动态索引，由此带来了空前的灵活性，并使新的渲染技术成为可能。比如，现代的延迟渲染引擎往往把材质和物体ID编码到某个中间g-buffer上。在Direct3D 11中，引擎必须避免使用太多材质，因为在一个g-buffer中包含太多材质会显著低降慢最终的渲染。如果有了动态索引资源，渲染包含上千种材质的场景可以和渲染只包含十种材质的场景一样快。

IASetVertexBuffers
IASetVertexBuffer
slot
但是inputlayout还是得自行创建

The vertex data and input signature do not need to match exactly

### 16/05/2017
- [] LOL file skn importer.

std::bind should not use *this.

take care about const member function 

> + low-level const:
> + high-level const:

balance of using raw pointer and 

> PSO state changes should be kept to a minimum for performance. Draw all
objects together that can use the same PSO. Do not change the PSO per draw
call!

> Because PSO validation and creation can be time consuming, PSOs should
be generated at initialization time. One exception to this might be to create a
PSO at runtime on demand the first time it is referenced; then store it in a
collection such as a hash table so it can quickly be fetched for future use.

### 22/05/2017
> Do not go overboard with the number of constant buffers in your shaders.
Keep them under five for performance.

*Balance between root signature size and switching root signature*
> For performance, we should aim to keep the root signature small. One reason for this is the automatic versioning of the root arguments per draw call. The larger the root signature, the larger these snapshots of the root arguments will be. Additionally, the SDK documentation advises that root parameters should be ordered in the root signature from most frequently changed to least frequently changed. The Direct3D 12 documentation also
advises to avoid switching the root signature when possible, so it is a good idea to share the same root signature across many PSOs you create. In particular, it may be beneficial to have a “super” root signature that works with several shader programs even though not all the shaders uses all the parameters the root signature defines. On the other hand, it also depends how big this “super” root signature has to be for this to work. If it is too big, it could cancel out the gains of not switching the root signature

> Recent versions of Direct3D have introduced new features to lessen the need for dynamic buffers. For instance:
1. Simple animations may be done in a vertex shader.
2. It is possible, through render to texture or compute shaders and vertex texture fetch functionality, to implement a wave simulation like the one described above that runs
completely on the GPU.
3. The geometry shader provides the ability for the GPU to create or destroy primitives, a task that would normally need to be done on the CPU without a geometry shader.
4. The tessellation stages can add tessellate geometry on the GPU, a task that would normally need to be done on the CPU without hardware tessellation.
Index buffers can be dynamic, too.



### 28/05/2017
volatile 


### 30/05/2017
Apps are required to explicitly manage resource lifetime in the heaps.

 SRV or UAV root descriptors can only be Raw or Structured buffers