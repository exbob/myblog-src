---
title: Linux 系统如何获取 CPU 主频
date: 2018-08-07T08:00:00+08:00
draft: false
toc: true
comments: true
---



## 1.CPU 主频

CPU 的主频是指 CPU 核心的时钟频率，它是 CPU 执行指令的最小时间单位。CPU 内部有时钟管理模块，通过外部振荡器（获取其他时钟电路）输入一个特定的频率（外频），经过内部的 PLL 电路（倍频器）锁定到一个很高的频率，再经过不同的分频，供给不同的模块和总线使用，供给 CPU 的就称为主频,就是通常所说的“主频 = 外频 x 倍频”。目前桌面 X86 CPU 的外频由主板供给，通常是 100MHz ，倍频通常是固定设置的。如果要超频，通常是在主板的 BIOS 中修改倍频因子，也有特殊情况可以增加外频。

X86-Linux 体系有三种硬件时钟：

* Real Time Clock(RTC) ，实时时钟，通常位于 CMOS ，独立工作
* Programmalbe Interval Timer(PIT) ，可编程的间隔定时器，通常由 8254 芯片实现
* Time Stamp Counter(TSC) ，时间戳控制器，记录 CPU 时钟周期

Linux 内核在计算 CPU 主频时会用到 PIT 和 TSC 。以下是在 kernel 3.4 版本中分析。

## 2.Programmalbe Interval Timer (PIT)

Programmalbe Interval Timer (PIT) 是现代计算机的重要组成部分，尤其是在多任务环境中。 PIT 是用 8253/8254 芯片实现的，由于历史原因，外接的晶振频率是 1.193182 MHz ，Linux 内核里的定义在 `include/linux/timex.h` 文件：

    /* The clock frequency of the i8253/i8254 PIT */
    #define PIT_TICK_RATE 1193182ul

8253/8254 内置三个独立的 16 位减法计数器用于分频，每个计数器有一个输出用于特定的功能，示意图如下：

![](./pics/2018-08-07_1.png)

1. Channel 0 ：PIT Channel 0 的输出连接在中断控制器上，因此它会产生 “IRQ 0”。通常在引导阶段，BIOS 将 Channel 0 设置为 65535 或 0（转换为65536），这将提供 18.2065Hz 的输出频率（每 54.9254ms 一次的中断）。 Channel 0 可能是最有用的 PIT 通道，因为它是唯一连接到 IRQ 的通道，可以用它产生定时中断。选择工作模式时，要注意 IRQ0 是由 Channel 0 输出电压的上升沿产生的。
2. Channel 1 ：PIT Channel 1 的输出曾被用于刷新 DRAM 或 RAM 。通常，RAM 中的每个位由一个电容器组成，该电容器保持代表该位状态的微小电荷，但是由于泄漏，这些电容器需要定期“刷新”，以便它们不会忘记自己的状态。在以后的机器上，DRAM 刷新是通过专用硬件完成的，不再使用 PIT 。在大规模集成电路中实现的现代计算机上，PIT Channel 1 不再可用。
3. Channel 2 ：PIT Channel 2 的输出连接在蜂鸣器上，因此输出的频率决定了蜂鸣器产生的声音的频率。这是唯一可以通过软件控制门信号的通道（通过I/O 端口 0x61 的 bit0），也可以用软件读取其输出。

PIT 的 8253/8254 芯片有四个寄存器，包括三个数据寄存器和一个模式控制寄存器，它们的地址和功能描述：

I/O port | Usage
--- | ---
0x40 | Channel 0 data port (read/write)
0x41 | Channel 1 data port (read/write)
0x42 | Channel 2 data port (read/write)
0x43 | Mode/Command register (write only, a read is ignored)

模式控制寄存器的格式：

![](./pics/2018-08-07_2.jpg)

编程方式是先在模式控制寄存器中设置计数器、读写方式和工作模式，然后向相应的计数器中写入初始值。

## 3.Time Stamp Counter (TSC)

时间戳控制器 Time Stamp Counter (TSC) 是 X86 CPU 里的一个 64 位寄存器，自 Pentium 开始引入，用于记录 CPU 复位后的周期数，CPU 内部时钟每产生一个时钟周期，该寄存器就加一，也就是 CPU 主频的节拍记录器。我们可以用单位时间内 TSC 记录的时钟周期个数来推算 CPU 的实际频率，比如一秒内 TSC 的值增长了 1000 ，那么主频就是 1KHz 。在单核 CPU 上，TSC 是一个简单高效的获取高精度 CPU 时序信息的方式，但是在多核 CPU 、休眠操作系统上，这个方式无法提供准确信息，依赖 TSC 会降低软件的可移植性。在 Windows 平台上，微软反对使用 TSC 进行高精度计时，在 POSIX 系统上，程序可以使用 `clock_gettime()` 函数读取 CLOCK_MONOTONIC 时钟的值来获得类似的功能。在 Linux 的内核上，可以用启动参数 `notsc` 禁用 TSC 。

X86 CPU 提供了 RDTSC 指令来读取 TSC 的值，低 32 位存放在 EAX 寄存器，高 32 位存放在 EDX 寄存器:

指令 | 操作码 | 说明
---|-----|---
RDTSC | 0F 31 | 将 TSC 的值读入 EDX:EAX

在内核源码的 `arch/x86/include/asm/msr.h` 文件中提供了读取方法：

``` C {.line-numbers}
#ifdef CONFIG_X86_64
#define DECLARE_ARGS(val, low, high)	unsigned low, high
#define EAX_EDX_VAL(val, low, high)	((low) | ((u64)(high) << 32))
#define EAX_EDX_ARGS(val, low, high)	"a" (low), "d" (high)
#define EAX_EDX_RET(val, low, high)	"=a" (low), "=d" (high)
#else
#define DECLARE_ARGS(val, low, high)	unsigned long long val
#define EAX_EDX_VAL(val, low, high)	(val)
#define EAX_EDX_ARGS(val, low, high)	"A" (val)
#define EAX_EDX_RET(val, low, high)	"=A" (val)
#endif
static __always_inline unsigned long long __native_read_tsc(void)
{
    DECLARE_ARGS(val, low, high);
    asm volatile("rdtsc" : EAX_EDX_RET(val, low, high));
    return EAX_EDX_VAL(val, low, high);
}
```

我们可以在用户空间用 C 语言内联汇编实现同样的功能：

``` C {.line-numbers}
#include <stdio.h>
int main()
{
    unsigned int low=0, high=0;
    asm volatile("rdtsc" : "=a"(low), "=d"(high));
    printf("0x%x 0x%x\n",high,low);
}
```

## 4.计算主频

Linux 内核在初始化阶段用 TSC 来计算 CPU 主频。我们可以在 dmesg 中找到类似的信息：

``` shell {.line-numbers}
$ dmesg | grep -E "TSC|tsc"
tsc: Fast TSC calibration using PIT
tsc: Detected 3192.872 MHz processor
TSC deadline timer enabled
tsc: Refined TSC clocksource calibration: 3192.747 MHz
Switched to clocksource tsc
```

前缀的 tsc 是模块的名称，有些内核可能没有这个，没有关系，我们从 `Detected 3192.872 MHz processor` 入手，这是在 `arch/x86/kernel/tsc.c` 文件的 `tsc_init()` 函数中打印的信息，属于内核的时钟子系统，它通过如下路径调用：

    start_kernel() -> time_init() —> x86_late_time_init() -> tsc_init()

这个函数执行的是 TSC 模块的初始化工作，然后校准 TSC 频率，设置为 CPU 主频，判断 TSC 频率是否可靠，用 TSC 频率计算 lpj 等，我们先关注这一段：

``` C {.line-numbers}
unsigned int __read_mostly cpu_khz;
EXPORT_SYMBOL(cpu_khz);
unsigned int __read_mostly tsc_khz;
EXPORT_SYMBOL(tsc_khz);

void __init tsc_init(void)
{
    ...
    tsc_khz = x86_platform.calibrate_tsc();
    cpu_khz = tsc_khz;
    if (!tsc_khz) {
        mark_tsc_unstable("could not calculate TSC khz");
        return;
    }
    printk("Detected %lu.%03lu MHz processor.\n",
            (unsigned long)cpu_khz / 1000,
            (unsigned long)cpu_khz % 1000);
    ...
}
```

其中的 `x86_platform.calibrate_tsc()` 调用的是 `native_calibrate_tsc()` 函数，它的功能是校准 tsc ，获取 tsc 频率。首先用 PIT 快速校准 TSC ，它的原理是用 PIT 记录一段时间，再测量这段时间内 TSC 的变换量，就可以计算出主频，通过 `quick_pit_calibrate()` 函数实现：

``` C {.line-numbers}
/*
  读取 PIT 的 MSB ，判断 MSB 是否等于参数 val
*/
static inline int pit_verify_msb(unsigned char val)
{
    /* Ignore LSB */
    inb(0x42);
    return inb(0x42) == val;
}
/*
  这个函数通过一个 for 循环不断的读取和判断 PIT 和 TSC ，最终用 *tscp 返回 MSB==val 时的 TSC 的值，*deltap 返回是增量（ delta ：希腊字母第四个）
*/
static inline int pit_expect_msb(unsigned char val, u64 *tscp, unsigned long *deltap)
{
    int count;
    u64 tsc = 0, prev_tsc = 0;
    for (count = 0; count < 50000; count++) {
        if (!pit_verify_msb(val)) // PIT 的 MSB 等于 val 时跳出循环
            break;
        prev_tsc = tsc;
        tsc = get_cycles(); //读取 tsc 的值，最终是调用上一章提到的 __native_read_tsc() 函数
    }
    *deltap = get_cycles() - prev_tsc;
    *tscp = tsc;
    return count > 5;
}

/*
  这个宏确定的是迭代次数，也就是获取多少次 PIT 的 MSB 。
  我们的目标是最大错误率为 500ppm（实际上真正的误差要小得多），但是耗时不能超过 50ms ，
  MAX_QUICK_PIT_MS * PIT_TICK_RATE / 1000  得到的是 50ms 内的时钟周期个数，也就是计数器减少的数值，
  最后除以 256 是因为我们只取 MSB 。 
*/
#define MAX_QUICK_PIT_MS 50
#define MAX_QUICK_PIT_ITERATIONS (MAX_QUICK_PIT_MS * PIT_TICK_RATE / 1000 / 256) //=233
static unsigned long quick_pit_calibrate(void)
{
    int i;
    u64 tsc, delta;
    unsigned long d1, d2;

    /* 关闭蜂鸣器 */
    outb((inb(0x61) & ~0x02) | 0x01, 0x61);
    /*
      计数器 2 , 读写方式是先低后高，工作模式是 0 , 二进制计数
      当计数器工作模式设为 0 后，该计数器的输出信号立即变为低电平，且计数过程中一直保持低电平。在经初值寄存器赋初值后，开始计数，在每个 CLK 时钟下降沿，计数器进行减 1 计数，当计数减到 0 时，OUT 输出信号变为高电平，且一直保持到该计数器重新赋初值。该信号可以作为中断请求信号。
      0 模式无自动装入计数初始值的功能，若要继续计数，则需要重新写入计数初始值。在计数期间，装入新的初始值，计数器会在初始值写入后重新开始计数。
    */
    outb(0xb0, 0x43);

    /* 从 0xffff 开始计数 */
    outb(0xff, 0x42);
    outb(0xff, 0x42);

    /*
      这里需要一个微小的延时，最简单的方法是第一次 PIT
    */
    pit_verify_msb(0);

    /*
      下面通过一个迭代过程测量出一段时间(50ms)内 TSC 的增长
      每次循环，PIT 都会减少 256 , i 次循环就是 (I * 256 / PIT_TICK_RATE) 秒
      delta 记录的是循环过程中 TSC 数值的增长
      循环结束后，用这两个数值计算主频
    */
    if (pit_expect_msb(0xff, &tsc, &d1)) {
        for (i = 1; i <= MAX_QUICK_PIT_ITERATIONS; i++) {
            if (!pit_expect_msb(0xff-i, &delta, &d2))
                break;
            delta -= tsc;
            if (d1+d2 >= delta >> 11) //确保误差小于 500ppm ，不理解
                continue;
            if (!pit_verify_msb(0xfe - i))  //再次检测 PIT 的 MSB ，确保 PIT 的值已经是 0xfe-i
                break;
            goto success;
        }
    }
    printk("Fast TSC calibration failed\n");
    return 0;
success:
    /*
	  kHz = ticks / time-in-seconds / 1000;
	  kHz = (t2 - t1) / (I * 256 / PIT_TICK_RATE) / 1000
	  kHz = ((t2 - t1) * PIT_TICK_RATE) / (I * 256 * 1000)
      主频通过 delta 返回
    */
    delta *= PIT_TICK_RATE;
    do_div(delta, i*256*1000); // do_div() 是内核的 64 位除法函数，结果保持在第一参数，返回余数
    printk("Fast TSC calibration using PIT\n");
    return delta;
}
```

通常用 PIT 快速校准 TSC 都会成功，直接用返回值作为 tsc_khz ，并赋予 cpu_khz 作为主频。如果失败，会继续用一种复杂的方式计算 PIT 和 TSC 。

## 5./proc/cpuinfo

在用户空间，我们是通过 `/proc/cpuinfo` 文件获得 CPU 主频的。proc 文件系统中的文件，必须在内核源码的某个位置创建并使用 `file_operations` 声明，cpuinfo 的声明位于 `fs/proc/cpuinfo.c` 文件：

``` C {.line-numbers}
    static const struct file_operations proc_cpuinfo_operations = {
        .open		= cpuinfo_open,
        .read		= seq_read,
        .llseek		= seq_lseek,
        .release	= seq_release,
    };

    static int __init proc_cpuinfo_init(void)
    {
        proc_create("cpuinfo", 0, NULL, &proc_cpuinfo_operations);
        return 0;
    }
```

然后在 `arch/x86/kernel/cpu/proc.c` 文件中有很多 `show_cpuinfo_*()` 函数，比如 `static int show_cpuinfo(struct seq_file *m, void *v)` ，它们会调用 `seq_printf()` 函数把信息输出到 /proc/cpuinfo 文件中:

``` C {.line-numbers}
    static int show_cpuinfo(struct seq_file *m, void *v)
    {
        struct cpuinfo_x86 *c = v;
        unsigned int cpu;
        int i;

        cpu = c->cpu_index;
        seq_printf(m, "processor\t: %u\n"
            "vendor_id\t: %s\n"
            "cpu family\t: %d\n"
            "model\t\t: %u\n"
            "model name\t: %s\n",
            cpu,
            c->x86_vendor_id[0] ? c->x86_vendor_id : "unknown",
            c->x86,
            c->x86_model,
            c->x86_model_id[0] ? c->x86_model_id : "unknown");
        ...
    }
```

可以看出大部分 CPU 信息都是通过 `struct cpuinfo_x86 *c` 结构获取的，这个结构的声明在 `arch/x86/include/asm/processor.h` 文件，在这个文件中搜索该结构的引用，会找到 `extern void cpu_detect(struct cpuinfo_x86 *c);` 等类似的函数，这些函数内通过 `cpuid()` 函数从硬件寄存器上读取信息，然后填充 `struct cpuinfo_x86 *c` 结构 ，这是一个内联函数 ：

``` C {.line-numbers}
    static inline void cpuid(unsigned int op,
                unsigned int *eax, unsigned int *ebx,
                unsigned int *ecx, unsigned int *edx)
    {
        *eax = op;
        *ecx = 0;
        __cpuid(eax, ebx, ecx, edx);
    }
```

函数内的 `__cpuid()` 是封装了 `native_cpuid()` 函数的宏定义，也在这个文件里定义：

``` C {.line-numbers}
    static inline void native_cpuid(unsigned int *eax, unsigned int *ebx,
                    unsigned int *ecx, unsigned int *edx)
    {
        /* ecx is often an input as well as an output. */
        asm volatile("cpuid"
            : "=a" (*eax),
            "=b" (*ebx),
            "=c" (*ecx),
            "=d" (*edx)
            : "0" (*eax), "2" (*ecx)
            : "memory");
    }
```

这里是通过汇编指令读取相应的寄存器，这些指令属于 CPUID ，是 X86 架构的处理器补充指令，用于发现处理器的详细信息，参考<https://zh.wikipedia.org/wiki/CPUID>。

还有一些信息不是通过 CUPID 获取的，比如 CPU 主频（CPU frequency），在 `arch/x86/kernel/cpu/proc.c` 文件的 `show_cpuinfo()` 函数中可以看到：

``` C {.line-numbers}
if (cpu_has(c, X86_FEATURE_TSC)) {
	unsigned int freq = cpufreq_quick_get(cpu);
	if (!freq)
		freq = cpu_khz;
	seq_printf(m, "cpu MHz\t\t: %u.%03u\n", freq / 1000, (freq % 1000));
}
```

它是先调用 `cpufreq_quick_get()` 函数返回一个值，这是 cpufrep 模块的一个函数，它的返回值与 sysfs 中 `/sys/devices/system/cpu/cpu[n]/cpufreq/` 目录下的 scaling_cur_freq 完全一致，而且可以动态变化。如果调用失败，就把 cpu_khz 作为 CPU 主频。

CPU 的主频是可以动态调节的。主频越高，功耗也越高，为了节省 CPU 的功耗和减少发热，我们可以根据当前 CPU 的负载情况，动态地提供刚好足够的主频给 CPU 。Linux 内核提供了一套框架来完成这个目标，这就是 cpufrep 子系统。

cpufrep 子系统在用户空间提供了 sysfs 接口，都位于 `/sys/devices/system/cpu` 目录下：

    /sys/devices/system/cpu$ ls
    cpu0  cpu2  cpufreq  kernel_max  modalias  online    power    probe    uevent
    cpu1  cpu3  cpuidle  microcode   offline   possible  present  release

## 6.BogoMIPS

在 `/proc/cpuinfo` 中可以看到一个参数 bogomips ，在 dmesg 中也可以看到类似的信息：

    [    0.000001] Calibrating delay loop (skipped), value calculated using timer frequency.. 6385.48 BogoMIPS (lpj=12770964)

从字面意思也可以理解， BogoMIPS 就是伪百万次指令每秒，每秒钟可以执行几百万条指令，是一种衡量 CPU 速度的不科学方法。这条信息来自于内核 `init/calibrate.c` 文件的 `calibrate_delay()` 函数。

## 参考

* [CPU 频率](http://www.expreview.com/57334.html)
* [Programmable Interval Timer](https://wiki.osdev.org/Programmable_Interval_Timer)
* [CPU frequency scaling](https://wiki.archlinux.org/index.php/CPU_frequency_scaling)
