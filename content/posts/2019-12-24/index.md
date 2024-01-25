---
title: UCI 和 ubus 学习笔记
date: 2019-12-24T08:00:00+08:00
draft: false
toc: true
comments: true
---


UCI 和 ubus 都是 Openwrt 项目提供的软件，UCI 提供了统一的配置文件格式和读写工具，ubus 提供了基于 Unix Socket 的进程间通信框架。两个软件都可以方便的移植到其他 Linux 系统，以 Ubuntu20.04 为例，首先要安装一些依赖的软件：

``` shell
apt-get install pkg-config
apt-get install lua5.1
apt-get install liblua5.1-dev
apt-get install cmake
apt-get install libjson-c-dev
```

然后要编译安装 libubox ：

``` shell
git clone https://git.openwrt.org/project/libubox.git
cd libubox
cmake .
make
make install
```

编译时可能出现找不到头文件的错误：

``` shell
/root/libubox/lua/uloop.c:21:17: fatal error: lua.h: No such file or directory
```

这是路径问题，因为 lua 的头文件在 `/usr/include/lua5.1` 目录下，所有修改 uloop.c 文件，为 lua.h 等头文件前面加上 `lua5.1/` 路径：

``` c
#include <lua5.1/lua.h>
#include <lua5.1/lualib.h>
#include <lua5.1/lauxlib.h>
```

## 1. UCI

官方文档：<https://openwrt.org/docs/guide-user/base-system/uci>

编译安装 uci ：

``` shell
git clone https://git.openwrt.org/project/uci.git
cd uci
cmake .
make 
make install # 默认都安装在 /usr/local 路径下
```

安装完成后执行一次 `sudo ldconfig -v` ，否则可能找不到刚安装的共享库。

UCI 的全称叫做统一配置接口（Unified Configuration Interface），它的作用为各种不同的服务单元提供统一的配置文件格式和编程方法。配置文件是纯文本文件，只支持 ASCII 字符，UCI 提供了 shell 命令，C 语言和 Lua 语言编程接口，不推荐手动编辑配置文件，避免出现语法错误。

### 1.1 配置文件语法

UCI 的配置文件默认都放在 `/etc/config` 路径下，也可以自定义。配置文件的语法是 `config -> section -> option` 这样的层级关系，一个配置文件就是一个 `config`，由多个 `section` 段组成的，每个 `section` 内包含了一组选项和值，以井号 `#` 开头的行是注释，语法如下：

```
config <type> ["name"]    # section
        option <name> "<value>"    # option
```

以 openwrt 系统的 `/etc/confg/network` 文件为例，系统的网络配置程序在启动时会读取并解析这个配置文件，然后根据文件内的选项来设置网卡参数：

```
config interface 'lan'
        option ifname 'eth0'
        option proto 'static'
        option netmask '255.255.255.0'
        option ipaddr '192.168.1.1'
 
config interface 'wan'
        option ifname 'eth1'
        option proto 'dhcp'
```

这里包含了两个 `section` , 每个 `section` 必须以 `config` 关键字开头，后面两个元素分别是 section 的 type 和 name ，由用户自定义，name 必须用引号包裹，如果没有定义 name，UCI 会自动分配一个 ID 作为它的 name ，这叫做匿名 section 。

每个 `section` 下包含了若干选项，以行为单位，必须以 `option` 关键字开头，后面两个元素分别是 option 的 name 和 vlaue ，由用户自定义，value 必须用引号包裹，不能为空，否则解析时会报错。


要获取 wan 口网卡的名称，可以用 `network.wan.ifname` 定位：

```
$ uci get network.wan.ifname
eth1
```

### 1.2 shell 命令

UCI 提供了 uci 命令读写配置文件，语法可以直接用 `uci -h` 获得，常用的命令：

* `batch` ，进入一个交互环境，可以连续执行多条 uci 命令，用 exit 命令退出。
* `export     [<config>]` ，以 uci 配置文件的语法显示 config 的内容。
* `import     [<config>]` ，导入配置文件。
* `changes    [<config>]` ，显示已修改未保存的内容。
* `commit     [<config>]` ，将修改内容提交保存到配置文件。 
* `add        <config> <section-type>` ，添加一个匿名 section 。
* `add_list   <config>.<section>.<option>=<string>` ，添加 list 。
* `del_list   <config>.<section>.<option>=<string>` ，删除 list 。
* `show       [<config>[.<section>[.<option>]]]` ，以编程可读的语法显示 config，section 或者 option 的内容
* `get        <config>.<section>[.<option>]` ，获取 section 的 type ，或者 option 的 value 。
* `set        <config>.<section>[.<option>]=<value>` ，设置 section 的 type ，或者 option 的 value 
* `delete     <config>[.<section>[[.<option>][=<id>]]]` ，删除一个 section，option 或者 option 的 type
* `rename     <config>.<section>[.<option>]=<name>` ，重命名 section 或者 option 。
* `revert     <config>[.<section>[.<option>]]` ，恢复未保存的修改内容
* `reorder    <config>.<section>=<position>`

新建一个 `/etc/config/system` 文件，然后做一次配置测试：

```
# 添加一个匿名 section
$ sudo uci add system system
cfg01e48a

# 设置一个选项 hostname 为 openwrt
$ sudo uci set system.@system[0].hostname="openwrt"

# 查看已修改未保存的内容
$ sudo uci changes system
system.cfg01e48a='system'
system.cfg01e48a.hostname='openwrt'

# 将修改内容提交保存到配置文件
$ sudo uci commit system

# 获取一个选项的值
$ uci get system.@system[0].hostname
openwrt

# 查看文件内容
$ cat /etc/config/system

config system
        option hostname 'openwrt'
```

> uci 默认先将修改内容保存在 /tmp/.uci/ 目录下的临时文件中，使用 commit 命令后，才会将修改内容合并到 /etc/confg/ 下的文件。还没有 commit 的内容，可以用 revert 命令恢复，原理就是删除临时文件。

将匿名 section 重命名 ：

```
$ uci rename system.@system[0]=info
$ uci changes
system.cfg01e48a='info'
$ uci show
system.info=system
system.info.hostname='openwrt'
$ uci commit
$ cat /etc/config/system

config system 'info'
        option hostname 'openwrt'
```

UCI 还支持一种特别的选项 list ，通常用于记录一组常量。以设置 ntp 服务器为例：

```
$ sudo uci add system timeserver
cfg02096b
$ sudo uci rename system.@timeserver[0]=ntp
$ sudo uci add_list system.ntp.server='0.de.pool.ntp.org'
$ sudo uci add_list system.ntp.server='1.de.pool.ntp.org'
$ sudo uci add_list system.ntp.server='2.de.pool.ntp.org'
$ sudo uci export system
package system

config system 'info'
        option hostname 'openwrt'

config timeserver 'ntp'
        list server '0.de.pool.ntp.org'
        list server '1.de.pool.ntp.org'
        list server '2.de.pool.ntp.org'
$ sudo uci commit
```

同名的 list 可以一次读取：

```
$ uci get system.ntp.server
0.de.pool.ntp.org 1.de.pool.ntp.org 2.de.pool.ntp.org
```

### 1.3 C 编程接口

使用 C 语言解析 UCI 非常复杂，不推荐。下面是一个简单的例子，可以读取一个选项的值：

``` c
// uci-example.c
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <uci.h>

int main(int argc, char **argv)
{
    struct uci_context *ctx;
    struct uci_ptr ptr;
    char *opt = strdup("system.@system[0].hostname");

    // 申请一个 uci_context 
    ctx = uci_alloc_context();

    // 获取并打印选项的值
    if(UCI_OK != uci_lookup_ptr(ctx, &ptr, opt, true))
    {
        uci_perror(ctx, "uci_lookup_ptr():");
    }
    else
    {
        printf("%s\n", ptr.o->v.string);
    }

    // 释放指针
    uci_free_context(ctx);
    free(opt);

    return 0;
}
```

要包含 uci.h 头文件，关键的数据结构和 API 都定义在这个文件中。

首先要调用 `uci_alloc_context()` 函数申请一个 `struct uci_context` 类型的指针，该结构存储了使用 UCI 过程中的各种状态数据，其他方法都要通过这个指针获得上下文数据。使用完毕用 `uci_free_context()` 函数释放。

`uci_lookup_ptr()` 函数的作用是解析 opt 传入的 uci 元素定位字符串，查找配置文件，将该元素下的树形结构保存到一个 `struct uci_ptr` 结构变量中，原型如下：

``` c
int uci_lookup_ptr(struct uci_context *ctx, struct uci_ptr *ptr, char *str, bool extended);
```

最后一个参数用于使能 UCI 扩展语法，设为 true 才可以解析 `@system[0]` 这种匿名 section 。函数调用成功会返回 `UCI_OK` ，调用失败会返回错误代码，可以用 `uci_perror()` 打印最新的错误代码对应的错误信息，原型如下：

``` c
void uci_perror(struct uci_context *ctx, const char *str);
```

第二个参数用于设置错误信息的前缀，可以设为空。

编译执行：

``` shell
$ gcc -Wall uci-example.c -o uci-example -luci
$ ./uci-example
openwrt
```

### 1.4 Lua 编程接口

使用 lua 编程更为简便，只需导入 uci 包，就可以调用 uci 的 lua 语言 API ，下面是一个简单的例子：

``` lua
#!/usr/bin/lua
-- uci-example.lua

require("uci")

print("Hello World!")

-- 新建一个 uci 操作实例
ctx = uci.cursor()

-- 获取一个选项的值
hostname = ctx:get("system","@system[0]","hostname")
print(hostname)
```

保存后执行：
``` shell
$ chmod +x uci-example.lua
$ ./uci-example.lua
Hello World!
openwrt
```

更多的 API 可以参考官方文档：<https://openwrt.org/docs/techref/uci> 。

## 2. ubus

ubus 是基于 unix socket 的进程间通信框架，包含守护进程、命令行工具和链接库，守护进程 ubusd 作为 socket server ，用户可用 lua 或者 C 语言的 API 实现 socket client ，client 和 server 之间用 json 格式进行通信，client 端的消息处理抽象处理对象（object）和方法（method）。ubus 通过对 socket 的封装，简化了进程间通信的步骤，只需按照固定模式调用 ubus 提供的API即可。有两种常见的应用场景：

1. 服务器-客户端的形式，进程 A 注册一系列服务，进程 B 调用这些服务
2. 订阅-通知的形式，进程 A 提供订阅服务，其他进程可用订阅或者退订这些服务，进程 A 可用向所有订阅者发布消息

编译安装 ubus

```shell
git clone https://git.openwrt.org/project/ubus.git
cd ubus
cmake .
make
make install
```

默认安装在 `/usr/local` 目录下，主要有四种文件：
* ubusd ，守护进程
* ubus ，命令行工具
* libubus.h 等，一些头文件
* libubus.so 等，一些链接库

