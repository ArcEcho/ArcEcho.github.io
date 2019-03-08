---
title: 在UMG中使用帧动画(C++&Slate&UMG)
date: 2017-04-16 06:29:28
tags: [UE4, UE4.15.x, c++]
categories: Tech
---

UI界面通常会使用帧动画来完成一些效果，那么在UE4中如何使用帧动画呢？在搜索一番后没有找到比较好的解决方案，便自行研究并实现了下。注意使用的版本的UE4.15.1。
<!---more--->

## 效果预览 
开门见图，这是最终的效果。
![](效果.gif)

 功能点：
+ 封魔录文字的效果会循环播放，每个loop间有大概1秒的间隔时间。飘带和刀剑文字的金属光泽间则没有。
+ 按钮在点下时，会播放一个滚动的效果。

具体运行情况见[github上的源代码](https://github.com/ArcEcho/CustomWidgetProj)。

## 阅读本文需要了解的知识
+ 基本的UMG和材质知识
+ UE4 C++及slate的基础知识。 

## UE4自带的功能实现UI中的Flipbook的方法

### Flipbook Material Function
我们知道Paper2D中可以展示一张Fipbook的图片的资源，同样的在Material Editor中也提供了一个名叫`Flipbook`的函数节点来播放动画。
![](MaterialEditor_Flipbook_Node.png)
这个节点是一个函数，双击可以展开看到里面具体的写法。这里不仔细解释这个函数，简单说下使用方法。通过传入`Animation Phase`来控制播放到第几帧，如果不传的话，函数内部默认按照时间输入更新动画帧数。这里值得注意的是你的所有的帧会在**一秒内播放完**，所以如果要控制播放速度的话，那么你就需要自己输入时间并乘上你想要的播放速率。
![](改变PlayRate.png)
总的来说这个方式，还算比较简便。记得把`Material Domain`改成`User Interface`，我们就可以将其用在SlateBrush上，然后看到动画效果了。使用动态材质或者材质实例，自己加入些控制的参数就可以简单的控制我们的动画。

### 在UMG的蓝图中用Tick函数实现
User Widget的蓝图中有Tick Event事件，这样我们就有了Delta Time，于是我们就可以来通过逻辑来定时的改变Image的Brush来实现动画。这种方式很直接，也很有效，大部分功能都能实现。

### 分析  
但是上述两种方式的缺点也很明显：
+ **仅使用Flipbook Node**无法实现播放一次就停下来且告知使用者动画结束等功能。可以认为Material Editor本质上是对Shader的一层工具化封装。那么Material Editor里面处理的是当前帧的数据，且不能记录数据。而实现我们要的播放一次，本质上需要记录我们播放的总帧数。实现暂停则需要记录是否是暂停的标识量。故这是无法实现的。另外如果时间使用内置的Input输入的话，我们无法控制每帧的具体时间。打个比方，如果电脑较卡，当第二次调用的时候可能过了x秒，这个时候flipbook就会直接按照x秒来计算要播放第几帧，那么就会出现跳帧的现象。
+ 使用User Widget蓝图来实现，前面说过的很直接很简单。但是需要控制一个动画在蓝图中要拖很多节点，并对该动画记录相关的变量来控制进程什么的。可以想象当界面上动画较多的时候这将会是多么恐怖的一件事情。当然可以使用蓝图自定义一个控件，在控件内部将这些东西封装起来，然后供别的控件来使用。这确实可行，但是考虑到动画这块是一个比较重的功能，而蓝图天生比C++方式慢很多，所以这种方式也不是很好。

## 使用Slate来创建自定义的控件
这个时候UE4提供源码的优势就体现了。我们可以通过继承相似功能的控件来实现我们想要的效果。这里我们选择了SLeafWidget做父类来创建我们需要的SUIFlipbookImage。另外我也将其用UWidget封装起来这样就可以直接在UMG中调用了。类图如下：
![](ClassDesign.png)

可以看到我们的控件需要支持的操作均有实现。具体代码内容可以参看github上的源码。这里只说说在做的时候需要注意的地方。

### 把SlateBrush放在SWidget中
我这里直接继承SLeafWidget，是为了把SlateBrush放在SUIFlipbookImage中方便操作。自带的SImage仅能通过const方式访问UImage的SlateBrush，而我们这里如果要实现动画效果的话，最好是更改SlateBrush的UVRegion。虽然也可以通过改变OnPaint函数中传入的AllotedGeometry的size和offset来达到效果。但是那种方式感觉怪怪的，我最开始就是那么写的，觉得是一种hack的手段。所以尝试了很久后，将其改为了现在的更改UV的方式了，这也是最直接明了且合乎逻辑的方式。但是这里需要注意的是：

+ 注意OnPaint后面那个const声明，OnPaint函数里面调用的SlateBrush的时候（成员变量）会被认为是一个const的对象。我个人猜测这里为了防止做一些过于繁重的操作，因为Paint需要较高的效率。实际想一下也可以理解，Brush的UV并不需要在每次绘制的时候重新计算。我们只需要在每次CachedFrameIndex变更的时候去就算下就可以了。

```cpp
class SUIFlipbookImage : public SLeafWidget
{
    FSlateBrush ImageBrush;    

publick:
    virtual int32 OnPaint(...) const override
}

int32 SUIFlipbookImage::OnPaint(...) const
{
    //...
    ImageBrush.SetUVRegion(...);  //This will not be compiled.
    //...
}
```

+ 初始化SlateBrush的时候需要将TileType设置为NoTile，默认构造的SlateBrush的是Tilling。这点我由于开始不知道从CoreStyle里面的DefaultSlateBrush取到的也是Tilling(实际上时对SlateBrush的原理不是很理解造成的)，浪费了很多时间。

### 在UUIFlipbook中仅让用户选择Texture
Image中可以将Material或者Texture等Asset设置给SlateBrush使用，这得益于UImage中提供的一系列转化各种资源的工具函数。但是对于UIFlipbook而言，我们只需要一张简单的Texture足矣。这里只需要在UUIFlipbook中声明一个`UTexture2D*`类型的成员，并在SynchronizeProperties的时候将其设置给给SUIFlipbookImage的SlateBrush设置就好了。

```cpp
   /**A texture is just enough, so here just surpport texture instead of slate brush */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "UIFlipbook", meta = (sRGB = "true"))
        UTexture2D* FlipbookImage;

void UUIFlipbook::SynchronizeProperties()
{
    Super::SynchronizeProperties();

    TAttribute<FSlateColor> ColorAndOpacityBinding = OPTIONAL_BINDING(FSlateColor, ColorAndOpacity);

    if (MyImage.IsValid())
    {
        //...
        
       MyImage->SetImageRes(FlipbookImage);
        
        //...
    }
} 
```

### 在一个动画Loop结束时抛出事件
这个可以参照Btton的OnClick事件写法来完成。需要先声明一个**多播委派**（区别于UImage的MouseDown绑定，因为要停供时间见，故必须是多播委派。）`DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnAnimationEndEvent)`。然后再声明一个`FOnAnimationEndEvent`的UPROPERTY成员以及一个处理的函数。

```cpp
     /** 
     * When an animation loop is end, this event will notify 
     * depends on your parameter in PlayAnimation().
     */
    UPROPERTY(BlueprintAssignable, Category = "UIFlipbook|Events")
        FOnAnimationEndEvent OnAnimationEnd;

    void HandleAnimationEnd();



```
这样就可以在编辑器的Details栏event区域看到我们的事件绑定的入口。点击后面的按钮就可以查看/添加相应的事件绑定。
![](EventOptionInEditor.png)

当然为了配合这个委派，SUIFlipbookImage中也需要声明一个`DECLARE_DELEGATE(FAnimationEndDelegate)`，并创建` FAnimationEndDelegate OnAnimationEndHandler`成员。并提供如下函数来让UUFlipbook绑定相应的委派。
```cpp
void SUIFlipbookImage::SetOnAnimationEnd(FAnimationEndDelegate EventHandler)
{
    OnAnimationEndHandler = EventHandler;
}
```
然后在UUIFlipbook中的`SynchronizeProperties`函数中设置绑定。
```cpp
void UUIFlipbook::SynchronizeProperties()
{
    Super::SynchronizeProperties();

    TAttribute<FSlateColor> ColorAndOpacityBinding = OPTIONAL_BINDING(FSlateColor, ColorAndOpacity);

    if (MyImage.IsValid())
    {
        //...
        
        MyImage->SetOnAnimationEnd(BIND_UOBJECT_DELEGATE(FAnimationEndDelegate, HandleAnimationEnd));
        
        //...
    }
} 
```
并在`HandleAnimationEnd`函数中去dipatch事件：
```cpp
void UUIFlipbook::HandleAnimationEnd()
{
    OnAnimationEnd.Broadcast();
}
```
最后回到我们的SUIFlipbookImage,当需要Notify end event的时候去调用`NotifyAnimationEnd`就可以了。
```
void SUIFlipbookImage::NotifyAnimationEnd()
{
    if (OnAnimationEndHandler.IsBound())
    {
        OnAnimationEndHandler.Execute();
    }
}
```
这样我们就实现了，当SUIFlipbookImage播放完一轮动画后，抛出相应的结束事件。并执行蓝图中的处理代码。
![](HandleEvent.png)

## 总结
以下是最终我们的UIFlipbook控件在UMG中使用的时候提供的选项，运用它可以实现开头的gif图中展示的效果了。

![](InDetails.png)

因为有UE4的源码，我们可以看到其背后实现的原理。虽然整个系统非常的繁杂，但是使用合理的方式去扩展其所提供的功能确实很简单的。这样可以避免很多丑陋的hack式的solution。也许我这里提供的方式不是最好的，但是比较接近我想要的功能了。且从这部分代码的实现过程中我对Slate部分理解更深了。如果你有什么疑问或者我有什么错误，或者有更优雅的实现方式。欢迎在下方留言。
