---
title: Linux IPv6 HOWTO
date: 2015-11-27T08:00:00+08:00
draft: false
toc:
comments: true
---


## 1. What is IPv6

IPv6 是为了解决 IPv4 地址资源日渐枯竭的问题，使用的是 128bit 地址，可以提供更多的地址空间。IPv6 地址以 16bit 为一组，每组用冒号隔开，可以分为八组，每组以 4 个十六进制数表示，共 32 个十六进制数，例如 `2001:0db8:85a3:08d3:1319:8a2e:0370:7344`  是一个合法的 IPv6 地址，它又可以分为两个逻辑部分：一个 64 位的网络前缀和一个 64 位的主机地址。

IPv6 中的 loopback interface 定义为 `0000:0000:0000:0000:0000:0000:0000:0001` ，也可以表示为 `::1` ，因为每组中的前导 0 可以省略，一对连续的冒号表示多组 0 ，一个 IPv6 地址中允许出现一对连冒号。

IPv4 位址可以很容易的转化为 IPv6 格式。如果 IPv4 的一个地址为`135.75.43.52`（十六进制为 0x874B2B34 ），它可以被转化为`0000:0000:0000:0000:0000:ffff:874B:2B34` 或者 `::ffff:874B:2B34` 。同时，还可以使用混合符号（IPv4-compatible address），则地址可以为 `::ffff:135.75.43.52` 。

## 2. Linux support

首先需要内核支持，2.6 之后的内核都支持 IPv6 ，在 3.x 版本中，通常默认已经编译入内核：

![](./pics_1.jpg)

如果 IPv6 编译成了模块，可以用 `modprobe ipv6` 命令加载。内核支持后就可以在 /proc 文件系统中看到 if_net6 文件：

![](./pics_2.jpg)

要将网口配置成 IPv6 ，也需要配置命令支持 IPv6 ，可以用如下命令检查 ifconfig 是否支持 IPv6 :

    ~# ifconfig -? 2>& 1 | grep -qw 'inet6' && echo "utility 'ifconfig' is IPv6-ready"

检查 route 是否支持 IPv6 :

    ~# route -? 2>& 1 | grep -qw 'inet6' && echo "utility 'route' is IPv6-ready"

## 3. Configuration

为网口添加一个 IPv6 地址 ：

![](./pics_3.jpg)

可以用 del 参数删除 ：`ifconfig eth0 inet6 del 2001:0db8:0:f101::1/64`

## 4. Test

可以用 IPv6 可以用 ping6 命令，例如测试 loopback interface ：

![](./pics_4.jpg)

ping6 的 -I 参数可以指定网口，例如要测试 eth0 可以用 `ping6 -I eth0  fe80::2e0:18ff:fe90:9205` 。

测试路由的 traceroute 命令也有 IPv6 版本： traceroute6 。

## 5. 参考

<http://tldp.org/HOWTO/Linux+IPv6-HOWTO/index.html>
