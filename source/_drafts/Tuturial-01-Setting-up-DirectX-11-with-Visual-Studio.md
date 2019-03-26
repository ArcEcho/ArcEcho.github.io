---
title: 'Tuturial 01:Setting up DirectX 11 with Visual Studio'
date: 2019-03-08 13:19:39
tags: [DirectX, Visual Studio]
categories: Tech
---

原文地址：
+ [Tutorial 1: Setting up DirectX 11 with Visual Studio](原文地址：http://www.rastertek.com/dx11tut01.html)
<!--more-->

### 设置Visual Studio 2017：

原文提到的要使用DirectX SDK，但是从Win 8开始官方便不再发布和维护单行版本，而是将其归入到了Windows SDK中去了。因此所有Tutorial都是默认开发环境不低于Win 8，并直接使用Windwos SDK中DirectX库。


#### 创建空的C++工程
![创建空的C++工程](Snipaste_2019-03-08_15-06-52.png)

#### 工程属性页
![默认工程属性页](Snipaste_2019-03-08_15-11-08.png)

+ 红框标注的是使用的Windows SDK的版本，一般来说它会默认设置成当前开发环境中最新的版本。 如果你在编译别人的代码时提示Windows SDK版本不对的话，就需要视情况修改这里的版本了。

+ 绿框标注的是当前C++ Project使用的字符集，C++中字符编码是个需要详细讨论的话题。在这里为了方便起见，将其设置为Unicode字符集。修改值之后的结果如下。


![修改了字符集](Snipaste_2019-03-08_15-47-13.png)

前面说过我们是直接使用Windows SDK的DirectX库，相对于原来的教程来说，当前Tutorial差不多就结束了，原文中的习题也变得没什么意义了。









