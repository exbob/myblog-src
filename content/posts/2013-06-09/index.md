---
title: QNX下的串口驱动——devc-ser8250
date: 2013-06-09T08:00:00+08:00
draft: false
toc:
comments: true
---


devc-ser8250 是 QNX 下的8250串口驱动，支持8250s, 14450s 和 16550s 。

必须以 root 用户运行该程序。

## 语法：

    devc-ser8250 [[options] 
        [port[^shift][,intr]]]... &

## 选项：

* -b number：初始化波特率，默认是 57600。
* -C size ：canonical buffer 的大小，单位是字节，默认是 256 。
* -c clock[/divisor] ：自定义时钟频率，单位是 Hz ，divisor 是串口。
* -E ：raw 模式（默认）。默认关闭软件流控制。
* -e ：edited 模式。默认使能软件流控制。
* -F ：关闭硬件流控制，默认使能硬件流控制。edited 模式不支持硬件流控制。
* -f ：使能硬件流控制。
* -I number ：中断输入 buffer 的大小，单位是字节，默认是2048 。
* -O number ：中断输出 buffer 的大小，单位是字节，默认是2048 。
* -o opt[,opt...] ：额外选项，用逗号隔开，包括：
    *  nodaemon —— 不要调用 `procmgr_daemon()` 是驱动在后台运行。如果你需要知道设备终止的时间，可以使用这个选项。
    *  priority=prio —— 设置内部脉冲的工作优先级。

* -S|s ：关闭/使能软件流控制。默认：raw 模式时关闭，edited 模式时使能。
* -T number ：使能发送 FIFO 并设置每次 TX 中断发送的字符数：1,4,8 或 14 。默认是 0 （FIFO 关闭）
* -t number ：使能接收 FIFO 并设置字符数为 1,4,8 或 14 。默认是 0 。
* -u number ：在设备名前缀(/dev/ser)附加号码。默认是 1 ；添加设备。
* port ：一个串口的十六进制的 I/O 地址（X86系统）或物理内存地址（PowerPC和MIPS）。
* shift ：设备寄存器的间隔为 2 的幂。例如：

    0 寄存器是 1 byte 间隔
    1 寄存器是 2 byte 间隔
    2 寄存器是 4 byte 间隔
    ...
    n 寄存器是 2^n byte 间隔
    默认 shift 是 0 。
    
* intr ： 该 port 使用的中断。

## 描述：

如果没有指定 I/O 端口，默认为 COM1(3f8,4) 和 COM2(2f8,3) 。
