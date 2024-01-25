---
title: "CMake 学习笔记"
date: 2020-06-29T22:25:11+08:00
draft: false
toc: true
comments: true
images:
tags:
  - untagged

---

本教程提供了一个渐进式的指导，参考的是官方教程 [CMake Tutorial](https://cmake.org/cmake/help/latest/guide/tutorial/index.html#id1) ，然后加入学习过程的笔记。涵盖了使用 CMake 构建一个工程时经常遇到的问题 。通过一个示例项目，展示各种功能是如何一起工作的，这对理解 CMake 非常有用。

## 1. 最简单的工程

最简单工程是从源码文件直接编译生成一个可执行的问题，最简单的解决方案只需要在 CMakeLists.txt 文件中添加三行。

新建一个工程目录，在目录下新建一个源文件 `Tutorial.c` ：

```c
#include <stdio.h>

int main (int argc, char *argv[])
{
    printf("Hello World!\n");
    return 0;
}
```

新建一个 `CMakeLists.txt` ：

```cmake
cmake_minimum_required(VERSION 3.1)
project(Tutorial)
add_executable(Tutorial Tutorial.c)
```

`CMakeLists.txt` 是 cmake 生成 Makefile 所依赖的描述性文件，文件内容由一行一行的命令组成，命令不区分大小写。

* cmake_minimum_required 表示该项目对 CMake 的最低版本要求。
* project 用于设置项目名称。
* add_executable 添加了一个生成的可执行文件，和依赖的源码。

这样的话，执行 `cmake .` 生成 Makefile ，再执行 `make` 开始编译，就可以使用 `Tutorial.c` 生成的可执行文件 `Tutorial ` 。

cmake 执行过程中会生成大量的缓存文件，又没有提供类似 `cmake clean` 的命令来清除生成的文件，有一个简单的方法可以解决这个问题。在工程目录下新建一个名为 `build` 的子目录，进入这个子目录中执行 `cmake ..` ，这样生成的文件都会输出到 `build` 子目录中，方便清理。

### 添加一个版本号

一个软件工程通常需要版本号，可以直接写在源码里，但是 CMake 提供了更便捷的方法。可以在 [`project()`](https://cmake.org/cmake/help/latest/command/project.html#command:project) 命令中添加版本号，例如：

```cmake
project(Tutorial VERSION 1.0)
```

其实，还可以在该命令中添加项目的描述等，它的语法是：

```
project(<PROJECT-NAME>
        [VERSION <major>[.<minor>[.<patch>[.<tweak>]]]]
        [DESCRIPTION <project-description-string>]
        [HOMEPAGE_URL <url-string>]
        [LANGUAGES <language-name>...])
```

这样添加的版本号，被 cmake 存放在特定的变量中：

* `<PROJECT-NAME>_VERSION` ，存放完整的版本号 。
* `<PROJECT-NAME>_VERSION_MAJOR` ，存放 major 。
* `<PROJECT-NAME>_VERSION_MINOR` ，存放 minor 。
* `<PROJECT-NAME>_VERSION_PATCH` ， 存放 patch 。
*  `<PROJECT-NAME>_VERSION_TWEAK` ，存放 tweak 。

`<PROJECT-NAME>`表示工程的名称，这里的值为 Tutorial ，所以 `Tutorial_VERSION_MAJOR` 的值就是 `1` ， `Tutorial_VERSION_MINOR` 的值就是 `0` 。我们需要新建一个名为 `TutorialConfig.h.in` 的文件传递这些变量：

```c
#define Tutorial_VERSION_MAJOR @Tutorial_VERSION_MAJOR@ 
#define Tutorial_VERSION_MINOR @Tutorial_VERSION_MINOR@ 
```

然后，在 `CMakeLists.txt` 中添加一条命令：

```cmake
configure_file(TutorialConfig.h.in TutorialConfig.h)
```

cmake 执行这条命令的时候，会读取 `TutorialConfig.h.in` 文件，并将其中的变量替换成真实的值，然后在执行目录下生成头文件 `TutorialConfig.h` ：

```c
#define Tutorial_VERSION_MAJOR 1
#define Tutorial_VERSION_MINOR 0
```

下一步，我们需要在源码文件 `Tutorial.c` 中导入头文件，然后使用头文件里定义的宏打印版本号：

```c
#include <stdio.h>
#include "TutorialConfig.h" # 导入头文件

int main (int argc, char *argv[])
{
    printf("Hello World!\n");
    printf("MAJOR Version is %d\n", Tutorial_VERSION_MAJOR); # 引用版本号的宏定义
    printf("MINOR Version is %d\n", Tutorial_VERSION_MINOR);
    return 0;
}
```

如果你是在源码目录下执行 cmake ，这样修改就可以了。如果是在 `build` 目录下执行 cmake ，生成的 `TutorialConfig.h` 文件位于 `build` 目录下，源文件中的 `#include "TutorialConfig.h"` 语句会找不到头文件，这时，需要将 `build` 目录页加入到头文件的检索路径中，可以在 `CMakeLists.txt` 的末尾加一行：

```cmake
target_include_directories(Tutorial PUBLIC "${PROJECT_BINARY_DIR}")
```

`target_include_directories()` 的语法是：

```cmake
target_include_directories(<target> [SYSTEM] [BEFORE]
  <INTERFACE|PUBLIC|PRIVATE> [items1...]
  [<INTERFACE|PUBLIC|PRIVATE> [items2...] ...])
```

它的作用是向目标文件添加头文件检索路径。当编译 `target` 目标文件时，去指定的 `iters*` 路径下检索头文件。`target` 的值必须是通过  [`add_executable()`](https://cmake.org/cmake/help/latest/command/add_executable.html#command:add_executable) 或 [`add_library()`](https://cmake.org/cmake/help/latest/command/add_library.html#command:add_library) 命令添加的目标文件名称。

`PROJECT_BINARY_DIR` 是指 cmake 提供的一个变量，表示目标文件输出的路径，通常就是执行 cmake 命令时的路径。还有一个变量 `PROJECT_SOURCE_DIR` ，表示源码的路径。它们的值都是由 `project()` 命令自动设置的。在 cmake 中，应用变量的语法是 `${variable-name}` 。

### 测试

修改完毕后，`CMakeLists.txt` 的完整内容是：

```cmake
cmake_minimum_required(VERSION 3.1)
project(Tutorial VERSION 1.0)

configure_file(TutorialConfig.h.in TutorialConfig.h)
add_executable(Tutorial Tutorial.c)

target_include_directories(Tutorial PUBLIC "${PROJECT_BINARY_DIR}")
```

然后，我们在 `build` 子目录下依次执行 `cmake ..` 和 `make` （或者 `cmake --build .`） ，生成的文件如下：

```bash
~$ ls
CMakeCache.txt      Tutorial            inc
CMakeFiles          TutorialConfig.h
Makefile            cmake_install.cmake
~$ ./Tutorial
Hello World!
MAJOR Version is 1
MINOR Version is 0
```

## 2. 添加一个库

下面我们在工程中添加一个用于数学计算的链接库，把库的源码放在 `MathFunctions` 子目录中，工程结构如下：

```bash
~$ tree
.
├── CMakeLists.txt
├── MathFunctions
│   ├── MathFunctions.h
│   └── mysqrt.c
├── Tutorial.c
└── TutorialConfig.h.in
```

头文件 `MathFunctions.h` 中声明了一个计算平方根的函数 `mysqrt()` ：

```c
double mysqrt(double x);
```

它定义在 `mysqrt.c` 文件中：

```c
#include <stdio.h>
#include "MathFunctions.h"

// a hack square root calculation using simple operations
double mysqrt(double x) {
    if (x <= 0) {
        return 0;
    }

    double result = x;

    // do ten iterations
    for (int i = 0; i < 10; ++i) {
        if (result <= 0) {
            result = 0.1;
        }
        double delta = x - (result * result);
        result = result + 0.5 * delta / result;
        printf("Computing sqrt of %f to be %f .\n", x, result);
    }
    return result;
}
```

然后，我们在 `Tutorial.c` 文件中调用这个函数计算一个数的平方根：

```c
#include <stdio.h>
#include "TutorialConfig.h"
#include "MathFunctions/MathFunctions.h"

int main (int argc, char *argv[])
{
    double input = 4;
    printf("Hello World!\n");
    printf("Version %d.%d\n", Tutorial_VERSION_MAJOR, Tutorial_VERSION_MINOR);

    double output = mysqrt(input);
    printf("The square root of %f is %f .\n", input, output);
    return 0;
}
```

编译的时候，我们希望将 `mysqrt.c` 生成一个共享库，再连接到 `Tutorial` 目标中。所以，需要对 CMake 的描述文件做如下修改：

1. 在 `MathFunctions` 子目录下新建一个 `CMakeLists.txt` ，内容是 `add_library(MathFunctions mysqrt.c)` ，表示将 `mysqrt.c` 编译为库文件。
2. 在顶层目录的 `CMakeLists.txt` 文件中如下内容：
   1.  `add_subdirectory(MathFunctions)` ，表示向 CMake 工程添加一个子目录，执行时会调用子目录中的 `CMakeLists.txt` 。
   2. `target_link_libraries(Tutorial PUBLIC MathFunctions)` ，表示目标文件 `Tutorial` 要链接 `MathFunctions` 。
   3. 因为 `Tutorial.c` 文件中导入了 `MathFunctions` 子目录下的头文件，所以，要用 `target_include_directories()` 命令将这个子目录也加入头文件检索路径。

完整的顶层目录 `CMakeLists.txt` 文件内容如下：

```cmake
cmake_minimum_required(VERSION 3.1)
project(Tutorial VERSION 1.0)

add_subdirectory(MathFunctions)

configure_file(TutorialConfig.h.in TutorialConfig.h)
add_executable(Tutorial Tutorial.c)

target_link_libraries(Tutorial PUBLIC MathFunctions)
target_include_directories(Tutorial PUBLIC 
                            "${PROJECT_BINARY_DIR}"
                            "${PROJECT_SOURCE_DIR}/MathFunctions"
                            )
```

然后，在 `build` 目录下依次执行 `cmake ..` 和 `cmake --build .` ，编译生成可执行文件 `Tutorial` ，执行：

```bash
~$ ./Tutorial
Hello World!
Version 1.0
Computing sqrt of 4.000000 to be 2.500000 .
Computing sqrt of 4.000000 to be 2.050000 .
Computing sqrt of 4.000000 to be 2.000610 .
Computing sqrt of 4.000000 to be 2.000000 .
Computing sqrt of 4.000000 to be 2.000000 .
Computing sqrt of 4.000000 to be 2.000000 .
Computing sqrt of 4.000000 to be 2.000000 .
Computing sqrt of 4.000000 to be 2.000000 .
Computing sqrt of 4.000000 to be 2.000000 .
Computing sqrt of 4.000000 to be 2.000000 .
The square root of 4.000000 is 2.000000 .
```

### 提供可选项

上一步添加的 `MathFunctions` 库可以做成一个可选的模块，这是大型工程里的常见做法。

首先需要用 `option()` 命令设置一个选项：

```cmake
option(USE_MYMATH, "Use tutorial provided math implementation", ON)
```

这样就设置了一个名为 `USE_MYMATH` 的选项，初始值是 `ON` 。`option()` 的作用是新建一个用户可以选择的选项，语法很简单：

```cmake
option(<variable> "<help_text>" [value])
```

三个参数依次是选项的变量名，选项的描述，选项的初始值。选项的值只有两个：`ON` 和 `OFF` ，如果没有设置初始值，默认就是 `OFF` 。

然后可以通过这个选项，把模块相关的语句包裹在一个选择语句中：

```cmake
option(USE_MYMATH "Use tutorial provided math implementation" ON)

if(USE_MYMATH)
    add_subdirectory(MathFunctions)
    list(APPEND EXTRA_LIBS MathFunctions)
    list(APPEND EXTRA_INCLUDES "${PROJECT_SOURCE_DIR}/MathFunctions")
endif()

target_link_libraries(Tutorial PUBLIC ${EXTRA_LIBS})
target_include_directories(Tutorial PUBLIC 
                            "${PROJECT_BINARY_DIR}"
                            "${EXTRA_INCLUDES}"
                            )
```

`list()` 命令用于操作列表，`APPEND` 可以将一个元素追加到一个列表的尾部。后面通过新建的列表调用模块，这样的话，只有 `USE_MYMATH ` 的值为 `ON` 时，才会将模块包含在编译过程中。

源码中的修改比较简单，只需修改 `Tutorial.c` 文件，通过宏定义将模块相关的语句做成可选项：

```c
#ifdef USE_MYMATH
    #include "MathFunctions/MathFunctions.h"
#endif

#ifdef USE_MYMATH
    double output = mysqrt(input);
    printf("The square root of %f is %f .\n", input, output);
#endif
```

这个宏定义的值也需要通过 `TutorialConfig.h.in` 文件传递给源码：

```cmake
#cmakedefine USE_MYMATH
```

执行到 `configure_file()` 命令的时候，如果 `USE_MYMATH` 的值是 `ON` ，这条语句会被替换为  `#define USE_MYMATH` ；如果  `USE_MYMATH` 的值是 `OFF` ，这条语句会被替换为一行注释 `/* #undef USE_MYMATH */` 。

### 设置库文件的使用要求

构建 C 语言的工程时，应该清晰的规划模块之间的关系，在编译时，先编译出子模块的目标文件，再由这些目标文件链接起来生成上一层的目标文件，层层递进，最终编译出可执行文件。目标文件包括 [`add_executable()`](https://cmake.org/cmake/help/latest/command/add_executable.html#command:add_executable) 和 [`add_library()`](https://cmake.org/cmake/help/latest/command/add_library.html#command:add_library) 命令生成的可执行文件和库。目标文件的依赖关系是通过两条命令控制的：

- [`target_include_directories()`](https://cmake.org/cmake/help/latest/command/target_include_directories.html#command:target_include_directories) ，向目标文件添加编译时的头文件检索目录。
- [`target_link_libraries()`](https://cmake.org/cmake/help/latest/command/target_link_libraries.html#command:target_link_libraries) ，向目标文件添加编译时依赖的库。

这两条命令需要一个控制传递属性的参数，可选三种关键字：

- `PRIVATE` ，私有。库文件提供的方法只供目标文件使用，不会暴露给更上层目标文件。即生产者需要，消费者不需要。
- `INTERFACE` ，接口。库文件提供的方法会暴露给上层文件使用，本目标文件只用到了库文件提供的一些数据结构和声明等。即生产者不需要，消费者需要。
- `PUBLIC` ，公开。库文件提供的方法可以供所有目标文件使用。即生产者和消费者都需要。

以上一节的工程为例，目录结果是：

```bash
.
├── build
├── CMakeLists.txt
├── MathFunctions      # 生成 libMathFunctions.a
│   ├── CMakeLists.txt
│   ├── MathFunctions.h
│   └── mysqrt.c
├── Tutorial.c
└── TutorialConfig.h.in
```

目标 `MathFunctions` 需要的头文件 `MathFunctions.h` 中的声明，并将方法暴露给上一层的 `Tutorial.c` 使用。所以，目标 `MathFunctions` 对头文件  `MathFunctions.h` 的使用要求就是 `INTERFACE` ，目标 `Tutrial` 对目标 `MathFunctions` 的使用要求是 `PRIVATE` 。

那么，可以在 `MathFunctions/CMakeLists.txt` 中添加一行：

```cmake
target_include_directories(MathFunctions
        INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
        )
```

然后就可以把顶层 `CMakeLists.txt` 中包含头文件的部分删除，并将库文件的使用要求改为私有：

```cmake
if(USE_MYMATH)
    add_subdirectory(MathFunctions)
    list(APPEND EXTRA_LIBS MathFunctions)
endif()

target_link_libraries(Tutorial PRIVATE ${EXTRA_LIBS})
target_include_directories(Tutorial PRIVATE 
                            "${PROJECT_BINARY_DIR}"
                            )
```

## 3. 安装和测试

这个工程只需要把可执行文件安装到指定的目录，所以，在顶层 `CMakeLists.txt` 目录下添加一行：

```cmake
install(TARGETS Tutorial DESTINATION bin)
```

这样，在执行 `make install` 时，就会把 `Tutorial` 文件安装到 `/usr/local/bin/` 目录下，默认的前缀是 `/usr/local/` ，如果要换别的目录，可以写上绝对路径。

