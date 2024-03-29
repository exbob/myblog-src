---
title: 个性化定制地图 —— Mapbox
date: 2014-10-09T08:00:00+08:00
draft: false
toc:
comments: true
---


Mapbox 想要构建世界上最漂亮的地图。支持多种平台，可以免费创建并定制个性化的地图，实现非常绚丽的效果。

* 主页：[http://www.mapbox.com](http://www.mapbox.com)
* 这里有一个介绍：[http://www.pingwest.com/demo/mapbox](http://www.pingwest.com/demo/mapbox)

## 定制自己的地图

首先要注册一个账号，然后在主页面上方点击 Project ，进入到如下界面，点击 Create project 就可以新建一个自己的地图。

![](./pics_1.PNG)

我新建了一个 My First Map 。点击它，就可以进入编辑界面，左上方是定制地图所需的工具：

### Style

![](./pics_2.PNG)

这个标签用来设置地图的样式，包括：

* Color ：设置街道，绿地，建筑，水在地图上显示的颜色。
* Baselayer ：设置地图的基本图层，有街道地图，地形图和卫星图。
* Language ：设置地图的语言，Localized 表示本地语言。

### Data

![](./pics_3.PNG)

这个标签用来向地图添加自定义的数据，包括：

* Marker ：点状标记。
* Line ：线，轨迹。
* Poygon ：一块图形，或者区域。

另外，点击下方的 import ，可以导入 csv 、kml 、gpx 格式的数据文件。

### Project

![](./pics_4.PNG)

这个标签中可以设置地图名称和描述，还可以在此下载和分享地图。

* Info ：Data 栏可以选择下载 GeoJSON 或 KML 格式的地图文件。Map ID 是这个地图的唯一标识符，用于开发。Share 栏是该地图的分享链接。Embed 是该地图嵌入 Web 页面的代码，下面可以选择页面中是否显示放大缩小，搜索和分享链接按钮。
* Settings ：设置地图名称和描述。
* Advanced ：这里有两个选项，选中 Save current map position 后，通过分享的地图会显示现在所选的位置和大小。选中 Hind Project frome public API ，通过分享的地图可以看到在 Data 中添加的数据。

![](./pics_5.PNG)

> 修改地图后一定要点击上方的 Save 保存。
