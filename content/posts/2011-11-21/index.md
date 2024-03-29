---
title: 使用GNU Autoconf/Automake创建Makefile
date: 2011-11-21T08:00:00+08:00
draft: false
toc:
comments: true
---


原文：

How To Create a GNU Autoconf / Automake Based Configure Script for Your Application

<http://www3.fh-swf.de/fbin/roth/download/prg3.howto_autoconfmake.pdf>

by Prof.Dr. Walter Roth

University of Applied Science Suedwestfalen, Germany

Translated by Bob

2011-11-18

Email：<gexbob@gmail.com>

Blog：<http://shaocheng.li> 

***

## 1. 本文档的基本信息

### 1.1. 印刷

有些字体比较难认，所以用下面这个表给出一些字符的图像，这对命令很重要。本文档用 Times New Roman 的 12 号字体写普通文本，用 Courier 的 11 号字体写命令行和源代码。注意：双线可能会画成一个比较长的单线

![](./pics_1.PNG)

### 1.2. 名词定义

应用（Application）是指你开发的程序。

目标系统（target system）是用于安装你的程序的计算机。

开发系统（development system）是指开发程序所用计算机

## 2. 为什么使用GNU AutoXXX Tools？

使用 Autoconf 和 Automake 是唯一的（合理的）为你的应用创建 Makefile 的方法，只要你的应用工作在任何有 GNU 工具的系统上。GNU 工具可用于所有的 Unix、Windows（Cywin）和 MacOS 系统

## 3. 它是如何工作的？

GNU Autoconf 由多个程序组成，最终由它们为你的应用创建 Makefile。它会为源码的每个子目录创建一个 Makefile。由于Makefile 是针对特定的用户机器的（目标系统），也就是你的程序运行的系统，所以必须在用户机器上创建。目标系统的所有信息对于这个机器都是可用的。Makefile 是由冗长的脚步程序“configure”创建的，这个脚本必须随你的源代码一起提供。在目标系统上，configure 是根据它运行的一些测试结果来创建 Makefile 的，这些结果已经事先写在了 Makefile.am文件。Makefile 支持很多不同的目标，第一个就是“all”。make all 会为你的程序创建二进制文件。install 目标会安装这些二进制文件，uninstall 用于卸载。这样的话，用户就可以很方便的使用你的程序，只需应用的顶层目录上，运行如下三条命令即可：

	./configure  
	make  
	make install  

第二条命令就相当于 make all，因为 all 是第一个目标。当然，目标系统必须有可用 make 工具和一个编译器。但是，这要用 configure 检查，如果 configure 没有找到所有它需要的程序，它会停止并返回错误信息。
可是，必须在你的系统上创建 configure 脚本，这是个非常复杂的任务。

## 4. 你需要什么？

首先，需要你的源码。确保处在顶层目录，并且包含了所有的文件，编译时不会报错。

你可能要添加一些新文件，为你的应用提供一些必要的文档。下面这些文件是必须存在于顶层目录的：

* INSTALL：安装描述。你可以从其他基于automake的应用中拷贝一个标准的INSTALL文件，然后添加一些针对你的应用的信息。
* README：用户应该知道的一些关于本应用的信息。最好在文件的开始处简单描述一些这个应用的目的
* AUTHORS：作者列表。
* NEWS：关于本应用的最新的新闻
* ChangLog：本应用的修订历史

这些文件可以不包含任何内容，因此，第一次运行时，你可以只创建一些空文件。但是，这些文档对用户是很重要的。你应该花点时间好好的写了它们。README 文件是最重要的一个。让它尽可能的保护一些有用的信息。

然后，当然是需要GNU工具。幸运的是，现在所有的Linux发行版都包含了GNU工具。你可以验证一些它们是否已经安装。要检查的话，只需键入：

	which automake  

它会产生类似下面的结果：

	/usr/bin/automake  

如果返回的是空行，很可能没有安装GNU工具。

## 5. 一步一步为“Hello World”创建配置脚本

### 5.1. 简评

下面内容中的命令都用 Courier 字体。所有的命令都可以在普通用户中使用，无需变成 root 。例子中使用的应用叫做 myapplication，版本是 1.0。该应用只有一个文件夹“myapplication”，单一源文件 main.c。你要自己编辑源代码、文档、configure.ac 和 makefile.am 文件。其他的都可以自动生成。

### 5.2. 准备源码

进入应用的顶层目录。

	cd  myapplication  

建立前面提到的那些空文档文件，稍后再填写它们。

	touch INSTALL README AUTHORS NEWS ChangeLog  

### 5.3. 新建makefile.am

####5.3.1. 构建应用

makefile.am 包含了关于应用的信息，配置脚本需要这些信息来创建最终的 Makefile。必须建立一个 makefile.am，它的内容包括目标、源代码和应用的子目录。下面是 myapplication 的 makefile.am，没有子目录：

	##Process this file with automake to create Makefile.in   
	bin_PROGRAMS = myapplication   
	myapplication_SOURCES=main.c  

第一行是默认的内容，每个 makefile.am 都可以使用。第二行列出了要建立和安装到目标系统的二进制程序文件。本例中只有一个 myapplication，它将被安装到 SuSe9.0 系统的 /usr/bin 目录下，这是一个默认目录。如果你要构建多于一个的程序，或要安装到其他目录，请查看第7章的 Automake 文档。

第三行列出了该应用的所有源文件。第一个词是由应用名称和_SOURCES组成的。

####5.3.2. 安装文件

makefile.am 不仅仅管理应用的构建过程，还定义了要安装到目标系统的文件的目标路径。automake已经提前定义了标准的安装目录，其中最重要的几个目录是：

* prefix ：安装目录树的顶层，标准是/usr/local(KDE是/opt/kde)
* binary ：二进制程序的目录
* libexecdir ：程序的库的目录

还有更多的提前定义的目录，请阅读“The GNU Coding Startding”的目录变量（5）。安装到这些目录的文件会像下面这样被列出了：

	bin_PROGRAMS=myapplication  

myapplication文件将被放到一个bin目录下。

如果你需要将某些文件安装到非标准目录下，就要自己定义。名字必须以dir作为后缀。例如：

	htmldir=$(prefix)/html  

html 目录就会处于 prefix 之下。在 makefile.am 定义要安装的文件，如下：

	html_DATA=usermanual.html  

除了标准目录,automake 还为个别包定义了目录：pkglibdir、pkgincludedir 和 pkgdatadir，可以用它们将你的文件安装到标准的bin、lib或data目录下的独立子目录。这些安装目录会用包的名字命名。

并不是所有文件都要被最终安装。例如，图标（或图标），它们被编译到可执行文件后就不再需要了。但它们并不是真正的源文件。由于它们必须包含在最终的发布中，所有要把它们作为EXTRA_dist文件列出了。

### 5.4. 新建configure.ac

注意：在比较早的 automake 和 autoconf 版本中，configure.ac 被叫做 configure.in。autoscan 工具会扫描你的源代码，然后创建一个默认的 configure.ac 初始文件。因此，你可以在源代码的顶层目录执行 autoscan，生成一个 configure.scan 文件作为 configure.ac 的模板。

	autoscan  

autoscan的执行结果大概是这样：
	
	#         -*- Autoconf -*-   
	# Process this file with autoconf to produce a configure script.   
	AC_PREREQ(2.59)   
	AC_INIT(FULL-PACKAGE-NAME, VERSION, BUG-REPORT-ADDRESS)   
	AC_CONFIG_SRCDIR([config.h.in])   
	AC_CONFIG_HEADER([config.h])   
	# Checks for programs.   
	AC_PROG_CXX   
	AC_PROG_CC   
	AC_PROG_CPP   
	AC_PROG_INSTALL   
	AC_PROG_LN_S   
	AC_PROG_MAKE_SET   
	AC_PROG_RANLIB   
	# Checks for libraries.   
	# Checks for header files.   
	# Checks for typedefs, structures, and compiler characteristics.   
	AC_HEADER_STDBOOL   
	AC_C_CONST   
	# Checks for library functions.   
	AC_CONFIG_FILES([Makefile 
							src/Makefile])   
	AC_OUTPUT 

编辑 configure.scan 文件，修改下面这几行：

	AC_INIT(FULL-PACKAGE-NAME, VERSION, BUG-REPORT-ADDRESS)  

用你的应用的名字替换 FULL-PACKAGE-NAME ，VERSION 就是它的版本号。BUG-REPORT-ADDRESS 应该设一个 Email 地址，以便报告 Bug。例如：

	AC_INIT(myapplication,1.0)  

接下来添加一行，来调用 automake。

	AM_INIT_AUTOMAKE(@PACKAGE_NAME@, @PACKAGE_VERSION@)  

这一行使用 PACKAGE\_NAME 和 PACKAGE\_VERSION变量，它们都是 AC\_INIT 中定义过的，最终会传递给 automake。@ 表示它包含字符串的是一个变量标识符。没有用 @ 的字符串直接按字面传递，结果包含在 PACKAGE\_NAME\_PACKAGE\_VERSION 。

AC\_CONFIG\_SRCDIR 用于检测源代码目录下的 config.h 文件。AC\_CONFIG\_HEADER 表示你想要使用一个配置头文件。

下面的宏用于检测构建应用所需的各种程序，把你需要用在目标系统上的程序都添加到这里。

在 typedefs 这一组，你可以检测目标机器上的系统的特殊属性。AC\_HEADER\_STDBOOL 是 autoscan 为本例添加的，用于检测 stdbool.h 的可用性和 C99 的 bool 类型是否存在。AC\_C\_CONST 用于检测例程所需的常量机制。

最后，你可以在 AC\_CONFIG\_FILES 中指定所有你想要配置生成的 makefile 文件，这些文件将由 AC\_OUTPUT 输出，通常将它卸载文件的最后一行。

### 5.5. 新建config.h.in

运行 autoheader 可以根据 configure.ac 文件创建一个 config.h.in。如果你想要指定 config.h 中包含 #define，必须在 configure.ac 中定义。查看 autoconf 文档中的 AC\_CONFIG\_HEADER。

	autoheader  

这样就会建立 config.h 文件，文件的内容是用预处理描述应用程序的代码。下面这段文本是例程的 config.h.in 文件的一部分。

	/* config.h.in.  Generated from configure.in by autoheader.  */   
	* Define to 1 if stdbool.h conforms to C99. */   
	#undef HAVE_STDBOOL_H   
	/* Define to 1 if the system has the type `_Bool'. */   
	#undef HAVE__BOOL   
	/* Name of package */   
	#undef PACKAGE   
	/* Define to the address where bug reports for this package should be   
	sent. */   
	#undef PACKAGE_BUGREPORT   
	/* Define to the full name of this package. */   
	#undef PACKAGE_NAME   
	/* Define to the full name and version of this package. */   
	#undef PACKAGE_STRING   
	/* Define to the one symbol short name of this package. */   
	#undef PACKAGE_TARNAME   
	/* Define to the version of this package. */   
	#undef PACKAGE_VERSION   
	/* Define to 1 if you have the ANSI C header files. */   
	#undef STDC_HEADERS   
	/* Version number of package */   
	#undef VERSION   
	/* Define to empty if `const' does not conform to ANSI C. */   
	#undef const   

### 5.6. 新建aclocal.m4

很幸运有一个程序可以完成这个工作。只需执行：

	aclocal  

这样就创建了 aclocal.m4 文件。文件中包含了 autoconf 的宏，它们可以用在你的机器上。文件包含了宏的完整源代码，所以很长。如果没有在你的机器上找到所有的宏，可以尝试从 autoconf 的宏档案（www.gnu.org/software/ac-archive）中找一找。这里有很多宏，可以解决你遇到的大部分问题。另外，还有 BNV\_HVE\_QT 用于检测 Qt 库，MDL\_HAVE\_OPENGL 用于检测 OpenGL。

如果没有找到你所需的宏，就不得不自己去写了。“Goat book”（1）会告诉你怎么做。

### 5.7. 新建configure

现在，autoconf 就可以用 autoconfig.ac 和 aclocal.m4 创建一个配置脚本了。只需运行：

	autoconf  

这样会产生一个配置脚本，对于一个GUI应用，可能超过2000行。

### 5.8. 新建makefile.in

makefile.in 包含很多从 makefile.am 自动添加的信息。makefile.in 是配置脚本最终创建 Makefile 所必须的。很幸运的是，automake 程序可以为你完成这个工作。可是，一些应用程序发布包所必须的文件还没有添加到应用的顶层目录。如果你运行下面的命令，automake 将从GNU工具中拷贝这些文件，然后创建 makefile.in：

	automake  -a  

或

	automake --add-missing  

### 5.9. 测试包

现在，配置脚本已经准备好了，可以在任何 GNU 支持系统上创建 Makefile。configure 接受很多命令行参数。运行 ./configure 可以得到一个概述。最重要的参数可能是 --enable-FEATURE ，这里的 FEATURE 有很多选择。对于程序开发而言，经常要用到 --enabl-debug=full 来选择调试。对于用户，--prefix 和 --with-LIBRARY-dir 可以控制很多安装路径。先试一下不用任何参数运行 configure。会在源码的顶层目录产生一个 Makefile ，prefix 设为 /usr/local。只需键入：

	./configure  

你将看到很多 check... 信息，最后结束时会出现在类似下面的信息：

	configure: creating ./config.status   
	config.status: creating makefile   
	config.status: creating config.h   
	config.status: config.h is unchanged   
	config.status: executing depfiles commands   

然后，测试一下新的 makefile：

	make  

应该会没有任何错误的编译应用。注意，不要用 root 用户运行 make install，否则会将程序安装到默认的 prefix 下，那很可能是一个错误的地址。运行如下命令就能将应用安装到默认的 prefix：

	make install  

只要你不是 root，将看到很多错误信息，这是因为没有写的权限。用普通用户运行 make install 的话，对于寻找安装的文件会很有用。

你的 Makefile 支持所有的标准的目标，例如 clean、dist、uninstall 等等。
要得到一个程序的开发版本，需要重新运行 configure，生成一个支持调试的 makefile。

	./configure  --enable-debug=full  

然后运行：

	make  

这样，编译的程序就包含了调试信息。因此，可执行文件也会比之前编译的大很多。现在你就可以在调试器中运行你的程序了。

## 6. 比较复杂的应用

### 6.1. 带有子目录的应用

你需要在顶层目录（myapplication）和每个子目录（src、doc、img）都有一个makefile.am。像myapplication/CVS这样的子目录不算发布包的一部分，必须跳过。相应目录的直接子目录必须像下面这样在 makefile.am 中列出了：

	SUBDIRS = subdir1  subdir2  subdir3  

不需要在SUBDIRS中指定子目录下的目录。每个子目录下的makefile.am只需指定本目录下的直接子目录。

例如，顶层目录是myapplication，CVS子目录用于管理CVS，src是源码，doc是文档，img是图片，myapplication 目录下的顶级 makefile.am 就应该是这样：

	##Process this file with automake to create Makefile.in  
	SUBDIRS = src doc img  

提供一个好主意，为大多数 autoXXX 工具创建和使用的文件使用用一个叫做 admin 的单独目录。这会使顶层目录更具可读性。你要做的就是在AC_INIT后面直接添加：

	AC_CONFIG_AUX_DIR(admin)  

然后在手动创建一个 admin 目录，它就可以被 automake 使用了。

	mkdir admin  

源文件通常被列在 myapplication\_SOURCES 列表。但是，这次的源文件在 src 目录下，所以要把它们列在 myapplication/src/makefile.am 文件中。二进制文件列表 bin\_PROGRAMS 也在这个文件中指定。如下：

	##Process this file with automake to create Makefile.in  
	bin_PROGRAMS = myapplication  
	myapplication_SOURCES = main.c  

对于其他的非源代码文件，如果想将它们包含在发布包中，就必须作为 EXTRA\_DIST 文件列出。如果 doc 目录中包含一个 index.html 文件，你必须将它添加到 myapplication/doc/makefile.am 文件的 EXTRA\_DIST 列表中：

	##Process this file with automake to create Makefile.in  
	EXTRA_DIST = index.html page1.html  

下面是 myapplication/img 目录下的 makefile.am 文件：

	##Process this file with automake to create Makefile.in  
	EXTRA_DIST = image1.png image2.bmp  

运行 autoscan，并按照3.3节描述的那样编辑 configure.scan 文件。在文件末尾的 AC\_CONFIG\_FILES 宏中为每个要包含在发布包的子目录列一个 makefile 文件。在顶层目录（myapplication）下运行：

	aclocal  
	autoconf  
	autoheader  
	automake -a  

那么，automake 将为每个 makefile.in 创建一个 makefile.am。

### 6.2. 库的应用

####6.2.1. 静态库

静态库的构建很像应用，可是，目标要用 \_LIBRARIES 变量指定。mylib 库可以用下面的这些方式指定：

* 如果它要被安装在全局库目录下（默认：/usr/lib）：

		lib_LIBRARIES = mylib.a  

* 如果它要被安装在应用的lib目录下（默认：/usr/myapplication/lib）：

		pkglib_LIBRARIES = mylib.a  


* 如果它只是在构建的过程中使用，不需要安装：

		[python] view plaincopy
		noinst_LIBRARIES = mylib.a  

####6.2.2. 共享库

构建共享库是一个比较复杂的问题，你最好参考一下 automake 和 libtool 的文档。这里介绍一种简单情况下工作方式：对于用 libtool 构建的库使用 \_LTLIBRARIES 宏。库的名字要以 lib 开头并以 .la 结尾（例如libmylib.la）。使用 \_SOURCES宏 时，la 前面的点(.)必须用下划线(\_)代替。对于要安装到 lib 目录下的 mylib 库来说，它的宏可以这样写：

	lib_LTLIBRARIES = libmylib.la  
	libmylib_la_SOURCES = mylib.c  

在 configure.ac 文件中的 AC\_PROG\_CC 后面添加 AC\_PROG_LIBTOOL 宏。这样的话，autoconf 就会为 configure 脚本增加 libtool 支持。

运行 automake 之前，先运行 libtoolize，会添加一些 automake 所需的文件。

## 7. 参考文献

1. Gary Vaughan, Ben Elliston, Tom Tromey, Ian Taylor: “GNU Autoconf, Automake and Libtool”, New Riders Publishing, 2000, also available online at <http://www.gnu.org>
2. GNU Automake:<http://www.gnu.org/software/automake/manual/automake.html>
3. GNU Autoconf:<http://www.gnu.org/software/autoconf/manual/autoconf-2.57/autoconf.html>
4. Libtool
5. The GNU Coding Standards:http://www.gnu.org/prep/standards/standards.html>
