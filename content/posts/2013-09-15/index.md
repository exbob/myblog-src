---
title: QNX 对触摸屏的支持
date: 2013-09-15T08:00:00+08:00
draft: false
toc:
comments: true
---


QNX Neutrino 支持多种触摸屏，可以在官网上查找支持的型号和对应的驱动：

<http://www.qnx.com/developers/hardware_support/>

或者在 Utilities Reference 中查看 `devi-*` 驱动，然后确定所需的参数，启动驱动。例如，启动一个 Dynapro SC4 触摸屏：

	devi-dyna dyna -4 fd -d/dev/ser1 &

使用 devi-dyna 驱动，SC4 协议（-4），串口1（/dev/ser1）。

第一次使用驱动时，会返回一个错误状态，无法获取校准文件。要校准触摸屏，需要在 Photon 下使用 calib 工具。

## calib 

用于校准触摸屏。成功配置触摸屏后（已经创建了设备文件），必须校准。calib 工具的配置文件保存在 /etc/system/config/calib.$hostname 。关于该文件的格式，可以在 “Writing an Input Device Driver” 的 “Calibration file format” 查看. 

校准的步骤是：

1. 启动 Photon. 
2. 运行 calib. 
3. 触摸屏幕上的目标点. 
4. 点击 Press to Complete Calibration 按钮，完成校准. 


### 语法

	calib [options]

### 参数

* -a alg ：指定校准算法。有效算法是 3 和 4 ，默认值是 3 。

* -b val ：指定触摸点的验收方差（范围是 0 - 2000）。使能该参数将会强制检查触摸点。

* -c ：如果已经配置文件 /etc/system/config/calib.$(hostname) 已经存在，就停止运行。

* -d w,h ：触摸屏的宽度和高度。如果不设置该参数，calib 会尝试从硬件获取信息。

* -f file ：校准文件的名称和路径，代替默认的 /etc/system/config/calib.$hostname 。

* -l limit ：校准触摸点的个数，默认值是 15 。

* -o offset ：相对于十字线的偏移，用于调整校验。只能用在四点校验。

* -O ：将触摸屏的起点（0,0）设为右下角。默认为左上角。

* -p x,y ：相对于校验起点的偏移。

* -P ：关闭提示。默认会在屏幕上显示提示信息。

* -s server ：服务器节点或设备名称。

* -S ：使用小触摸目标。默认是大的。

* -t timer ：完成按钮的定时值，默认是 10 。

* -v ：输出详情。

* -x x ：初始化 x 坐标。

* -y y ：初始化 y 坐标。

### 例

校准一个四分子一的标准 640*480 VGA 屏：

	calib -d 320,240

## ELO 触摸屏

Elographics 触摸屏的驱动是 `devi-elo` ，它会在 Photon 上启动一个 Elographics 输入管理器 。

### 语法

	devi-elo [general_opts] 
	         protocol* [protocol_opts]*
	         device* [device_opts]*
	         filter* [filter_opts]*

> 使用 `devi-*` 触摸屏驱动时，需要一个校准文件。用 `calib` 工具产生：
>
>	calib > calib_file.txt
>

### 参数

general_opts：

* -b ：禁止使用 Ctrl-Alt-Shift-Backspace 组合键结束 Photon （默认是允许的）。

* -d device ：设备（默认：/dev/photon 或 $PHOTON ）。

* -G ：启动触摸屏驱动时无需图形驱动。在调试时很有用。

* -g input_group ：输入组（默认是 1 ）。

* -l ：列出内部模块。模块用如下格式显示：
		
		module name | date compiled | revision | class

* -v[v]... ：输出详情，更多的 v 字符导致输出更多的详情。

protocol* [protocol_opts]*：

	smartset [smartset_opts] [fd fd_opts]|[uart uart_opts]

* smartset —— Elographics smartset 协议

	-b baud ：波特率（默认是9600）

	-R ：不要 reset 设备（默认是 reset ）

device* [device_opts]*：

* fd —— 通过 open() 打开一个设备

	-d device ：设备文件名（默认是 /dev/ser1）

	-s ：输入接口是串口

* uart —— 直接访问 8250/16550/16450 UART

	-1 ：COM1

	-2 ：COM2

	-i irq ：串口的 IRQ （默认是 4 ）

	-p ioport ：串口的端口地址（默认是 3f8）

filter* [filter_opts]*：

* abs —— 转换和压缩绝对坐标

	-b ：点击屏幕代表鼠标右键（默认是左键）

	-c ：校准模式；不转换坐标

	-f filename ：校准文件

	-o x,y ：显示区域的起始点（默认是图形区域的起始点）

	-s x,y ：显示区域右下角的坐标（默认是图形区域的宽和高）

	-x ：翻转 x 坐标

	-y ：翻转 y 坐标

### 例

使用 COM1 ，点击屏幕代表鼠标右键：

	devi-elo smartset fd -d/dev/ser1 abs -b
