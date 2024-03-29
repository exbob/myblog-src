---
title: Logrotate 
date: 2016-01-21T08:00:00+08:00
draft: false
toc:
comments: true
---


在 Linux 系统中存在各种日志文件，例如保存启动信息和内核信息的 /var/log/dmesg ，保存系统日志的 /var/log/syslog 等。如果连续运行时间太长，这些日志会越来越大，最终占据太多系统空间。所以，我们需要定期清理系统日志。Logrotate 的主要功能就是定时将旧的日志文件归档，同时创建一个新的空的日志文件，归档的文件可以选择压缩或者发送到指定的邮箱，这个过程叫做轮替（rotate）：

![](./pics_1.jpg)

Logrotate 是基于 cron 运行的，他的脚本是 /etc/cron.daily/logrotate :

    #!/bin/sh
    
    /usr/sbin/logrotate /etc/logrotate.conf
    EXITVALUE=$?
    if [ $EXITVALUE != 0 ]; then
        /usr/bin/logger -t logrotate "ALERT exited abnormally with [$EXITVALUE]"
    fi
    exit 0
    
> cron 用于设置周期性被执行的指令，是运行在后台的守护进程。

Logrotate 的主配置文件是 /etc/logrotate.conf ：

    # see "man logrotate" for details
    # rotate log files weekly
    weekly
    
    # keep 4 weeks worth of backlogs
    rotate 4
    
    # create new (empty) log files after rotating old ones
    create
    
    # use date as a suffix of the rotated file
    dateext
    
    # uncomment this if you want your log files compressed
    #compress
    
    # RPM packages drop log rotation information into this directory
    include /etc/logrotate.d
    
    # no packages own wtmp and btmp -- we'll rotate them here
    /var/log/wtmp {
        monthly
        create 0664 root utmp
            minsize 1M
        rotate 1
    }
    
    /var/log/btmp {
        missingok
        monthly
        create 0600 root utmp
        rotate 1
    }
    
    # system-specific logs may be also be configured here.
    
其中，以 # 开头的都是注释。`include /etc/logrotate.d` 之前的是默认配置，全局有效。之后以花括号包围的是针对单个文件的配置，这里的配置项会覆盖默认配置。配置项的含义：

* weekly 表示每周对日志文件进行一次轮替，类似的可选项还有 monthly （每月一次，通常是每月的第一天），daily（每天一次） 。
* rotate 4 表示保留最近四次的归档，之前的全部清除。
* create 表示轮替后立即创建新的空的日志文件，它可以带三个参数：mode owner group ，分别表示新文件的权限、所有者和用户组，例如 create 0600 root utmp。
* dateext 表示为归档后的文件名添加日期信息，日期的格式由 dateformat 选项设置。
* compress 表示压缩归档文件，注释掉这个配置项就表示不压缩。

另外，在 /etc/logrotate.d/ 目录下的配置文件会被读入到 /etc/logrotate.d ，我们自行添加的配置文件都可以放在这里。
