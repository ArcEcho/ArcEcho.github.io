---
title: 使用UE4制作简单的局域网对战小游戏
date: 2017-04-28 04:15:29
tags: [UE4, UE4.15.x, Blueprint]
categories: Tech
---
大多数文章都是只讲到大致的UE4网络的概念，并未涉及实际使用。事实上在使用的时候还是有很多要注意的地方。这篇文章会展示如何使用蓝图制作一个简单的局域网对战小游戏及使用UE4网络的需要注意的地方。注意示例并非step-by-step,只是列出主干并提及一些需要注意到地方，最后会讨论下自己对UE4网络部分的理解（非完全的概念解释，大部分是自己试验观察并思考的结论），如果有什么错误请不吝赐教。
<!--more-->

## 效果展示
![](2017-04-28-05-48-41.png)

> + [B站视频链接]()
> + 资源和移动表现处理的代码参考及直接引用了[youtube上space shooter tutorial](https://www.youtube.com/watch?v=omU-P1I8RZc&list=PLwmGmCVti_dBUu-57WkLips2kq2bT_4wO)
> + [引用资源及源码下载地址](https://drive.google.com/open?id=0BzL0m5Dhv_4Lcnotd3d6a3NUQ2c)
> + [本示例github链接](https://github.com/ArcEcho/SpaceshipWar)

## 大致思路
这里不过多的累述具体的代码细节，想要了解更多可以直接查看(源码)(https://github.com/ArcEcho/SpaceshipWar)。且先声明下面的讨论建立在我们使用的是Listening server模式下的，因为这个示例中即使用这种模式。

### 所需要的核心成员
#### GameInstance
对应代码里的`BP_SpaceshipWarGameInstance`。GameInstance顾名思义，一个client就拥有这么一个对象的实例。生命周期自游戏创建到游戏结束，不会受关卡切换影响，适合于处理一些全局的事物。像UE4就把类似`NetError`的处理的入口放在GameInstance里面。
![GameInstance的代码总览](2017-04-28-06-16-48.png)
> 官方的示例上面的都是把`CreateSession`放在了GameInstance里面处理，我为了简便直接在Menu的事件响应里面直接处理。

#### GameMode
对应代码里的`BP_BattleGameMode`，注意继承的是GameModeBase，而不是GameMode，这是因为GameModeBase足矣。它制定游戏的规则等，是游戏的核心部分。在Multiplayer中处理玩家登录`OnPostLogin`(在蓝图中关于登录的只有这个事件，但是C++中有额外的PreLogin等处理)后的响应，确定是否要进行比赛等以及玩家得分，对局情况等。
![GameMode代码总览](2017-04-28-06-26-05.png)

### GameState
这个例子中没有扩展GameState，因为暂时没有用到GameState。但是提一下，GameState存在于Server，且各个Client有其copy。里面存储了诸如所有PlayerState等关于游戏client希望能取到的全局数据，用途也由此决定，不累述。

#### PlayerController
对应代码里的`BP_SpaceshipController`。处理脱离`Pawn`无关的操作，如显示等待界面或者向server告知玩家已经准备好进行新一轮比赛的信息等。总的来说，PlayerController是玩家在server的抽象概念，是处理输入的中枢（虽然有一部分操作是在Pawn里面直接处理的，如move和开火等，但是实际上Pawn的输入也来源于PlayerController。相当于派发到Pawn自己处理，这是设计的考量），是沟通server和client时玩家的主要中介。
![PlayerController代码总览](2017-04-28-06-33-56.png)

#### Pawn
对应代码里的`BP_Spaceship`。这个不用多说，我们的操作的对象的表现基本上由它来实现。
![Pawn里面的代码总览](2017-04-28-06-22-53.png)

#### Bullet Actor
对应代码里的`BP_Bullet`。被发射，然后击中敌人就会触发其HP减少，这个检测时在Server完成的。
![Bullet代码总览](2017-04-28-06-37-57.png)

#### PlayerState
对应代码里的'BP_SpaceshipPlayerState',用来存储玩家的血量信息，用以Client表现以及对局输赢的判断。

### 其它辅助的成员
#### UI界面
UI界面很简单，全部使用了UMG来完成，没有使用资源来美化界面，使用了部分UMG动画，如等待时闪烁的动画。且除了在ServerList中的ListItem比复杂一点以外，逻辑什么的都是很简单的，故不累述。
![](2017-04-28-06-52-32.png)

#### CameraShake
当spaceship被击毁时就会产生镜头抖动的效果，很简单实用的功能。

#### 特效
大部分特效是借鉴别人的东西。但是需要注意的是原来的引擎喷射特效的某个Emitter的InitialVelocity是常量，在飞船方向改变时不会变化。这里把这个提升成一个变量，可以通过自己传值来改变其方向。
![](2017-04-28-07-13-47.png)

#### 音效
需要注意的就是简单的处理了下背景音乐，创建一个cue资源，然后设置背景音乐wave为循环播放。
![](2017-04-28-07-17-12.png)

### 制作时需要注意的地方
在制作时有些细枝末节的地方需要注意，且他们隐藏的较深，但是没正确设置不行。下面说一下我在制作时遇到的问题，也会解释解决的方案。

#### 最优先的是需要在配置修改网络配置
简单使用网络功能时请确保在`DefaultEngine.ini`的配置是正确的！！！
![](2017-04-28-08-45-26.png)

#### 关于PlayerController的AutoManageActiveCameraTarget
在场景中放置一个CameraActor，然后各个client改变其roll角并通过`SetViewTargetWithBlend`来使用，会发现只有一个Client（在listening server模式下即server所在的client）上的表现正常，另外一个使用的默认相机。虽然这个可以通过放置两个摄像机来解决，但是按照最初设计那是hack式的做法。正确的解决方案如下：
> 若要在multiplayer game中使用一个固定的camera，则需要关掉PlayerController的 AutoManageActiveCameraTarget，否则不能同时使用一个。

#### 关于Actor的Component的同步问题
我们飞船的在左右移动的时候，其roll角会随速度发生变化，在原来space shooter tutorial中表现正常，但是在multiplayer时却表现出没有正确同步。原因是Actor的component并不会受actor本身的Replicates属性影响，必须自行启用。
> 虽然Pawn的Replicates是默认勾选的，在其下面加上一个Mesh。不勾选ComponentReplicate的时候，在Server端改变其Relative Rotation，则只会在Server端看到效果，Client不会同步变化。勾选之后Client就会同步了。
> 为什么不会自动继承同步呢？因为不是所有的Component都需要在Server去操作然后同步到各个Client的，比如自己的角色下的光圈只需要在当前Client显示，这个光圈可以是一个DecalComponent，它不需要同步。鉴于此种情况，组件同步需要用户手动来启用。

#### UE4默认情况下，当程序被挂起的时候是不播放声音的
这个挂起是指焦点不在程序窗口。这时候UE4不播放声音，我开始还以为是我的代码出错，后面排除并得出了这么个结论。需要修改一些设置之后才行，但是这里没有必要暂不处理。

#### 在哪里以及如何处理类似用户开火及移动的输入
前面在介绍核心成员PlayerController的时候有提到将开火及移动输入的处理放到了Pawn中处理。为什么这么做呢？所有操作不是都是应该由PlayerController来处理么？这个问题恰巧群里也有人问到，我解释了我的看法，这里也提一下把。放在哪里处理是个设计问题，按道理来说确实应该由PlayerController来处理，因为所有用户输入都必须要经过PlayerController，比如我们在`SetInputMode`的时候target是一个PlayerController，通过PlayerController可以BlockInput等等。虽然存在且必须存在一个PlayerController，但是它可能就没有possess任何一个Pawn，实际响应输入的时候，就需要做Pawn是否valid的验证，这真的很麻烦，如果将这个和Pawn直接关联操作响应移到Pawn中处理，这个写判断就可以省去，因为只有Possess的时候（当然不要勾选AutoRecieveInput什么的选项。。。）才会响应输入，代码就变得更加合理优雅了。另外如果在输入的时候需要时就是要判断Pawn有没有并给出提示信息的话，这些个处理代码移动到PlayerController里面才合适。所以归根结底这是一个设计问题，并且这也是UE4灵活性的一个体现。
然后在谈Multiplayer中如何处理这些输入。UE4提供了多种Replication机制，有属性的Replicate和3种类型的RPC方式。其中RPC的Multicast及RunOnServer方式可以将用户操作传到Server并作出响应。但是具体何时及如何使用是值得商榷的。举个例子角色开火会发射子弹。这个操作（Server的pawn是取不到且不应该input数据的，Server要的输入数据必须从Client传过去）由Client输入发起，应当请求Server进行操作，即调用一个RunOnServer的RPC，这点应当没有疑问，但是重点来了，到底要不要调用Multicast来spawn对应的bullet呢？答案是不应该！spawn的时候可能需要取到和actor位置相关的数据，注意Multicast是Server和各个Client上面的Pawn都会去调用相应的操作代码，然后这个时候取到的分别是Server和Client自己的位置数据，那么由于client和Server的同步差异会导致取到的位置的可能是不同的。然后且会Spawn多个Actor，因为每次调用都会spawn，若是bullet是一个replicated的actor那么各个Client上面都会显示多个bullet，这明显不是我们要的。我们仅需要一次spawn一个actor即可，那么这就需要仅在Server调用spawn函数，然后通过replication机制来同步到各个Client。那么Multicast函数的使用时机是什么呢？上面描述的是仅需要在Server干的活，但是Client也会要同时要做一些事情，比如同时播放个声音什么的，这个时候如果只在上面的那个RunOnServer事件里面执行这句话，只会在Server上（listening server模式下即host game的Client上生效），这显然也不是我们想要的。这个时候就是Multicast的应用场景了。
再然后讨论在讨论移动需不需要使用Multicast，不同于服务器Spawn，不会产生多个actor，因为整个操作过程中只有实际意义上的一个Pawn受控制（客户端会同步服务器上对应的Pawn）。第一种方案，在服务端移动Pawn，并且将RootComponent设置成Replicate的就可以看到同步效果了，但是似乎这种方式客户端的对象由于延迟感觉移动不是很流畅。而第二种方式使用Mutilcast在Server和Client分别让关联的Pawn自己处理自己的移动，然后通过同步来让服务器纠正客户端的位置的话，这样感觉移动比上面的更加连贯了。大部分网络游戏好像都是这么做的。

### 关于UE4的Network的思考
UE4的提供的Network功能，有他自己的一套方案，且和大多数S/C结构不一样，它的Server和Client端的代码是混在一起而不是各自独立分离。当然有好处也有坏处，比如好处是可以少写很多Client和Server共用的重复的代码，并在UE4的支持下快速实现联网游戏；也比如坏处是代码看起来就比较杂，也额外多了很多概念让人感到混乱。下面就我自己的理解来谈谈把。

#### 理解UE4中通常意义的单机游戏实际上可以看作是联网游戏的退化版
这个我个人认为是Epic早年是做对战游戏的，然后将引擎特化出来后，了同时支持联网和单机类型，选择了这么个设计。单机模式下，实际上就是本地Server，只有玩家一个人在这个Server里面。这个可以从单机模式下GameMode的依旧会调用Login相关的处理且此时也不会创建Session等可以简单的看出来。

#### 但谈论到UE4的网络的时候必须分清楚使用的是Dedicated Server还是Listening Server模式
必须要区分清楚，因为这个实际上会影响代码里面的一些写法，而且这个也是让人混淆的一个知识点。不同的模式下，可能处理的方式不一样。比如authority的问题。不过不管怎么样，记住一点当时用Listening Server的时候，Host game的Client即是Cient也是Server，而Dedicated Server模式下Serverr和Client有直接关系。

#### RPC调用时请注意调用时的context是处于Server还是Client
首先就RunOnOwningClient方式而言，它必须调用在Server上Context中被调用，否则会被当成一个普通的事件被调用。比如下图的打印，存在两个Pawn，并在Pawn的`BeginPlay`中调用，Server加上两个Client总共是6个对象，上面确实打印了6次
![](2017-04-27-07-31-07.png)
而加入authority的判断后打印如下，这是加上了Authority的判断后的打印，当拥有Authority的时候才执行RunOnOwning的事件，并在其中打印（注意这并不是判断server）。
![](2017-04-27-17-31-47.png)
> - 这里的对象都在server和相应的client都有copy，且pawn的copy存在于每个客户端。在authority的干涉下，执行RunOnOwningClient事件，仅在其对应的client有打印。这就表明拥有copy不一定代表own它，这个client owned的关系是明确指定的。
> - 额外的启示是从打印对象的名称如`BP_MyPawn_C_0`最后的suffix index可以看出，client在产生相应actor的时候，这个名字和server（选择性不考虑listening server 自身的client）上的不是对应的，这个suffix index是生成顺序决定的（经验上这个0代表的是自己的pawn），所以并不能作为判断对象的唯一性的标准。换句话说打印名字一致不是说就是同样的copy，唯一性还是要通过一个unique id来表明。

RunOnServer的话，在服务器上调用RunOnServer方式，本来就是就是server端了，这个RunOnServer的事件类型的指令就是冗余的。实际例子就是GameMode里面调用自己内部的事件时，还将其指定为RunOnServer话就是多余的。因为GameMode本身就是直存在于server，其一切操作就是RunOnServer的。又比如在TakeDamage里面去调用RunOnServer事件，TakenDamage只会在服务器触发，因此前面的做法也是冗余的。

#### 明确Authority的具体含义
上面有说Authority的判断不是判断是否是Server。我所在的讨论群里就有这种错误的认识，认为蓝图节点`SwtitchHasAuthority`就是判断是Server还是Client。这是不准确的。比如HUD类似的对象，只在owning client上存在，即其在且仅在owning client上有authority。而且我前面提到的要注意分清楚使用的是Dedicated Server还是Listening Server模式，这是因为那个Listen Server的缘故，在Server扮演Client时，对所有拥有的对象都有Authority。具体可以看下图，均是在`BeginPlay`中打印Authority信息。
![](2017-04-27-07-45-11.png)
> 我认为使用Authority判断的情景是，如果客户端和服务器都会执行同一段代码且让最终执行结果仅由有authority的一方决定，就可以使用authority判断。当然像前面所说的HUD就没有必要判断authority了，因为它的代码只在客户端执行。不能滥用，避免冗余，引起混淆。
> UE4官方论坛上有个帖子对这个问题有深入的讨论：[What is the actual meaning of "Authority"?](https://forums.unrealengine.com/showthread.php?40809-What-is-the-actual-meaning-of-quot-Authority-quot)

#### 不可忽略延迟以及相关的时序问题
只要是使用到网络就不能忽略延迟，比如UE4里面的RPC有时候没有调用成功，很可能就是延迟导致的。另外值得注意的时这也是导致单机模式下和联网模式下代码差异的一个因素哦。
比如在Server的PlayerController的BeginPlay中直接调用一个RunOnOwningClient的RPC，这个成不成就看运气了，纵使它是Reliable的。
再比如测试Multiplayer中，假设这么个情形，场景中设置两个player start设置两个玩家，然后登录，这个时候有可能出现第二个客户端的pawn没有正确生成。
> 首先pawn里面的component有collsion设置，然后由于在Editor里面启动的时候，两个client访问server时的间隔过短，导致了可能取到了同一个player start，这样就导致了第二个pawn尝试被spawn的时候由于collsion而失败，然后就出现上述的情形了。
> + 验证其实很简单把collision去掉，则个时候不会出现上面的情况，但是两个pawn有几率重合在一起。
> + 这点我认为在处理多人游戏时应该注意一下，因为玩家的登录间隔是无法预测的。

![](2017-04-28-09-47-41.png)
上面例子说明UE4并没有保证那些个单机模式下的时序，且估计也不想去保证，因为网络环境时不可预测的。这样就导致了我的项目中存在一些bug，比如要对pawn判断是不是当前client拥有时，可能由于同步延迟server的posses操作的结果还有同步过来，就出错等。我暂时也没有想到比较好的解决方案，暂时只好加上个delay来处理，不过这也是治标不治本。这个我会在后面的项目中继续思考，这暂时当作一个问题放在这里把。

#### 评估项目是否可能需要做成联网，这很重要！
由上面的讨论可知，联网和单机类型的代码差异还是比较大。如果不好好评估，则可能到时候会很痛苦。

### 总结
通过学习并编写这个项目，算是把UE4中关于网络部分的表面功能弄清楚了。就这个项目而言C++部分的代码实际上和蓝图差不多。但是蓝图上提供的功能时比较有限，而C++代码里面支持更多了。比如对登陆人数的限制，蓝图只提供了`OnPostLogin`的BlueprintImplementable事件来协助处理，但是这个时候实际上server已经接受了，已经为其创建了PlayerController了，如过设置了PawnClass那也就已经生成Pawn了，没有办法直接拒绝超出预期的人数的玩家。这就需要C++中的`PreLogin`方法协助处理。不管怎么样，一个playable的游戏做出来了，虽然存在问题，但是不能停滞不前，带着问题继续思考学习，这才是一个比较好的状态啊。
