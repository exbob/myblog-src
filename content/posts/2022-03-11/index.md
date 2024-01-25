---
title: "配置 SSH 密钥登录"
date: 2022-03-11T14:34:49+08:00
draft: false
toc: true
comments: true
images:
tags:
  - untagged

---

## 1. 在客户端电脑生成密钥对

在客户端电脑上执行如下命令，生成一个密钥对：

```bash
ssh-keygen -t ed25519 -C "lishaocheng_20220201"
```

* -t 选项指定了加密类型，我们选择 ed25519 ，也可以选择其他类型。
* -C 选项是设置密钥对的注释，我习惯设置用户名和日期。

 设置一个便于记忆的文件名，密码可以跳过，生成的密钥对文件位于当前目录下。后缀为 .pub 的文件是公钥，另一个是私钥，把两个文件复制到 ~/.ssh/ 目录下。

如果在 Linux 下使用，需要设置密钥文件的权限，否则添加时会报错：

```bash
chmod 600 ~/.ssh/lishaocheng_20220201
```

## 2. 将公钥添加到 SSH 服务器

在客户电脑的在 ~/.ssh/ 目录下执行 `ssh-copy-id -i [public key] username@[server ip]` ，将公钥添加到服务器上，例如：

```bash
~/.ssh $ ssh-copy-id -i lishaocheng_20220201.pub sbs@192.168.42.131
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "lishaocheng_20220201.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
sbs@192.168.42.131's password:

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'sbs@192.168.42.131'"
and check to make sure that only the key(s) you wanted were added.
```

执行成功后，公钥会复制到服务器的 ~/.ssh 目录下的 authorized_keys 文件中。

## 3. 修改客户端配置文件

在客户端配置文件 `~/.ssh/config` 中添加如下内容：

```bash
Host vm_ubuntu18
    HostName 192.168.42.131
    Port 22
    User sbs
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/lishaocheng_20220201
```

* Host 设置为服务器 IP
* Hostname 设置为服务器名称
* Port 是服务器 SSH 的端口
* User 是用户名
* PreferredAuthentications 设为公钥验证
* IdentityFile 设置私钥文件的路径

保存后，在客户端执行 `ssh vm_ubuntu18` 即可登录。