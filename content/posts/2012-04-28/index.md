---
title: 在大项目中使用 Cscope
date: 2012-04-28T08:00:00+08:00
draft: false
toc:
comments: true
---


原文：

Using Cscope on large projects (example: the Linux kernel)

<http://cscope.sourceforge.net/large_projects.html>

Translated by Bob

2012-4-28

Email：<gexbob@gmail.com>

Blog：<http://shaocheng.li> 

***

如果你要涉及一个大的代码库，Cscope 会是一个非常有用的工具. 它可以通过快速、有目的的搜索为你节省很多时间，而不是像 grep 那样随机的对源文件手动搜索(对于大的代码库，grep 需要一段时间才能启动).

在这个教程中，你将学会如何针对一个大项目来设置 Cscope. 我们用到的例子是 Linux 内核源代码, 基本的步骤和其他大项目是一样的, 包括 C++ 和 JAVA 项目.

<!-- more -->

1.获取源代码. 首先要获取源代码. 可以从 http://www.kernel.org 下载内核源代码. 本教程中假设你下载的是 Linux 2.4.18 并且安装在 /home/jru/linux-2.4.18.

注意: 确保你有足够的磁盘空间: 内核压缩包只有 30 MB, 解压后会的源代码是 150 MB , 生成的 Cscope 数据库会占用额外的 20-100+ MB (这取决于你想要数据库包含多少内核代码). 有必要的话，可以把源代码和 Cscope 数据库放在两个不同的磁盘分区 .

2.弄清楚你想要把 Cscope 数据库文件放在哪里. 我假设你会在 /home/jru/cscope 存放数据库和关联文件.

3.生成一个带有浏览文件列表的 cscope.files . 对于某些项目, 你可能想要在 Cscope 数据库中包含项目目录中的所有 C 源文件. 这种情况下可以跳过这一步, 只需在项目的顶层目录上执行 'cscope -R' 来构建你的 Cscope 数据库. 但是如果有些代码你不想包含, 或者你的项目包含 C++ 或 JAVA 源代码 (Cscope 默认只能解析 .c, .h, .y, 或 .l 文件), 就要生成一个 cscope.files 文件, 其中包含了想要 Cscope 扫描的所有文件名 (每个文件名占一行).

你有可能用到绝对路径 (至少在编辑器里使用 Cscope 数据库时需要), 这样就可以在你创建的目录之外使用数据库. 我展示的命令会先进入根目录, 这样就可以用 find 打印出绝对路径.

对于很多项目, find 命令可以这样用:

    cd /  
    find /my/project/dir -name '*.java' >/my/cscope/dir/cscope.files  

对于 Linux 内核, 就有点棘手, 因为我们想要排除文档和脚本目录下的代码, 还有除 Intel x86 外的所有芯片和体系结构的汇编代码(我想你的体系结构是 X86). 另外, 本例中我会排除所有的内核驱动代码 (这些代码超过要解析的代码总量的两倍, 会导致 Cscope 数据库膨胀, 并且包含了很多重复的定义, 通常更难搜素. 如果你对驱动代码感兴趣, 可以省略下面相关的行, 或者修改为只输出你感兴趣的驱动文件):


    LNX=/home/jru/linux-2.4.18  
	cd /       
	find  $LNX                                                                \  
	-path "$LNX/arch/*" ! -path "$LNX/arch/i386*" -prune -o               \  
	-path "$LNX/include/asm-*" ! -path "$LNX/include/asm-i386*" -prune -o \  
	-path "$LNX/tmp*" -prune -o                                           \  
	-path "$LNX/Documentation*" -prune -o                                 \  
	-path "$LNX/scripts*" -prune -o                                       \  
	-path "$LNX/drivers*" -prune -o                                       \  
    -name "*.[chxsS]" -print >/home/jru/cscope/cscope.files  
    
这里用到了 find 命令, 在大项目中，这样做比手动编辑一个文件列表容易多了, 也可以从其他地方复制一个.

4.生成 Cscope 数据库. 到了生成 Cscope 数据库的时候了:

    cd /home/jru/cscope     # the directory with 'cscope.files'  
    cscope -b -q -k  
    
-b 选项告诉 Cscope 只要构建数据库，无需启动 Cscope GUI. -q 会导致一个额外的'inverted index' 文件被创建, 它会使大数据库的搜索更快. 最后, -k 设置 Cscope 为 'kernel' 模式——这样它就不会去 /usr/include 下搜索源文件中包含的头文件 (这是在操作系统或 C 源码库中使用 Cscope 时的主要作用).

在我的 900 MHz Pentium III 系统上 (带一个标准的 IDE 硬盘), 解析这样的 Linux 源码只用了 12 秒, 输出的 3 个文件 (cscope.out, cscope.in.out, 和 cscope.po.out) 总共占用了 25 MB.

5.使用数据库. 如果你喜欢用 vim 或 emacs/xemacs, 我建议你先学习怎样在这些编辑器中使用 Cscope, 这样才能让你在编辑器中轻松的运行搜索. 我们有一份 tutorial for Vim, emacs 用户当然是足够聪明的，可以根据 cscope/contrib/xcscope 目录下的宝贵意见来解决所有问题.

否则, 你可以用独立的基于 curses 的 Cscope GUI 来运行搜索, 然后启动你喜欢的编辑器(无论 $EDITOR 设为什么,或默认是vi) 来打开搜索结果中的行.

如果你用独立的 Cscope 浏览器, 确保这样调用它:

    cscope -d  
    
这样 Cscope 就不会重新生成数据库. 否则你就不得不 Cscope 检测修改过的文件, 在大项目中会花很多时间, 即使没有文件被修改过. 如果偶然没有带任何参数就运行了 'cscope', 也会导致重新创建没有快速索引和内核模式的数据库, 那就要重新运行之前的 cscope 命令了.

6.源码改变时重新生成数据库.
如果项目中有了新文件, 就再运行 'find' 命令来更新 cscope.files (如果正在使用它).

像初始生成数据那样，用同样的方法调用 cscope (并且在相同的目录下) (即, cscope -b -q -k).
 
*Tutorial by Jason Duell*
