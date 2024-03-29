---
title: GBK点阵显示字库的制作和使用
date: 2011-06-12T08:00:00+08:00
draft: false
toc:
comments: true
---


GBK编码共收录汉字21003个、符号883个，并提供1894个造字码位，简、繁体字融于一库。以两个字节表示一个汉字，编码范围是0x8140~0xfefe，兼容GB2318，并覆盖了unicode中的所有汉字。Win7记事本默认以GBK保存汉字。

关于GBK的详细信息：<http://baike.baidu.com/view/25421.htm>
 
开发环境:

Win7、Eclipse、MinGW
 
## 1.生成GBK全字符文件

运行下面这段代码，生成GBK全字符文件gbk.txt,编码范围0x8140~0xfefe。

	#include <stdio.h>
	#include <stdlib.h>
	
	int main(void)
	{
		FILE *fp=0;
		char ch=0;
		unsigned short int start=0x8140;
		unsigned char part1=0;
		unsigned char part2=0;
	
		fp=fopen("gbk.txt","wb");
		if(fp==NULL)
		{
			perror("Cann't open gbk.txt");
			return -1;
		}
		else
			printf("Creat file gbk.txt/n");
		while(start < 0xfeff)
		{
			part1=start>>8;
			part2=start;
			fputc(part1,fp);
			fputc(part2,fp);
			start++;
		}
		fclose(fp);
		printf("success!");
	
		return 0;
	}

运行后，用记事本打开gbk.txt文件，可以看到其中的字符。

## 2.生成字模二进制文件

用“牧码字模”软件打开gbk.txt文件，选择字体为宋体，字重为1，点阵大小16*16，对齐方式为左下，取模方式为“纵向取模、高位在下”。输出格式选择bin。然后点击输出，会生成一个temp.bin文件，改名为gbk.bin。

gbk.bin文件就是GBK编码字符的点阵字库文件，每32个字节可以绘制一个字符，例如第一个字符‘丂’的显示如下：

![](./pics_1.JPG)

取模的数据为：

0x02, 0x02, 0x02, 0xc2, 0xb2, 0x8e, 0x82, 0x82, 0x82, 0x82, 0x82, 0x82, 0x02, 0x02, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x80, 0x40, 0x3f, 0x00, 0x00, 0x00, 0x00, 
 
## 3.使用字库文件

gbk.bin文件中按GBK编码的大小排列，每32个字节可以显示一个字符，假设一个字符的GBK编码为NUM，那么它的点阵数据第一个字节的位置就是：

（NUM-0x8240）*32

从这个字节开始，读取32个字节，将其按按照取模方式显示即可。

例如：用Linux的终端模拟点阵屏幕，每个字符位置就是一个点，程序如下：

	#include <stdio.h>
	#include <unistd.h>
	#include <curses.h>
	
	#define START 0x8140
	#define DATANUM 0x20
	
	int displaychar(FILE *fp,unsigned short int dispch,char fillch,char start_x,char start_y);
	
	int main(void)
	{
		FILE * fp=0;
		unsigned short int testch = 0xb0ae;  //汉字'爱‘的gbk码
	
		fp = fopen("gbk.bin","rb");
	
		initscr();
	
		displaychar(fp,testch,'*',0,0);
	
		refresh();
	
		while(1);
		endwin();
		fclose(fp);
		return 0;
	}
	
	/*
	 * fp指向点阵字库二进制文件
	 * 以点阵方式显示一个GBK字符
	 * dispch是要显示的字符，fillch是填充点阵的字符
	 * start_x,start_y是显示的起始坐标
	 */
	int displaychar(FILE *fp,unsigned short int dispch,char fillch,char start_x,char start_y)
	{
		char x=start_x;
		char y=start_y;
		unsigned int location=(dispch-START)*DATANUM;
	
		int i=0;
		int j=0;
		char buf=0;
	
		fseek(fp,location,SEEK_SET);
	
		for(i=0;i<DATANUM;i++)
		{
			buf=fgetc(fp);
	
			//显示一个字节
			for(j=0;j<8;j++)
			{
				move(y+j,x);
				if( buf & (0x01<<j) )
				{
					addch(fillch);
				}
			}
	
			if(x == (start_x+15))
			{
				x=start_x;
				y=start_y+8;
			}
			else
				x++;
		}
		return 0;
	
	}

显示效果如下：

![](./pics_2.JPG)

## 下载：

字库文件：<http://download.csdn.net/source/3359198>
字模提取软件：<http://download.csdn.net/source/3358791>
