#!/bin/sh

postdir="./content/posts"
postname=$(date "+%Y-%m-%d")

# 在 postdir 下新建一个名为 postname 的目录
mkdir -p $postdir/$postname

# 在 postdir/postname 下新建一个名为 index.md 的文件，再新建一个 pics 目录
touch $postdir/$postname/index.md
mkdir -p $postdir/$postname/pics

# 在 index.md 中写入一些内容
cat <<EOF >  $postdir/$postname/index.md
---
title: ""
date: $(date "+%Y-%m-%dT%H:%M:%S%z")
draft: false
toc: true
comments: true
images:
tags:
  - untagged
---
EOF

