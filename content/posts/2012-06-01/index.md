---
title: 在 Redhat9 文本系统上安装 Qt/E 4.4.0
date: 2012-06-01T08:00:00+08:00
draft: false
toc:
comments: true
---


Qt Embedded 直接依赖 Framebuffer，无需 X-Window。所以要开启 Linux 系统的 Framebuffer 。开启方法是通过 BootLoader 向内核传递参数：

* 对于 grub，在 grub.conf 文件的kernel 命令后面添加 vga=0x311 fb:on 。
* 对于 lilo，在 lilo.conf 文件中添加 vga=0x311。0x311 表示分辨率为 640*480，16dpp。

## 编译安装

首先下载 Qt/E-4.4.0 的源码，然后解压在 root 目录：

	cd /root
	tar -xvjf qt-embedded-linux-opensource-src-4.4.0.tar.bz2
	cd qt-embedded-linux-opensource-src-4.4.0

源码中包含了文档、例程。这些会占用很多空间和编译时间，如果不需要的话就修改 configure ，把它去掉：

	QT_DEFAULT_BUILD_PARTS="libs tools examples demos doc" 

	改为

	QT_DEFAULT_BUILD_PARTS="libs tools"

通过 configure 的选项可以关闭很多不需要的模块，用 ./configure -help 查看详情。

<!-- more -->

针对嵌入式版本，还可以用 -no-feature-&lt;feature> 关闭相应的特性，默认情况下会编译全部的特性。可用的 feature 在 src/corelib/global/qfeatures.txt 文件中有完整描述。但是这个方法不方便，通常是通过 -qconfig 参数指定一个配置文件，在 src/corelib/global/ 目录下有几个典型的配置文件：

	qconfig-large.h  #包含了大多数特性。
	qconfig-small.h  #关闭了很多特性。
	qconfig-minimal.h   #最小配置，几乎关闭了所有特性。

可以手动编辑修改配置。但是各种特性之间的依赖很复杂，所有Qt提供了一个图形工具 qconfig 来帮助生成配置。这个工具需要编译，安装 Qt/E 后再介绍。 

执行：

	./configure -prefix /usr/qt -release -no-largefile -no-qt3support -no-xmlpatterns -no-phonon -no-svg -no-webkit  -no-mmx -no-3dnow -no-sse -no-sse2 -no-gif -no-libtiff -no-libmng -qt-libpng -qt-libjpeg -no-openssl -no-nis -no-cups -no-iconv -no-opengl -no-dbus -qt-freetype -depths 16 -embedded x86 -qt-decoration-default -qt-gfx-linuxfb -qt-kbd-tty -qt-kbd-usb -qt-mouse-pc -qt-mouse-bus -no-glib -qconfig src/corelib/global/qconfig-small.h
	make
	make install

编译工程需要几个小时，所有文件都会被安装到 /usr/qt/ 目录下。现在配置环境变量：
在 /etc/profile 文件中添加：

	PATH=$PATH:/usr/qt/bin

在 /etc/ld.so.conf 文件中添加：

	/usr/qt/lib

然后执行 ldconf -v

重启系统后，Qt/E 就可以使用了。 

## 测试

demo.cpp

	#include <QApplication>  
	#include <QPushButton>  
	#include <QFont>  
	#include <QTextCodec>  
	int main(int argc, char *argv[])  
	{  
	    QApplication app(argc, argv);  
	    QTextCodec *codec = QTextCodec::codecForName("GB18030");    
	    QTextCodec::setCodecForLocale(codec);    
	    QTextCodec::setCodecForCStrings(codec);    
	    QTextCodec::setCodecForTr(codec);    
	    QPushButton hello("Hello 世界!");  
	    hello.show();  
	    return app.exec();  
	}  

编译：

	qmake -project
	qmake
	make

编译生成了 demo 程序，运行：

	./demo -qws -fn wenquanyi

![](./pics_1.PNG)


## 用qconfig工具配置qconfig-local.h文件

进入qconfig的源码目录编译生成 qconfig ：

	cd  tools/qconfig/
	qmake 
	make

执行qconfig：

	./qconfig -qws

首次打开时可能出现如下界面，需要导入 feature.txt 文件：

![](./pics_2.PNG)

选择 src/corelib/global/feature.txt 文件，然后点击 Open ，就会导入所有可配置的特性：

![](./pics_3.PNG)

在左侧的树状列表中选择需要编译的特性，然后通过 File 菜单的 Save As 保存为qconfig-local.h文件即可。
也可以通过 File -> Open 打开已有的配置文件，例如 qconfig-small.h，进行修改。
