---
title: NetworkManager 使用笔记
date: 2016-10-13T08:00:00+08:00
draft: false
toc:
comments: true
---


NetworkManager 是目前 Linux 系统中提供网络连接管理服务的一套软件，也支持传统的 ifcfg 类型配置文件。核心是 NetworkManager 守护进程，还提供了命令行工具 nmcli ，以及图形界面配置工具。NetworkManager 可用于以下连接类型：以太网、VLAN、网桥、绑定、成组、Wi-Fi、移动宽带（比如移动网络 3G）及 IP-over-InfiniBand。在这些连接类型中，NetworkManager 可配置网络别名、IP 地址、静态路由器、DNS 信息及 VPN 连接以及很多具体连接参数。最后，NetworkManager 通过 D-bus 提供 API，D-Bus 允许应用程序查询并控制网络配置及状态。

启动、停止、查看 NetworkManager 服务：

    [root@localhost ~]# systemctl start|stop|restart|status NetworkManager
    
NetworkManager 的配置文件和脚本保存在 /etc/sysconfig/ 目录中。大多数网络配置信息都保存在这里，VPN、移动宽带及 PPPoE 配置除外，这些配置保存在 /etc/NetworkManager/ 子目录中。例如，接口的具体信息是保存在 /etc/sysconfig/network-scripts/ 目录下的 ifcfg-* 文件中。全局设置使用 /etc/sysconfig/network 文件

在命令行中，可以使用 nmcli 工具与 NetworkManager 进行交互。例如，修改了某个 ifcfg-* 文件后，需要手动载入，可以执行：

    [root@localhost ~]# nmcli connection load /etc/sysconfig/network-scripts/ifcfg-ifname
    
如果要重新载入全部配置文件，可以执行 ：
    
    [root@localhost ~]# nmcli connection reload

可以执行 `nmcli help` 查看该命令的语法，命令的各种参数都可以用 Tab 键补全。

    [root@localhost ~]# nmcli help
    Usage: nmcli [OPTIONS] OBJECT { COMMAND | help }
     
    OPTIONS
      -t[erse]                                   简洁输出
      -p[retty]                                  美化输出
      -m[ode] tabular|multiline                  输出模式
      -f[ields] <field1,field2,...>|all|common   指定字段输出
      -e[scape] yes|no                           指定分隔符
      -n[ocheck]                                 不检测版本
      -a[sk]                                     询问缺失参数
      -w[ait] <seconds>                          设置超时等待完成操作
      -v[ersion]                                 显示版本
      -h[elp]                                    获得帮助
     
    OBJECT
      g[eneral]       常规管理
      n[etworking]    全面的网络控制
      r[adio]         无线网络管理
      c[onnection]    网络连接管理
      d[evice]        网络设备管理
      a[gent]         网络代理管理
      
列出所有的网络设备：

    [root@localhost ~]# nmcli device show
    GENERAL.DEVICE:                         enp4s0
    GENERAL.TYPE:                           ethernet
    GENERAL.HWADDR:                         00:1D:F3:51:95:4D
    GENERAL.MTU:                            1500
    GENERAL.STATE:                          100 (connected)
    GENERAL.CONNECTION:                     enp4s0
    GENERAL.CON-PATH:                       /org/freedesktop/NetworkManager/ActiveConnection/0
    WIRED-PROPERTIES.CARRIER:               on
    IP4.ADDRESS[1]:                         ip = 192.168.5.242/24, gw = 0.0.0.0
    IP6.ADDRESS[1]:                         ip = fe80::21d:f3ff:fe51:954d/64, gw = ::
    
    GENERAL.DEVICE:                         ttyACM3
    GENERAL.TYPE:                           gsm
    GENERAL.HWADDR:                         (unknown)
    GENERAL.MTU:                            0
    GENERAL.STATE:                          30 (disconnected)
    GENERAL.CONNECTION:                     --
    GENERAL.CON-PATH:                       --
    
    GENERAL.DEVICE:                         lo
    GENERAL.TYPE:                           loopback
    GENERAL.HWADDR:                         00:00:00:00:00:00
    GENERAL.MTU:                            65536
    GENERAL.STATE:                          10 (unmanaged)
    GENERAL.CONNECTION:                     --
    GENERAL.CON-PATH:                       --
    
查看所有网络设备的状态：


    [root@localhost ~]# nmcli device status 
    DEVICE   TYPE      STATE         CONNECTION 
    enp4s0   ethernet  connected     enp4s0     
    ttyACM3  gsm       disconnected  --         
    lo       loopback  unmanaged     --   

查看所有的网络连接：

    [root@localhost ~]# nmcli connection show 
    NAME    UUID                                  TYPE            DEVICE 
    enp4s0  f056272b-e28a-4e69-8264-af9fccfbf45d  802-3-ethernet  enp4s0
    
可以看到，本机有一个以太网卡和一个 3G 网卡，只有以太网使能了连接，3G 网卡处于未连接状态。TYPE 字段表示连接类型，支持的值有：adsl, bond, bond-slave, bridge, bridge-slave, bluetooth, cdma, ethernet, gsm, infiniband, olpc-mesh, team, team-slave, vlan, wifi, wimax。可以在新建或者编辑连接时用 type 参数设置，按 Tab 键查看该列表，或查看 nmcli(1) man page 中的 TYPE_SPECIFIC_OPTIONS 列表。

DEVICE 表示设备名称，如果是以太网或者WiFi，就是用 ifconfig -a 看到的名称。CONNECTION 表示连接名称，这是在连接配置文件的名称，这里的以太网配置文件是 ifcfg-enp4s0 。可以在新建连接时用 con-name 参数设置。

## 1. 以太网

新建一个以太网连接，使用动态 IP ：

    [root@localhost ~]# nmcli connection add type ethernet con-name connection-name ifname interface-name

这样会在 /etc/sysconfig/network-scripts/ 目录下生成一个 ifcfg-* 配置文件。使用以下命令激活以太网连接：

    [root@localhost ~]# nmcli con up my-office
    Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/5)

用如下命令可以查看该连接的详细信息：
    
    [root@localhost ~]# nmcli connection show enp4s0 
    
## 2. 3G 网卡

查看这个设备的详情：

    [root@localhost ~]# nmcli device show ttyACM3 
    GENERAL.DEVICE:                         ttyACM3
    GENERAL.TYPE:                           gsm
    GENERAL.HWADDR:                         (unknown)
    GENERAL.MTU:                            0
    GENERAL.STATE:                          30 (disconnected)
    GENERAL.CONNECTION:                     --
    GENERAL.CON-PATH:                       --
    
新建一个 3G 网卡的连接：

    [root@localhost ~]# nmcli connection add type gsm ifname ttyACM3 user 3gnet password 3gnet apn 3gnet
    Connection 'gsm-ttyACM3' (d15e8860-6dc1-4aa5-b579-b898e651a984) successfully added.
    
这会在 /etc/NetworkManager/system-connections/ 下生成一个配置文件，并且会自动连接，生成一个 ppp0 的网络设备：

    [root@localhost ~]# cat gsm-ttyACM3 
    [connection]
    id=gsm-ttyACM3
    uuid=7561e339-43b7-4e7f-bc2c-5886b5a97afc
    interface-name=ttyACM3
    type=gsm
    
    [gsm]
    number=*99#
    username=3gnet
    password=3gnet
    apn=3gnet
    [root@localhost ~]# nmcli device status 
    DEVICE   TYPE      STATE      CONNECTION  
    enp4s0   ethernet  connected  enp4s0      
    ttyACM3  gsm       connected  gsm-ttyACM3 
    ppp0     unknown   connected  ppp0        
    lo       loopback  unmanaged  --    
    ~]# nmcli connection show
    NAME         UUID                                  TYPE            DEVICE  
    ppp0         9e55469f-b362-4122-8031-aa18360a8d75  generic         ppp0    
    gsm-ttyACM3  7561e339-43b7-4e7f-bc2c-5886b5a97afc  gsm             ttyACM3 
    enp4s0       f056272b-e28a-4e69-8264-af9fccfbf45d  802-3-ethernet  enp4s0  
    
要取消自动连接，需要将 autoconnect 设为 false ：

    [root@localhost ~]# nmcli connection modify gsm-ttyACM3 connection.autoconnect false
    [root@localhost ~]# cat /etc/NetworkManager/system-connections/gsm-ttyACM3 
    [connection]
    id=gsm-ttyACM3
    uuid=86f38b5b-31e3-4250-8304-c94a8fe7ac29
    interface-name=ttyACM3
    type=gsm
    autoconnect=false
    
    [gsm]
    number=*99#
    username=3gnet
    password=3gnet
    apn=3gnet
    
## 3. WiFi

用如下命令查看可访问的 WiFi 热点：

    [root@localhost ~]# nmcli device wifi list 
    *  SSID               MODE   CHAN  RATE       SIGNAL  BARS  SECURITY  
       SBSon              Infra  4     54 Mbit/s  84      â–‚â–„â–†â–ˆ  WPA1 WPA2 
       TP-LINK_3          Infra  1     54 Mbit/s  77      â–‚â–„â–†_  WPA2      
       readtime           Infra  1     54 Mbit/s  70      â–‚â–„â–†_  WPA2      
       sbstest            Infra  1     54 Mbit/s  59      â–‚â–„â–†_  WPA1 WPA2 
       Xiaomi             Infra  1     54 Mbit/s  57      â–‚â–„â–†_  WPA2      
       wifi-360           Infra  6     54 Mbit/s  47      â–‚â–„__  WPA2      
       
新建一个名为 wifi-con 的 WiFi 连接：

    [root@localhost ~]# nmcli connection add con-name wifi-con ifname wlp1s0 type wifi ssid TP-LINK_3
    Connection 'wifi-con' (7c5ae676-a2c7-49df-a37b-d93787be2b72) successfully added.    

设置加密方式为 WPA2 ，并设置密码：

    [root@localhost ~]# nmcli connection modify wifi-con wifi-sec.key-mgmt wpa-psk  
    [root@localhost ~]# nmcli connection modify wifi-con wifi-sec.psk 87654321
    
激活该连接：

    [root@localhost ~]# nmcli connection up wifi-con 
    Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/3)
    [root@localhost ~]# iwconfig 
    lo        no wireless extensions.
    
    enp4s0    no wireless extensions.
    
    wlp1s0    IEEE 802.11abgn  ESSID:"TP-LINK_3"  
              Mode:Managed  Frequency:2.412 GHz  Access Point: 64:09:80:64:2F:8E   
              Bit Rate=1 Mb/s   Tx-Power=15 dBm   
              Retry short limit:7   RTS thr:off   Fragment thr:off
              Encryption key:off
              Power Management:off
              Link Quality=44/70  Signal level=-66 dBm  
              Rx invalid nwid:0  Rx invalid crypt:0  Rx invalid frag:0
              Tx excessive retries:3  Invalid misc:20   Missed beacon:0
