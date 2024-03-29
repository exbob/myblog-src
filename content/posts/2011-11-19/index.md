---
title: pkg-config指南
date: 2011-11-19T08:00:00+08:00
draft: false
toc:
comments: true
---


原文：

Guide for pkg-config:<http://people.freedesktop.org/~dbn/pkg-config-guide.html>

Dan Nicholson

Translated By Bob

2011-11-13

Email:<gexbob@gmail.com>

Blog:<http://shaocheng.li> 

***

## 概述

这个文档的目的是从用户和开发者的角度给一个 pkg-config 工具的使用概述。本文复习一些 pkg-config 背后的概念，怎样写 pkg-config 文件来支持你的项目，以及怎样用 pkg-config 集成第三方项目。

关于 pkg-config 的更多信息可以在 web 站点和 pkg-config 的 man 手册中找到。

本文档假的 pkg-config 在类UNIX操作系统中使用，例如 Linux。其他平台可能在一些细节上的存在差别。

## 为什么？

现代计算机系统使用了很多分层组件为用户提供应用。其中一个困难就是如何正确的整合这些组件。pkg-config 会收集系统中安装的库的数据，然后提供给用户。

如果没有 pkg-config 这样的数据系统，定位计算机提供的服务和获取它们的细节会很困难。对于开发者，安装软件包的 pkg-config 文件极大的简化了对 API 的获取。

## 一些概念

使用 pkg-config 的初级阶段是为编译和链接程序时提供必要的细节。数据存储在 pkg-config 文件中。这些文件有一个 .pc 的后缀，放在一个特定的、pkg-config 工具所知道的位置。我们会在后面描述更多的细节。

这个文件的格式包括预定义的关键字和自由形式的变量。例如：

	prefix=/usr/local  
	exec_prefix=${prefix}  
	includedir=${prefix}/include  
	libdir=${exec_prefix}/lib  
	Name: foo  
	Description: The foo library  
	Version: 1.0.0  
	Cflags: -I${includedir}/foo  
	Libs: -L${libdir} -lfoo  

以预定义关键字 Name：为例，以关键字开头，后面跟一个冒号和一个值。变量是一个字符串和一个值，例如 prefix= ，用等号分开。关键字是由 pkg-config 定义和输出的。变量不是必须的，但可以被关键字用来定位和存储 pkg-config 没有覆盖的数据。

这里只是简单的描述一下关键字。更深入的描述和怎样有效的使用它们将在“写pkg-config文件”段中给出。

**Name：**一个人们可读的链接库或软件包的名称，这不影响pkg-config的使用，它用的是.pc文件的名称。

**Description：**关于软件包的简单描述。

**URL：**一个URL，可以在那里获得更多的信息，并且下载这个软件包。

**Version：**软件包的版本。

**Requires：**这个软件包所需的包的列表。这些包的版本可能用一写运算符来指定：=、>、<、>=、<=。

**Requires.private：**这个软件包所需的私有包的列表，不会暴露给应用。版本的指定规则与Requires相同。

**Conflicts：**可选，描述了会与这个软件包产生冲突的包。版本的指定规则与Requires相同。这个域会提供同一个包的多个实例，例如：Conflicts: bar < 1.2.3, bar >= 1.3.0。

**Cflags：**为这个软件包指定编译器选项，以及pkg-config不支持的必要的库。如果所需的库支持pkg-config，应该将它们添加到Requires和Requires.private。

**Libs：**为这个软件包指定的链接选项，以及pkg-config不支持的必要的库。与Cflags的规则相同。

**Libs.private：**这个软件包所需的私有库的链接选项，不会暴露给应用。规则与Cflags相同。

## 写pkg-config文件

为一个软件包创建 pkg-config 时，首先要确定怎样描述它。一个文件最好只用于描述一个库，所以，每个软件包至少需要像它所需的链接库那么多的 pkg-config 文件。

软件包的名字是由 pkg-config 数据文件的名字确定的。就是文件名去掉 .pc 后缀的那一部分。通常都用库的名字命名 .pc 文件。例如，一个安装 libfoo.so 的包会有一个相应的 libfoo.c 文件来包含 pkg-config 数据。这不是必须的，.pc 文件仅仅是一个对你的库的唯一标识符。所以，foo.pc 或 foolib.pc 也能正常工作。

Name、Description 和 URL 的值是纯粹的信息，容易填写。Version 比较棘手，它要确保这个包可以被用户使用。pkg-config 使用 RPM 算法来进行版本比较。Version 最好是用点分开的十进制数字，例如 1.2.3，因为字母可能引起意外的结果。数字应该是单调递增的，并且要竟可能具体的描述这个库。通常使用包的版本号即可，这样可以方便使用者跟踪。

在描述更多的有用的关键字之前，有必要展示一下变量的定义。最常见的用法是定义安装路径，这样就不会使其他字段显得杂乱。因为变量是扩大递归的，在结合 autoconf 派生路径时，这会很有用。

	prefix=/usr/local  
	includedir=${prefix}/include  
	Cflags: -I${includedir}/foo  

最重要的 pkg-config 数据字段是 Requires，Requires.private，Cflags，Libs 和 Libs.private 。它们定义的数据被外部项目用来编译和链接库。

Requires 和 Requires.private 定义了库所需的其他模块。通常首选 Requires.private，以便避免程序链接到一些不必要的库。如果一个程序不使用所需库的符号，它就不应该直接链接到这个库。可以在 overlinking 的讨论中看到更多详细的解释。

由于 pkg-config 通常会公开 Requires 库的链接标识，这些模块会变成程序的直接依赖。另外，Requires.private 中的库只有在静态链接是才会被包含。正因如此，pkg-config 通常只会适当的从 Requires 中的同一个包中添加模块。

Libs 包含了使用库是所必须的链接标识。此外，Libs 和 Libs.private 还包含了 pkg-config 不支持的库的链接标识。与 Requires 类似，首选将外部库的链接标识添加到 Libs.private，这样，程序就不会获得额外的直接依赖。

最后，Cflags 包含了所用的库的编译标识。与 Libs 不同，Cflags 没有私有变种。这是因为，数据类型和宏定义在任何链接情况下都是需要的。

## 使用pkg-config文件

假设系统中已经安装了 .pc 文件，pkg-config 工具就被用来提取其中的数据。执行 pkg-config --help 命令可以看到一些关于命令选项的简单描述。深入的描述可以在 pkg-config（1）的 man 手册页中找到。本地将对一些常见的用法进行简单的描述。

假设系统中已经有了两个模块：foo和bar。它们的.pc文件可能像下面这样：

	foo.pc:  
	prefix=/usr  
	exec_prefix=${prefix}  
	includedir=${prefix}/include  
	libdir=${exec_prefix}/lib  
	Name: foo  
	Description: The foo library  
	Version: 1.0.0  
	Cflags: -I${includedir}/foo  
	Libs: -L${libdir} -lfoo  
	bar.pc:  
	prefix=/usr  
	exec_prefix=${prefix}  
	includedir=${prefix}/include  
	libdir=${exec_prefix}/lib  
	Name: bar  
	Description: The bar library  
	Version: 2.1.2  
	Requires.private: foo >= 0.7  
	Cflags: -I${includedir}  
	Libs: -L${libdir} -lbar  

模块的版本可以用 --modversion 选项获得。

	$ pkg-config --modversion foo  
	1.0.0  
	$ pkg-config --modversion bar  
	2.1.2  

要打印模块的链接标识，就用 --libs 选项。

	$ pkg-config --libs foo  
	-lfoo  
	$ pkg-config --libs bar  
	-lbar  

请注意，pkg-config 压缩了两个模块 Libs 字段。这是因为 pkg-config 对 -L 标识有特殊处理，它知道 ${libdir} 目录 /usr/lib 是系统链接器搜素路径的一部分。也就是 pkg-config 受到了链接器选项的影响。

还有就是，虽然 foo 是 bar 所需要的，但是没有输出 foo 的链接标识。这是因为，只使用 bar 库的应用并不直接需要 foo。对应静态链接 bar 的应用，我们需要两个链接标识:

	$ pkg-config --libs --static bar  
	-lbar -lfoo  

这种情况下，pkg-config就要输出两个链接标识，这样才能保证静态链接的应用可以找到所有必须的符号。另一方面，它会输出所有的Cflags字段。

	$ pkg-config --cflags bar  
	-I/usr/include/foo    
	$ pkg-config --cflags --static bar  
	-I/usr/include/foo  

还有一个有用的选项，--exists，可以用来测试模块的可用性。

	$ pkg-config --exists foo  
	$ echo $?  
	0  

最值得注意的 pkg-config 特性是它所提供的版本检测，可以用来确定某个版本是否可用。

	$ pkg-config --exists foo  
	$ echo $?  
	0  

有些命令在结合 --print-errors 选项使用时可以输出更详细的信息。

	$ pkg-config --exists --print-errors xoxo  
	Package xoxo was not found in the pkg-config search path.  
	Perhaps you should add the directory containing `xoxo.pc'  
	to the PKG_CONFIG_PATH environment variable  
	No package 'xoxo' found  

上面的信息出现了 PKG\_CONFIG_PATH 环境变量。这个变量用来配置 pkg-config 的搜索路径。在类 Unix 操作系统中，会搜索 /usr/lib/pkconfig 和 /usr/share/pkgconfig 目录。这通常已经覆盖了系统已经安装的模块。但是，有些本地模块可能安装在了其他路径，例如 /usr/local 。这种情况下，需要指定搜索路径，以便 pkg-config 可以定位 .pc 文件。

	$ pkg-config --modversion hello  
	Package hello was not found in the pkg-config search path.  
	Perhaps you should add the directory containing `hello.pc'  
	to the PKG_CONFIG_PATH environment variable  
	No package 'hello' found  
	$ export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig  
	$ pkg-config --modversion hello  
	1.0.0  

autoconf也提供了一些宏，可以将pkg-config集成到项目中。

* PKG\_PROG\_PKG\_CONFIG(\[MIN-VERSION])：定位系统中的 pkg-config 工具，并检测版本兼容性。
* PKG\_CHECK\_EXISTS(MODULES,\[ACTION-IF-FOUND], \[ACTION-IF-NOT-FOUND])：检测指定的模块是否存在。
* PKG\_CHECK\_MODULES(VARIABLE-PREFIX,MODULES, \[ACTION-IF-FOUND], \[ACTION-IF-NOT-FOUND]):：检测指定的模块是否存在，如果存在，就根据 pkg-config --cflags 和 pkg-config --libs 的输出设置 &lt;VARIABLE-PREFIX>\_CFLAGS and &lt;VARIABLE-PREFIX>\_LIBS。

## 常见问题

1. 我的程序使用了x库，我该怎么做？
	pkg-config 的输出可以在编译命令中使用，假设 x 库已经有了一个叫做 x.pc 的 pkg-config 文件：

		cc `pkg-config --cflags --libs x` -o myapp myapp.c  

	将 pkg-config 集成到 autoconf 和 automake 中使用会更强大。但是，用 PKG\_CONFIG\_PATH 宏可以很容易的在建立过程中访问元数据。

		configure.ac:  
		PKG_CHECK_MODULES(\[X], [x])  
		Makefile.am:  
		myapp_CFLAGS = $(X_CFLAGS)  
		myapp_LDADD = $(X_LIBS)  

	如果找到了 x 模块，宏会填充和替代 X\_CFLAGS和X\_LIBS变量。如果没有找到，会产生错误。配置 PKG\_CHECK\_MODULES 的第3、4个参数，可以控制没有找到模块时的动作。

2. 我的 z 库安装了保护 libx 头的头文件。我应该在 z.pc 中添加什么？

	如果 x 库支持 pkg-config，将它添加到 Requires.private 字段。如果不支持，就配置 Cflags 字段，添加一些使用 libx 头时所需的编译器标识。在这两种情况下，无论是否使用了--static，pkg-config 都会输出编译器标识。

3. 我的 z 库内部使用了 libx，但是不能再公开 API 中暴露libx的数据类型。我应该在 z.pc 中添加什么？
	
	同样的，如果 x 支持 pkg-config，就把它添加到 Requires.private 。这种情况下，就没必要发出编译器标识，但是在今天链接时要确保有链接器标识。如果 libx 不支持pkg-config ，就将必要的链接器标识添加到 Libs.private。

***

Dan Nicholson &lt;dbn.lists (at) gmail (dot) com>

Copyright (C) 2010 Dan Nicholson.

This document is licensed under the GNU General Public License, Version 2 or any later version.
