---
title: Pak文件导出插件
date: 2017-11-01 16:28:33
tags: [UE4, UE4.17, UE4 Plugin]
categories: Tech
---
之前写过一篇关于Pak的文章--[UE4 Pak 相关知识总结](https://arcecho.github.io/2017/07/02/UE4-Pak-%E7%9B%B8%E5%85%B3%E7%9F%A5%E8%AF%86%E6%80%BB%E7%BB%93/)，简单分析了下Pak使用的方式。并提供了几个插件和脚本处理整个工作流。虽然我在ReadMe中简略的写了下如何使用，但是仍然有一些读者在e-mail中问这个插件怎么用。我思考了下，分了几个插件虽然灵活，但是实际每个插件的功能还是太单薄，再加上用Python写了一部分处理脚本，所以导致使用起来很繁琐，我就尝试把上述的功能整合到一个插件了。下面来大致介绍下怎么使用。
<!--more-->

### 插件界面
![](ExportPakPluginPreview.png)
插件会自己开一个DockWindow来方便操作，替代之前ExportAssetDependencies插件的界面功能。其实仔细想想，之前把导出入口放在Settings界面里面也是不对的。
+ UseBatchMode：这个是CheckBox控制着我们是否需要把导出的Package和其依赖的GameContent下的Package是否导出到一个pak文件中。
+ PackagesToExport：对Asset使用右键copy reference，将得到字串添加进导出列表中即可。
设置好自己的导出信息后，就可以点击右下角按钮导出我们需要的Pak文件了。

### 操作图解
这里以StarterContent为例。记住一定要先Cook工程，然后才有后续操作。

![](step_01.png)
+ 从window菜单打开插件界面

![](step_00.png)

+ 右键asset获取asset reference字串。
是这种形式的“Material'/Game/StarterContent/Materials/M_Metal_Brushed_Nickel.M_Metal_Brushed_Nickel'”，当然也可以手动输入/game/xxx.xxx这样的形式。

![](step_03.png)
+ 添加到导出列表中。

![](step_02.png)
+ 导出成功后右下角会提示AssetDependencies相关的信息。

![](step_04.png)
+ AssetDependencies文件内容示例

![](step_06.png)
+ 没有选择BatchMode，每一个uasset对应生成一个pak文件

![](step_07.png)
+ BatchMode最终只生成了一个pak文件。

### 验证pak是否可以使用
首先在这里我还是想强调一句，pak文件是用来挂载而不是被加载的。有些读者e-mail问问题第一句还是pak是怎么加载的，我是很无奈的。

![](validation_00.png)
首先是在编辑器里面创建一个新的关卡，包含静态光源，构建关卡并cook。

![](paks_directory.png)
然后按照之前的方式导出关卡，打包TestPak工程。并将生成的pak文件放到如图的paks文件夹下。按照之前的文章可以知道，这个文件夹下的pak文件会在启动程序的时候自动挂载。

![](open_level_success.png)
首先,这张图是打开我们导出关卡成功后的截图。

![](open_level_failed.png)
当我们不把pak文件放在paks文件夹下去尝试打开关卡时，会有如下报错。

从上面两图对比，可知插件生效，即pak使用流程符合预期。

### 注意事项
前面演示导出pak文件具有以下局限性：
+ 只有game content 下的依赖文件才会被导出，也就是如果依赖C++ scripts的话，就不能直接使用这样的方式了。实际上必须要用包含那些C++文件的工程打包后来测试。
+ 同上，非game content下的资产如果要使用的话需要额外的导出，当前的插件没有尝试导出，因为暂时没看到强烈的需求。

