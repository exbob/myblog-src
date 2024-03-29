---
title: Font Awesome 矢量字体图标
date: 2013-10-15T08:00:00+08:00
draft: false
toc:
comments: true
---


项目主页：<http://fortawesome.github.io/Font-Awesome/>

目前的  Version 3.2.1  版本支持如下特性：

* 一个字体文件， 361 个图标
* 用 CSS 控制样式
* 无限缩放
* 免费
* 支持视网膜屏幕
* 为 Bootstrap 设计，也可集成到非 Bootstrap 项目


## 1.集成

1. 复制 font 目录到项目根目录下
2. 复制 css 目录到项目根目录下，主要使用 font-awesome.min.css 文件
3. 修改 font-awesome.min.css 文件中的字体路径，默认是 ../font/ 
4. 在 html 文件中引用 css 文件：`<link rel="stylesheet" href="./css/font-awesome.min.css" type="text/css" />`

## 2.实例

### 使用图标

	<i class="icon-youtube"></i> icon-youtube

<i class="icon-youtube"></i> icon-youtube

其中的 icon-youtube 是图标的名称，所有支持的图标名称可以在 font-awesome.min.css 文件中查找，也可在 [Font-Awesome icons](http://fortawesome.github.io/Font-Awesome/icons/) 中预览。


### 更大的图标

通过给图标设置 icon-large、icon-2x、 icon-3x 或 icon-4x 样式，可以让图标相对于它所在的容器变得更大：

	<p><i class="icon-camera-retro icon-large"></i> icon-camera-retro</p>
	<p><i class="icon-camera-retro icon-2x"></i> icon-camera-retro</p>
	<p><i class="icon-camera-retro icon-3x"></i> icon-camera-retro</p>
	<p><i class="icon-camera-retro icon-4x"></i> icon-camera-retro</p>

<p><i class="icon-camera-retro icon-large"></i> icon-camera-retro</p>
<p><i class="icon-camera-retro icon-2x"></i> icon-camera-retro</p>
<p><i class="icon-camera-retro icon-3x"></i> icon-camera-retro</p>
<p><i class="icon-camera-retro icon-4x"></i> icon-camera-retro</p>

### 动画微调

使用 icon-spin 使图标旋转，对于 icon-spinner 和 icon-refresh 图标可以得到很好的效果：

	<i class="icon-spinner icon-spin"></i> Spinner icon when loading content...

<i class="icon-spinner icon-spin"></i> Spinner icon when loading content...

	<i class="icon-refresh icon-spin"></i> Refresh icon when refresh content...

<i class="icon-refresh icon-spin"></i> Refresh icon when refresh content...

### 列表

在列表中使用图标：

	<ul class="icons">
	  <li><i class="icon-ok"></i> Lists</li>
	  <li><i class="icon-ok"></i> Buttons</li>
	  <li><i class="icon-ok"></i> Button groups</li>
	  <li><i class="icon-ok"></i> Navigation</li>
	  <li><i class="icon-ok"></i> Prepended form inputs</li>
	</ul>

<ul class="icons">
  <li><i class="icon-ok"></i> Lists</li>
  <li><i class="icon-ok"></i> Buttons</li>
  <li><i class="icon-ok"></i> Button groups</li>
  <li><i class="icon-ok"></i> Navigation</li>
  <li><i class="icon-ok"></i> Prepended form inputs</li>
</ul>
