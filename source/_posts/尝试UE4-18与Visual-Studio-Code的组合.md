---
title: 尝试UE4.18与Visual Studio Code的组合
date: 2017-11-09 17:48:27
tags: [UE4, UE4.18, Visual Studio Code]
categories: Tech
---

在UE4.18[Release Note](https://docs.unrealengine.com/latest/INT/Support/Builds/ReleaseNotes/4_18/index.html#new:visualstudiocodesupportedonwindows,macandlinux)中提到了新版本对Visual Studio Code加入了支持，于是尝试了下。
![](preview.png)

<!--more-->
### 概述
通常我们都是用Visual Studio来编写UE4 C++工程的。使用VS作为代码编辑器，也可以用它来调试代码。但是实际上编译代码时，是使用UBT配合VS build tool的。因此，当Visual Studio Code把相应环境配置好了之后也是可以替代VS的。

### 下载所需的环境
+ [Visual Studio 2017 Build Tools](https://www.visualstudio.com/zh-hans/downloads/?rr=https%3A%2F%2Fhatenablog-parts.com%2Fembed%3Furl%3Dhttps%253A%252F%252Fwww.visualstudio.com%252Fja%252Fdownloads%252F#other-zh-hans)

这里只需要安装如下图所示的组件即可
![](install_vs_build_tools.png)

+ [Visual Studio Code](https://www.visualstudio.com/zh-hans/downloads/?rr=https%3A%2F%2Fhatenablog-parts.com%2Fembed%3Furl%3Dhttps%253A%252F%252Fwww.visualstudio.com%252Fja%252Fdownloads%252F#code-zh-hans)

Visual Studio Code里面需要安装如下的两个插件
![](vsc_extension.png)

可能此时会提示需要安装.Net相关的组件，就顺手装上吧。我之前装过所以这里没有提示。

### 在UE4工程中设置VS Code作为代码工具
![](UE_Setting.png)
如图选择VS Code即可看到如下图相应的菜单项发生了改变。

![](file_menu.png)

### VS Code 工程
然后，我们尝试生成一个VS Code的工程
![](VSC_Proeject.png)

然后把Debug设置的编译选项设置成Development就可以正常编译代码了。这实际上和VS里面是一致的。
![](VSC_debug.png)

然后需要注意的是，这里工程的文件目录只有游戏目录的代码，而没有Engine部分的，但是代码跳转还是可以到达我们想要的位置的。

### 总结
总的来说，这一个组合还是可以使用的。VS Code完全算的上是一个IDE了，占用的内存比较小，且可定制化很强。一些不喜欢Visual Studio那种大体量的玩家还是可以体验下的。但是对我而言，我还是离不开Visual Studio，毕竟已经习惯VAX+VS的组合了。而且当前版本的工程是不包含Engine的代码的，这点就很不方便。

 
