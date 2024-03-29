---
title: 在 ITerm2 中使用 Zmodem 协议传输文件
date: 2017-01-10T08:00:00+08:00
draft: false
toc:
comments: true
---


Zmodem 是跨平台的文件传输协议，可以很方便的在不同的操作系统之间接传输文件。lzrsz 是该协议的实现方式：<https://ohse.de/uwe/software/lrzsz.html> 。安装后，在 Mac 的 ITerm2 中用 SSH 登陆远程的 Linux 主机，然后用 rz 、sz 命令传输文件。

在 Ubuntu 中安装:

    $ sudo apt-get install lrzsz

在 Mac 中安装：

    $ brew install lrzsz
    
为方便 ITerm2 中使用，需要下载两个脚本：

    cd /usr/local/bin
    sudo wget https://raw.github.com/mmastrac/iterm2-zmodem/master/iterm2-send-zmodem.sh
    sudo wget https://raw.github.com/mmastrac/iterm2-zmodem/master/iterm2-recv-zmodem.sh
    sudo chmod 777 /usr/local/bin/iterm2-*

然后打开 ITerm2 ，点击 preferences > profiles ，选中 Default ，在右侧的 Advanced 标签页中，点击 Tirggers 框的 Edit 按钮，按如下设置添加两个条目：

Regular expression |  Action | Parameters | Instant
--- | --- |--- |--- 
rz waiting to receive.\*\*B0100 | Run Silent Coprocess | /usr/local/bin/iterm2-send-zmodem.sh | checked
\*\*B00000000000000 | Run Silent Coprocess | /usr/local/bin/iterm2-recv-zmodem.sh | checked

![](./pics/2017-01-10_1.png)

向远程 Linux 主机发送文件：

1. 在 Ubuntu 上执行 rc
2. 在弹出的对话框中选中要发送的文件
3. 等待发送完成

接收远程 Linux 发来的文件：

1. 在 Ubuntu 上执行 `sz filename1 filename2 ...` 
2. 在弹出的对话框中选中接收文件的目录
3. 等待接收完成。

iterm2-send-zmodem.sh 内容：

    #!/bin/bash
    # Author: Matt Mastracci (matthew@mastracci.com)
    # AppleScript from http://stackoverflow.com/questions/4309087/cancel-button-on-osascript-in-a-bash-script
    # licensed under cc-wiki with attribution required
    # Remainder of script public domain
    
    osascript -e 'tell application "iTerm2" to version' > /dev/null 2>&1 && NAME=iTerm2 || NAME=iTerm
    if [[ $NAME = "iTerm" ]]; then
    	FILE=`osascript -e 'tell application "iTerm" to activate' -e 'tell application "iTerm" to set thefile to choose file with prompt "Choose a file to send"' -e "do shell script (\"echo \"&(quoted form of POSIX path of thefile as Unicode text)&\"\")"`
    else
    	FILE=`osascript -e 'tell application "iTerm2" to activate' -e 'tell application "iTerm2" to set thefile to choose file with prompt "Choose a file to send"' -e "do shell script (\"echo \"&(quoted form of POSIX path of thefile as Unicode text)&\"\")"`
    fi
    if [[ $FILE = "" ]]; then
    	echo Cancelled.
    	# Send ZModem cancel
    	echo -e \\x18\\x18\\x18\\x18\\x18
    	sleep 1
    	echo
    	echo \# Cancelled transfer
    else
    	/usr/local/bin/sz "$FILE" -e -b
    	sleep 1
    	echo
    	echo \# Received $FILE
    fi
    
iterm2-recv-zmodem.sh 内容：

    #!/bin/bash
    # Author: Matt Mastracci (matthew@mastracci.com)
    # AppleScript from http://stackoverflow.com/questions/4309087/cancel-button-on-osascript-in-a-bash-script
    # licensed under cc-wiki with attribution required
    # Remainder of script public domain
    
    osascript -e 'tell application "iTerm2" to version' > /dev/null 2>&1 && NAME=iTerm2 || NAME=iTerm
    if [[ $NAME = "iTerm" ]]; then
    	FILE=`osascript -e 'tell application "iTerm" to activate' -e 'tell application "iTerm" to set thefile to choose folder with prompt "Choose a folder to place received files in"' -e "do shell script (\"echo \"&(quoted form of POSIX path of thefile as Unicode text)&\"\")"`
    else
    	FILE=`osascript -e 'tell application "iTerm2" to activate' -e 'tell application "iTerm2" to set thefile to choose folder with prompt "Choose a folder to place received files in"' -e "do shell script (\"echo \"&(quoted form of POSIX path of thefile as Unicode text)&\"\")"`
    fi
    
    if [[ $FILE = "" ]]; then
    	echo Cancelled.
    	# Send ZModem cancel
    	echo -e \\x18\\x18\\x18\\x18\\x18
    	sleep 1
    	echo
    	echo \# Cancelled transfer
    else
    	cd "$FILE"
    	/usr/local/bin/rz -E -e -b
    	sleep 1
    	echo
    	echo
    	echo \# Sent \-\> $FILE
    fi
