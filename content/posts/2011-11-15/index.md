---
title: 在Redhat9下构建TinyX+GTK图形环境
date: 2011-11-15T08:00:00+08:00
draft: false
toc:
comments: true
---


## 概述

最近要将 Redhat9.02 移植到一块嵌入式 586 的主板上，空间有限，还要有图形环境，支持中文。所以，要建立一个精简的图像环境，先选择 TinyX+GTK 的方式进行研究。TinyX 是 XFree86 针对嵌入式的编译选项，体积小，启动速度快。
本文使用虚拟机 vmware 安装 Redhat-9.02 文本系统，然后用 XFree86-4.3.0 编译 TinyX ，最后编译 GTK+-2.0。

<!--more-->

## 1. 安装Redhat-9.02

在 vmware 上新建一个虚拟机，硬盘空间为 4GB，内存 512MB。开始安装 Redhat-9.02，选择 linux text 模式，中文安装语言，swap 分区为 512MB，其余空间都挂载到根目录下。bootloader 用 Grub，自定义安装软件包，选择的软件包如下：

	Administration tools
	Development Tools
	Editors
	Ftp Server
	Kernel Development
	NetWork Server
	Printing Support
	Server Configuration Tools
	Sound and Video
	System Tool

选择系统支持的语言为 Chinese+English。

安装后将 /etc/sysconfig/ 下的 i18n 文件修改如下：

	LC_CTYPE="zh_CN.GB2312"
	SUPPORTED="zh_CN.GB2312:en_US.UTF-8:en_US:en"
	SYSFONT="latercyrheb-sun16"
	SYSFONTACM="iso01"

## 2. 编译libpng-1.2.16

编译 TinyX 时需要 png.h 文件，所以要重新安装 libpng。先删除原有的 libpng：

	rm -rf /usr/lib/libpng*

下载 libpng-1.2.16.tar.bz2 ，复制到 /root 目录下解压：

	tar -xvjf  libpng-1.2.16.tar.bz2

源码包中的 README 和 INSTALL 文件有关于 libpng 的详细信息和编译安装方法，用如下命令编译安装：

	cd /root/libpng-1.2.16
	./configure
	make
	make install

默认安装在 /usr/local/ 目录下，支持 pkg-config，pkg-config 文件放在 /usr/lib/pkg-config/ 目录下。如果想卸载 libpng，执行：make uninstall。

## 3.编译freetype-2.2.1

删除原有的 freetype：

	rm -rf /usr/lib/libfreetype*

下载 freetype-2.2.1.tar.gz：<http://download.savannah.gnu.org/releases/freetype/>

复制到 `/root/` 目录下解压：

	tar -xvzf  freetype-2.2.1.tar.gz

编译、安装：

	cd /root/freetype-2.2.1
	./configure
	make
	make install

默认安装到 `/usr/local/` 目录下，支持 pkg-config。

## 4.编译TinyX

先删除原系统的 X-window：

	rm -rf /usr/X11R6
	rm -rf /etc/X11

下载XFree86-4.3.0：ftp://ftp.xfree86.org/pub/XFree86/4.3.0/，共下载7个软件包：

	X430src-1.tgz 
	X430src-2.tgz
	X430src-3.tgz
	X430src-4.tgz 
	X430src-5.tgz
	X430src-6.tgz 
	X430src-7.tgz

全部复制到 `/root` 下解压，解压后的源码都会放在 `/root/xc` 目录下。

先编译一个 lndir 工具：

	cd  /root/xc/config/util
	make -f Makefile.ini lndir
	cd ../../../

用 lndir 制作一个源文件的符号链接目录：

	mkdir build 
	cd build
	../xc/config/util/lndir  ../xc

用 TinyX.cf 的配置安装：

	cd config/cf
	cp -arf TinyX.cf host.def

修改 host.def 为：
	
	#define KDriveXServer  YES  
	#define TinyXServer    YES  
	#define XfbdevServer   YES  
	#define BuildLBX                YES  
	#define BuildFonts              YES  
	#define BuildAppgroup           NO  
	#define BuildDBE                NO  
	#define BuildXCSecurity         YES  
	#define FontServerAccess        NO  
	#undef BuildXF86RushExt  
	#define BuildXF86RushExt        NO  
	#undef BuildRender  
	#define BuildRender             YES  
	#define UseRgbTxt               YES  
	#define BuildFontServer         NO  

然后：

	cd ../../
	touch xf86Date.h
	touch xf86Version.h
	make World
	make install

主要的库、头文件、可执行文件和配置文件等都安装了在 `/etc/X11` 和 `/usr/X11R6` 下。

TinyX 依赖于 framebuffer，要打开 framebuffer。修改 `/etc/grub.conf` 文件，在 `kernel` 一行添加：

	vga=0x311 fb：on
	0x311为640x480，16bpp。

然后重启系统，启动时，屏幕左上方会出现一个企鹅 Logo。

重启后运行 /usr/X11R6/bin/Xfbdev，即可启动 Xserver，可以看到灰色背景上有一个 X 形的鼠标。
为 Xfbdev 建立一个符号链接：

	ln -s Xfbdev X

这样就可以用startx命令启动 X-window。用Ctrl+Alt+Backspace组合键退出X-window。

这里可能出现加载链接库的错误，查看 /etc/ld.so.conf 文件中是否有 /usr/X11R6/lib，然后执行 ldconfig -v。

## 5.设置pkg-config

在 /root/.bashrc 文件中添加 PKG\_CONFIG\_PATH 环境变量：

	export PKG\_CONFIG\_PATH=/usr/local/lib/pkgconfig:/usr/X11R6/lib/pkgconfig

## 6.编译Glib-2.0

先删除原有的 glib：

	rm -rf /usr/lib/libglib*
	rm -rf /usr/lib/libgmoudle*
	rm -rf /usr/lib/libgobject*
	rm -rf /usr/lib/gthread*

下载 glib-2.0.0.tar.bz2：<http://ftp.gnome.org/pub/gnome/sources/glib/2.0/>

复制到/root/目录下解压：

	tar -xvjf  glib-2.0.0.tar.bz2

编译、安装：

	cd /root/glib-2.0.0
	./configure
	make
	make install

默认安装到/usr/local/目录下，支持pkg-config。

## 7.编译atk-1.0.0

删除原有的 atk：

	rm -rf /usr/lib/libatk*

修改 /etc/ld.so.conf 文件，添加：

	/usr/local/lib

下载 atk-1.0.0.tar.bz2：<http://ftp.gnome.org/pub/gnome/sources/atk/1.0/>

复制到/root/目录下解压：

	tar -xvjf  atk-1.0.0.tar.bz2

编译、安装：

	cd /root/atk-1.0.0
	./configure
	make
	make install

默认安装到 /usr/local/ 目录下，支持 pkg-config。

## 8.编译pango-1.0.0

删除原有的pango：

	rm -rf /usr/lib/libpango*
	rm -rf /usr/lib/pango

下载pango-1.0.0.tar.bz2：<http://ftp.gnome.org/pub/gnome/sources/pango/1.0/>

复制到 /root/ 目录下解压：

	tar -xvjf  pango-1.0.0.tar.bz2

编译、安装：

	cd  /root/pango-1.0.0
	./configure
	make
	make install

默认安装到 /usr/local/ 目录下，支持 pkg-config。

## 9.编译libjpeg-6b

删除原有的 libjpeg：

	rm -rf  /usr/lib/libjpeg*

下载libjpeg-6b.tar.gz：<http://jaist.dl.sourceforge.net/project/cross-stuff/cross-stuff/1.0/libjpeg-6b.tar.gz>

复制到 /root/ 目录下解压：

	tar -xvzf  libjpeg-6b.tar.gz

编译、安装：

	cd  /root/libjpeg-6b
	./configure  --enable-shared
	make
	make install

默认安装到/usr/local/目录下。

## 10.编译gtk+-2.0

删除原有的gtk:

	rm -rf  /etc/gtk*
	rm -rf  /etc/gnome
	rm -rf  /usr/bin/*gtk*
	rm -rf  /usr/lib/libgtk*
	rm -rf  /usr/lib/gtk*

下载gtk+-2.0.0.tar.bz2：<http://ftp.gnome.org/pub/gnome/sources/gtk+/2.0/>

复制到/root/目录下解压：

	tar -xvjf  gtk+-2.0.0.tar.bz2

编译、安装：

	cd  /root/gtk+-2.0.0
	./configure  --without-libtiff
	make
	make install

默认安装到/usr/local/目录下，支持pkg-config。

## 11.测试

运行 startx，可以启动 X-window。
然后运行gtk-demo，可以启动 gtk-demo 程序。
编写 demo.c 文件：

	#include <gtk/gtk.h>  
	char *_(char *c)  
	{  
	    return(g_locale_to_utf8(c,-1,0,0,0));  
	}  
	int  main(int argc,char *argv[])  
	{  
	    GtkWidget *window;  
	    gtk_init(&argc,&argv);  
	    window = gtk_window_new(GTK_WINDOW_TOPLEVEL);  
	    gtk_window_set_title(GTK_WINDOW(window),_("中文窗口"));   //定义窗口的标题  
	    gtk_window_set_default_size(GTK_WINDOW(window),200,200);   //设置窗口的大小  
	    gtk_window_set_position(GTK_WINDOW(window),GTK_WIN_POS_MOUSE);   //设置窗口显示的位置为鼠标的位置  
	    gtk_widget_show(window);  
	    gtk_main();  
	    return 1;  
	}  

编译：

	gcc -Wall -o demo demo.c `pkg-config --cflags --libs gtk+-2.0` 

执行：

	./demo

效果：

![](./pics_1.JPG)
