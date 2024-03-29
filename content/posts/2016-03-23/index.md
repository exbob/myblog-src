---
title: BlueZ 蓝牙编程笔记
date: 2016-03-23T08:00:00+08:00
draft: false
toc:
comments: true
---


## 1. 简介

BlueZ 是 Linux 官方的蓝牙协议栈，官网地址：<www.bluez.org> 。

BlueZ 的代码由两个部分组成：内核代码和用户空间程序。内核代码包括驱动和核心协议栈，用户空间程序包括应用程序接口和操作蓝牙设备的工具。BlueZ 的体系结构如下图：

![](./pics_1.jpg)

我使用的版本是 bluez-4.101 。

## 2. 扫描

下面这个例程展示了搜索蓝牙设备的过程，并显示设备名称和地址。

    //samplescan.c
    #include <stdio.h>
    #include <stdlib.h>
    #include <unistd.h>
    #include <sys/socket.h>
    #include <bluetooth/bluetooth.h>
    #include <bluetooth/hci.h>
    #include <bluetooth/hci_lib.h>
    
    int main(int argc, char **argv)
    {
        inquiry_info *ii = NULL;
        int max_rsp, num_rsp;
        int dev_id, sock, len, flags;
        int i;
        char addr[19] = { 0 };
        char name[248] = { 0 };
    
        dev_id = hci_get_route(NULL);
        sock = hci_open_dev( dev_id );
        if (dev_id < 0 || sock < 0) {
            perror("opening socket");
            exit(1);
        }
    
        len  = 8;
        max_rsp = 255;
        flags = IREQ_CACHE_FLUSH;
        ii = (inquiry_info*)malloc(max_rsp * sizeof(inquiry_info));
        
        num_rsp = hci_inquiry(dev_id, len, max_rsp, NULL, &ii, flags);
        if( num_rsp < 0 ) perror("hci_inquiry");
    
        for (i = 0; i < num_rsp; i++) {
            ba2str(&(ii+i)->bdaddr, addr);
            memset(name, 0, sizeof(name));
            if (hci_read_remote_name(sock, &(ii+i)->bdaddr, sizeof(name), 
                name, 0) < 0)
            strcpy(name, "[unknown]");
            printf("%s  %s\n", addr, name);
        }
    
        free( ii );
        close( sock );
        return 0;
    }

编译 `gcc -o simplescan simplescan.c -lbluetooth`

bdaddr_t 是存储蓝牙设备地址的基本数据结构：

    typedef struct {
    	uint8_t b[6];
    } __attribute__((packed)) bdaddr_t; 
    
BlueZ 中的所有蓝牙地址都存放在 bdaddr_t ，同时提供了两个函数用于地址字符串与 bdaddr_t 之间的转换：
    
    int str2ba( const char *str, bdaddr_t *ba );
    int ba2str( const bdaddr_t *ba, char *str );
    
地址字符串的结构应该是 `XX:XX:XX:XX:XX:XX` ，XX 是一个十六进制数，str2ba 函数将它转换到 6 Byte 的 bdaddr_t 中。ba2str 的作用相反。

