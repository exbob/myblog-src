---
title: 从源码建立XFree86
date: 2011-11-08T08:00:00+08:00
draft: false
toc:
comments: true
---


原文：

Building XFree86 from a Source Distribution

<http://www.xfree86.org/4.3.0/BUILD.html>

26 February 2003

Translated By Bob

Email：<gexbob@gmail.com>

Blog：<http://shaocheng.li> 

***

这个文档描述了怎样从源代码发行版构建XFree86，要结合特定操作系统的README文件来使用它。

>注：构建XFree86之前，最好参考特定操作系统的README文件，这些文件包含了在你的操作系统下成功构建XFree86所需的详细信息。

我们强烈推荐使用GCC构建XFree86，但是通常也可以使用各个平台的本地编译器。

***

## 1. 怎样得到XFree86 4.3.0 的源码

推荐的方法是从 XFree86 的 CVS 库中获取 XFree86 4.3.0 的源码。有多种途径可以做到这一点，可以在我们的 CVS 页面找到 xf-4.3.0 发行版的标签。

另一个途径是在 XFree86 的 FTP 站点下载 4.3.0 的 tar 格式源码包。步骤如下：

* XFree86 4.3.0的源码包含在 X430src-1.tgz, X430src-2.tgz, X430src-3.tgz, X430src-4.tgz,X430src-5.tgz, X430src-6.tgz 和 X430src-7.tgz 中。这些文件可以在 <ftp://ftp.xfree86.org/pub/XFree86/4.3.0/source/> 或 XFree86 站点的类似地址中找到。X430src-4.tgz 和 X430src-5.tgz包含了字体，X430src-6.tgz 和 X430src-7.tgz 包含了文档。X430src-1.tgz, X430src-2.tgz 和 X430src-3.tgz 包含了其他所有的东西。如果你不需要字体和文档，可以只下载 X430src-1.tgz, X430src-2.tgz 和 X430src-3.tgz。

* 运行下面的命令解压每个文件，确保足够的空间，全部源码大约需要305M，还要一些空间编译二进制文件。

		gzip -d < X430src-1.tgz | tar vxf -
		gzip -d < X430src-2.tgz | tar vxf -
		gzip -d < X430src-3.tgz | tar vxf -
		gzip -d < X430src-4.tgz | tar vxf -
		gzip -d < X430src-5.tgz | tar vxf -
		gzip -d < X430src-6.tgz | tar vxf -
		gzip -d < X430src-7.tgz | tar vxf -


如果你已经有了一份 XFree86 4.2.0 源码的拷贝，可以从 <ftp://ftp.xfree86.org/pub/XFree86/4.3.0/patches/> 下载补丁来升级到 4.3.0 。补丁的下载和使用信息可以在这个发行版的R EDAME 文件的 “How to get XFree86” 段找到。
所有的方法都将产生一个主源码目录，叫做 xc 。

## 2. 构建之前先配置源码

在大多数情况下，没有必要做任何配置。

如果你确实想要改变配置，建议你先进入 xc/config/cf 目录，复制 xf86site.def 为 host.def。然后通过阅读 host.def 文件，根据你的配置设置你想要的参数。你也可以通过查看 .cf 文件，找出针对你的操作系统的默认设置。

通常遵循的规则是，只修改你理解的选项，并且有好的修改原因。修改默认配置容易产生一些问题。很多配置选项记录在 xc/config/cf/README。

如果你只使用源代码的 x430src-1.tgz,x430src-2.tgz 和 x430src-3.tgx 部分，你需要定义 BuildFonts 为 NO。

## 3. 使用符号链接的目录来构建

推荐的做法是，用一个符号链接的目录来构建 XFree86。这样可以保证源代码目录在构建过程中不被修改，还有以下好处：

* 当使用 CVS 维护源码树的更新时，更新进程不会被非 CVS 控制的文件所干扰。
* 可以用同样的源码为不同的操作系统或架构构建 XFree86 ，用只读的 NFS 共享。
* 可以用不同的配置构建 XFree86，只需要在每一个构建树中放一个 host.def 的拷贝，并且分别定义。

用下面步骤建立一个符号链接目录：

* 在构建树的顶层创建目录，通常新建在xc目录的同层，但不是强制性的。

		cd [xc目录]
		mkdir build

* 用“lndir”命令创建影子树：

		lndir ../xc

	注：如果需要的话，最好使用xc目录的绝对路径。


如果你的系统没有安装 lndir ，你可以用下面的命令从 XFree86 的源码安装它：

	cd xc/config/util
	make -f Makefile.ini lndir
	cp lndir [some directory in your PATH]

随着时间的推移，可能在构建树中产生一些陈旧的链接，例如，当源码中的文件被删除或重命名。可以在构建目录中运行“cleanlinks”脚本来清除。很少会因为一些变化而要从头开始重新创建构建树。如果有这样的情况，那可能是构建过程中问题。最好的方法是删除构建树，然后按上面的步骤重新构建。

## 4. 构建和安装

构建之前，读一下 xc/programs/Xserver/hw/xfree86/doc 中与你相关的特定操作系统的 README 。一旦特定操作系统的详情已经有了描述，就可以到你的构建目录（xc目录或之前建立的影子树），运行“make World”，如果有必要，就带上 README 中描述的 BOOTSTRAPCFLAGS 设置，但是 XFree86 支持大多数操作系统已经不需要 BOOTSTRAPCFLAGS。一个明智的做法是将 stdout 和 stderr 重定向到 World.log，以便追踪构建过程中可能产生的问题。

* 在类 Bourne 的 shell(Bash,Korn shell,zsh,等)中使用如下的命令：

		make World > World.log 2>&1

* C-shell(csh,tcsh,等)中使用：

		make World >& World.log

你可以根据构建的进展运行：
	
	tail -f World.log

构建完成后，如果有什么问题，你需要检查 World.log 文件。如果没有问题，你就可以安装二进制文件了。默认的“make World” 过程会忽略错误，以便尽可能的构建成功。如果在这一步中有无法解决的问题，安装过程将会失败。解决问题后重新开始构建时，只需要运行 “make” 。如果在解决问题的过程中改变了 Imakefile 或其它构建配置，需要重新运行 “make World” 或 “make Everything”。

如果你想要 “make World” 在第一个错误是结束，用下面的命令来替换前面所讲的:

* 在类Bourne的shell中：

		make WORLDOPTS= World > World.log 2>&1

* 在C-shell中：

		make WORLDOPTS= World >& World.log 


对于安装，运行“make install”和“make install.man”。确保 /usr/X11R6 中有足够的空间用于安装。如果你想要安装在 /usr 之外的文件系统，需要在新建一个指向 /usr/X11R6 的符号连接。

## 5. 重新配置服务器

为服务器构建不同的设置，或带有不同驱动设置的服务器。

1. 确保新的驱动源码在正确的位置（例如，驱动源码应该在 xc/programs/Xserver/hw/xfree86/drivers 下的一个子目录）。
2. 修改host.def（你要构建的服务器）中定义的服务器设置，也可以根据你的需要修改驱动列表。
3. 在xc/programs/Xserver中运行：

		make Makefile
		make Makefiles
		make includes
		make depend
		make

## 6. 其他有用的make目标

下面是一些在 XFree86 的 Makefile 中定义的其他有用的目标：

* **Everything**  make Worle之后，make Everything 会做任何 make World 可以做的，除了清理树。这是一个为源码打补丁后、快速重新构建树的方法。但它并不是100%可靠的。最好是用 make World 做一次完整的构建。
* **clean**       用于对源码树进行局部清理。删除目标文件和生成的手册页，但是保留 Makefile 和生成的依赖文件。执行 make clean 后，你需要重新运行以下命令来重新构建 XFree86 ：

		make include 
		make depend
		make

* **disclean**   对源码树进行完全清理，删除所有的生产文件。make disclean后，只能用make World重新构建XFree86。
* **includes**  生产所有的可生成头文件和构建所需的符号链接。make clean时，这些文件会被删除。
* **depend**   重新计算 Makefile 中各个目标的依赖关系。根据操作系统，依赖关系储存在 Makefile ，或一个独立的文件中，叫做 .depend。这目标需要用到 make includes 生产的头文件。VerifyOS  显示检测到的操作系统的版本。如版本号与你的系统不匹配，你可能要在 host.def 中设置并且向 <XFree86@XFree86.org> 报告这个问题
