---
title: 建立一个定制内核
date: 2012-04-01T08:00:00+08:00
draft: false
toc:
comments: true
---


原文：

Building a custom kernel

<https://fedoraproject.org/wiki/Building_a_custom_kernel>

Translated By Bob

2012-3-31

Email：<gexbob@gmail.com>

Blog：<http://shaocheng.li> 

***

## 1. 从源码RPM包建立一个内核

>注意：下面的说明只对 Fedora12 和之后版本有效

这份文档为那些想要重新建立内核的高级用户提供说明。但是，重新建立的内核无法得到 Fedora 内核团队的支持。但是，您是高级用户，您可以自己处理，对吗？无论如何，高级用户建立定制内核的原因有如下几项：

* 测试他们编写的或从其他地方得到的补丁。
* 重新配置已经存在的内核。
* 学习内核或内核开发。

这些说明也可以用于简单的准备内核源码树。

<!-- more -->

开始之前，确认系统已经安装了必要的软件包：

* rpmdevtools
* yum-utils

yum-utils 是一个默认的包。用如下命令安装：

	su -c 'yum install rpmdevtools yum-utils'

如果您要用 make xconfig，安装如下软件是必要的：

* qt3-devle
* libXi-devel
* gcc-c++

对于 Fedora 15，用如下命令：

	su -c 'yum install qt3-devel libXi-devel'

### 1.1. 获得源码

>不要用 root 建立软件包,用 root 建立软件包是很危险且没有必要的，即使对于内核。下面的指令允许任何普通用户从源码包开始建立和安装内核.

1.在您的用户主目录下准备一个建立RPM包的环境，运行如下命令：

    rpmdev-setuptree

这个命令新建了几个不同的目录 ${HOME}/rpmbuild/SOURCES， ${HOME}/rpmbuild/SPECS和${HOME}/rpmbuild/BUILD 。${HOME} 是您的用户主目录。

2.下载 kernel-&lt;version>.src.rpm 文件。用--enablerepo选项使能适当的源码库。（yumdownloader --enablerepo=repo_to_enable --source kernel)

    yumdownloader --source kernel

3.用 yum-builddep 命令为内核源码安装编译依赖。

    su -c 'yum-builddep kernel-<version>.src.rpm'

4.用如下命令安装 kernel-&lt;version>.src.rpm

    rpm -Uvh kernel-<version>.src.rpm

这个命令把RPM目录写入了 ${HOME}/repbuild/SOURCES和${HOME}/rpmbuild/SPECS ，${HOME} 是您的用户主目录。可以忽略像下面这样的信息：

    warning: user kojibuilder does not exist - using root
    warning: group kojibuilder does not exist - using root

>空间需求:完全的内部编译过程需要若干 GB 的额外空间。

### 1.2. 准备内核源码树

这一步扩大为整个内核源码文件。这对于查看代码、编辑代码和生成补丁是必需的。

用如下命令准备内核源码树：

	cd ~/rpmbuild/SPECS
	rpmbuild -bp --target=$(uname -m) kernel.spec

现在，内核源码树就位于 ~/rpmbuild/BUILD/kernel-&lt;version>/linux-&lt;version>.&lt;arch> 目录。

### 1.3. 复制源码树和生成一个补丁

这一步是为了对内核源码使用一个补丁。如果不需要这个补丁，直接跳到“配置内核选项”。

>高级用户：
>有些工具，例如“quilt”，允许您避免复制源码树。对应高级用户，这样的工具可以使您在下面的步骤中节省很多时间。

复制源码树是为了保留修改前的原始代码。

	export arch=x86_64 # replace x86_64 with your arch
	export ver=3.1 # replace 3.1 with your kernel version
	export fedver=fc16 # replace fc16 with your fedora version 
	cp -r ~/rpmbuild/BUILD/kernel-$ver.$fedver/linux-$ver.$arch ~/rpmbuild/BUILD/kernel-$ver.$fedver.orig
	cp -al ~/rpmbuild/BUILD/kernel-$ver.$fedver.orig ~/rpmbuild/BUILD/kernel-$ver.$fedver.new

>第二个 cp 命令在 .orig 和 .new 树之间建立了硬连接，这样可以使 diff 运行的更快。大部分文本编辑者都知道怎样正确的破坏硬连接来避免问题。

在 FC14 上使用 vim 时，它会把上面的硬连接当做硬连接来处理，从而导致上面的技术失败。有必要将原始代码完全复制到 .new 目录。但是这样将使用双倍的空间。

直接更改 .new 源码树中的代码，或者复制到一个副本文件。这个文件可以来自于一个要求测试的开发者，上游内核源码，或者另一个发行版本。

修改 .new 源码树之后，生成一个补丁。要生成一个补丁，用下面命令对整个 .new 和 .orig 源码树运行 diff 。

	cd ~/rpmbuild/BUILD
	diff -uNrp kernel-$ver.$fedver.orig kernel-$ver.$fedver.new > ../SOURCES/linux-$ver.$fedver-mynewpatch.patch

用新补丁的名字替换 'linux-$ver.$fedver-mynewpatch.patch' 。在 FC14 上必须把前面的补丁名字复制到 ~/rpmbuild/SOURCES 中的 linux-$ver.$fedver-mynewpatch.patch ，以便 rpmbuild 找到它。

>更多关于补丁的信息请看 diff(1) 和 patch(1) 的 man 手册

### 1.4. 配置内核选项

这一步是为了修改内核的选项。这一步是可选的。如果没有需要修改的配置，可以跳到“准备建立文件”。

>小变化:
>如果您只是想要做一点小的修改，可以在config-local文件中根据需要直接设置选项。这样会找到并覆盖其余的config-\*文件，避免很多不必要的工作。如果您使用config-local就可以跳过下面的步骤。*

1.改变内核源码树目录：

    cd ~/rpmbuild/BUILD/kernel-$ver.$fedver/linux-$ver.$arch/
	
如果您只是对默认的 fedora 内核做小的修改，跳到第四步，从两个配置工作中选择一个，将这些修改编辑到默认的配置文件。

2.从 ~/rpmbuild/BUILD/kernel-$ver.$fedver/linux-$ver.$arch/configs 选择所需的配置文件。复制所需的 config 文件到 ~/rpmbuild/BUILD/kernel-$ver.$fedver/linux-$ver.$arch/.config:

    cp configs/<desired-config-file> .config

3.运行下面命令：

    make oldconfig

4.运行下面命令，在文本界面上选择并保持所需的内核选项

    make menuconfig

运行图形界面的话用这个命令：

    make xconfig

5.在顶层 config 文件中添加一行，该文件包含了内核支持的硬件架构（uname -i的输出）。这一行以 # 开头。例如，x86_64 设备应该在顶层 config 文件中添加下面这行：

    # x86_64

6.复制 config 文件到 ~/rpmbuild/SOURCES/:

    cp .config ~/rpmbuild/SOURCES/config-`uname -m`-generic

*32-bit x86 内核*

*32-bit PAE 内核使用 config-i686-PAE 配置文件。如果您正在建立一个 PAE 内核，需要复制您的 config 文件到 ~/rpmbuild/SOURCES/:*

	cp .config ~/rpmbuild/SOURCES/config-i686-PAE

*如果您正在建立一个非 PAE 内核，需要复制您的 config 文件到：*

	cp .config ~/rpmbuild/SOURCES/config-x86-32-generic

*再次鼓励使用 config-local，除非您正在修改大量的配置。*

### 1.5. 准备建立文件

这一步将对 kernel.spec 文件做必要的修改。只是建立定制内核所需的。

1.进入~/rpmbuild/SPECS目录：

    cd ~/rpmbuild/SPECS

2.用编辑器打开kernel.spec文件。

3.为内核起一个唯一的名字。这对于确保定制内核不与其他内核混淆是很重要的。通过修改 ‘buildid’ 一行，为内核名字添加一个唯一的字符串。可以把 “.local” 改为您的名字缩写，一个 bug 号，日期，或其它任何唯一的字符串。

修改这一行：

    #% define buildid .local
	
改为（注意，# 号和额外的空格都被删除了）：

    %define buildid .<custom_text>

4.如果您生成了一个补丁，最后把它添加到 kernel.spec 文件中所有已存在的补丁的后面，并且添加详细的注释。

    # cputime accounting is broken, revert to 2.6.22 version
    Patch2220: linux-2.6-cputime-fix-accounting.patch
    Patch9999: linux-2.6-samfw-test.patch

然后，需要将补丁应用到spec文件的application段，放在所有已存在的补丁应用的后面，并添加详细的注释。

    ApplyPatch linux-2.6-cputime-fix-accounting.patch
    ApplyPatch linux-2.6-samfw-test.patch

### 1.6. 建立新内核

这一步实际是要生成一个内核 RPM 文件。只是建立定制内核所需的。对于 Fedora10 或 11 ，大多数场合下，这是建立内核（包括固件）的最简单的方法（看最后一部分）。

用 rpmbuild 工具建立新内核：

1.建立所有内核配置：

    rpmbuild -bb --target='uname -m' kernel.spec

2.关闭指定的内核配置（为了更快的建立）：

    rpmbuild -bb --without <option> --target='uname -m' kernel.spec

其中 “option” 的有效值包括 xen、smp、up、pae、kdump、debug 和 debuginfo 。指定 --without debug 会剔除内核中的调试代码，指定 --without debuginfo 会禁止建立 kernel-debuginfo 包。

3.只建立一个特定的内核：

    rpmbuild -bb --with <option> --target='uname -m' kernel-spec

“option” 的有效值包括 xenonly、smponly 和 beseonly。

4.例如，只建立 kernel 和 kernel-devel 包的命令是：

    rpmbuild -bb --with baseonly --without debuginfo --target='uname -m' kernel.spec

5.建立时包含固件，用如下命令：

    rpmbuild -bb --with baseonly --with firmware --without debuginfo --target=`uname -m` kernel.spec

建立的过程需要很长时间。会在屏幕上打印大量的信息。这些信息可以被忽略，除非建立过程因为一个error而停止。如果成功完成建立过程，一个新的内核包会出现在~/rpmbuild/RPMS目录。

*应该添加一个故障排除的部分。*

####1.6.1. 以下是通用教程

大部分关于 Linux 内核开发的教程，例子和教科书都假设内核源码被安装在/usr/src/linux目录下。如果您想下面这样做一个符号链接，您就可以使用那些Fedora包的学习材料了。安装合适的内核源码，然后运行下面命令：

	su -c 'ln -s /usr/src/kernels/<version>.<release>-<arch> /usr/src/linux'

根据提示输入 root 密码。

### 1.7. 安装新内核

这一步将把新内核安装到运行中的系统。

要安装新内核，用 rpm -ivh 命令，不要带 -U 或 --upgrade 选项：

	su -c "rpm -ivh --force $HOME/rpmbuild/RPMS/<arch>/kernel-<version>.<arch>.rpm"

如果您根据需要修改了内核的名字，您的固件和内核头文件将无法匹配。最简单的解决方法是用前面描述的方法建立新的固件，然后：

	su -c "rpm -ivh $HOME/rpmbuild/RPMS/<arch>/kernel-<version>.<arch>.rpm \
	$HOME/rpmbuild/RPMS/<arch>/kernel-firmware-<version>.<arch>.rpm \
	$HOME/rpmbuild/RPMS/<arch>/kernel-headers-<version>.<arch>.rpm \
	$HOME/rpmbuild/RPMS/<arch>/kernel-devel-<version>.<arch>.rpm"

这些命令会把您的内核安装到 /boot目录，创建一个新的 initramfs，并且自动把新内核添加到 grub 的 “menu.list” 中。然后，您就可以重启并使用您的新内核了。

## 2. 只建立内核模块（kernel modules）

*本段需要更新和充实*

这一段针对那些只想在内核模块上工作的用户，他们并不想建立一个完整的内核。只要就没必要下载和重新建立整个内核。要为当前运行的内核建立一个模块，只需要相匹配的 kernel-devel 包。运行下面命令安装 kernel-devel 包：

	su -c 'yum install kernel-devel'

如果您用的是 PAE 内核，可能要安装 “kernel-PAE-devel” 。

只要您安装了相应版本的 kernel 或 kernel-devel 包，就可以建立任何内核版本。本段的其余部分假设您正在使用当前运行的内核。如果不是，用指定的版本号代替 ‘uname -r’。

kernel-doc 包包含了官方的 Kbuild 文档。在 Documentation/kbuild 目录下查看，尤其是 modules.txt 文件。

一个简单的例子，从 foo.c 建立 foo.ko 模块，在 foo.c 所在的目录下创建下面这样的 Makefile：

	obj-m := foo.o
	KDIR  := /lib/modules/$(shell uname -r)/build
	PWD   := $(shell pwd)
	default:
	[TAB]$(MAKE) -C $(KDIR) M=$(PWD) modules

[TAB] 表示 makefile 中包含命令的一行必须以一个 tab 字符开头。

然后，执行 make 命令建立 foo.ko 模块。

上面是是通过一个本地 Makefile 包装调用 kbuild。通常您可以简单一点，想下面这样来建立那些目标。

	# make -C /lib/modules/`uname -r`/build M=`pwd` modules
	# make -C /lib/modules/`uname -r`/build M=`pwd` clean
	# make -C /lib/modules/`uname -r`/build M=`pwd` modules_install
