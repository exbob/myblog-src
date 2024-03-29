---
title: 科学上网利器 Shadowsocks
date: 2015-01-20T08:00:00+08:00
draft: false
toc:
comments: true
---


Shadowsocks 可以为浏览器，支持代理服务器的软件（例如 Dropbox）提供代理服务。

首先购买一个付费的 Shadowsocks 服务账号，推荐 [https://shadowsocks.com](https://shadowsocks.com)，不限流量，速度还不错。购买后会提供多个可用的服务器地址，端口，密码和加密方式。

欢迎使用我的推广链接：[https://portal.shadowsocks.com/aff.php?aff=424](https://portal.shadowsocks.com/aff.php?aff=424)

下载 OS X 客户端：[ShadowsocksX](https://github.com/shadowsocks/shadowsocks-iOS/wiki/Shadowsocks-for-OSX-Help)。安装后启动，选择 “打开服务器设定” ：

![](./pics_1.JPG)

添加服务器，输入服务商提供的域名，端口，密码：

![](./pics_2.JPG)

然后就可以科学上网了。客户端已经集成了 GFWList ，可以自动识别访问地址，墙内地址走国内路径，墙外地址走代理服务器。可以添加多个服务器，感觉日本的节点速度更快。

Dropbox 已经完全被墙，修改 hosts 也无法连接，只能用代理。打开 “首选项” ，在“网络”标签中选择 “代理服务器设置”，手动设置服务器类型为 SOCK5 ，服务器地址 127.0.0.1 ，端口 1080：

![](./pics_3.JPG)

点击 “更新”，Dropbox 就复活了。
