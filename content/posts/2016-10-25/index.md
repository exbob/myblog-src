---
title: Linux 3G Module HowTo
date: 2016-10-25T08:00:00+08:00
draft: false
toc: true
comments: true
---



Linux 中 3G 模块的层次结构：

![](./pics_1.jpg)

硬件模块就是 3G 模块，通常通过 USB 总线接入计算机。内核中的 3G 模块驱动可以在应用层生成串行设备，例如 ttyUSB\*、ttyACM\* 等。3G 模块的拨号连接过程遵循 ppp 协议，它提供了通过串行点对点链路传输数据报的方法，Linux 内核集成了 ppp 协议栈，pppd 程序是 ppp 协议在用户空间的守护进程，chat 程序负责通过串行设备与 pppd 之间的通信。

## 1. 硬件和驱动

大部分 3G 模块是挂在 USB 总线上，以 Telit HE910 模块为例，这是一个支持 WCDMA ，即联通 3G 的模块 ：

    [root@localhost ~]# lsusb
    Bus 001 Device 006: ID 09da:0260 A4Tech Co., Ltd. KV-300H Isolation Keyboard
    Bus 001 Device 005: ID 0424:2514 Standard Microsystems Corp. USB 2.0 Hub
    Bus 001 Device 004: ID 1bc7:0021 Telit Wireless Solutions HE910

Linux 系统包含一个通用的 USB 驱动 CDC_ACM，很多 3G 模块都用它来驱动，HE910 就是这样。驱动加载成功后会创建多个 tty 设备文件，其中两个比较重要：

* /dev/ttyACM0: PPP 连接和 AT 指令的通用接口
* /dev/ttyACM3: AT 指令接口

不同的模块所用驱动可能不同，具体情况要查看模块的使用手册。Linux 内核要支持 ppp 协议，这已经是现在 Linux 的默认配置。

## 2. AT 指令

对 3G 模块执行 AT 指令用很多方式，最简单的是用 cat 和 echo 命令。例如，在一个终端执行 `cat < /dev/ttyACM3`，它会持续监听该端口的返回信息，然后在另一个终端用 echo 向 /dev/ttyACM3 发送 AT 指令，在 cat 中就可以看到返回：

    #Terminal 1
    [root@localhost ~]# cat < /dev/ttyACM3 
    OK
    
    #Terminal 2
    [root@localhost ~]# echo -en "AT\r" > /dev/ttyACM3

常用的是 minicom ，可以用于交互调试：

    [root@localhost ~]# minicom -D /dev/ttyACM3 -b 115200
    Welcome to minicom 2.7                                                                         
    OPTIONS: I18n                                                                                  
    Compiled on Aug 17 2014, 17:34:01.                                                             
    Port /dev/ttyACM3, 15:39:12                                                                    
    Press CTRL-A Z for help on special keys                                                        
                                                                                                   
    AT                                                                                             
    OK                                                                                             
    ATZ                                                                                            
    OK                                                                                             
    AT+CSQ                                                                                         
    +CSQ: 3,3                                                                                      

还用一个纯命令行工具 comgt ，可以很方便的集成到其他程序中，还支持脚本执行一系列 AT 指令，完成复杂的功能。一般 Linux 系统都没有安装，需要下载编译：<https://sourceforge.net/projects/comgt/> 。 这有我写的一篇文档：<http://shaocheng.li/post/blog/2015-09-09>

AT 指令分为两部分，一部分是通用标准的指令，各个模块都一样；另一部分是各厂商为自家模块自定义的扩展指令，详细信息可以查看模块的 AT 指令手册。以 HE910 为例，介绍几个常用指令。

* ATZ ，软重启 3G 模块。

* AT+CGMI ，读取模块厂商：

        AT+CGMI
        Telit
    
* AT+CGMM ，读取模块名称：

        AT+CGMM
        HE910-D

* AT+CGSN ，读取模块的 IMEI：

        AT+CGSN
        351579053301782

* AT+CGMR ，读取模块的固件版本：

        AT+CGMR"
        12.00.024

* AT+CIMI ，查询 IMSI 。IMSI 是国际移动用户识别码，储存在 SIM 卡中，每张 SIM 卡都不一样，通常是十五位数字，由三段组成。前三位是国家代码（MCC，中国是 460）。之后的两位或者三位是移动网络代码（MNC)，用于标识不同的运营商网络，中国移动使用 00、02、07（不同的号码可以区分不同的号段），中国联通使用 01、06、09，中国电信使用 03、05、11，更多的可以查看[这里](https://en.wikipedia.org/wiki/Mobile_country_code)。最后是用户识别码（MSIN），由运营商自定义。

        AT+CIMI
        460019048517149
         
* AT+CSQ ，获取信号强度，信号强度与是否插 SIM 卡无关：

        AT+CSQ
        +CSQ: 15,1  
        
    第一个数字表示信号轻度，取值0~31，数字越大信号越好，99 表示未知或不可检测，换算方式： CSQ 值=（接收信号强度 dBm + 113）/2 ：
    
    ![](~/14-31-06.jpg)
    
* AT+CPIN? ，可以用来查看 SIM 卡是否插好，插好会返回 READY ：

        AT+CPIN?
        +CPIN: READY
        OK
        
* AT+CNUM ，查看电话号码，前提是号码已经存储在 SIM 中 ：

        AT+CNUM
        +CNUM: "","+8618589041260",145        
        OK
   
* AT+WS46=[<n>] ，选择无线网络,三个数字分别是 2G only、3G only、3G first 。

![](./pics_2.jpg)

* AT#PSNT? ，查询当前的网络类型，返回的数据格式是 `#PSNT: <mode>,<nt>` ：

        AT#PSNT?
        #PSNT: 0,3
        
        OK
        
    数据的含义：
        
        <mode>
            0 - PSNT unsolicited result code disabled
            1 - PSNT unsolicited result code enabled
        <nt> - network type
            0 - GPRS network
            1 - EGPRS network
            2 - WCDMA network
            3 - HSDPA network
            4 - unknown or not registered.

* AT#RFSTS ，读取当前的网络状态，数据比较多，具体含义需要查看手册：

        AT#RFSTS
        #RFSTS: "460 01",10713,64,-4.5,-89,-80,A53F,02,-128,64,19,4,2,,17030E9,"460010892513284","CHN-UNICOM",3,0
        
        OK
    

AT 指令可能返回错误代码，下面常见错误代码的含义：

    CME ERROR: 0	Phone failure
    CME ERROR: 1	No connection to phone
    CME ERROR: 2	Phone adapter link reserved
    CME ERROR: 3	Operation not allowed
    CME ERROR: 4	Operation not supported
    CME ERROR: 5	PH_SIM PIN required
    CME ERROR: 6	PH_FSIM PIN required
    CME ERROR: 7	PH_FSIM PUK required
    CME ERROR: 10	SIM not inserted
    CME ERROR: 11	SIM PIN required
    CME ERROR: 12	SIM PUK required
    CME ERROR: 13	SIM failure
    CME ERROR: 14	SIM busy
    CME ERROR: 15	SIM wrong
    CME ERROR: 16	Incorrect password
    CME ERROR: 17	SIM PIN2 required
    CME ERROR: 18	SIM PUK2 required
    CME ERROR: 20	Memory full
    CME ERROR: 21	Invalid index
    CME ERROR: 22	Not found
    CME ERROR: 23	Memory failure
    CME ERROR: 24	Text string too long
    CME ERROR: 25	Invalid characters in text string
    CME ERROR: 26	Dial string too long
    CME ERROR: 27	Invalid characters in dial string
    CME ERROR: 30	No network service
    CME ERROR: 31	Network timeout
    CME ERROR: 32	Network not allowed, emergency calls only
    CME ERROR: 40	Network personalization PIN required
    CME ERROR: 41	Network personalization PUK required
    CME ERROR: 42	Network subset personalization PIN required
    CME ERROR: 43	Network subset personalization PUK required
    CME ERROR: 44	Service provider personalization PIN required
    CME ERROR: 45	Service provider personalization PUK required
    CME ERROR: 46	Corporate personalization PIN required
    CME ERROR: 47	Corporate personalization PUK required
    CME ERROR: 48	PH-SIM PUK required
    CME ERROR: 100	Unknown error
    CME ERROR: 103	Illegal MS
    CME ERROR: 106	Illegal ME
    CME ERROR: 107	GPRS services not allowed
    CME ERROR: 111	PLMN not allowed
    CME ERROR: 112	Location area not allowed
    CME ERROR: 113	Roaming not allowed in this location area
    CME ERROR: 126	Operation temporary not allowed
    CME ERROR: 132	Service operation not supported
    CME ERROR: 133	Requested service option not subscribed
    CME ERROR: 134	Service option temporary out of order
    CME ERROR: 148	Unspecified GPRS error
    CME ERROR: 149	PDP authentication failure
    CME ERROR: 150	Invalid mobile class
    CME ERROR: 256	Operation temporarily not allowed
    CME ERROR: 257	Call barred
    CME ERROR: 258	Phone is busy
    CME ERROR: 259	User abort
    CME ERROR: 260	Invalid dial string
    CME ERROR: 261	SS not executed
    CME ERROR: 262	SIM Blocked
    CME ERROR: 263	Invalid block
    CME ERROR: 527	Please wait, and retry your selection later (Specific Modem Sierra)
    CME ERROR: 528	Location update failure – emergency calls only (Specific Modem Sierra)
    CME ERROR: 529	Selection failure – emergency calls only (Specific Modem Sierra)
    CME ERROR: 772	SIM powered down

## 3. pppd

pppd 是 ppp 协议的守护进程，全称点对点协议守护进程。它的 man 手册提供了详细使用说明，这里有中文版：<https://docs.oracle.com/cd/E56344_01/html/E54077/pppd-1m.html> 。语法是：

    pppd [option]
    
常用的选项：

* *tty_name* ：指定用于 ppp 拨号的串行设备，通常是 /dev/ 目录下的 tty 设备，对于 HE910 应该设为 /dev/ttyACM0 。
* *speed* : 指定串口波特率，十进制数，常用的有9600、19200、115200、460800。
* damand ：仅在有数据通信时启动链路，该选项隐含了 persist 选项。
* persist ：连接终止后程序不退出，并尝试重新打开连接，也就是掉线重连。
* debug ：启用连接调试工具。如果指定了此选项，则 pppd 将以可阅读格式记录所发送或接收的所有控制包的内容。
* dump ：指定此选项后，pppd 会打印所有已经设置的选项的值。
* crtscts ：使用硬件流量控制（即 RTS/CTS）来控制串行端口上的数据流。
* lock ：为串行设备加锁，确保对设备的独占访问。
* user *username* ：向对等方证明身份的用户名。
* password *password* ： 向对等方证明身份的密码。
* defaultroute ：拨号成功完成时，向系统路由表添加一个缺省路由。
* usepeerdns ：向对等方请求最多两个 DNS 服务器地址。
* nodetach ：设置该选项后，pppd 将保持前台运行，默认是后台运行。
* logfile *filename* ：将日志信息附加到文件 filename 。
* connect *script* ：使用由 script 指定的可执行文件或 shell 命令来设置串行设备。此脚本通常将使用 chat(1M) 程序拨打调制解调器并启动远程 PPP 会话。
* disconnect *script* ：在 pppd 终止链路后，运行由 script 指定的可执行文件或 shell 命令。
* call *filename* ：从 /etc/ppp/peers/ 下的 filename 文件中读取选项。上面这些选项可以在执行命令是设置，也可以放在 /etc/ppp/peers/ 目录下的自定义配置文件中，用 call 选项调用。
* local_IP_address:remote_IP_address : 设置本地和/或远程接口 IP 地址。两者都可以省略，但冒号是必需的。IP 地址可以通过主机名来指定，也可以通过十进制点记法来指定，例如：:10.1.2.3。缺省本地地址是系统的第一个 IP 地址，除非提供了 noipdefault 选项。如果未在任何选项中指定远程地址，则将从对等方获取远程地址。因此，在简单情况下，此选项不是必需的。如果通过此选项指定了本地和/或远程 IP 地址，则 pppd 在 IPCP 协商中将不会接受来自对等方的不同值，除非分别指定了 ipcp-accept-local 和/或 ipcp-accept-remote 选项。
* noipdefault : 禁用未指定本地 IP 地址时的缺省行为，即通过主机名确定本地 IP 地址（如果可行）。指定了此选项时，对等方在 IPCP 协商期间必须提供本地 IP 地址（除非在命令行上或选项文件中显式指定了该地址）。未指定该选项时，可能被设置缺省地址，而导致拨号失败，比如`sent [IPCP ConfReq id=0x2 <addr 192.168.199.152> <ms-dns1 0.0.0.0> <ms-dns2 0.0.0.0>]` 。

在 /etc/ppp/peers/ 下新建一个配置文件，命名为 wcdma ，内容如下：

    /dev/ttyACM0
    115200
    dump
    debug
    lcp-echo-failure 3
    lcp-echo-interval 3
    # user "card"
    # password "card"
    defaultroute
    ipcp-accept-local
    ipcp-accept-remote
    crtscts
    usepeerdns
    novj
    nobsdcomp
    novjccomp
    nopcomp
    noaccomp
    lock
    show-password
    logfile /var/log/pppd.log
    connect "/usr/sbin/chat -v -f /etc/ppp/peers/he910_connect"
    
对于 user 和 password ，电信 3G 是有用户名和密码的，移动和联通为空，所以最好不要设置，可以用井号注释掉，曾经遇到过随意设置这两个值后，连接被拒绝的情况。最后启动连接用的是 chat ，负责与 3G 模块的串口通信，拨打运营商的调制解调器，目的是建立 pppd 守护进程和远程 pppd 进程之间的连接，如果程序执行错误，会返回错误状态代码，代码的含义可以在 man 手册中查找。chat 通过 -f 选项指定一个脚本，脚本的内容就是执行一些 AT 指令设置拨号相关参数。这个脚本如何设置也可以在模块软件手册里找到，以 HE910 为例：

    [root@localhost ppp]# cat /etc/ppp/peers/he910_connect 
    #!/bin/sh
    # init
    TIMEOUT 30
    "" ATZ
    # Connection to the network
    '' AT+CGDCONT=1,"IP","3gnet"
    # Dial the number.
    OK ATD*99#
    # The modem is waiting for the following answer
    CONNECT ''

* AT+CGDCONT 指令是设置拨号的各项参数，第二个参数是设置 PDP 类型，IP 表示  Internet Protocol ；第三个参数是设置 APN （接入点名称），由运营商决定。
* ATD 指令是设置拨号号码，这个值由运营商决定。
* CONNECT 指令表示开始拨号，并等待回应。

下面是针对不同运营商的各项参数设置列表：

| 运营商（ISP）| APN | 拨号号码 | 用户名 | 密码 |
| ------ | ------ | ------ | ------ | ------ |
| 中国联通 WCDMA (China Unicom) | 3GNET | *99# | 空 | 空 |
| 中国电信 CDMA2000 (China Telecom) EVDO网络 | 空 | #777 | ctnet@mycdma.cn | vnet.mobi |
| 中国移动 TD-SCDMA (China Mobile) | CMNET | *98*1# | 空 | 空 |
| 中国移动 GPRS (China Mobile) | CMNET | \*99***1# | 空 | 空 |

> 4G 模块拨号的设置都没有用户名和密码，拨号号码都用 *99# ，在拨号前要初始化模块，使用 AT^SYSCFG 或者 AT^SYSCFGEX 指令将网络连接顺序设为 LTE 优先。

设置完毕后，执行 `pppd call wcdma` ，程序会自动到 /etc/ppp/peers/ 目录下调用名为 wcdma 配置文件，然后开始拨号，整个过程可以在日志文件中查看。拨号成功后会获得 IP 和 DNS ，DNS 保存在 /var/run/ppp/resolv.conf 文件中。之后会调用 /etc/ppp/ip-up 脚本文件 ：

    [root@localhost ppp]# cat /etc/ppp/ip-up
    #!/bin/bash
    # This file should not be modified -- make local changes to
    # /etc/ppp/ip-up.local instead
    
    PATH=/sbin:/usr/sbin:/bin:/usr/bin
    export PATH
    
    LOGDEVICE=$6
    REALDEVICE=$1
    
    [ -f /etc/sysconfig/network-scripts/ifcfg-${LOGDEVICE} ] && /etc/sysconfig/network-scripts/ifup-post --realdevice ${REALDEVICE} ifcfg-${LOGDEVICE}
    
    /etc/ppp/ip-up.ipv6to4 ${LOGDEVICE}
    
    [ -x /etc/ppp/ip-up.local ] && /etc/ppp/ip-up.local "$@"
    
    exit 0

这个脚本先执行了 ifup-post 脚本，作用是配置 IP ，默认路由等网络参数。然后执行了 ip-up.local 脚本，该脚本通常不存在，可以将 /usr/share/doc/ppp/scripts/ip-up.local.add 复制过来改名，这个脚本的作用是，如果在执行 pppd 时设置了 usepeerdns ，就用 /var/run/ppp/resolv.conf 替换当前的 DNS 。

    [root@localhost ppp]# cat ip-up.local.add 
    
    #
    # This sample code shows you one way to modify your setup to allow automatic
    # configuration of your resolv.conf for peer supplied DNS addresses when using
    # the `usepeerdns' option.
    #
    # In my case I just added this to my /etc/ppp/ip-up.local script. You may need to 
    # create an executable script if one does not exist.
    #
    # Nick Walker (nickwalker@email.com)
    #
    . /etc/sysconfig/network-scripts/network-functions
    
    if [ -n "$USEPEERDNS" -a -f /var/run/ppp/resolv.conf ]; then
            rm -f /var/run/ppp/resolv.prev
            if [ -f /etc/resolv.conf ]; then
                    cp /etc/resolv.conf /var/run/ppp/resolv.prev
                    rscf=/var/run/ppp/resolv.new
                    grep domain /var/run/ppp/resolv.prev > $rscf
                    grep search /var/run/ppp/resolv.prev >> $rscf
                    if [ -f /var/run/ppp/resolv.conf ]; then
                            cat /var/run/ppp/resolv.conf >> $rscf
                    fi
                    change_resolv_conf $rscf
                    rm -f $rscf
            else
                    change_resolv_conf /var/run/ppp/resolv.conf
            fi
    fi
    
## 4. wvdial

wvdial 是一个智能 ppp 拨号工具，替换了 chat ，简化了拨号的步骤，可以一步实现拨号、启动 pppd 、最终连接互联网。它带有一个配置工具 wvdialconf ，用于探测当前系统中 3G 模块的串口，然后生成一个配置文件 /etc/wvdial.conf 。还是以 HE910 为例，生成的配置文件：

    [root@localhost ~]# cat /etc/wvdial.conf 
    [Dialer Defaults]
    Init2 = ATQ0 V1 E1 S0=0 &C1 &D2 +FCLASS=0
    Modem Type = USB Modem
    ; Phone = <Target Phone Number>
    ISDN = 0
    ; Username = <Your Login Name>
    Init1 = ATZ
    ; Password = <Your Password>
    Modem = /dev/ttyACM0
    Baud = 460800

只需要修改账号、密码和拨号号码即可，注意要把前面的分号去掉：

    [root@localhost ~]# cat /etc/wvdial.conf 
    [Dialer Defaults]
    Init2 = ATQ0 V1 E1 S0=0 &C1 &D2 +FCLASS=0
    Modem Type = USB Modem
    Phone = *99#
    ISDN = 0
    Username = "card"
    Init1 = ATZ
    Password = "card"
    Modem = /dev/ttyACM0
    Baud = 460800 


配置文件的其他选项可以查看 wvdial.conf 的 man 手册，这些参数最终会传递给 pppd 。然后执行 wvdial ：

    [root@localhost ~]# wvdial         
    --> WvDial: Internet dialer version 1.61
    --> Initializing modem.
    --> Sending: ATZ
    ATZ
    OK
    --> Sending: ATQ0 V1 E1 S0=0 &C1 &D2 +FCLASS=0
    ATQ0 V1 E1 S0=0 &C1 &D2 +FCLASS=0
    OK
    --> Modem initialized.
    --> Sending: ATDT*99#
    --> Waiting for carrier.
    ATDT*99#
    CONNECT
    --> Carrier detected.  Waiting for prompt.
    ~[7f]}#@!}!}!} }8}"}&} } } } }#}$@#}%}&_}8[14][14]}'}"}(}"[1f]P~
    --> PPP negotiation detected.
    --> Starting pppd at Thu Nov  3 17:36:51 2016
    --> Pid of pppd: 3393
    --> Using interface ppp0
    --> local  IP address 10.228.54.19
    --> remote IP address 10.228.54.19
    --> primary   DNS address 210.21.196.6
    --> secondary DNS address 221.5.88.88

默认会自动设置 default route 和 DNS 。如果没有自动替换 DNS ，应该是没有 /etc/ppp/ip-up.local 文件，可以复制一个过来。查看 pppd 进程，看看都执行了哪些参数：

    [root@localhost ~]# ps -ef | grep pppd
    root       955   954  0 09:02 pts/1    00:00:00 /usr/sbin/pppd 460800 modem crtscts defaultroute usehostname -detach user card noipdefault call wvdial usepeerdns idle 0 logfd 6 remotename 0
    root       982   799  0 09:03 pts/0    00:00:00 grep --color=auto pppd
    [root@localhost ~]# route
    Kernel IP routing table
    Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
    default         0.0.0.0         0.0.0.0         U     0      0        0 ppp0
    192.168.5.0     0.0.0.0         255.255.255.0   U     0      0        0 enp4s0

这个程序是前台运行的，用 Ctrl-C 键可以退出。
