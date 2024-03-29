---
title: 牛逼的AA
date: 2012-03-05T08:00:00+08:00
draft: false
toc:
comments: true
---


也许你还不知道 AA 是什么，但只看那牛逼哄哄的名字，就该知道它绝非善类。 

没错。进入这个项目的主页：<http://aa-project.sourceforge.net/>，就能看到它的三个宏伟目标：

* 将所有的重要软件移植到AA-lib
* 将AA-lib移植到所有的可用平台
* 迫使IBM重新制造MDA卡

>注：MDA（Monochrome Display Adapter ），单色字符显示适配卡，与单色字符显示器配接，它只支持字符显示功能，无图形功能，是一种相当古老的显卡。

如果你对技术不感兴趣，可用点击这里 <http://v.youku.com/v_show/id_XMzYwNTIyODY4.html>，观看利用 AA 制作的一段动画,制作方法和源代码在文档的最后一节。 

简单的说，它可用实现下面的效果，就是将图片转换为 ASCII 文本。

![](./pics_1.JPG)

这个略显粗糙，如果将字体调小，增大分辨率，可显示更加逼真的图片，例如：

![](./pics_2.JPG)

其实，这是一个由ASCII字符的狂热爱好者们开发的项目，最初的发起人叫 Jan Hubicka ，目的是将计算机上的一切都用 ASCII 字符来表现，包括图形和视频。


该项目提供了一个库—— AA-lib ，这是一个低级图形库，与其他的库的区别是它不需要图形设备，完全用 ASCII 字符描绘图形，它的 API 被设计得与其他库类似。还提提供一个演示程序—— BB（这个名字更显另类），播放了一段完全由 ASCII 字符绘制的动画，其中有文字，图像，分形几何，还有一个 3D 效果。

下面在 fedora12 中安装它们。

### 1. 安装 AA-lib

下载 aalib-1.2：

<http://prdownloads.sourceforge.net/aa-project/aalib-1.2.tar.gz>
	
最新版本是 1.4，但是 BB 是基于 1.2 的，所有先安装1.2。

解压、编译、安装：
	
    tar  xvzf aalib-1.2.tar.gz  
    cd  aalib-1.2  
    ./configure  
    make  
    make install  
	
默认安装在 /usr/local 下

### 2. 安装 bb

下载 bb-1.2：

<http://prdownloads.sourceforge.net/aa-project/bb-1.2.tar.gz>

编译前需要设置一个环境变量，否则会找不到 aa-lib：

    export CFLAGS=-I/usr/local/include  

解压：

    tar xvzf bb-1.2.tar.gz  
    cd aalib-1.2  
	
编译时会报 textform.c 文件的错误，是因为该文件内定义的某些字符串太长，换行时没有用反斜杠，可以在后面加上反斜杠	，或直接注释掉。然后编译：

    ./configure  
    make  
	
编译生成了可执行文件 bb，直接执行即可看到一段演示。最好在文本模式下执行，否则可能会报错。

这段演示还可以添加音乐，在源码的 mikunix 目录下有音频的程序，直接 make ，然后执行 strip ../bb\_snd\_	server。但是我一直没有弄出声音，也许是虚拟机的问题。

### 3. 安装 aview

aview 的作用是将 pnm 格式的图片转换为 ASCII 文本，并显示。aview只支持 pnm、pgm、pbm 和 ppm 格式的图片，所以需要将其他格式的图片转换，它提供了一个 asciiview 的脚本，利用 convert 转换图片格式，然后再传递给 aview。

aview 依赖于 aalib-1.4，所有要先用 1.4 替换之前安装的 1.2，安装方法与 1.2 相同。安装后下载 aview：<http://prdownloads.sourceforge.net/aa-project/aview-1.3.0rc1.tar.gz>

解压、编译、安装：
	
    tar xvzf aview-1.3.0rc1.tar.gz  
    cd  aview-1.3.0  
    ./configure  
    make  
    make install  

编译生成的 aview 程序可以将 pbm、pgm 或 pnm 图片用 ASCII 字符显示。但是不支持 JPEG 图片，所以它提供了一个 shell 脚本 ascii	view，先调用 convert 将 JPEG 图片转换为 pgm 图片，然后再用 aview 显示。

fedora12 中没有 convert 命令，先用下面的命令安装：

    yum  install  ImageMagick  

准备一张图片，例如 1.jpg，用下面的命令就可以把它转换为 ASCII文本：

    asciiview  1.jpg  

### 4. Bad Apple

下面参考 aview 的源码，编写了一个程序，在 Linux 的终端下播放一段由 ASCII 字符绘制的动画：Bad Apple。原理比较	简单，就是将视频逐帧截图，然后用程序按一定的时间间隔将图片依次转换为ASCII文本在终端上显示。动画视频在这里：<http://v.youku.com/v_show/id_XMzYwNTIyODY4.html>，动画中的卡顿是屏幕录像软件的问题，AA-lib本身是很流畅的。
	
制作步骤：
	
准备 apple.flv，用 kmplayer 做每 50 毫秒截图，截图为 jpeg 格式，把它们都复制到 /root/aa/img 目录下。

用下面 shell 脚本将 jpeg 图片转化为 pgm 格式，共 3202 张，文件名为 1.pgm 到 3202.pgm ，全部放在 pgm 文件夹下。
		
    #!/bin/sh  
    ls -l *.jpg > sort  
    i=1  
    while [ $i -le 3202 ]  
    do  
        filename=`sed -n ''$i'p' sort | awk '{print $8}'`  
        echo $filename  
        convert $filename ./pgm/$i.pgm  
        i=`expr $i + 1`  
    done  
	
在 pgm 文件夹下执行程序：
	
    ./aviewdemo -contrast 20 -extended 1.pgm  
	
程序源码在这里：<http://download.csdn.net/detail/exbob/4112093>
	
动画视频在这里：<http://v.youku.com/v_show/id_XMzYwNTIyODY4.html>
