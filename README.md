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

新建文章：

```
> hugo.exe new posts/2014-01-10/index.md
```

这条命令会新建 `content/posts/2014-01-10/index.md` 文件，

写完后生成预览,访问<http://localhost:1313/>查看效果:

```
> hugo.exe server
```

提交发布：

```
> git commit -m "commit message"
> git push
```
