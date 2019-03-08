---
title: 在UE中使用LoadingScreen
date: 2017-04-20 18:35:06
tags: [UE4, UE4.15.x, C++]
categories: Tech
---
在进入游戏时或者加载地图时我们通常会使用LoadingScreen来防止用户看到加载过程。在UE中如何使用呢？

<!--more-->
### 播放游戏起始的动画
UE4自己提供了播放游戏起始动画的入口，只需要在Project Setting->Movies设置中添加我们需要播放的视频即可。
> 注意似乎比较旧的引擎版本下，对播放的影片的尺寸及帧率什么的都是有需求的。但是在4.15.1版本下好像是没有问题的。

### 加载界面的实现
网上大多数教程都是蓝图的，且官方也是推荐使用streaming level的方式来加载地图，在这样的情形下来实现部分加载界面是可以很简单的完成的。但是这么做是有局限性的：
+ 如果无法避免地图过大的情况，则使用streamin level是不现实的。这种情况下需要使用`SetClientTravel`的方式来加载地图了，也就是调用`UGameplayStatics`(即蓝图里面的函数)的`OpenLevel`方式。这种方式下，加载地图的时候，引擎的主线程是被占用的，也就是说此时的UMG什么的是无法使用的。
+ 启动游戏时如果要显示加载界面而不是播放片头动画的话，蓝图也是无法实现的。因为在直到蓝图支持的模块启动完毕之前这段时间，蓝图是无法使用的，故也就不能显示加载界面了。

### 用C++实现加载动画
从上面的分析可以看出来，有些东西还是必须要用C++来实现的。我们可以利用UE4提供的`MoviePlayer`来帮助我们完成我们要用的功能，而用C++实现主要有三个思路。
#### 在GameInstance中hook PreLoadMap来实现
Wiki中有一篇关于[LoadingScreen实现的文章](https://wiki.unrealengine.com/Loading_Screen)。主要实现方式是在GameInstance初始化的时候，将我们的事件处理函数绑定在`PreLoadMap`委派上。在该处理函数中使用`FLoadingScreenAttributes`来显示我们的加载界面。代码如下：
```cpp
//MyGameInstance.h

public:
	virtual void Init() override;
 
	UFUNCTION()
	virtual void BeginLoadingScreen(const FString& MapName);
	UFUNCTION()
	virtual void EndLoadingScreen();

```
```cpp
//MyGameInstance.cpp

    void UMyGameInstance::Init()
{
	UGameInstance::Init();
 
	FCoreUObjectDelegates::PreLoadMap.AddUObject(this, &UMyGameInstance::BeginLoadingScreen);
	FCoreUObjectDelegates::PostLoadMap.AddUObject(this, &UMyGameInstance::EndLoadingScreen);
}
 
void UMyGameInstance::BeginLoadingScreen(const FString& MapName)
{
        if (!IsRunningDedicatedServer())
	{
 		FLoadingScreenAttributes LoadingScreen;
	 	LoadingScreen.bAutoCompleteWhenLoadingCompletes = false;
 		LoadingScreen.WidgetLoadingScreen = FLoadingScreenAttributes::NewTestLoadingScreenWidget();
 
	 	GetMoviePlayer()->SetupLoadingScreen(LoadingScreen);
        }
}
 
void UMyGameInstance::EndLoadingScreen()
{
 
}
```
注意`LoadingScreen.WidgetLoadingScreen = LoadingScreenAttributes::NewTestLoadingScreenWidget();` 这句代码我们可以使用我们自己的SWidget来作为加载界面,类似如下代码:
```cpp
	LoadingScreen.WidgetLoadingScreen =  SNew(SMyLoadingScreen);
```

#### 参照Showcase（PlatformerGame或者ShooterGame）的实现。
ShowCase中将LoadingScreen抽成了一个单独的模块来使用。使用时注意，我们需要在`.uproject`(UE4工程文件)中正确的定义其加载阶段，如下(JSON格式的文件)：
```
{
	"FileVersion": 3,
	"EngineAssociation": "4.15",
	"Category": "",
	"Description": "",
	"Modules": [
		{
			"Name": "TestLoadingScreen",
			"Type": "Runtime",
			"LoadingPhase": "Default",
			"AdditionalDependencies": [
				"Engine"
			]
		},
		{
			"Name": "MyLoadingScreen",
			"Type": "Runtime",
			"LoadingPhase": "PreLoadingScreen",
			"AdditionalDependencies": [
				"Engine"
			]
		}
	]
}
```
**这里需要设置其LodaingPhase为PreLoadingScreen**,这样才能在第一次进游戏的时候显示我们的加载画面。这里插一下LoadingPhase有哪些：

```cpp
namespace ELoadingPhase
{
	enum Type
	{
		/** Loaded before the engine is fully initialized, immediately after the config system has been initialized.  Necessary only for very low-level hooks */
		PostConfigInit,

		/** Loaded before the engine is fully initialized for modules that need to hook into the loading screen before it triggers */
		PreLoadingScreen,

		/** Right before the default phase */
		PreDefault,

		/** Loaded at the default loading point during startup (during engine init, after game modules are loaded.) */
		Default,

		/** Right after the default phase */
		PostDefault,

		/** After the engine has been initialized */
		PostEngineInit,

		/** Do not automatically load this module */
		None,

		// NOTE: If you add a new value, make sure to update the ToString() method below!
		Max
	};
}
```
上面的代码可以很清楚的看到只有在这个阶段加载我们的模块才能正常的使用。

模块里面具体实现加载界面的部分是在`StartModule`的时候直接使用`FLoadingScreenAttributes`创建并显示加载界面。
```cpp
class FPlatformerGameLoadingScreenModule : public IPlatformerGameLoadingScreenModule
{
public:
	virtual void StartupModule() override
	{		
		// Load for cooker reference
		LoadObject<UObject>(NULL, TEXT("/Game/UI/Menu/LoadingScreen.LoadingScreen") ); 

		if (IsMoviePlayerEnabled())
		{
			CreateLoadingScreen();
		}
	}


	virtual bool IsGameModule() const override
	{
		return true;
	}

	virtual void StartInGameLoadingScreen() override
	{
		CreateLoadingScreen();
	}

	void CreateLoadingScreen()
	{
		FLoadingScreenAttributes LoadingScreen;
		LoadingScreen.bAutoCompleteWhenLoadingCompletes = true;
		LoadingScreen.WidgetLoadingScreen = SNew(SPlatformerLoadingScreen);
		GetMoviePlayer()->SetupLoadingScreen(LoadingScreen);
	}
};
```
> 但是经过我的实验，它这种实现方式必须要和其内置的`GameMenuBuilder`来配合使用，在代码中直接调用`CreateLoadingScreen`似乎没有办法显示加载界面（由于我对UE4还是不是很了解，暂时还不知道原因），虽然相应的SWidget的Construct函数都被调用了。

#### 使用UE官方代码库中的LoadingScreen插件
[代码库位置](https://github.com/ue4plugins/LoadingScreen)
插件基本上是前两种实现方式的结合。其实现的核心部分是给`MoviePlayer`的`OnPrepareLoadingScreen`委派上添加自己的处理函数。这个实际上是和第一种方式是一致的（该委派实际上就放在PreLoadMap的处理函数进行BroadCast）。然后插件本身就是一个模块，这是第二种方式更加高级的用法了。
> 使用该插件的时候需要注意：
- 我当前使用的版本是4.15.1**（4/20/207）**而作者代码库中的版本已经改为了4.16的写法所以这里需要做一些改动 。具体见这个[issue](https://github.com/ue4plugins/LoadingScreen/issues/15)。

### 总结
上面三种方式各有优缺点，第一种十分直接，具有非常高的可定制性。而最后一种可以非常方便迁移到别的工程来使用，但是缺点是由于是插件不好扩展。而中间那种方式，如果不需要复杂的界面设计的话可以使用下，这个均分了前两种的优缺点，但是注意我上面提到的局限性。
**最后强调版本UE4.15.1，且在尝试展示加载界面的时候请使用StandAlone模式来运行游戏。**

> 相关讨论的帖子:
[Nick Darnell Loading Screen Plugin - GREAT! But I have some questions](https://forums.unrealengine.com/showthread.php?114999-Nick-Darnell-Loading-Screen-Plugin-GREAT!-But-I-have-some-questions&styleid=7#post556047)