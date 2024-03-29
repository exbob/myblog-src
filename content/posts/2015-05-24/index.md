---
title: Libmodbus 编程说明
date: 2015-05-24T08:00:00+08:00
draft: false
toc:
comments: true
---


项目主页：[http://libmodbus.org](http://libmodbus.org)

程序中必须包含头文件，编译时连接到 libmodbus ：

    #include <modbus.h>
    cc `pkg-config --cflags --libs libmodbus` files
    
在程序中使用 libmodbus 主要是如下几个步骤。

## 1. 新建环境
新建一个 libmodbus 环境，如果是串口连接的modbus设备，用 modbus_new_rtu() 函数，如果是tcp连接的modbus 设备，用 modbus_new_tcp() 函数。如果新建成功会返回一个 struct modbus_t 指针，以后我们操作modbus设备，就是对这个指针进行操作；失败返回空指针。

一个物理接口可以连接多个 modbus 从设备，每个modbus 从设备有自己独立的 ID， 叫做”从设备编号“，是一个整数。所有要用 modbus_set_slave() 函数为 modbus_t 结构设置从设备编号，表示要连接的是哪个 modbus 设备。

释放一个 libmodbus 环境，用 modbus_free() 函数。

## 2. 连接
新建成功后，就可以建立连接，用 modbus_connect() 函数。
关闭连接用 modbus_class() 函数。
刷新连接用 modbus_flush() 函数。

## 3. 读写
连接成功后，可以调用相关函数对modbus设备进行操作。

## 4. 相关函数说明

* 新建一个 RTU 类型的 libmodbus 环境，返回一个 modbus_t 结构 

        modbus_t *modbus_new_rtu(const char *device, int baud, char parity, int data_bit, int stop_bit); 

* 新建一个 TCP 类型 的 libmodbus 环境 ，返回一个 modbus_t 结构
   
        modbus_t *modbus_new_tcp(const char *ip, int port);

* 设置 slave id ，返回值 EINVAL 表示 slave 值无效

        int modbus_set_slave(modbus_t *ctx, int slave); 

* 使能 debug 

        void modbus_set_debug(modbus_t *ctx, int boolean);

    如果 boolean 为 true ，会使能 ctx 的 debug 标志位，在 stdout 和 stderr 上显示 modbus message ，例如 ：

        [00][14][00][00][00][06][12][03][00][6B][00][03]
        Waiting for a confirmation…
        <00><14><00><00><00><09><12><03><06><02><2B><00><00><00><00>

* 设置故障恢复模式

        int modbus_set_error_recovery(modbus_t *ctx,modbus_error_recovery_mode error_recovery); 

    参数 error_recovery 可以设置0，或者如下的值：
    
    MODBUS_ERROR_RECOVERY_LINK
    

* 建立一个 modbus 连接。返回0表示成功。失败返回 -1 

        int modbus_connect(modbus_t *ctx);

* 释放一个 modbus_t 结构。

        void modbus_free(modbus_t *ctx);

* function id 0x01

        int modbus_read_bits(modbus_t *ctx, int addr, int nb, uint8_t *dest);
        
    使用 modbus 功能码 0x01 ，从 addr 读取连续的 nb 个状态位，结果放在 *dest 指向的数组，每个状态位占用一个数组元素，状态为 TRUE 或 FALSE 。成功返回 0 ，失败返回 -1 。

* function id 0x02

        int modbus_read_input_bits(modbus_t *ctx, int addr, int nb, uint8_t *dest);

    使用 modbus 功能码 0x02 ，从 addr 读取 nb 个输入状态位，结果放在 *dest 指向的数组，每个状态位占用一个素组元素，状态为 TRUE 或 FALSE 。成功返回 0 ，失败返回 -1 。
    
* function id 0x03 

        int modbus_read_registers(modbus_t *ctx, int addr, int nb, uint16_t *dest);

    使用 modbus 功能码 0x03 ，从 addr 地址开始，读取连续的 nb 个寄存器的值，一个寄存器是两个字节。结果存放在 dest 。返回读取寄存器的个数，失败返回 -1 。
    
    >设备上的地址是从 1 开始的，modbus是从0开始寻址，如果要读取1的数据，addr应该设为0.
    
* function id 0x05
    
        int modbus_write_bit(modbus_t *ctx, int addr, int status);
    
    使用 modbus 功能码 0x05 ，向 addr 写一个状态：TRUE 或 FALSE ，成功会返回 0 ，失败返回 -1 。 
    
* function id 0x0F

        int modbus_write_bits(modbus_t *ctx, int addr, int nb, const uint8_t *src);

    使用 modbus 功能码 0x0F ，将 *src 指向的数组写入从 addr 开始的 nb 个状态位，数组元素的值应该是 TRUE 或 FALSE ，每个元素对应一个状态位。成功会返回 0 ，失败返回 -1 。
    
* function id 0x06

        int modbus_write_register(modbus_t *ctx, int addr, int value);
    
    使用 modbus 功能码 0x06 ，将 value 写入地址为 addr 的一个寄存器中。成功会返回 1 ，失败返回 -1 。
