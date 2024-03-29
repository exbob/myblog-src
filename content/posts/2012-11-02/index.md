---
title: sed 学习笔记
date: 2012-11-02T08:00:00+08:00
draft: false
toc:
comments: true
---


## 一些选项

* -e script ：添加一套命令，可通过该选项添加多个处理命令
* -n ：只打印通过 p 命令匹配到的行
* -i ：将修改结果写入文件
* -f scriptfile ：使用脚本文件

## 常用命令

* ! ：对所选行以为的行进行操作
* p ：打印
* d ：删除
* s ：替换
* g ：行内全局替换
* w ：将行写入文件
* c\ ：用命令后面的文本替换当前的行
* a\ ：在当前行后添加文本

## GNU对正则表达式的扩展

* \n : 产生或匹配一个换行符（ASCII 10）
* \r : 产生或匹配一个回车符（ASCII 13）
* \t : 产生或匹配一个制表符（ASCII 9）
* \v : 产生或匹配一个垂直制表符（ASCII 11）

## 指定地址范围

打印第一行到第十行：
	
	sed -n -e '1,10p' filename

打印最后一行：

	sed -n -e '$p' filename

用正则表达式匹配行，	打印从以 root 开头的行到以 mail 开头的行：

    sed -n -e '/^root/,/^mail/p' filename

## 大小写转换

\U \u ：转换为大写

\L \l ：转换为小写

    sed -e 's/[a-z]/\U&/g' filename
    sed -e 's/[A-Z]/\L&/g' filename

_& 表示前面的模式所匹配到的字符_

## 文本转换

DOS/Windows格式的文本的每一行末尾是一个回车（CR）和一个换行符（LF），而Unix风格的文本只有一个换行符。

Unix转DOS，$ 匹配到每行的末尾，\r 表示回车符，这样就会在每行的末尾前添加一个回车符：

	sed -e 's/$/\r/' filename > filename.txt

DOS转Unix，将行尾前的一个字符（回车）替换为空即可：

	sed -e 's/.$//' filename.txt > filename
