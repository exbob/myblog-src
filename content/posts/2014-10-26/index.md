---
title: 在 Linux 中使用 amixer 设置 Input source
date: 2014-10-26T08:00:00+08:00
draft: false
toc:
comments: true
---


电脑的音频输入通常有两个通道：Mic 和 Line in。Mic就是麦克风，Line in 用于连接未经放大的模拟音频信号，例如 Mp3 播放器的耳机插孔，可以将其连接到 PC 的 Line in 插孔。

Linux 上只要用 alsa 管理声卡，它还提供很多工具，alsamixer用于配置音频的各个参数，基于文本下的图形界面。

在命令行输入 alsamixer 就可以启动它的界面，然后按 F6 就可以看到当前系统的网卡，每个网卡都由一个独立的数字 ID ：

![](./pics_1.PNG)

这里的网卡是 HDA Intel，ID 是 0。


amixer 是 alsamixer 的命令行模式。

先看看 amixer 的语法：

![](./pics_2.PNG)

用 amixer -c 0 scontrols 就可以看到 ID 为 0 的网卡的所有可配置接口：

![](./pics_3.PNG)

用 scontents 可以查看这些接口的详细内容，包括可选的选项和当前的选项：

![](./pics_4.PNG)

用 sget 可以查看某个接口的详细信息，然后有 sset 就可以设置：

![](./pics_5.PNG)

如上图所示，Input source 有三个通道可选：Mic ，Front Mic，Line。Line 就表示 Line in 。用 sset 设置具体通道后，就可以用 arecord 对相应通道录音。
