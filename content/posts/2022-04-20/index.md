---
title: "Linux 内核数据结构-链表"
date: 2022-04-20T18:34:49+08:00
draft: false
toc: true
comments: true
images:
tags:
  - untagged
---

Linux 内核实现了一个循环双向链表，而且是侵入式链表，核心数据结构定义在 `include/linux/types.h` 文件：

```c
struct list_head {
  struct list_head *next, *prev;
};
```

实现方法都定义在 `include/linux/list.h` 文件。

![](<./pics/绘图文件 (1)_MJv1V110Os.jpg>)

## 1. 初始化链表

内核提供了两种初始化链表节点的方法。

一种是初始化宏：

```c
#define LIST_HEAD_INIT(name) { &(name), &(name) }

#define LIST_HEAD(name) \
    struct list_head name = LIST_HEAD_INIT(name)
```

展开后就是：

```c
#define LIST_HEAD(name) \
    struct list_head name = { &(name), &(name) }

```

它的作用是新建一个 `struct list_head` 变量 name ，让两个指针指向自己，通常用户新建一个链表的 head ：

![](./pics/绘图文件_nQobzytDTU.jpg)

另一种是初始化函数 ：

```c
static inline void INIT_LIST_HEAD(struct list_head *list)
{
  WRITE_ONCE(list->next, list);
  list->prev = list;
}

```

它的作用是让节点 `struct list_head *list` 的两个指针指向自己，通常用于初始一个节点。

内核的 `struct list_head` 保持了最简的结构，其他数据结构要表示为链表时，需要将 `struct list_head` 元素嵌入到自己的数据结构中，例如：

```c
// 新建一个链表，head 就是 students_list
LIST_HEAD(students_list);
    
// 新建两个节点，并初始化
struct student *student_1 = kmalloc(sizeof(struct student), GFP_KERNEL);
struct student *student_2 = kmalloc(sizeof(struct student), GFP_KERNEL);

student_1->id = 1;
strcpy(student_1->name, "Bob");
INIT_LIST_HEAD(&student_1->list);
    
student_2->id = 2;
strcpy(student_2->name, "Alice");
INIT_LIST_HEAD(&student_2->list);

// 将两个节点依次插入队尾
list_add_tail(&student_1->list, &students_list);
list_add_tail(&student_2->list, &students_list);

```

实际构造的链表结构如下：

![](<./pics/绘图文件 (4)_ULgPNVvQd1.jpg>)

## 2. 添加节点

在 head 后面（也就是队头）添加一个 new 节点：

```c
void list_add(struct list_head *new, struct list_head *head)
```

![](<./pics/绘图文件 (2)_rKgYQjqfsc.jpg>)

在 head 前面（也就是队尾）添加一个 new 节点：

```c
void list_add_tail(struct list_head *new, struct list_head *head)
```

![](<./pics/绘图文件 (3)_F4GTz4yKYb.jpg>)

例如：

```c
list_add(&student_1->list, &students_list);
```

## 3. 删除节点

删除一个节点：

```c
void list_del(struct list_head *entry)
```

例如：

```c
list_del(&student_1->list);
```

## 4. 判断节点的位置

判断 list 节点是否是 head 链表的 firts/last 节点，如果正确会返回 1 ，错误返回 0 ：

```c
int list_is_first(const struct list_head *list, const struct list_head *head)
int list_is_last(const struct list_head *list, const struct list_head *head)

```

判断一个链表是否为空格，如果为空会返回 1 ：

```c
int list_empty(const struct list_head *head)
```

## 5. 查找节点

作为侵入式链表，需要通过 `struct list_head` 结构的节点地址获得真正的数据节点，内核提供了 container\_of 的重新封装：

```c
#define list_entry(ptr, type, member) container_of(ptr, type, member)
```

三个参数分别表示：

*   ptr ：结构体成员变量 member 的地址，就是 `struct list_head` 成员的地址，

*   type ：数据节点的结构体类型的名称

*   member ：结构体成员变量的名称

例如：

```c
list_entry(&student_1->list, struct student, list)
```

返回队头/队尾的节点：

```c
list_first_entry(head, type, member)
list_last_entry(head, type, member)

```

三个参数分别表示：

*   head ：链表头的地址，

*   type ：结构体类型的名称

*   member ：结构体中的成员变量的名称

例如：

```c
struct student *entry;
entry = list_first_entry(&students_list, struct student, list);

```

获取下一个/上一个节点：

```c
list_next_entry(pos, member)
list_prev_entry(pos, member) 

```

两个参数的含义：

*   pos ：数据节点的地址

*   member：数据节点内 `sturct list_head` 成员的名称

例如：

```c
struct student *entry;
entry = list_first_entry(&students_list, struct student, list);
entry = list_next_entry(entry, list);
```

## 6. 遍历链表

内核定义了一个宏，用于从队头开始遍历链表：

```c
#define list_for_each_entry(pos, head, member)        \
  for (pos = list_first_entry(head, typeof(*pos), member);  \
       &pos->member != (head);          \
       pos = list_next_entry(pos, member))
```

三个参数的含义：

*   pos ：一个数据节点类型的指针，用于遍历链表中的每个节点

*   head ：链表的 head&#x20;

*   member ：数据节点内 `sturct list_head` 成员的名称

例如：

```c
list_for_each_entry(entry, &students_list, list)
{
    printk("entry %d:%s\n", entry->id, entry->name);
}

```

## 7. 例程

hellomod.c ：

```c
#include <linux/init.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/string.h>

struct student {
    int id;
    char name[10];
    struct list_head list;
};

static int __init hellomod_init(void)
{
    struct student *entry;
    // 新建一个链表
    LIST_HEAD(students_list);
    
    // 新建两个节点，并初始化
    struct student *student_1 = kmalloc(sizeof(struct student), GFP_KERNEL);
    struct student *student_2 = kmalloc(sizeof(struct student), GFP_KERNEL);

    student_1->id = 1;
    strcpy(student_1->name, "Bob");
    INIT_LIST_HEAD(&student_1->list);
    
    student_2->id = 2;
    strcpy(student_2->name, "Alice");
    INIT_LIST_HEAD(&student_2->list);

    // 将两个节点依次插入队尾
    list_add_tail(&student_1->list, &students_list);
    list_add_tail(&student_2->list, &students_list);

    entry = list_first_entry(&students_list, struct student, list);
    printk("first entry is %d:%s\n", entry->id, entry->name);

    entry = list_next_entry(entry, list);
    printk("next entry of first entry is %d:%s\n", entry->id, entry->name);

    list_for_each_entry(entry, &students_list, list)
    {
        printk("entry %d:%s\n", entry->id, entry->name);
    }
    printk("hellomod init\n");
    
    return 0;
}

static void __exit hellomod_exit(void)
{
    printk("hellomod exit\n");
}

module_init(hellomod_init);
module_exit(hellomod_exit);

MODULE_LICENSE("GPL");
```

Makefile ：

```c
KERDIR=/lib/modules/$(shell uname -r)/build
PWD=$(shell pwd)

obj-m:=hellomod.o

default:
  make -C ${KERDIR} M=${PWD} modules
clean:
  make -C ${KERDIR} M=${PWD} clean
```

编译后加载驱动：

```c
$ make
$ sudo insmod hellomod.ko
$ dmesg
[35509.579609] first entry is 1:Bob
[35509.579610] next entry of first entry is 2:Alice
[35509.579611] entry 1:Bob
[35509.579611] entry 2:Alice
[35509.579611] hellomod init
```
