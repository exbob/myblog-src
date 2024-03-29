---
title: 怎样设置Framebuffer
date: 2011-12-14T08:00:00+08:00
draft: false
toc:
comments: true
---


环境：Redhat9.02

启动级别：3

## 1. 配置内核：

首先要再编译内核是选中如下几项：

	Code maturity level options --->[*] Prompt for development and/or incomplete code/drivers  
	Processor type and features --->[*] MTRR (Memory Type Range Register) support  
	Block Devices ->[*] Loopback device support
	                [*] RAM disk support
	                    (4096) Default RAM disk size
	                [*] Initial RAM disk (initrd) support  
	Console Drivers ->[*] VGA text console
	                  [*] Videomode selection support  
	Console Drivers -> Frame-buffer support ->[*] Support for frame buffer devices
	                                          [*] VESA VGA graphics console
	                                          [*] Use splash screen instead of boot logo   

## 2. 配置Bootloader

* Grub
	修改/etc/grub.conf，在kernel项的最后添加vga参数和fb，例如：

		kernel  /boot/vmlinuz-2.4.20-8 ro root=LABEL=/  vga=0x311 fb:on  

* LILO

	修改/etc/lilo.conf，添加vga参数，例如：

		vga=0x311  
	
	修改后执行lilo命令，写入bootloader。

vga参数的可选值如下：

![](./pics_1.JPG)

修改后重启系统，会在右上角看到一个Linux的企鹅Logo。
