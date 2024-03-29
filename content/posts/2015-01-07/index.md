---
title: Lua语言学习笔记
date: 2015-01-07T08:00:00+08:00
draft: false
toc:
comments: true
---


Lua （英语发音：/ˈluːə/）是一种轻量级的脚本语言，可以方便的嵌入到其他语言中，很易学习。它是用C语言编写的。广泛应用于游戏和 web 开发中。据说 Adobe Photoshop Lightroom 中 50% 的代码是有 Lua 写的。我学习这个语言是因为目前的项目要用到 LuCI 。

* Lua 的主页：[http://www.lua.org](http://www.lua.org)
* 中国开发者论坛：[http://www.luaer.cn](http://www.luaer.cn)
* Lua 程序设计：[http://book.luaer.cn](http://book.luaer.cn)
* Lua 在线手册：[http://manual.luaer.cn](http://manual.luaer.cn)
* 酷壳的 Lua 简明教程：[http://coolshell.cn/articles/10739.html](http://coolshell.cn/articles/10739.html)

## 1.Hello World

Mac 平台默认已经安装了 Lua , 直接执行 lua 就可以进入它的 shell , 首先输出一个 Hello World , 语法很像 C , 结尾有没有分号都可以：

	[18:54]~/ ❯ lua
	Lua 5.2.3  Copyright (C) 1994-2013 Lua.org, PUC-Rio
	> print("Hello World")
	Hello World
	> 


也可以写一个脚本文件，直接执行：

	[18:57]Workspace/ ❯ cat test.lua 
	#!/usr/local/bin/lua
	print("Hello World")
	[18:57]Workspace/ ❯ ./test.lua 
	Hello World


## 2.基本语法

### 注释

两个减号是行注释，两个减号加方括号是块注释：

	#!/usr/local/bin/lua
	--行注释
	--[[
	块注释
	--]]
	print("Hello World")


### 数据类型和变量

Lua 支持动态数据类型，定义变量时无需声明类型，几个基本的数据类型有：

* 字符串，用引号包含，单引号和双引号都可以；Lua 还支持 C 语言类型的转义字符，例如 \n 换行，\r 回车
* 实数，Lua 的数只有 double 型，64 bits 浮点数
* 布尔，true 和 false
* 空，Lua 的空类型用 nil 表示，没有声明过的变量就是 nil

![](./pics_1.JPG)

> type 是一个函数，它会返回数据的类型


Lua 中的变量分为全局变量和局部变量，未加说明的都是全局变量，用 local 关键字定义局部变量 ：

	theGlobalVar = 50
	local theLocalVar = "local variable"
	
	
### 表达式

Lua 的表达式由数字，字符串，变量，运算符组成，运算符分为几个类别，和 C 语言很像：

* 数学运算符：+-*/^ (加减乘除幂），- (负号），这些运算符只能用于实数
* 关系运算符：< ，> ，<= ，>= ，== ，还有一个 ~= 表示不等；比较结果返回 true 或 false ；如果两个值的类型不同，那么一定是不等的，nil 之和自己相等；比较字符串时，是按照字母的顺序进行的
* 逻辑运算符：and , or , not ；not 只会返回 true 和 false，除了 false 和 nil ，其他都是 true ，所以 `not nil` 就是 ture。and 和 or 返回的结果不是 true 或 false，而是和操作数有关：`a and b` -- 如果a为false，则返回a，否则返回b；`a or  b` -- 如果a为true，则返回a，否则返回b
* 连接运算符：..(两个点)，用于连接字符串，如果操作符是数字，会连接后转为字符串。

### 控制语句

if 语句

	if conditions then
		then-part
	end;
	
	if conditions then
		then-part
	else
		else-part
	end;
	
	if conditions then
		then-part
	elseif conditions then
		elseif-part
	..       --->多个elseif
	else
		else-part
	end;

while 循环

	while condition do
	    statements;
	end;
	
for 循环

	for var=exp1,exp2,exp3 do
		loop-part
	end
	
exp1 是初始值，exp2 是终止值，exp3是每一步的间隔，如果exp3，默认是1，例如：

![](./pics_2.JPG)

### 函数

函数的定义以 function 关键字开头，以 end 结尾，可以返回多个值。

Lua 有个特别的语法，就是可以一行为多个变量赋值，那么多个返回值就可以依次赋给多个变量。如果值的数量比变量多，多余的会舍弃；如果变量比值多，后面的变量会被赋 nil 。

![](./pics_3.JPG)
