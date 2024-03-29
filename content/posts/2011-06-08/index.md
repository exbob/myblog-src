---
title: ASCII字符点阵字库的制作和使用
date: 2011-06-08T08:00:00+08:00
draft: false
toc:
comments: true
---


开发环境：

Win7，Eclipse，MinGW
 
#1.生成ASCII字符文件

ASCII编码的可打印字符是0x20~0x7E,先用运行下面这段代码，生成一个包含全部可打印字符的txt文件：

	#include <stdio.h>
	#include <stdlib.h>
	
	int main(int argc,char *argv[])
	{
		FILE * fp;
		unsigned char i = 0;
	
		fp = fopen("ascii.txt","w");
		if(fp == 0)
		{
			perror("open");
			return -1;
		}
		for(i=0x20;i<0x7F;i++)
		{
			fputc(i,fp);
		}
	
		return 0;
	}

运行后，用记事本打开ascii.txt文件，会看到如下文本：

![](./pics_1.JPG)

#2.生成字模数据

使用字模提取V2.1软件，设置字体为宋体、12，纵向取模，字节倒序（即高位在下）。这些设置可以根据实际情况设置。用C51格式生成字模，大小是8*16，每个字符用16个字节表示。如字符A的显示如下：

![](./pics_2.JPG)

取模数据为：

0x00,0x00,0xC0,0x38,0xE0,0x00,0x00,0x00,0x20,0x3C,0x23,0x02,0x02,0x27,0x38,0x20,

然后将所有的字模数据复制到一个文本文件，删除其中的空行，换行，注释等与字模数据无关的内容，并将文件最后的一个逗号改为ASCII字符的句号，得到一个纯字模数据文件ascii_zk.txt
 
#3.将字模数据文件转换为二进制文件

将ascii\_zk.txt文件中的每个字模数据转换为占一个字节的数，将所有的数据填充为一个二进制文件ascii\_zk.bin。这样，按照ASCII码的顺序，ascii\_zk.bin中每16个字节就可以绘制一个字符。文件转换的程序如下：

	#include <stdio.h>
	#include <stdlib.h>
	/*
	 *将一个ascii字符转换为数
	 */
	unsigned char c2x(char ch)
	{
		unsigned char temp=0;
		if(ch>=0x30 && ch<=0x39)
			temp = ch-0x30;
		else if(ch>=0x41 && ch<=0x46)
			temp = 0x0a+(ch-0x41);
		else if(ch>=0x61 && ch<=0x66)
			temp = 0x0a+(ch-0x61);
		else
			temp =0xff;
		return temp;
	}
	//将ascii_zk.txt转换为二进制文件
	int main(void)
	{
		char buffer[5];
		unsigned char ch=0;
	
		int i=0;
	
		FILE *frp=0;
		FILE *fwp=0;
	
		for(i=0; i<5; i++)
			buffer[i] = 0;
	
		frp=fopen("ascii_zk.txt","r");
		fwp=fopen("ascii_zk.bin","w");
	
		while(buffer[4] != 0x2e) //全部数据以句号结尾
		{
			for(i=0; i<5; i++)
				buffer[i]=fgetc(frp);
			ch = c2x(buffer[2]);
			ch = ch*16;
			ch = ch+c2x(buffer[3]);
	
			fputc(ch,fwp);
	
		}
	
		fclose(frp);
		fclose(fwp);
	
		return 0;
	}

字库文件制作完毕。

#4.字库文件ascii_zk.bin的使用

ascii_zk.bin文件从ASCII码的空格（0x20）开始，每16个字节表示一个字符的点阵字模。以字母A为例，它的ASCII码是0x41，那么，它的字模数据的开始位置就是：

（0x41-0x20）*16

从这个位置开始依次读取16个字节，就是字母A的字模数据，将其显示即可。

例：用Linux的终端模拟显示点阵字符，终端屏幕中的每个字符位置就是一个点，程序如下。

	#include <stdio.h>
	#include <unistd.h>
	#include <curses.h>
	
	#define START 0x20
	#define DATANUM 0x10
	
	int displaychar(FILE *fp,char dispch,char fillch,char start_x,char start_y);
	
	int main(void)
	{
		FILE* fp=0;
	
		int i = 0;
		const char * teststring="I love Julia";
	
		fp=fopen("ascii_zk.bin","r");
	
	
		initscr();
	
		for(i=0;(teststring[i]!=0);i++)
		{
			displaychar(fp,teststring[i],'*',0+(i*8),0);
		}
	
		refresh();
	
		while(1);
	
		endwin();
		fclose(fp);
		return 0;
	}
	
	/*
	 * 以点阵方式显示一个ASCII字符
	 * dispch是要显示的字符，fillch是填充点阵的字符
	 * start_x,start_y是显示的起始坐标
	 */
	
	int displaychar(FILE *fp,char dispch,char fillch,char start_x,char start_y)
	{
		int location = ((dispch-START) * DATANUM);
		char x=start_x;
		char y=start_y;
	
		int i=0;
		int j=0;
		char buf=0;
	
		//将文件流指针移到到dispch字符点阵数据的起始位置
		fseek(fp,location,SEEK_SET);
	
		for(i=0;i<DATANUM;i++)
		{
			buf = fgetc(fp);
	
			//显示一个字节
			for(j=0;j<8;j++)
			{
				move(y+j,x);
				if(buf & (0x01<<j))
					addch(fillch);
			}
	
			if(x == (start_x+7))
			{
				x = start_x;
				y = (start_y+8);
			}
			else
			{
				x++;
			}
		}
	
		return 0;
	}

该程序在Fedora12的终端中运行，效果如下：

![](./pics_3.JPG)

#下载：

[ASCII点阵字库文件](http://download.csdn.net/source/3349413)
