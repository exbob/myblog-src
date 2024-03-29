---
title: iptables 学习笔记
date: 2018-12-12T08:00:00+08:00
draft: false
toc:
comments: true
---


关于 iptables 的原理，这里有一份教程写得深入浅出，浅显易懂：

* [iptables 详解](http://www.zsythink.net/archives/1199)

![](./pics/2018-12-12_1.png)


常用的命令可以参考参考 [iptables 手册](https://linux.die.net/man/8/iptables)

下面记录一些常见的 iptables 应用场景。

## 1. IP 转发

IP 转发也可以叫做路由转发，用于连接两个不同的网段，做软路由时经常用到，如下是一个应用场景的网络拓扑：

![](./pics/2018-12-12_2.png)

中间的路由器上是 Linux 系统，有两张网卡，eth0 作为 LAN 口连接内网，wan 作为 WAN 口连接公网。要实现软路由功能，使内网的设备可以通过 WAN 口上网。首先需要开启内核的 IP 转发功能，可以用 sysctl 命令或者直接查看 `/proc/sys/net/ipv4/ip_forward` 文件获得当前系统的 ip_forward 是否开启：

```
~# sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 0
~# cat /proc/sys/net/ipv4/ip_forward
0
```

Linux 系统默认是禁止 IP 转发的，所有返回 0 ，可以用 sysctl 命令或者直接向 `/proc/sys/net/ipv4/ip_forward` 文件写 1 来开启 IP 转发，如果要永久开启，可以在 `/etc/sysctl.conf` 文件中修改配置：

```
~# cat /etc/sysctl.conf | grep ip_forward
net.ipv4.ip_forward=1
```

然后在 iptables 中添加规则：

```
# Default policy to drop all incoming packets
iptables -P INPUT DROP
iptables -P FORWARD DROP

# Accept incoming packets from localhost and the LAN interface
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -i eth0 -j ACCEPT

# Accept incoming packets from the WAN if the router initiated the connection
iptables -A INPUT -i wan -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Forward LAN packets to the WAN
iptables -A FORWARD -i eth0 -o wan -j ACCEPT

# Forward WAN packets to the LAN if the LAN initiated the connection
iptables -A FORWARD -i wan -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# NAT traffic going out the WAN interface
iptables -t nat -A POSTROUTING -o wwan -j MASQUERADE
```

## 2. 端口映射

端口映射就是将外网主机的一个端口映射到内网中某台主机的某个端口，当用户访问外网主机的这个端口时，实际上是由内网主机的相应端口通讯。如下是一个典型的应用场景：

![](./pics/2018-12-12_3.png)

在这个网络拓扑里，右侧 192.168.2.101 的主机想要访问下方路由器连接的 192.168.1.101 主机的 HTTP 服务，该怎么办呢？

方法是在下方路由器上做端口映射，将 192.168.1.101 的 80 端口映射到 192.168.2.103 的 80 端口上，这样直接访问 192.168.2.103:80 就可以与 192.168.1.101:80 通讯。
具体添加的规则是：

```
iptables -t nat -I PREROUTING -i eth2 -d 192.168.2.103 -p tcp --dport 80 -j DNAT --to-destination 192.168.1.101:80
iptables -t nat -I POSTROUTING -o eth1 -d 192.168.1.101 -p tcp --dport 80 -j SNAT --to-source 192.168.1.1
```

当 192.168.2.101 访问 192.168.2.103:80 时，第一条规则在入口处修改了数据包的目的地址，第二条规则在出口处修改了源地址，就将数据包转移到了 192.168.1.101:80 。

## 3. 禁止 ping

禁止 ping 指的是禁止别的主机 ping 本机，可以添加如下规则：

```
iptables -t filter -I INPUT -p icmp -m icmp --icmp-type 8/0 -j REJECT
# or
iptables -t filter -I INPUT -p icmp -m icmp --icmp-type 8 -j REJECT
# or
iptables -t filter -I INPUT -p icmp -m icmp --icmp-type "echo-request" -j REJECT
```

发出的 ping 请求属于 type 8 类型的 ICMP 报文，这条规则表示 type 为 8 ，code 为 0 的 ICMP 包会被拒绝。

