---
title: 在 Linux 系统中部署 goagent
date: 2012-03-23T08:00:00+08:00
draft: false
toc:
comments: true
---


Goagent 的项目主页在 googlecode：<http://code.google.com/p/goagent/>

首页有 Windows 系统中的部署教程，Linux 系统中的部署方法有些复杂，记录如下:

1. 申请一个Google Appengine：<http://code.google.com/intl/zh-CN/appengine/>，并且创建一个 appid。
2. 下载 Python 版的 Google App Engine SDK，下载页面：<http://code.google.com/intl/zh-CN/appengine/downloads.html#Google_App_Engine_SDK_for_Python>，要选择 Linux 平台。下载后解压为一个 google_appengine 文件夹。
3. 下载 goagent 稳定版，在项目主页的顶部就有下载链接，当前的版本是 goagent 1.7.10。下载后解压到 google_appengine/goagent 文件夹。
4. 修改 local/proxy.ini 文件中的 [gae] 下的 appid=你的appid ，多个 appid 可以用 | 隔开。
5. 上传。在 google_appengine 目录下执行：python appcfg.py update goagent/server/python。上传需要一些时间。
6. chrome 浏览器请安装 SwitchySharp 插件：<https://chrome.google.com/webstore/detail/dpplabbmogkhghncfbfdeeokoefdjegm>，安装后导入这个设置：<http://goagent.googlecode.com/files/SwitchyOptions.bak>。
7. 使用时在 goagent/local 下执行 python proxy.py ，然后打开 chrome 即可。
