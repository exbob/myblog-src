---
title: "在 i.MX 6ULL 上学习 Yocto"
date: 2020-12-12T18:40:11+08:00
draft: false
toc: true
comments: true
images:
tags:
  - untagged

---

# 1. 概述

NXP 为官方评估板  i.MX6ULL EVK  提供了完整的 Yocto 项目源码和文档 ，板卡的外观和接口如图：

![img](./pics/wpsgkfcCn.jpg) 

特性：

![img](./pics/wpsF6ZDic.jpg) 

* 参考板是 iMX6ULL EVK ：https://www.nxp.com/design/development-boards/i-mx-evaluation-and-development-boards/evaluation-kit-for-the-i-mx-6ull-and-6ulz-applications-processor:MCIMX6ULL-EVK
* 芯片是 NXP 的 iMX6ULL : https://www.nxp.com/products/processors-and-microcontrollers/arm-processors/i-mx-applications-processors/i-mx-6-processors:IMX6X_SERIES
* 软件使用最新的 Linux 5.4.47_2.2.0 : https://www.nxp.com/design/software/embedded-software/i-mx-software/embedded-linux-for-i-mx-applications-processors:IMXLINUX

# 2. 构建系统 

我们先为这个板卡编译一个可以运行的系统。

## 2.1. 准备宿主机

使用 Ubuntu 20.04 （至少要用 18.04 ，低版本系统会遇到很多问题），安装必要的开发包：

``` bash
$ sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib \
build-essential chrpath socat cpio python python3 python3-pip python3-pexpect \
xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
pylint3 xterm 
```

安装 repo :

``` bash
$ sudo curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/bin/repo
$ sudo chmod +x /usr/bin/repo
```

需要设置 git 账户：

``` bash
$ git config --global user.name "Your Name"
$ git config --global user.email "Your Email" 
```

新建一个工程目录，然后开始拉取源码：

``` bash
$ mkdir imx-yocto-bsp-5.4.47
$ cd imx-yocto-bsp-5.4.47
$ repo init -u https://source.codeaurora.org/external/imx/imx-manifest -b imx-linux-zeus -m imx-5.4.47-2.2.0.xml
$ repo sync 
```

拉取过程需要连接 google 和 github 的服务器，所以必须翻墙。有些远程仓库使用 git:// 下载很慢，可以修改 .repo/manifests/imx-5.4.47-2.2.0.xml 文件中的 URL ，替换成 https:// 加快下载速度。中途如果卡住，可以结束进程后重新执行 `repo sync` 。也可以在 `repo sync` 命令中添加 -j4 选项，开启四线程下载，加快下载速度。

拉取成功后，会提示 repo sync has finished successfully. ，所有源码会放在 imx-yocto-bsp-5.4.47/sources 目录下:

``` bash
~/imx-yocto-bsp-5.4.47$ ls -l
total 12
lrwxrwxrwx  1 sbs sbs  19 Nov 20 05:55 README -> sources/base/README
lrwxrwxrwx  1 sbs sbs  23 Nov 20 05:55 README-IMXBSP -> sources/meta-imx/README
drwxrwxr-x  3 sbs sbs 4096 Nov 20 07:08 downloads
lrwxrwxrwx  1 sbs sbs  43 Nov 20 05:55 imx-setup-release.sh -> sources/meta-imx/tools/imx-setup-release.sh
lrwxrwxrwx  1 sbs sbs  30 Nov 20 05:55 setup-environment -> sources/base/setup-environment
drwxrwxr-x 16 sbs sbs 4096 Nov 20 05:55 sources
```

## 2.2. 配置

NXP 提供了一个脚本 imx-setup-release.sh，它简化了 i.MX 机器的设置。语法：

``` bash
[MACHINE=<machine>] [DISTRO=fsl-imx-<backend>] source ./imx-setup-release.sh -b <build folder>
```

* MACHINE 表示目标机的硬件名称，当前版本支持的硬件可以在 meta-imx/README 文件中查看，实际上是指向了 meta-imx/meta-bsp/conf/machine 目录下的相应配置文件。对于 i.MX 6ULL EVK 开发板，要设为 imx6ull14x14evk 。
* DISTRO 是发行版的名称，需要设置为 meta-imx/meta-sdk/conf/distro 目录下存在的配置文件（不用带后缀），这个配置文件设置了该发行版包含哪些软件。当前版本支持发行版有：
    * fsl-imx-fb.conf，支持 framebuff 图像界面的系统
    * fsl-imx-wayland.conf，支持 wayland 协议的系统
    * fsl-imx-x11.conf，支持 x11 协议的系统
    * fsl-imx-xwayland.conf，同时支持 x11 和 wayland 的系统
* build folder 用于指定编译目录，每个发行版都应该有独立的编译目录，编译过程中产生的所有文件都会输出到这个目录下。

在 imx-yocto-bsp-5.4.47 目录下执行：

```
MACHINE=imx6ull14x14evk DISTRO=fsl-imx-fb source ./imx-setup-release.sh -b imx6ullevk-fb
```

根据提示接受 EULA 协议，执行成功后，会自动进入 imx-yocto-bsp-5.4.47/imx6ullevk-fb 目录，所有的配置文件都位于 conf 目录下：

* bblayers.conf  包含了本发行版所需的所有 layer ，编译时，会到这些 layer 下找相应的 recipe 。
* local.conf 包含了一些编译设置选项，比如指定了硬盘平台的 MACHINE 变量。

## 2.3. 编译

官方提供了多种编译目标，可以根据需要选择，或者在此基础上修改：

![img](./pics/wpsXP7dFt.jpg)

这里编译一个基础版本：

``` bash
$ bitbake core-image-base
```

网络良好的情况下，大约需要 5 小时。下载的软件包源码都位于 imx-yocto-bsp-5.4.47/downloads 目录下。如果出现类似如下的错误，通常是网络连接的问题，确保可以访问 [www.example.com](http://www.example.com) 后即可正常编译：

```
Fetcher failure for URL: 'https://www.example.com/'. URL https://www.example.com/ doesn't work.
```

## 2.4. 烧写

编译成功后，输出的文件位于 tmp/deploy/images/imx6ull14x14evk 目录下，用于 SD/MMC/eMMC 的镜像压缩文件是 core-image-base-imx6ull14x14evk.wic.bz2，它包含了 U-boot ，设备树，内核和根文件系统，可以用如下命令直接写入 SD 卡：

``` bash
$ bunzip2 -dk -f <image_name>.wic.bz2
$ sudo dd if=<image name>.wic of=/dev/sd<partition> bs=1M conv=fsync 
```

默认的 .wic 镜像上的 rootfs 被限制在 4GB 以下，但重新分区和重新加载 rootfs 可以将其增加到卡的大小。默认情况下，该版本对SD卡上的镜像使用以下布局。内核映像和 DTB 移动到使用 FAT 分区，在 SD 卡上没有固定的原始地址。如果需要固定的原始地址，用户必须改变 U-Boot 的启动环境。

![img](./pics/wpsAqCcYQ.jpg) 

为了灵活使用，也有可以单独烧写的组件：

* u-boot-imx6ull14x14evk.imx，U-boot 文件
* imx6ull-14x14-evk-emmc-imx6ull14x14evk.dtb ，设备树文件
* zImage-imx6ull14x14evk.bin， 内核文件
* core-image-base-imx6ull14x14evk.tar.bz2 ，根文件系统压缩文件。

上面这些文件通常是一个软链接，每次编译后都会指向最新编译生成的实际文件。关于单独烧写的详细信息可以参考 i.MX Linux® User's Guide (IMXLUG) 中的  "4.3 Preparing an SD/MMC card to boot" 。如果要烧写到板载的 eMMC ，通常是用 UUU 工具，通过 USB-OTG 接口烧写。

## 2.5. 安装

1. 将 TF卡安装到 CPU 板的 MicroSD 插槽（J301）
2. 用 USB 线缆（Micro-B 转标准-A）连接开发板的调试 USB 口（J1901 ）和电脑的 USB 口，在电脑的设备管理器上可以看到串口设备（需要安装驱动）：
    ![img](/images/2020-12-12/wpssg94Ws.jpg) 
3. 在电脑上打开一个串口终端，比如 putty ，按如下配置：
    * 波特率： 115200
    * 数据位： 8
    * 停止位： 1
    * 奇偶校验：无
    * 流控制：无 
4. 将 CPU 板的启动模式选择开关（SW602）设为 D1:ON、 D2:OFF ，启动设备选择开关（SW601）设为 D1:OFF、 D2:OFF、 D3:ON、 D4:OFF ，表示从 TF 卡启动：
    ![img](/images/2020-12-12/wpsTaqH0k.jpg) 
    ![img](/images/2020-12-12/wpspxtemJ.jpg) 
    ![img](/images/2020-12-12/wps1gfhId.jpg) 
5. 连接电源，将电源开关（SW2001）滑至 ON ，系统即开始启动，在串口终端软件上可以看到启动过程。
6. 启动完毕后会看到登录提示符，用户名是 root ，无密码。

# 3. 使用 UUU 

Universal Update Utility（UUU）是 MFGTools 的最新演进版(也叫做 MFGTools v3)，可以在 Win10 64bit 和 Ubuntu 16.14 64bit 以上版本的主机上运行，是NXP官方开发的镜像烧写工具，我们主要是用它通过 USB-OTG 接口将各种系统镜像组件烧写到板载的 eMMC 。可以在 https://github.com/NXPmicro/mfgtools/releases 下载软件和文档，当前版本是 1.4.43 。

## 3.1. 准备 

需要将板上的 SD 卡取出，换成 eMMC ，然后将启动模式改为串行下载器（SW602:D1:OFF,D2:ON)。使用 USB-OTG 数据线将板载的 OTG 接口连接到电脑。 在电脑端打开 PowerShell 环境，进入 uuu 程序的目录，执行 `uuu.exe -lsusb` ，会列出识别到的 USB Device ：

```
PS D:\NXP_iMX6\UUU> .\uuu.exe -lsusb
uuu (Universal Update Utility) for nxp imx chips -- libuuu_1.4.43-0-ga9c099a

Connected Known USB Devices
     Path   Chip   Pro   Vid   Pid   BcdVersion
     ==================================================
     1:4    MX6ULL  SDP:   0x15A2 0x0080  0x0001
```

可以将调试串口也连接到电脑，会有信息打印输出。

## 3.2. 烧写 BootLoader

以烧写 u-boot 为例，将 u-boot 镜像文件放在 uuu 程序的目录下，然后执行 `uuu.exe -b emmc <bootloader>` ，立即开始烧写，烧写成功显示如下：

```
PS D:\NXP_iMX6\UUU> .\uuu.exe -b emmc .\u-boot-sd-optee-2020.04-r0.imx
uuu (Universal Update Utility) for nxp imx chips -- libuuu_1.4.43-0-ga9c099a

Success 1   Failure 0

1:6    7/ 7 [Done                  ] FB: Done
```

在电脑的串口终端也可以调试串口打印的详细烧写过程：

```
U-Boot 2020.04-5.4.47-2.2.0+gffc3fbe7e5 (Nov 23 2020 - 03:48:29 +0000)

CPU:  i.MX6ULL rev1.1 900 MHz (running at 396 MHz)
CPU:  Commercial temperature grade (0C to 95C) at 43C
Reset cause: POR
Model: i.MX6 ULL 14x14 EVK Board
Board: MX6ULL 14x14 EVK
DRAM:  512 MiB
MMC:  FSL_SDHC: 0, FSL_SDHC: 1
Loading Environment from MMC... *** Warning - bad CRC, using default environment

[*]-Video Link 0 (480 x 272)
      [0] lcdif@21c8000, video
In:   serial
Out:  serial
Err:  serial
switch to partitions #0, OK
mmc1(part 0) is current device
flash target is MMC:1
Net:
Warning: ethernet@20b4000 using MAC address from ROM
eth1: ethernet@20b4000 [PRIME]Get shared mii bus on ethernet@2188000

Warning: ethernet@2188000 using MAC address from ROM, eth0: ethernet@2188000
Fastboot: Normal
Boot from USB for mfgtools
*** Warning - Use default environment for mfgtools, using default environment

Run bootcmd_mfg: run mfgtool_args;if iminfo ${initrd_addr}; then if test ${tee} = yes; then bootm ${tee_addr} ${initrd_addr} ${fdt_addr}; else bootz ${loadaddr} ${initrd_addr} ${fdt_addr}; fi; else echo "Run fastboot ..."; fastboot 0; fi;

Hit any key to stop autoboot:  0

## Checking Image at 86800000 ...
Unknown image format!
Run fastboot ...
switch to partitions #0, OK
mmc1(part 0) is current device
Starting download of 543744 bytes
....

downloading of 543744 bytes finished
writing to partition 'bootloader'
Initializing 'bootloader'
switch to partitions #1, OK
mmc1(part 1) is current device
Writing 'bootloader'

MMC write: dev # 1, block # 2, count 1062 ... 1062 blocks written: OK
Writing 'bootloader' DONE!
```

烧写完毕后，将启动模式设为 eMMC 启动（SW602:D1:ON,D2:OFF; SW601:D1:OFF,D2:ON,D3:ON,D4:OFF），然后按下复位键，主板复位，在串口终端可以看到 u-boot 的启动信息：

```
U-Boot 2020.04-5.4.47-2.2.0+gffc3fbe7e5 (Nov 23 2020 - 03:48:29 +0000)

CPU:  i.MX6ULL rev1.1 900 MHz (running at 396 MHz)
CPU:  Commercial temperature grade (0C to 95C) at 47C
Reset cause: POR
Model: i.MX6 ULL 14x14 EVK Board
Board: MX6ULL 14x14 EVK
DRAM:  512 MiB
MMC:  FSL_SDHC: 0, FSL_SDHC: 1
Loading Environment from MMC... *** Warning - bad CRC, using default environment

[*]-Video Link 0 (480 x 272)
      [0] lcdif@21c8000, video
In:   serial
Out:  serial
Err:  serial
switch to partitions #0, OK
mmc1(part 0) is current device
flash target is MMC:1
Net:
Warning: ethernet@20b4000 using MAC address from ROM
eth1: ethernet@20b4000 [PRIME]Get shared mii bus on ethernet@2188000

Warning: ethernet@2188000 using MAC address from ROM, eth0: ethernet@2188000
Fastboot: Normal
Normal Boot
Hit any key to stop autoboot:  0
=>
```

## 3.3. 烧写系统镜像 

烧写系统镜像的语法是 `uuu.exe -b emmc_all <bootloader> <rootfs.wic.bz2>` ,例如：

```
PS D:\NXP_iMX6\UUU> .\uuu.exe -b emmc_all .\u-boot-sd-optee-2020.04-r0.imx .\core-image-base-imx6ull14x14evk-20201123024550.rootfs.wic.bz2
uuu (Universal Update Utility) for nxp imx chips -- libuuu_1.4.43-0-ga9c099a

Success 1   Failure 0

1:6    8/ 8 [Done                  ] FB: done
```


烧写完毕后，将启动模式设为 eMMC 启动（SW602:D1:ON,D2:OFF; SW601:D1:OFF,D2:ON,D3:ON,D4:OFF），然后按下复位键，主板复位，在串口终端可以看到系统启动信息。

```
U-Boot 2020.04-5.4.47-2.2.0+gffc3fbe7e5 (Nov 23 2020 - 03:48:29 +0000)

CPU:  i.MX6ULL rev1.1 900 MHz (running at 396 MHz)
CPU:  Commercial temperature grade (0C to 95C) at 43C
Reset cause: POR
Model: i.MX6 ULL 14x14 EVK Board
Board: MX6ULL 14x14 EVK
DRAM:  512 MiB
MMC:  FSL_SDHC: 0, FSL_SDHC: 1
Loading Environment from MMC... *** Warning - bad CRC, using default environment

[*]-Video Link 0 (480 x 272)
     [0] lcdif@21c8000, video
In:   serial
Out:  serial
Err:  serial
switch to partitions #0, OK
mmc1(part 0) is current device
flash target is MMC:1
Net:
Warning: ethernet@20b4000 using MAC address from ROM
eth1: ethernet@20b4000 [PRIME]Get shared mii bus on ethernet@2188000

Warning: ethernet@2188000 using MAC address from ROM, eth0: ethernet@2188000
Fastboot: Normal
Boot from USB for mfgtools
*** Warning - Use default environment for mfgtools, using default environment

Run bootcmd_mfg: run mfgtool_args;if iminfo ${initrd_addr}; then if test ${tee} = yes; then bootm ${tee_addr} ${initrd_addr} ${fdt_addr}; else bootz ${loadaddr} ${initrd_addr} ${fdt_addr}; fi; else echo "Run fastboot ..."; fastboot 0; fi;
Hit any key to stop autoboot:  0
......

NXP i.MX Release Distro 5.4-zeus imx6ull14x14evk ttymxc0

imx6ull14x14evk login:
```

# 4. 使用 U-boot

内核和文件系统还可以使用 u-boot 下载。 

# 5. Yocto系统开发 

Yocto系统开发的学习过程可以参考 https://www.yoctoproject.org/docs/what-i-wish-id-known/ 。

前面是使用官方提供的配置编译出系统镜像，通常我们需要根据实际情况定制自己的系统。在 Yocto 工程中，工作开始之前，都应该初始化编译环境，语法是：`source setup-environment <build dir>` 。

## 5.1. OpenEmbedded

Yocto 是一个开源合作项目，它帮助开发人员创建基于 Linux 的定制系统，使用 OpenEmbedded 开发模型构建。

![img](./pics/wpsrtxo05.jpg) 

几个概念：

* Layers ，中文可以叫做层。Layer 被用来分类不同的任务单元。某些任务单元有共同的特性，可以放在一个 Layer 下，方便模块化组织元数据，也方便日后修改。例如要定制一套支持特定硬件的系统，可以把与低层相关的单元放在一个 layer 中，这叫做 Board Support Package(BSP) Layer 。
* Configuration ，中文叫做配置。Configuration 文件的后缀是 .conf ，它会在很多地方出现，定义了多种变量，包括硬件架构选项、编译器选项、通用配置选项、用户配置选项。主 Configuration 文件是 bitbake.conf ，以 Yocto 为例，位于 ./poky/meta/conf/bitbake.conf ，其他都在源码树的 conf 目录下。
* Classes ，中文叫做类。Class 文件的后缀是 .bbclass ，它的内容是元数据文件之间的共享信息。BitBake 源码树都源自一个叫做 base.bbclass 的文件，在 Yocto 中位于 ./poky/meta/classes/base.bbclass ，它会被所有的 recipe 和 class 文件自动包含。它包含了标准任务的基本定义，例如获取、解压、配置、编译、安装、打包，有些定义只是框架，内容是空的。
* Recipe ，中文叫做菜单或者配方。Recipe 文件是最基本的元数据文件，每个任务单元对应一个 Recipe 文件，后缀是 .bb ，这种文件为 BitBake 提供的信息包括软件包的基本信息（作者、版本、License等）、依赖关系、源码的位置和获取方法、补丁、配置和编译方法、如何打包和安装。
* Append ，中文叫做追加。Append 文件的后缀是 .bbappend ，用于扩展或者覆盖 recipe 文件的信息。BitBake 希望每一个 append 文件都有一个相对应的 recipe 文件，两个文件使用同样的文件名，只是后缀不同，例如 formfactor_0.0.bb 和 formfactor_0.0.bbappend 。命名 append 文件时，可以用百分号（%）来通配 recipe 文件名。例如，一个名为 busybox_1.21.%.bbappend 的 apend 文件可以对应任何名为 busybox_1.21.x.bb 的 recipe 文件进行扩展和覆盖，文件名中的 x 可以为任何字符串，比如 busybox_1.21.1.bb、busybox_1.21.2.bb … 通常用百分号来通配版本号。

OpenEmbedded 的工作流如下：

![img](./pics/wpsioFQSO.jpg) 


参考：[https://www.yoctoproject.org/docs/3.1.2/overview-manual/overview-manual.html](https://www.yoctoproject.org/docs/3.1.2/overview-manual/overview-manual.html#overview-manual-concepts)

## 5.2. 目录结构

通常情况下，我们会使用一个硬件原厂发布的 BPS 源码编译系统镜像，BSP 源码包含了 Yocto 项目的参考发行版 poky 包，还有原厂加入的扩展包，当完成了第一次系统构建后，工程目录下的文件结构大致如下：

```
imx-yocto-bsp-5.4.47
├── downloads # bitbake 下载的软件包都放在这里
├── imx6ullevk-fb # 工作目录，编译过程产生的所有文件都在这里，我们自己添加的源码也应该放在这里。
├── imx-setup-release.sh # 配置脚本
├── README
├── README-IMXBSP
├── setup-environment # 用于初始化编译环境的脚本
└── sources # 原厂官方提供的 BSP 源码，通常不要直接修改这个目录下的文件。
    ├── base  # 原厂添加的包
    ├── meta-browser
    ├── meta-freescale
    ├── meta-freescale-3rdparty
    ├── meta-freescale-distro
    ├── meta-imx
    ├── meta-openembedded
    ├── meta-python2
    ├── meta-qt5
    ├── meta-rust
    ├── meta-timesys
    └── poky # Yocto 项目的主仓库
```

下载的软件包都放在 downloads 目录下，并生成一个后缀为 .done 的空文件，表示指定的包已经下载完毕。如果使用 bitbake 下载某个包失败，也可以手动下载，然后放到 downloads 路径下，并新建一个 .done 文件，这样 bitbake 工作时就会任务 fetch 任务已经完成。

poky 是 yocto 项目的参考发行版，官方文档都是基于这个包讲解的，单独使用这个包可以构建一个运行在 QEMU 虚拟机上的系统。它包含了构建系统所需的核心包，比如 Linux 内核的 recipe 。

meta-openembedded 提供很多扩展包。meta-imx 和 meta-freescale* 都是 NXP 官方提供的，针对硬件的扩展。

我们需要在此基础上添加或者修改一些包，完成自己的特定需求。这时，建议在工作目录下新建一个 layer ，在 layer 中包含自己的 append (.bbappend) 文件和 recipe(.bb)文件，来完成相应的工作，尽量不要修改 sources 目录下的文件。

源码目录结构的详细信息可以查看 https://www.yoctoproject.org/docs/3.0.4/ref-manual/ref-manual.html#ref-structure 。

## 5.3. Bitbake

Bitbake 手册：https://www.yoctoproject.org/docs/3.1.2/bitbake-user-manual/bitbake-user-manual.html

OpenEmbedded 构建系统时使用的生产工具是 BitBake ，是用 Python 写的一个程序，现在有很多嵌入式系统都是在使用，比如Yocto 、WindRiver Linux 等。它是一个多任务引擎，可以并行执行 shell 和 Python 任务，每个任务单元根据预定义的元数据来管理源码、配置、编译、打包，并最终将每个任务生成的文件集合成为系统镜像。例如要从源码构建一个 Linux 系统，需要搭建一个生产环境，然后依次生成 Grub、Kernel、各种库文件、各种可执行文件，然后集合到一个文件系统里。如果你玩过 LFS ，就会了解这个过程的复杂性。BitBake 存在的意义就是提供了一个高效的工具，将这个过程标准化、流程化。BitBake 与 GNU Make 的关系就像 GNU Make 之于 GCC ，运作方式也类似 GNU Make ，又有很多不同：

* BitBake 根据预先定义的元数据执行任务，这些元数据定义了执行任务所需的变量，执行任务的过程，以及任务之间的依赖关系，它们存储在 recipe(.bb)、append(.bbappend)、configuration(.conf)、include(.inc) 和 class(.bbclass) 文件中。
* BitBake 包含一个抓取器，用于从不同的位置获取源码，例如本地文件、源码控制器(git)、网站等。
* 每一个任务单元的结构通过 recipe 文件描述，描述的信息有依赖关系、源码位置、版本信息、校验和、说明等等。
* BitBake 包含了一个 C/S 的抽象概念，可以通过命令行或者 XML-RPC 使用，拥有多种用户接口。

执行 `bitbake -s` 命令可以列出当前项目中所有可构建的包和版本。构建一个包的最简单方法是执行 `bitbake <package_name>` ，Bitbake 会搜索这个包的 recipe 文件，找到后就解析 recipe 中的配置选项，然后依次执行如下任务（task）。

1. Fetch--从远程或者本地获取源码
2. Extract--将源码解压到指定的工作目录下，之后所有的构建工作都在这个工作目录下进行
3. Patch--为错误修复和新功能应用补丁文件
4. Configure--进行编译前的配置工作
5. Compile--编译和链接
6. Install--将文件复制到目标目录下
7. Package--生成安装包

也可以通过 -c 参数执行单独的任务，例如只下载源码可以执行  `bitbake <package_name> -c fetch` 。所有任务可以在 https://www.yoctoproject.org/docs/3.0.4/ref-manual/ref-manual.html#ref-tasks 查询。常用的任务选项有：

* fetch ，下载源码
* unpack ，解压源码
* patch ， 打补丁
* configure ，配置
* compile ，编译
* clean ，删除最终输出的文件
* clearsstate ，删除编译过程产生的所有文件
* cleanall ，删除所有文件，包括下载的源码包，编译过程的缓存文件和最终的输出文件。

此外，执行 listtasks 选项可以查看所有可用的任务，例如查看 linux-imx 的任务列表和描述：

```bash
bitbake linux-imx -c listtasks
```

执行 `bitbake -e <package>` 可以解析特定包的配置选项。例如查找 Linux 内核的包名称和版本可以执行：

``` bash
~/imx-yocto-bsp-5.4.47/imx6ullevk-fb$ bitbake -s | grep linux
binutils-crosssdk-x86_64-pokysdk-linux         :2.32.0-r0
cryptodev-linux                    :1.10-r0
cryptodev-linux-native                :1.10-r0
gcc-crosssdk-x86_64-pokysdk-linux          :9.2.0-r0
go-crosssdk-x86_64-pokysdk-linux          :1.12.9-r0
linux-atm                      :2.5.2-r0
linux-firmware                  1:20190815-r0
linux-imx                       :5.4-r0
linux-imx-headers                   :5.4-r0
linux-imx-mfgtool                 :4.14.98-r0
```

很明显，linux-imx 就是当前项目的 Linux 内核，然后先定位 recipe 文件的位置：

``` bash
~/imx-yocto-bsp-5.4.47/imx6ullevk-fb$ bitbake -e linux-imx | grep ^FILE=
FILE="/home/sbs/imx-yocto-bsp-5.4.47/sources/meta-imx/meta-bsp/recipes-kernel/linux/linux-imx_5.4.bb"
```

有时候，我们还需要知道这个 recipe 依赖的 conf、bbclass 、bbappend 等文件，可以通过 `BBINCLUDED` 变量获得：

```bash
~/imx-yocto-bsp-5.4.47/imx6ullevk-fb$ bitbake -e linux-imx | grep ^BBINCLOUD=
```

然后我们可以定位构建这个包时的工作目录：

``` bash
~/imx-yocto-bsp-5.4.47/imx6ullevk-fb$ bitbake -e linux-imx | grep ^WORKDIR=
WORKDIR="/home/sbs/imx-yocto-bsp-5.4.47/imx6ullevk-fb/tmp/work/imx6ull14x14evk-poky-linux-gnueabi/linux-imx/5.4-r0"
```

定义源码解压后的位置：

``` bash
~/imx-yocto-bsp-5.4.47/imx6ullevk-fb$ bitbake -e linux-imx  | grep ^S=
S="/home/sbs/imx-yocto-bsp-5.4.47/imx6ullevk-fb/tmp/work/imx6ull14x14evk-poky-linux-gnueabi/linux-imx/5.4-r0/git"
```


定位源码的编译目录：

``` bash
~/imx-yocto-bsp-5.4.47/imx6ullevk-fb$ bitbake -e linux-imx  | grep ^B=
B="/home/sbs/imx-yocto-bsp-5.4.47/imx6ullevk-fb/tmp/work/imx6ull14x14evk-poky-linux-gnueabi/linux-imx/5.4-r0/build"
```

工作目录下还有几个重要的文件夹：

1. image ，存放这要安装到目标系统的文件，而且是按照安装路径存放。
2. deploy ，存放 rpm ，deb 等格式的安装包
3. tmp ，存放了构建过程中执行的所有任务指令，已经执行过程的日志。

BitBake 执行任务的顺序由其任务调度器控制。`${WORKDIR}/tmp/` 目录下，以 `run_` 开头的文件记录了每个任务解析后的详细内容，以 `log_` 开头的文件记录任务执行时的日志，`log.task_order` 文件按顺序记录了当前目标执行了哪些任务。

关于 recipe 文件中其他选项的含义可以查看 https://www.yoctoproject.org/docs/3.0.4/ref-manual/ref-manual.html#ref-varlocality-recipes 。

## 5.4. 新建 Layer

新建 layer 的过程可以手动完成，但是推荐使用 bitbake-layers 脚本的create-layer子命令来简化创建过程。基本的语法是 `bitbake-layers create-layer <your_layer_name>` ，这条命令会按默认的模式新建如下文件：

* 一个名为 your_layer_name 的文件夹，注意，layer 的名称应该以 meta- 为前缀，且不要与已有的 layer 重名。
* 一个配置文件 conf/layer.conf ，内容如下：
    ``` bash
    # We have a conf and classes directory, add to BBPATH
    BBPATH .= ":${LAYERDIR}"

    # We have recipes-* directories, add to BBFILES
    BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
                ${LAYERDIR}/recipes-*/*/*.bbappend"
    BBFILE_COLLECTIONS += "mylayer"
    BBFILE_PATTERN_mylayer = "^${LAYERDIR}/"
    BBFILE_PRIORITY_mylayer = "6"

    LAYERDEPENDS_mylayer = "core"
    LAYERSERIES_COMPAT_mylayer = "warrior zeus"
    ```
    * BBPATH：将 layer 的根目录添加到 BitBake 的搜索路径中。通过使用 BBPATH 变量，BitBake可以定位类文件（.bbclass）、配置文件以及包含在 include 和 require 语句中的文件。在这些情况下，BitBake 会使用第一个与 BBPATH 中找到的文件名相匹配的文件。这与 PATH 变量用于二进制文件的方式类似。因此，建议你在自定义层中使用唯一的类和配置文件名。
    * BBFILES: 定义 layer 中所有 recipes 的位置。
    * BBFILE_COLLECTIONS：定义了当前层中所有配方的位置。通过独特的标识符建立当前层，该标识符在整个OpenEmbedded构建系统中用于引用该层。在本例中，标识符 "yoctobsp" 是名为 "meta-yocto-bsp" 的容器层的表示。
    * BBFILE_PATTERN: 在解析过程中立即展开，提供层的目录。
    * BBFILE_PRIORITY: 建立了一个优先级，当 OpenEmbedded 构建发现不同层中的同名配方时，该层中的配方将被使用。
    * LAYERVERSION：为图层建立一个版本号，你可以在使用 LAYERDEPENDS 变量时使用这个版本号来指定这个图层的确切版本作为依赖关系。当使用 LAYERDEPENDS 变量时，你可以使用这个版本号来指定这个层的确切版本作为依赖关系。
    * LAYERDEPENDS: 列出这个图层所依赖的所有图层（如果有的话）。
    * LAYERSERIES_COMPAT: 列出当前版本兼容的 Yocto 项目版本。这个变量是表明你的图层是否是当前版本的好方法。

* 一个 recipes-example 子目录，其中包含了另一个名为 example 的子目录，其中包含了一个 example.bb 配方文件
* 一个 COPYING.MIT ，这是该层的许可证声明。脚本假设你想对图层本身的内容使用 MIT 许可证，这对大多数图层来说是典型的。
* 一个 README 文件，这是一个描述新图层内容的文件。

我们新建一个名为 meta-mylayer 的层：

``` bash
$ bitbake-layers create-layer meta-mylayer
```

新建完毕后，需要根据 layer 的类型，添加内容。如果该层添加了对机器的支持，则在该层的conf/machine/文件中添加机器配置。如果该层增加了发行版策略，就把发行版配置添加到该层内的conf/distro/ 文件中。如果图层引入了新的配方，把你需要的配方放在图层内的 recipes-* 子目录中。

要想 bitbake 编译时找到这个新建的 layer ，还需要把它添加到 conf/bblayers.conf 文件的 BBLAYERS 变量中，例如：

```
BBLAYERS += "${BSPDIR}/imx6ullevk-fb/meta-mylayer"
```

这一步也可以使用脚本完成：

```
$ bitbake-layers add-layer meta-mylayer
```

BitBake按照 BBLAYERS 变量的设置，自上而下地解析每个 conf/layer.conf 文件。在处理每个 conf/layer.conf 文件的过程中，BitBake会将特定层中包含的配方、类和配置添加到源目录中。

有些工作可能已经有前人做过了，我们可以在 [OpenEmbedded Metadata Index](http://layers.openembedded.org/layerindex/branch/master/layers/) 下查找特定功能 layer ，拿来直接用。

## 5.5. 自定义系统镜像

自定义系统镜像主要是修改构建系统的源码，定制输出到目标镜像的文件，有很多种方式，比如修改 con/local.conf 文件，这里的修改是全局性的，会所有的镜像生效，不利于项目的工程化管理，最好的方式依然是在自定义的 layer 中添加对源码的修改。例如，要定制 fsl-image-machine-test 生成的镜像，就可以新建一个 image-machine-test.bbappend 文件进行修改。

### 5.5.1. 添加或删除包

定制系统时,经常要添加一个包到目标镜像中，或者从目标镜像里删除一个已有的包。Yocto 构建系统镜像时，主要是通过 IMAGE_INSTALL 和 IMAGE_IMAGE_FEATURES 两个变量来确定目标镜像要安装那些包，以构建 fsl-image-machine-test 系统镜像为例：

``` shell
$ bitbake -e fsl-image-machine-test | grep ^IMAGE_INSTALL=
IMAGE_INSTALL="    packagegroup-core-boot     packagegroup-base-extended               packagegroup-fsl-gstreamer1.0     packagegroup-fsl-gstreamer1.0-full     packagegroup-fsl-tools-gpu     packagegroup-fsl-tools-gpu-external     packagegroup-fsl-tools-testapps     packagegroup-fsl-tools-benchmark                           packagegroup-fsl-optee-imx"
$ bitbake -e fsl-image-machine-test | grep ^IMAGE_FEATURES
IMAGE_FEATURES="debug-tweaks package-management tools-profile tools-testapps"
IMAGE_FEATURES_REPLACES_ssh-server-openssh="ssh-server-dropbear"
```

IMAGE_INSTALL 设置了安装到目标镜像的包和包组，包组就是一些相关的包的集合，它们都是通过 .bb 文件定义的。如果要向目标镜像添加包，可以用 _append 语法（参考 [Bitbake user manual](https://www.yoctoproject.org/docs/3.1.2/bitbake-user-manual/bitbake-user-manual.html#appending-and-prepending-override-style-syntax)）向 IMAGE_INSTALL 变量中追加内容，例如：

```bash
IMAGE_INSTALL_append = " vim"
```

也可以用 _remove 语法从 IMAGE_INSTALL 变量中删除已有的内容，例如：

```bash
IMAGE_INSTALL_remove = "packagegroup-fsl-tools-testapps"
```

IMAGE_FEATURES 设置了目标镜像的特性，不止是包和包组，这些特性来自于 IMAGE_FEATURES 的定义，假设 :

```
FEATURE_PACKAGES_widget = "package1 package2"
```

那么，如果 IMAGE_FEATURES 中包含了 widget ，就包含了 package1  和 package2 。例如：


```bash
$ bitbake -e fsl-image-machine-test | grep ^FEATURE_PACKAGES
FEATURE_PACKAGES_eclipse-debug="packagegroup-core-eclipse-debug"
FEATURE_PACKAGES_hwcodecs=""
FEATURE_PACKAGES_nfs-client="packagegroup-core-nfs-client"
FEATURE_PACKAGES_nfs-server="packagegroup-core-nfs-server"
FEATURE_PACKAGES_package-management="dpkg apt"
FEATURE_PACKAGES_splash="psplash"
FEATURE_PACKAGES_ssh-server-dropbear="packagegroup-core-ssh-dropbear"
FEATURE_PACKAGES_ssh-server-openssh="packagegroup-core-ssh-openssh"
FEATURE_PACKAGES_tools-debug="packagegroup-core-tools-debug"
FEATURE_PACKAGES_tools-profile="packagegroup-core-tools-profile"
FEATURE_PACKAGES_tools-sdk="packagegroup-core-sdk packagegroup-core-standalone-sdk-target"
FEATURE_PACKAGES_tools-testapps="packagegroup-core-tools-testapps"
FEATURE_PACKAGES_x11="packagegroup-core-x11"
FEATURE_PACKAGES_x11-base="packagegroup-core-x11-base"
FEATURE_PACKAGES_x11-sato="packagegroup-core-x11-sato"
```

IMAGE_FEATURES 中定义的 tools-testapps 就表示 packagegroup-core-tools-testapps ，可以在源码目录中直接搜索这个包组的 .bb 文件：

```bash
$ find ./ -name "packagegroup-core-tools-testapps*"
./poky/meta/recipes-core/packagegroups/packagegroup-core-tools-testapps.bb
./meta-imx/meta-sdk/recipes-fsl/packagegroup/packagegroup-core-tools-testapps.bbappend
```

我们也可以用 _append 和 _remove 语法修改 IMAGE_FEATURES 变量的内容，Yocto 提供的可选项可以参考 [Feature Image](https://www.yoctoproject.org/docs/3.0.4/ref-manual/ref-manual.html#ref-features-image) 。

如果我们想删除的包没有显示在 IMAGE_INSTALL 和 IMAGE_IMAGE_FEATURES 的定义里，通常是被封装到了包组里面，这时，可以用 PACKAGE_EXCLUDE 变量设置：

```
PACKAGE_EXCLUDE = "package_name package_name package_name ..."
```

这些列出的包都不会被安装到目标镜像中。这里可能会出现一个问题，如果其他一些包依赖于这里列出的包（即在 RDEPENDS 变量中列出），构建时会报错，必须接触相应的依赖关系。以删除 connman 为例：

```bash
PACKAGE_EXCLUDE = "connman"
```

构建时会出现如下错误：

```bash
$ bitbake fsl-image-machine-test
...
Some packages could not be installed. This may mean that you have requested an impossible situation or if you are using the unstable distribution that some required packages have not yet been created or been moved out of Incoming.
The following information may help to resolve the situation:

The following packages have unmet dependencies:
 packagegroup-core-tools-testapps : Depends: connman-client but it is not going to be installed
                                    Depends: connman-tools but it is not going to be installed
E: Unable to correct problems, you have held broken packages.
...
```

packagegroup-core-tools-testapps 包组里的 connman-client 和 connman-tools 都依赖于 connman ，在 packagegroup-core-tools-testapps.bb 文件中可以看到： 

```bash
RDEPENDS_${PN} = "\
    blktool \
    ${KEXECTOOLS} \
    alsa-utils-amixer \
    alsa-utils-aplay \
    ltp \
    connman-tools \
    connman-tests \
    connman-client \
    ${@bb.utils.contains('DISTRO_FEATURES', 'x11', "${X11TOOLS}", "", d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'x11 opengl', "${X11GLTOOLS}", "", d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', '3g', "${3GTOOLS}", "", d)} \
    "
```

可以新建一个 packagegroup-core-tools-testapps.bbappend 文件，使用 _remove 语法将其删除：

```bash
RDEPENDS_${PN}_remove = "connman-tools connman-tests connman-client"
```

修改完毕后，可以使用 bitbake 的 -g 选项生成目标的依赖关系：

```bash
bitbake -g fsl-image-machine-test
```

它会在当前目录下生成两个文件，pn-buildlist 列出了生成目标所依赖的所有包，我们可以在这里快速的检查删减和增加的操作是否成功，task-depends.dot 记录了所有任务的依赖关系，可以用 Graphviz 打开，进行图形化的阅览。

### 5.5.2. 自定义 recipe 

我们也可以新建一个系统镜像的 recipe ，添加自己需要的特性。例如，在 meta-freescale-distro/recipes-fsl/images 目录下新建一个 fsl-image-custom.bb 文件，然后添加如下内容：

```bash
LICENSE = "MIT" # 声明许可证
inherit core-image # 继承 core-image 类
IMAGE_INSTALL_append = " package-name" # 添加的包
```

### 5.5.3. 自定义包组

包组（packagegroup）就是按特定需求把几个包组合成一个变量，以 packagegroup- 为前缀，在类似 meta*/recipes*/packagegroups/packagegroup*.bb的文件中定义。以 poky/meta/recipes-core/packagegroups/packagegroup-base.bb 文件为例，文件内通过 PACKAGES 变量列出了要产生的包组，然后再用 RDEPENDS 和 RRECOMMENDS 项设置每个包组所包含的软件包。

下面是一个简单的例子，我们自定义一个名为 packagegroup-custom.bb 的 recipe 文件：

``` bash
DESCRIPTION = "My Custom Package Groups"

inherit packagegroup

PACKAGES = "\
    ${PN}-apps \
    ${PN}-tools \
    "

RDEPENDS_${PN}-apps = "\
    dropbear \
    portmap \
    psplash"

RDEPENDS_${PN}-tools = "\
    oprofile \
    oprofileui-server \
    lttng-tools"

RRECOMMENDS_${PN}-tools = "\
    kernel-module-oprofile"
```

`${PN}` 是替代文件名（packagegroup-custom）的变量，所以，这里是定义了两个包组：packagegroup-custom-apps 和 packagegroup-custom-tools ，然后用 `RDEPENDS_${PN}-*` 设置了每个包组依赖的软件包。如果只想定义一般包组，可以不用 PACKAGES 变量，​`${PN}` 即是包组的名称，用 `RDEPENDS_${PN}` 设置包组依赖的软件包。

### 5.5.4. 自定义 hostname 

Linux 系统在 /etc/hostname 文件中定义了 hostname ，默认情况下，Yocto 是在 base-files_*.bb 文件中定义 hostname  的：

```bash
# By default the hostname is the machine name. If the hostname is unset then a
# /etc/hostname file isn't written, suitable for environments with dynamic
# hostnames.
#
# The hostname can be changed outside of this recipe by using
# hostname_pn-base-files = "my-host-name".
hostname = "${MACHINE}"
```



默认值是 ${MACHINE} 定义在 conf/local.conf 文件中。有两种方法重写定义 hostname 的值。你可以新增一个 base-files_*.bbappend 文件，在其中添加：

```bash
hostname="myhostname"
```

或者在 conf/local.conf 中添加：

```bash
hostname_pn-base-files = "myhostname"
```

### 5.5.5. 自定义 /etc/issue 和 /etc/issue.net

Linux 系统在用户登录时会显示欢迎信息，通常是一些关于系统版本的说明，这些信息定义在 /etc/issue 和 /etc/issue.net 两个文件中。在 Yocto 中，这两个文件的内容也是在  base-files_*.bb 文件中定义的：

```bash
​```
BASEFILESISSUEINSTALL ?= "do_install_basefilesissue"

......

DISTRO_VERSION[vardepsexclude] += "DATE"
do_install_basefilesissue () {
        install -m 644 ${WORKDIR}/issue*  ${D}${sysconfdir}
        if [ -n "${DISTRO_NAME}" ]; then
                printf "${DISTRO_NAME} " >> ${D}${sysconfdir}/issue
                printf "${DISTRO_NAME} " >> ${D}${sysconfdir}/issue.net
                if [ -n "${DISTRO_VERSION}" ]; then
                        distro_version_nodate="${@d.getVar('DISTRO_VERSION').replace('snapshot-${DATE}','snapshot').replace('${DATE}','')}"
                        printf "%s " $distro_version_nodate >> ${D}${sysconfdir}/issue
                        printf "%s " $distro_version_nodate >> ${D}${sysconfdir}/issue.net
                fi
                printf "\\\n \\\l\n" >> ${D}${sysconfdir}/issue
                echo >> ${D}${sysconfdir}/issue
                echo "%h"    >> ${D}${sysconfdir}/issue.net
                echo >> ${D}${sysconfdir}/issue.net
        fi
}
do_install_basefilesissue[vardepsexclude] += "DATE"
```

欢迎信息是通过 `do_install_basefilesissue()` 函数添加到文件的，主要是记录了发行版的名称 ${DISTRO_NAME} 和版本号 ${DISTRO_VERSION} ，这两个变量的值可以直接查询：

```
$ bitbake -e base-files | grep -E "^DISTRO_NAME=|^DISTRO_VERSION="
DISTRO_NAME="NXP i.MX Release Distro"
DISTRO_VERSION="5.4-zeus"
```

我们可以新增一个 base-files_*.bbappend 文件，禁用 `do_install_basefilesissue()` 函数，然后添加自己的函数，例如：

```bash
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
SRC_URI_prepend = " file://issue \
                    file://issue.net "
BASEFILESISSUEINSTALL = "do_install_basefilesissuecustom"

do_install_basefilesissuecustom () {
    install -m 644 ${WORKDIR}/issue*  ${D}${sysconfdir}
}
```



### 5.5.6. 修改 rootfs 分区的大小

我们的系统镜像文件使用 .wic 格式定义 SD/MMC 存储介质上的分区， .wic 是用 OpenEmbedded Kickstart(.wks) 生成的，支持 RAW 和 FileSystem两种分区方式，关于 .wks 的详细信息可以查看 [kickstart-docs](#ref-kickstart) 。

可以执行 `bitbake -e core-image-base` 导出当前镜像的所有元数据，在 _WKS_TEMPLATE 字段可以看到启动镜像在存储介质上的布局：

```bash
# $_WKS_TEMPLATE
#   set image_types_wic.bbclass:112 [__anon_115__home_sbs_imx_yocto_bsp_5_4_47_sources_poky_meta_classes_image_types_wic_bbclass]
#     "# short-description: Create SD card image with a boot partition
#     # long-description:
#     # Create an image that can be written onto a SD card using dd for use
#     # with i.MX SoC family
#     # It uses u-boot
#     #
#     # The disk layout used is:
#     #  - --------- -------------- --------------
#     # | | u-boot  |     boot     |    rootfs   |
#     #  - --------- -------------- --------------
#     # ^ ^         ^              ^
#     # | |         |              |
#     # 0 1kiB    4MiB          16MiB + rootfs + IMAGE_EXTRA_SPACE (default 10MiB)
#     #
#     part u-boot --source rawcopy --sourceparams="file=${UBOOT_BINARY}" --ondisk mmcblk --no-table --align 1
#     part /boot --source bootimg-partition --ondisk mmcblk --fstype=vfat --label boot --active --align 4096 --size 16
#     part / --source rootfs --ondisk mmcblk --fstype=ext4 --label root --align 4096
#
#     bootloader --ptable msdos
#     "
_WKS_TEMPLATE="# short-description: Create SD card image with a boot partition \
```

可见，U-boot 占了前面的 4MB ，boot 是一个 FAT 格式的分区，存放了设备树和内核文件，rootfs 是 ext4 分区，在宿主机的编译环境下也会保留一份根文件系统的拷贝，位于 IMAGE_ROOTFS 变量指定的路径：

```bash
# $IMAGE_ROOTFS [2 operations]
#   set /home/sbs/imx-yocto-bsp-5.4.47/sources/poky/meta/conf/bitbake.conf:451
#     "${WORKDIR}/rootfs"
#   set /home/sbs/imx-yocto-bsp-5.4.47/sources/poky/meta/conf/documentation.conf:219
#     [doc] "The location of the root filesystem while it is under construction (i.e. during do_rootfs)."
# pre-expansion value:
#   "${WORKDIR}/rootfs"
IMAGE_ROOTFS="/home/sbs/imx-yocto-bsp-5.4.47/imx6ullevk-fb/tmp/work/imx6ull14x14evk-poky-linux-gnueabi/core-image-base/1.0-r0/rootfs"
```

rootfs 之后的存储空间都可能成为未使用的空间而被浪费，我们可以修改 rootfs 分区的大小，使其占满整个 SD/MMC 的存储空间。

rootfs 分区的大小是由一套算法决定的,可以表示如下：

``` bash
if (image-du * overhead) < rootfs-size:
    internal-rootfs-size = rootfs-size + xspace
else:
    internal-rootfs-size = (image-du * overhead) + xspace

where:
    image-du = Returned value of the du command on the image.
    overhead = IMAGE_OVERHEAD_FACTOR
rootfs-size = IMAGE_ROOTFS_SIZE
xspace = IMAGE_ROOTFS_EXTRA_SPACE
    internal-rootfs-size = Initial root filesystem size before any modifications.
```

该算法涉及三个变量：

1. 初始磁盘空间 IMAGE_ROOTFS_SIZE
2. 开销系数 IMAGE_OVERHEAD_FACTOR
3. 额外可用空间 IMAGE_ROOTFS_EXTRA_SPACE 

构建系统首先运行 du 命令来确定 rootfs 目录树的磁盘使用量（image-du）。如果 IMAGE_ROOTFS_SIZE 当前值大于磁盘使用量（image-du）乘以开销系数（IMAGE_OVERHEAD_FACTOR），则只增加额外的空间（IMAGE_ROOTFS_EXTRA_SPACE）。如果 IMAGE_ROOTFS_SIZE 小于磁盘使用量乘以开销系数，则在添加额外空间之前，先将磁盘使用量乘以开销系数。

IMAGE_ROOTFS_SIZE 变量必须设置一个默认值，单位是 KBytes ，这个默认值通常很低，因为它只是初始化，并在每次生成镜像时根据实际大小需求进行更新。以 core-image-base 镜像为例，默认值是 65536 KBytes ：

```bash
# $IMAGE_ROOTFS_SIZE [2 operations]
#   set /home/sbs/imx-yocto-bsp-5.4.47/sources/poky/meta/conf/documentation.conf:221
#     [doc] "Defines the size in Kbytes for the generated image."
#   set /home/sbs/imx-yocto-bsp-5.4.47/sources/poky/meta/conf/bitbake.conf:783
#     [_defaultval] "65536"
# pre-expansion value:
#   "65536"
IMAGE_ROOTFS_SIZE="65536"
```

开销系数的默认值是 1.3 ，也就是在 rootfs 中预留 30% 的空间给用户安装软件，额外空间默认为 0 ：

```bash
# $IMAGE_OVERHEAD_FACTOR [2 operations]
#   set? /home/sbs/imx-yocto-bsp-5.4.47/sources/poky/meta/conf/bitbake.conf:460
#     "1.3"
#   set /home/sbs/imx-yocto-bsp-5.4.47/sources/poky/meta/conf/documentation.conf:216
#     [doc] "Defines a multiplier that the build system applies to the initial image size for cases when the multiplier times the returned disk usage value for the image is greater than the sum of IMAGE_ROOTFS_SIZE and IMAGE_ROOTFS_EXTRA_SPACE."
# pre-expansion value:
#   "1.3"
IMAGE_OVERHEAD_FACTOR="1.3"
#
# $IMAGE_ROOTFS_EXTRA_SPACE [2 operations]
#   set? /home/sbs/imx-yocto-bsp-5.4.47/sources/poky/meta/conf/bitbake.conf:465
#     "0"
#   set /home/sbs/imx-yocto-bsp-5.4.47/sources/poky/meta/conf/documentation.conf:220
#     [doc] "Defines additional free disk space created in the image in Kbytes. By default, this variable is set to '0'."
# pre-expansion value:
#   "0"
IMAGE_ROOTFS_EXTRA_SPACE="0"
```

所以，扩大 rootfs 分区大小有多种方法。

1. 修改开销系数，比如在 conf/local.conf 中添加：IMAGE_OVERHEAD_FACTOR = "1.5" ，使 rootfs 分区有 50% 的空闲存储空间。
2. 增加额外空间，比如在 conf/local.conf 文件中添加：IMAGE_ROOTFS_EXTRA_SPACE = "1048576" ，使 rootfs 直接多出 1GB 的空间。需要注意的是，这可能是 IMAGE_OVERHEAD_FACTOR 系数之后的额外空间。
3. 直接设置 IMAGE_ROOTFS_SIZE ，使它足够大，可以占满存储介质的空间。

## 5.6. 添加新的 recipe 

recipe（.bb文件）是 Yocto 项目环境中的基本组件。由 OpenEmbedded 构建系统构建的每个软件包都需要一个 recipe 来定义。我们可以从头开始手写 recipe ，或者参考别的 recipe 进行修改，例如在 http://layers.openembedded.org/layerindex/branch/master/layers/ 中有很多社区维护的recipe ，可以查找符合需求的拿来用。此外，OpenEmbedded 和 Yocto 分别提供了了 devtool 和 recipetool 两种工具来新建 recipe 。Recipe 文件的语法也可以参考 https://www.yoctoproject.org/docs/1.8/bitbake-user-manual/bitbake-user-manual.html 。下面是手写一个 recipe 的基本流程：

![img](./pics/wpsXEGnru.jpg) 

### 5.6.1. 新建文件

以移植 [UCI](https://git.openwrt.org/?p=project/uci.git;a=summary) 为例，因为 bitbake 是通过 conf/layer.conf 文件中定义的 BBFILES 变量来搜索 recipe 的，这个变量定义了搜索路径：

``` bash
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
        ${LAYERDIR}/recipes-*/*/*.bbappend"
```

所以我们依次建立如下路径和文件：

``` bash
meta-mylayer/recipes-example/uci
meta-mylayer/recipes-example/uci/uci_git.bb
```

recipe 文件的命名规范是 `<packagename>_<version>-<revision>.bb` :
* packagename 就是包的名字，名字中间不应该有下划线，可以用短横线，bitbake 会将其赋值给变量 PN
* version 是软件包的版本号，bitbake 会将其赋值给变量 PV
* revision 是修订版本号，bitbake 会将其赋值给变量 PR 

例如 linux-imx_5.4.bb 。传统的开源软件都是以源码压缩包的形式，压缩包的文件名里就带有版本号，这样的命名就可以方便把版本号传递到 recipe 文件内部。对于 git 或者 svn 等形式发布的软件，可以直接用 git 或 svn 替代版本号的位置，例如 uci_git.bb 。向文件填入一些基本信息：

``` bash
SUMMARY = "UCI"
DESCRIPTION = "OpenWrt Unified Configuration Interface"
LICENSE = "GPLv2"
```

* SUMMARY 是对这个 recipe 的概述，不能超过 72 个字符。
* DESCRIPTION 是对这个 recipe 的详细描述
* LICENSE 是这个软件包的开源许可证

此时，recipe 文件已经可以被正确解析，查看一些基本的变量：

``` bash
$ bitbake -e uci | grep -E "^PN=|^PV=|^PR="
PN="uci"
PR="r0"
PV="git"
```

下面开始编辑这个文件。

### 5.6.2. 获取源码

获取源码的过程是由 do_fetch 任务来完成，主要是通过 SRC_URI 变量控制，它可以指定源码的位置，获取源码的协议，源码的版本等。源码通常来源于三种途径：

1. 上游发布的源码压缩包，通常是 ftp 、http 等协议的下载地址。
2. 通过版本控制服务器发布的源码，通常是 git 、svn 等协议下载地址。
3. 本地源码树，源码文件就放在 recipe 文件的同层路径下，通常是用户自己开发的软件。

必须在 recipe 中定义 SRC_URI ，尽量不要使用硬编码，而要多用系统体用的变量，比如 poky/meta/recipes-connectivity/iw/iw_5.3.bb 中的定义：

```
SRC_URI = "http://www.kernel.org/pub/software/network/iw/${BP}.tar.gz \
```

BP 的含义就是 ${BPN}-${PV} ，BPN 是 PN 的另一个版本，它会去掉 PN 的一些特殊前后缀（比如lib32- 、-native等）。

如果是通过 git 克隆的源码，还需要手动设置 SRCREV 和 PV 。SRCREV 是 git 仓库的 commit hash 值，bitbake 根据这个值调用 git 命令检出我们需要的版本。PV 的默认值就是 git ，最好手动设置一个具有版本意义的值，比如 /meta-openembedded/meta-oe/recipes-devtools/libubox/libubox_git.bb 中的定义：

```
PV = "1.0.1+git${SRCPV}"
```

1.0.1+git 是自定义的字段，SRCPV 的值是 bitbake 自动生成的，主要使用了 SRCREV 的前十个字符。对于 git 协议，还可以设置其他参数来精确匹配想要的版本，例如：

* branch，要克隆的分支，如果未设置，默认为 "master"。
* tag，指定用于检出的标签，有些软件是用 tag 来标记版本的。

参数之间用分号隔开，例如：

```
SRC_URI = "git://git.oe.handhelds.org/git/vip.git;tag=version-1"
```

对于远程下载的源码压缩包，bitbake 会尝试计算文件的校验和，然后与 recpie 中设置的 SRC_URI[md5sum] 和 SRC_URI[sha256sum] 进行对比，确保没有篡改或损坏，如果检验和不一致，会报错。还是以 poky/meta/recipes-connectivity/iw/iw_5.3.bb 中的定义为例：

``` bash
SRC_URI = "http://www.kernel.org/pub/software/network/iw/${BP}.tar.gz \
    file://0001-iw-version.sh-don-t-use-git-describe-for-versioning.patch \
    file://separate-objdir.patch \
    "

SRC_URI[md5sum] = "6d4d1c0ee34f3a7bda0e6aafcd7aaf31"
SRC_URI[sha256sum] = "175abbfce86348c0b70e778c13a94c0bfc9abc7a506d2bd608261583aeedf64a"
```

如果使用了本地的源码，源码文件要放在 recipe 文件旁边名为 ${BP}、${BPN} 或者 files 的文件夹中，然后用 file:// 协议指定相对路径，bitbake 会依次从 ${BP}、${BPN} 和 files 文件夹中按相对路径进行搜索。

源码获取成功后，do_unpack 任务会把源码释放到 ${S} 变量指向的路径。S 的默认值是 ${[WORKDIR](#var-WORKDIR)}/${[BPN](#var-BPN)}-${[PV](#var-PV)} ，如果下载的是源码压缩包，并且压缩包的内部结构符合顶层子目录 ${BPN}-${PV} 的约定，那就不需要设置 S 。然而，压缩包不符合这个约定，或者是从 git 等版本管理服务器克隆的源码，就要手动设置 S ，比如 git 会将源码克隆到 ${WORKDIR}/git 路径下，就要在 recipe 中设置这个值。下面是获取和释放源码的示意图：

![img](./pics/wps7jXRFz.jpg) 

我们需要在 uci_git.bb 中添加：

``` bash
SRC_URI = "git://git.openwrt.org/project/uci.git"
SRCREV = "52bbc99f69ea6f67b6fe264f424dac91bde5016c"
PV = "1.0.0+git${SRCPV}"
S = "${WORKDIR}/git"
```

然后执行 unpack 任务，验证 recipe 是否正确：

```
bitbake uci -c unpack
```

源码会释放到 tmp/work/cortexa7t2hf-neon-poky-linux-gnueabi/uci/1.0.0+gitAUTOINC+52bbc99f69-r0/git 路径下。

### 5.6.3. 打补丁

有时需要在获取源码后对其打补丁。SRC_URI 中提到的任何文件，如果其名称以 .patc 或 .diff结尾，或者是这些后缀的压缩版本(例如：diff.gz)，都会被视为补丁。do_patch 任务会自动应用这些补丁。

构建系统应该能够使用"-p1 "选项来应用补丁 (即路径中的一个目录级别将被移除)。如果你的补丁需要剥离更多的目录级别，请使用补丁的 SRC_URI 条目中的 "striplevel" 选项指定级别数。另外，如果您的补丁需要应用在补丁文件中没有指定的特定子目录中，请使用条目中的 "patchdir "选项。

如同在 SRC_URI 中使用 file:// 引用的本地文件一样，应该把补丁文件放在 recipe 文件旁边名为 ${BP}、${BPN} 或者 files 的文件夹中。

### 5.6.4. 设置 License

应该在 recipe 中用  [LICENSE](#var-LICENSE) 和 [LIC_FILES_CHKSUM](#var-LIC_FILES_CHKSUM) 设置版权许可证和许可证文件的校验和。

软件通常会在源码包的某个文件中声明自己的许可证类型，比如 COPYING, LICENSE 和 README 等，查到许可证类型就可以设置 LICENSE ，对于标准许可证，使用 poky/meta/files/common-licenses/ 中的文件名，或者 meta/conf/licenses.conf 中定义的 SPDXLICENSEMAP 标志名即可，也可以使用自定义的许可证名称。然后用许可证文件的 md5 校验值设置 [LIC_FILES_CHKSUM](#var-LIC_FILES_CHKSUM) 。如果源码包里没有许可证文件，也可以用任意文件替代。或者用系统内的 License ，例如:

```bash
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
```

我们需要在 uci_git.bb 中添加：

``` bash
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://CMakeLists.txt;md5=5c39cc16168ed9d0e1603468508a6e2b"
```

### 5.6.5. 确定依赖关系

大多数软件包都有一个它们所需要的其他软件包的简短列表，这就是所谓的依赖关系。这些依赖关系可分为两大类：构建时依赖关系，这是软件构建时需要的；运行时依赖关系，这是软件运行时需要安装在目标机上的。

在 recipe 文件中，可以使用 DEPENDS 变量设置构建时的依赖关系，DEPENDS中指定的项目应该是其他 recipe 的名称。以 meta-openembedded/meta-oe/recipes-devtools/libubox/libubox_git.bb 为例：

```
DEPENDS = "json-c"
```

另一个考虑因素是，configure 脚本可能会自动检查可选的依赖关系，并在发现这些依赖关系时启用相应的功能。这意味着，为了保证确定性，应该把这些依赖关系也显式地指定出来，或者明确地告诉 configure 脚本禁用这些功能。

与构建时的依赖关系类似，可以 RDEPENDS 变量设置运行时的依赖关系，这些依赖关系是为了让包正确运行而必须安装的其他包。因为 RDEPENDS 变量适用于正在构建的包，所以你应该总是以带有包名的形式来使用这个变量（记住，一个 recipe 可以构建多个包）。例如，假设你正在构建一个依赖于perl包的开发包。在这种情况下，你会使用下面的RDEPENDS语句。

```
RDEPENDS_${PN}-dev += "perl"
```

uci 的编译和运行都依赖 libubox ，我们需要在 uci_git.bb 中添加：

```
DEPENDS = "libubox"
```

### 5.6.6. 配置

大部分软件在编译之前都需要进行配置，通常有如下三种情况：

* Autotools：如果源文件中有configure.ac文件，那么软件是使用 Autotools 构建的，recipe 文件里需要继承 autotools 类（inherit [autotools](#ref-classes-autotools)），而且不必包含 do_configure 任务。但是，可能还是要做一些调整，可以设置 EXTRA_OECONF 或 PACKAGECONFIG_CONFARGS 来传递所需的配置选项。
* CMake: 如果源文件中有一个 CMakeLists.txt 文件，那么你的软件是用 CMake 构建的，recipe文件需要继承 cmake 类（inherit cmake），而且不必包含do_configure任务。你可以通过设置 EXTRA_OECMAKE 来进行一些调整。
* 其他：其他情况就需要在你的 recipe 中提供一个do_configure任务。

uci 编译时默认需要 lua5.1 ，但是我们的系统没有安装 lua5.1 ，源码包中的 CMakeLists.txt 提供了 BUILD_LUA 选项，默认是 ON ，我们把这个特性关闭，执行 cmake 时就不会寻找 lua5.1 了：

``` bash
inherit cmake
EXTRA_OECMAKE = "-DBUILD_LUA=OFF"
```

一旦配置成功，最好检查一下 log.do_configure 文件，以确保适当的选项已经启用。

### 5.6.7. 编译

配置成功后，系统会自动调用 do_compile 任务进行编译，如果没有报错，就不用做任何事情。如果编译步骤失败，需要分析失败原因，可能的原因有：

* 并行构建失败。这些故障表现为间歇性错误，或报告说找不到应由构建过程其他部分创建的文件或目录。详细信息和解决方法可以参考 https://docs.yoctoproject.org/3.0.4/dev-manual/dev-manual.html#debugging-parallel-make-races
* 主机路径错误。当为目标机交叉编译时，使用了来自主机系统的不正确的头文件、库或其他文件时，就会发生该故障。要解决这个问题，请检查log.do_compile文件，以确定正在使用的路径，然后添加配置选项、应用补丁等。
* 错误的头文件和库文件。如果因为没有在 DEPENDS 中声明而缺少构建时的依赖关系，或者因为依赖关系存在，但构建过程用来查找文件的路径不正确，配置步骤没有检测到它，编译过程可能会失败。对于这两种失败的情况，编译过程都会报告无法找到文件。在这些情况下，需要回过头来向配置过程添加额外的选项。

### 5.6.8. 安装

安装过程中，系统调用 do_install 任务生成的文件和目录结构复制到目标设备上的镜像位置。会将 ${S}、${B} 和 ${WORKDIR} 目录中的文件复制到 ${D} 目录中，以创建目标系统中的结构。对于使用 autotools 和 cmake 构建的软件包，系统会调用它们的 instal 指令执行安装任务，如果能够满足要求，就不用修改。其他情况则需要修改或者手写 do_install 任务。我们可以在 recipe 文件中定义一个 do_install 函数，然后添加安装指令。

如果你的源码包有 Makefile 文件，并支持 make install 操作，需要在 do_install 中调用  oe_runmake install 指令执行安装操作，例如：

``` bash
do_install () {
  oe_runmake install DESTDIR=${D} SBINDIR=${sbindir} MANDIR=${mandir} INCLUDEDIR=${includedir}
}
```

如果要手动安装，必须先在 do_install 函数中使用 install -d 来创建 ${D} 下的目录。一旦这些目录存在，就可以使用 install 来手动安装文件到这些目录中。以 meta-openembedded/meta-networking/recipes-connectivity/mosquitto/mosquitto_1.6.7.bb 为例：

``` bash
do_install() {
    oe_runmake 'DESTDIR=${D}' install

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${S}/service/systemd/mosquitto.service.notify ${D}${systemd_unitdir}/system/mosquitto.service

    install -d ${D}${sysconfdir}/mosquitto
    install -m 0644 ${D}${sysconfdir}/mosquitto/mosquitto.conf.example \
                    ${D}${sysconfdir}/mosquitto/mosquitto.conf

    install -d ${D}${sysconfdir}/init.d/
    install -m 0755 ${WORKDIR}/mosquitto.init ${D}${sysconfdir}/init.d/mosquitto
    sed -i -e 's,@SBINDIR@,${sbindir},g' \
        -e 's,@BASE_SBINDIR@,${base_sbindir},g' \
        -e 's,@LOCALSTATEDIR@,${localstatedir},g' \
        -e 's,@SYSCONFDIR@,${sysconfdir},g' \
        ${D}${sysconfdir}/init.d/mosquitto
}
```

### 5.6.9. 使能系统服务 

如果希望软件安装后随系统开机启动，通常需要使能 SysVinit 或 Systemd  。

对于 SysVinit服务，recipe 需要继承 update-rc.d 类，并设置INITSCRIPT_PACKAGES、INITSCRIPT_NAME和INITSCRIPT_PARAMS变量。详情参考 https://www.yoctoproject.org/docs/3.0.4/ref-manual/ref-manual.html#ref-classes-update-rc.d 。

对于 Systemd 服务，首先要确保  DISTRO_FEATURES 中已经加入了 "systemd"，然后 recipe 需要继承 systemd 类。详情参考 https://www.yoctoproject.org/docs/3.0.4/ref-manual/ref-manual.html#ref-classes-systemd 。

### 5.6.10. 打包

如果使用了 cmake ，这一步也是自动的，否则需要写一个 do_package 函数。

### 5.6.11 实例

下面是一个简单实例，目录结构如下：

```bash
test-app
|---files
    |---helloworld.c
    |---CMakeLists.txt
|---test-app_0.1.bb
```

源码编译使用了 cmake ，CMakeLists.txt 的内容：

```bash
cmake_minimum_required(VERSION 3.1)
project(test-app)
add_executable(helloworld helloworld.c)

install(TARGETS helloworld DESTINATION bin)
```

所以 recipe 文件非常简单：

```bash
SUMMARY = "test app"
DESCRIPTION = "interface test application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit cmake

S = "${WORKDIR}"

SRC_URI = "file://helloworld.c \
	file://CMakeLists.txt "
```

这里源码文件只有两个，比较简单，如果源码很多，一个个的添加到 SRC_URI 非常麻烦，可以选择将源码打包成一个压缩包，例如 helloworld.tar.gz ，还是放在 files 目录下，然后直接添加：

```bash
SRC_URI = "file://helloworld.tar.gz;md5=0374ade698e0bcf8509ecda2f7b4f404"
```

这样虽然方便，但是压缩包无法用 git 进行版本控制，所以，最好是在服务器上建立 git 仓库，然后通过 git 协议添加到 SRC_URI 。

## 5.7. 使用 .bbappend 文件

将元数据追加到另一个 recipe 的 recipe 称为 BitBake append 文件。一个 BitBake append文件使用 .bbappend 后缀，而相应的配方中的 Metadata 被附加到的配方使用 .bb 文件类型后缀。

你可以在你的图层中使用 .bbappend 文件对另一个图层的配方内容进行添加或更改，而不必将另一个图层的配方复制到你的图层中。您的 .bbappend 文件位于您的图层中，而您要附加元数据的主.bb配方文件则位于另一个图层中。

能够将信息追加到现有的配方中，不仅避免了重复，而且还能自动将不同层的配方更改应用到您的层中。如果你是复制配方，你将不得不在发生变化时手动合并。

当你创建一个追加文件时，你必须使用与对应的配方文件相同的根名。例如，追加文件 someapp_3.1.2.bbappend 必须应用到 someapp_3.1.2.bb。这意味着原始配方和追加文件的名称是针对版本号的。如果重命名相应的配方以更新到较新的版本，你也必须重命名并可能更新相应的.bbappend。在构建过程中，如果 BitBake 检测到一个 .bbappend 文件，而该文件没有对应的配方与名称相匹配，则会在启动时显示一个错误。请参阅 BB_DANGLINGAPPENDS_WARNONLY 变量，了解如何处理这个错误。

以 formfactor_0.0.bb 为例，位于meta/recipes-bsp/formfactor ：

``` bash
     SUMMARY = "Device formfactor information"
     SECTION = "base"
     LICENSE = "MIT"
     LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
     PR = "r45"

     SRC_URI = "file://config file://machconfig"
     S = "${WORKDIR}"

     PACKAGE_ARCH = "${MACHINE_ARCH}"
     INHIBIT_DEFAULT_DEPS = "1"

     do_install() {
	     # Install file only if it has contents
             install -d ${D}${sysconfdir}/formfactor/
             install -m 0644 ${S}/config ${D}${sysconfdir}/formfactor/
	     if [ -s "${S}/machconfig" ]; then
	             install -m 0644 ${S}/machconfig ${D}${sysconfdir}/formfactor/
	     fi
     }
```

在 recipe 中，注意 SRC_URI 变量，它告诉 OpenEmbedded 构建系统在构建过程中在哪里找到文件。下面是 append 文件，名为 formfactor_0.0.bbappend ，来自meta-raspberrypi/recipes-bsp/formfactor :

```
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
```

默认情况下，构建系统使用 FILESPATH 变量来定位文件。这个 append 文件通过设置 FILESEXTRAPATHS 变量来扩展这些位置。在 .bbappend 文件中设置这个变量是将目录添加到构建系统用来查找文件的搜索路径中的最可靠和最推荐的方法。

本例中的语句将目录扩展为包括 `${THISDIR}/${PN}`，它的解析结果是在 append 文件所在的同一目录下的一个名为 formfactor 的目录（即 meta-raspberrypi/recipes-bsp/formfactor ）。这意味着你必须设置好支持的目录结构，它将包含你将从层中包含的任何文件或补丁。

使用立即扩展赋值运算符  :=  是很重要的，因为它引用了 thisdir 。尾部的冒号字符很重要，因为它确保列表中的项目保持冒号分隔。

注意，BitBake 会自动定义 THISDIR 变量，你不应该自己设置这个变量。使用"_prepend "作为 FILESEXTRAPATHS 的一部分，可以确保你的路径会在最终列表中的其他路径之前被搜索到。另外，并不是所有的追加文件都会添加额外的文件。很多 append 文件只是为了添加构建选项而存在（例如systemd）。对于这些情况，你的 append 文件甚至不会使用 FILESEXTRAPATHS 语句。

# 6. Yocto 内核开发

参考：[Linux Kernel Development Manual](https://docs.yoctoproject.org/3.0.4/kernel-dev/kernel-dev.html)。进行开发工作之前，都要初始化开发环境：

```
source setup-environment imx6ullevk-fb/
```

新建一个 layer ，用于开发，记得把它添加到 conf/bblayers.conf  例如：

```
bitbake-layers create-layer meta-mylayer
bitbake-layers add-layer meta-mylayer
```

然后在 meta-mylayer 下新建一个 recipes-kernel 文件夹，用于存放内核开发相关的 append 和 recipe 。

## 6.1. 修改内核源码

对内核源码的修改是通过 append 文件，使用补丁文件的形式添加修改内容。

首先需要新建 append文件 。内核的 recipe 文件是 linux-imx_5.4.bb ，所以要新建如下目录和文件：

```
meta-mylayer/recipes-kernel/linux/
meta-mylayer/recipes-kernel/linux/linux-imx/
meta-mylayer/recipes-kernel/linux/linux-imx_5.4.bbappend 
```

在 .bbappend 文件中添加

```
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:" 
```

构建时，`${THISDIR}/${PN}` 会被替换为 meta-mylayer/recipes-kernel/linux/linux-imx ，构建系统会到该路径下搜索补丁文件。

然后需要获取或者制作补丁。以修改 calibrate.c 文件添加内核打印信息为例，先进入内核源码目录 /tmp/work/imx6ull14x14evk-poky-linux-gnueabi/linux-imx/5.4-r0/git ，编辑 init/calibrate.c 文件的 calibrate_delay() 函数，添加如下 printk 函数：

``` c
void calibrate_delay(void)
{
    unsigned long lpj;
    static bool printed;
    int this_cpu = smp_processor_id();

    printk("*************************************\n");
    printk("*                                   *\n");
    printk("*        HELLO YOCTO KERNEL         *\n");
    printk("*                                   *\n");
    printk("*************************************\n");

    if (per_cpu(cpu_loops_per_jiffy, this_cpu)) {
    ...
```

使用 git 命令提交变更并生成补丁：

``` bash
$ git add init/calibrate.c
$ git commit -m "calibrate.c - Added some printk statements"
$ git format-patch -1
0001-calibrate.c-Added-some-printk-statements.patch
```

把生成的补丁文件放到 meta-mylayer/recipes-kernel/linux/linux-imx/ 路径下，并在 .bbappend 文件中添加：

```
SRC_URI_append = " file://0001-calibrate.c-Added-some-printk-statements.patch"
```


执行如下命令，先清空内核编译目录，然后重新打补丁：

```
$ bitbake linux-imx -c clean
$ bitbake linux-imx -c patch
```

然后查看打过补丁的源码，确认补丁已经生效，即可执行编译：

```
$ bitbake linux-imx
```

## 6.2. 修改内核配置

源码准备完毕后，bitbake 会继续执行配置工作，如果要修改配置，需要手动执行 menuconfig ：

``` bash
$ bitbake linux-imx -c menuconfig
```

这一步就是执行内核编译时的 make menuconfig 操作，会打开一个交互界面，在这里修改配置：

![img](./pics/wpsCl2Hug.jpg) 

这里的配置来自于编译目录下的 .config 文件，如果是第一次编译，这个文件就是内核源码的 arch/arm/conifg 目录的某个 defconfig 文件的拷贝，具体是哪个文件，通常是在 recipe 文件的 do_config 任务中有说明。

在 menuconfig 中修改完毕后，保存并推出。在编译目录 tmp/work/imx6ull14x14evk-poky-linux-gnueabi/linux-imx/5.4-r0/build/ 下面会生成更新后的 .config 文件，原有的 .config 被重命名为 .config.old 。然后调用 diffconfig 选项生成一个配置片段：

```bash
bitbake linux-imx -c diffconfig
```

这一步就是对比 .config 和 .config.old 的区别，确定修改的内容，生成一个补丁文件，称之为配置片段，生成的文件位于内核构建目录下的 fragment.cfg 。我们可以把这个文件复制到 meta-mylayer/recipes-kernel/linux/linux-imx/ 目录下，然后在 linux-imx_5.4.bbappend 文件中添加：

```bash
SRC_URI += "file://fragment.cfg"
```

最好为 fragment.cfg 更改一个有意义的文件名，因为通常会使用多个配置片段来添加不同类型的修改内容。

在编译前，可以调用 kernel_configcheck 选项检查内核配置是否正确：

```bash
bitbake linux-imx -c kernel_configcheck
```

> 在某些旧版本里，内核的 recipe 存在 bug，无法合并配置片段，可以参考如下方法解决。

Linux 内核源码的 `/scripts/kconfig/merge_config.sh` 脚本提供了合并配置片段的功能，语法：

```bash
$ ./merge_config.sh -h
Usage: ./merge_config.sh [OPTIONS] [CONFIG [...]]
  -h    display this help text
  -m    only merge the fragments, do not execute the make command
  -n    use allnoconfig instead of alldefconfig
  -r    list redundant entries when merging fragments
  -y    make builtin have precedence over modules
  -O    dir to put generated output files.  Consider setting $KCONFIG_CONFIG instead.

Used prefix: 'CONFIG_'. You can redefine it with $CONFIG_ environment variable.
```

我们可以在 linux-imx 的 `.bbappend` 文件中添加一个任务，让它在编译前利用 merge_config.sh 脚本合并配置片段：

```
do_merge_fragment() {
	if [ -f ${WORKDIR}/fragment.cfg ]; then
        ${S}/scripts/kconfig/merge_config.sh -m ${B}/.config ${WORKDIR}/fragment.cfg
        mv .config ${B}/.config
    fi
}
addtask merge_fragment before do_compile after do_configure
```

## 6.3. 编译外部驱动

对于来自内核源码树之外的驱动，可以通过新建 recipe 的方式进行编译。以 sources/poky/meta-skeleton/recipes-kernel/hello-mod/hello-mod_0.1.bb 为例：

``` bash
SUMMARY = "Example of how to build an external Linux kernel module"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=12f884d2ae1ff87c09e5b7ccc2c4ca7e"

inherit module

SRC_URI = "file://Makefile \
      file://hello.c \
      file://COPYING \
     "

S = "${WORKDIR}"

RPROVIDES_${PN} += "kernel-module-hello"
```

可以把这个文件复制到 meta-mylayer/recipes-kernel/ 下的相应文件夹里，更改一个有意义的名字，在此基础上进行修改。

# 7. Yocto 应用开发

Yocto 的应用开发有两种方式，一种是在 yocto 项目内新建 recipe ，另一种是导出 SDK ，然后使用 SDK 独立开发应用软件，第二种更方便一点。

## 7.1. 安装 SDK

执行如下命令，生成扩展 SDK 安装脚本：

``` bash
~/imx-yocto-bsp-5.4.47/imx6ullevk-fb$ bitbake imx-image-multimedia -c populate_sdk
```

生成的脚本位于 tmp/deploy/sdk 目录下，执行这个脚本即可安装：

``` bash
~/imx-yocto-bsp-5.4.47/imx6ullevk-fb$ cd tmp/deploy/sdk/
~/imx-yocto-bsp-5.4.47/imx6ullevk-fb/tmp/deploy/sdk$ ./fsl-imx-fb-glibc-x86_64-imx-image-multimedia-cortexa7t2hf-neon-imx6ull14x14evk-toolchain-5.4-zeus.sh
```

默认安装在 /opt 目录下。也可以把这个脚本复制到其他主机中执行。参考：[Using the Standard SDK](https://docs.yoctoproject.org/3.0.4/sdk-manual/sdk-manual.html#sdk-using-the-standard-sdk)

 

 