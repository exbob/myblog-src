---
title: Appweb 学习笔记
date: 2017-11-24T08:00:00+08:00
draft: false
toc:
comments: true
---



## 1. 概述

Appweb 是一个快速、高效、安全的开源嵌入式 web server ，同时包含了 ESP web 框架和一系列扩展支持，可以极大的缩短开放时间，官网：<https://embedthis.com/> ，包含如下组件：

* HTTP web server 程序和库
* HTTP client 程序和库
* 管理和监视进程
* ESP web 框架
* 可选的 CGI、Ejscript、ESP 和 PHP 模块
* SSL/TLS 支持包
* 文档和源码

![](./pics/2017-11-24_1.jpg)

特性：

* 快速开发。Appweb 提供最简单、最低消耗的开发 web 应用方法，它包含了嵌入式 web 应用开发所需的全部特性，极大的缩短了开发时间。
* 最小的资源需求。Appweb 非常简洁和快速，只需要极小的系统资源，最小只需 2MB 的存储空间，运行时最少只需 1MB 内存。
* 可定制的开发环境。Appweb 高度模块化，你可以只选择所需的特性，并且支持运行时模块加载和编译时控制。
* 安全可靠。支持 SSL/TLS，提供最基本的验证，沙盒限制，访问和错误日志。
* 性能。事件驱动的多线程核心提供了最快的响应，。
* 标准化。Appweb 支持 HTTP/1.0 、HTTP/1.1 、CGI/1.1 、SSL RFC 2246 、HTTP RFC 2617 。
* 可移植。Appweb 支持 Linux 、Windows 、Mac OSX ，支持 ARM 、MIPS 、i386/X86/X86_64 、PowerPC 等。

## 2. 安装

Appweb 以源码形式在 github 上发布：<https://github.com/embedthis/appweb> ，支持的运行环境：

* Linux — Linux 2.6 with GNU C/C++
* Windows — Microsoft Windows 7 with Visual Studio 2010 or later
* Mac OS X — Mac OS X 10.8 (Mountain Lion) or later

下载后解压，在源码目录下执行 make ，编译完成后生成的文件都在 build 目录下:

    ~/appweb-7.0.1 $ cd build/linux-x64-default/bin
    ~/appweb-7.0.1/build/linux-x64-default/bin $ ls
    appman           ca.key           libappweb.dylib  libmpr-version.a self.crt
    appweb           ec.crt           libesp.dylib     libmpr.dylib     self.key
    appweb-esp       ec.key           libhttp.dylib    libpcre.dylib    test.crt
    authpass         esp-compile.json libmbedtls.a     makerom          test.key
    ca.crt           http             libmpr-mbedtls.a roots.crt        vcvars.bat

然后执行 `make install` 安装到本地，安装时执行的脚本是 projects/appweb-linux-default.mk ，二进制文件默认都安装在 /usr/local/lib/appweb/ 目录下。安装完成后会自动启动 appweb 。如果想要部署到其他系统，可以执行 `make deploy` ，会将所有需要安装的文件都输出到 linux-x64-default 目录下。当然还可以交叉编译，常用系统的编译文件都在 projects 目录下，可以用 ARCH 设置目标机的 CPU ，用 CC、CFLAGS、DFLAGS、LD 和 LDFLAGS 等参数设置自己的交叉编译工具链。卸载可以用 `make uninstall` 。

## 3. 运行

安装后，会自动在 /etc/init.d 下新建一个 appweb 服务，appweb 会作为系统守护进程自动启动，错误日志位于 /var/log/appweb/ 目录下：

$ ps -ef | grep appweb
root      6501     1  0 13:44 ?        00:00:00 /usr/local/bin/appman --daemon --program /usr/local/bin/appweb --home /etc/appweb --pidfile /var/run/appweb.pid run
nobody    6505  6501  0 13:44 ?        00:00:00 /usr/local/bin/appweb --log stdout:1
 $ sudo lsof -i | grep appweb
appweb    6505 nobody    6u  IPv6 1444273      0t0  TCP *:http (LISTEN)
appweb    6505 nobody    7u  IPv6 1444274      0t0  TCP *:https (LISTEN)

如果发现启动不成功，可以查看一下 /etc/appweb/install.conf 文件，把第一行开头的 -e 去掉，然后重启。启动成后通过浏览器访问主机 IP 即可显示默认页面：

![](./pics/2017-11-24_2.png)
Appweb 提供了一个管理工具 appman ，它可以将 appweb 作为一个守护进程启动，还可以管理 appweb 的运行。appweb 的语法是 `appweb  [option]` ，可用的选项有：

* --config filename，指定配置文件替代默认的 appweb.conf.
* --chroot directory ，改变 Appweb 运行的系统根目录，导致 Appweb 无法访问该目录之外的其他文件。
* --debugger，启动 debug.
* --log logSpec ，指定 log 文件。此选项会覆盖配置文件中的 ErrorLog ，logSpec 的语法是 logName[:logLevel][.maxSize] 。当 log 文件的大小超过 maxSize 时，会将 log 文件备份为 logName.old ，再新建一个 logName 。logLevel 是一个 0~9 的数字，0 表示最少的 log 信息。该选项可以缩写为 -l 。
* --home directory ，指定服务器的根目录，该目录包含 Appweb 的配置文件。
* --name uniqueName ，设置程序名称，当同时运行多个 appweb 实例时，可以为当前程序指定唯一名称。
* --threads ，设置线程号。
* --verbose ，--log stderr:2 的缩写，可以进一步缩写为 -v 。
* --version ，显示 appweb 版本。

如果启动 appweb 时指定了 IP 和端口，就不会去读取默认的 appweb.conf 文件，语法是：

    appweb  [IP]:[PORT]  [documents]

如果没有指定端口，默认会监听 80 端口。如果没有指定 IP，默认会监听所有 IP 。documents 用于指定 web 页面的目录。如果没有指定配置文件，appweb 会使用一个默认的最简配置。

## 4. 配置

appweb 的配置文件管理着监听的 IP 和端口，要加载的模块，Web 页面的位置，如何记录日志等。置顶的配置文件默认叫做 appweb.conf，允许用 include 语句导入子配置文件。配置文件中每一行设置一个选项，用井号 # 表示注释。一份配置文件是由多种选项构成的：

* 全局选项
* Route 选项块
* Virtual Host 选项块
* 条件选项块

没有被任何选项块包含的选项就是全局选项，定义一些 appweb 的全局属性。Route 选项块用 <Route "URL"></Route> 标签标识，用于设置特定的 URL，例如：

    <Route "/myapp/">
        SetHandler esp
    </Route>

它表示以 "/myapp/" 开头的 URL 请求转给 esp 处理。

Virtual Host 选项块用 <VirtualHost></VirtualHost> 标签标识，用于定义虚拟子服务，将虚拟子服务的内容与 IP 或者域名绑定，例如：

    <VirtualHost>
        ServerName www.mycorp.org
        Documents /var/www/mycorp
        ...
    </VirtualHost>

条件选项块用 <if SYMBOL></if> 标签标识，读取配置文件时会判断 SYMBOL 的值，如果为 true 就会加载这些选项，否则就会忽略，例如：

    <if FILE_MODULE>
        LoadModule fileHandler mod_file
    </if>

appweb 支持两种条件选项块：

* BLD_DEBUG ：如果 appweb 使能了 DEBUG ，该符号为 true
* NAME_MODULE ：如果使能了 NAME_MODULE 模块，该符号为 true 

整个配置文件是从头到尾被读取的，所有要注意各选项的排列顺序。说有选项的列表：<https://embedthis.com/appweb/doc/users/directives.html>

## 5. 开发

Appweb 提供了三种应用开发方式：

1. 开发额外的模块，由 appweb 程序加载
2. 用 ESP web 框架开发一个应用，有 appweb 程序加载
3. 在自己的程序中使用 Appweb 的 HTTP library 开发应用

Appweb 包含了四个可加载的模块：CGI 、ESP 、PHP 和 SSL 。我们可以开发自己的模块，扩展功能，appweb 支持动态加载和静态链接两种方式调用模块，使用 C 语言接口。新建一个模块时，首先要新建一个初始化函数，格式如下：

    maNameInit(Http *http, MprModule *module)

Name 可以替换成模块的名字，第一个字母必须大写，例如 `maCgiHandlerInit` 可以做为 CgiHandler 模块的初始化接口，appweb 加载  CgiHandler  的时候首先调用这个函数。

新建自己的 Handler ，处理 Http 请求。Handler 通常包含在模块里，然后在配置文件里设置，用 LoadModule 命令加载模块，每一个  handler 对应一种 Http 请求，在 Route 选项块里用  AddHandler 或者 SetHandler 命令设置，例如：

    LoadModule myHandler mod_my
    <Route /my/>
        SetHandler myHandler
    </Route>
