---
title: UE4 Skeletal Animation System探究之Pose Asset
date: 2019-04-05 19:21:33
tags: [UE4.22, Animation]
categories: Tech
---

Skeletal Animation System中有一种资源类型叫做Pose Asset。它是可以使用Curve驱动来用来制作表情动画的基础资源文件。官方文档中只是草草演示了一下，关于它的介绍网络上比较少。本文就自己的理解介绍下PoseAsset的基本概念和使用方式。
<!--more-->

# Pose Asset基本概念

## Pose的概念
首先我们要理解Pose在UE4中的概念。因为这个Pose出现的地方很多，比如在Anim Graph中使用Montage时需要用Slot Node来Blend Montage Animation到我们指定的Pose，而常规的Blend Node操作的目标都是Pose。那么Pose究竟作何理解呢？顾名思义，Pose可以翻译为“姿势”，描述的是某个比较固定的动作状态。因此，排除时间的影响，那么我可以理解为对应某个时刻，骨骼处于的的空间变换状态。程序上的定义就是：
```C++
USTRUCT()
struct ENGINE_API FPoseData
{
	GENERATED_USTRUCT_BODY()

#if WITH_EDITORONLY_DATA
	// source local space pose, this pose is always full pose
	// the size this array matches Tracks in the pose container
	UPROPERTY()
	TArray<FTransform>		SourceLocalSpacePose;

	// source curve data that is full value
	UPROPERTY()
	TArray<float>			SourceCurveData;
#endif // WITH_EDITORONLY_DATA

	// local space pose, # of array match with # of TrackToBufferIndex
	// it only saves the one with delta as base pose or ref pose if full pose
	UPROPERTY()
	TArray<FTransform>		LocalSpacePose;

	// this is PoseContainer.Tracks to Buffer Index of LocalSpacePose
	UPROPERTY()
	TMap<int32, int32>		TrackToBufferIndex;

	// # of array match with # of Curves in PoseDataContainer
	// curve data is not compressed
 	UPROPERTY()
 	TArray<float>			CurveData;
};

```
上述定义来自于`FPoseData`，通过`LocalSpacePose`就可以很轻易看出定义，

### Reference Pose


## Pose Asset
首先我们要明白一点PoseAsset不是直接的动画资源，它是自既有的动画资源来创建的。比如从Animation Sequence、Animation Montage甚至是Pose Asset中创建。而创建方式一般分为两种，如下图显示的入口：
![](Snipaste_2019-04-07_20-56-34.png)

### 从Current Animation创建
一般这种方式还是从Animation Sequece Asset来创建，其他类型只能生成空的Pose Asset资源（按我的尝试，如果没有错误操作的话）。

+ Per Pose Per Frame
![](Snipaste_2019-04-07_21-00-13.png)
`每一个关键帧都会生成一个Pose数据`，这个很好地对应了之前介绍的Pose的概念，一个时间点对应的骨骼的变换数据。另外我们也要理解Pose Asset是一系列的Pose的合集。

### 从Current Pose创建
这个Current Pose是当前动画预览在操作发起时,动画预览（如果正在动画播放，则是卡住UI线程的取一个时间点）对应的Pose。

无论哪种方式我们都会获得一个Pose Asset，里面包含零至多个Pose数据。值得注意的是，这个过程也会按一个Pose Name一个Curve的对应关系来创建Curve，且Curve的名字和对应的Pose Name一致。实际上，每当一个Pose Name第一次出现的时候，就会自动创建一个同名字的Curve。编辑器中保证了Pose Name的唯一性，因此在重命名时一定要注意如果目标名字和某个Curve名字一样时可能会产生冲突的问题。

## Create Animation From Pose Asset
能从Animation Sequece中创建Pose Asset，当然也能从Pose Asset来创建Animation Sequence。这项操作也有两种方式，一种是从Current Pose创建，一种是从Reference Pose创建。需要注意的是一般只使用From Current Pose且保证至少一个Pose数据上的Weight是有效的，不然的话Current Pose就和Reference Pose一样了。

创建之后获得的是一个"空帧"的Animation Sequence,注意这里的“空帧”表示的是没有关键帧数据，也就是说

![](Snipaste_2019-04-08_10-13-27.png)



