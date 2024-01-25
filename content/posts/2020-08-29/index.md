---
title: "uthash 学习笔记"
date: 2020-08-29T11:23:11+08:00
draft: false
toc: true
comments: true
images:
tags:
  - untagged
---

uthash 是一个 C 语言的哈希表函数库，支持哈希表的各种操作，包括添加，删除，查找，排序等。你可以在 github 上下载到它的源码：

* 源码：<https://github.com/troydhanson/uthash>
* 文档：<https://troydhanson.github.io/uthash/userguide.html>

这个函数库在使用时只需要包含 `uthash.h` 头文件即可，没有二进制的库文件。

## 1. 数据结构

uthash 的哈希表是由多个结构体组成的双向链表实现的，一个结构体就是一个键值对，例如：

```c
#include "uthash.h"

struct my_struct {
    int id;                    /* key */
    char name[10];
    UT_hash_handle hh;         /* makes this structure hashable */
};
```

* id 就是键（key），名称和数据类型没有限制；
* name 就是值（value），也可以是任何数据类型；
* hh 是内部使用的 hash 处理句柄，UT_hash_handle 字段必须存在于你的结构中。它用于内部记录，使哈希表正常工作，它不需要初始化。可以被命名为任何标识符；

哈希句柄在 32 位系统中每个元素消耗约 32 个字节，在 64 位系统中每个元素消耗 56 个字节。其他的开销成本--桶和表--相比之下可以忽略不计。你可以使用 `HASH_OVERHEAD` 来获取哈希表的开销大小，单位是字节。

## 2. 基本操作

完整的例子可以在源码下的 `tests/exapmle.c` 文件中找到，可以执行 `make example` 进行编译。

### 2.1 声明

定义一个结构体类型的空指针，即声明了一个哈希表：

```c
struct my_struct *users = NULL; 
```

此时的哈希表示空的，我们需要先表中添加数据元素，在整个生命周期中，这个指针都指向链表的头结点。

### 2.2 添加

首先需要初始化一个数据元素，也就是定义一个 `struct my_struct` 变量，并分配空间，然后调用 `HASH_ADD` （这里我们使用方便的宏 `HASH_ADD_INT`，它为 int 类型的 key 提供了简化的用法）方法，将其添加到哈希表中：

```c
void add_user(int user_id, char *name) {
    struct my_struct *s;

    s = malloc(sizeof(struct my_struct));
    s->id = user_id;
    strcpy(s->name, name);
    HASH_ADD_INT( users, id, s );  /* id: name of key field */
}
```

`HASH_ADD_INT` 的第一个参数是哈希表的指针，第二个参数是结构体中 key 的变量名，最后一个参数是需要加入哈希表的元素。一个元素添加到哈希表后，就不能修改它的 key 的值，必须从哈希表中删除后，才能修改。

### 2.3 查询

可以调用 `HASH_FIND` （这里我们使用方便的宏 `HASH_ADD_INT`，它为 int 类型的 key 提供了简化的用法）查询某个 key 的 value ：

```c
struct my_struct *find_user(int user_id) {
    struct my_struct *s;

    HASH_FIND_INT( users, &user_id, s );  /* s: output pointer */
    return s;
}
```

第一个参数是哈希表的指针，第二个参数是 key 的值，第三参数是返回的结果，就是给定 key 的结构体指针，如果没找到，就返回 NULL 。

通常在添加之前要查询一下 key 是否已经存在，避免发生冲突。

### 2.4 删除

要从哈希表中删除一个元素，必须先获取这个元素的指针（可以用 `HASH_FIND`），然后调用 `HASH_DEL` ：

```c
void delete_user(struct my_struct *user) {
    HASH_DEL(users, user);  /* user: pointer to deletee */
    free(user);             /* optional; it's up to you! */
}
```

users 就是哈希表的指针，user 就是要删除的元素，删除后，uthash 不会自动释放 user 指向的内存，可以调用 `free()` 手动释放，可以继续其他工作，比如修改这个键值对。

当删除的是哈希表的第一个元素时，users 的值是会改变的，它会继续指向新的头结点。

如果要删除所有元素，可以调用 `HASH_ITER` 方法，这个宏可以扩展为一个简单的循环：

```c
void delete_all() {
  struct my_struct *current_user, *tmp;

  HASH_ITER(hh, users, current_user, tmp) { 
    HASH_DEL(users,current_user);  /* delete; users advances to next */
    free(current_user);            /* optional- if you want to free  */
  }
}
```

如果清空哈希表时，并不想释放所有元素的空间，可以直接调用：

```c
HASH_CLEAR(hh, users);
```

之后，users 就会变为空指针。

### 2.5 统计

获取哈希表中元素总数时，可以调用 `HASH_COUNT` ：

```c
unsigned int num_users;
num_users = HASH_COUNT(users);
printf("there are %u users\n", num_users);
```

如果哈希表是空的，会返回 0 。