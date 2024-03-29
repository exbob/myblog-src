---
title: GRUB2常用配置
date: 2013-04-25T08:00:00+08:00
draft: false
toc:
comments: true
---


[GRUB2 指南中文版](http://www.eit.name/blog/read.php?442)

修改 GRUB2 的配置文件后，都要执行 `update_grub` 命令生成 `/boot/grub/grub.cfg` 文件，这样才能使修改生效。任何情况下都不建议手动更改该文件。

## 1.显示启动菜单

默认情况下，如果只安装了一个系统，GRUB2是不会显示启动菜单的。

可以在启动时按住 Shift 键，强制显示启动菜单。

## 2.修改默认启动项

在 `/etc/default/grub` 文件中，设置 `GRUB_DEFAULT`：

	GRUB_DEFAULT = 0

`/boot/grub/grub.cfg` 文件中的第一个菜单项为 0 ，第二个为 1 ... 

也可以设置为 `saved` ，表示默认启动项为上一次选择的项目。

## 3.修改 Linux 内核参数

在 `/etc/default/grub` 文件中，有两个选项用于设置向 Linux 内核传递的参数：

* **GRUB\_CMDLINE\_LINUX**  若存在，无论在一般或是救援模式，此行将追加到所有的 'linux'  命令行后面（传统 GRUB  的「kernel」选项）。类似于 menu.lst 中的「altoptions 」选项。  
* **GRUB\_CMDLINE\_LINUX\_DEFAULT**   此行将追加在 'linux'  命令行后面（传统 GRUB  的「kernel」选项）。此选项只会追加在一般模式的最后方。类似于 menu.lst 中的「defoptions」选项。如果想显示黑色屏幕以及启动进程文字，请移除「quiet splash」。若想看到 grub 引导画面及简短的文字输出，使用「splash」。若有需要的话，也可以在此行输入选项「acpi=off」。
