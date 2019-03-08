---
title: 蓝图异步节点初探-UBlueprintAsyncActionBase
date: 2017-10-12 14:02:02
tags: [UE4, Blueprint, UE4 C++]
categories: Tech
---
蓝图层面上没有线程概念。那么蓝图中是如何处理异步操作的呢？本文会简单介绍UBlueprintAsyncActionBase，并用其实现简单的异步Http下载文件节点。
<!--More--->
### 阅读本文最好了解以下知识
+ 线程（Thread）
+ 委派（Delegate）
+ Http基础概念

### 自带的异步节点DownloadImage
![](AsyncTaskDownloadImage_node.png)
UE4自带了一个以Http方式下载图片的节点。右上角的时钟标志表明此为一个异步节点
使用方式也是很简单的，输入Url，然后成功下载后在OnSuccess引脚执行流中就可以从Texture引脚得到图片资源。

#### 节点分析
+ 这里可以看到有3个Exec pin，也就是说有3条执行流。Exec Out引脚如果你查看节点复制的文本代码的话，你会发现它被叫做Then引脚。但是实际上这里是一个异步操作，也就是你的图片下载和Exec Out的执行不是先后顺序，而是直接执行Exec out引脚后面的代码，下载过程会被异步执行，然后会各自调用两个On对应的引脚。
+ Texture引脚非常特殊，这个引脚的内容应该且必须在OnSuccess执行流中去访问，这一点会在后面C++代码分析中提到。

#### 对应代码分析
蓝图节点对应代码UAsyncTaskDownloadImage类，其被归类于UMG下的Blueprint文件下。源代码头文件如下：
```cpp
// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "Interfaces/IHttpRequest.h"
#include "Kismet/BlueprintAsyncActionBase.h"

#include "AsyncTaskDownloadImage.generated.h"

class UTexture2DDynamic;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FDownloadImageDelegate, UTexture2DDynamic*, Texture);

UCLASS()
class UMG_API UAsyncTaskDownloadImage : public UBlueprintAsyncActionBase
{
	GENERATED_UCLASS_BODY()

public:
	UFUNCTION(BlueprintCallable, meta=( BlueprintInternalUseOnly="true" ))
	static UAsyncTaskDownloadImage* DownloadImage(FString URL);

public:

	UPROPERTY(BlueprintAssignable)
	FDownloadImageDelegate OnSuccess;

	UPROPERTY(BlueprintAssignable)
	FDownloadImageDelegate OnFail;

public:

	void Start(FString URL);

private:

	/** Handles image requests coming from the web */
	void HandleImageRequest(FHttpRequestPtr HttpRequest, FHttpResponsePtr HttpResponse, bool bSucceeded);
};

```
+ 首先该类继承自UBlueprintAsyncActionBase类，这个是必须的，如果你将这个类代码中的一部分代码直接移植到派生类中，虽然能够编译成功但是会崩溃。这就表明蓝图的解释系统对该类做了特殊的处理，因此生成那种特殊的节点。
+ 注意声明的FDownloadImageDelegate的signature，其参数实际上就是引脚的名称。然后注意类成员OnSuccess和OnFail的顺序，这里仅仅有且仅有第一个Delegate成员的signature会成为节点引脚。请注意这一段话，这个会影响我们后面自己实现一个节点的写法。

cpp代码中主要看下面三个函数
```cpp
UAsyncTaskDownloadImage::UAsyncTaskDownloadImage(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	if ( HasAnyFlags(RF_ClassDefaultObject) == false )
	{
		AddToRoot();
	}
}

UAsyncTaskDownloadImage* UAsyncTaskDownloadImage::DownloadImage(FString URL)
{
	UAsyncTaskDownloadImage* DownloadTask = NewObject<UAsyncTaskDownloadImage>();
	DownloadTask->Start(URL);

	return DownloadTask;
}

void UAsyncTaskDownloadImage::Start(FString URL)
{
#if !UE_SERVER
	// Create the Http request and add to pending request list
	TSharedRef<IHttpRequest> HttpRequest = FHttpModule::Get().CreateRequest();

	HttpRequest->OnProcessRequestComplete().BindUObject(this, &UAsyncTaskDownloadImage::HandleImageRequest);
	HttpRequest->SetURL(URL);
	HttpRequest->SetVerb(TEXT("GET"));
	HttpRequest->ProcessRequest();
#else
	// On the server we don't execute fail or success we just don't fire the request.
	RemoveFromRoot();
#endif
}

```
+ 构造函数中将自己标记为不自动GC，是为了防止GC导致异步任务处理的对象被干掉。所以在执行完毕某些操作后需要手动还原GC标志。
+ DownloadImage方法是一个静态方法，它就是最终暴露出的蓝图节点的主体。这个实际上就有点类似BlueprintFunctionLibrary。但是正如前面说的蓝图解释系统会对其做特殊处理，所以声明的delegate会以Exec pin方式出现，以及第一个delegate成员的signature会成为一个输出引脚。
+ Start方法中注意BindUObject方法，将自身的一个成员函数绑定在了Http处理的委派上。
+ 实际上里Http在调用这些委派的时候不是在其所开辟的线程中调用的，事实上也不应该那么调用，因为在哪个线程执行Delgate那么其处理函数的执行上下文就是在哪个线程。这同时也说明了这个异步节点本身并没有提供实现异步操作的功能，实际上是对C++代码层线程的一个简单的包装，让节点显示的更加简单。
+ 这个节点功能实际上还是比较简陋，比如我们无法得知下载的进度。

### 模仿实现http文件下载的异步节点
```cpp
// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "Interfaces/IHttpRequest.h"
#include "Kismet/BlueprintAsyncActionBase.h"
#include "AsyncTaskDownloadFile.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FDownloadFileUpdateProgressDelegate, int32, ReceivedDataInBytes, int32, TotalDataInBytes,const TArray<uint8>&, BinaryData);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FDownloadFileUnsuccssfullyDelegate);

UCLASS()
class MYPROJECT_API UAsyncTaskDownloadFile : public UBlueprintAsyncActionBase
{
	GENERATED_UCLASS_BODY()

public:
	UFUNCTION(BlueprintCallable, meta=( BlueprintInternalUseOnly="true" ))
	static UAsyncTaskDownloadFile* DownloadFile(FString URL);

public:
	UPROPERTY(BlueprintAssignable, Category = "AsyncTaskDownloadFile", meta = (DisplayName = "On Update Progress"))
		FDownloadFileUpdateProgressDelegate OnUpdateProgress;


	UPROPERTY(BlueprintAssignable, Category = "AsyncTaskDownloadFile", meta = (DisplayName = "On Fail"))
		FDownloadFileUnsuccssfullyDelegate OnFail;

public:

	void Start(FString URL);

private:

	/** Handles image requests coming from the web */
	void HandleFileRequest(FHttpRequestPtr HttpRequest, FHttpResponsePtr HttpResponse, bool bSucceeded);
	void HandleFileRequestProgress(FHttpRequestPtr HttpRequest, int32 BytesSent, int32 BytesReceived);
};

```

```cpp
// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "AsyncTaskDownloadFile.h"
#include "Modules/ModuleManager.h"
#include "Interfaces/IHttpResponse.h"
#include "HttpModule.h"


//----------------------------------------------------------------------//
// UAsyncTaskDownloadFile
//----------------------------------------------------------------------//

UAsyncTaskDownloadFile::UAsyncTaskDownloadFile(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	if (HasAnyFlags(RF_ClassDefaultObject) == false)
	{
		AddToRoot();
	}
}

UAsyncTaskDownloadFile* UAsyncTaskDownloadFile::DownloadFile(FString URL)
{
	UAsyncTaskDownloadFile* DownloadTask = NewObject<UAsyncTaskDownloadFile>();
	DownloadTask->Start(URL);

	return DownloadTask;
}

void UAsyncTaskDownloadFile::Start(FString URL)
{
#if !UE_SERVER
	// Create the Http request and add to pending request list
	TSharedRef<IHttpRequest> HttpRequest = FHttpModule::Get().CreateRequest();

	HttpRequest->OnProcessRequestComplete().BindUObject(this, &UAsyncTaskDownloadFile::HandleFileRequest);
	HttpRequest->OnRequestProgress().BindUObject(this, &UAsyncTaskDownloadFile::HandleFileRequestProgress);
	HttpRequest->SetURL(URL);
	HttpRequest->SetVerb(TEXT("GET"));
	HttpRequest->ProcessRequest();
#else
	// On the server we don't execute fail or success we just don't fire the request.
	RemoveFromRoot();
#endif
}

void UAsyncTaskDownloadFile::HandleFileRequest(FHttpRequestPtr HttpRequest, FHttpResponsePtr HttpResponse, bool bSucceeded)
{
#if !UE_SERVER
	RemoveFromRoot();

	if (bSucceeded && HttpResponse.IsValid() && HttpResponse->GetContentLength() > 0)
	{
		OnUpdateProgress.Broadcast(HttpResponse->GetContentLength(), HttpResponse->GetContentLength(), HttpResponse->GetContent());
		return;
	}

	OnFail.Broadcast();

#endif
}

void UAsyncTaskDownloadFile::HandleFileRequestProgress(FHttpRequestPtr HttpRequest, int32 BytesSent, int32 BytesReceived)
{
#if !UE_SERVER
	if (HttpRequest->GetResponse()->GetContentLength() > 0)
	{
		TArray<uint8> EmptyData;
		OnUpdateProgress.Broadcast(BytesReceived, HttpRequest->GetResponse()->GetContentLength(), EmptyData);
	}
#endif
}
```

先贴代码，然后描述下需要注意的地方：
+ 正如前面所说的，节点只会识别第一个Delegate成员的signature。所以我本来想把Progress和Success分开，但是发现虽然确实能够响应Progress的调用，但是无法传递进度值，因此将它们合并成一个委派了。
+ 声明Delegate时，Dynamic对于TArray必须使用引用传递，否则虽然能够编译通过但是蓝图节点无法通过编译，委派中对于复杂类还是尽量使用引用传递的signature把。

#### 简单的demo
[github地址](https://github.com/ArcEcho/TestBlueprintAsycTask)
代码在之前的DownloadImage的基础上实现了以Http方式下载文件，在下载的同时以进度条展现进度。这里把下载的文件当作文本文件，最后打印出来。
![demo](demo.png)

#### 仍然存在的问题
+ 由于合并了完成和进度更新所以，完成判断会触发两次。



