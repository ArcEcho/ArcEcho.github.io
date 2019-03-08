---
title: UE4 Pak 相关知识总结
date: 2017-07-02 08:30:42
tags: [UE4]
categories: Tech
---
近来研究了下UE4中Pak文件的工作流程，并对UE4中的文件系统了解了下。这个过程中，我发现现有的资料讲的比较乱，且有的版本很老。遂在此按照自己理解来简单阐述下UE4中和Pak文件相关的各种知识，如果有什么错误或者不明白的地方请在下方留言或者发送Email：zmy_qwerty@163.com。
<!--more-->

### 需要知道的核心概念
这里根据自己的理解把使用Pak时需要的核心概念提炼出来了。

#### 印证了《Gmae Engine Architechture》中的一些设计
之前看那本书的感触不是特别深，感觉太理论化。在研究UE4的时候，发现UE4实际上的很多设计就是那本书的一些印证。
UE4和绝大多数游戏引擎一样使用了文件系统即资源管理器的方式管理的文件和游戏资源，比如PlatformFile就是可以认为其平台独立层的File system，而使用的Package管理的方式就是对应其资源管理器的概念。
后面记《GEA》为《Gmae Engine Architechture》。

##### File System
书中列举的主要用途如下:
+ 操作文件名及路径
+ 对单独的文件进行读写等常规的文件操作
+ 扫描文件目录下内容
+ 处理异步的文件I/O请求

除了主要用途，文件系统还要可能需要满足资源Packaging，Patching等功能。
我所了解比较好的文件系统例子是[暴雪的CASC](http://wow.gamepedia.com/Content_Addressable_Storage_Container),我们玩的WOW的更新及修复什么的，都是依靠它实现的。

#### UE4中的对应的一些概念

##### File
File在UE4中的概念，实际上和我们使用操作系统时的是基本一致的，用来记录数据信息。

##### Asset Package
实际上UE4中没有Asset Package这个名词，只有Package，为了区别于Packaging Project的package，这里先声明这样的记法。Asset Package，就是指的在UE4中能够在直接使用的游戏资源，比如material，map，blueprint等，每一个独立的资源的对应一个Package概念。
+ 一个Asset Package可能包含多个File，比如cooked之后的usset实际上可能会分离出.uexp .ubulk等文件。
+ 多个Asset Package可以称作一个Pack，比如Add Feature Pack就是提供了一系列Asset Packages。
+ Asset Package和UOject关系很紧密，直接Load的Asset Package就是一个UObject对象。
+ FPackageName就是我们通常在Load Asset时使用的路径形式。更为具体点就是FStringAssetReference。但是注意FStringAssetReference不是一个字串，不要被名字迷惑。

##### PlatformFile
UE4中使用使用IPlatformFile来抽象出平台无关的文件操作的接口，对应《GEA》中架构的平台独立层中的文件系统。 相对Asset Reference方式来说这是一个低层文件访问的对象。它提供了基本的文件Read，Write，Delete等等操作。比较接近std::fstream的一些操作。针对支持的各个平台都会从IPlatformFile派生出相应的具体实现的类，比如WidowsPlatformFile。除了平台相关的的派生类以外，还有IPlatformFilePak，IPlatformFileModule等，这里只介绍IPlatformFilePak。和上面FPackageName相对应的是FPaths用来处理一些PlatformFile下的文件路径的操作。

##### Pak PlatformFile
用以管理Pak相关操作的PlatformFile类。提供了使用.pak文件的最为核心的两个操作Mount及Unmount。


#### 引擎提供的相关操作
 + [Content Cooking](https://docs.unrealengine.com/latest/INT/Engine/Deployment/Cooking/)
 + [Packaging Project](https://docs.unrealengine.com/latest/INT/Engine/Basics/Projects/Packaging/index.html)

#### 需要注意的问题
下面是我在学习的时候，总结的一些知识以及容易混淆的概念。

##### 在PIE模式下使用Pak文件的意义不大
我最开始的时候按照自己的理解，认为既然是虚拟文件系统，那么只要我正确挂载路径，那么就可以正常的访问文件数据了。按照样的说法在PIE模式下，这也应该是可行的，那么这样子我在测试Pak相关功能时是不是可以不用那么麻烦的每次都需要Pakcaging Project了呢？虽然这个问题的前半段确实可行，但是后半段的问题仍然无法避免。
+ 虽然能够挂载pak文件，并能够加载其中的Asset Package，但是只能是未被Cooked的才可以正常使用，同理Packaging之后的Project也无法使用没有Cooked的Asset Package。

##### 区分Mount和Load的区别
Mount翻译为挂载，而Load一般被翻译为加载。Mount只是告诉了文件系统有哪些文件可以从当前挂载的Pak文件中读到，即提供了虚拟的路径来访问Pak文件包含的文件，而Load一般就是指把文件的内容加载到内存中了，当然加载一个Package不是说的这么简单的流程。另外我看很多示例上可能是没有理解这边文件系统的原理，会在挂载之后直接写一些加载的代码，并没有在此时去使用加载之后的数据。*挂载pak文件之后就可以通过常规的方式来访问其中的文件了，并不需要特意的去做一次加载操作，且和使用或不使用异步加载方式没有直接的关系*


##### 注意PlatformFile是一个链状结构
如果阅读IPlaformFile相关的代码就会发现IPlatformFile实际上是一个链状的结构。在其Intialize的时候，会要求传一个IPlatformFile的指针，这个将会作为其inner lower PlatformFile存在，在通过一个PlatformFile尝试访问文件目录时，可以通过这个链自顶向下访问每个节点上所挂载的文件。
+ 可以这样理解，每个节点都有包含一部分文件信息，整个链上节点的信息综合起来，就是你能够访问的所有文件信息。值得注意的是，这种方式是允许节点间信息冗余的。如果冗余会访问第一个找到的数据。
+ 既然是一个链状结构，UE4提供了FPlatformFileManager来方便set/get topmost PlatformFile。

##### 注意一个PakPlatformFile上可以挂载多个Pak文件
网上大多数挂载pak的示例中，都是直接创建新的PakPlatformFile，然后把PlatformFileManager取到的当前的topmost PlatformFile作为其inner lower PlatformFile，然后将这个PakPlatformFile指定为topmost。实际上如果没有特殊要求的话，没有必要去增长这个链，会造成内存的浪费。一个PakPlatformFile可以挂载多个Pak文件，其内部有一个记录FPakFile的List。

##### 注意使用PackageName和Path的区别
一般来说，Path就是接近我们在操作系统中读取文件时的那种路径。而PackageName提供的字串形式，实际上是一种简写的方式。
+ FPackageName提供了RegsterMountPoint和UnRegisterMountPoint函数，这个函数的作用实际上就是提供了一种重定向的方式，即你在使用"/Game/xxxx.xxxx"的PackageName时，资源管理器会翻译成文件系统所能识别的Path。注意提过一个Asset Package可能对应多个文件，这个过程可能不是简单的字符串转换。另外还需要注意的是，PIE模式下你使用这个函数的时候，会抛出事件让Content Browser去扫描改动，如果你的注册的文件是在GameDir下的话，会反映到编辑器的Content Browser中。一般来说，这个函数没必要特意去调用，如果你mount的路径在GameContentDir下的话是可以直接使用"/Game/"开头的那种方式来加载Asset Package的。

##### pak文件中可以存放非Asset Package文件类型
这里的意思是在使用UnrealPak.exe可以放入类似.txt的文件，挂载后可以通过PlatformFile来访问其中的文件内容。

##### Pak文件大小要求
~~前面的文章基本上描述了pak文件的使用的基本流程，但是UE4中处理这些流程的复杂程度远不止所提到的这些。比如pak文件在使用的时候还涉及到资源缓存的问题，对应代码中的USE_PAK_CACHE。这个功能，限定了pak文件的最小size。目前4.16.2版本中这个大小被设置为64KB（PAK_CACHE_GURANLULARITY），也就是如果你的pak文件小于64KB，将无法被预缓存。这一点我通过补足pak文件大小和修改源码中的PAK_CACHE_GURANLULARITY数值两个方式进行了验证，结果都符合预期。~~
UE4.17.1版本中已经把这个问题修正了。
> Fixed async loading from pak files < 64k.



##### 制作pak文件的一个小技巧
UE4提供了命令行工具来生成pak文件，我们只需要编写一些脚本，就可以方便按照自己的需求来生成相应的pak文件。这里说的小技巧可以让你把某个路径下的制作成pak文件时保留你想要的部分路径。具体的脚本代码如下：
```python
# This function accepts a short package filepath with out extension.
# And when generating pak file, it will add a dummy file to the reponse file list,
# in this way, the relative path to expected package root path will be saved in pak file.
# For example:
# If the input parameters targetPackagePathRootDir="F:\\AAA\\BBB\\" assetPackage="F:\\AAA\\BBB\\CCC\\*.*",
# then in the output pak file, the file's saved path will start with "\\CCC\\"
def GenerateSplitedPaks(outputPakFileDir, targetPackagePathRootDir, assetPackage):
    pakCmdTemplate = '"{}" "{}" {} "{}"'
    urealPakToolPath = GetUnrealPakToolPath()

    outputPakFileDir = os.path.normpath(outputPakFileDir)
    targetPackagePathRootDir = os.path.normpath(targetPackagePathRootDir)
    
    filesToWrite = ""
    for associatedFile in assetPackage.associatedFiles:
        filesToWrite += ' "{}"'.format(associatedFile)  
    
    #Use hash
    pakFilename = str(hash(assetPackage.name))

    # _, pakFilename = os.path.split(assetPackage.name)
    
    outputPakFilePath = os.path.join(outputPakFileDir, pakFilename + ".pak")
    dummyPackagePath = os.path.join(targetPackagePathRootDir, "dummy.uasset")

    pakCmd = pakCmdTemplate.format(urealPakToolPath, outputPakFilePath, filesToWrite, dummyPackagePath)

    subprocess.call(pakCmd, shell=True)
```
简单来说就是以你想要相对的路径下加一个不存在的文件，上面代码中是dummy.uasset。然后作为命令行输入的时候，工具提示找不到那个文件且不会加入那个文件。但是这个时候，你要保留的路径就留下来了。可能讲的不是很直观，你可以自己尝试几次不同的组合就知道了。

*注意这里是简单的技巧示例，真正使用的时候请参照编辑器中的传详细的参数来进行脚本的编写。因为生成pak文件的时候，还需要需要指定合适的patchpaddingalign等数据。详细可以参看工程的ProjectUitls下的python脚本的代码。*

##### 挂载前后的路径问题
这个问题非常重要，我也将其放在最后来说。但其实挂载前后的路径确定出乎意料的简单，就是要保证你在制作那些资源时的目录结构和你挂载后的目录结构完全一致，这样就能保证其中资源依赖没有问题。给个简单的例子说明：
![](2017-07-02-14-24-35.png)
图中ToPak路径下的Package我都需要放入到Pak文件中，使用UnrealPak工具，以ToPak为Root生成Pak文件。然后使用此pak文件时，只需要把pak文件在挂载在FPaths::GameContentDir()下，就可以正常使用，包括依赖关系。
+ 同一个文件夹目录下的的文件可以分散在不同的Pak文件中，对同一个路径mount不同的Pak文件就可以还原之前的目录结构。
+ 同时需要注意的是实际挂载时并不一定需要去指定mount point，但这个的前提是你生成pak文件的时候在response file中已经指定好了各文件的redirection path。这一点是通过阅读程序如何使用自身的paks文件下的pak文件得知的，我做了多次验证后确实如此。且不按照此种方式使用时，静态光源的构建数据可能会出现错误的带状显示效果。


#### 核心的代码示例
工程托管在GitHub上：[TestPak](https://github.com/ArcEcho/TestPak), 我只把使用Pak文件最核心的一些代码提炼出来了，并给予一些示例。

#### 目前尚未解决的问题
+ 当前我测试通过的的版本是4.15.1和4.16.2，在正确生成pak文件后（正确是指使用unrealPak工具时，相关的命令行参数需要恰当），基本上能够正常运行。如果使用最简单的方式的话可能静态光源的builddata使用错误，出现带状的错误显示效果。然后就是在4.15.3版本下cook之后，只有uasset文件，而缺少uexp等文件，暂时不知道为什么，此种情况下使用时也会出现前面的错误。这个需要等我后面弄明白了再补充。