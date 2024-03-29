---
title: Linux 系统下编程控制蜂鸣器
date: 2013-01-24T08:00:00+08:00
draft: false
toc:
comments: true
---


## 原理

X86架构的蜂鸣器连接图如下：

![](./pics_1.JPG)

由图可见，蜂鸣器的声调是由定时器8254的计数器2的输出 OUT2 控制的，OUT2 输出一定频率的正弦波就可以驱动蜂鸣器发声。8254 的端口地址是 0x40~0x43 。

<!--more-->

计数器2是否工作由门控信号 GATE2 决定，GATE2 接并口 PB0 位，即 IO 端口 0x61 的 D0 位。OUT2 和 PB1 经过一个与门后连接到蜂鸣器，PB1 是 IO 端口 0x61 的 D1 位。所以只有当 PB0 和 PB1 同时为高，OUT2 的输出才会到达蜂鸣器。

## 编程

在 Linux 下，可以直接在用户空间访问 IO 端口。下面程序将是蜂鸣器发声 2 秒。

	#include <stdio.h>
	#include <unistd.h>
	#include <sys/io.h>
	
	/*
	 * val 为写入计数器的值
	 * delay 为蜂鸣器发声持续的时间，单位是毫秒
	 */
	void beep(unsigned short int val,int delay)
	{
		unsigned char reg_val = 0;
		iopl(3);
	
		outb(0xb6,0x43); //counter 2 , mode 3
		outb(val&0x00ff,0x42);
		outb(val>>8,0x42);
	
		reg_val = inb(0x61);
		outb(reg_val|0x03,0x61);  //PB0和PB1输出高电平
		usleep(1000*delay);
		outb(reg_val&0xfc,0x61);  //PB0和PB1输出低电平
	
		iopl(0);
	
	}
	
	int main()
	{
		beep(500,2000);
		return 0;
	}
