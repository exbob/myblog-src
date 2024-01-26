# Source code of my blog

基于 Hugo 和 Github 搭建：

- Host: [GitHub Pages](https://pages.github.com/)
- Build Backend: [Hugo](https://gohugo.io/)
- Theme: [Congo](https://jpanther.github.io/congo/)
- CI/CD: [GitHub Actions](https://github.com/features/actions)

## 快速开始

在电脑上安装 (hugo v0.121.1](https://github.com/gohugoio/hugo/releases/tag/v0.121.1) :

```
> hugo.exe version
hugo v0.121.1-00b46fed8e47f7bb0a85d7cfc2d9f1356379b740 windows/amd64 BuildDate=2023-12-08T08:47:45Z VendorInfo=gohugoio
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


