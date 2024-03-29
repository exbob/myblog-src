---
title: Linux 串口编程笔记
date: 2017-03-27T08:00:00+08:00
draft: false
toc: true
comments: true
---



## 1. 串口简介

这里的串口是指美国电子工业联盟（EIA）制定的三种串行数据通信的接口标准， RS-232 、RS-485 和 RS422 ，RS-232 是单端信号全双工，RS-485 是差分信号半双工，RS-422 是差分信号全双工。差分信号的通信速率更高，通信距离更长，RS-232 的通信距离通常小于 15 米，而 RS-485 和 RS-422 可以达到 100 米以上。

以 RS-232 为例，设计之初是用来连接调制解调器做传输之用，也因此它的脚位意义通常也和调制解调器传输有关。RS-232 的设备可以分为数据终端设备（DTE，Data Terminal Equipment, For example, PC）和数据通信设备（DCE，Data Communication Equipment）两类，这种分类定义了不同的线路用来发送和接受信号。一般来说，计算机和终端设备有DTE连接器，调制解调器和打印机有DCE连接器。标准的 232 接口有 25 针，不过常用的是 9 针的 DB-9 接口，信号定义如下：

脚位	| 简写 | 意义 | 说明
--- | --- | --- | ---
Pin1 | DCD | Carrier Detect | 调制解调器通知电脑有载波被侦测到。
Pin2 | RXD | Receiver | 接收数据。
Pin3 | TXD | Transmit | 发送数据。
Pin4 | DTR | Data Terminal Ready | 电脑告诉调制解调器可以进行传输。
Pin5 | GND | Ground | 地线。
Pin6 | DSR | Data Set Ready | 调制解调器告诉电脑一切准备就绪。
Pin7 | RTS | Request To Send | 电脑要求调制解调器将数据提交。
Pin8 | CTS | Clear To Send | 调制解调器通知电脑可以传数据过来。
Pin9 | RI | Ring Indicator | 调制解调器通知电脑有电话进来。

这个信号说明是从 DTE 设备的角度出发的，TXD、DTR 和 RTS 信号是由 DTE 产生的，RXD、DSR、CTS、DCD 和 RI 信号是由 DCE 产生的。

RS-232 在发送数据时，并不需要另外使用一条传输线来发送同步信号，就能正确的将数据顺利发送到对方，因此叫做“异步传输”，简称UART（Universal Asynchronous Receiver Transmitter），不过必须在每一笔数据的前后都加上同步信号，把同步信号与数据混和之后，使用同一条传输线来传输。比如数据 11001010b 被传输时，数据的前后就需加入 Start(Low）以及 Stop（High）等两个比特，值得注意的是，Start信号固定为一个比特，但 Stop 停止比特则可以是 1、1.5 或者是 2 比特，由收发双方自行选择，但必须保持一致。常见的设置包括波特率、数据位、奇偶校验、停止位和流控制。

* 波特率 (Baud) 表示串口的传输速率叫做波特率，指单位时间内传输符号的个数，在计算机上，通常一个符号就是一个比特，所有可以理解为 bit/s 。因为 5 的 ASCII 码是 01010101b，所以可以发送这个字符，然后用示波器测量出一个 bit 的周期，换算出波特率。典型的波特率是 300, 1200, 2400, 9600, 19200, 115200 等。
* 数据位 (Data) 表示一个数据帧中数据所占的长度，可以设置 5、6、7 或者 8 bit 。
* 奇偶校验 (Parity) 用来验证数据的正确性，一般不使用，如果使用，那么既可以做奇校验（Odd Parity）也可以做偶校验（Even Parity）。奇偶校验是通过修改每一发送字节（也可以限制发送的字节）来工作的。
* 停止位 (Stop)，是在每个字节传输之后发送的，它用来帮助接受信号方硬件重同步，可以设置 1、1.5 或者是 2 bit 。
* 流控制 (flow control) ，当需要发送握手信号或数据完整性检测时需要制定其他设置。可以使用特定的管脚信号组合 RTS/CTS 和 DTR/DSR ，这叫硬件流控制；或者不使用连接器管脚而在数据流内插入特殊字符 XON/XOFF ，称为软件流控制。

RS-232 的逻辑1(mark)的电平为-3～-15V，逻辑0(space)的电平为+3～+15V，注意电平的定义反相了一次。一个典型的数据帧：

![](./pics/2017-03-27_1.jpg)

## 2. 串口操作

Linux 中的串口设备文件通常是 /dev/ttyS0、/dev/ttyS1 ... ，使用 POSIX 终端控制接口编程，串口操作所需的头文件：

    #include     <stdio.h>      /*标准输入输出定义*/
    #include     <stdlib.h>     /*标准函数库定义*/
    #include     <unistd.h>     /*Unix 标准函数定义*/
    #include     <fcntl.h>      /*文件控制定义*/
    #include     <termios.h>    /*POSIX 终端控制定义*/
    #include     <errno.h>      /*错误号定义*/

### 2.1. 打开串口

串口设备也是文件，可以用 `open()` 函数访问。可能遇到的问题是 Linux 系统禁止普通用户访问设备文件，解决方案包括修改设备文件的访问权限，用 root 用户运行程序，或者改变程序的 owner 。假设任何用户都可以访问设备文件，打开串口的代码如下：

    int open_port(void)
    {
        int fd; /* File descriptor for the port */
        fd = open("/dev/ttyS0", O_RDWR | O_NOCTTY | O_NDELAY);
        if (fd == -1)
            perror("open_port: Unable to open /dev/ttyS0");
        else
            fcntl(fd, F_SETFL, 0);
        return (fd);
    }

O_RDWR 表示可读可写；O_NOCTTY 表示不会将这个串口作为该进程的控制终端，如果没有设置这一项，程序会受到键盘控制信号的影响；O_NDELAY 表示无需等待对方串口准备完毕，也就是不会检查 DCD 信号，否则会一直等待 DCD 信号变为 space 。

### 2.2. 读写串口

调用 `write()` 函数向串口写数据即可实现发送：

    n = write(fd, "ATZ\r", 4);

`wirte()` 函数返回成功发送的字节数，如果发送失败会返回 -1 。

从串口读取数据稍显复杂。当串口配置为 raw 数据模式，如果串口的输入缓存区有数据，`read()` 函数调用会立即读取并返回；如果输入缓存区没有数据，`read()` 函数可能会阻塞，等待超时，或者返回错误。可以将 `read()` 函数设为非阻塞模式：

    fcntl(fd, F_SETFL, FNDELAY);

这样，如果没有收到数据，`read()` 会立即返回 0 。也可以改回阻塞模式：
    
    fcntl(fd, F_SETFL, 0);

### 2.3. 关闭串口

调用 `close()` 函数关闭串口：

    close(fd);
    
### 2.4. 一个简单的串口收发程序

send.c ，发送一个字符串 “Hello World”。

	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <fcntl.h>
	#include <unistd.h>
	
	int main(int argc,char **argv)
	{
		int fd = 0;
		int ret = 0;
		char *device = "/dev/ttyS0";
		char send_buf[20] = "Hello World";
		int send_size = 0;
	
		fd = open(device,O_RDWR | O_NOCTTY | O_NDELAY ); //打开 ttyS0，默认为阻塞方式
        if (fd == -1)
            perror("open_port: Unable to open /dev/ttyS0");
        else
            fcntl(fd, F_SETFL, 0);	
            
		send_size = strlen(send_buf);
		ret = write(fd,send_buf,send_size+1);  //将字符串结尾的 \0 也发送
		if(ret < send_size)
		{
			printf("write error\n");
			return -2;
		}
		printf("Send %d characters\n",ret);
		write(fd,"\n",1);     //最后发送一个换行符
		
		close(fd);	
		return 0;
	}

recv.c ，接收字符串，read 函数遇到回车或换行符才会返回。

	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <fcntl.h>
	#include <unistd.h>
	
	int main(int argc,char **argv)
	{
		int fd = 0;
		int ret = 0;
		char *device = "/dev/ttyS1";
		char recv_buf[20];
		int recv_size = 0;
	
		fd = open(device,O_RDWR | O_NOCTTY | O_NDELAY );  //打开 ttyS1，默认为阻塞方式
        if (fd == -1)
            perror("open_port: Unable to open /dev/ttyS1");
        else
            fcntl(fd, F_SETFL, 0);
	
		recv_size = 20;
		ret = read(fd,recv_buf,recv_size);   //阻塞的读取数据
		if(ret < 0)
		{
			perror("read error");
			return -2;
		}
		printf("Receive %d character: %s\n",ret,recv_buf);
		
		close(fd);
		return 0;
	}


Makefile ：

	all:send recv
	
	send:send.c
		gcc -Wall -o $@ $<
	recv:recv.c
		gcc -Wall -o $@ $<
	clean:
		rm -rf send
		rm -rf recv

连接 ttyS0 和 ttyS1 ，首先执行 recv ，因为是阻塞方式，recv 会一直等待数据。然后在另一个终端执行 send ，接收函数就会显示接收到的字符串。

## 3. 串口配置

配置串口涉及到一个结构和两个函数，需要包含头文件 `termios.h` :

    #include <termios.h>
    #define NCCS 32
    struct termios {
        tcflag_t c_cflag; //控制选项
        tcflag_t c_iflag; //输入选项
        tcflag_t c_oflag; //输出选项
        tcflag_t c_lflag; //本地选项
        cc_t     c_line;
        cc_t     c_cc[NCCS]; //控制字符
        speed_t  c_ispeed; //输入速率
        speed_t  c_ospeed; //输出速率
    };
    int tcgetattr(int fd, struct termios *termios_p); //获取当前配置，并保存到 termios_p 中
	int tcsetattr(int fd, int option, const struct termios *termios_p); //将 termios_p 写入配置

`tcsetattr()` 函数的 `option` 参数可以选择三个常量：

* TCSANOW	 立即写入配置，无需等待数据传输完成
* TCSADRAIN	 等待数据传输结束后再更改配置
* TCSAFLUSH	 刷新输入输出缓存，然后再更改配置

### 3.1. 控制选项

`c_cflag` 成员用于设置波特率、数据位、校验位、停止位和硬件流控制，下面是常用的宏，位于 `bits/termios.h` 头文件。

* CBAUD	波特率的位掩码
* B4800	4800 baud
* B9600	9600 baud
* B115200	115,200 baud
* EXTA	External rate clock
* EXTB	External rate clock
* CSIZE	数据位的位掩码
* CS5	5 data bits
* CS6	6 data bits
* CS7	7 data bits
* CS8	8 data bits
* CSTOPB	2 stop bits (1 otherwise)
* CREAD		使能接收
* PARENB	使能校验位，默认为偶校验
* PARODD	设为奇校验
* HUPCL		Hangup (drop DTR) on last close
* CLOCAL	Local line - do not change "owner" of port
* LOBLK		Block job control output
* CNEW_RTSCTS/CRTSCTS	使能硬件流控制 (某些平台不支持)

在传统的POSIX编程中，当不连接一个本地的（通过调制解调器）或者远程的终端（通过调制解调器）时，这里有两个选项应当一直打开，一个是 CLOCAL ，另一个是 CREAD 。这两个选项可以保证你的程序不会变成端口的所有者，而端口所有者必须去处理发散性作业控制和挂断信号，同时还保证了串行接口驱动会读取过来的数据字节。

下面一段代码将设置串口为 9600 8N1 ：

	struct termios options;
	tcgetattr(fd,&options);

	options.c_cflag |= (CLOCAL|CREAD);

	options.c_cflag &= ~CBAUD;
	options.c_cflag |= B9600;

	options.c_cflag &= ~CSIZE;
	options.c_cflag |= CS8;

	options.c_cflag &= ~PARENB;
	options.c_cflag &= ~CSTOPB;

	tcsetattr(fd,TCSANOW,&options);


本地模式

`c_lflag` 用于控制串口驱动怎样控制接收字符。常用的选项用如下几个。

ICANON 

用于设置接收字符的处理模式，如果设置了 ICANON 标志，就启动了标准行输入模式，接收的字符会被放入一个缓冲之中，这样可以用交互方式编辑缓冲的内容，直到收到CR(carriage return)或者LF(line feed)字符。进入该模式时，通常需要将 ECHO 和 ECHOE 选项打开：

	options.c_lflag |= (ICANON | ECHO | ECHOE);

如果清除了 ICANON ，就启动了非标准模式。输入字符只是被原封不动的接收。进入该模式时，通常要关闭 ECHO 、ECHOE 和 ISIG 选项：

	options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);

ECHO

使能输入字符回显。设置该标识后，接收到字符后会自动将字符返回到发送端。

下面的程序中，为接收端的串口设置了该标识，发送端 `write` 之后立即 `read` ，可以读到回显的字符，回显的字符中有一个 `^@` ，表示字符串结尾的空字符，这是因为设置了 ECHOCTL 标识，以 `^char` 的方式回显控制字符。

**send.c：**

	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <fcntl.h>
	#include <unistd.h>
	#include <termios.h>
	
	int main(int argc,char **argv)
	{
		int fd = 0;
		int ret = 0;
		char *device = argv[1];
		char send_buf[20] = "0123456789";
		int send_size = 0;
	
		fd = open(device,O_RDWR | O_NOCTTY );
		if(fd<=0)
		{
			printf("open device error\n");
			return -1;
		}
	
		send_size = strlen(send_buf);
		ret = write(fd,send_buf,send_size+1);  
		if(ret < send_size)
		{
			printf("write error\n");
			return -2;
		}
		
		printf("Send %d characters\n",ret);
		write(fd,"\n",1);     
	
		//读取回显的字符
		ret = 0;
		memset(send_buf,0x00,20);
		ret = read(fd,send_buf,20);
		if(ret > 0)
		{
			printf("ret = %d\n",ret);
			printf("%s\n",send_buf);
		}	
		
	 	close(fd);
	
		return 0;
	}

**read.c：**

	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <fcntl.h>
	#include <unistd.h>
	#include <termios.h>
	
	int main(int argc,char **argv)
	{
		int fd = 0;
		int ret = 0;
		char *device = argv[1];
		char recv_buf[20];
		int recv_size = 0;
		struct termios options;	
	
		fd = open(device,O_RDWR | O_NOCTTY );  
		if(fd<=0)
		{
			printf("open device error\n");
			return -1;
		}
		
		tcgetattr(fd,&options);
		options.c_lflag |= ICANON;
		options.c_lflag |= ECHO | ECHOCTL;
		tcsetattr(fd,TCSANOW,&options);
		
		recv_size = 12;
		ret = read(fd,recv_buf,recv_size);   
		if(ret < 0)
		{
			perror("read error");
			return -2;
		}
		printf("Receive %d character: %s\n",ret,recv_buf);
		
		close(fd);
	
		return 0;
	}

连接 ttyS0 和 ttyS1 ，在第一个终端执行 `./read /dev/ttyS0`，在第二个终端执行 `./send /dev/ttyS1` 可以看到如下结果：

	Send 11 characters
	ret = 13
	0123456789^@

如果清除 ECHOCTL 标识，执行的结果如下：

	Send 11 characters
	ret = 12
	0123456789

**注意，**如果通讯双方都设置了 ECHO 标识，可能会陷入互相回显的死循环。

其他选项

* ISIG	使能 SIGINTR, SIGSUSP, SIGDSUSP, 和 SIGQUIT 信号
* XCASE	Map uppercase \lowercase (obsolete)
* ECHOE	Echo erase character as BS-SP-BS
* ECHOK	接收到 kill 字符后回显一个换行符。
* ECHONL	回显换行符(0x0A)
* NOFLSH	Disable flushing of input buffers after interrupt or quit characters
* IEXTEN	Enable extended functions
* ECHOPRT	Echo erased character as character erased
* ECHOKE	BS-SP-BS entire line on line kill
* FLUSHO	Output being flushed
* PENDIN	Retype pending input at next read or input char
* TOSTOP	Send SIGTTOU for background output


输入模式

`c_iflag` 用于控制接收的数据在传递给程序之前的处理方式。

使能奇偶校验

如果在 c_cflag 中设置了奇偶校验位，就要在这里使能奇偶校验：

	options.c_iflag |= (INPCK | ISTRIP);

INPCK 表示使能奇偶校验，ISTRIP 表示将数据中的奇偶校验位剥离。

使能软件流控制

软件流控制可以通过IXON，IXOFF和IXANY常量设置成有效：

	options.c_iflag |= (IXON | IXOFF | IXANY);

XON(start data)和XOFF(stop data)字符在c_cc数组中定义，关于软件流控制的详细内容在后面介绍。

其他选项

* IGNPAR	Ignore parity errors
* PARMRK	Mark parity errors
* IXON	Enable software flow control (outgoing)
* IXOFF	Enable software flow control (incoming)
* IXANY	Allow any character to start flow again
* IGNBRK	Ignore break condition
* BRKINT	Send a SIGINT when a break condition is detected
* INLCR	Map NL to CR
* IGNCR	Ignore CR
* ICRNL	Map CR to NL
* IUCLC	Map uppercase to lowercase
* IMAXBEL	Echo BEL on input line too long

输出模式

`c_oflag` 用于控制由程序发送的数据在传递给串口或屏幕之前做怎样的处理。很多处理方式和输入模式是相对。

要使用输出模式必须设置 OPOST 标识，否则其他标识都会被忽略，数据会以原始形式发送。

	options.c_oflag |= OPOST;

* OPOST	Postprocess output (not set = raw output)
* OLCUC	Map lowercase to uppercase
* ONLCR	Map NL to CR-NL
* OCRNL	Map CR to NL
* NOCR	No CR output at column 0
* ONLRET	NL performs CR function
* OFILL	Use fill characters for delay
* OFDEL	Fill character is DEL
* NLDLY	Mask for delay time needed between lines
* NL0	No delay for NLs
* NL1	Delay further output after newline for 100 milliseconds
* CRDLY	Mask for delay time needed to return carriage to left column
* CR0	No delay for CRs
* CR1	Delay after CRs depending on current column position
* CR2	Delay 100 milliseconds after sending CRs
* CR3	Delay 150 milliseconds after sending CRs
* TABDLY	Mask for delay time needed after TABs
* TAB0	No delay for TABs
* TAB1	Delay after TABs depending on current column position
* TAB2	Delay 100 milliseconds after sending TABs
* TAB3	Expand TAB characters to spaces
* BSDLY	Mask for delay time needed after BSs
* BS0	No delay for BSs
* BS1	Delay 50 milliseconds after sending BSs
* VTDLY	Mask for delay time needed after VTs
* VT0	No delay for VTs
* VT1	Delay 2 seconds after sending VTs
* FFDLY	Mask for delay time needed after FFs
* FF0	No delay for FFs
* FF1	Delay 2 seconds after sending FFs

控制字符

控制字符都是一些字符组合，例如 Ctrl+C 。当用户键入这些组合键时，终端会采取一些特殊的处理方式。termios 结构中的 c_cc 数组成员将控制字符映射到对于的支持函数。控制字符的位置用一个宏定义（即数组下标）。

c_cc 中的控制字符的数组下标：

<table>
	<tr>
		<td>常量</td><td>键</td><td>字符</td><td>描述</td>
	</tr>
	<tr>
		<td>VINTR</td><td>CTRL-C</td><td></td><td></td>
	</tr>
	<tr>
		<td>VQUIT</td><td>CTRL-Z</td><td></td><td></td>
	</tr>
	<tr>
		<td>VERASE</td><td>Backspase</td><td></td><td></td>
	</tr>
	<tr>
		<td>VKILL</td><td>CTRL-U</td><td></td><td></td>
	</tr>
	<tr>
		<td>VEOF</td><td>CTRL-D</td><td></td><td></td>
	</tr>
	<tr>
		<td>VEOL</td><td>CTRL-D</td><td></td><td></td>
	</tr>
	<tr>
		<td>VSTART</td><td>CTRL-Q</td><td></td><td></td>
	</tr>
	<tr>
		<td>VSTOP</td><td>CTRL-S</td><td></td><td></td>
	</tr>
	<tr>
		<td>VTIME</td><td></td><td></td><td></td>
	</tr>
	<tr>
		<td>VMIN</td><td></td><td></td><td></td>
	</tr>
</table>

 VTIME 和 VMIN

只有在非标准输入模式或者没有通过open(2)和fcntl(2)函数传递NDELAY选项时，这两个值才有效。二者结合起来控制对输入的读取。


## 4. 流控制

## 5. UART、RS-232 与 TTL

逻辑1(mark)的电平为-3～-15V，逻辑0(space)的电平为+3～+15V，注意电平的定义反相了一次。

## 参考

[The Serial Programming Guide for POSIX Operating Systems](https://www.cmrr.umn.edu/~strupp/serial.html)
