---
title: Daily-Records-06-2017
tags:
---

### 04/06/2017

 对于STL，微软为每个版本的VS都有不同的实现，VS2008(VC90),VS2010（VC100），VS2013（VC120）。
由于不同的STL的实现，我们不能在不同的版本见直接传递std::string, 否则运行期可能出现不可预知的错误。
而事实上我们在ExportClass中的std::string x变量是不希望被外部直接使用的，也就是并没有export的必要，事实上，不建议让dll向外导出任何关于非C++基础类型的定义。
但是由于ExportClass需要向外导出（因为需要使用foo（）函数），应该如何处理这样的矛盾呢？

对于这样的问题，我们需要使用C++的抽象类（其实就是java中的interface概念）来解决：
我们需要：
1. declare一个只有纯虚函数和C++基础类型的基类，所有需要向外部导出的定义都包含在该类中。
2. declare另一个类，继承该基类。
3. 实现一个返回基类函数指针的getInstance函数，即返回一个派生类实例的工厂方法。
4. 在外部代码中，通过多态机制访问该类。
```cpp
#pragma once

#ifdef DLL_EXPORTS
#define DLL_API __declspec(dllexport)
#else
#define DLL_API __declspec(dllimport)
#endif

class DLL_API ExportInterface
{
public:
    virtual void foo() = 0;
};

extern "C" DLL_API ExportInterface*  getInstance();

#ifdef DLL_EXPORTS  //我们并不需要向外导出该类的定义，在外部代码编译时，也不需要包含此类的定义。
class ExportClass: public ExportInterface
{
pirvate:
    std::string x; //由于外部代码对此不可见，此处的std::string是安全的。
public:
    void foo(); //函数体在dllExample.cpp中实现
};
#endif
```


### 04/06/2017
![](Daily-Records-06-2017\2017-06-25-11-45-35.png)


[Unreal Engine 4 多线程任务C++构建]http://www.taidous.com/thread-55472-1-1.html
