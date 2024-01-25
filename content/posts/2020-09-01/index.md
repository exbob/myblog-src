---
title: "使用 Docker 学习 Redis"
date: 2020-09-01T09:53:11+08:00
draft: false
toc: true
comments: true
images:
tags:
  - untagged

---

## # 1. 安装

Docker 的安装比较简单，访问 <www.docker.com> ，按照指引安装相应系统的版本即可。安装完毕后，我们先拉取 Redis 的镜像：

```bash
$ docker pull redis
```

这个命令默认是拉取 Redis 官方的 Docker 镜像最新版，也可以在后面指定具体的版本：

```bash
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
docker101tutorial   latest              8e9d20f8bd52        38 hours ago        27.3MB
nginx               alpine              6f715d38cfe0        2 weeks ago         22.1MB
nginx               latest              4bb46517cac3        2 weeks ago         133MB
python              alpine              44fceb565b2a        2 weeks ago         42.7MB
redis               latest              1319b1eaa0b7        3 weeks ago         104MB
node                12-alpine           18f4bc975732        4 weeks ago         89.3MB
```

然后启动这个进行容器:

```bash
$ docker run -itd --name redis -p 6379:6379 redis
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
f0b825b877b8        redis               "docker-entrypoint.s…"   1 hours ago        Up Up 9 seconds         0.0.0.0:6379->6379/tcp   redis
```

最后，进入容器，使用 redis-cli 命令连接 Redis ：

```bash
$ docker exec -it redis redis-cli
127.0.0.1:6379> ping
PONG
127.0.0.1:6379> exit
```

