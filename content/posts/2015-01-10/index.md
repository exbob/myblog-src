---
title: Today Scripts —— 通过脚本打造自己的通知栏部件
date: 2015-01-10T08:00:00+08:00
draft: false
toc:
comments: true
---


OS X Yosemite 新增了一个通知中心，可以在上面放一些小部件。而 Today Script 这个小部件可以让你写自己的脚本，在通知栏显示自己想要的东西。

* 主页：[https://github.com/SamRothCA/Today-Scripts](https://github.com/SamRothCA/Today-Scripts)
* 脚本列表：[https://github.com/SamRothCA/Today-Scripts/wiki](https://github.com/SamRothCA/Today-Scripts/wiki)

在主页上点击下载链接，下载一个压缩包：Today-Scripts.tar.gz，解压得到 Today Scripts.app ，放到应用程序文件夹内，然后打开。在通知中心就会出现 Scripts :

![](./pics_1.JPG)

点击加号，把它添加到通知栏。按照提示，点击右上角的 Info 图标来添加一个脚本：

![](./pics_2.JPG)

添加一个显示当前月份的命令：

	cal | grep --before-context 6 --after-context 6 --color -e " $(date +%e)" -e "^$(date +%e)"
	
记得写上标题：

![](./pics_3.JPG)

效果如下：

![](./pics_4.JPG)
