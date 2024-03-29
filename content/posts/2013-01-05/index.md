---
title: 使用 udev 管理设备
date: 2013-01-05T08:00:00+08:00
draft: false
toc:
comments: true
---



udev 是 linux 2.6 内核提供的一种动态管理设备器，主要功能是管理 /dev 目录下的设备节点，同时也替换了 devfs 和 hotplug 的功能，这意味着它要在添加/删除硬件时处理 /dev 目录以及所有用户空间的行为，包括加载 firmware 时。

udev 依赖于内核提供的 uevent 接口，每次添加或删除设备时，内核都会发送 uevent 向 udev 通知更改。udev 的守护进程是 udevd ，在系统启动时会读取并分析 udev 规则文件提供的所有规则，并保存在内存。 当 udev 接收到内核发出的设备更改事件后，会将设备信息与规则进行匹配，然后执行相应的操作。

linux内核中的设备信息都是通过 sysfs 文件系统导出的，位于 /sys 目录下。

## 1. udevadm

udevadm 是一个 udev 管理工具。可用于监视和控制 udev 的运行时行为、请求内核事件、管理事件队列，以及提供简单的调试机制。

### 1.1 监视正在运行的 udev 守护进程

程序 `udevadm monitor` 用于将驱动程序核心时间和 udev 事件处理的计时可视化。执行 `udevadm monitor` 后，会出现如下内容：

	monitor will print the received events for:
	UDEV - the event which udev sends out after rule processing
	KERNEL - the kernel uevent

之后发生的所有 udev 事件都会显示。例如下面是插入 U 盘后显示的前几行：

	KERNEL[1356423352.040293] add      /devices/pci0000:00/0000:00:11.0/0000:02:03.0/usb1/1-1 (usb)
	KERNEL[1356423352.098881] add      /devices/pci0000:00/0000:00:11.0/0000:02:03.0/usb1/1-1/1-1:1.0 (usb)
	UDEV  [1356423352.181389] add      /devices/pci0000:00/0000:00:11.0/0000:02:03.0/usb1/1-1 (usb)
	KERNEL[1356423352.239535] add      /module/usb_storage (module)
	UDEV  [1356423352.241499] add      /module/usb_storage (module)

每行表示一个事件。第一个字段中，KERNEL 表示这是一个内核产生的事件，UDEV 表示 udev 事件。第二个字段是计时，单位是微秒。第三个字段表示事件的动作，add 表示添加，如果卸载 U 盘会显示 remove 。最后是 sysfs 文件系统中添加或删除的文件和目录。

### 1.2 查询设备信息

`udevadm info` 用于查询 sysfs 文件系统中的设备信息，信息是按照 Linux 设备模型的层次结构显示的，首先是这个设备的路径和信息，然后依次遍历它的父设备。

例如要查询 U 盘 sdb1 的信息，就执行：

	udevadm info -a -p /sys/class/block/sdb1

显示的第一段信息如下：

	looking at device '/devices/pci0000:00/0000:00:11.0/0000:02:03.0/usb1/1-1/1-1:1.0/host5/target5:0:0/5:0:0:0/block/sdd/sdd1':
    KERNEL=="sdd1"
    SUBSYSTEM=="block"
    DRIVER==""
    ATTR{partition}=="1"
    ATTR{start}=="1040128"
    ATTR{size}=="6848768"
    ATTR{alignment_offset}=="0"
    ATTR{stat}=="     143     6874     9334     1493        1        0        1        3        0     1266     1496"
    ATTR{inflight}=="       0        0"

KERNEL 是设备在内核中的名称，SUBSYSTEM 表示它所属的子系统，ATTR{} 表示各种属性。这些字段都会在 udev 规则中 用到。

## 2. udev 规则

udev 规则可以与内核添加到事件本身的属性或者内核导出到 sysfs 的任何信息匹配。规则还可以从外部程序请求其他信息。根据提供的规则匹配每个事件。所有规则都位于 /etc/udev/rules.d 目录下。

规则文件中的每一行至少包含一个关键字值对。有两种类型的关键字，匹配关键字和指派关键字。如果所有匹配关键字与它们的值匹配，则应用此规则并将指派关键字指派给特定的值。匹配规则可以指定设备节点的名称、添加指向该节点的符号链接或者运行作为事件处理一部分的特定程序。如果找不到匹配的规则，则使用默认设备节点名来创建设备节点。udev 手册页中描述了有关规则语法和提供用来与数据匹配或导入数据的关键字的详细信息。

下面这个例子来自 /etc/udev/rules.d/10-automount.rules 。

	KERNEL=="sd[b-z]",SUBSYSTEM=="block",BUS=="usb",SYMLINK+="usb_%k"
	KERNEL=="sd[b-z][1-9]",SUBSYSTEM=="block",BUS=="usb",SYMLINK+="usb_%k"
	
	ACTION=="add",KERNEL=="sd[b-z][1-9]",SUBSYSTEM=="block",BUS=="usb",RUN+="/bin/mkdir -m 777 /media/usb_%k",RUN+="/bin/mount -t auto /dev/usb_%k /media/usb_%k"
	
	ACTION=="remove",KERNEL=="sd[b-z][1-9]",SUBSYSTEM=="block",BUS=="usb",RUN+="/bin/rm -rf /media/usb_%k"

前两条规则由四个键构成：三个匹配键 (KERNEL,SUBSYSTEM,BUS) 和一个赋值键 (SYMLINK)。三个匹配规则搜索设备列表以查找所有的 U 盘。只有完全匹配才能触发执行此规则。在这种情况下，SYMLINK 指派关键字会在 /dev 目录下生产一个的链接，指向默认的设备节点。匹配此特殊设备类型的任何后续规则都不产生任何影响。

后两条规则分别对应插入(add)和拔出(remove) U 盘的事件。RUN 表示事件发生时执行的程序。

所有规则具有一些共同的特征:


* 每个规则由一个或多个以逗号分隔的关键字值对构成。

* 关键字的运算由运算符确定，udev 规则支持多个不同的运算符。

* 每个给定值必须用引号引起来。

* 规则文件的每一行代表一个规则。如果一个规则超过一行，请使用 `\` 合并不同行，就像在壳层语法中一样。

* udev 规则支持与 \*、? 和 \[] 模式匹配的外壳式模式。

* udev 规则支持替换。

### 2.1 在 udev 规则中使用运算符

创建可以从若干不同运算符选择的关键字，具体取决于希望创建的关键字类型。匹配关键字通常仅用于查找匹配或明显不匹配搜索值的值。匹配关键字包含以下运算符之一：

* `==`	比较等于性。如果关键字包含搜索模式，则匹配该模式的所有结果均有效。

* `!=`	比较不等于性。如果关键字包含搜索模式，则匹配该模式的所有结果均有效。

赋值关键字可以使用下面的任何运算符：

* `=`	为关键字指派值。如果关键字以前由一列值构成，关键字将重置，并且仅指派一个值。

* `+=`	为包含一列项的关键字添加一个值。

* `:=`	指派最终值。不允许后面的规则进行任何后续更改。

### 2.2 在 udev 规则中使用替换项

udev 规则支持使用占位符和替换项。请按照在其他任何脚本中的相同方式使用。在 udev 规则中可使用以下替换项：

* **%r、$root**	

	设备目录 /dev（默认）。

* **%p、$devpath**	

	DEVPATH 的值。

* **%k、$kernel**	

	KERNEL 的值或内部设备名称。

* **%n、$number**	

	设备号。

* **%N、$tempnode**	

	设备文件的临时名称。

* **%M、$major**	

	设备的主编号。

* **%m、$minor**	

	设备的次编号。

* **%s{attribute}/$attr{attribute}**	

	sysfs 属性的值（由 attribute 指定）。

* **%E{variable}、$attr{variable}**	

	环境变量的值（由 variable 指定）。

* **%c、$result** 

	PROGRAM 的输出。

* **%%**  

	%字符。

* **$$**  

	$ 字符。

### 2.3 使用 udev 匹配关键字

匹配关键字描述应用 udev 规则之前必须满足的条件。以下匹配关键字可用：

* **ACTION**

	事件操作的名称，如 add 或 remove（添加或删除设备时）。

* **DEVPATH**

	事件设备的设备路径，如 DEVPATH=/bus/pci/drivers/ipw3945，用于搜索与 ipw3945 驱动程序有关的所有事件。

* **KERNEL**

	事件设备的内部（内核）名称。

* **SUBSYSTEM**

	事件设备的子系统，如 SUBSYSTEM=usb（用于与 USB 设备有关的所有事件）。

* **ATTR{filename}**

	事件设备的 sysfs 属性。例如，要匹配 vendor 属性文件名中包含的字符串，可以使用 ATTR{vendor}=="On(sS)tream"。

* **KERNELS**

	让 udev 向上搜索设备路径以查找匹配的设备名称。

* **SUBSYSTEMS**

	让 udev 向上搜索设备路径以查找匹配的设备子系统名称。

* **DRIVERS**

	让 udev 向上搜索设备路径以查找匹配的设备驱动程序名称。

* **ATTRS{filename}**

	让 udev 向上搜索设备路径以查找具有匹配的 sysfs 属性值的设备。

* **ENV{key}**

	环境变量的值，如 ENV{ID_BUS}="ieee1394，用于搜索与该 FireWire 总线 ID 有关的所有事件。

* **PROGRAM**

	让 udev 执行外部程序。程序必须返回退出码零，才能成功。程序的输出（打印到 stdout）可用于 RESULT 关键字。

* **RESULT**

	匹配上次 PROGRAM 调用的输出字符串。在与 PROGRAM 关键字相同的规则中包含该关键字，或在后面的一个中。

### 2.4 使用 udev 指派关键字

与上述匹配键相比，赋值键未描述必须满足的条件。它们将值、名称和操作指派给由 udev 维护的设备节点。

* **NAME**

	将创建的设备节点的名称。在一个规则设置节点名称之后，将对该节点忽略带有 NAME 关键字的其他所有规则。

* **SYMLINK**

	与要创建的节点有关的符号链接名称。多个匹配的规则可添加要使用设备节点创建的符号链接。也可以通过使用空格字符分隔符号链接名称，在一个规则中为一个节点指定多个符号链接。

* **OWNER, GROUP, MODE**

	新设备节点的权限。此处指定的值重写已编译的任何值。

* **ATTR{key}**

	指定要写入事件设备的 sysfs 属性的值。如果使用 == 运算符，也将使用该关键字匹配 sysfs 属性的值。

* **ENV{key}**

	告知 udev 将变量导出到环境。如果使用 == 运算符，也将使用该关键字匹配环境变量。

* **RUN**

	告知 udev 向程序列表添加要为该设备执行的程序。请记住，将此程序限制于很短的任务，以免妨碍此设备的后续事件。

* **LABEL**

	添加 GOTO 可跳至的标签。

* **GOTO**

	告知 udev 跳过一些规则，继续执行具有按 GOTO 关键字引用的标签的规则。

* **IMPORT{type}**

	将变量装载入外部程序输出之类的事件环境中。udev 导入不同类型的若干变量。如果未指定任何类型，udev 将尝试根据文件许可权限的可执行位来自行确定类型。

	* program 告知 udev 执行外部程序并导入其输出。
	* file 告知 udev 导入文本文件。
	* parent 告知 udev 从父设备导入储存的关键字。

* **WAIT_FOR_SYSFS**

	告知 udev 等待要为某个设备创建的指定 sysfs 文件。例如，WAIT\_FOR\_SYSFS="ioerr\_cnt" 通知 udev 等待 ioerr\_cnt 文件创建完成。

* **OPTIONS**

	OPTION 关键字可能有若干值：

	* last_rule 告知 udev 忽略后面的所有规则。
	* ignore_device 告知 udev 完全忽略此事件。
	* ignore_remove 告知 udev 忽略后面针对设备的所有删除事件。
	* all_partitions 告知 udev 为块设备上的所有可用分区创建设备节点。

## 3. udev 使用的文件
* /sys/\*

	Linux 内核提供的虚拟文件系统，用于导出所有当前已知设备。此信息由 udev 用于在 /dev 中创建设备节点

* /dev/\*

	动态创建的设备节点和引导时从 /lib/udev/devices/* 复制的静态内容

* /etc/udev/udev.conf

	主 udev 配置文件。

* /etc/udev/rules.d/\*

	udev 事件匹配规则.

* /lib/udev/devices/\*

	静态 /dev 内容。

* /lib/udev/\*

	从 udev 规则调用的帮助程序。
