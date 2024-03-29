---
title: 搭建 QNX 开发环境
date: 2013-05-02T08:00:00+08:00
draft: false
toc:
comments: true
---


30天评估版页面：<http://www.qnx.com/products/evaluation/>
在该页面下载所需软件，并申请 License 。

系统环境为：Windows XP 和 VMware 7.0

## 1. 安装 Windows 平台的 QNX 开发套件

下载 QNXSDP-6.5.0 和 QNXSDP-6.5.0-SP1 ，依次安装，安装过程中需要输入 License 。

>注意：安装目录不能有空格，否则以后使用过程中会出错。

安装后在桌面会出现 QNX Momentics IDE 4.7 的图标:

![](./pics_1.GIF)

## 2. 在 VMWare 中运行 QNX

在该页面中选择 VMware (PC) target ，下载文件 650SP1-VM.tar 。下载后解压。

然后用 VMware Workstation 7.0 或 VMware Player 3.0 打开其中的 650SP1-VM.vmx 文件。

如果在启动过程中 VMWare 弹出对话框提示“虚拟机被移动”，选择 Create 并点击 OK 。

启动后无需密码可直接用 root 用户登录。

登录后打开终端，用 ifconfig 查看网卡配置，用 ping 命令查看网络连接。确保可以和宿主机联通。

默认是用 DHCP 方式获取 IP 。

## 3. 创建程序项目

打开 QNX Momentics IDE 。首次打开是根据提示设置 Workspace ，路径中不能有空格。

在菜单上选择 File / New / QNX C Project ，打开 New Project 对话框:

![](./pics_2.GIF)

输入 Project Name ，点击 Next 。在 Build Variants 标签页中选择 X86(Little Endian) 。最后点击 Finish :

![](./pics_3.GIF)

这时 IDE 可能还处于 Welcome 页面，点击右上方的 Workbench 图标，进入项目页面。

![](./pics_4.GIF)

## 4. QNX 的通讯

目标机系统需要能够响应来自开发环境的请求，所以要保证网络连通，并且在目标机系统的终端里启动 qconn 程序：

![](./pics_5.GIF)

然后在开发环境的 Window 菜单中选择 Open Perspective-->QNX System Information ，在打开的 Target Navigator 标签页的空白处点击鼠标右键并选择 New QNX Target...  :

![](./pics_6.GIF)

在打开的对话框中输入 Target Name，也可以选择 Same as hostname ，输入目标机的 IP 。点击 Finish :

![](./pics_7.GIF)

然后在 Target Navigator 中点击刚才新建的目标就可以在右边的 System Summary 页面看到目标机系统的进程列表:

![](./pics_8.GIF)

## 5. 编译和链接

点击右上方的 C/C++ 图标从 QNX System Information 页面返回项目源码编辑页面:

![](./pics_9.GIF)

在项目名称上点击鼠标右键，选择 Build Project 开始编译链接。编译过程应该不会报错。


## 6. 启动和调试

首先要创建一个启动配置。在工具栏上的 bug 图标下拉菜单中选择 Debug Configurations… ：

![](./pics_10.GIF)

然后会出现一个对话框，在这里可以创建、管理和启动配置。

在左栏中选择 C/C++ QNX QConn (IP) ，然后点击 New launch configuration  图标：

![](./pics_11.GIF)

现在只需要设置 main 标签页中的内容。在 C/C++ Application 中点击 C/C++ Application 按钮，选择需要启动和调试的二进制文件，其中带有 `_g` 后缀的文件带有调试信息，否则只能运行不能调试。选择后点击 OK 。

![](./pics_12.GIF)

确保目标机在 Target Options 下列表中，然后点击 Apply ，一个新的启动配置就完成了。

现在点击 Debug ，集成开发环境就进入了调试界面，并通过网络将可执行程序传送到了目标机的系统中，然后在调试器中启动它。
