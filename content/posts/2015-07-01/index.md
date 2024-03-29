---
title: Linux 系统中的时间
date: 2015-07-01T08:00:00+08:00
draft: false
toc:
comments: true
---


## 1. 时区

Linux 系统中通过 /etc/localtime 文件设置系统时区，所有的时区文件在 /usr/share/zoneinfo/ 目录下

如果要修改时区，直接将 /usr/share/zoneinfo/ 下的相应时区文件复制到 /etc/ 下，改名为 localtime 即可。

## 2. 系统时间的显示和设置

常用的显示或设置系统时间的命令是 date 。

直接执行 date 就可以显示当前的日期时间和时区，如果要格式化显示，需要用加号指定格式化参数，例如按 “年-月-日 时:分:秒”当前时间：

	~# date  +"%Y-%m-%d  %H:%M:%S"  
	2015-07-01 11:00:40

设置时间需要用 -s 参数，例如：

	~# date  -s  "20150701 12:03:00"  
	Wed Jul  1 12:03:00 HKT 2015

查看硬件时钟的时间用 hwclock命令：

	~# hwclock
	Wed Jul  1 11:09:54 2015  -0.127600 seconds

将系统时间写入硬件时钟：

	~# hwclock --systohc

读取硬件时钟设置系统时间：

	~# hwclock --hctosys

## 3. C语言的时间转换

C语言对时间的处理函数大部分在 `<time.h>` 头文件。

函数 time 会返回从 ”1970 年 1 月 1 日 0 点“ 到当前的秒数，如果参数 t 不为空，也会存储在该指针指向的内存里。失败会返回 -1 。函数原型：

	time_t time(time_t *t);

time 返回的时间可读性不好，如果要看到类似 ”2014 年 12 月 7 日“  这样的显示，需要将其转换。用 localtime 函数可以将 time_t 类型转换为本地时间，存储在 tm 结构中：

	struct tm
    {
        int tm_sec; /* Seconds (0-60) */
    	int tm_min; /* Minutes (0-59) */
    	int tm_hour; /* Hours (0-23) */
    	int tm_mday; /* Day of the month (1-31) */
    	int tm_mon; /* Month (0-11) */
    	int tm_year; /* Year since 1900 */
    	int tm_wday; /* Day of the week (Sunday = 0)*/
    	int tm_yday; /* Day in the year (0-365; 1 Jan = 0)*/
    	int tm_isdst; /* Daylight saving time flag
    	 > 0: DST is in effect;
    	 = 0: DST is not effect;
    	 < 0: DST information not available */
	};

	struct tm *localtime(const time_t *timep);

tm 结构的格式就很清晰了，还可以进一步将这个结构按照指定的格式转换为字符串，这需要 strftime 函数：

	size_t strftime(char *outstr, size_t maxsize, const char *format, const struct tm *timeptr);

strftime 会将 timeptr 结构按照 format 指定的格式转换为字符串，并存储在 outstr 中。maxsize 指定 outstr 的字节数。format 的常用格式命令有 ：

	%y 不带世纪的十进制年份（值从0到99）
	%Y 带世纪部分的十制年份
	%m 十进制表示的月份
	%B 月份的全称
	%b 月份的简写
	%d 十进制表示的每月的第几天
	%H 24小时制的小时
	%I 12小时制的小时
	%M 十时制表示的分钟数
	%S 十进制的秒数
	%x 标准的日期串
	%X 标准的时间串

获取系统时间并格式化显示的例程：

	#include <stdio.h>
	#include <time.h>

	int main ()
	{
	        time_t sys_time;
	        struct tm * local_time;
	        char time_buf[30];

	        time(&sys_time);
	        local_time=localtime(&sys_time);
	        strftime(time_buf,30,"%Y-%m-%d %H:%M:%S",local_time);

	        printf("NOW:%s\n",time_buf);
	        return 0;
	}

该程序的输出：

	NOW:2015-07-01 11:53:59

## 4. C语言的时间测量

C语言提供了 gettimeofday 函数，它会返回从 1970 年 1 月 1 日 0 点到现在的时间，精确到微秒，保存在 timeval 结构中，函数原型：

	#include <sys/time.h>
	int gettimeofday(struct timeval *tv, struct timezone *tz);

	struct timeval 
	{
		time_t      tv_sec;     /* seconds */
		suseconds_t tv_usec;    /* microseconds */
	};

>注：第二个参数已经废止，传入 NULL 即可。

例如，计算输出 Hello world 的耗时：

	#include <stdio.h>
	#include <sys/time.h>

	int main ()
	{
		struct timeval start_time,end_time;

		gettimeofday(&start_time,NULL);
		printf("Hello world\n");
		gettimeofday(&end_time,NULL);

		printf("%ld s %ld us\n",end_time.tv_sec-start_time.tv_sec,end_time.tv_usec-start_time.tv_usec);
        return 0;
	}

该程序的输出：

	Hello world
	0 s 41 us

## 5. 计时器
要定时执行某段代码，最简单的方法是用 sleep 函数，它会使进程挂起一段时间，单位是秒，更精确的睡眠需要调用 usleep 函数，它单位是微秒 。

更好的方法是使用 POSIX Timer 。POSIX  Timer 可以为一个进程设置多个计时器，时间到达后，可以通过信号或其他方式通知进程，最高可以达到纳秒级别的精度。

涉及的函数：

* timer_create ：创建一个新的 Timer；并且指定定时器到时通知机制
* timer_delete ：删除一个 Timer
* timer_gettime ：Get the time remaining on a POSIX.1b interval timer
* timer_settime ：开始或者停止某个定时器。
* timer_getoverrun ：获取丢失的定时通知个数。

### 创建 Timer

使用 Posix Timer 的基本流程很简单，首先调用 timer_create 函数创建一个 Timer。函数原型：

    int timer_create(clockid_t clockid, struct sigevent *sevp, timer_t *timerid);
    
创建的时候需要指定该 Timer 的一些特性，比如 clock ID。clock ID 即 Timer 的种类，可以为如下任意一种：

* CLOCK_REALTIME ：Settable system-wide real-time clock；
* CLOCK_MONOTONIC	：Nonsettable monotonic clock
* CLOCK_PROCESS_CPUTIME_ID	：Per-process CPU-time clock
* CLOCK_THREAD_CPUTIME_ID	：Per-thread CPU-time clock

CLOCK_REALTIME 时间是系统保存的时间，即可以由 date 命令显示的时间，该时间可以重新设置。比如当前时间为上午 10 点 10 分，Timer 打算在 10 分钟后到时。假如 5 分钟后，我用 date 命令修改当前时间为 10 点 10 分，那么 Timer 还会再等十分钟到期，因此实际上 Timer 等待了 15 分钟。假如您希望无论任何人如何修改系统时间，Timer 都严格按照 10 分钟的周期进行触发，那么就可以使用 CLOCK_MONOTONIC。

CLOCK_PROCESS_CPUTIME_ID 的含义与 setitimer 的 ITIMER_VIRTUAL 类似。计时器只记录当前进程所实际花费的时间；比如还是上面的例子，假设系统非常繁忙，当前进程只能获得 50%的 CPU 时间，为了让进程真正地运行 10 分钟，应该到 10 点 30 分才允许 Timer 到期。

CLOCK_THREAD_CPUTIME_ID 以线程为计时实体，当前进程中的某个线程真正地运行了一定时间才触发 Timer。

timer_create 的第二个参数 struct sigevent 用来设置定时器到时时的通知方式。该数据结构如下：

    struct sigevent
    {
        int sigev_notify; /* Notification method */
        int sigev_signo; /* Notification signal */
        union sigval sigev_value; /* Data passed with  notification */
        void (*sigev_notify_function) (union sigval);   
        /* Function used for thread notification (SIGEV_THREAD) */
        void *sigev_notify_attributes;
        /* Attributes for notification thread  (SIGEV_THREAD) */
        pid_t sigev_notify_thread_id;
        /* ID of thread to signal (SIGEV_THREAD_ID) */
    };
    union sigval
    {         
        int   sival_int;    /* Integer value */
        void   *sival_ptr;    /* Pointer value */
    };
 
 其中 sigev_notify 表示通知方式，有如下几种：
 
* SIGEV_NONE	：定时器到期时不产生通知。。。
* SIGEV_SIGNAL	 ：定时器到期时将给进程投递一个信号，用 sigev_signo 指定信号值。
* SIGEV_THREAD	：定时器到期时将启动新的线程进行需要的处理
* SIGEV_THREAD_ID ：（仅针对 Linux)定时器到期时将向指定线程发送信号。

如果采用 SIGEV_NONE 方式，使用者必须调用timer_gettime 函数主动读取定时器已经走过的时间。类似轮询。

如果采用 SIGEV_SIGNAL 方式，使用者可以选择使用什么信号，用 sigev_signo 表示信号值，比如 SIG_ALARM。

如果使用 SIGEV_THREAD 方式，则需要设置 sigev_notify_function，当 Timer 到期时，将使用该函数作为入口启动一个线程来处理信号；sigev_value 保存了传入 sigev_notify_function 的参数。sigev_notify_attributes 如果非空，则应该是一个指向 pthread_attr_t 的指针，用来设置线程的属性（比如 stack 大小,detach 状态等）。

SIGEV_THREAD_ID 通常和 SIGEV_SIGNAL 联合使用，这样当 Timer 到期时，系统会向由 sigev_notify_thread_id 指定的线程发送信号，否则可能进程中的任意线程都可能收到该信号。这个选项是 Linux 对 POSIX 标准的扩展，目前主要是 GLibc 在实现 SIGEV_THREAD 的时候使用到，应用程序很少会需要用到这种模式。

### 启动 Timer

创建 Timer 之后，便可以调用 timer_settime() 函数指定定时器的时间间隔，并启动了。函数原型：

    int timer_settime(timer_t timerid, int flags,
    const struct itimerspec *new_value,
    struct itimerspec * old_value);

new_value 和 old_value 都是 struct itimerspec 数据结构：

    struct itimerspec
    {
         struct timespec it_interval; //定时器周期值
         struct timespec it_value; //定时器到期值
    };
    struct timespec
    {
        time_t 	 tv_sec;  //秒
        long	 tv_nsec;  //纳秒
    };
    
启动和停止 Timer 都可以通过设置 new_value 来实现：

* new_value->it_interval 为定时器的周期值，比如 1 秒，表示定时器每隔 1 秒到期；
* new_value->it_value 如果大于 0，表示启动定时器，Timer 将在 it_value 这么长的时间过去后到期，此后每隔 it_interval 便到期一次。如果 it_value 为 0，表示停止该 Timer。

有些时候，应用程序会先启动用一个时间间隔启动定时器，随后又修改该定时器的时间间隔，这都可以通过修改 new_value 来实现；假如应用程序在修改了时间间隔之后希望了解之前的时间间隔设置，则传入一个非 NULL 的 old_value 指针，这样在 timer_settime() 调用返回时，old_value 就保存了上一次 Timer 的时间间隔设置。多数情况下我们并不需要这样，便可以简单地将 old_value 设置为 NULL，忽略它。

### 例程

下面这个例程使用 SIGEV_THREAD 方式的 timer ，每隔两秒调用一次 timer_thread 函数，将 counter 加一，并打印。主函数等待 counter 等于 5 时退出。

    #include <stdio.h>
    #include <unistd.h>
    #include <time.h>
    #include <signal.h>
    
    int counter = 0;
    
    void timer_thread(union sigval val)
    {
        counter++;
        printf("counter = %d\n",counter);
    }
    int main ()
    {
        int ret = 0;
        timer_t timer_id;
        struct sigevent se;
        struct itimerspec ts;

        se.sigev_notify=SIGEV_THREAD;
        se.sigev_notify_function = timer_thread;
        se.sigev_notify_attributes = NULL;
    
        ret = timer_create(CLOCK_MONOTONIC,&se,&timer_id);
        if(ret<0)
        {
            perror("timer create failed\n");
            return -1;
        }
    
        ts.it_value.tv_sec = 2;
        ts.it_value.tv_nsec = 0;
        ts.it_interval.tv_sec = 2;
        ts.it_interval.tv_nsec = 0;
    
        ret = timer_settime(timer_id,0,&ts,NULL);
        if(ret<0)
        {
            perror("timer set failed\n");
            return -1;
        }
    
        printf("...start\n");
        while(counter<5)
        {
            sleep(1);
        }

        return 0;
    }
    
编译时要带 -lrt 参数，该程序的输出是：

    ~# gcc test.c -Wall -lpthread  -lrt -o test
    ~# ./test 
    ...start
    counter = 1
    counter = 2
    counter = 3
    counter = 4
    counter = 5

## 参考
[浅析 Linux 中的时间编程和实现原理](http://www.ibm.com/developerworks/cn/linux/1307_liuming_linuxtime1/)
