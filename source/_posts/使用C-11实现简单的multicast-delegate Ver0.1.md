---
title: 使用C++11实现简单的delegate v0.1
tags: [C++11, C++]
date: 2017-05-28 10:40:45
categories: Tech
---

传统的事件系统需要预先定义事件类型才能使用。UE4使用了delegate的方式来代替传统的事件系统，因此自己在造玩具代码的时候也想模仿下。本文通过C++11提供的std::function通过非常粗陋的方式实现了一版delegate，包含multicast delegate。

<!--more-->

### 阅读本文需要了解基础知识
+ 基础的泛型编程的知识：如知道模板类，Variadic arguments等。
+ 基础的smart pointer相关的知识。
+ 基础的STL容器知识：如vector的简单操作。

### 实现的基本功能特性
+ 通过智能指针来自动管理相关delegate的生命周期，即放置调用已经被释放过的类的成员函数等。
+ 通过Variadic arguments实现可扩展的参数列表。
+ single delegate 和 multicast delegate

### 实现的代码及解释

#### Single Delegate
代码很简单，通过模板类来实现：
```cpp
  template<typename ReturnType, typename ...ParameterTypes>
    class SingleDelegate
    {
    public:
        using  EventType = std::function<ReturnType(ParameterTypes...)>;

        SingleDelegate()
            :
            boundEvent { nullptr }
            bShouldExcuteOnce { false }
        {

        }

        ~SingleDelegate() = delete;

    public:
        void Bind(std::shared_ptr<EventType> &inEvent, bool bInShouldExcuteOnce = false)
        {
            boundEvent = inEvent;
            bShouldExcuteOnce = bInShouldExcuteOnce;
        }

        void Unbind()
        {
            boundEvent.reset();
        }

        void IsBound()
        {
            return boundEvent && !boundEvent.expired();
        }

        ReturnType Execute(ParameterTypes... args)
        {
            auto event = boundEvent.lock();

            if (bShouldExcuteOnce)
            {
                boundEvent.reset();
                boundEvent = nullptr;
            }

            return event(args...);
        }

    private:
        bool bShouldExcuteOnce;
        std::weak_ptr<EventType> boundEvent;
    };
```
> + `Bind`和`Unbind`: 提供绑定和解绑操作。提
> + `IsBound`: 判定是否对该委派进行过绑定。
> + ·`Execute`：传入参数以及获得返回值。

主要需要注意的是Bind传入的是一个Shared Pointer，然后让我们的delegate实例保留对它指向的数据的弱引用。通过这样的设计外部的函数是否有效和我们的委派实例本身就没有关联，如果指针已经失效则忽略它。也即是前面提到自动管理life time。

使用时是通过以下方式：
```
    SingleDelegate<int, int> testSingleDelegate;
    auto f1 = std::make_shared<SingleDelegate<int, int>::EventType>([](int i) -> int { return i * i; });
    testSingleDelegate.Bind(f1);
```
这里是绑了一个lambda函数，实际上只要最后类型是`SingleDelegate<int, int>::EventType`的函数就行了，当然可以也使用`std::bind`,后面muticast的例子会用到。

#### Multicast Delegate
代码如下：
```cpp
template<typename ...ParameterTypes>
    class MulticastDelegate
    {
    public:
        using  EventType = std::function<void(ParameterTypes...)>;

        MulticastDelegate() = default;
        ~MulticastDelegate() = default;

    public:
        void add(std::shared_ptr<EventType> &inEvent, bool bInShouldExcuteOnce = false)
        {
            if (!bInShouldExcuteOnce)
            {
                events.push_back(inEvent);
            }
            else
            {
                eventsExecuteOnce.push_back(inEvent);
            }
        }

        void Remove(std::shared_ptr<EventType> &inEvent)
        {
            {
                auto iter = events.begin();
                while (iter != events.end())
                {
                    if ((*iter).expired())
                    {
                        iter = events.erase(iter);
                    }
                    else
                    {
                        auto event = (*iter).lock();
                        if (event == inEvent)
                        {
                            iter = events.erase(iter);
                        }
                        else
                        {
                            iter++;
                        }
                    }
                }
            }

            {
                auto iter = eventsExecuteOnce.begin();
                while (iter != eventsExecuteOnce.end())
                {
                    if ((*iter).expired())
                    {
                        iter = eventsExecuteOnce.erase(iter);
                    }
                    else
                    {
                        auto event = (*iter).lock();
                        if (event == inEvent)
                        {
                            iter = eventsExecuteOnce.erase(iter);
                        }
                        else
                        {
                            iter++;
                        }
                    }
                }
            }
        }

        void Broadcast(ParameterTypes ...args)
        {
            {
                auto iter = events.begin();
                while (iter != events.end())
                {
                    if (!(*iter).expired())
                    {
                        auto event = (*iter).lock();
                        (*event)(args...);
                        iter++;
                    }
                    else
                    {
                        iter = events.erase(iter);
                    }
                }
            }

            {
                auto iter = eventsExecuteOnce.begin();
                while (iter != eventsExecuteOnce.end())
                {
                    if (!(*iter).expired())
                    {
                        auto event = (*iter).lock();
                        (*event)(args...);
                    }

                    iter = eventsExecuteOnce.erase(iter);
                }
            }
        }

    private:
        std::vector<std::weak_ptr<EventType>> events;
        std::vector<std::weak_ptr<EventType>> eventsExecuteOnce;
    };
```

比Single delegate的实现稍微复杂那么一丢丢，主要是引入了两个vector来装我们加入的绑定函数的指针，这样在broadcast调用的时候就可以遍历派发了。为了描述简便这里是分了俩vector，只需要执行一次就放弃的和可能需要多次执行的。

使用用法和上面single delegate大同小异：
```cpp

    class Foo
    {
        public:
        void TestMulticastDelegate(int inValue)
        { 
            //Do Something with inValue.
         }
    }

    Foo a;
    Foo b;

    MulticastDelegate<int> testMulticastDelegate;
    auto f1 = std::make_shared<MulticastDelegate<int>::EventType>(std::bind(&Foo::TestMulticastDelegate, a, std::placeholders::_1));
    testMulticastDelegate.add(f1);
  
    auto f2 = std::make_shared<MulticastDelegate<int>::EventType>(std::bind(&Foo::TestMulticastDelegate, b, std::placeholders::_1));
     testMulticastDelegate.add(f2, true);
  
     //f1.reset();
    testMulticastDelegate.Remove(f2);
  
     testMulticastDelegate.Broadcast(5);
```
这里面的例子都是使用的是成员函数，实际上只要是符合声明形式的函数都是可以绑的。

### 总结
前面说了这个版本的实现是比较粗糙的，比如感觉可以把声明shared_ptr那一步省略掉或者简化点。但是作为0.1版话已经足够使用了。因此等后面对泛型编程了解更多后可以尝试扩展下。关于delegate的补充资料，可以搜索fast delegate，讲的非常详细，但是为了兼容不是使用纯C++11的，且较为复杂，暂时也没怎么看懂。等看懂了会分析和改进下它的写法把。
