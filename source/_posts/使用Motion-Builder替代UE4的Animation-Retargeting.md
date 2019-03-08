---
title: 使用Motion Builder替代UE4的Animation Retargeting
date: 2018-02-01 17:33:34
tags: [UE4, Motion Builder, Motion Builder 2018, Animation]
categories: Tech
---
在UE4制作游戏的时候，往往苦恼于美术资源，尤其是3D动画。动画建模工具往往界面复杂，操作起来更是让人摸不着头脑。好在有一些免费的模型动画资源，比如[Adobe Mixamo](https://www.mixamo.com/)和Epic的官方的资源包。如果只是为了做做demo完全足够了。但是这里面也还是有很多不方便的地方，如果想给角色加个另外角色动作什么的，就会发现很难处理了。因为绝大多数情况下，骨骼、模型和动画很难拆开。为了处理这样一个问题，就有了Animation Retargeting这门技术。UE4也提供了相应的功能支持，见[文档](https://docs.unrealengine.com/latest/INT/Engine/Animation/AnimationRetargeting/index.html)。但是实际使用后，发现UE4这套解决方案流程固然简单，但同时也存在一些问题。比如，不方便编辑调整，在UE4中虽然可以创建新动画，但似乎无法很好的调整每一帧具体的curve，另外，UE4的Retargeting给人感觉似乎是Additive的，即得到结果动画不是很精细。还有就是不方便脚本化，这样对于workflow来说是难以接受的。因此针对以上问题，我们这里需要借助第三方的建模工具了。
<!--more-->
在众多工具中选择了一下，发现Motion Builder（后面简称Mobu，使用版本时Motion Builder 2018）甚是好用，它不仅有友好的UI界面，并且提供了较为详尽的文档以及脚本支持。本文会简单介绍Mobu的一些基本概念及Animation Retargeting的基本操作。

### Mobu的一些基本概念
[Mobu官方帮助站点](http://help.autodesk.com/view/MOBPRO/2018/ENU/)（近几个版本没有中文文档）， 提供了比较详尽的界面介绍以及操作方式，这里就不一一累述了。

#### 基于Character的动画
通常我们所说的骨骼动画，都是针对关节的定义关键帧来生成的。而Mobu同很多动画建模软件一样，把这些都抽象了出来，形成了Character的概念。即大多说动画对象差不多都是二足生物（当然四足的也是能够处理的），它们的骨骼结构大致上类似，我们做好其对一个标准的人形生物的骨骼层级的映射，就可以大致创建了一个Character。这么做的好处是，统一了输入的骨架的信息可以衍生出一系列更通用的功能。比如Control Rig工具，它比传统的一根根Bone来Key动画效率高多了，它还可以用来套用动画数据，我们经常听到的动作捕捉用到了这个。这篇文章所讲的Animation Retargeting也是用到了这个，且在Mobu中一般来说为了更好的Retargeting质量，我们通常都会把基础的骨骼动画数据转换为Control Rig的动画数据，然后套用到其他定义了Control Rig的角色上。   

##### 创建Character
这里是官方提供的教程：[Character Setup](http://help.autodesk.com/view/MOBPRO/2018/ENU/?guid=GUID-12F7FCD3-004E-45E9-85B3-E42C7C51B2F7)
教程还算比较详细，因此不过多累述，只提下一些需要注意的地方：

###### Define Skeleton
+ 在进行Define Skeleton的时候，不必每一个根骨头都要映射上去。因为Mobu提供的是一个非常详尽的骨骼模型，因此通常我们创建的骨骼是少于它的。但是映射时一定要保证连接顺序。如下图，我们只需要定义最初的几根spine骨骼就好了。
![](character_mapping_0.png)
+ Define Skeleton不必每次都手动一根根定义，Character Control面板上有`Save/Load Skeleton Definition`可以导出和导入相同结构的骨骼定义文件。但是这个功能有一个缺点，它只是简单的包含判断，而没有提供全匹配等更严格的限制条件。这样就导致，对于`hand`这样的模板数据，如果同时有`hand`和`hand_ik`，且后者先做判断，则会优先映射后者了。不过这个可以通过撰写脚本来确定自己的规则来替代这部分规则，倒也不是什么特别严重的问题。

###### Characterization和Control Rig
骨骼映射好之后还需要做一个`Characterize`的操作，我们才能有一个可操作的Character。
如下图：
![](character_1.png)
为什么这个子标题要把Characterization和Control Rig关联起来呢？这是因为笔者曾经踩过一个坑，动画数据重定向后胳膊和脚各种不对劲，仔细研究后发现：
+ ``在Control Rig的初始Stance是Characterize之时的骨骼对应的姿势数据。如要完美的Animation Retargeting，必须保证Control Rig初始Stance是标准T Pose。即Characterize之时骨骼处于标准T Pose。``
+ 标准的T Pose在Character Control也会有相应的提示，除了骨骼映射关系要正确以外，还要满足其他一些条件，如手臂需要和X轴平行。下图分别展示了标准和不标准时的界面表现：
![](character_2.png)
![](character_3.png)

#### Control Rig
Control Rig提供了一套可以用来操控角色各个部分的位置，朝向的工具。它还提供了FK、IK相关的工具来帮助我们快速的创建更自然的动画。基本上绝大多数的动画建模软件都提供了这个功能。
![](character_4.png)

##### 创建Control Rig
同样的，这里是[官方教程](http://help.autodesk.com/view/MOBPRO/2018/ENU/?guid=GUID-7461D9D8-5193-4372-A6EF-267D3E9EB534)的链接。


##### Control Rig动画数据和骨骼动画数据的转换
官方教程：[Plotting character animation](http://help.autodesk.com/view/MOBPRO/2018/ENU/?guid=GUID-8E1B13DA-DB2F-48DF-B251-D9DA21E86C21)
Control Rig也是可以建立关键帧动画的，且骨骼动画数据和Control Rig的动画数据数据是互相独立的概念的。在不同skeleton间来进行Animation Retargting，我们需要借助control rig来转移动画数据，这个中间数据实质上就是control rig的关键帧动画。然后一般使用动画时普遍都是基本的骨骼动画，所以我需要把control rig的关键帧动画数据转换到目标skeleton的骨骼动画。这个过程的关键字就是Plot，可以翻译成中文绘制。

### 自制插件
自制的插件：[github地址](https://github.com/ArcEcho/MobuUtils/tree/master/Scripts/Mobu2018)

#### 界面
![](script_01.png)
+ 界面大致元素基本都由[《灵之秘境:异象残影》](http://usecret.shisyu.site/)制作人：终わりの虚妄提出。

#### 演示的例子
[B站地址](https://www.bilibili.com/video/av20694602/)
只是简单的展示了下使用流程

#### 未实现部分
由于对autodesk系列的异步编程的理解不是很透彻，所以本应该有的一个一键完成整个工作流的功能没有实现。后续如果继续了解之后可能会补上。本文主要是介绍下使用外部工具得到更好动画重定向的过程。