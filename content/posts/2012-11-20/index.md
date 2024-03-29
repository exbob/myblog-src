---
title: Linux 驱动的异步通知
date: 2012-11-20T08:00:00+08:00
draft: false
toc:
comments: true
---


## 实现步骤

假设设备驱动名为 module ，设备的私有数据结构为 module\_dev\_t ，实现异步通知的步骤如下 ：

1.定义一个 `struct fasync_struct *`类型的指针，通常是在设备的私有数据结构中定义。

	struct module_dev_t module_dev {
	...
	strcut fasync_struct * fasync_queue;
	}

2.实现 `fasync` 方法,在 `fasync` 方法中调用 `fasync_helper` 函数。

	static int module_fasync(int fd,struct file *filp,int mode)
	{
		struct module_dev_t *dev = filp->private_data;
		return fasync_helper(fd,filp,mode,&dev->fasync_queue);
	}
	
	struct file_operations fops = {
	...
	.fasync = module_fasync,
	}

3.在数据到达时调用 `kill_fasync` 函数产生信号。

	if(dev->fasync_queue)
		kill_fasync(&dev->fasync_queue,SIGIO,POLL_IN);

4.在关闭设备是调用 `fasync` 方法。

	module_fasync(-1,filp,0);

## 应用程序的编程方法

1.为信号注册一个处理函数

	signal(SIGIO,sig_handler);

当进程接收到 SIGIO 信号是会执行 sig_handler 函数：

	void (*sig_handler)(int sig)

2.设置将要接收 SIGIO 或 SIGURG 信号的进程 id 。

	fcntl(fd,F_SETOWN,getpid());

这样会将进程的 ID 保存到 filp->f_woner 中，内核就知道当信号到达时应该通知哪个进程。

3.为文件设置 FASYNC 标志。

	oflas = fcntl(fd,F_GETFL);
	fcntl(fd,F_SETFL,oflags | FASYNC);

设置 FASYNC 时就会调用驱动的 fasync 方法。在文件打开时，FASYNC 标志是默认清除的。
