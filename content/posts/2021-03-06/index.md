---
title: "Systemd 中实现自动登录和程序自启动"
date: 2021-03-06T21:19:11+08:00
draft: false
toc: true
comments: true
images:
tags:
  - untagged
---

以 NXP 的 Yocto Linux 4.9.88 为例。

Systemd 管理系统资源的基本单元是 Unit ，分为 12 种：

```
Service unit：系统服务
Target unit：多个 Unit 构成的一个组
Device Unit：硬件设备
Mount Unit：文件系统的挂载点
Automount Unit：自动挂载点
Path Unit：文件或路径
Scope Unit：不是由 Systemd 启动的外部进程
Slice Unit：进程组
Snapshot Unit：Systemd 快照，可以切回某个快照
Socket Unit：进程间通信的 socket
Swap Unit：swap 文件
Timer Unit：定时器
```

我们可以使用 systemd-analyze 命令来分析系统启动的过程：

```
# 查看启动耗时
$ systemd-analyze

# 查看每个服务的启动耗时
$ systemd-analyze blame

# 显示瀑布状的启动过程流
$ systemd-analyze critical-chain

# 显示指定服务的启动流
$ systemd-analyze critical-chain atd.service

# 将系统启动流程输出为 svg 格式，可以通过浏览器查看
systemd-analyze plot > ./systemd.svg
```

Systemd 使用 Target 替换了 init 启动模式的 runlevel 概念。常用的分析命令：

```
# 查看当前系统的所有 Target
$ systemctl list-unit-files --type=target

# 查看一个 Target 包含的所有 Unit
$ systemctl list-dependencies multi-user.target

# 查看启动时的默认 Target
$ systemctl get-default

# 设置启动时的默认 Target
$ systemctl set-default multi-user.target

# 切换 Target 时，默认不关闭前一个 Target 启动的进程，systemctl isolate 命令可以改变这种行为，它会关闭前一个 Target 里面所有不属于后一个 Target 的进程
$ systemctl isolate multi-user.target
```

常用的两个 Target 是：

* multi-user.target , 多用户文本界面
* graphical.target , 图形界面，在 multi-user.target 的基础上，增加了图形界面的相关单元。


## 系统登录

虚拟控制台（tty1...）的登录是 `getty@.service` 服务维护的，最终调用的是 agetty ：

```
ExecStart=-/sbin/agetty -o '-p -- \\u' --noclear %I $TERM
```

启动服务时通过 `@` 符号向 agetty 传递一个参数，例如执行 `getty@tty1.service` ，启动的进程就是：

```
/sbin/agetty -o -p -- \u --noclear tty1 linux
```

串口控制台的登录是 `serial-getty@.service` 服务维护的，最终调用的也是 agetty ：

```
ExecStart=-/sbin/agetty -8 -L %I 115200 $TERM
```

这里传递的参数应该是串口设备文件，例如 `serial-getty@ttymxc0.service` 。

[agetty](https://man7.org/linux/man-pages/man8/agetty.8.html) 有很多参数，--noclear 表示清除控制台显示的启动信息：

```
-J, --noclear
              Do not clear the screen before prompting for the login
              name.  By default the screen is cleared.
```

-a 用于自动登录：

```
-a, --autologin username
              Automatically log in the specified user without asking for
              a username or password.  Using this option causes an -f
              username option and argument to be added to the /bin/login
              command line.  See --login-options, which can be used to
              modify this option's behavior.

              Note that --autologin may affect the way in which getty
              initializes the serial line, because on auto-login agetty
              does not read from the line and it has no opportunity
              optimize the line setting.
```

要系统启动时在串口控制台自动登录 root 用户，可以做如下操作：

1. 新建 `/etc/systemd/system/serial-getty@ttymxc0.service.d/` 目录。
2. 在上面新建的目录中添加 autologing.conf 文件。
3. 在 autologing.conf 文件中添加如下内容：
	```
	[Service]
	ExecStart=
	ExecStart=-/sbin/agetty -a root -8 -L %I 115200 $TERM
	```

这里利用的是 systemd 的附加配置片段功能，这个功能可以修改、重置或者追加配置选项。先创建名为 `/etc/systemd/system/<Unit>.d/`  的目录，然后放入 `*.conf` 文件，其中可以添加或重置选项参数，这里设置的参数优先级高于原来的 Unit 配置文件。用 systemctl 命令会更简单：

```
$ systemctl edit unit
```

这将会在编辑器中打开文件 `/etc/systemd/system/[unit].d/override.conf`，编辑完成之后自动加载。

## 基于 X11 的 Qt 应用自启动

系统中启动 Qt 的服务是 xserver-nodm ，是通过 Yocto 的 `xserver-nodm-init_3.0.bb` 安装的。启动后调用了如下脚本：

```
xserver-nodm.service
	/etc/xserver-nodm/Xserver - /etc/default/xserver-nodm 初始化一些环境变量
		exec xinit /etc/X11/Xsession -- $XSERVER $DISPLAY $ARGS $*
		xinit /etc/X11/Xsession -- /usr/bin/Xorg :0 -br -pn
```

最终干活的是 xinit ，这是 X Window 系统的启动器，它的功能是启动一个 X Server ，同时启动一个 X Client ，基本语法是：

```
xinit [ [ client ] options ] [ -- [ server ] [ display ] options ]
```

在这里它执行了 `/etc/X11/Xsession` 脚本，Xsession 会按字母顺序执行 `/etc/X11/Xsession.d` 下面的脚本，在脚本内启动 Qt 应用，默认安装时会有很多：

```
$ ls /etc/X11/Xsession.d/
13xdgbasedirs.sh  30xinput_calibrate.sh  70settings-daemon.sh  80matchboxkeyboard.sh  89xdgautostart.sh  90XWindowManager.sh
```

我们可以修改这里的脚本，来启动自己的 Qt 应用。例如，我们只想启动 /home/root/ 下的 basiclayouts ，可以将 `/etc/X11/Xsession.d/` 下的文件全部删掉，然后新建一个 10qtapp.sh ，内容如下：

```
exec /home/root/basiclayouts
```

重启系统，basiclayouts 就会自动启动。

## 文本界面的程序自启动

默认情况下，系统启动的是图形目标：

```
$ systemctl get-default
graphical.target
```

如不不需要图形界面，可以切换到多用户文本目标：

```
$ systemctl set-default multi-user.target
Removed /etc/systemd/system/default.target.
Created symlink /etc/systemd/system/default.target → /lib/systemd/system/multi-user.target.
```

systemd 通过 rc-local.service 调用 /etc/rc.local 。需要开机时实现的程序，可以添加到 rc.local 文件中。