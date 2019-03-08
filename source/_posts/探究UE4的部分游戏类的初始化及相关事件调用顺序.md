---
title: 探究UE4的部分游戏类的初始化及相关事件调用顺序
date: 2017-04-08 00:05:58
tags: [UE4, UE4.15.x]
categories: Tech
---
为什么写这篇文章呢？因为学习UE4已经一月有余了，想通过写技术博客的方式来总结一下所学的东西，也想锻炼下语言组织和写作能力。这是一个开端，希望自己能坚持下去。这篇文章会很浅显，只是基于观察，然后分析，最后总结下一些东西。
<!-- more -->   

UE4很灵活，灵活到可以把代码写在各种地方来完成所需的游戏逻辑。这一点实际上可以从youtube上的大多数教程以及github的一些开源工程中可以看出来。因为这些教程都比较基础和零散，很少有比较完整的例子，加上很多作者也是把自己学到的东西分享出来的。这样就导致了当我在看完大部分教程后想自己完成一个像模像样的游戏时不知道从何处开始。虽然绝大多数人都不能一次性就写出非常优美和完善的代码，但是如果最开始不把一些最基础的概念弄清楚，而是胡乱的堆砌功能的话，最终会使得代码难以维护。也许对于个人项目来说，这感觉太过于麻烦。但是鉴于我上一个公司的在职经历，我认为尽量让代码更有条理性是非常有必要的。
那么如何在UE4中来合理的组织自己的逻辑呢？这是一个很难回答的问题，我也在慢慢研究中。虽然难，但是如何做也有迹可循的，阅读官方文档和范例源码，尤其是范例源码。我们会对UE4的[GamePlay Fraemwork](https://docs.unrealengine.com/latest/INT/Gameplay/Framework/index.html)为我们提供一些基本的游戏类有基本的了解。这些游戏类是支持游戏玩法的基石，我们的游戏就是要通过合理组织他们，编写规则来完成。另外的表现相关的东西之于GamePlay的游戏类，如同皮肉之于血骨。无骨不成形，无血则无代谢。过多详情这里就不再累述了，这篇文章还是要和标题相对应。
GamePlay Framework有对[Game Flow](https://docs.unrealengine.com/latest/INT/Gameplay/Framework/GameFlow/index.html)有过介绍。但是非常简略，如下图：
![](官方的流程.png)
这个简单的流程在代码层面的指导意义太弱了。就代码而言，也就是C++，我们知道一个类会被进行构造、始化等等操作。UE4的C++是被魔改了的，且还有蓝图的使用方式。那么谈到代码的流程无外乎就是一些类的初始化顺序以及部分方法的调用顺序的问题。于是我针对这个问题，创建了一个空的C++项目，并创建了相关的游戏类，并在一些关键事件做了打印，这样就得到了如下结果。注意除了GameMode的InitGame有额外的打印外，其他都是一一对应其函数名。
![](部分对象的构造及运行顺序.png)
这里打印了OnConstruction 和 construct， 为什么要打印这两个呢？我最开始一直以为Blueprint中的Construction Script就是C++代码中的Constructor。但是在尝试在C++代码中实现BP中Expose On Spawn的时候发现，C++中并没有直接对应的函数。需要使用SpawnActorDefered函数来实现，按照我最初的理解，那么在被Spawn的Actor的Constructor里应该可以取到赋予的值，但是失败了。为什么失败呢？探究了一下发现执行顺序是这样的：`SpawnActorDefered -> 对应actor的constructor -> UGameplayStatics::FinishSpawningActor -> 对应actor的OnConstruction函数 -> 对应actor的BeginPlay事件`。这就说明了，只要创建一个Actor必定会调用其构造函数，这是遵循C++的规则。这个时候能读到的值只会是初始化列表赋予的，外部无法干涉。要想实现BP中Expose On Spawn功能，那么就需要另外找时机了。那么UE4也就提供了这个机会，在OnConstruction之前把相关的值设置好就行了。即OnConstruction可以认识一个二段构造的写法，且OnConstruction才是一个游戏对象在UE4中正式被创建的时机。后者是和蓝图一致的。为什么说一致的呢？实际上当你打开Actor的头文件的时候，你会发现如下一些注释：
```cpp
	/*
    * ... (UE4.15.1  #Line 79)
    * AActor::OnConstruction - The construction of the actor, this is where Blueprint actors have their components created and blueprint variables are initialized
    * ...
    */

    /**
	 * Called when an instance of this class is placed (in editor) or spawned.
	 * @param	Transform			The transform the actor was constructed at.
	 */
	virtual void OnConstruction(const FTransform& Transform) {}
```
第一段是Actor起始处的注释，后面是对函数本身的注释。这也就验证前面的推测。可能此时你会有另外的疑问，LevelScriptActor为什么只有Constructor而没有OnConstruction打印呢？实际上我也Override了OnConstruction的，但是却没有打印。翻看源码发现LevelScriptActor没有重载这个方法，且OnConstruction需要配套ExecuteConstruction这个使用，这里属于设计上的问题，并且可以观察到在关卡蓝图中是没有Construction Script的，这一点也更是验证了前面所述的一致性。

BeginPlay事件基本上是在所有这些基础的游戏类构建初始化发生的，即基础数据准备好了才是游戏正式开始。此处看代码是GameState调用的NotifyBeginPlay然后调用各个BeginPlay事件，是在一个但是不知道是基于什么原因，是保持这个顺序的，PlayerController第一，然后LevelScriptActor最后。这个暂时作为一个问题放在这里，后面会继续研究。

我还做过别的打印，虽然这里没有体现但是还是值得提下。在编辑器的Project Setting中的Map&Mode选项的设定中，我们会发现DefaultPawn以及HUD是可以被设置成None，且运行后没有相应的Actor创建。这也就说明GameMode必须要PlayerController，却不一定要Pawn，这点可以从很多类型的游戏看出，比如扫雷什么的。但是是一个游戏必须要有GameMode，虽然WorldSetting和ProjectSetting中可以同时设置Override GameMode为None，但是你会发现在运行后会创建出一系列的GameMode相关的东西。所以不要纠结于对于GameMode只存在于Server的解释了。然后4.14将GameModeBase抽出来也是这么个考虑。其实可以换个思路考虑，单机游戏在UE4里可以看作是联网游戏的退化版本，毕竟UE4的历史是《虚幻竞技场》。

写在最后：
> 好了差不多就是这么简单的一篇文章了，写完才发现，写技术博客是一件艰难的事情啊，需要组织语言，知识片段。完全不像记笔记的时候随便怎么写就可以，而且很耗时间。但是这个整理的过程确实对自己很有帮助，记录的笔记比较杂乱，很容易就不管了，也不便于自己的查找，不整理的话，过一段时间就等于没有了。所以希望自己能坚持下去。**另外对于文章中的错误请不吝赐教和质疑**。