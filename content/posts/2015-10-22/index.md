---
title: Linux 下调试蓝牙模块的笔记
date: 2015-10-22T08:00:00+08:00
draft: false
toc:
comments: true
---



## 1. 蓝牙简介

蓝牙是一种支持设备短距离通信的无线电技术，使用 2.4GHz 频段，数据速率为1Mbps 。采用时分复用方案实现全双工传输。

蓝牙技术将设备分为两种：主设备和从设备。 

蓝牙主设备的特点：主设备一般具有输入端。在进行蓝牙匹配操作时，用户通过输入端可输入随机的匹配密码来将两个设备匹配。蓝牙手机、安装有蓝牙模块的 PC 等都是主设备。（例如：蓝牙手机和蓝牙 PC 进行匹配时，用户可在蓝牙手机上任意输入一组数字，然后在蓝牙PC上输入相同的一组数字，来完成这两个设备之间的匹配。） 

蓝牙从设备特点：从设备一般不具备输入端。因此从设备在出厂时，在其蓝牙芯片中，固化有一个4位或6位数字的匹配密码。蓝牙耳机等都是从设备。（例如：蓝牙 PC 与蓝牙耳机匹配时，用户将蓝牙耳机上的匹配密码输入到蓝牙 PC 上，完成匹配。）

蓝牙设备的呼叫过程：

1. 蓝牙主端设备发起呼叫，首先是查找，找出周围处于可被查找的蓝牙设备，此时从端设备需要处于可被查找状态。
2. 主端设备找到从端蓝牙设备后，与从端蓝牙设备进行配对，此时需要输入从端设备的 PIN 码。
3. 配对完成后，从端蓝牙设备会记录主端设备的信任信息，此时主端即可向从端设备发起呼叫，根据应用不同，可能是ACL数据链路呼叫或SCO语音链路呼叫，已配对的设备在下次呼叫时，不再需要重新配对。
4. 已配对的设备，做为从端的蓝牙耳机也可以发起建链请求，但做数据通讯的蓝牙模块一般不发起呼叫。
5. 链路建立成功后，主从两端之间即可进行双向的数据通讯。在通信状态下，主端和从端设备都可以发起断链，断开蓝牙链路。

蓝牙协议栈：

![](./pics_1.jpg)

* RFCOMM 叫做电缆替代协议，它在蓝牙基带协议上仿真 RS-232 控制和数据信号，为使用串行线传送机制的上层协议（如 OBEX ）提供服务。
* OBEX 叫做对象交换协议，采用简单的和自发的方式交换目标，用于传输文件。

## 2. Linux 对蓝牙的支持

2.6 之后的内核都提供了蓝牙支持，通常都已经是默认的设置：

    [*] Networking support --->                [CONFIG_NET]
      </M> Bluetooth subsystem support --->    [CONFIG_BT]
        <*/M> RFCOMM protocol support          [CONFIG_BT_RFCOMM]
        [*]   RFCOMM TTY support               [CONFIG_BT_RFCOMM_TTY]
        <*/M> BNEP protocol support            [CONFIG_BT_BNEP]
        [*]   Multicast filter support         [CONFIG_BT_BNEP_MC_FILTER]
        [*]   Protocol filter support          [CONFIG_BT_BNEP_PROTO_FILTER]
        <*/M> HIDP protocol support            [CONFIG_BT_HIDP]
            Bluetooth device drivers --->
              (Select the appropriate drivers for your Bluetooth hardware)
    
      <*/M> RF switch subsystem support --->   [CONFIG_RFKILL]

Linux 官方的蓝牙协议栈是 BlueZ ，BlueZ 包括 ：
* HCI Core
* HCI UART, USB and Virtual HCI device drivers
* L2CAP module
* Configuration and testing utilities

BlueZ 包提供了蓝牙编程库和各种工具：

* bccmd : is used to issue BlueCore commands to Cambridge Silicon Radio devices.
* bluemoon : is a Bluemoon configuration utility.
* bluetoothctl : is the interactive Bluetooth control program.
* bluetoothd : is the Bluetooth daemon.
* btmon : provides access to the Bluetooth subsystem monitor infrastructure for reading HCI traces.
* ciptool : is used to set up, maintain, and inspect the CIP configuration of the Bluetooth subsystem in the Linux kernel.
* hciattach : is used to attach a serial UART to the Bluetooth stack as HCI transport interface.
* hciconfig : is used to configure Bluetooth devices.
* hcidump : reads raw HCI data coming from and going to a Bluetooth device and prints to screen commands, events and data in a human-readable form.
* hcitool : is used to configure Bluetooth connections and send some special command to Bluetooth devices.
* hex2hcd : is used to convert a file needed by Broadcom devices to hcd (Broadcom bluetooth firmware) format.
* l2ping : is used to send a L2CAP echo request to the Bluetooth MAC address given in dotted hex notation.
* l2test : is L2CAP testing program.
* rctest : is used to test RFCOMM communications on the Bluetooth stack.
* rfcomm : is used to set up, maintain, and inspect the RFCOMM configuration of the Bluetooth subsystem in the Linux kernel.
* sdptool : is used to perform SDP queries on Bluetooth devices.
* libbluetooth.so : contains the BlueZ 4 API functions.

安装了 BlueZ 之后，配置文件都在 /etc/bluetooth 目录下。

## 3. 在 Linux 中配置蓝牙

使用的模块是 Intel 2330 ，同时支持 WIFI 和 Bluetooth 。调试前应该先下载模块的固件 iwlwifi-2030-6.ucode ，放入系统的 /lib/fireware 目录下，系统加载驱动 iwlwifi 时会自动查找。使用的系统是 yocto linux ，运行在 Intel Quark 平台的主板。

系统启动后可以查看设备：

    root@WR-IntelligentDevice:~# lsusb
    Bus 001 Device 002: ID 0424:2514 Standard Microsystems Corp. USB 2.0 Hub
    Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
    Bus 002 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
    Bus 001 Device 003: ID 8087:07da Intel Corp. 

应该加载的驱动：

    root@WR-IntelligentDevice:~# lsmod | grep bt
    bluetooth             200527  6 rfcomm,hidp,btusb
    btusb                  11506  0 

如果驱动加载成功，会出现蓝牙的设备节点，使用 hciconfig 命令查看：

    root@WR-IntelligentDevice:~# hciconfig -a
    hci0:   Type: BR/EDR  Bus: USB
            BD Address: 00:15:00:A1:E3:83  ACL MTU: 310:10  SCO MTU: 64:8
            DOWN 
            RX bytes:495 acl:0 sco:0 events:22 errors:0
            TX bytes:369 acl:0 sco:0 commands:22 errors:0
            Features: 0xff 0xff 0x8f 0xfe 0xdb 0xff 0x5b 0x87
            Packet type: DM1 DM3 DM5 DH1 DH3 DH5 HV1 HV2 HV3 
            Link policy: RSWITCH HOLD SNIFF PARK 
            Link mode: SLAVE ACCEPT 
            
可以看到设备的状态是 DOWN ，表示蓝牙还没有启动。手动启动蓝牙，可以看到蓝牙状态变为 UP RUNNING ，而且是从设备：

    root@WR-IntelligentDevice:~# hciconfig hci0 up
    root@WR-IntelligentDevice:~# hciconfig -a 
    hci0:   Type: BR/EDR  Bus: USB
            BD Address: 00:15:00:A1:E3:83  ACL MTU: 310:10  SCO MTU: 64:8
            UP RUNNING 
            RX bytes:990 acl:0 sco:0 events:44 errors:0
            TX bytes:738 acl:0 sco:0 commands:44 errors:0
            Features: 0xff 0xff 0x8f 0xfe 0xdb 0xff 0x5b 0x87
            Packet type: DM1 DM3 DM5 DH1 DH3 DH5 HV1 HV2 HV3 
            Link policy: RSWITCH HOLD SNIFF PARK 
            Link mode: SLAVE ACCEPT 
            Name: 'PC Controller App v1.4'
            Class: 0x000000
            Service Classes: Unspecified
            Device Class: Miscellaneous, 
            HCI Version: 4.0 (0x6)  Revision: 0x1ebd
            LMP Version: 4.0 (0x6)  Subversion: 0xfc00
            Manufacturer: Intel Corp. (2)

更好的方法是用 bluetoothd 启动蓝牙， bluetoothd 是一个守护进程，启动时会根据 /etc/bluetooth/ 下的配置文件初始化蓝牙，直接执行 `bluetoothd` 。

### 3.1 连接手机蓝牙

打开手机的蓝牙，测试用的是小米手机。这里要注意一点，手机上的蓝牙在打开后会有一段时间处于可检测状态，也就是其他蓝牙设备可以扫描到它，之后会关闭可检测性，这段时间的长短通常可以设置，有的手机在熄屏时也会关闭蓝牙的可检测性。

然后扫描一下周边的蓝牙设备：   

    root@WR-IntelligentDevice:~# hcitool scan
    Scanning ...
            A2:CF:49:FD:99:AF       MI-ONE Plus

> scan 用于扫描经典蓝牙设备，如果是低功耗蓝牙设备（BLE），例如手环之类，要 用 lescan 选项，调试 BLE 设备要用 gatttool 工具。

测试能否连通：

    root@WR-IntelligentDevice:~# l2ping -i hci0 -c 4 A2:CF:49:FD:99:AF
    Ping: A2:CF:49:FD:99:AF from 00:15:00:A1:E3:83 (data size 44) ...
    44 bytes from A2:CF:49:FD:99:AF id 0 time 25.03ms
    44 bytes from A2:CF:49:FD:99:AF id 1 time 25.32ms
    44 bytes from A2:CF:49:FD:99:AF id 2 time 26.96ms
    44 bytes from A2:CF:49:FD:99:AF id 3 time 27.06ms
    4 sent, 4 received, 0% loss

利用 SDP 协议，我们还可以查看每个设备都有功能，能提供什么服务，每种基于 RFCOMM 的服务都使用某种协议，占据哪个“频道 (channel)”，这是使用服务时的一个重要参数，先看看自己：

    root@WR-IntelligentDevice:~# sdptool browse local
    Browsing FF:FF:FF:00:00:00 ...
    Service Name: SIM Access Server
    Service RecHandle: 0x10000
    Service Class ID List:
      "SIM Access" (0x112d)
      "Generic Telephony" (0x1204)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
      "RFCOMM" (0x0003)
        Channel: 8
    Profile Descriptor List:
      "SIM Access" (0x112d)
        Version: 0x0101
    
    Service Name: Headset Audio Gateway
    Service RecHandle: 0x10001
    Service Class ID List:
      "Headset Audio Gateway" (0x1112)
      "Generic Audio" (0x1203)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
      "RFCOMM" (0x0003)
        Channel: 12
    Profile Descriptor List:
      "Headset" (0x1108)
        Version: 0x0102
    
    Service Name: Hands-Free Audio Gateway
    Service RecHandle: 0x10002
    Service Class ID List:
      "Handsfree Audio Gateway" (0x111f)
      "Generic Audio" (0x1203)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
      "RFCOMM" (0x0003)
        Channel: 13
    Profile Descriptor List:
      "Handsfree" (0x111e)
        Version: 0x0105
    
    Service Name: Audio Source
    Service RecHandle: 0x10003
    Service Class ID List:
      "Audio Source" (0x110a)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
        PSM: 25
      "AVDTP" (0x0019)
        uint16: 0x102
    Profile Descriptor List:
      "Advanced Audio" (0x110d)
        Version: 0x0102
    
    Service Name: AVRCP TG
    Service RecHandle: 0x10004
    Service Class ID List:
      "AV Remote Target" (0x110c)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
        PSM: 23
      "AVCTP" (0x0017)
        uint16: 0x103
    Profile Descriptor List:
      "AV Remote" (0x110e)
        Version: 0x0104
    
    Service Name: AVRCP CT
    Service RecHandle: 0x10005
    Service Class ID List:
      "AV Remote" (0x110e)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
        PSM: 23
      "AVCTP" (0x0017)
        uint16: 0x103
    Profile Descriptor List:
      "AV Remote" (0x110e)
        Version: 0x0100
    
    Service Name: Dial-Up Networking
    Service RecHandle: 0x10006
    Service Class ID List:
      "Dialup Networking" (0x1103)
      "Generic Networking" (0x1201)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
      "RFCOMM" (0x0003)
        Channel: 1
    Profile Descriptor List:
      "Dialup Networking" (0x1103)
        Version: 0x0100

再看看手机的蓝牙服务：

    root@WR-IntelligentDevice:~# sdptool browse  A2:CF:49:FD:99:AF 
    Browsing A2:CF:49:FD:99:AF ...
    Service RecHandle: 0x10000
    Service Class ID List:
      "PnP Information" (0x1200)
    Profile Descriptor List:
      "PnP Information" (0x1200)
        Version: 0x0102
    
    Service Name: Audio Source
    Service RecHandle: 0x10001
    Service Class ID List:
      "Audio Source" (0x110a)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
        PSM: 25
      "AVDTP" (0x0019)
        uint16: 0x102
    Profile Descriptor List:
      "Advanced Audio" (0x110d)
        Version: 0x0102
    
    Service Name: AVRCP TG
    Service RecHandle: 0x10002
    Service Class ID List:
      "AV Remote Target" (0x110c)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
        PSM: 23
      "AVCTP" (0x0017)
        uint16: 0x103
    Profile Descriptor List:
      "AV Remote" (0x110e)
        Version: 0x0100
    
    Service Name: Voice Gateway
    Service RecHandle: 0x10003
    Service Class ID List:
      "Handsfree Audio Gateway" (0x111f)
      "Generic Audio" (0x1203)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
      "RFCOMM" (0x0003)
        Channel: 10
    Profile Descriptor List:
      "Handsfree" (0x111e)
        Version: 0x0105
    
    Service Name: Voice Gateway
    Service RecHandle: 0x10004
    Service Class ID List:
      "Headset Audio Gateway" (0x1112)
      "Generic Audio" (0x1203)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
      "RFCOMM" (0x0003)
        Channel: 11
    Profile Descriptor List:
      "Headset" (0x1108)
        Version: 0x0102
    
    Service Name: OBEX Object Push
    Service RecHandle: 0x10005
    Service Class ID List:
      "OBEX Object Push" (0x1105)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
      "RFCOMM" (0x0003)
        Channel: 12
      "OBEX" (0x0008)
    Profile Descriptor List:
      "OBEX Object Push" (0x1105)
        Version: 0x0100
    
    Service Name: OBEX Phonebook Access Server
    Service RecHandle: 0x10006
    Service Class ID List:
      "Phonebook Access - PSE" (0x112f)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
      "RFCOMM" (0x0003)
        Channel: 19
      "OBEX" (0x0008)
    Profile Descriptor List:
      "Phonebook Access" (0x1130)
        Version: 0x0100


使用 openobex 包提供的 obex_test 工具，在 yocto 的官网可以下载到 recipes 文件和补丁。或者在下载源码：<https://github.com/zuckschwerdt/openobex>

### 3.2 连接蓝牙耳机

先启动本地的蓝牙服务并配置：

    root@WR-IntelligentDevice:~# bluetoothd
    root@WR-IntelligentDevice:~# hciconfig hci0 noencrypt
    root@WR-IntelligentDevice:~# hciconfig hci0 piscan
    root@WR-IntelligentDevice:~# hciconfig hci0 name "bluez4"
    root@WR-IntelligentDevice:~# hciconfig hci0 pageto 65535

然后启动蓝牙耳机，使之处于可检测状态，然后扫描：

    root@WR-IntelligentDevice:~# hcitool scan
    Scanning ...
            50:C9:71:AA:E0:AE       JABRA EASYGO
        
准备一个 test.wav 的音频文件，然后用如下脚本测试蓝牙耳机：

    #!/bin/sh
    local mac="50:C9:71:AA:E0:AE"
    local asoundconf="/etc/asound.conf"
    
    #add service    
    sdptool add a2snk
    sdptool add a2src
    sdptool add avrct
    sdptool add avrtg
    sdptool add hf
    sdptool add hs

    echo "" >> $asoundconf
    echo "pcm.bluetooth{" >> $asoundconf
    echo "    type bluetooth" >> $asoundconf
    echo "    device $mac" >> $asoundconf
    echo "    profile \"hifi\"" >> $asoundconf
    echo "}" >> $asoundconf

    echo "Bind to $mac ..."
    simple-agent hci0 $mac || {
        echo "simple-agent failed!"
        exit 1
    }

    echo "Connect $mac ..."
    bluez-test-audio connect $mac || {
        echo "audio connect failed!"
        exit 1
    }

    echo "Connection result ..."
    hcitool con

    echo "Play audio ..."
    aplay -D bluetooth ./test.wav

正常情况会打印如下信息，蓝牙耳机可以听到音频内容：

    Audio sink service registered
    Audio source service registered
    Remote control service registered
    Remote target service registered
    Handsfree service registered
    Headset service registered
    Bind to 50:C9:71:AA:E0:AE ...
    Release
    New device (/org/bluez/3319/hci0/dev_50_C9_71_AA_E0_AE)
    Connect 50:C9:71:AA:E0:AE ...
    Connection result ...
    Connections:
            < ACL 50:C9:71:AA:E0:AE handle 34 state 1 lm MASTER AUTH ENCRYPT 
    Play audio ...
    Playing WAVE './test.wav' : Signed 16 bit Little Endian, Rate 44100 Hz, Stereo
