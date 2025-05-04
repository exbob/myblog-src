---
title: "将豆瓣电影记录添加在 Hugo 博客"
date: 2025-05-04T21:44:37+0800
draft: false
toc: true
comments: true
images:
tags:
  - untagged
---

今天下午为博客添加了观影页面，因为我每次看过一个电影，就喜欢在豆瓣上标注打分，现在就是把这些标注过的电影显示到博客上。每行显示四个电影的海报，鼠标悬停会显示电影的名称，评分和观看时间，点击海报可以跳转到豆瓣的电影页面。效果就是这样：

![豆瓣电影记录](./pics/20250504215720.png)

实现过程首先用到了 [doumark-action](https://github.com/lizheming/doumark-action)，这是一个可以[自动同步豆瓣书影音到本地文件的 github action](https://imnerd.org/doumark.html)，我用它将自己的观影记录同步到本地,然后复制到 `assets/movie.csv` 文件。

然后编写一个hugo的模板 `layouts/_default/movies.html`，将 `assets/movie.csv` 文件中的内容读取出来，然后按照想要的样式显示出来。因为我本身对前端开发很不熟悉，所以这个过程用了 AI 编程工具 [monica code](https://monica.im/en/code) 辅助完成，作为一个 vscode 的插件，可以自动补全代码，生成注释，通过对话生成代码，极大的提高了学习和开发效率。AI时代，对软件开发工作的冲击真的很大，唯有积极拥抱了。


参考资源：

- 自动爬取豆瓣记录的 github action ：https://imnerd.org/doumark.html- 
- 自动提交变更的 github action ：https://github.com/EndBug/add-and-commit
- 利用 github action 自动更新豆瓣观影记录的例子：https://github.com/koobai/blog/tree/main
- 手动更新豆瓣观影记录的例子：https://liuhouliang.com/post/movie_record
