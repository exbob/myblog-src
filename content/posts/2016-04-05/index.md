---
title: Linux 下调试低功耗蓝牙的笔记
date: 2016-04-05T08:00:00+08:00
draft: false
toc:
comments: true
---



蓝牙 4.0 版本推出了低功耗规范，简称 BLE (Bluetooth Low Energy)，很多小型设备，例如小米手环，都是使用低功耗蓝牙。要与这类模块连接，主设备的蓝牙模块必须支持低功耗，例如 intel 2230 ：

![](./pics_1.jpg)

现在有一个 BLE 的透传模块，会不断的发出数据，我的主机安装了 Linux ，使用 intel 2230 接收数据。协议栈依然是 BlueZ 。

## 1. GATT 协议

BLE 连接都是建立在 GATT 协议之上的。介绍 GATT 之前，需要了解 GAP（Generic Access Profile）。它在用来控制设备连接和广播。GAP 使你的设备被其他设备可见，并决定了你的设备是否可以或者怎样与合同设备进行交互。GAP 给设备定义了若干角色，其中主要的两个是：外围设备（Peripheral）和中心设备（Central），外设必须不停的向外广播，让中心设备知道它的存在。中心设备扫描到外设后，发起并建立 GATT 连接。

GATT 连接是独占的，也就是一个 BLE 外设同时只能被一个中心设备连接。一旦外设被连接，它就会马上停止广播。中心设备和外设需要双向通信的话，唯一的方式就是建立 GATT 连接。一个外设只能连接一个中心设备，而一个中心设备可以连接多个外设。GATT 定义 BLE 通信的双方是 C/S 关系，外设作为服务端（Server），也叫从设备（Slave），中心设备是客户端（Client），也叫主设备（Master）。所有的通信事件，都是由 Client 发起请求，Server 作出响应。但 GATT 还有两个特性：notification 和 indication。这意味着 server 可以主动发出通知和指示，使 client 端不用轮询。

GATT 是一个在蓝牙连接之上的发送和接收很短的数据段的通用规范（ATT），这些很短的数据段被称为属性（Attribute）。一个 attribute 由三种元素组成：

* 一个16位的句柄（handle）
* 一个定长的值（value）
* 一个 UUID，定义了 attribute 的**类型**，value 的意义完全由 UUID 决定。

> attribute 的 handle 具有唯一性，仅用作区分不用的 attribute（因为可能有很多不同的 attribute 拥有相同的 UUID）

Attribute 只存储在 Server 端，多个 attribute 构成一个 characteristic（特征值），一个或多个 characteristic 构成一个 Service (服务)，一个 BLE 设备可以有多个 Service ，Service 是把数据分成一个个的独立逻辑项。

![](./pics_2.jpg)

一个 GATT Service 始于 UUID 为 0x2800 的 attribute ，直到下一个 UUID 为 0x2800 的 attribute 为止。范围内的所有 attribute 都属于该服务的。例如，一台有三种服务的设备拥有如下所示的 attribute 布局：

| Handle | UUID | Description | Value
| ----- | ----- | ----- | -----
| 0x0100 | 0x2800 | Service A definition | 0x1816 (UUID)
| ... | ... | Service details | ...
| 0x0150 | 0x2800 | Service B definition | 0x18xx
| ... | ...	| Service details | ...
| 0x0300 | 0x2800 | Service C definition | 0x18xx
| ... | ... | Service details | ...

handle 具有唯一性，属于 Service B 的 attribute 的 handle 范围肯定落在 0x0151  和 0x02ff 之中。那么，我如何知道一个 Service 是温度检测，还是 GPS 呢？通过读取该 Service 的 attribute 的 value 。UUID 为 0x2800 的 attribute 作为 Service 的起始标志，它的 value 就是该服务的 UUID ，是该服务的唯一标识，表示了该服务的类型。UUID 有 16 bit 的，或者 128 bit 的。16 bit 的 UUID 是官方通过认证的，需要购买，128 bit 是自定义的，这个就可以自己随便设置。

每个 Service 都包含一个或多个 characteristic（特征值）。这些 characteristic 负责存储 Service 的数据和访问权限。每个 Characteristic 用 16 bit 或者 128 bit 的 UUID 唯一标识。例如，一个温度计（service）一般会有一个只读的“温度”characteristic，和一个可读写的“日期时间”characteristic：

| Handle | UUID | Description | Value
| ----- | ----- | ----- | -----
| 0x0100 | 0x2800 | Thermometer service definition | UUID 0x1816
| 0x0101 | 0x2803 | Characteristic: temperature | UUID 0x2A2B,Value handle: 0x0102
| 0x0102 | 0x2A2B | Temperature value | 20 degrees
| 0x0110 | 0x2803 | Characteristic: date/time | UUID 0x2A08,Value handle: 0x0111
| 0x0111 | 0x2A08 | Date/Time | 1/1/1980 12:00

可以看到，handle 0x0101 定义了一个“温度” characteristic ，该 characteristic 的 UUID 是 0x2A2B，它的值位于 handle 0x0102 。

除了 value，还可以在 characteristic 的附加 attribute 里获取到其它信息。这些附加的 attribute 称为 descriptor 。例如，当我们我们需要明确温度计的计量单位时，可以通过添加一个 descriptor 来实现：

| Handle | UUID | Description | Value
| ----- | ----- | ----- | -----
| 0x0100 | 0x2800 | Thermometer service definition | UUID 0x1816
| 0x0101 | 0x2803 | Characteristic: temperature | UUID 0x2A2B,Value handle: 0x0102
| 0x0102 | 0x2A2B | Temperature value | 20 degrees
| 0x0104 | 0x2A1F | Descriptor: unit | Celsius
| 0x0110 | 0x2803 | Characteristic: date/time | UUID 0x2A08,Value handle: 0x0111
| 0x0111 | 0x2A08 | Date/Time | 1/1/1980 12:00

GATT 知道 handle 0x0104 是属于 characteristic 0x0101 的 descriptor，因为：

* 它不是一个 value attribute，因为 value attribute 已经指明是 handle 0x0102 
* 它刚好在 0x0103..0x010F 的范围内，两个 characteristic 之间

每个 service 都可以自定义 desctiptor，GATT 已经预定义了一系列常用的 desctiptor ：

* 数据格式和表达方式
* 可读性描述
* 有效范围
* 扩展属性

其中一个很重要的 descriptor 是 client characteristic configuration ，简称 CCC descriptor ，它的 UUID 是 0x2902 ，有一个可读性的 16 位 Value ，低两位已经被占用，用于配置 characteristic 的 notification 和 indication ：

* Bit 0 设为 1 表示使能 Notification 
* Bit 1 设为 1 表示使能 Indication     

对于具有 Notify 属性的 characteristic ，使能 Notification 后，数据发生变化时会主动通知 Client 端，Client 端只要监听即可。

## 2. Linux 中的操作

在 BlueZ 中就要用 `hcitool lescan` 命令扫描低功耗蓝牙设备：

    root@WR-IntelligentDevice:~# hcitool lescan   
    LE Scan ...
    20:91:48:6B:65:08 (unknown)
    20:91:48:6B:65:08 SPP_2091486B6508

`gatttool` 是用来访问 BLE 设备的命令，用 `gatttool -b 20:91:48:6B:65:08 -I` 打开一个与远程设备的会话，-I 表示交互模式：

    root@WR-IntelligentDevice:~# gatttool -b 20:91:48:6B:65:08 -I
    [   ][20:91:48:6B:65:08][LE]> help
    help                                           Show this help
    exit                                           Exit interactive mode
    quit                                           Exit interactive mode
    connect         [address [address type]]       Connect to a remote device
    disconnect                                     Disconnect from a remote device
    primary         [UUID]                         Primary Service Discovery
    characteristics [start hnd [end hnd [UUID]]]   Characteristics Discovery
    char-desc       [start hnd] [end hnd]          Characteristics Descriptor Discovery
    char-read-hnd   <handle> [offset]              Characteristics Value/Descriptor Read by handle
    char-read-uuid  <UUID> [start hnd] [end hnd]   Characteristics Value/Descriptor Read by UUID
    char-write-req  <handle> <new value>           Characteristic Value Write (Write Request)
    char-write-cmd  <handle> <new value>           Characteristic Value Write (No response)
    sec-level       [low | medium | high]          Set security level. Default: low
    mtu             <value>                        Exchange MTU for GATT/ATT
    [   ][20:91:48:6B:65:08][LE]> 


`connect` 表示连接远程设备，连接成功后，提示符签名的状态会显示 "CON" :

    [   ][20:91:48:6B:65:08][LE]> connect
    [CON][20:91:48:6B:65:08][LE]> 
    
`primary` 命令会列出远程设备上所有的 Service ，每个服务所在的 handle 范围:

    [CON][20:91:48:6B:65:08][LE]> primary 
    [CON][20:91:48:6B:65:08][LE]> 
    attr handle: 0x0001, end grp handle: 0x000b uuid: 00001800-0000-1000-8000-00805f9b34fb
    attr handle: 0x000c, end grp handle: 0x000f uuid: 00001801-0000-1000-8000-00805f9b34fb
    attr handle: 0x0010, end grp handle: 0x0017 uuid: 0000fee7-0000-1000-8000-00805f9b34fb
    attr handle: 0x0018, end grp handle: 0x001b uuid: 0000fee0-0000-1000-8000-00805f9b34fb
    attr handle: 0x001c, end grp handle: 0x0024 uuid: f000ffc0-0451-4000-b000-000000000000
    attr handle: 0x0025, end grp handle: 0x002f uuid: 0000ccc0-0000-1000-8000-00805f9b34fb
    attr handle: 0x0030, end grp handle: 0xffff uuid: 0000180a-0000-1000-8000-00805f9b34fb

用 `primary fee7`  查看 UUID 为 0xfee7 的 Service ，执行 `characteristics 0x0010 0x0017` 可以发现它有三个 characteristics ：

    [CON][20:91:48:28:26:AF][LE]> primary fee7
    [CON][20:91:48:28:26:AF][LE]> 
    Starting handle: 0x0010 Ending handle: 0x0017
    [CON][20:91:48:28:26:AF][LE]> characteristics 0x0010 0x0017
    [CON][20:91:48:28:26:AF][LE]> 
    handle: 0x0011, char properties: 0x20, char value handle: 0x0012, uuid: 0000fec8-0000-1000-8000-00805f9b34fb
    handle: 0x0014, char properties: 0x0a, char value handle: 0x0015, uuid: 0000fec7-0000-1000-8000-00805f9b34fb
    handle: 0x0016, char properties: 0x02, char value handle: 0x0017, uuid: 0000fec9-0000-1000-8000-00805f9b34fb
    
char properties 表示 characteristic 的属性，char value handle 表示 characteristic 的值所在的 attribute 的 handle 。下面是 characteristic properties 的说明：

![](./pics_3.jpg)

现在远程设备上有一个透传服务是 0xFEE0, 传输数据的特征值是 0xFEE1 ，可以用如下方式查看：

    [CON][20:91:48:6B:65:08][LE]> primary 0xfee0
    [CON][20:91:48:6B:65:08][LE]> 
    Starting handle: 0x0018 Ending handle: 0x001b
    [CON][20:91:48:6B:65:08][LE]> characteristics  0x0018 0x001b       
    [CON][20:91:48:6B:65:08][LE]> 
    handle: 0x0019, char properties: 0x14, char value handle: 0x001a, uuid: 0000fee1-0000-1000-8000-00805f9b34fb
    [CON][20:91:48:6B:65:08][LE]> char-desc 0x0018 0x001b
    [CON][20:91:48:6B:65:08][LE]> 
    handle: 0x0018, uuid: 2800
    handle: 0x0019, uuid: 2803
    handle: 0x001a, uuid: fee1
    handle: 0x001b, uuid: 2902
    
首先执行 `primary 0xfee0` ，发现该服务包含 handle 0x0018 到 handle 0x001b 之间的 attribute 。然后用 `characteristics  0x0018 0x001b` 发现该服务有一个 characteristic ，它的值在 handle 0x001a ，属性是 0x14 ，表示可写无回复/通知（Write without response/Notify）。最后用 `char-desc 0x0018 0x001b` 列出该特征值的所有 Descriptor ，最后一个 UUID 为 0x2902 ，是一个 CCC Descriptor ，读取它当前的值：

    [CON][20:91:48:28:26:AF][LE]> char-read-hnd 0x001b
    [CON][20:91:48:28:26:AF][LE]> 
    Characteristic value/descriptor: 00 00

> 通过 handle 读写的好处是准确，因为 handle 具有唯一性。如果执行 `char-read-uuid 0x2902` ，就会发现列出了很多个 attribute 。

当前的值是 0 ，这个 characteristic 的属性是 Notify ，所以要向 handle 0x001b 写入 0x0100 （X86 是小端），使能 Notify ，然后就会不停的收到数据：

    [CON][20:91:48:28:26:AF][LE]> char-write-req 0x001b 0100
    [CON][20:91:48:28:26:AF][LE]> Characteristic value was written successfully
    
    Notification handle = 0x001a value: 41 47 3a 20 37 30 34 38 20 37 30 39 35 20 36 30 20 2d 31 37 
    [CON][20:91:48:28:26:AF][LE]> 
    Notification handle = 0x001a value: 20 2d 32 31 33 20 39 34 36 20 2d 39 33 30 20 2d 31 39 36 20 
    [CON][20:91:48:28:26:AF][LE]> 
    Notification handle = 0x001a value: 39 33 38 20 2d 39 33 30 0a 41 47 3a 20 37 30 34 31 20 37 31 
    [CON][20:91:48:28:26:AF][LE]> 

在非交互模式下，用 `--listen` 选项启动监听模式来接收通知：

    root@WR-IntelligentDevice:~# gatttool -b 20:91:48:28:26:AF --char-write-req --handle=0x001b --value=0100 --listen
    Characteristic value was written successfully
    Notification handle = 0x001a value: 32 30 37 32 20 35 33 32 39 20 34 32 39 35 20 41 47 3a 20 2d 
    Notification handle = 0x001a value: 32 30 37 36 20 35 33 32 36 20 34 33 30 30 20 41 47 3a 20 2d 
    Notification handle = 0x001a value: 32 30 37 38 20 35 33 32 37 20 34 33 30 35 20 41 47 3a 20 2d 

## 3. 参考

[Introduction to Bluetooth Low Energy](https://learn.adafruit.com/introduction-to-bluetooth-low-energy?view=all)
[Get started with Bluetooth Low Energy](http://www.jaredwolff.com/blog/get-started-with-bluetooth-low-energy/)
[GATT Specifications](https://developer.bluetooth.org/gatt/Pages/default.aspx)
[Bluetooth: ATT and GATT](https://epxx.co/artigos/bluetooth_gatt.html)
