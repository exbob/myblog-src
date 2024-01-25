---
title: "epoll 学习笔记"
date: 2020-08-30T11:53:11+08:00
draft: false
toc: true
comments: true
images:
tags:
  - untagged
---

## 1. 工作原理

epoll 是 Linux 独有的 I/O 多路复用机制，核心概念就是 epoll 实例，它是一个内核里的数据结构，从用户角度来看它可以简单的看做包含了两个队列：

* interest list（或者叫epoll set），用户注册的感兴趣的描述符集合。
* ready list，就绪的描述符集合，当有 I/O 就绪时，内核会自动将就绪的描述符加到 ready list 中。

在用户端的工作流程就是：

1. 向 interest list 注册感兴趣的文件描述符的 I/O 事件。
2. 等待已注册的文件描述符就绪。
3. 处理所有已经就绪的文件描述符。

## 2. 使用方法

使用 epoll 时，需要包括头文件：

```c
#include <sys/epoll.h>
```

### 2.1 新建一个 epoll 实例

```c
int epoll_create(int size);
```

`epoll_create()` 函数会新建一个 epoll 实例，然后返回一个文件描述符，作为 epoll 操作的句柄。从 Linux 2.6.8 开始， 参数 size 可以忽略，但是必须大于 0 。当不在需要这个描述符时，应该调用 `close()` 函数将其关闭。

调用失败时，会返回一个负数。

### 2.2 操作 epoll 实例 

```c
int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);
```

这是操作 epoll 实例的接口函数，用于添加、删除和修改 interest list 中监控的文件描述符。如果调用成功，会返回 0 ，如果失败，会返回一个负数，并设置 errno 。参数的含义：

* 第一个参数 epfd 就是 `epoll_create()` 函数返回的文件描述符。
* 第二个参数表示操作类型，可选：
    * EPOLL_CTL_ADD，将 fd 添加到 epfd 的 interest list 中。
    * EPOLL_CTL_MOD，从 interest list 中删除 fd 。
    * EPOLL_CTL_DEL，修改 fd 的监视事件。
* 第三个参数是需要监听的文件描述符。
* 第四个参数是需要监听的事件。

监视的事件通过 `struct epoll_event` 结构体设置：

```c
typedef union epoll_data {
void        *ptr;
int          fd;
uint32_t     u32;
uint64_t     u64;
} epoll_data_t;

struct epoll_event {
uint32_t     events;      /* Epoll events */
epoll_data_t data;        /* User data variable */
};
```

结构成员 data 由内核负责修改，当监视的文件描述符准备就绪时返回。结构成员 event 用于设置监视的事件类型，是一个枚举的集合，可以用 `|` 来增加多种事件类型，枚举如下：

* EPOLLIN 表示关联的 fd 可以进行读操作了。
* EPOLLOUT 表示关联的 fd 可以进行写操作了。
* EPOLLRDHUP(since Linux 2.6.17) 表示套接字关闭了连接，或者关闭了正写一半的连接。
* EPOLLPRI 表示关联的 fd 有紧急优先事件可以进行读操作了。
* EPOLLERR 表示关联的fd发生了错误，`epoll_wait()` 会一直等待这个事件，所以一般没必要设置这个属性。
* EPOLLHUP 表示关联的fd挂起了，`epoll_wait()` 会一直等待这个事件，所以一般没必要设置这个属性。
* EPOLLET 设置关联的fd为ET的工作方式，epoll 的默认工作方式是LT。
* EPOLLONESHOT (since Linux 2.6.2) 设置关联的 fd 为 one-shot 的工作方式。表示只监听一次事件，如果要再次监听，需要把 socket 放入到 epoll 队列中。

### 2.3 等待 I/O 事件

```c
int epoll_wait(int epfd, struct epoll_event *events, int maxevents, int timeout);
```

`epoll_wait()` 用于等待监视的 I/O 事件就绪，也就是返回 ready list 中的文件描述符 。调用后，函数开始阻塞，直到：

* 一个文件描述符触发了一个监视的事件。
* 被信号中断。
* 超时时间到。

已经就绪的文件描述符会写入 `events` 指向的缓存，这是一个数组，每个元素记录了一个就绪的文件描述符的信息。`maxevents` 用于告诉内核一次最多返回多少个已经就绪的文件描述符，这个值必须大于 0 ，但不要大于已经注册的文件描述符的个数。`timeout` 设置了等待超时，单位是毫秒，0 表示立即返回，如果设为 -1 ，表示永久等待。

如果调用成功，返回值就是已经就绪的文件描述符的数量，如果返回值是 1，那 `events` 数字的长度也只有 。失败会返回一个负数。

## 3. 例程


## 参考

* [彻底理解 I/O 多路复用](https://juejin.im/post/6844904200141438984)
* [epoll 的运行机制](http://www.skybluues.com/epoll%E7%9A%84%E8%BF%90%E8%A1%8C%E6%9C%BA%E5%88%B6/](http://www.skybluues.com/epoll的运行机制/))
* [epoll_create](https://man7.org/linux/man-pages/man2/epoll_create.2.html)
* [epoll_ctl](https://man7.org/linux/man-pages/man2/epoll_ctl.2.html)