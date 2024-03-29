---
title: 计算机是如何实现重启的
date: 2017-11-30T08:00:00+08:00
draft: false
toc: true
comments: true
---



## 1. Soft Power

早期的计算机主板都是使用 AT 电源管理技术，AT 电源系统非常简单，电源键是机械式开关，只有开闭两种状态，闭合后电流从开关上流过为主板供电，断开后主板上的所有器件同时断电，无法实现待机、软关机等功能，这个时期的 Windows 系统关机后会一直显示一条 "It is now safe to turn off your computer" 的信息，因为操作系统无法切断电源。这时期的电源可以叫做 Hard Power ，因为全部都是硬件控制的。

后来英特尔提出了 ATX 主板标准，它带来了 Soft Power ，它使用的 [ATX 电源](http://www.pcguide.com/ref/power/sup/form_ATX.htm)没有直接连到电脑的开关，而是插在主板上，可以通过软件控制，下面是 ATX 主板电源接口的信号定义：

![](./pics/2017-11-30_1.jpg)

它还带来了两个重要的变化：

1. 备份电源：主板电源接口上有一个 "+5VSB" 或者 "+5V Standby" 的信号，即使计算机已经关机，这个 5V 信号也会一直供给主板，主板可以持续运行一些最简单的功能，也就是待机状态，我们可以随时唤醒计算机。该信号还有一个作用就是替代 CMOS 电池。
2. 智能电源控制：电源接口还有 PS-ON 和 PW-OK/PS-RDY 信号，代表“电源接通”和“电源就绪”。你可以试试将 PS-ON 信号与地线短接，ATX 电源会立即启动，风扇开始旋转。主板上某个由 +5VSB 供电的组件就是通过短接 PS-ON 和地来启动计算机的。由于电源中有些部分启动一段时间后才能稳定，电源完全稳定后才会打开 PW-OK/PS-RDY 信号，主板会等待该信号打开后才开始引到启动。

所以，计算机的电源键不再是“打开”计算机，它连接在主板的基本控制器上，控制器检测到电源键按下，再启动电源，引导系统。电源键不再是启动系统的唯一方式，扩展总线上的其他设备也可以。这很重要，计算机关机时，以太网适配器还是保持打开的，这样就可以通过以太网远程启动计算机。

## 2. 电源管理

现在的计算机都采用了 ACPI(Advanced Configuration and Power Interface) 技术，它是英特尔等公司提出的操作系统应用程序管理所有电源管理接口的规范，包括了软件和硬件方面的规范，操作系统的电源管理功能通过调用 ACPI 接口，实现对符合 ACPI 规范的硬件设备的电源管理，下面是电源管理与 ACPI 的全局结构图：

![](./pics/2017-11-30_2.png)

ACPI 有个概念叫做 power states ，可以理解为电源状态，操作系统可以通过切换设备的电源状态来控制功耗，主板的电源状态有：

1. G0：工作（计算机处于开机工作状态）
2. G1：睡眠（您的计算机的待机状态，分为几个子状态）
    * S1：CPU 和 RAM 的电源保持打开，但 CPU 未执行指令， 外围设备关闭
    * S2：CPU 关闭，RAM 保持打开
    * S3：所有组件关闭，除了 RAM 和触发恢复的设备（键盘）， 当你告诉操作系统“Sleep”时，它会关闭所有进程，然后进入这个模式。
    * S4：休眠，关闭所有组件。 当您将操作系统告知休眠时，它会停止进程，将 RAM 的内容保存到磁盘，然后进入此模式。
3. G2：软关，这就是计算机的“关机”状态， 除了可以触发引导的设备之外，其他电源均已关闭。
4. G3：机械关闭，ATX 电源本身都已经断电。

ACPI 为 CPU 和计算机上的其他设备都定义了不同的电源状态。

## 3. 重启

当我们在 Linux 系统中执行 reboot 命令时，它会执行系统调用 `reboot()` 函数：

    int reboot(int magic, int magic2, int cmd, void *arg);

函数定义在内核的 kernel/reboot.c 文件中：

    /*
     * Reboot system call: for obvious reasons only root may call it,
     * and even root needs to set up some magic numbers in the registers
     * so that some mistake won't make this reboot the whole machine.
     * You can also set the meaning of the ctrl-alt-del-key here.
     * reboot doesn't sync: do that yourself before calling this.
     */
    SYSCALL_DEFINE4(reboot, int, magic1, int, magic2, unsigned int, cmd, void __user *, arg)

该函数有个 cmd 参数，通过不同的选项调用相应的内核函数实现不同的功能：

* LINUX_REBOOT_CMD_CAD_OFF：禁止 CAD ， 这意味着无法通过 ctrl-alt-del 组合键产生 SIGINT 信号触发重启。
* LINUX_REBOOT_CMD_CAD_ON：使能 CAD ，可以通过 ctrl-alt-del 组合键触发重启
* LINUX_REBOOT_CMD_HALT：关闭操作系统
* LINUX_REBOOT_CMD_KEXEC：重新加载内核，当内核配置了 CONFIG_KEXEC 时才有效
* LINUX_REBOOT_CMD_POWER_OFF：关机，关闭操作系统，然后让计算机的电源进入 G2 状态
* LINUX_REBOOT_CMD_RESTART：立即重启计算机，打印信息 "Restarting system."
* LINUX_REBOOT_CMD_RESTART2：立即重启计算机， 打印信息 "Restarting system with command '%s'" 
* LINUX_REBOOT_CMD_SW_SUSPEND：休眠，将运行状态保存到硬盘，系统挂起，当内核配置了 CONFIG_HIBERNATION 时有效

可以看到，除了重启 ，`reboot()` 函数还可以实现停机和关机的功能，所有 halt 和 poweroff 命令也会调用该函数。以 Linux kernel 4.1 为例，系统重启的流程如下图：

![](./pics/2017-11-30_3.png)

重启会调用内核函数 `kernel_restart()` ，定义在 kernel/reboot.c 文件中：
    
    void kernel_restart(char *cmd)
    {
    	kernel_restart_prepare(cmd);
    	migrate_to_reboot_cpu();
    	syscore_shutdown();
    	if (!cmd)
    		pr_emerg("Restarting system\n");
    	else
    		pr_emerg("Restarting system with command '%s'\n", cmd);
    	kmsg_dump(KMSG_DUMP_RESTART);
    	machine_restart(cmd);
    }
    EXPORT_SYMBOL_GPL(kernel_restart);
    
依次完成如下工作:

1. kernel_restart_prepare(cmd)：向关心系统重启的进程发出通知，各进程会依次关闭，然后设置系统状态为 SYSTEM_RESTART，关闭所有外部设备。
2. syscore_shutdow()：关闭操作系统核心，比如中断
2. machine_restart(cmd)：硬件重置

在 x86 系统中，`machine_restart()` 函数最终会调用 arch/x86/kernel/reboot.c 文件中的 `native_machine_emergency_restart()` 函数，根据不同的重置方式，执行相应的 reboot 代码：

    static void native_machine_emergency_restart(void)
    {
    ......
        for (;;) {
    		/* Could also try the reset bit in the Hammer NB */
    		switch (reboot_type) {
    		case BOOT_ACPI:
    			acpi_reboot();
    			reboot_type = BOOT_KBD;
    			break;
    		case BOOT_KBD:
    			mach_reboot_fixups(); /* For board specific fixups */
        			for (i = 0; i < 10; i++) {
    				kb_wait();
    				udelay(50);
    				outb(0xfe, 0x64); /* Pulse reset low */
    				udelay(50);
    			}
    			if (attempt == 0 && orig_reboot_type == BOOT_ACPI) {
    				attempt = 1;
    				reboot_type = BOOT_ACPI;
    			} else {
    				reboot_type = BOOT_EFI;
    			}
    			break;
    		case BOOT_EFI:
    			efi_reboot(reboot_mode, NULL);
    			reboot_type = BOOT_BIOS;
    			break;
    		case BOOT_BIOS:
    			machine_real_restart(MRR_BIOS);
    			/* We're probably dead after this, but... */
    			reboot_type = BOOT_CF9_SAFE;
    			break;
    		case BOOT_CF9_FORCE:
    			port_cf9_safe = true;
    			/* Fall through */
    		case BOOT_CF9_SAFE:
    			if (port_cf9_safe) {
    				u8 reboot_code = reboot_mode == REBOOT_WARM ?  0x06 : 0x0E;
    				u8 cf9 = inb(0xcf9) & ~reboot_code;
    				outb(cf9|2, 0xcf9); /* Request hard reset */
    				udelay(50);
    				/* Actually do the reset */
    				outb(cf9|reboot_code, 0xcf9);
    				udelay(50);
    			}
    			reboot_type = BOOT_TRIPLE;
    			break;
    		case BOOT_TRIPLE:
    			load_idt(&no_idt);
    			__asm__ __volatile__("int3");
    			/* We're probably dead after this, but... */
    			reboot_type = BOOT_KBD;
    			break;
    		}
        }
    }

可以看出，计算机有多种方式可以重置硬件，在一个无限循环里逐一执行，如果成功，机器就会重启，否则就切换到下一种方法。默认使用 ACPI 方式，其次还有 KBD 、CF9、BIOS、EFI等，使用哪种方式主要取决于内核引导选项 reboot 的设置：

    reboot=[mode][,type][,force]

含义：

* mode 用于指定重启模式，可以使用如下两种模式之一：warm (热重启，跳过内存检测)，cold (冷重启，检测并重新初始化所有硬件)
* type 用于指定重启类型，可以使用如下4种类型之一：bios (为热重启使用 CPU reboot vector)，acpi (优先使用 FADT 中的 ACPI reset register  ，若失败再转为 kbd ，这是目前内核的默认值，定义在 kernel/reboot.c 文件： `enum reboot_type reboot_type = BOOT_ACPI;`)，kbd (使用键盘控制器冷重启)， efi (优先使用 EFI 提供的 reset_system 运行时服务,若失败再转 kbd )
* 结尾的 "force" 表示在重启时不停用其它的 CPU，在某些情况下可以让reboot更可靠。

>系统启动后，可以在 /proc/cmdline 文件查看启动时使用的引导选项以和值。可以使用 "modinfo -p ${modulename}" 命令显示可加载模块的所有可用选项。已经加载到内核中的模块会在 /sys/module/${modulename}/parameters/ 中显示出其选项，并且某些选项的值还可以在运行时通过 "echo -n ${value} > /sys/module/${modulename}/parameters/${parm}" 进行修改。

### 3.1. ACPI reset

ACPI 规定了一个特殊的寄存器 reset register，它可以位于 IO/Memory、或者 PCI bus #0 上的一个设备的配置空间，通过向 reset register 写入特定值来重置计算机。根据 ACPI 的规定，所有硬件必须在这个机制之后重置，主板收到请求后要做如下工作：

* 所有逻辑复位。 这意味着将相应的复位命令发送到包括 CPU，存储控制器，外围控制器等的各种硬件。在大多数情况下，这意味着向设备的 RST 线发送复位信号。
* 然后引导计算机。主板执行的步骤与刚刚在按下电源键后开机的步骤相同。

如果内核使能了 ACPI ，就会通过 ACPI 重置硬件，实现的函数是 `acpi_reboot()` ，定义在 drivers/acpi/reboot.c 文件：

    void acpi_reboot(void)
    {
    	struct acpi_generic_address *rr;
    	struct pci_bus *bus0;
    	u8 reset_value;
    	unsigned int devfn;
    
    	if (acpi_disabled)
    		return;
    
    	rr = &acpi_gbl_FADT.reset_register;
    	/* ACPI reset register was only introduced with v2 of the FADT */
    	if (acpi_gbl_FADT.header.revision < 2)
    		return;
    
    	/* Is the reset register supported? The spec says we should be checking the bit width and bit offset, but Windows ignores these fields */
    	if (!(acpi_gbl_FADT.flags & ACPI_FADT_RESET_REGISTER))
    		return;
    
    	reset_value = acpi_gbl_FADT.reset_value;
    
    	/* The reset register can only exist in I/O, Memory or PCI config space on a device on bus 0. */
    	switch (rr->space_id) {
    	case ACPI_ADR_SPACE_PCI_CONFIG:
    		/* The reset register can only live on bus 0. */
    		bus0 = pci_find_bus(0, 0);
    		if (!bus0)
    			return;
    		/* Form PCI device/function pair. */
    		devfn = PCI_DEVFN((rr->address >> 32) & 0xffff,
    				  (rr->address >> 16) & 0xffff);
    		printk(KERN_DEBUG "Resetting with ACPI PCI RESET_REG.");
    		/* Write the value that resets us. */
    		pci_bus_write_config_byte(bus0, devfn,
    				(rr->address & 0xffff), reset_value);
    		break;
    	case ACPI_ADR_SPACE_SYSTEM_MEMORY:
    	case ACPI_ADR_SPACE_SYSTEM_IO:
    		printk(KERN_DEBUG "ACPI MEMORY or I/O RESET_REG.\n");
    		acpi_reset();
    		break;
    	}
    }
    
 ACPI 编程接口的 [FADT](http://wiki.osdev.org/FADT) 数据结构描述了 reset register ：

    // 12 byte structure; see below for details
    struct GenericAddressStructure
    {
      uint8_t AddressSpace;  
      uint8_t BitWidth;
      uint8_t BitOffset;
      uint8_t AccessSize;
      uint64_t Address;
    };       
    GenericAddressStructure ResetReg;
     uint8_t  ResetValue;

结构成员 AddressSpace 指示了 reset register 所处的地址空间：

Value | Address Space
--- | ---
0 | System Memory
1 | System I/O
2 | PCI Configuration Space

Linux kernel 用 数据结构 `struct acpi_table_fadt` 实现了 FADT，定义在 include/acpi/actbl.h 文件，并定义了变量 `acpi_gbl_FADT` 存放所有数据。如果 reset register 位于 Memory 或者 IO ，`acpi_reboot()`  会调用 `acpi_reset()` 向 `acpi_gbl_FADT.reset_register` 写入 `acpi_gbl_FADT.reset_value` 完成重置。如果 reset register  在 PCI 配置空间，需要先找到配置空间内的地址，然后写入  `acpi_gbl_FADT.reset_value` 。

### 3.2. KBD

KBD 是 keyboard 的缩写，这是通过键盘控制器重置计算机的方式。[8042](http://wiki.osdev.org/%228042%22_PS/2_Controller) 是早期 x86 计算机上的 PS/2 键盘控制器，80 年代 IBM 推出搭载 80268 CPU 的 PC/AT 计算机时，为了解决某些兼容问题，为它添加了很多与键盘无关的功能，比如重置 CPU 。8024 的控制寄存器位于 IO 端口 0x64 ，向它写入 0xfe 就可以重置 CPU ：

    outb(0xfe, 0x64);

由于历史原因，直到今天，x86 计算机上依然需要兼容 PC/AT 机的 8042，这种方式几乎可以重启一切 x86 计算机。

### 3.3. CF9

主板上的南桥芯片也有电源管理的功能，通过 IO 端口 0xCF9 南桥的 Reset Control Register ，以英特尔的南桥芯片 ICH10 为例，寄存器定义详情可以查看芯片的 Datesheet：

![](./pics/2017-11-30_4.png)

内核中有两种选择：

1. 向 IO Port CF9 写 0x06。热重启，这种 reset 方法不会使系统设备掉电，仅仅将 CPU 和系统设备的 status 干净彻底的 reset 一 下。
2. 向 IO Port CF9 写 0x0E。冷重启，这是一种非常彻底的 reset 方法，系统的硬件会掉电，然后重新上电。

### 3.4. BIOS

这种方式会调用一段汇编代码，使 CPU 跳转到 BIOS 的重置代码处，由 BIOS 重启系统，实现方法在 arch/x86/kernel/reboot.c 文件的  `machine_real_restart()` 函数：

    #ifdef CONFIG_X86_32
    	asm volatile("jmpl *%0" : :
    		     "rm" (real_mode_header->machine_real_restart_asm),
    		     "a" (type));
    #else
    	asm volatile("ljmpl *%0" : :
    		     "m" (real_mode_header->machine_real_restart_asm),
    		     "D" (type));

### 3.5. EFI

调用 EFI/UEFI 提供的接口实现重启。

## 4. 参考

* [How does a computer restart itself](https://superuser.com/questions/294681/how-does-a-computer-restart-itself)
* [Debugging ACPI](http://wiki.ubuntu.com/DebuggingACPI)
* [Power management](https://wiki.archlinux.org/index.php/Power_management_(简体中文))
* [ACPI](https://zh.wikipedia.org/wiki/高级配置与电源接口)
* [Reboot](http://wiki.osdev.org/Reboot)
* [Linux 内核引导选项简介](http://www.jinbuguo.com/kernel/boot_parameters.html)
