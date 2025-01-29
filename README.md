# Source code of my blog

基于 Hugo 和 Github 搭建：

- Host: [GitHub Pages](https://pages.github.com/)
- Build Backend: [Hugo](https://gohugo.io/)
- Theme: [Congo](https://jpanther.github.io/congo/)
- CI/CD: [GitHub Actions](https://github.com/features/actions)

## 快速开始

下载安装 [hugo version 0.142.0](https://github.com/gohugoio/hugo/releases/tag/v0.142.0) 版本：

- Windows 就下载 hugo_extended_0.142.0_windows-amd64.zip
- Ubuntu 就下载 hugo_extended_0.142.0_linux-amd64.deb

```
> hugo.exe version
hugo v0.142.0-1f746a872442e66b6afd47c8c04ac42dc92cdb6f+extended windows/amd64 BuildDate=2025-01-22T12:20:52Z VendorInfo=gohugoio
```

将源码克隆到本地：

```
> git clone git@github.com:exbob/myblog-src.git
> cd myblog-src
```

修改完成后生成预览:

```
> hugo.exe server
```

访问<http://localhost:1313/>查看效果。没有问题的话，提交发布：

```
> git commit -m "commit message"
> git push
```

## 写博客

在 `content/posts/` 路径下新建一个以日期命令的文件夹，一篇文章的所有内容都放在这个文件夹下，例如：

```
> tree 2024-01-26
2024-01-26
├── pics/
│   └── picture.jpg
└── index.md
```

index.md 是 markdown 格式的文章内容:

```
---
title: "博客测试"
date: 2024-01-26T11:15:22+08:00
draft: true
toc: true
comments: true
---

## 标题

正文

图片：

![图片名称](./pics/picture.jpg)
```

用三条横线标注头部元数据，`draft = true` 表示这个文章会被隐藏，不显示到博客上，发布时可以改为 fales 。图片存放在 pics 路径下，在 index.md 中通过相对路径引用。

## 使用 github actions

在 `.github\workflows\deploy.yml` 文件中配置了工作流，在源码仓库 `exbob/myblog-src` 利用 github actions 自动生成静态页面，并推送到 `exbob/exbob.github.io` 仓库。使用的模块是:

- [peaceiris/actions-hugo](https://github.com/peaceiris/actions-hugo): 安装并设置 Hugo 构建环境
- [peaceiris/actions-gh-pages](https://github.com/peaceiris/actions-gh-pages): 生成静态页面并推送到指定仓库

需要注意的是，推送过程需要使用密钥，设置步骤如下：

1. 执行 `ssh-keygen -t rsa -b 4096 -C "actions-hugo_20240202" -f gh-pages -N ""` 生成 gh-pages 和 gh-pages.pub 两个密钥文件。
2. 在源码仓库的页面，进入 Settings->Secrets and variables->Actions 页面，点击 **New repository secret** 按钮添加一条私钥，私钥名称设为 **ACTIONS_HUGO_KEY** ，私钥内容为 gh-pages 文件的内容。
3. 在目标仓库的页面，进入 Settings->Deploy keys 页面，点击 **Add deploy key** 按钮添加一条公钥，公钥名称可以随意，这里设为 **ACTIONS_HUGO_KEY_PUBLIC** ，公钥内容为 gh-pages.pub 文件的内容。
