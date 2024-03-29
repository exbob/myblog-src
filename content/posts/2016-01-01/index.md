---
title: hostapd HOWTO
date: 2016-01-01T08:00:00+08:00
draft: false
toc:
comments: true
---



## 1. About

hostapd 是一个运行在 Linux 用户空间的 daemon 程序，它可以将 IEEE 802.11 无线网卡切换为 AP 模式，也就是实现软 AP 功能，并提供 IEEE 802.1X/WPA/WPA2/EAP/RADIUS 的认证服务。它使用 nl80211 接口与内核进行通信，支持基于 mac80211 框架的无线驱动。下面是 Linux 的无线网络架构：

![](./pics_1.jpg)

* IEEE 802.11 是现在的无线局域网通用的标准，我们通常把它与 Wi-Fi 混为一谈。
* mac80211 是 Linux 内核的 802.11 无线设备驱动框架，intel 的无线网卡驱动 iwlwifi 就是基于这个框架。
* cfg80211 是 Linux 内核中配置和管理 802.11 无线设备的接口，与 FullMAC 驱动, mac80211 驱动一起工作。
* nl80211 和 wext 是两种面向用户空间的接口标准，用于在用户空间配置和管理 802.11 无线设备，内核的 cfg80211 一起工作，目前两种标准同时存在于内核中，nl80211 正在逐步替代 wext ，hostapd 只支持 nl80211 。

iw 就是一个使用 nl80211 接口的命令，用它可以查看和配置无线网卡，支持 nl80211 标准，不支持老的 wext 标准。用 `iw list` 可以获取当前无线网卡的全部特性，在 Supported interface modes 和 software interface modes 中看到无线网卡是否支持 AP 模式，已经 AP 类型：

    root@WR-IntelligentDevice:~# iw list
    Wiphy phy0
        ......
        Supported interface modes:
                 * IBSS
                 * managed
                 * AP
                 * AP/VLAN
                 * monitor
                 * P2P-client
                 * P2P-GO
        software interface modes (can always be added):
                 * AP/VLAN
                 * monitor
         ......
 
 用 ethtool 工具可以确定网卡使用的驱动：
 
    root@WR-IntelligentDevice:~# ethtool -i wlan0
    driver: iwlwifi
    version: 3.4.91-WR5.0.1.24_standard_IDP-
    firmware-version: 18.168.6.1
    bus-info: 0000:01:00.0
    supports-statistics: yes
    supports-test: no
    supports-eeprom-access: no
    supports-register-dump: no
    supports-priv-flags: no    

查看连接在 AP 上的终端：

    root@WR-IntelligentDevice:~# iw dev wlan0 station dump 
    Station bc:6c:21:6e:04:c3 (on wlan0)
            inactive time:  20 ms
            rx bytes:       159304
            rx packets:     2076
            tx bytes:       4368817
            tx packets:     3068
            tx retries:     293
            tx failed:      2
            signal:         -41 dBm
            signal avg:     -40 dBm
            tx bitrate:     54.0 MBit/s
            authorized:     yes
            authenticated:  yes
            preamble:       short
            WMM/WME:        no
            MFP:            no
            TDLS peer:              no
            
## 2. 配置

hostapd 的配置文件是 /etc/hostapd.conf ，这个文件里有详细的配置说明，下面是一些常用选项。

### 2.1. 无线接口

* interface：无线网卡的设备节点名称，就是 iwconfig 看到的名称，例如 wlan0 。
* bridge：指定所处网桥，对于一个同时接入公网、提供内部网和无线接入的路由器来说，设定网桥很有必要 。
* driver：设定无线驱动，我这里是 nl80211 。

### 2.2. 无线环境

* ssid：这个无线接入点对外显示的名称 。
* hw_mode：指定802.11协议，a = IEEE 802.11a, b = IEEE 802.11b, g = IEEE 802.11g 。这个选项是根据硬件特性设置的，g 是最常用的设置，它向下兼容 b 。
* channel：设定信道，必须是 hw_mode 指定协议能够支持的信道。信道的选择应该避免与同区域内的其他 AP 的信道产生重叠，这与 802.11 标准的信道划分有关，在 802.11b/g 中，83.5MHz 的带宽划分了 14 个信道，相邻的多个信道存在频率重叠，整个频段内只有 1、6、11 ，三个信道互不干扰。

![](./pics_2.jpg)

### 2.3. 认证与加密

* ignore_broadcast_ssid: 使能/禁止广播 SSID 。
* macaddr_acl：可选，指定 MAC 地址过滤规则，0 表示除禁止列表外都允许，1 表示除允许列表外都禁止，2 表示使用外部 RADIUS 服务器。
* accept_mac_file：指定 MAC 允许列表文件路径。
* deny_mac_file：指定 MAC 禁止列表文件路径。
* auth_algs: 指定认证算法，低两位有效，0 表示禁止，1 表示使能。bit0 表示开放系统认证（OSA），bit1 表示共享密钥认证（SKA），如果设为 3 ，表示两种认证方式都支持。
* wpa: 指定加密算法，低两位有效，0 表示禁止，1 表示使能。bit0 表示 wpa，bit1 表示 wpa2 ，如果设为 3 ，表示 WPA/WPA2 加密方式。
* wpa_passphrase: 共享秘钥，就是我们连接 Wi-Fi 时输入的密码。
* wpa_psk：对共享秘钥加密后的 64 位十六进制数。可以通过 wpa_passphrase 命令获得：

        root@WR-IntelligentDevice:~# wpa_passphrase             
        usage: wpa_passphrase <ssid> [passphrase]
        
        If passphrase is left out, it will be read from stdin
        root@WR-IntelligentDevice:~# wpa_passphrase  TP-Link  password
        network={
            ssid="TP-Link"
            #psk="password"
            psk=895b209c4c7ff1ea45d079eb5b04155cc1793669c6dc08470157c23fa6532694
        }
    
* wpa_key_mgmt: 指定秘钥管理算法，可选 WPA-PSK 和 WPA-EAP 。
* wpa_pairwise: WPA 的加密选项，可选 TKIP 和 CCMP 。
* rsn_pairwise: WPA2 和 RSN 的加密选项，可选 TKIP 和 CCMP 。

关于认证算法：

* 开放系统认证（Open system authentication）

    开放系统认证是缺省使用的认证机制，也是最简单的认证算法，即不认证。如果认证类型设置为开放系统认证，则所有请求认证的客户端都会通过认证。开放系统认证包括两个步骤：第一步是无线客户端发起认证请求，第二步AP确定无线客户端是否通过无线链路认证并回应认证结果。如果认证结果为“成功”，那么客户端成功通过了AP的链路认证。
 
    ![](~/10-32-32.jpg)

* 共享密钥认证（shared key authentication）

    共享密钥认证是除开放系统认证以外的另外一种链路认证机制。共享密钥认证需要客户端和设备端配置相同的共享密钥。共享密钥认证的认证过程为：客户端先向AP发送认证请求，AP端会随机产生一个Challenge（即一个字符串）发送给客户端；客户端会将接收到Challenge加密后再发送给AP；AP接收到该消息后，对该消息解密，然后对解密后的字符串和原始字符串进行比较。如果相同，则说明客户端通过了Shared Key链路认证；否则Shared Key链路认证失败。

    ![](~/10-33-09.jpg)

## 3. 运行

    root@WR-IntelligentDevice:/etc# hostapd -h
    hostapd v2.3
    User space daemon for IEEE 802.11 AP management,
    IEEE 802.1X/WPA/WPA2/EAP/RADIUS Authenticator
    Copyright (c) 2002-2014, Jouni Malinen <j@w1.fi> and contributors
    
    usage: hostapd [-hdBKtv] [-P <PID file>] [-e <entropy file>] \
             [-g <global ctrl_iface>] [-G <group>] \
             <configuration file(s)>
    
    options:
       -h   show this usage
       -d   show more debug messages (-dd for even more)
       -B   run daemon in the background
       -e   entropy file
       -g   global control interface path
       -G   group for control interfaces
       -P   PID file
       -K   include key data in debug messages
       -t   include timestamps in some debug messages
       -v   show hostapd version

 分享一个在 Ubuntu 12.04 下设置无线 AP 的脚本 [install_wifi_access_point.sh](https://gist.github.com/dashohoxha/5767262) ，内容如下：
 
    #!/bin/bash
    ### Setup a wifi Access Point on Ubuntu 12.04 (or its derivatives).
    
    ### make sure that this script is executed from root
    if [ $(whoami) != 'root' ]
    then
        echo "
    This script should be executed as root or with sudo:
        sudo $0
    "
        exit 1
    fi
    
    ##############################################################
    ## Check whether the wireless card supports Access Point mode
    ##############################################################
    
    ### make sure that iw is installed
    apt-get -y install iw
    
    ### check that AP is supported
    supports_access_point=$(iw list | sed -n -e '/* AP$/p')
    if [ "$supports_access_point" = '' ]
    then
        echo "AP is not supported by the driver of the wireless card."
        echo "This script does not work for this driver."
        exit 1
    fi
    
    ##############################################################
    ##  Setup and host a network
    ##############################################################
    
    ### install hostapd
    apt-get -y install hostapd
    
    ### it should not start automatically on boot
    update-rc.d hostapd disable
    
    ### get ssid and password
    ssid=$(hostname --short)
    read -p "The name of your hosted network (SSID) [$ssid]: " input
    ssid=${input:-$ssid}
    password='1234567890'
    read -p "The password of your hosted network [$password]: " input
    password=${input:-$password}
    
    ### get wifi interface
    rfkill unblock wifi   # enable wifi in case it is somehow disabled (thanks to Darrin Wolf for this tip)
    wifi_interface=$(lshw -quiet -c network | sed -n -e '/Wireless interface/,+12 p' | sed -n -e '/logical name:/p' | cut -d: -f2 | sed -e 's/ //g')
    
    ### create /etc/hostapd/hostapd.conf
    cat <<EOF > /etc/hostapd/hostapd.conf
    interface=$wifi_interface
    driver=nl80211
    ssid=$ssid
    hw_mode=g
    channel=1
    macaddr_acl=0
    auth_algs=1
    ignore_broadcast_ssid=0
    wpa=3
    wpa_passphrase=$password
    wpa_key_mgmt=WPA-PSK
    wpa_pairwise=TKIP
    rsn_pairwise=CCMP
    EOF
    
    ### modify /etc/default/hostapd
    cp -n /etc/default/hostapd{,.bak}
    sed -i /etc/default/hostapd \
        -e '/DAEMON_CONF=/c DAEMON_CONF="/etc/hostapd/hostapd.conf"'
    
    ################################################
    ## Set up DHCP server for IP address management
    ################################################
    
    ### make sure that the DHCP server is installed
    apt-get -y install isc-dhcp-server
    
    ### it should not start automatically on boot
    update-rc.d isc-dhcp-server disable
    
    ### set the INTERFACES on /etc/default/isc-dhcp-server
    cp -n /etc/default/isc-dhcp-server{,.bak}
    sed -i /etc/default/isc-dhcp-server \
        -e "/INTERFACES=/c INTERFACES=\"$wifi_interface\""
    
    ### modify /etc/dhcp/dhcpd.conf
    cp -n /etc/dhcp/dhcpd.conf{,.bak}
    sed -i /etc/dhcp/dhcpd.conf \
        -e 's/^option domain-name/#option domain-name/' \
        -e 's/^option domain-name-servers/#option domain-name-servers/' \
        -e 's/^default-lease-time/#default-lease-time/' \
        -e 's/^max-lease-time/#max-lease-time/'
    
    sed -i /etc/dhcp/dhcpd.conf \
        -e '/subnet 10.10.0.0 netmask 255.255.255.0/,+4 d'
    cat <<EOF >> /etc/dhcp/dhcpd.conf
    subnet 10.10.0.0 netmask 255.255.255.0 {
            range 10.10.0.2 10.10.0.16;
            option domain-name-servers 8.8.4.4, 208.67.222.222;
            option routers 10.10.0.1;
    }
    EOF
    
    #################################################
    ## Create a startup script
    #################################################
    
    cat <<EOF > /etc/init.d/wifi_access_point
    #!/bin/bash
    
    ext_interface=\$(ip route | grep default | cut -d' ' -f5)
    
    function stop_wifi_ap {
        ### stop services dhcpd and hostapd
        service isc-dhcp-server stop
        service hostapd stop
    
        ### disable IP forwarding
        echo 0 > /proc/sys/net/ipv4/ip_forward
        iptables -t nat -D POSTROUTING -s 10.10.0.0/16 -o \$ext_interface -j MASQUERADE 2>/dev/null
        
        ### remove the static IP from the wifi interface
        if grep -q 'auto $wifi_interface' /etc/network/interfaces
        then
            sed -i /etc/network/interfaces -e '/auto $wifi_interface/,\$ d'
            sed -i /etc/network/interfaces -e '\$ d'
        fi
    
        ### restart network manager to takeover wifi management
        service network-manager restart
    }
    
    function start_wifi_ap {
        stop_wifi_ap
        sleep 3
    
        ### see: https://bugs.launchpad.net/ubuntu/+source/wpa/+bug/1289047/comments/8
        nmcli nm wifi off
        rfkill unblock wlan
    
        ### give a static IP to the wifi interface
        ip link set dev $wifi_interface up
        ip address add 10.10.0.1/24 dev $wifi_interface
    
        ### protect the static IP from network-manger restart
        echo >> /etc/network/interfaces
        echo 'auto $wifi_interface' >> /etc/network/interfaces
        echo 'iface $wifi_interface' inet static >> /etc/network/interfaces
        echo 'address 10.10.0.1' >> /etc/network/interfaces
        echo 'netmask 255.255.255.0' >> /etc/network/interfaces
    
        ### enable IP forwarding
        echo 1 > /proc/sys/net/ipv4/ip_forward
        iptables -t nat -A POSTROUTING -s 10.10.0.0/16 -o \$ext_interface -j MASQUERADE
    
        ### start services dhcpd and hostapd
        service hostapd start
        service isc-dhcp-server start
    }
    
    ### start/stop wifi access point
    case "\$1" in
        start) start_wifi_ap ;;
        stop)  stop_wifi_ap  ;;
    esac
    EOF
    
    chmod +x /etc/init.d/wifi_access_point
    
    ### make sure that it is stopped on boot
    sed -i /etc/rc.local \
        -e '/service wifi_access_point stop/ d'
    sed -i /etc/rc.local \
        -e '/^exit/ i service wifi_access_point stop'
    
    
    ### display usage message
    echo "
    ======================================
    
    Wifi Access Point installed.
    
    You can start and stop it with:
        service wifi_access_point start
        service wifi_access_point stop
    
    "

## 4. 参考

* <https://wireless.wiki.kernel.org/en/users/Documentation/hostapd>
* <http://blog.csdn.net/myarrow/article/details/7930131>
* <http://www.cnblogs.com/zhuwenger/archive/2011/03/11/1980294.html>
* <https://github.com/hotice/AP-Hotspot>
