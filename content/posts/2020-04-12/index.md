---
title: "tcpdump 使用笔记"
date: 2020-04-12T22:25:11+08:00
draft: false
toc: true
comments: true
images:
tags:
  - untagged


---

**tcpdump** 是一个帮助用户捕获、筛选和解析 TCP/IP 协议数据包的命令行工具。

## 1. 基本用法

下面展示了 tcpdump 的常用的选项：

```bash
:~$ tcpdump -nn -s0 -v -i en0  port 80 
```

* -i ：指定需要监听的网卡，可以是物理网卡，也可以是虚拟网卡。途径该网卡的数据包都会被捕获，然后用过滤器的规则进行筛选。如果没有指定，默认会监听本机的所有网卡。
* port ：这是一个过滤器规则，表示只显示使用该端口收发的数据。
* -nn ：默认情况下，tcpdump 会将 ip 和端口号解析为字符串的形式，例如 80 端口会显示为 http 。可以用 `-n` 表示不解析主机名，`-nn` 表示不解析主机名和端口号，这样可以加快速度，也方便查看。
* -s0 ：设置要捕获的数据包的大小，s0 表示不限制大小。
* -v ：表示粗略显示数据包的内容，-vv 可以增加显示数据包的细节。

### 1.1 显示控制

使用 `-A` 选项可以将数据包的内容以 ASCII 字符形式显示，方便阅读，另一个选项 `-X` 可以让数据包的内容同时以 16 进制和 ASCII 字符形式显示，例如：

```bash
:~$ tcpdump -nn -s0 -v -i en0  port 80 -X
tcpdump: listening on en0, link-type EN10MB (Ethernet), capture size 262144 bytes
08:51:01.902291 IP (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto TCP (6), length 40)
    192.168.50.102.53936 > 120.92.84.16.80: Flags [F.], cksum 0xefc2 (correct), seq 710116020, ack 2044458673, win 4096, length 0
	0x0000:  4500 0028 0000 4000 4006 7b55 c0a8 3266  E..(..@.@.{U..2f
	0x0010:  785c 5410 d2b0 0050 2a53 82b4 79db f6b1  x\T....P*S..y...
	0x0020:  5011 1000 efc2 0000                      P.......
```

 ### 1.2 组合规则

多种过滤器规则可以用标准逻辑进行组合。

* `and` 或者 `&&` 表示 与
* `or` 或者 `||` 表示或
* `not` 或者 `!` 表示非

### 1.3 写入文件

用 `-w [filename]` 选项可以将筛选解析后的数据以 `pcap` 格式写入文件，这种格式可以用 wireshark 打开显示，方便查看。例如：

```bash
:~$ tcpdump -nn -s0 -v -i en0  port 80 -w test.pcap
```

### 1.4 行缓存模式

如果想实时将抓取到的数据通过管道传递给其他工具来处理，需要使用 `-l` 选项来开启行缓存模式（或使用 `-c` 选项来开启数据包缓存模式）。它可以将标准输出立即发送给其他命令，其他命令会立即响应。例如：

```bash
:~$ tcpdump -l | tee dat
```

## 2. 过滤器

### 2.1 筛选 IP 

筛选目的 IP 或者源 IP 为特定值的数据包：

```bash
:~$ tcpdump -i en0 host 192.168.1.1
```

也可用 `src` 筛选源 IP 为特定值的数据包，用 `dst` 筛选目的 IP 为特定在的数据包：

```bash
:~$ tcpdump -i en0 dst 192.168.1.1
```

### 2.2 筛选端口

使用 `port` 选项可以筛选通过特定端口收发的数据包，例如：

```bash
:~$ tcpdump -i en0 port 80
```

也可以筛选特定范围内的端口：

```bash
:~$ tcpdump -i en0 portrange 21-23
```

### 2.2 筛选协议

使用 `proto` 选项可以筛选特定协议的数据包，例如只显示 upd 数据包：

```bash
:~$ tcpdump -i en0 proto udp
```

关键字 `proto` 可以省略，直接写协议名称，支持的协议有 `icmp`, `igmp`, `igrp`, `pim`, `ah`, `esp`, `carp`, `vrrp`, `udp`和 `tcp` 。

