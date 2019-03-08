---
title: Hexo Next下添加版权声明模块
date: 2017-04-08 05:10:06
tags: [Hexo,Next]
categories: Misc
---
在网上找了较多Next下的教程，均未达到想要的效果。于是自己根据Html标签找到位置后，理解代码并进行魔改。总结下即是如下教程。因为审美不佳，故直接借用了**[Next作者的格式和样式](http://notes.iissnan.com/2015/something-about-next/)**。
<!-- more -->

### 魔改脚本建立基础的HTML代码
首先定位到Theme文件夹下的layout/_Marco/post.swig文件，这个和于layout下的post.swig的区别是前者扶着具体的post-content的生成，而后者是调用前者，然后补充类似comment第三方的模块的脚本。找到post-body所在的标签，并在其后加上如下代码：
```swig
    <div>    
     {# 表示如果不在索引列表中加入后续的HTML代码 #}
     {% if not is_index %}
        <ul class="post-copyright">
          <li class="post-copyright-author">
              <strong>本文作者：</strong>{{ theme.author }}
          </li>
          <li class="post-copyright-link">
            <strong>本文链接：</strong>
            <a href="{{ url_for(page.path) }}" title="{{ page.title }}">{{ page.path }}</a>
          </li>
          <li class="post-copyright-license">
            <strong>版权声明： </strong>
            本博客所有文章除特别声明外，均采用 <a href="http://creativecommons.org/licenses/by-nc-sa/3.0/cn/" rel="external nofollow" target="_blank">CC BY-NC-SA 3.0 CN</a> 许可协议。转载请注明出处！
          </li>
        </ul>
      {% endif %}
    </div>
```
这样就生成了基础的HTML代码。类似theme.autor的变量，或从配置中读取或在运行时获取

### 加上样式
定位到Next下的source/css/_custom/custom.styl,并在里面添加如下样式代码:
```css
    .post-copyright {
        margin: 2em 0 0;
        padding: 0.5em 1em;
        border-left: 3px solid #ff1700;
        background-color: #f9f9f9;
        list-style: none;
    }
```
在下文章下方可以看到效果。

搭建的时候有说，马克飞象的markdown用的比较熟悉，但是hexo似乎不支持。感觉可以自己魔改下，有时间去尝试下。