---
title: Linux Wireless HowTo
date: 2016-10-26T08:00:00+08:00
draft: false
toc: true
comments: true
---



这里的无线（Wireless）指无线局域网，它的通用标准是 IEEE 802.11 协议，定义了数据链路层（MAC层）和物理层协议，工作载波的频率为 2.4GHz ，划分了 11 个频道，最新的协议已经有 5GHz 的工作频率。协议的演进方向是 802.11a->802.11b->802.11g->802.11n 。

而 802.11i 是 802.11 的无线安全协议，它的技术实现是 WPA 和 WPA2 ，都是开放秘钥认证方式，都属于 Wi-Fi 联盟，WPA2 是比 WPA 更高级的一种安全方式，RSN 是 WPA2 的别名。PSK 和 802.1X 是两种无线安全实现的方式，PSK 是个人级别的，而 802.1X 是企业级别的，较为复杂，但更安全。TKIP 和 CCMP 是两种数据加密算法，在 WPA 和 WPA2 中都可以使用。而 AES 是 CCMP 算法中的核心算法，且目前来看，是最可靠的加密算法。

Wi-Fi 是一个厂商联盟的标志，目的是建立一个统一的、基于 IEEE 802.11 协议的技术实现。可以简单把 Wi-Fi 设备理解为符合 IEEE 802.11 协议标准的设备。

Linux 系统中的无线网卡通常用到两种模式，一种是 Station 模式，也就是作为普通 Wi-Fi 设备去连接无线路由器；另一种是 AccessPoint（AP）模式，就是让无线网卡作为 Wi-Fi 热点，供其他 Wi-Fi 设备连接，这需要用到 hostapd ，可以参考 <http://shaocheng.li/post/blog/2016-01-01>， 这里主要讲 Station 模式下无线网卡的操作方式。关于无线操作模式：<http://shaocheng.li/post/blog/2012-10-27-wireless-oprating-mode> 。

## 1. 硬件和驱动

大部分无线网卡是 pci 设备，以 Intel 6205 为例，在 Fedora 21 中查看：

    [root@localhost ~]# lspci
    00:00.0 Host bridge: Intel Corporation Atom Processor Z36xxx/Z37xxx Series SoC Transaction Register (rev 0c)
    ...
    01:00.0 Network controller: Intel Corporation Centrino Advanced-N 6205 [Taylor Peak] (rev 34)
    04:00.0 Ethernet controller: Intel Corporation 82574L Gigabit Network Connection
    [root@localhost ~]# lspci -vk -s 01:00.0
    01:00.0 Network controller: Intel Corporation Centrino Advanced-N 6205 [Taylor Peak] (rev 34)
            Subsystem: Intel Corporation Centrino Advanced-N 6205 AGN
            Flags: bus master, fast devsel, latency 0, IRQ 268
            Memory at 90700000 (64-bit, non-prefetchable) [size=8K]
            Capabilities: [c8] Power Management version 3
            Capabilities: [d0] MSI: Enable+ Count=1/1 Maskable- 64bit+
            Capabilities: [e0] Express Endpoint, MSI 00
            Capabilities: [100] Advanced Error Reporting
            Capabilities: [140] Device Serial Number 10-0b-a9-ff-ff-b4-99-00
            Kernel driver in use: iwlwifi
            Kernel modules: iwlwifi

可以看到它使用的驱动是 iwlwifi ，这是当前 Intel 无线芯片的通用驱动，针对不同的芯片需要不同的固件，固件名称的格式是 iwlwifi-*.ucode ，存放在 /lib/firmware/ 目录下。在这个页面可以查看支持的芯片和固件下载列表：<https://wireless.wiki.kernel.org/en/users/drivers/iwlwifi> 。Linux 内核对无线设备的支持也是分层的结构，最上层面向用户空间的接口标准有两个，nl80211 和 wext ，nl80211 正在逐步替代 wext 。我们可以在 /sys/module/iwlwifi/parameters/ 目录下读取驱动的各项参数：

    /sys/module/iwlwifi/parameters# ls -l
    total 0
    -r--r--r-- 1 root root 4096 Nov 29 10:03 11n_disable
    -r--r--r-- 1 root root 4096 Nov 29 10:03 amsdu_size_8K
    -r--r--r-- 1 root root 4096 Nov 29 10:03 antenna_coupling
    -r--r--r-- 1 root root 4096 Nov 29 10:03 bt_coex_active
    -r--r--r-- 1 root root 4096 Nov 29 10:03 fw_restart
    -r--r--r-- 1 root root 4096 Nov 29 10:03 led_mode
    -r--r--r-- 1 root root 4096 Nov 29 10:03 nvm_file
    -r--r--r-- 1 root root 4096 Nov 29 10:03 power_level
    -r--r--r-- 1 root root 4096 Nov 29 10:03 power_save
    -r--r--r-- 1 root root 4096 Nov 29 10:03 swcrypto
    -r--r--r-- 1 root root 4096 Nov 29 10:03 wd_disable

如果要修改某个参数，需要在 /etc/modprobe.d/ 目录下新建一个 iwlwifi.conf 文件，然后添加选项，比如禁用 11n ：

    /etc/modprobe.d# cat iwlwifi.conf 
    options iwlwifi 11n_disable=1

修改后重新加载驱动，或者重启，就可以在 /sys/module/iwlwifi/parameters 目录下验证该选项是否已经被修改：

    /sys/module/iwlwifi/parameters# cat 11n_disable 
    1

驱动和固件加载成功后，就会出现设备文件：

    [root@localhost ~]# iw dev
    phy#0
            Interface wlp1s0
                    ifindex 3
                    wdev 0x1
                    addr 10:0b:a9:b4:99:00
                    type managed

可以看到，这个无线设备的名称是 phy#0 ，接口名称是 wlp1s0 ，addr 段就是 mac 地址，当前的设备类型是 managed ，也就是 station 模式。用 `ifconfig -a` 也可以看到。

可以通过内核信息查询当前加载的固件版本：

```
[root@localhost ~]# dmesg | grep iwlwifi
[27592.118803] iwlwifi 0000:03:00.0: Direct firmware load for iwlwifi-7265D-19.ucode failed with error -2
[27592.118837] iwlwifi 0000:03:00.0: Direct firmware load for iwlwifi-7265D-18.ucode failed with error -2
[27592.118890] iwlwifi 0000:03:00.0: Direct firmware load for iwlwifi-7265D-17.ucode failed with error -2
[27592.128638] iwlwifi 0000:03:00.0: loaded firmware version 16.242414.0 op_mode iwlmvm
```



## 2. iw 工具

iw 是一个管理无线设备的命令行工具，使用 nl80211 接口标准，支持所有最新被添加到 Linux 内核的无线网卡驱动。旧的 iwconfig 工具使用 wext 接口标准。

用 `iw list` 命令可以列出当前系统中所有无线设备的功能特性。如果要看指定网卡的特性，语法是 `iw devicename info` ：

    [root@localhost ~]# iw phy#0 info
    Wiphy phy0
            max # scan SSIDs: 20
            max scan IEs length: 195 bytes
            Coverage class: 0 (up to 0m)
            Device supports RSN-IBSS.
            Supported Ciphers:
                    * WEP40 (00-0f-ac:1)
                    * WEP104 (00-0f-ac:5)
                    * TKIP (00-0f-ac:2)
                    * CCMP (00-0f-ac:4)
            Available Antennas: TX 0 RX 0
            Supported interface modes:
                     * IBSS
                     * managed
                     * AP
                     * AP/VLAN
                     * monitor
             ...
            Supported commands:
                     * new_interface
                     * set_interface
                     * new_key
                     * start_ap
                     * new_station
                     * new_mpath
             ...
            software interface modes (can always be added):
                     * AP/VLAN
                     * monitor
             ...
            Device supports TX status socket option.
            Device supports HT-IBSS.
            Device supports scan flush.

这个信息很长，首先看到最多可以扫描 20 个热点，支持的加密算法是 WEP            、TKIP、CCMP。在 Supported interface modes 段可以看到该网卡支持的模式，包括 AP ，在 software interface modes 可以看到该网卡支持软 AP 。在 Supported commands 段列出了该网卡支持的命令，这些都是 nl80211 接口提供的命令，可以在 Linux 内核的 nl80211.c 文件中看到。

运行 `iw dev wlp1s0 scan` 可以扫描 Wi-Fi 热点，前题是接口已经激活，可以用 `ifconfig wlp1s0 up` ，否则会失败：

    [root@localhost ~]# iw dev wlp1s0 scan                  
    command failed: Network is down (-100)

以扫描到的一个热点为例：

    BSS f4:ec:38:30:bb:b8(on wlp1s0)
            TSF: 2459924068 usec (0d, 00:40:59)
            freq: 2437
            beacon interval: 100 TUs
            capability: ESS Privacy ShortPreamble ShortSlotTime (0x0431)
            signal: -51.00 dBm
            last seen: 1 ms ago
            SSID: TP-LINK_30BBB8
            Supported rates: 1.0* 2.0* 5.5* 11.0* 6.0 9.0 12.0 18.0 
            DS Parameter set: channel 6
            RSN:     * Version: 1
                     * Group cipher: CCMP
                     * Pairwise ciphers: CCMP
                     * Authentication suites: PSK
                     * Capabilities: 1-PTKSA-RC 1-GTKSA-RC (0x0000)
            WPA:     * Version: 1
                     * Group cipher: CCMP
                     * Pairwise ciphers: CCMP
                     * Authentication suites: PSK
            ERP: <no flags>
            ...

可以读到几个有用的信息，首先是信号强度 signal:-51.00 dBm ，热点的 SSID 是 TP-LINK_30BBB8 ，使用的频道是 6 ，认证方式是
WPA 和 RSN （即 WPA2），秘钥管理算法是 PSK ，加密算法是 CCMP 。

iw 支持手动连接无认证或者 WEP 认证的 Wi-Fi 热点，而不支持 WPA/WPA2 认证热点。如果要加入无认证的热点，执行 `iw wlp1s0 connect <SSID>` 。对于 WEP 认证的热点，执行 `iw wlp1s0 connect <SSID>  [key 0:abcde d:1:6162636465]` 。连接成功后，可以设置静态 IP ，也可以用 dhclient 动态获取 IP 和 DNS 。我们很少用 iw 来连接 Wi-Fi ，通常是用 wpa_supplicant 。

还有一个在调试时有用的命令 `iw event` ，它可以监听 Wi-Fi 连接过程中的所有事件。当启动 wpa_supplicant 去连接一个热点时，可以开启该命令，它会显示完整的连接过程，包括扫描、协商、验证、连接。加一个 -f 选项可以显示连接过程发送的帧，加 -t 选项可以显示每个步骤的时间：

    [root@localhost ~]# iw event -t
    1478053617.986731: wlp1s0 (phy #0): scan started
    1478053619.947956: wlp1s0 (phy #0): scan finished: 2412 2417 2422 2427 2432 2437 2442 2447 2452 2457 2462 2467 2472 5180 5200 5220 5240 5260 5280 5300 5320 5745 5765 5785 5805 5825, ""
    1478053619.977751: wlp1s0: new station f4:ec:38:30:bb:b8
    1478053619.988617: wlp1s0 (phy #0): auth f4:ec:38:30:bb:b8 -> 10:0b:a9:b4:99:00 status: 0: Successful
    1478053620.043766: wlp1s0 (phy #0): assoc f4:ec:38:30:bb:b8 -> 10:0b:a9:b4:99:00 status: 0: Successful
    1478053620.043992: wlp1s0 (phy #0): connected to f4:ec:38:30:bb:b8

查看连接状态：

    [root@localhost ~]# iw wlp1s0 link    
    Not connected.
    [root@localhost ~]# iw wlp1s0 link
    Connected to f4:ec:38:30:bb:b8 (on wlp1s0)
            SSID: TP-LINK_30BBB8
            freq: 2437
            RX: 6256 bytes (46 packets)
            TX: 1435 bytes (15 packets)
            signal: -59 dBm
            tx bitrate: 1.0 MBit/s
            bss flags:      short-preamble short-slot-time
            dtim period:    1
            beacon int:     100

SSID 字段表示当前连接的热点名称。signal 字段表示当前连接热点的信号强度，它是个负数，越接近 0 ，表示信号越好，小于 -113 就基本没信号了。

查看当前无线设备的使用情况，包括进出流量等信息：

    [root@localhost ~]# iw dev wlp1s0 station dump   
    Station f4:ec:38:30:bb:b8 (on wlp1s0)
            inactive time:  175 ms
            rx bytes:       4635
            rx packets:     31
            tx bytes:       1095
            tx packets:     11
            tx retries:     49
            tx failed:      2
            signal:         -68 dBm
            signal avg:     -64 dBm
            tx bitrate:     1.0 MBit/s
            rx bitrate:     54.0 MBit/s MCS 3 40MHz
            authorized:     yes
            authenticated:  yes
            preamble:       long
            WMM/WME:        yes
            MFP:            no
            TDLS peer:      no

iw 还有其他选项，可以执行 `iw help` 查看。

## 3. wpa_supplicant

wpa_supplicant 是一个命令行式的 Wi-Fi 访问客户端程序，支持 WEP、WPA/WPA2 认证方式，在 Linux 中用于自动连接 Wi-Fi 热点，支持断线后自动重连。同时支持 nl80211 和 wext 两种驱动接口。

常用选项：

* -B ：让 wpa_supplicant 运行在后台，在 -i 选项前设置。
* -c filename ：配置文件的路径，在 -i 选项前设置。
* -D ：设置使用的驱动，可选 nl80211 和 wext 等，在 -i 选项前设置。
* -i interface ：监听的无线设备接口名称，这里可以设为 wlp1s0 。
* -d ：增加调试信息，-dd 可以显示更多。
* -t ：在调试信息中加上时间戳。
* -f filename ：日志文件的路径。
* -P filename ：PID 文件的路径。
* -q ：减少调试信息，-qq 可以显示的更少。
* -u ：使能 DBus 控制接口。
* -N ：如果有多个无线设备，就用 -N 分隔，之后继续设置下一个。例如 `wpa_supplicant -c wpa1.conf -i wlan0 -D hostap -N  -c wpa2.conf -i ath0 -D madwifi`

配置文件通常是 /etc/wpa_supplicant/wpa_supplicant.conf ，可以在文件内设置多个 Wi-Fi 热点的连接信息，wpa_supplicant 启动后会自动选择一个最好的网络，依据是认证方式（ WPA/WPA2 优先）和信号强度。如果完整安装了 wpa_supplicant ，在 /usr/share/doc/wpa_supplicant/ 目录下会有一个 wpa_supplicant.conf 文件，里面有各种情况的详细配置和说明。说几个常用的全局配置选项：

* ctrl_interface=filename ：设置控制接口的路径。如果设置了该参数，wpa_supplicant 会打开一个控制接口，供外部程序管理 wpa_supplicant 。推荐设置为 /var/run/wpa_supplicant ，wpa_supplicant 会在此目录下生成 socket ，用于监听外部程序状态的请求。
* ap_scan ：通常设为 1 。由 wpa_supplicant 启动扫描和 AP 选择，如果没有找到与配置文件中相匹配的 AP ，则初始化一个新网络（如果有配置）。另外可选 0 或 2 。

每个 Wi-Fi 热点的连接信息都配置在一个 network 段中，几个常用的选项：

* key_mgmt ：秘钥管理算法，对于 WPA/WPA2 ，根据 Wi-Fi 热点的配置可选 WPA-PSK 和 WPA-EAP 。
* ssid ：热点的 ssid 。
* psk ：对于 WPA/WPA2 ，密码不能设为明码，需要用 wpa_passphrase 命令生成加密后的 64 位十六进制数，语法是 `wpa_passphrase SSID password` 。

假如现在要连接一个 WPA/WPA2 认证的无线路由器，配置文件如下：

    [root@localhost ~]# wpa_passphrase TP-LINK_30BBB8 123456789 
    network={
        ssid="TP-LINK_30BBB8"
        #psk="123456789"
        psk=b9ea0d09776bd4f4d8099b78ab91d924b97366562d620161a1b4ffb1ac99ae33
    }
    [root@localhost ~]# cat /etc/wpa_supplicant/wpa_supplicant.conf
    ctrl_interface=/var/run/wpa_supplicant
    ap_scan=1
    network={
            ssid="TP-LINK_30BBB8"
            key_mgmt=WPA-PSK
            #psk="123456789"
            psk=b9ea0d09776bd4f4d8099b78ab91d924b97366562d620161a1b4ffb1ac99ae33
    }

对于无许认证的热点，只设置 ssid 即可 ：

    network={
        ssid="MYSSID"
        key_mgmt=NONE
    }

然后执行 wpa_supplicant 开始连接：

    [root@localhost ~]# wpa_supplicant -B -Dnl80211 -u -iwlp1s0 -c /etc/wpa_supplicant/wpa_supplicant.conf -f /var/log/wpa_supplicant.log -P /var/run/wpa_supplicant.pid 

连接过程可以查看 log 文件，连接成功后可以设置静态 IP ，也可以用 dhclient 获得动态 IP 。    
    
## 4. dhclient

DHCP 协议是一种集中管理和自动分配 IP 地址的通信协议，使用 UDP 协议工作。DHCP 使用了租约的概念，即获得的 IP 地址的有效期。一次典型的 DHCP 工作周期分为发现、提供、请求、确认，如图：

![](./pics_1.jpg)

不再租用 IP 后，客户端应该向 DHCP 服务器发送一个请求以释放 DHCP 资源，并注销其IP地址。详情可以参考[动态主机设置协议](https://zh.wikipedia.org/wiki/%E5%8A%A8%E6%80%81%E4%B8%BB%E6%9C%BA%E8%AE%BE%E7%BD%AE%E5%8D%8F%E8%AE%AE)

dhclient 是一个 DHCP 客户端程序，用于从 DHCP 服务器获取动态 IP ，默认支持 IPV4 ，也支持 IPV6 。成功获得 IP 后，程序会驻留在后台。常用的选项有：

* -lf <lease-file> ：lease 文件的路径，默认是 /var/lib/dhclient/dhclient.leases ，是成功获取 IP 后的数据库。
* -pf <pid-file> ：PID 文件的路径，默认是 /var/run/dhclient.pid 。
* -cf <config-file> ：配置文件的路径. 默认是 /etc/dhcp/dhclient.conf 。
* -sf <script-file> ：网络配置脚本文件的路径。默认是 /sbin/dhclient-script ，成功获取 IP 后会执行该脚本，主要作用是配置 IP 、DNS、和默认路由，还会调用 /etc/dhcp/dhclient.d/ 下的用户自定义脚本。
* -q ：保持安静，不输出任何信息。
* -timeout <time> ：超时时间，超过这个时间而无法获得 IP 即退出。
* -r ：告诉 dhclient 释放获取的 IP ，释放后，后台的 dhclient 会退出。
* -d ：让 dhclient 在前台运行。

配置文件默认是 /etc/dhcp/dhclient.conf，同目录下还有一个名为 dhclient.d 的文件夹，可以在下面放一些脚本，供 dhclient-script 调用，执行一下获取 IP 后的动作。如果安装了完整的程序，在 /usr/share/doc/dhclient 目录下会有配置文件的例子和 dhclient.d 下脚本文件的说明。

针对 wlp1s0 这个接口写一个简单的配置文件：

    timeout 60;
    retry 60;
    reboot 10;
    select-timeout 5;
    initial-interval 2;
    reject 192.33.137.209;
    interface "wlp1s0" {
        send host-name “my_pc";
        send dhcp-lease-time 3600;
        request subnet-mask, broadcast-address, time-offset, routers,domain-search, domain-name, domain-name-servers, host-name;
        require subnet-mask, domain-name-servers,host-name;
    }

解释一下这些配置选项：

* timeout ：超时时间，这里设置是 60 秒。从尝试与 DHCP server 联系开始，超过这个时间还没有获得 IP ，就结束这次协商，在重试间隔后再重启协商。
* retry ：重试间隔，一次与 DHCP server 协商失败后，经过这个时间后重启协商，默认是五分钟。
* reboot ：当 dhclient 启动后，它会首先尝试请求上一次连接该网络时获得的 IP ，如果失败，则经过这个时间后在尝试请求新 IP ，默认是十秒。
* select-timeout ：如果有多个 DHCP server 为该网络提供服务，client 可能获得多个 IP 提议，而这些提议有先后顺序，client 会在 select-timeout 时间内接收提议，然后选择最优的（比如上一次获得的 IP ），超过这个时间，就停止接收新提议。默认是零秒，就是直接采用第一个接收到的提议。
* initial-interval ：第一次尝试到达服务器和第二次尝试到达服务器的间隔。
* reject ：拒绝来自某些 DHCP server 的提议。可以指定某个 IP ，也可以通过子网掩码指定拒绝某个网段，多个 IP 用逗号分隔，例如：`reject 192.168.0.0/16, 10.0.0.5;` 。

设置完全局选项，就可以对网口进行单独设置，这些选项可以在 dhcp-options 的 man 手册中查找。一个配置文件可以为多个网口配置不同的行为，语法是 `interface "name" { declarations ... }` ，name 就是网口名称，花括号内为它的配置选项：

* send host-name ：向服务器发送本机的名称。
* send dhcp-lease-time ：告诉服务器请求的 IP 租期，这里设置了 3600 秒。
* request ：请求服务器向客户端发送指定选项的值，通常不用设置，缺省已经请求了很多必要选项。
* require ：列出了必须向服务器发送的选项，以便接收要约，要发送的值用 send 语句设置。没有缺省值。

有了配置文件后，执行 `dhclient` 即可。与 DHCP server 协商成功后，会将获取的 IP 等信息保存到 dhclient.leases 文件，这是 DHCP client 租赁数据库，如果有多条数据，最后一天有效。

    [root@localhost ~]# cat /var/lib/dhclient/dhclient.leases 
    default-duid "\000\001\000\001\037\234\226n\020\013\251\264\231\000";
    lease {
      interface "wlp1s0";
      fixed-address 192.168.1.105;
      option subnet-mask 255.255.255.0;
      option routers 192.168.1.1;
      option dhcp-lease-time 7200;
      option dhcp-message-type 5;
      option domain-name-servers 192.168.1.1;
      option dhcp-server-identifier 192.168.1.1;
      renew 1 2016/10/24 08:59:57;
      rebind 1 2016/10/24 09:51:49;
      expire 1 2016/10/24 10:06:49;
    }

然后 dhclient 会调用 dhclient-script 文件，它的作用修改网口 IP 、修改默认路由、替换 /etc/resolv.conf 文件，还会调用 /etc/dhcp/dhclient.d/ 下的用户自定义脚本，详情可以查看 dhclient-script 的 man 手册。

如果要是否释放 IP ，执行 `dhclient -r` 。

最后补充一点，在目前的 Linux 发行版中，已经有集成化的网卡管理工具，比如 NetworkManager ，可以统一的管理以太网、Wi-Fi、3G等网卡设备，简化了很多步骤，比较方便，当然底层还是调用这些基本的程序。

## 5. 国别代码问题

不同的国家和地区对 Wi-Fi 的合法频段有不同的要求，Wi-Fi 模块都支持设置国别代码，使模块使用合法的频段。可以通过 iw 命令读取当前模块设置的国别代码与合法频段：

```shell
root@localhost:~# iw reg get
country CN: DFS-FCC
	(2402 - 2482 @ 40), (N/A, 20), (N/A)
	(5170 - 5250 @ 80), (N/A, 23), (N/A)
	(5250 - 5330 @ 80), (N/A, 23), (0 ms), DFS
	(5735 - 5835 @ 80), (N/A, 30), (N/A)
	(57240 - 59400 @ 2160), (N/A, 28), (N/A)
	(59400 - 63720 @ 2160), (N/A, 44), (N/A)
	(63720 - 65880 @ 2160), (N/A, 28), (N/A)
```

在 Linux 系统里通常是通过配置文件这种相应的驱动参数：

```shell
root@localhost:~# cat /etc/default/crda
# Set REGDOMAIN to a ISO/IEC 3166-1 alpha2 country code so that iw(8) may set
# the initial regulatory domain setting for IEEE 802.11 devices which operate
# on this system.
#
# Governments assert the right to regulate usage of radio spectrum within
# their respective territories so make sure you select a ISO/IEC 3166-1 alpha2
# country code suitable for your location or you may infringe on local
# legislature. See `/usr/share/zoneinfo/zone.tab' for a table of timezone
# descriptions containing ISO/IEC 3166-1 alpha2 country codes.

REGDOMAIN=CN


root@localhost:~# cat /etc/modprobe.d/iwlwifi.conf
# /etc/modprobe.d/iwlwifi.conf
# iwlwifi will dyamically load either iwldvm or iwlmvm depending on the
# microcode file installed on the system.  When removing iwlwifi, first
# remove the iwl?vm module and then iwlwifi.
remove iwlwifi \
(/sbin/lsmod | grep -o -e ^iwlmvm -e ^iwldvm -e ^iwlwifi | xargs /sbin/rmmod) \
&& /sbin/modprobe -r mac80211
options iwlwifi lar_disable=1


root@localhost:~# cat /etc/modprobe.d/cfg80211.conf
options cfg80211 ieee80211_regdom="CN"
```

## 参考

* <https://wireless.wiki.kernel.org>
* man 手册
