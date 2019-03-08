---
title: Slate进阶应用之两个相当有用的工具和一个示例合集
date: 2017-09-18 17:19:41
tags: [UE4, Slate]
categories: Tech
---
一直看见有人吐槽Slate，说太烂。问他们烂的原因，往往又只是说难写，资料太少什么的肤浅的理由。诚然，slate语法在初学阶段比较繁杂以及编译需要较多的时间。但是你要是深入了解及使用正确的方法来使用slate，你会发现slate的设计也是很强大的，毕竟Editor是用它作为基石的。本文将介绍进阶学习slate两个相当有用的工具和官方自带的slate示例合集程序。
<!--more-->

### WidgetReflector
这个工具属于Developer分类中，因此我们可以在各个Develop场景中来使用它，比如DevelopGame，DevelopEditor。它可以用来帮我们分析slate结构及各种slate使用的数据信息，比如图集等。它就很像Chrome中的inspector了。
![WidgetReflector界面展示](WidgetReflector_01.png)
可以看到鼠标在所在的SlateWidget会自动和Widget列表中同步，并用不同颜色来高亮显示轮廓。
这个工具是我寻找很多代码实现的主要工具，可以从界面快速定位到代码的大致方向。

#### 启动方式
![WidgetReflector启动方式](WidgetReflector_launcher_entry_01.png)
在4.17之前我们都需要从菜单栏来打开此界面。而4.17则在UMG Editor的工具栏中集成了。
![WidgetReflector启动方式](WidgetReflector_02.png)


### RenderDoc
这个工具的适用性很强，对于slate来说我们可以看到slate具体绘制的DrawCall这对我们调试显示错误具有很好的 提示作用。但注意这个工具的不仅仅只局限于此。
具体关于这个RenderDoc的使用请参看[官方文档](https://wiki.unrealengine.com/RenderDoc_plugin)，非常详细。

### SlateViewer
如果你使用的是源码编译版的话，你可以在Programs中找到这么个名字的项目。这是读源码时偶然中发现的，发现时让我感觉到捡到了绝世秘籍的感觉，且基本上没有什么资料介绍这个项目的。先不说别的直接上几张张图：
![SlateViewer界面0](slateviewer.png)
![SlateViewer界面1](slateviewer_1.png)
![SlateViewer界面2](slateviewer_2.png)
是不是很惊讶，它涵盖了绝大多数的slate的使用方式，也就是说它是一份活生生的slate示例手册，那么一些人的资料太少的观点也就不存在了。