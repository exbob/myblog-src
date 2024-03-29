---
title: lsof 命令入门
date: 2016-01-08T08:00:00+08:00
draft: false
toc:
comments: true
---



> 以前只是用 lsof 命令查看某个文件被那些进程打开了，直到看了这篇文章：[An lsof Primer](https://danielmiessler.com/study/lsof/) ，展示了 lsof 强大的一面。网上有很多翻译，找不到原始版本了，我修改了一些地方。

lsof 是系统管理/安全的高级工具（über-tool）。大多数时候，我用它来获取系统中与网络连接相关的信息，但那只是这个强大有小众的命令的第一步。将这个工具称之为 lsof 真是名副其实，因为它是指“列出打开的文件（lists openfiles）”。切记，在 Unix 中一切（包括网络套接字）都是文件。

有趣的是，lsof 也是有着最多开关的 Linux/Unix 命令之一。它有那么多的开关，许多选项支持使用 - 和 + 前缀。

    usage: [-?abhlnNoOPRstUvV] [+|-c c] [+|-d s] [+D D] [+|-f[cgG]]
     [-F [f]] [-g [s]] [-i [i]] [+|-L [l]] [+|-M] [-o [o]]
     [-p s] [+|-r [t]] [-S [t]] [-T [t]] [-u s] [+|-w] [-x [fl]] [--] [names]
     
如你所见，lsof 有着实在是令人惊讶的选项数量。你可以使用它来获得系统上的设备信息，了解指定的用户在指定的地点正在碰什么东西，甚至是一个进程正在使用什么文件或网络连接。

对于我，lsof 替代了 netstat 和 ps 的全部工作。它带来那些工具的所有功能，而且要比那些工具还多得多。那么，让我们来看看它的一些基本能力吧。

## 1. 关键选项

理解一些关于 lsof 工作方式的关键点是很重要的。最重要的是，当你给它传递选项时，默认行为是对结果进行“或”运算。因此，如果你正是用 -i 来拉出一个端口列表，同时又用 -p 来拉出一个进程列表，那么默认情况下你会获得两者的结果。

下面这些需要牢记：

* 默认 : 没有选项时，lsof 列出活跃进程的所有打开文件
* 组合 : 可以将选项组合到一起，如-abc，但要注意哪些选项需要参数
* -a : 结果进行“与”运算（而不是“或”）
* -l : 在输出显示用户 ID 而不是用户名
* -h : 获得帮助信息
* -t : 仅获取进程 ID
* -U : 获取 UNIX 套接字地址
* -F : 格式化输出结果，用于其它命令。可以通过多种方式格式化，如 `-F pcfn`（用于进程 id、命令名、文件描述符、文件名，并以空终止）

## 2. 获取网络信息

正如我所说的，我主要用 lsof 获取关于系统和网络交互的信息。这里提供了关于此信息的一些主题。

### 2.1. 使用 `-i` 显示所有连接

有些人喜欢用 netstat 来获取网络连接，但是我更喜欢使用 lsof 来进行此项工作。获取的信息以很直观的方式呈现，我仅仅只需改变我的语法，就可以通过同样的命令来获取更多信息。

    # lsof -i 
    COMMAND  PID USER   FD   TYPE DEVICE SIZE NODE NAME
    dhcpcd 6061 root 4u IPv4 4510 UDP *:bootpc
    sshd 7703 root 3u IPv6  6499 TCP *:ssh (LISTEN)
    sshd 7892 root 3u IPv6  6757 TCP 10.10.1.5:ssh->192.168.1.5:49901 (ESTABLISHED)

### 2.2. 使用 `-i 6` 仅获取 IPv6 流量

    # lsof -i 6

### 2.3. 仅显示 TCP 连接（同理可获得 UDP 连接）

可以通过在 -i 后提供对应的协议来仅仅显示 TCP 或者 UDP 连接信息。

    # lsof -iTCP
    COMMAND  PID USER   FD   TYPE DEVICE SIZE NODE NAME
    sshd 7703 root 3u IPv6 6499 TCP *:ssh (LISTEN)
    sshd 7892 root 3u IPv6 6757 TCP 10.10.1.5:ssh->192.168.1.5:49901 (ESTABLISHED)

### 2.4. 使用 `-i:port` 来显示与指定端口相关的网络信息

你也可以通过端口搜索，这对于要找出什么阻止了另外一个应用绑定到指定端口实在是太棒了。

    # lsof -i :22
    COMMAND  PID USER   FD   TYPE DEVICE SIZE NODE NAME
    sshd 7703 root 3u  IPv6 6499 TCP *:ssh (LISTEN)
    sshd 7892 root 3u  IPv6 6757 TCP 10.10.1.5:ssh->192.168.1.5:49901 (ESTABLISHED)
    
### 2.5. 使用 `@host` 来显示指定到指定主机的连接

这对于你在检查是否开放连接到网络中或互联网上某个指定主机的连接时十分有用。

    # lsof -i@172.16.12.5
    sshd 7892 root 3u IPv6 6757 TCP 10.10.1.5:ssh->172.16.12.5:49901 (ESTABLISHED)

### 2.6. 使用 `@host:port` 显示基于主机与端口的连接

你也可以组合主机与端口的显示信息。

    # lsof -i@172.16.12.5:22
    sshd 7892 root 3u IPv6 6757 TCP 10.10.1.5:ssh->172.16.12.5:49901 (ESTABLISHED)

### 2.7. 找出监听端口

找出正等候连接的端口。

    # lsof -i -sTCP:LISTEN
    
也可以用 grep 筛选出信。

    # lsof -i | grep -i LISTEN
    iTunes     400 daniel   16u  IPv4 0x4575228  0t0 TCP *:daap (LISTEN)

### 2.8. 找出已建立的连接

你也可以显示任何已经连接的连接。

    # lsof -i -sTCP:ESTABLISHED

也可以通过 grep 筛选。

    # lsof -i | grep -i ESTABLISHED
    firefox-b 169 daniel  49u IPv4 0t0 TCP 1.2.3.3:1863->1.2.3.4:http (ESTABLISHED)

## 3. 用户信息

你也可以获取各种用户的信息，以及它们在系统上正干着的事，包括它们的网络活动、对文件的操作等。

### 3.1. 使用 -u 显示指定用户打开了什么

    # lsof -u daniel
    -- snipped --
    Dock 155 daniel  txt REG   14,2   2798436   823208 /usr/lib/libicucore.A.dylib
    Dock 155 daniel  txt REG   14,2   1580212   823126 /usr/lib/libobjc.A.dylib
    Dock 155 daniel  txt REG   14,2   2934184   823498 /usr/lib/libstdc++.6.0.4.dylib
    Dock 155 daniel  txt REG   14,2    132008   823505 /usr/lib/libgcc_s.1.dylib
    Dock 155 daniel  txt REG   14,2    212160   823214 /usr/lib/libauto.dylib
    -- snipped --
    
### 3.2. 使用 `-u user` 来显示除指定用户以外的其它所有用户所做的事情

    # lsof -u ^daniel
    -- snipped --
    Dock 155 jim  txt REG   14,2   2798436   823208 /usr/lib/libicucore.A.dylib
    Dock 155 jim  txt REG   14,2   1580212   823126 /usr/lib/libobjc.A.dylib
    Dock 155 jim  txt REG   14,2   2934184   823498 /usr/lib/libstdc++.6.0.4.dylib
    Dock 155 jim  txt REG   14,2    132008   823505 /usr/lib/libgcc_s.1.dylib
    Dock 155 jim  txt REG   14,2    212160   823214 /usr/lib/libauto.dylib
    -- snipped --
    
### 3.3. 杀死指定用户所做的一切事情

可以消灭指定用户运行的所有东西，这真不错。

    # kill -9 `lsof -t -u daniel`

## 4. 命令和进程

可以查看指定程序或进程由什么启动，这通常会很有用，而你可以使用lsof通过名称或进程ID过滤来完成这个任务。下面列出了一些选项：

### 4.1. 使用 `-c` 查看指定的命令正在使用的文件和网络连接

    # lsof -c syslog-ng
    COMMAND    PID USER   FD   TYPE     DEVICE    SIZE       NODE NAME
    syslog-ng 7547 root  cwd    DIR    3,3    4096   2 /
    syslog-ng 7547 root  rtd    DIR    3,3    4096   2 /
    syslog-ng 7547 root  txt    REG    3,3  113524  1064970 /usr/sbin/syslog-ng
    -- snipped --
    
### 4.2. 使用 `-p` 查看指定进程ID已打开的内容

    # lsof -p 10075
    -- snipped --
    sshd    10068 root  mem    REG    3,3   34808 850407 /lib/libnss_files-2.4.so
    sshd    10068 root  mem    REG    3,3   34924 850409 /lib/libnss_nis-2.4.so
    sshd    10068 root  mem    REG    3,3   26596 850405 /lib/libnss_compat-2.4.so
    sshd    10068 root  mem    REG    3,3  200152 509940 /usr/lib/libssl.so.0.9.7
    sshd    10068 root  mem    REG    3,3   46216 510014 /usr/lib/liblber-2.3
    sshd    10068 root  mem    REG    3,3   59868 850413 /lib/libresolv-2.4.so
    sshd    10068 root  mem    REG    3,3 1197180 850396 /lib/libc-2.4.so
    sshd    10068 root  mem    REG    3,3   22168 850398 /lib/libcrypt-2.4.so
    sshd    10068 root  mem    REG    3,3   72784 850404 /lib/libnsl-2.4.so
    sshd    10068 root  mem    REG    3,3   70632 850417 /lib/libz.so.1.2.3
    sshd    10068 root  mem    REG    3,3    9992 850416 /lib/libutil-2.4.so
    -- snipped --

### 4.3. 使 `-t` 选项只返回 PID

    # lsof -t -c Mail
    350


## 5. 文件和目录

通过查看指定文件或目录，你可以看到系统上所有正与其交互的资源——包括用户、进程等。

显示与指定目录交互的所有一切

    # lsof /var/log/messages/
    COMMAND    PID USER   FD   TYPE DEVICE   SIZE   NODE NAME
    syslog-ng 7547 root    4w   REG    3,3 217309 834024 /var/log/messages

显示与指定文件交互的所有一切

    # lsof /home/daniel/firewall_whitelist.txt

## 6. 高级用法

与 tcpdump 类似，当你开始组合查询时，它就显示了它强大的功能。

### 6.1. 显示 daniel 连接到 1.1.1.1 所做的一切

    # lsof -u daniel -i @1.1.1.1
    bkdr   1893 daniel 3u  IPv6 3456 TCP 10.10.1.10:1234->1.1.1.1:31337 (ESTABLISHED)

### 6.2. 同时使用 `-t` 和 `-c` 选项以给进程发送 HUP 信号

    # kill -HUP `lsof -t -c sshd`
    
### 6.3. 显示某个端口范围内打开的连接

    # lsof -i @fw.google.com:2150=2180

## 7. 结尾

本入门教程只是管窥了 lsof 功能的一斑，要查看完整参考，运行 man lsof 命令或查看在线版本。希望本文对你有所助益，也随时欢迎你的评论和指正。

lsof手册页：<http://www.netadmintools.com/html/lsof.man.html>
