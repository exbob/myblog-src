---
title: 为Linux系统配置serial console
date: 2011-07-22T08:00:00+08:00
draft: false
toc:
comments: true
---


原文：

《Remote Serial Console HOWTO》：<http://www.linux.com/learn/docs/ldp/714-Remote-Serial-Console-HOWTO>

Translate By Bob

Friday, July 15, 2011

Email：<gexbob@gmail.com>

Blog：<http://shaocheng.li>

根据我的环境（Redhat 9，Grub 0.93），翻译了我需要的部分。原文还有针对Lilo和Syslinux的配置说明。

***

## 1. 准备工作

### 1.1. 关于serial console

Console是一个输出系统管理信息的文本输出设备，这些信息来自于内核，系统启动和系统用户，serial console就是串口作为输出终端设备，是这些信息可以通过串口在远程的终端上显示。

配置一个serial console大致包括五项内容：

* 配置BIOS使用serial console（可选）；
* 配置Bootloader使用serial console（可选）；
* 配置内核使用serial console
* 在系统启动时运行一个支持serial console登录的程序
* 一些其他系统配置，使这些功能支持serial console，或者防止它们扰乱serial console

### 1.2. 串口线

使用RS232方式的DB9串口线，信号连接如下：

		 Signal ground ------------------ Signal ground
		  Receive data ------------------ Transmit data
		 Transmit data ------------------ Receive data
		 Ready to send ------------------ Clear to send
		 Clear to send ------------------ Ready to send
	ata terminal ready -------------+--- Data carrier detect
	                                |
	                                +--- Data set ready
	Data carrier detect ----+---------------- Data terminal ready
	                        |
	     Data set ready ----+

### 1.3. 串口参数的设置

选择的串口是COM1，设备名为ttyS0，波特率为9600,8位数据位，无奇偶校验，1位停止位。
 
## 2. 配置BIOS

有些BIOS支持serial console，可以在serial console显示BIOS启动信息，这需要在BIOS中配置。
 
## 3. 配置Bootloader

LILO、GRUB和SYSLINUX都支持serial console。

### 3.1. GRUB的配置

GRUB的配置文件是/boot/grub目录下的grub.conf，在配置文件的开始处添加：

	serial --unit=0 --speed=9600 --word=8 --parity=no --stop=1
	terminal --timeout=10 serial console

Serial命令用于设置串口的参数：

	--unit：串口设备，0就表示ttyS0，如果是ttyS1就要设为1；
	--speed：波特率；
	--work：数据位；
	--parity：奇偶校验位；
	--stop：停止位。
	Terminal命令用于设置终端的类型
	--timeout：等待时间，单位是秒
 
## 4. 配置Kernel

Kernel的console类型可以通过console参数选择，console配置的语法如下：

	console=ttyS<serial_port>[,<mode>]
	console=tty<virtual_terminal>
	console=lp<parallel_port>
	console=ttyUSB[<usb_port>[,<mode>] 

其中的ttyS就是串口设备，mode表示串口的参数；tty表示虚拟终端。

每个console类型指南设置一个设备，例如，可以设置为console=tty0 console=lp0 console=ttyS0，但是设为 console=ttyS0 console=ttyS1就是错误的。 

如果没有设置console参数，内核默认使用虚拟终端，即tty0，使用组合键 Ctrl+Alt+F1 可以切换到 tty0。如果你的电脑有显示设备，最好将它设为 console，即 console=tty0。

根据我的设备情况可以设置为：

	console=tty0 console=ttyS0,9600n8

Console参数需要用bootloader在内核启动时传递给内核，对于GRUB，需要修改grub.conf文件，将参数添加到kernel命令后面即可，例如；

grub.conf

	title Red Hat Linux (2.4.9-21)  
	  root (hd0,0)  
	  kernel /vmlinuz-2.4.9-21 ro root=/dev/hda6 console=tty0 console=ttyS0,9600n8  
	  initrd /initrd-2.4.9-21.img  

## 5. 配置getty

getty会监控和等待一个连接，然后配置串口连接，发送/etc/issue的内容，并且要求输入登录名和密码，然后开始登录，如果登录失败，getty会返回等待状态。

getty的另一项工作是设置TERM变量的值，以指定所连接的终端的类型。

常用的getty有四个版本：

*getty：*传统的getty，需要配置文件/etc/gettydefs
*agetty：*无需配置文件，直接通过命令行传递参数
*mgetty：*支持modem的getty，需要配置文件
*minigetty：*精简版的getty，不支持serial console

RedHat9自带agetty和mgetty，在/etc/inittab文件中默认使用mgetty，在该文件中添加：

	co：2345：respawn：/sbin/agetty  -h -t 60 ttyS0 9600 vt102  

-t 60 : 60秒内无操作，agetty将会返回等待状态。

-h ： 使用硬件流控制（CTS/RTS握手）
 
## 6. 其他配置

### 6.1. 让root可以通过serial console登录

配置文件/etc/securetty用于管理root用户可以登录的设备，将serial console的设备名添加到该文件，即可使root用户通过serial console登录。

为了安全性，我们通常root用户在远程登录，而是用普通用户登录，然后用su或sudo命令切换到root。

### 6.2. 将启动基本改为文本方式

这个只针对在没有屏幕的服务器上运行X-Window系统，编辑/etc/inittab文件中包含initdefault的那一行，例如：

	id:5:initdefault:  
改为

	id:3:initdefault:  

如果连接了键盘和显示器，可以用start命令启动X-Window。

####6.2.1. 配置为运行X

有时，一台有serial console却没有连接显示器的电脑依然需要运行X-Window，例如，这台电脑连接有X终端。

这种情况下，计算机还是需要运行在第5级，但是不能为显示器运行X-server。修改/etc/X11/xdm/Xservers,删除所有以冒号开头的行，例如：

	:0 local /usr/X11R6/bin/X  
	
如果操作系统使用的是GNOME，那就要修改它的配置文件/etc/X11/gdm/gdm.conf，删除\[servers\] 段中的所有本地X-Server的条目，例如：

	[servers]  
	0=/usr/bin/X11/X  

### 6.3. 删除已有的console设置

/etc/ioctl.save包含了单用户模式中使用的串口和终端的特性，这些特性通常是有getty来设置的——在没用getty运行的单用户模式下，这个文件的内容被用来设置串口和终端。

因为我们已经改变了console，已有的设置已经不正确了，所以要删除这个文件：

	rm -f /etc/ioctl.save  

一旦我们可以从serial console登录，我们会重建这个文件。

### 6.4. serial console不是/dev/modem

很多Linux会将/dev/modem链接到一个包含可用modem的串口设备。

虽然serial console是一个带有modem的串口，但是我们真的不希望它被用作一个呼叫设备。

检查/dev/modem是否指向了那个用做console的串口，如果是，将它删除。

	bash$ ls -l /dev/modem  
	lrwxrwxrwx 1 root root 10 Jan 01 00:00 /dev/modem -> /dev/ttyS0  
	bash# rm /dev/modem  

### 6.5. 更改/dev/systty的目标

很多Linux将/dev/systty链接到了键盘和显示器所使用的那个终端设备。

如果计算机没有连接键盘和显示器，或者不想给键盘和显示器提供一个文本终端，那就修改/dev/systty，使它指向serial console。

相对于修改链接，修改MAKEDEV使用的配置文件更好，这样会重建链接。配置文件位于/dev/makedev.d目录下，默认配置指向第一个虚拟终端：

	l systty tty0  

修改它，使systty指向用作console的串口：

	bash# cd /etc/makedev.d  
	bash# fgrep systty *  
	linux-2.4.x:l systty tty0  
	bash# vi linux-2.4.x  

将systty那一行改为：

	l systty ttyS0  

然后根据新定义重建/dev/systty:

	bash# cd /dev  
	bash# rm systty  
	bash# ./MAKEDEV systty  

### 6.6. 配置可拔插认证模块

可拔插认证模块系统被用于向用户提供通过console登录系统的特权，它使得设备像软盘那样可以由console用户挂载，通常情况下，挂载磁盘需要超级用户权限。

PAM配置文件/etc/security/console.perms包含&lt;console>变量，对于连接了键盘显示器的系统，默认的&lt;console>变量为：

	<console>=tty[0-9][0-9]* vc/[0-9][0-9]* :[0-9]\.[0-9] :[0-9]  

在该文件的后面部分，console用户被赋予了使用一些设备的权限，设备权限的修改会在登录或退出后生效。
console.perms文件中默认的设备列表如下：

console.perms

	<console>  0660 <floppy>     0660 root.floppy  
	<console>  0600 <sound>      0600 root  
	<console>  0600 <cdrom>      0660 root.disk  
	<console>  0600 <pilot>      0660 root.uucp  
	<console>  0600 <jaz>        0660 root.disk  
	<console>  0600 <zip>        0660 root.disk  
	<console>  0600 <ls120>      0660 root.disk  
	<console>  0600 <scanner>    0600 root  
	<console>  0600 <camera>     0600 root  
	<console>  0600 <memstick>   0600 root  
	<console>  0600 <flash>      0600 root  
	<console>  0600 <fb>         0600 root  
	<console>  0600 <kbd>        0600 root  
	<console>  0600 <joystick>   0600 root  
	<console>  0600 <v4l>        0600 root  
	<console>  0700 <gpm>        0700 root  
	<console>  0600 <mainboard>  0600 root  
	<console>  0600 <rio500>     0600 root  

以上被列出的设备分为两种：一些设备需要来自键盘和显示器的连接，而另一些设备可以方便的连接，这个配置文件无法区分逻辑console和物理console，可通过修改文件来区分二者。

需要键盘和显示器连接的设备如下：

	<console>  0600 <fb>         0600 root  
	<console>  0600 <kbd>        0600 root  
	<console>  0600 <joystick>   0600 root  
	<console>  0600 <v4l>        0600 root  
	<console>  0700 <gpm>        0700 root  

其余的设备要修改为通过serial console来控制。例如，我们不想要一个处于托管位置的非特权用户去挂载软盘。为serial console定义一个新的console类型，叫做&lt;sconsole>，将它添加到console.perms：

	<sconsole>=ttyS0  

然后将其他设备的 &lt;console> 改为 &lt;sconsole>,使它们指向serial console:

	<sconsole>  0660 <floppy>     0660 root.floppy  
	<sconsole>  0600 <sound>      0600 root  
	<sconsole>  0600 <cdrom>      0660 root.disk  
	<sconsole>  0600 <pilot>      0660 root.uucp  
	<sconsole>  0600 <jaz>        0660 root.disk  
	<sconsole>  0600 <zip>        0660 root.disk  
	<sconsole>  0600 <ls120>      0660 root.disk  
	<sconsole>  0600 <scanner>    0600 root  
	<sconsole>  0600 <camera>     0600 root  
	<sconsole>  0600 <memstick>   0600 root  
	<sconsole>  0600 <flash>      0600 root  
	<sconsole>  0600 <mainboard>  0600 root  
	<sconsole>  0600 <rio500>     0600 root  

### 6.7. 针对RedHat的配置

RedHat将一些系统初始化所需的参数存放在 /etc/sysconfig/init。

修改BOOTUP参数，使用独立终端命令写OK、PASSED和FAULT信息，这些信息将不再显示为绿色、黄色或红色。/etc/sysconfig/init 文件的注释说，除了color，还可以设置其他的值，但是，BOOTUP 必须被设为 serial。

修改PROMPT参数，禁止交互启动。

对 /etc/sysconfig/init 的修改如下：

	BOOTUP=serial  
	PROMPT=no

RedHat会运行一个用于发现硬件设备的程序，叫做 kudzu。当发现一个串口时，kudzu会将其复位，这将停止 serial console。kudzu 的配置文件是 /etc/sysconfig/kudzu。

将配置文件中的 SAFE 设为 yes，就会阻止 kudzu 复位设备。

修改 /etc/sysconfig/kudzu:

	SAFE=yes  
  
## 7.  重启测试

### 7.1. 验证console操作

有可能的话，在串口上接一个串口接线盒。在重启的过程中，DTR信号会被激活，出现console信息时，数据指示灯会闪烁。在里一台电脑上配置好终端，重启计算机。

重启过程中，在终端界面可以看到bootloader的启动信息，然后是kernel启动，系统初始化输出，最后会显示/etc/issue的内容，并且getty要求你登录。

如果没有看到login信息，可能会提示按下Return或Enter键。

### 7.2. 重建console设置

用root用户登录serial console。前面我们删除了/etc/ioctl.save，现在要重新配置console，波特率为9600,8位数据位，无奇偶校验，1位停止位。

	remote.example.edu.au ttyS0 login: root  
	Password: …  
	sh# rm -f /etc/ioctl.save  
	bash# telinit 1  
	…Telling INIT to go to single user mode.  
	INIT: Going single user  
	INIT: Sending processes the TERM signal  
	sh# stty sane -parenb cs8 crtscts brkint -istrip -ixoff -ixon  

结束单用户模式返回正常运行级别后，serial console的终端配置会保存到/etc/ioctl.save。

	sh# exit  
	...  
	bash# ls -l /etc/ioctl.save  
	-rw------- 1 root root 60 Jan 1 00:00 /etc/ioctl.save  

当系统以单用户模式启动后，会使用/etc/ioctl.save。
 
## 附录：

我的平台：

两台PC，一个安装Redhat 9，bootlloader为Grub 0.93，另一个安装WindowsXP,用超级终端作为serial console显示设备，用DB9头的串口通信线将二者COM1相连，只将两端的TX和RX信号交叉相连，其他信号都直连。

操作步骤：

1. 修改/boot/grub/grub.conf

	添加：

		serial --unit=0 --speed=9600 --word=8 --parity=no --stop=1  
		terminal --timeout=10 serial console  

	在kernel后面添加参数：

		console=tty0 console=ttyS0,9600n8  
2. 修改/etc/inittab

	添加：

		co：2345：respawn：/sbin/agetty  -t 60 ttyS0 9600 vt100  

3. 在XP系统上打开超级终端，波特率为9600，8位数据位，1位停止位，无奇偶校验，无数据流控制。然后重启Redhat9，在超级终端上即可看到内核和文件系统的启动信息，最后可以用普通用户登录，登录后可以用su root命令切换到root用户。这里有个问题还未解决，文件系统的信息只能在超级终端上显示，在Redhat9的屏幕上显示完内核启动信息后就暂停输出了，最后直接显示登录信息，待解决。

4. 如果想让root用户通过serial console登录，需要修改/etc/securetty，在该文件的最后一行添加ttyS0，重启后即可在超级终端用root用户登录。

5. 其他设置暂未测试。
