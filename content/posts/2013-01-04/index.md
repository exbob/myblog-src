---
title: Linux 字符驱动的基本结构
date: 2013-01-04T08:00:00+08:00
draft: false
toc:
comments: true
---


假设字符设备名为 led ，源文件为led.c ，不涉及实际的硬件操作。基本的驱动代码结构如下：

## 1. 包含必要的头文件

	#include <linux/init.h>    //module_init() 和 module_exit() 
	#include <linux/sched.h>   //包含大部分内核API的定义
	#include <linux/module.h>  //什么模块信息的宏，例如MODULE_AUTHOR(author)
	#include <linux/version.h> //包含内核版本信息的头文件
	#include <linux/moduleparam.h>  //创建模块参数的宏
	#include <linux/kernel.h>  //printk等函数
	#include <linux/types.h>   //内核模块的各种数据类型，例如dev_t
	#include <linux/fs.h>      //文件系统
	#include <linux/cdev.h>    

还可以根据需要添加其他头文件。

## 2. 定义一个设备私有数据结构

通常会将设备名，设备号，cdev等都放入这个数据结构。

	struct led_dev_t {
		char dev_name[10];
		dev_t dev_num;
		struct cdev cdev;
	}
	struct led_dev_t *led_dev;

## 3. 实现 file_operations 结构

file_operations 结构首先要实现 `.owner` 然后再根据需要实现相关函数。

	struct file_operations led_fops = {
		.owner = THIS_MODULE,
		.open = led_open,
		.release = led_close,
	}

## 4. 实现模块初始化函数

模块加载函数应该依次完成如下几个步骤：

1. 为设备私有数据结构分配内存，然后初始化。
2. 申请设备号。
3. 注册字符设备。即初始化 `cdev` ，将 `file_operations` 结构和设备号与 `cdev` 绑定。

最后用 `module_init()` 宏向内核说明初始化函数的位置。

## 5. 实现模块卸载函数

模块卸载函数的内容基本是加载函数的逆过程：

1. 释放设备号。
2. 删除 `cdev` 。
3. 释放申请的内存。

最后用 `module_exit()` 宏向内核说明卸载函数的位置。

## 6. 实现文件操作函数

open 和 close 函数通常是必须的。

open 函数的原型是

	int (*open)(struct inode *,struct file *)

`inode` 结构的成员 `i_cdev` 指向的就是先前设置的 `cdev` 。要确保设备成功打开，应该通过 `inode->i_cdev` 找到包含 `cdev` 的设备私有数据结构的实例。内核提供 `container_of` 宏来完成这项工作：
	
	container_of(poiner,container_type,container_field);

用法如下：

	struct led_dev_t *dev;
    dev = container_of(inode->i_cdev,struct led_dev_t,cdev);
    DEBUG("open %s\n",dev->dev_name);
    filp->private_data = dev;

close 函数的原型是

	int (*release)(struct inode *,struct file *)

## 7. 模块参数

模块的参数通过 `module_param(name,type,flag)` 声明，并且应该有一个默认值，例如：

	static int addr=0x300;
	module_param(addr,int,S_IRUGO|S_IWUSR);

如果参数类型为字符串，type 应该设为 `charp` 。

flag 是访问许可值，可用的值定义在 `<linux/stat.h>` 中。`S_IRUGO` 表示任何人都可以读取该参数，但不能修改；`S_IWUSR` 表示 root 用户可以修改该参数。

## 8. 声明许可证

	MODULE_LICENSE("GPL");

## 9. 关于调试

最常用的调试手段是内核打印函数 `printk` ，使用方法与标准库函数 `printf` 类似。`printk` 打印的信息通常用 `dmesg` 命令查看。

为了方便在最终发布时去掉打印的调试信息，通常将 `printk` 函数封装为一个宏 ：

	#define PRINT_DEBUG
	#ifdef PRINT_DEBUG
		#define DEBUG(fmt,args...) printk("LED:"fmt,##args)
	#else
		#define DEBUG(fmt,args...)
	#endif

发布时只需将第一行注释掉，就可以去掉打印信息。

## 10. Makefile

	KERNELDIR=/lib/modules/$(shell uname -r)/build
	PWD=$(shell pwd)
	
	obj-m := led.o
	
	default:
		$(MAKE) -C $(KERNELDIR) M=$(PWD) modules
	clean:
		$(MAKE) -C $(KERNELDIR) M=$(PWD) clean

如果模块包含多个源文件，比如 file1.c 和 file2.c ，Makefile 应该如下编写：

	obj-m := modulename.o
	modulename-objs := file1.o file2.o

modulename 是模块的名称，最好不要与源文件同名。

## 11. 加载驱动

用 insmod 命令加载驱动，加载时可以指定参数，例如：

	insmod led.ko addr=0x300

加载成功后，`/sys/modules/` 下会出现相应的目录，`/proc/modules`文件（lsmod 即查看的该文件）中会出现模块的信息， `/proc/devices` 文件中可以看到设备名和主设备号：

	cat /proc/devices | grep led

可以根据主设备号创建设备节点。

## 12. 附录：完整代码

	#include <linux/init.h>
	#include <linux/module.h>
	#include <linux/slab.h>
	#include <linux/mm.h>
	#include <linux/fs.h>
	#include <linux/types.h>
	#include <linux/cdev.h>
	#include <linux/version.h>
	
	#define PRINT_DEBUG
	#ifdef PRINT_DEBUG
		#define DEBUG(fmt,args...) printk("LED : "fmt,##args)
	#else
		#define DEBUG(fmt,args...)
	#endif
	
	
	struct led_dev_t {
	    const char *dev_name;
	    dev_t dev_num;
	    struct cdev cdev;
	};
	
	struct led_dev_t *led_dev;
	
	int led_open(struct inode *inode,struct file *filp)
	{
	    struct led_dev_t *dev;
	    dev = container_of(inode->i_cdev,struct led_dev_t,cdev);
	    DEBUG("open %s\n",dev->dev_name);
	    filp->private_data = dev;
	
	    return 0;
	}
	
	int led_close(struct inode *inode,struct file *filp)
	{
	    DEBUG("close %s\n",((struct led_dev_t *)filp->private_data)->dev_name);
	
	    return 0;
	}
	
	struct file_operations led_fops = {
	    .owner = THIS_MODULE,
	    .open = led_open,
	    .release = led_close,
	};
	
	static int __init led_init(void)
	{
	    int ret = 0;
	    unsigned int dev_major = 0;
	    unsigned int dev_minor = 0;
	
	    //初始化设备私有数据结构
	    led_dev = kmalloc(sizeof(struct led_dev_t),GFP_KERNEL);
	    if(led_dev <= 0) {
		DEBUG("led init kmalloc failed\n");
		return -1;
	    }
	    memset(led_dev,0,sizeof(struct led_dev_t));
	    led_dev->dev_name = "led";  //定义设备名
	
	    //申请设备号
	    if(dev_major) {
		led_dev->dev_num = MKDEV(dev_major,dev_minor);
		ret = register_chrdev_region(led_dev->dev_num,1,led_dev->dev_name);
	    }
	    else {
		ret = alloc_chrdev_region(&(led_dev->dev_num),dev_minor,1,led_dev->	dev_name);
		dev_major = MAJOR(led_dev->dev_num);
	    }
	
	    if(ret) {
		DEBUG("register chrdev region failed\n");
		return ret;
	    }
	    else {
		DEBUG("Major: %d, Minor: %d\n",dev_major,dev_minor);
	    }
	
	    //初始化 cdev
	    cdev_init(&(led_dev->cdev),&led_fops);
	    led_dev->cdev.owner = THIS_MODULE;
	    ret = cdev_add(&(led_dev->cdev),led_dev->dev_num,1);
	
	    if(ret<0) {
		DEBUG("cdev add failed\n");
		return ret;
	    }
	
	    DEBUG("led init\n");
	
	    return 0;
	}
	
	
	static void __exit led_exit(void)
	{
	
	    DEBUG("device is %s\n",led_dev->dev_name);
	    unregister_chrdev_region(led_dev->dev_num,1);
	    cdev_del(&led_dev->cdev);
	    kfree(led_dev);
	    DEBUG("led exit\n");
	}
	
	module_init(led_init);
	module_exit(led_exit);
	
	
	MODULE_AUTHOR("Li Shaocheng");
	MODULE_LICENSE("GPL");
