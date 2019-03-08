---
title: Daily Records 04/2017
tags:
---

## 18/04/2017
UE4 键位映射 http://www.52vr.com/article-880-1.html

UE4 module

```
GetWorld()->GetTimerManager().SetTimer(
	HUDToggleTimer,
	FTimerDelegate::CreateLambda  (
		[this] 
		{
			if (this->widget->GetVisibility().IsVisible())    
			{      
				this->widget->SetVisibility(EVisibility::Hidden);    
			}    
			else    
			{      
			this->widget->SetVisibility(EVisibility::Visible);
			}  
		}), 
		5, 
		true
		);
```

UE4 事件流程是怎么一回事，这么做到鼠标事件像下层传递?

如果要播放 片头动画的时候，还自己写了LoadingScreen相关的Module。下面一段代码会决定两者的关系：
  
```cpp
virtual void StartupModule() override
    {
        //Load for cooker reference
        LoadObject<UObject>(nullptr, TEXT("/Game/UI/T_LoadingScreen"));

        if (IsMoviePlayerEnabled())
        {
            //CreateLoadingScreen();
            FLoadingScreenAttributes LoadingScreen;
            LoadingScreen.bAutoCompleteWhenLoadingCompletes = false; //注1
            LoadingScreen.MoviePaths.Add(TEXT("LoadingScreen"));     //注2
            GetMoviePlayer()->SetupLoadingScreen(LoadingScreen);
        }
    }
```
> + ~~当注1为true的时候且没有注2语句，loading界面会顶替Movie。~~
> + ~~bAutoCompleteWhenLoadingCompletes 为false的时候才会正常显示至完全播放完毕。但是如果播放完时游戏已经加载好，则直接进入游戏。~~
> +  LoadingScreen这个对象实际上包含了一个序列可以添加movie，也可以添加我们SWidget(即WidgetLoadScreen成员)。bAutoCompleteWhenLoadingCompletes控制是否在资源加载完毕的时候就结束LoadScreen的展示。
![](Daily-Records\2017-04-26-23-43-11.png)


Listen Server下的打印
![](2017-04-26-22-59-15.png)

Dedicated Server下的打印
![](2017-04-26-23-00-23.png)


对于PlayerController而言
> +  服务端的BeginPlay一定会调用，但是当执行到OwningClient的函数时，无法保证Owning客户端（非Listen server的client）的PlayerController构建完毕，因此直接调用这个RPC就可能不生效。
> + ~~似乎所有客户端代理的Actor的BeginPlay都不会在客户端调用！！！~~
> + OnPostLogin发生在服务端的Player Controller构建完毕之后才会执行，然后执行HandleStartingNewPlayer，但是此时客户端并不能确定已经构造完毕（实际上这个阶段以前的所有OwningClient的RPC，均不能确定能够被调用。至少时序是如此的，所以很纠结有些东西是这么保证可用性的，使用polling方式感觉有点恐怖，加个Delay可以接受。）。


那么以什么为标准来知道客户端已经准备好了呢？能以BeginPlay作为标准么，全部都告知本地的PlayerController自己准备好了，然后PlayerController告诉服务器都准备好了么？
> 客户端代理的对象的BeginPlay只是代表其自身在客户端已经开始建立完毕，但是相对于服务端的本体来说，此时不能保证相应关联的数据已经同步完毕。这点可以由在BeginPlay时去获取PlayerState里面的数据，有时失效来证明。

可以在Local PlayerController里面读取GameState里面的数据，然后在PlayerArray（实际上记录的是PlayerScate）里面得到

UE4 richtext???

### 22/04/2017

[What is a "Presence" Session?](https://answers.unrealengine.com/questions/270766/what-is-a-presence-session.html)

### 23/04/2017
~~OnPostLogin中直接调用客户端的PlayerController中的函数时会出现找不到PlayersState的错误。~~
> 实际上这些问题都是server到客户端的数据同步存在延迟，即在当前函数调用时，可能预计的数据还没有同步到客户端，故直取不到。验证：若加一个delay，则客户端按照原有逻辑即可访问预期的数据。但是这是hack式的写法，具体应该如何写呢。

若要在multiplayer game中使用一个固定的camera，则需要关掉PlayerController的 AutoManageActiveCameraTarget，否则不能同时使用一个。
只有sever上的对象才能取到game mode即，client要操作game mode必须使用RunOnServer函数来访问GameMode

Actor的component并不会受actor本身的Replicates属性影响，必须自行启用。
> 比如虽然awn的Replicates是默认勾选的
> 在其下面加上一个Mesh。不勾选ComponentReplicate的时候，在Server端改变其Relative Rotation，则只会在Server端看到效果，客户端不会同步变化。勾选之后客户端就会同步了。
> 为什么不会自动同步呢，因为不是所有的Component都需要在服务端去操作然后同步到各个客户端的，比如自己的角色下的光圈只需要在当前客户端显示，这个光圈可以是一个DecalComponent，它不需要同步。鉴于此种情况，组件同步需要用户手动来启用。

论Multicast和RunOnSever事件，举个例子角色开火会发射子弹。这个操作（服务端的pawn是取不到且不应该input数据的，服务端要的输入数据必须从客户端传过去）由客户端输入发起，应当请求服务器进行操作，即调用一个RunOnServer的RPC，然后重点来了，到底要不要调用Multicast来spawn对应的bullet呢？答案是不应该！spawn的时候可能需要取到和actor位置相关的数据，注意Multicast是Server和各个Client上面的Pawn都会去调用相应的操作代码，然后这个时候取到的分别是服务器和客户端自己的位置数据，那么由于延迟即同步频率会导致取到的位置的是不同的。然后且会Spawn多个Actor，因为每次调用都会spawn，若是bullet是一个replicated的actor那么各个客户端上面都会显示多个bullet，这明显不是我们要的。我们仅需要一次spawn一个actor即可，那么这就需要仅在服务端调用spawn函数，然后通过replication机制来同步到各个客户端。那么Multicast函数的使用时机是什么呢？上面描述的是仅需要在服务端干的活，但是客户端也会要同时要做一些事情，比如同时播放个声音什么的，这个时候如果只在上面的那个RunOnServer事件里面执行这句话，只会在host game的客户端上生效，这显然是不对的。这个时候就是Multicast的应用场景了。

现在在讨论移动需不需要使用Multicast，不同于服务器Spawn，不会产生多个actor，因为整个操作过程中只有实际意义上的一个Pawn受控制（客户端会同步服务器上对应的Pawn）。第一种方案，在服务端移动Pawn，并且将RootComponent设置成Replicate的就可以看到同步效果了，但是似乎这种方式客户端的对象由于延迟感觉移动不是很流畅。使用Mutilcast在各个Pawn对象中自己处理自己的移动，然后通过同步来让服务器纠正，这样感觉移动比上面的更加连贯了。

！！！当UE4程序处于后台挂起的时候，是无法播放声音的。（这可能需要有某些设置后才能播放）。

### 24/04/2017
PlayerController只存在于服务器及相应的OwningClient上面。其他客户端是无法访问到别的客户端的PlayerController的。

~~从这一点可以推断出，当要操作Pawn时且要获得输入要取到用户的输入应该从PlayerController中获取。举个例子，如果Pawn的移动需要在Tick函数中处理的话，且此时又要去访问某个AxisInputValue来作为输入。那么直接在Pawn的Tick函数里面去实现并调用Pawn的Server_Move及Client_Move是错误的做法，因为客户端上也存在其他的客户端的Pawn的副本，他们也是会调用Tick函数并去尝试调用move相关的处理函数，当然在这里这些Pawn都是没有Authority的，会去调用Client_Move，这个可以接受。但是在Server端他们都是有Authority的，但是并取不到对应本地的输入的。之所以按照上述代码写，表现上是差不多对的，是因为从对应Client上调用了Server_Move，都可以看作是从Remote端调用的。所以应该这么处理，PlayerController和Pawn可以用来处理用户的输入，Pawn的处理的输入应该是其特化的响应操作。PlayerController中的作为适用于多个Pawn的操作的处理，以及处理Server操作Pawn时有输入依赖的操作。上述的Move的操作在这种模式下可以设计为PlayerController来接受输入事件，此时事件必定是从OwningClient上触发的入口，~~(这段我也不知道这么合适的描述)。

应当避免在代码中直接调用GetAxisValue类似的操作，这个应当将操作转化为同步的属性，通过replicate机制来供给客户端代理及服务端使用。

关于输入
移动的的处理，可以这样做，客户端代理Actor和服务器的Actor都要Tick处理移动，那么也就是说，移动所需的数据应当作为Pawn的一个属性，这样只需要通过PlayerController改变这个数据就可以实现同步的移动，也就是输入和移动通过该属性变量脱耦。因为Input输入只会在OwningClient上触发，在OwningClient上的Actor才有处理输入的能力，服务器及其他客户端是不会触发的。在不考虑Host的情况下，可以认为输入都是在Remote触发的，那么这个时候有两个选择，一是只调用服务器的的属性的Update，这个时候本地客户端的代理的Pawn的移动会通过服务器的移动同步到本地，可以认为是一个服务器Multicast操作各个客户端代理的Actor的位置；第二种方式是服务器客户端都调用，这样就是客户端自己做自己的表现，然后由服务器计算的结果纠正。建议第二种，理论上第二种在客户端表现更平滑。
> -  只在客户端改变一个replicate的属性是不会同步到服务器的，也就是只有服务器同步到客户端，而没有客户端同步到服务器的做法或者叫法。应该是客户端发送数据（RPC传参）给服务器，服务器的数据可以同步到发送者的客户端。

> - 按照前面的说法，那么在输入的时候是不是就不应该对authority进行判断了呢？答案是若有某个客户端作为Host话就仍需判断，因为这个时候Server即Host client只需要做其客户端上的输入处理，此即server。若按照前面所述的client和server都都处理的话，等于有冗余的操作？实际上这中方式也不要滥用，这个最好是应用于需求平滑的客户端表现的效果，且平滑基于的参数是一个属性值的方式，类似我们的Tick时处理移动的方式。但是类似于开火（不考虑spawn子弹，考虑相应的动作即声音播放等表现）这种一次性触发的操作最好时直接通过server执行，并multicast到各个客户端。因为如果时客户端和服务器都做的的话，实际上输入发起的客户端会执行两次操作的响应，对于这种立即响应的操作是不合理。当然开火这个例子举得不是很好（考虑到开火的动画也是需要针对延迟做一定的优化处理的，也即是所谓的前摇什么的），总的来说就是这种方式是用来缓解服务端和客户端同步的延迟的，不要滥用。

### 25/04/2017
只要是使用到网络就不能忽略延迟，比如UE4里面的RPC有时候没有调用成功，很可能就是延迟导致的。比如在PlayerController的BeginPlay中直接调用一个OwningClient的RPC，这个成不成就看运气了，纵使它是Reliable的。

![](2017-04-27-07-31-07.png)
RunOnOwningClient事件应该必须确保是在Server端调用的，从客户端调用的话就会被当成一个普通的事件调用（可以从pawn调用时打印的次数可以看出来，服务器加上两个客户端总共是6个对象，上面确实打印了6次），那是错误的做法。

![](2017-04-27-17-31-47.png)
这是加上了Authority的判断后的打印，当拥有Authority的时候才执行RunOnOwning的事件，并在其中打印（注意这并不是判断server）。
> - ~~从图中可以看出，对于PlayerController来说，RunOnOwningClient仅仅会在其所在的客户端调用，而pawn却会在相应的客户端及服务器上都会调用。这就说明一个问题，对于PlayerController而言其所有权在客户端，而actor两者都有。~~
> - ~~从上面可以推断最好的判断是否是在本地客户端的方式是在PlayerController内部调用RunOnOwningClient的事件。~~
> - 这里的对象都在server和相应的client都有copy，且pawn的copy存在于每个客户端。在authority的干涉下，执行RunOnOwningClient事件，仅在其对应的client有打印。这就表明拥有copy不一定代表own它，这个client owned的关系是明确指定的。
> - 额外的启示是从打印对象的名称如`BP_MyPawn_C_0`最后的suffix index可以看出，client在产生相应actor的时候，这个名字和server（选择性不考虑listening server 自身的client）上的不是对应的，这个suffix index是生成顺序决定的（经验上这个0代表的是自己的pawn），所以并不能作为判断对象的唯一性的标准。换句话说打印名字一致不是说就是同样的copy，唯一性还是要通过一个unique id来表明。

![](2017-04-27-07-45-11.png)
> - 需要重新审视对SwitchHasAuthority的理解了
> - ~~对于PlayerController而言，无论在服务端还是客户端都是显示No authority。即Player Controller代码中根本没有必要出现HasAuthority的判断~~。
> [What is the actual meaning of "Authority"?](https://forums.unrealengine.com/showthread.php?40809-What-is-the-actual-meaning-of-quot-Authority-quot)

如何处理这个由于同步导致的读取数据无效的问题呢？

### 27/04/2017
```cpp
FLatenActionInfo info;
info.CallbackTarget = this;
info.ExecutionFunction = TEXT("myFunctionToCall");
info.UUID = 1;
info.Linkage = 0;

UKismetSystemLibrary::Delay(GetWorld(), 5 , info);//延时5秒后 调用myFunctionToCall函数
```
C++中使用蓝图Delay函数，实际上就是一个timer后执行相应的事件，但是这么写不如直接timerhandle加lambda函数。
[官网上的给出的timer的使用方法](https://docs.unrealengine.com/latest/CHN/Programming/UnrealArchitecture/Timers/index.html)

UE4的网络类型要分Dedicated Server和Listening Server来讨论。不同的模式下，可能处理的方式不一样。比如authority的问题。在Server对应的client上和其他客户端上，同样的代码可能得到的结果不一样。因为listnening server既扮演server也扮演一个client的角色。
authority并非是判断是否是Server的途径，因为对于HUD类似的对象，只在owning client上存在，即其在且仅在owning client上有authority。使用Authority判断的情景是，如果客户端和服务器都会执行同一段代码且让最终执行结果仅由有authority的一方决定，就可以使用authority判断。当然像前面所说的HUD就没有必要判断authority了，因为它的代码只在客户端执行。

使用RPC的时候，要注意其调用者的context是在server还是client，比如在服务器上RunOnServer运行时，若本来就是就是server端了，这个RunOnServer的事件类型的指令很可能就是冗余的。实际例子就是GameMode里面调用自己内部的事件时，还将其指定为RunOnServer话就是多余的。因为GameMode本身就是直存在于server，其一切操作就是RunOnServer的。又比如在TakeDamage里面去调用RunOnServer事件，TakenDamage只会在服务器触发，因此前面的做法也是冗余的。

测试Multiplayer中，假设这么个情形，场景中设置两个player start设置两个玩家，然后登录，这个时候有可能出现第二个客户端的pawn没有正确生成。
> 首先pawn里面的component有collsion设置，然后由于在Editor里面启动的时候，两个client访问server时的间隔过短，导致了可能取到了同一个player start，这样就导致了第二个pawn尝试被spawn的时候由于collsion而失败，然后就出现上述的情形了。
> + 验证其实很简单把collision去掉，则个时候不会出现上面的情况，但是两个pawn有几率重合在一起。
> + 这点我认为在处理多人游戏时应该注意一下，因为玩家的登录间隔是无法预测的。

![](2017-04-27-22-39-34.png)
Pawn的possessed事件只会在server端触发，但是这个第二个的possess为什么会触发两次？？？
> 简化了应用场景，只要用蓝图就会出现两次，而C++代码只会触发一次！！！！

UE4文件读取
![](2017-04-28-17-47-38.png)

Delay 节点的时间设为0似乎和js里面SetTimer为0的用法类似，是为了让代码~~异步操作~~到下一帧执行？


### 29/04/2017 
steam 接入的时候如果出现取ID时灵时不灵
> steam_appid.txt 这个文件是动态生成。。关闭exe后他要延迟一会才会自动删除，当我开启的时候他刚好删除 然后就造成没有这个文件了

静态成员及函数不影响类的size，只有普通数据成员才影响。

连续调用push_back会出现molloc失败？

![](2017-04-29-20-54-15.png)
出错

```cpp
 mesh.materials.resize(mesh.numMaterials);
        ifs.read(reinterpret_cast<char *>(&mesh.materials.front()), mesh.numMaterials * sizeof(Material));

        ifs.read(reinterpret_cast<char *>(&mesh.numIndices), sizeof(Mesh::numIndices));
        ifs.read(reinterpret_cast<char *>(&mesh.numVertices), sizeof(Mesh::numVertices));

        mesh.indices.resize(mesh.numIndices);
        ifs.read(reinterpret_cast<char *>(&mesh.indices.front()), mesh.numIndices * sizeof(int16_t));

        mesh.vertices.resize(mesh.numVertices);
        ifs.read(reinterpret_cast<char *>(&mesh.vertices.front()), mesh.numVertices * sizeof(Vertex));
```
正常

类成员如果有string等成员，将其放在容器中，会出现释放时出错？简单的析构函数解决不了...

