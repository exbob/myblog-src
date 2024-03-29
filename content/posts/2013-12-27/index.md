---
title: QNX 的 Telnet 和 FTP 服务
date: 2013-12-27T08:00:00+08:00
draft: false
toc:
comments: true
---


## Telnet

在QNX中，telnet 服务必须用 inetd启动，所以，先确保 /etc/inetd.conf 文件中有一行 ：

	telnet  stream  tcp  nowait  root  /usr/sbin/telnetd    in.telnetd 

且没有被注释。

各自字段的含义：

	<service_name> <socket_type> <proto> <flags> <user> <server_pathname> <args>

其中 `<user>` 为启动服务的用户名，必须为系统中已经存在的用户。

然后执行 inetd & 即可启动telnet服务。

执行 netstat 命令，可以看到 telnet 已经打开：

![](./pics_1.PNG)

如果要开机启动，可以将 /usr/sbin/inetd & 命令添加到 /etc/rc.d/rc.local 文件中。

## FTP

在QNX中，FTP 服务必须用 inetd启动，所以，先确保 /etc/inetd.conf 文件中有一行 ：

	ftp  stream  tcp  nowait  root  /usr/sbin/ftpd    in.ftpd -l

且没有被注释。

各自字段的含义：

	<service_name> <socket_type> <proto> <flags> <user> <server_pathname> <args>

其中 `<user>` 为启动服务器的用户名，必须为系统中已经存在的用户。

然后执行 inetd & 即可启动ftp服务。

执行 netstat 命令，可以看到 ftp 已经打开：

![](./pics_2.PNG)

如果要开机启动，可以将 /usr/sbin/inetd & 命令添加到 /etc/rc.d/rc.local 文件中。

/etc/ftpuser 文件用于控制访问ftpd 的用户。要使root用户登陆，将文件中把禁止root用户使用ftp这项屏蔽掉（root前面加#号）:

![](./pics_3.PNG)

并且，root 用户必须有密码，否则无法通过 ftp 登陆。
