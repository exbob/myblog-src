---
title: 使用 keepalived 实现双机热备
date: 2019-08-24T08:00:00+08:00
draft: false
toc:
comments: true
---


keepalived 是一个用 C 语言编写的免费开源软件，它实现了 VRRP协议，同时提供了强大的负载均衡 (LVS) 功能。我们可以用他的 VRRP 功能实现路由器或者服务器等网络设备的双机热备。简单的说，两台路由器，一台作为主机，一台作为备机，两台路由器有自己的独立 IP ，同时共享一个虚拟 IP ，主机正常是，这个虚拟 IP 指向主机，当主机出现故障时，虚拟 IP 指向备机，实现了路由器的无缝自动切换。网络拓扑如下图所示：

![](./pics/2019-08-24_1.jpg)

虚拟 IP 的实现方式有很多种，比较可靠的方法是为一个网卡定义多个 IP ，端口名用冒号隔开一个数字，用  ifconfig 命令实现，例如：

```
ifconfig eth0:0 192.168.6.100 netmask 255.255.255.0 up
```

> 用点隔开一个数字的端口名属于 VLAN 网卡，例如 eth0.100 ，具有不同的特性和应用。

## 安装

keepalived 官网在 <https://www.keepalived.org/> ，可以编译源码进行安装。在 ubuntu 系统下，直接用 apt 安装：

```
apt-get install keepalived
```

## 配置

keepalived 只有一个配置文件 keepalived.conf，通常位于 `/etc/keepalived/` 目录下，keepalived 还提供了很多配置文件的实例，安装在 `/usr/share/doc/keepalived/sample/` 目录下。对于双机热备，最简单的配置如下：

主机 ：

```
vrrp_instance VI_1 {   # 定义一个 VRRP 实例，VI_1 表示这个实例的名称，同一组 VRRP 路由器的实例名称必须一致
    state MASTER        # 定义本机的初始状态，MASTER 表示主机，BACKUP 表示备机
    interface enp3s0     # 指定 VRRP 运行的网卡
    virtual_router_id 51  # 定义 VRRP 路由器的 ID ，取值 1~255 ，同一组 VRRP 路由器的 ID 必须一致，这个 ID 会用于虚拟路由器的 MAC 地址
    priority 100               # 定义本机的优先级，取值 1~254 ，数字越大，优先级越高，MASTER 应该比 BACKUP 高 50 以上。
    virtual_ipaddress {   # 定义虚拟 IP 
        192.168.1.3/24
    }
}
```

备机：

```
vrrp_instance VI_1 {
    state BACKUP
    interface enp3s0
    virtual_router_id 51
    priority 40
    virtual_ipaddress {
        192.168.1.3/24
    }
}
```

配置完成后，执行 `systemctl start keepalived` 命令启动 keepalived 服务。

## 验证

主机正常的情况下，可以看到主机的  VRRP 实例处于 MASTER 状态：

```
# systemctl  status keepalived.service
● keepalived.service - Keepalive Daemon (LVS and VRRP)
   Loaded: loaded (/lib/systemd/system/keepalived.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2019-08-24 16:22:33 CST; 9min ago
  Process: 2311 ExecStart=/usr/sbin/keepalived $DAEMON_ARGS (code=exited, status=0/SUCCESS)
 Main PID: 2315 (keepalived)
    Tasks: 3
   Memory: 1.2M
      CPU: 195ms
   CGroup: /system.slice/keepalived.service
           ├─2315 /usr/sbin/keepalived
           ├─2316 /usr/sbin/keepalived
           └─2319 /usr/sbin/keepalived

Aug 24 16:22:33 ubuntu Keepalived_vrrp[2319]: Using LinkWatch kernel netlink reflector...
Aug 24 16:22:33 ubuntu Keepalived_healthcheckers[2316]: Registering Kernel netlink reflector
Aug 24 16:22:33 ubuntu Keepalived_healthcheckers[2316]: Registering Kernel netlink command channel
Aug 24 16:22:33 ubuntu Keepalived_healthcheckers[2316]: Opening file '/etc/keepalived/keepalived.conf'.
Aug 24 16:22:33 ubuntu Keepalived_healthcheckers[2316]: Using LinkWatch kernel netlink reflector...
Aug 24 16:25:27 ubuntu Keepalived_vrrp[2319]: VRRP_Instance(VI_1) Entering MASTER STATE
```

以及虚拟 IP 指向主机的网卡：

```
root@ubuntu:~# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enp3s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 00:1d:f3:52:99:10 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.1/24 brd 192.168.1.255 scope global enp3s0
       valid_lft forever preferred_lft forever
    inet 192.168.1.3/24 scope global secondary enp3s0
       valid_lft forever preferred_lft forever
    inet6 fe80::21d:f3ff:fe52:9910/64 scope link
       valid_lft forever preferred_lft forever
```

如果把主机关闭，则备机的 VRRP 实例状态会变为 MASTER ，虚拟 IP 也会指向备机的网卡：

``` 
# systemctl  status keepalived.service
● keepalived.service - Keepalive Daemon (LVS and VRRP)
   Loaded: loaded (/lib/systemd/system/keepalived.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2019-08-24 16:22:33 CST; 9min ago
  Process: 2311 ExecStart=/usr/sbin/keepalived $DAEMON_ARGS (code=exited, status=0/SUCCESS)
 Main PID: 2315 (keepalived)
    Tasks: 3
   Memory: 1.2M
      CPU: 195ms
   CGroup: /system.slice/keepalived.service
           ├─2315 /usr/sbin/keepalived
           ├─2316 /usr/sbin/keepalived
           └─2319 /usr/sbin/keepalived

Aug 24 16:22:33 ubuntu Keepalived_vrrp[2319]: Using LinkWatch kernel netlink reflector...
Aug 24 16:22:33 ubuntu Keepalived_healthcheckers[2316]: Registering Kernel netlink reflector
Aug 24 16:22:33 ubuntu Keepalived_healthcheckers[2316]: Registering Kernel netlink command channel
Aug 24 16:22:33 ubuntu Keepalived_healthcheckers[2316]: Opening file '/etc/keepalived/keepalived.conf'.
Aug 24 16:22:33 ubuntu Keepalived_healthcheckers[2316]: Using LinkWatch kernel netlink reflector...
Aug 24 16:22:34 ubuntu Keepalived_vrrp[2319]: VRRP_Instance(VI_1) Entering BACKUP STATE
Aug 24 16:25:26 ubuntu Keepalived_vrrp[2319]: VRRP_Instance(VI_1) Transition to MASTER STATE
Aug 24 16:25:27 ubuntu Keepalived_vrrp[2319]: VRRP_Instance(VI_1) Entering MASTER STATE
```

## 参考
* [虚拟路由冗余协议(VRRP)](https://cshihong.github.io/2017/12/18/%E8%99%9A%E6%8B%9F%E8%B7%AF%E7%94%B1%E5%86%97%E4%BD%99%E5%8D%8F%E8%AE%AE-VRRP/)
* [CentOS 7 配置 Keepalived 实现双机热备](https://qizhanming.com/blog/2018/05/17/how-to-config-keepalived-on-centos-7)
* [虚拟 IP 技术](http://www.xumenger.com/virtual-ip-20190220/)
* [Linux-eth0 eth0:1 和eth0.1关系、ifconfig以及虚拟IP实现介绍](https://www.cnblogs.com/JohnABC/p/5951340.html)
