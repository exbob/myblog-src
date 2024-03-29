---
title: 在Fedora7下安装USB无线网卡TL-WN321G
date: 2012-01-17T08:00:00+08:00
draft: false
toc:
comments: true
---


今天是年前最后一天上班，要在 Fedora7 下安装一款 USB 无线网卡—— TP-Link 的 WN321G+，该网卡使用的是 rt73 芯片，属于 Ralink 芯片组，安装过程中遇到了一下问题，最后总算成功了，记录一下。

插上usb网卡，用 lsusb 命令就可以看到设备：

	Bus 004 Drvice 003： ID 148f:2573  Ralink Technology,Corp

fedora7 已经带了 rt73 的驱动，用如下命令即可加载：

	modprobe  rt73usb

可是加载了驱动后，网卡还是不能用，用 iwconfig 命令也没有看到无线网卡，用 dmesg 命令看到一条错误信息：

	Error-connt read  firmware

无法读取固件，原因不明。

无奈只能下载在一个新的驱动，编译安装，驱动名称是：

	rt73-k2wrlz-3.0.3-3

下载地址：
<http://homepages.tu-darmstadt.de/~p_larbig/wlan/rt73-k2wrlz-3.0.3.tar.bz2>

下载后解压，按照README文件的描述进行编译安装：

	tar -xvf rt73-k2wrlz-3.0.3-3.tar.bz2
	cd rt73-k2wrlz-3.0.3-3/Module
	make
	make install
	modprobe rt73  ifname=wlan0

安装成功。

用 iwconfig 可以看到 wlan0 的相关信息，

![](./pics_1.JPG)

在 /etc/sysconfig/network-scripts 目录下添加 ifcfg-wlan0 文件，添加如下内容：

	DEVICE=wlan0
	ONBOOT=yes
	ROOTPROTO=dhcp

保存，退出，用 ifup wlan0 命令启动网卡。

用 iwlist wlan0 scan 可以看到可用的无线路由器。
用 iwconfig wlan0 ap \[mac] 命令连接到可用的无线路由器的MAC地址。

工作完成，开心回家。

**P.S.:**

make 后可能会报 warning：Module file much too big，用 strip 压缩即可：

	strip --strip-debug rt73.ko

原来 2.7M 的驱动文件压缩后只有200KB。

最近发现该驱动不太稳定，经常会连不上无线路由，最终更换为芯片厂商 Ralink 提供的驱动。

下载地址：<http://www.ralinktech.com/en/04_support/support.php?sn=501>

文件名：2011\_0210\_RT73\_Linux\_STA\_Drv1.1.0.5.bz2

安装方法参考Readme文件。

**参考：**

Wireless Setup：<https://wiki.archlinux.org/index.php/Wireless_Setup>

rt73-k2wrlz-3.0.3-3：<http://aur.archlinux.org/packages.php?ID=15377>

Rt2x00 beta driver：<https://wiki.archlinux.org/index.php/Using_the_new_rt2x00_beta_driver>
