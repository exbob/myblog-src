---
title: "Linux 下使用 ioctl 接口访问指定网卡"
date: 2021-10-26T20:09:49+08:00
draft: false
toc: true
comments: true
images:
tags:
  - untagged


---

[netdevice](https://man7.org/linux/man-pages/man7/netdevice.7.html) 是 glibc 提供的访问网卡设备的低级接口，支持标准 ioctl 函数，需要的头文件是：

```c
#include <sys/ioctl.h>
#include <net/if.h>
```

使用方法是调用 ioctl 函数访问 socket 文件，基本语法是：

```c
ioctl(int fd, int request, struct ifreq *);
```

`int fd` 应该是一个 socket 文件描述符，主要通过 `struct ifreq` 结构传递数据：

```c
struct ifreq
{
    char ifr_name[IFNAMSIZ]; /* Interface name */
    union
    {
        struct sockaddr ifr_addr; // IP 地址
        struct sockaddr ifr_dstaddr;
        struct sockaddr ifr_broadaddr; // 广播地址
        struct sockaddr ifr_netmask;  // 子网掩码
        struct sockaddr ifr_hwaddr;   // MAC 地址
        short ifr_flags;
        int ifr_ifindex;
        int ifr_metric;
        int ifr_mtu;
        struct ifmap ifr_map;
        char ifr_slave[IFNAMSIZ];
        char ifr_newname[IFNAMSIZ];
        char *ifr_data;
    };
};
```

使用方法：

1. 新建一个 AF_INET 地址的 socket 文件
2. 新建一个  `struct ifreq` 结构，并设置 `ifr_name` 为指定的网卡名称，例如 eth0
3. 调用 `ioctl` ，通过 request 指定要访问的信息，通过 `struct ifreq` 结构传递数据
4. 解析 `struct ifreq` 结构。

支持的 request 包括：

* SIOCGIFFLAGS, SIOCSIFFLAGS ：获取、设置网卡的 Flag ，通过 `ifreq->ifr_flags` 传递数据，ifr_flags 包含一个由以下数值组成的位掩码。
    * IFF_UP            Interface is running.
    * IFF_BROADCAST     Valid broadcast address set.
    * IFF_DEBUG         Internal debugging flag.
    * IFF_LOOPBACK      Interface is a loopback interface.
    * IFF_POINTOPOINT   Interface is a point-to-point link.
    * IFF_RUNNING       Resources allocated.
    * IFF_NOARP         No arp protocol, L2 destination address not set.
    * IFF_PROMISC       Interface is in promiscuous mode.
    * IFF_NOTRAILERS    Avoid use of trailers.
    * IFF_ALLMULTI      Receive all multicast packets.
    * IFF_MASTER        Master of a load balancing bundle.
    * IFF_SLAVE         Slave of a load balancing bundle.
    * IFF_MULTICAST     Supports multicast
    * IFF_PORTSEL       Is able to select media type via ifmap.
    * IFF_AUTOMEDIA     Auto media selection active.
    * IFF_DYNAMIC       The addresses are lost when the interface goes down.

* SIOCGIFADDR, SIOCSIFADDR, SIOCDIFADDR ：获取、设置和删除网卡的 IP ，通过 `ifreq->ifr_addr` 传递数据
* SIOCGIFNETMASK, SIOCSIFNETMASK ：获取、设置子网掩码，通过 `ifreq->ifr_netmask` 传递数据

* SIOCGIFBRDADDR, SIOCSIFBRDADDR ：获取、设置广播地址，通过 `ifreq->ifr_broadaddr` 传递数据

* SIOCGIFHWADDR, SIOCSIFHWADDR ：获取、设置 MAC 地址，通过 `ifreq->ifr_hwaddr` 传递数据

* SIOCGIFMTU, SIOCSIFMTU ：获取、设置 MTU ，通过 `ifreq->ifr_mtu` 传递数据

例如 SIOCGIFADDR 可以获得 IP 地址：

```c
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <netinet/in.h>
#include <arpa/inet.h>

int main()
{
    int fd;
    struct ifreq ifr;
    struct in_addr addr;
	
    // 1. 新建一个 socket
    fd = socket(AF_INET, SOCK_DGRAM, 0);
    // 2. 设置网卡名称
    strncpy(ifr.ifr_name, "enp3s0", IFNAMSIZ - 1);
	// 3. 读取指定网卡的 IP
    ioctl(fd, SIOCGIFADDR, &ifr);
	// 4. IP 存放在 ifr.ifr_addr 里
    addr = ((struct sockaddr_in *)&ifr.ifr_addr)->sin_addr;
    // 5. 转换格式，并打印
    printf("ip address is : %s <%08x>\n", inet_ntoa(addr), addr.s_addr);
    
    close(fd);
}
```

编译和执行：

```bash
~# gcc test.c -o test
~# ./test
ip address is : 172.16.1.1 <010110ac>
```

一个完整的例程：

```c
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <net/if.h>
#include <arpa/inet.h>

struct ifinfo_t
{
    struct in_addr addr;  // IP 地址
    struct in_addr netmask;  // 子网掩码
    struct in_addr broadaddr; // 广播地址
    struct in_addr net;  // 网段
    unsigned char  hwaddr[6];  // MAC 地址
    int netmask_len;  // 十进制格式的子网掩码
};

// 获得指定网卡的 IP 信息
int getifinfo(const char *ifname, struct ifinfo_t *ifinfo)
{
    int fd;
    int i;
    int len;
    unsigned int netmask = 0;
    struct ifreq ifr;

    fd = socket(AF_INET, SOCK_DGRAM, 0);
    strncpy(ifr.ifr_name, ifname, IFNAMSIZ - 1);

    ioctl(fd, SIOCGIFADDR, &ifr);
    ifinfo->addr = ((struct sockaddr_in *)&ifr.ifr_addr)->sin_addr;

    ioctl(fd, SIOCGIFNETMASK, &ifr);
    ifinfo->netmask = ((struct sockaddr_in *)&ifr.ifr_netmask)->sin_addr;

    ioctl(fd, SIOCGIFBRDADDR, &ifr);
    ifinfo->broadaddr = ((struct sockaddr_in *)&ifr.ifr_broadaddr)->sin_addr;

    ioctl(fd, SIOCGIFHWADDR, &ifr);
    memcpy(ifinfo->hwaddr, ifr.ifr_hwaddr.sa_data, 6); 

    netmask = ifinfo->netmask.s_addr;
    len = 0;
    for (i = 0; i < 32; i++)
    {
        if (netmask & 0x00000001)
            len++;
        netmask = netmask >> 1;
    }
    ifinfo->netmask_len = len;

    ifinfo->net.s_addr = ifinfo->addr.s_addr & ifinfo->netmask.s_addr;

    close(fd);
    return 0;
}

//判断两个 ip 是否属于同一子网
int issamenet(struct in_addr *addr_1, struct in_addr *addr_2, struct in_addr *netmask)
{
    return (addr_1->s_addr & netmask->s_addr) == (addr_2->s_addr & netmask->s_addr);
}

int main()
{
    struct ifinfo_t ifinfo;
    getifinfo("enp3s0", &ifinfo);

    printf("address : <%08x> %s\n", ifinfo.addr.s_addr, inet_ntoa(ifinfo.addr));
    printf("netmask : <%08x> %s\n", ifinfo.netmask.s_addr, inet_ntoa(ifinfo.netmask));
    printf("hwaddr : %02x:%02x:%02x:%02x:%02x:%02x\n", ifinfo.hwaddr[0],ifinfo.hwaddr[1],ifinfo.hwaddr[2],ifinfo.hwaddr[3],ifinfo.hwaddr[4],ifinfo.hwaddr[5]);
    printf("broadaddr : <%08x> %s\n", ifinfo.broadaddr.s_addr, inet_ntoa(ifinfo.broadaddr));
    printf("net : <%08x> %s\n", ifinfo.net.s_addr, inet_ntoa(ifinfo.net));
    printf("netmask_len : %d\n", ifinfo.netmask_len);

    // 判断两个 IP 是否属于同一个子网
    struct in_addr addr_1;
    struct in_addr addr_2;
    struct in_addr netmask;
    int ret = 0;

    addr_1.s_addr = inet_addr("172.16.144.138");
    addr_2.s_addr = inet_addr("172.16.144.1");
    netmask.s_addr = inet_addr("255.255.255.240");

    ret = issamenet(&addr_1, &addr_2, &netmask);
    printf("ret is %d\n", ret);

    return 0;
}
```

编译和执行：

```bash
~# gcc test.c -o test
~# ./test
address : <010110ac> 172.16.1.1
netmask : <00ffffff> 255.255.255.0
hwaddr : 00:1d:f3:52:99:0c
broadaddr : <ff0110ac> 172.16.1.255
net : <000110ac> 172.16.1.0
netmask_len : 24
ret is 0
```



参考：

- https://man7.org/linux/man-pages/man7/netdevice.7.html

- http://www.microhowto.info/howto/get_the_ip_address_of_a_network_interface_in_c_using_siocgifaddr.html

