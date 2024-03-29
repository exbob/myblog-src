---
title: Linux Wireless —— 无线操作模式
date: 2012-10-27T08:00:00+08:00
draft: false
toc:
comments: true
---


原文：
[Wireless Operating Modes](http://linuxwireless.org/en/users/Documentation/modes)

Translated by Bob

2012-10-27

Email：gexbob@gmail.com

Blog：<http://shaocheng.li>

***

一个 WNIC （Wireless Network Interface Controller，无线网络接口控制器）总是运行在如下几种模式之一。这些模式设定了无线连接的主要功能。有时也可能同时运行在两种模式。

## Station (STA) 基本模式

任何无线驱动都能运行在这种模式。因此它被称作默认模式。两个 STA 模式的 WNIC 无法相互连接。它们需要第三个 AP 模式的 WNIC 来管理无线网络！STA 模式的 WNIC 通过发送管理数据帧来连接 AP 模式的 WNIC 。这个过程叫做认证（authentication）和关联（association）。当 AP 发送关联成功的回复后，这个 STA 就成为了无线网络的一部分。

## AccessPoint (AP) 基本模式

在一个已经被管理的无线网络中，Access Point 是作为主设备存在的。它通过管理和维护 STA 列表来聚合网络。它还管理安全策略。这个网络就以 AP 的 MAC 地址命名。同时还会为 AP 设置一个可读的名字 SSID 。

_Linux 下使用 AP 模式需要用到 hostapd ，当前至少是 0.6 版本，最好通过 git 获得。<http://wireless.erley.org>_

## Monitor (MON) 模式

Monitor 模式是一个被动模式，不会传输数据帧。所有的输入包都交给主机处理，不会进行任何过滤。这个模式被用来监视网络。

对于 mac80211 ，除了常规设备，它可能还有一个处于 Monitor 模式的网络设备，用于检测和使用网络。可是，不是所有的硬件都支持这个功能，因为不是所有的硬件都能配置为在其他模式下显示所有的数据包。Monitor 模式接口总是工作在“尽可能(best effort)”的基础上。

对于 mac80211 ，也可以在 Monitor 模式下发送数据包，这叫做数据包注入。用于想在用户空间实施 MLME 工作的应用程序，例如支持 IEEE 802.11 的非标准 MAC 扩展。

## Ad-Hoc (IBSS) 模式

Ad-Hoc 模式也叫 IBBS (Independent Basic Service Set) 模式，用于创建无需 AP 的无线网络。IBSS 网络中的每个节点都管理自己的网络。 Ad-Hoc 用于在没有可用 AP 的情况下使两台或更多的电脑相互连接。

## Wireless Distribution System (WDS) 模式

分发系统 (Distribution System) 是通过有线连接到 AP 。无线分发系统 (Wireless Distribution System) 是通过无线的方式完成相同的工作。WDS 作为多个关联 AP 之间的共同途径，可被用于替代综合布线。阅读 [iw WDS](http://linuxwireless.org/en/users/Documentation/iw#Setting_up_a_WDS_peer) 文档可以详细了解怎样使能这个模式，也要重新理解使用 [4-address mode](http://linuxwireless.org/en/users/Documentation/iw#Using_4-address_for_AP_and_client_mode) 。

## Mesh

Mesh 接口被用于允许多个设备之间通过动态的建立智能路由来相互沟通。

查看 [Wikipedia's entry on 802.11s](http://en.wikipedia.org/wiki/IEEE_802.11s) 和 [Wireless mesh network(WMN)](http://en.wikipedia.org/wiki/Wireless_mesh_network)。

为了实现 mesh 的 portal 功能，可以为常规网口桥接一个 mesh 接口。
