---
title: Linux 命令行下的 3G 模块配置工具 comgt
date: 2015-09-09T08:00:00+08:00
draft: false
toc:
comments: true
---


[comgt帮助文档](http://manpages.ubuntu.com/manpages/natty/man1/comgt.1.html)

comgt 是一个 GPRS/EDGE/3G/HSDPA 和 3G/GPRS 模块配置工具。它更像是一个脚本语言解释器，通过调用内建、或者外部脚本与 GPRS 和 3G 模块通讯。

## 语法

comgt -d device -ehstvVx script

## 参数

* -d device ：指定模块的通讯口，例如 /dev/ttyUSB2 或 /dev/modem
* -e ：打开串口通信的 echo 
* -h ：显示帮助信息
* -s ：在外部脚本执行前，不要运行内建的默认脚本
* -t ：使用备用线路终端
* -v ：运行详细模式，会显示详细的通讯过程
* -V ：显示版本信息
* -x ：将内建和外部脚本中的波特率 115200 改为 57600 

## 内建脚本

* comgt ：运行默认的内建脚本。如果运行 comgt 时没有指定任何脚本，例如 `comgt -d /dev/ttyS1` ,它会依次执行几个内建的脚本 PIN 、reg、sig 。
* comgt help ：列出所有帮助信息。
* comgt info ：列出当前模块的配置。
* comgt sig ：获取信号强度。
* comgt reg ：显示注册状态。
* comgt 3G ：将模块设为 3G only (UMTS/HSDPA) 模式。
* comgt 2G ：将模块设为 2G only (GSM/GPRS/EDGE) 模式。
* comgt 3G2G ：将模块设为 3G preferred (UMTS/HSDPA and GSM/GPRS/EDGE) 模式

## 外部脚本

以 sendmsg.gcom 为例，该脚本实现了发送短信的功能：

    opengt
        set com 115200n81
        set comecho off
        set senddelay 0.02
        waitquiet 0.2 0.2
        flash 0.1
    
    :start
        send "AT+CMGF=1^m"
        get 1 "" $s
        print $s
        send "AT+CSCS=GSM^m"
        get 1 "" $s
        print $s
        send "AT+CSMP=17,168,0,0^m"
        get 1 "" $s
        print $s
        print "Input message:\n"
        input $m
        send "AT+CMGS=+8613824741490^m"
        send  $m+"^Z"
        get 1 "" $s
        print $s
    
    :continue
        exit 0
        
opengt 段用于设置串口的各项参数,之后会一次执行 start 段的命令，这里涉及到几个常用的命令：

* send : 向串口发送字符串。这个字符应该以 `^m` 结尾，表示一个回车符。几个字符串可以用加号连接。有时一个 AT 命令后会等待用户输入，比如 `AT+CMGS` 后会等待输入短信内容，此时继续调用 send 命令即可。`^Z` 表示 Ctrl+Z 组合键。
* input : 等待用户输入，输入的字符串放入变量 $x 中。
* print : 在终端打印一行字符串。
* get : 获取串口返回从字符串。语法是 `get timeout "terminators" $string`

执行该脚本：

    gcom -d /dev/ttyUSB2 -s sendmsg.gcom
