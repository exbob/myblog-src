---
title: Tkinter 学习笔记 
date: 2017-12-18T08:00:00+08:00
draft: false
toc: true
comments: true
---



## 0. 开始

Tkinter 是 Python 内置的 GUI 框架，安装后 Python 后即可使用：

    Python 3.6.2 (v3.6.2:5fd33b5926, Jul 16 2017, 20:11:06)
    [GCC 4.2.1 (Apple Inc. build 5666) (dot 3)] on darwin
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import tkinter as tk
    >>> tk._test()

运行结果：

![](./pics/2017-12-18_1.png)

下面这个例子只包含一个 Quit 按钮:

    import tkinter as tk
    
    window = tk.Tk() #定义一个顶层窗口
    window.title('my window')  #定义窗口的标题
    window.geometry('200x100')  #设置窗口的大小
    
    quitbutton = tk.Button(window, text="Quit", command=window.quit)  #在 window 上定义一个按钮，显示 Quit ，点击按钮执行 quit 方法
    quitbutton.grid()  #显示这个按钮
    window.mainloop()  #开始主循环

运行结果：

![](./pics/2017-12-18_2.png)

## 1. 布局管理

Tkinter 有多种布局管理系统，grid 是最常用的一种。以顶层窗口作为根控件形成一个控件树，一个父控件上可以包含很多子控件，例如顶层窗口上有按钮、输入框等，大体应该是如下的结构：

![](./pics/2017-12-18_3.png)

新建一个控件分为两步：

    self.thing = tk.Constructor(parent, ...)
    self.thing.grid(...)

1. 定义控件，Constructor 是一种控件的类， 比如 Button、Frame ，parent 表示该控件的父控件
2. 将控件放到窗口上，所有的控件都有 grid 方法，负责通知布局管理器将这个组件放置到合适的位置

grid 布局将父控件的显示区域划分为网格，使用 grid 布局的过程就是为各个子控件指定行号和列号，左上角的坐标是 (0,0)，不需要为每个单元格指定大小，grid 布局会自动设置一个合适的大小。grid 方法的原型是 `w.grid(option=value, ...)` ，它将控件 w 注册到父控件的 grid 布局，并设置所处的单元格坐标，常用属性如下：

* column ，列坐标，默认是 0 
* row ，行坐标，默认是新启一行
* sticky ，控件填充单元格的方式，不设置该选项时默认是横竖居中，它有两种可选值，可以用加号组合：
    * 紧贴单元格的某个角落：sticky=tk.NE (右上角) ， tk.SE (右下角) ， tk.SW (左下角) 或者 tk.NW (左上角)
    * 紧贴单元格的某条边线：sticky=tk.N (上边居中) ， tk.E (右边居中) ， tk.S (底边居中) 或者 tk.W (左边居中)
* padx ，横向内边距
* pady ，纵向内边距

也可以手动设置当前控件的单元格大小：

* 设置第 N 列：`w.columnconfigure(N, option=value, ...)`
* 设置第 N 行：`w.rowconfigure(N, option=value, ...)`

option 有三个属性可选：

* minsize ，行或者列的最小尺寸，单位是像素
* pad ，行或者列占用的尺寸大小，单位是像素
* weight ，设置行或者列占用的比例，使网格尺寸具有弹性，

例如：

    import tkinter as tk
    
    window = tk.Tk()
    window.title('my window')
    window.geometry('200x100')
    window.columnconfigure(0, weight=1)  #第一列占用 1/3 宽度
    window.columnconfigure(1, weight=2)  #第二列占用 2/3 宽度
    window.rowconfigure(0, weight=1)  #第一行占用全部高度
    
    Abutton = tk.Button(window, text="A")
    Abutton.grid()
    Bbutton = tk.Button(window, text="B")
    Bbutton.grid(row=0,column=1,sticky=tk.W+tk.E)
    
    window.mainloop()

运行结果：

![](./pics/2017-12-18_4.png)

还有一些常用的方法：

* w.grid_forget() ，隐藏一个控件
* w.grid_propagate() ，控件的尺寸通常是由控件里的内容决定的，但是有时需要强制设置控件大小，这就要先设置 `w.grid_propagate(0)` ，然后设置尺寸
* w.grid_info()，返回一个字典，包含了控件的属性名称和值
* w.grid_size()，返回一个元组，包含两个元素，分别是行和列
* w.grid_configure(option, ...) ，设置 grid 的属性，例如 `w.grid_configure(padx=5,pady=5)`

## 2. 一个完整的例子

### 2.1. 设计

这个例子是一个单窗口 GUI 应用，功能是将英尺转换为米，界面草图是这个样子：

![](./pics/2017-12-18_5.jpg)

第一行有一个输入框，单位 feet 放在一个标签里，第二行中间是一个空白标签，用于放置转换后的结果，左右分别是文字说明，右下角是一个 'Calculate' 按钮，按下时获取输入框中的数值，转换成米后显示在中间的标签中。整个窗口是一个 3x3 的 grid 布局：


![](./pics/2017-12-18_6.jpg)

三行所占高度应该是 1:1:1 ，三列所占的宽度应该是 2:1:1 ，输入框宽度 7 个字符。

### 2.2. 编码

新建一个目录，编辑源文件 mygui.py ，代码如下：

    #!~/py3-env/bin/python
    import tkinter as tk
    
    #新建一个根窗口，并设置窗口标题
    window = tk.Tk()
    window.title('Feet to Meters')
    
    #按下按钮是调用的函数，获取输入框的值，转换成米制单位在写入标签
    def calculate(*args):
        value = float(feet.get())
        meters.set( (0.3048*value*10000.0 + 0.5) / 10000.0 )
    
    #在窗口上绘制一个框架，并定义框架的内边距
    mainframe = tk.Frame(window,padx=15,pady=25)
    #mainframe 会占满整个窗口
    mainframe.grid(row=0,column=0,sticky=tk.N+tk.W+tk.E+tk.S)
    mainframe.rowconfigure(0,weight=1)
    mainframe.columnconfigure(0,weight=1)
    
    #输入框位于第一行第二列，左右占满，宽度是 7 个字符，内部文本右对齐，并且是程序启动后默认的焦点
    feet=tk.StringVar()
    feet_entry = tk.Entry(mainframe,width=7,justify=tk.RIGHT,textvariable=feet)
    feet_entry.grid(row=0,column=1,sticky=tk.W+tk.E)
    feet_entry.focus()
    
    feet_label = tk.Label(mainframe,text="Feet",anchor=tk.W)
    feet_label.grid(row=0,column=2,sticky=tk.W)
    
    meters=tk.StringVar()
    tk.Label(mainframe,text="is equivalent to").grid(row=1,column=0,sticky=tk.E)
    tk.Label(mainframe,textvariable=meters).grid(row=1,column=1,sticky=tk.W+tk.E)
    tk.Label(mainframe,text="Meters").grid(row=1,column=2,sticky=tk.W+tk.W)
    
    #在右下角放置一个按钮，按下时执行 calculate 函数
    tk.Button(mainframe,text="Calculate",command=calculate).grid(row=2,column=2,sticky=tk.W)
    
    #设置 mainframe 内每个控件的内边距为 5
    for child in mainframe.winfo_children():
        child.grid_configure(padx=5,pady=5)
    
    #按下回车键时也会执行转换
    window.bind('<Return>', calculate)
    
    window.mainloop()

保存后运行，看一下效果：

![](./pics/2017-12-18_7.png)

### 2.3. 打包

测试成功后用 pyinstaller 将源码打包，这样在其他计算机上也可以运行，甚至不用安装 python ，但是有一点要注意，在 macOS 下用 pyinstaller 打包的程序只能运行于 macOS ，在 Windows 下用 pyinstaller 打包的程序只能运行于 Windows 。先安装 pyinstaller ：

    $ pip  install  pyinstaller
    $ python -m PyInstaller --version
    3.3.1

这个版本在 macOS 上有个 Bug ，就是打包的 tkinter 程序在运行时会报如下的错误：

    ImportError: dlopen(/var/folders/gk/q_9lv83d6999mzn5d3cjrry80000gn/T/_MEIlRBLqx/_tkinter.so, 2): Library not loaded: @loader_path/Tcl
      Referenced from: /var/folders/gk/q_9lv83d6999mzn5d3cjrry80000gn/T/_MEIlRBLqx/_tkinter.so
      Reason: image not found

需要安装下面提供的补丁修改 pyinstaller : <https://github.com/pyinstaller/pyinstaller/pull/2969> 。然后在源码目录下执行：

    $ pyinstaller  -w  -F  mygui.py

-F 表示将所有文件和库打包成一个文件，这样在没有安装 python 的计算机上也可以运行，-w 表示关闭终端，否则在运行生成的应用在打开时会运行一个终端。生成的应用程序在 dist 目录下，该目录下有两个文件，mygui 是调试版，mygui.app 是发行版，双击 mygui.app 即可运行：


![](./pics/2017-12-18_8.png)

默认打包后的程序是不支持 Retina 屏幕的，所以在 macOS 上会显示模糊。需要先生成一个 spec 文件：

    $ pyi-makespec -w -F mygui.py

然后编辑生成的 mygui.spec ，添加 `info_plist` 并设置 `'NSHighResolutionCapable': 'True'` ：

    app = BUNDLE(exe,
                 name='mygui.app',
                 icon=None,
                 bundle_identifier=None,
                 info_plist={
                     'NSHighResolutionCapable': 'True'
                 }
                )

保存后用这个配置文件执行打包任务：

    $ pyinstaller -w -F mygui.spec

这样生成的应用就支持 Retina 屏幕了。

## 3. 常用控件

每个控件都是一个类，调用控件的初始化函数就会新建一个实例。

### 3.1. 按钮

按钮的原型：

    w = tk.Button(parent, option=value, ...)

* bg or background	，背景颜色
* bd or borderwidth	 ，边框宽度，默认是 2
* anchor ，按钮上文字的对齐位置，例如 anchor=tk.NE 表示右上角对齐
* text ，按钮上显示的文字
* textvariable ，为该属性设置一个控制变量 StringVal 类的实例，以后修改这个变量就可以修改标签内显示的文本
* command ，设置按钮按下时的行为，可以指向一个函数或者方法
* width ，按钮的宽度，单位是字符个数，如果按钮显示的是图片，则单位是像素
* padx ，按钮边框与文字之间的横向间距，就是内边距，单位是像素
* pady ，按钮边框与文字之间的纵向间距，单位是像素
* relief ，3D 样式，默认值是 relief=tk.RAISED，可选四个值：tk.GROOVE(边框突出)，tk.RIDGE(边框凹陷)，tk.SUNKEN(整体凹陷)，tk.RAISED(整体突出)，边框宽度由 borderwidth 决定
* state ，按钮的状态，默认是 tk.NORMAL ，鼠标悬停时这个值是 tk.ACTIVE ，设为 tk.DISABLED 时按钮变灰并且失效

它有两个方法：

* .invoke() ，调用 command 指定的函数。
* .flash() ，使按钮的颜色在按下和放开之间闪烁几次。

例程：

    import tkinter as tk
    
    window = tk.Tk()
    window.title('my window')
    window.geometry('200x100')
    window.columnconfigure(0, weight=1)
    window.rowconfigure(0, weight=1)
    
    button = tk.Button(window, anchor=tk.CENTER, text='Quit', command=window.quit)
    button.grid()
    
    window.mainloop()

运行结果：

![](./pics/2017-12-18_9.png)

### 3.2. 标签

标签控件可以显示一行或者多行文本，或者一张图片。

    w = tk.Label(parent, option, ...)

常用属性；

* activebackground ，鼠标经过时的背景颜色
* activeforeground ，鼠标经过时的前景颜色
* anchor ，文本或者图片的对齐位置，默认是  anchor=tk.CENTER 
* bg or background ，背景颜色
* bd or borderwidth	 ，边框宽度，默认是 2
* text ，显示是文本
* textvariable ，为该属性设置一个控制变量 StringVal 类的实例，以后修改这个变量就可以修改标签内显示的文本
* width ，宽度，单位是字符，如果没有设置，宽度随内容变化
* padx ，按钮边框与文字之间的横向间距，就是内边距，单位是像素
* pady ，按钮边框与文字之间的纵向间距，单位是像素
* relief ，3D 样式，默认值是 relief=tk.FLAT，可选四个值：tk.GROOVE(边框突出)，tk.RIDGE(边框凹陷)，tk.SUNKEN(整体凹陷)，tk.RAISED(整体突出)，边框宽度由 borderwidth 决定

例程：

    import tkinter as tk
    
    window = tk.Tk()
    window.title('my window')
    window.geometry('200x100')
    window.columnconfigure(0, weight=1)
    window.rowconfigure(0, weight=1)
    
    label = tk.Label(window, bg='#ff0000', text='Please',padx=5, pady=3)
    label.grid()
    
    window.mainloop()

运行结果：

![](./pics/2017-12-18_10.png)

### 3.3. 输入框

输入框可以显示和输入单行文本，文本中的字符编号从 0 开始，常量 tk.END 表示文本的结尾，tk.INSERT 表示当前光标所处的位置，原型：

    w = tk.Entry(parent, option, ...)

常用属性：

* bg or background	，背景颜色
* bd or borderwidth	 ，边框宽度，默认是 0
* width ，输入框能够容纳的字符数，默认是 20
* show，默认情况下，输入的字符会直接显示，如果是密码，需要隐藏，可以要求输入的字符都显示为星号： `show='*'`
* justify ，输入框内文本的对齐方式，默认是左对齐 justify=tk.LEFT ，还可选 tk.CENTER 和 tk.RIGHT
* validate ，设置检查输入框内容的时机
* validatecommand ，设置一个回调函数，负责检查输入框的内容
* textvariable ，为该属性设置一个控制变量 StringVar 类的实例，就可以用 v.get() 方法取回输入框中内容，或者用 v.set(value) 设置，v 就是这个实例
* state ，默认是 tk.NORMAL ，鼠标悬停时这个值是 tk.ACTIVE ，设为 tk.DISABLED 时输入框变灰，并无法输入。

常用方法：

* .delete(first, last=None) ，删除字符，从第 first 个字符到第 last 个字符之前。
*  .get() ，获取输入框中的文本，返回值是字符串。
*  .insert(index, s) ，在第 index 个字符前插入字符串 s 。


例程：

    import tkinter as tk
    
    window = tk.Tk()
    window.title('my window')
    window.geometry('300x100')
    window.columnconfigure(0, weight=1)
    window.columnconfigure(1, weight=2)
    window.rowconfigure(0, weight=1)
    
    label1 = tk.Label(window,text="Username:", anchor=tk.E)
    label1.grid(row=0,column=0,sticky=tk.SE)
    user = tk.Entry(window, width=16, justify=tk.RIGHT)
    user.grid(row=0,column=1,sticky=tk.SW)
    
    label2 = tk.Label(window,text="Password:", anchor=tk.E)
    label2.grid(row=1,column=0,sticky=tk.NE)
    passwd = tk.Entry(window, width=16,show='*', justify=tk.RIGHT)
    passwd.grid(row=1,column=1,sticky=tk.NW)
    
    window.mainloop()

运行结果：

![](./pics/2017-12-18_11.png)

有时我们需要检查输入的文本是否合法，这需要定义一个检测函数，并设置调用它的时间，具体步骤：

1. 定义一个回调函数，负责检查输入的内容，如果合法就返回 True ，否则返回 False 
2. 用 `w.register(function)` 方法将回掉函数封装为 Tcl ，它会返回一个字符串，用它设置 validatecommand 
3. 设置 validate ，声明调用回掉函数的时机，常用从选项有：
    * 'focus' ，输入框获得或者失去焦点时
    * 'focusin' ，输入框获得焦点时
    * 'focusout' ，输入框失去焦点时
    * 'key' ，内容改变时
    * 'all' ，以上任何情况发生时
    * 'none' ，关闭内容检查，这是默认值

### 3.4. 框架

框架是其他控件的容器，顶层窗口本质上就是一个框架，默认情况下，框架会紧紧的包裹它的控件，它的原型：

    w = Frame(parent, option, ...)

常用属性：

* bg or background	，背景颜色
* bd or borderwidth	 ，边框宽度，默认是 0
* width ，框架的宽度， `w.grid_propagate(0)`  时有效
* height ，框架的高度，`w.grid_propagate(0)`  时有效
* padx ，在框架与控件之间的横向间距，单位是像素
* pady ，在框架与控件之间的纵向间距
* relief ，3D 样式，默认情况下，框架是完全隐形的 relief=tk.FLAT，可选四个值：tk.GROOVE(边框突出)，tk.RIDGE(边框凹陷)，tk.SUNKEN(整体凹陷)，tk.RAISED(整体突出)，边框宽度由 borderwidth 决定

下面是一个例程：

    import tkinter as tk
    
    window = tk.Tk()
    window.title('my window')
    window.geometry('200x100')
    window.columnconfigure(0, weight=1)
    window.rowconfigure(0, weight=1)
    
    frame = tk.Frame(window,height=50,width=100,relief=tk.GROOVE,bd=5)
    frame.grid_propagate(0)
    frame.grid()
    
    label = tk.Label(frame, text="Label")
    label.grid()
    
    window.mainloop()

运行结果：

![](./pics/2017-12-18_12.png)
### 3.5. 标签框架

LabelFrame 控件是带有标签的框架，原型：

    w = tk.LabelFrame(parent, option, ...)

常用属性：

* bg or background	，背景颜色
* bd or borderwidth	 ，边框宽度，默认是 2
* width ，框架的宽度， `w.grid_propagate(0)`  时有效
* height ，框架的高度，`w.grid_propagate(0)`  时有效
* labelwidget ，可以在标签中插入任何控件，代替原来的文本
* text ，标签中的文字
* labelanchor ，标签在框架上的位置，默认值是 'nw' ，可选值：
    
    ![](./_image/2017-12-21-10-35-09.png)

* padx=N ，在框架与控件之间，横向添加 N 个像素
* pady=N ，在框架与控件之间，纵向添加 N 个像素
* relief ，3D 样式，默认情况下，默认值是 tk.GROOVE，可选四个值：tk.GROOVE(边框突出)，tk.RIDGE(边框凹陷)，tk.SUNKEN(整体凹陷)，tk.RAISED(整体突出)，边框宽度由 borderwidth 决定

例程：

    import tkinter as tk
    
    window = tk.Tk()
    window.title('my window')
    window.minsize(width=300,height=150)
    window.columnconfigure(0, weight=1)
    window.rowconfigure(0, weight=1)
    
    login = tk.LabelFrame(window,text="Login",labelanchor='n',padx=10,pady=10)
    login.grid()
    
    label1 = tk.Label(login,text="Username:", anchor=tk.E)
    label1.grid(row=0,column=0,sticky=tk.SE)
    user = tk.Entry(login, width=16, justify=tk.RIGHT)
    user.grid(row=0,column=1,sticky=tk.SW)
    
    label2 = tk.Label(login,text="Password:", anchor=tk.E)
    label2.grid(row=1,column=0,sticky=tk.NE)
    passwd = tk.Entry(login, width=16,show='*', justify=tk.RIGHT)
    passwd.grid(row=1,column=1,sticky=tk.NW)
    
    window.mainloop()

运行结果：

![](./pics/2017-12-18_13.png)

### 3.6. 菜单


## 4. 顶层窗口

`Tk()` 是由 root 新建的顶层窗口，如果要新建其他窗口，需要调用 `.Toplevel()` 方法：

    w = tk.Toplevel(option, ...)

### 4.1. 常用属性

* bg or background ，背景颜色
* bd or borderwidth	 ，边框宽度，默认是 0 
* menu ，为该属性传递一个 menu 控件的实例，会为窗口添加一个菜单栏，如果是 Windows 或者 Unix 系统，菜单栏会出现在串口的顶端，如果是 MacOS ，菜单栏会出现在屏幕顶端

### 4.2. 常用方法

* .maxsize(width=None, height=None) ，设置窗口的最大尺寸。
* .minsize(width=None, height=None) ，设置窗口的最小尺寸。
* .title(text=None) ，设置窗口标题。
* .withdraw() ，隐藏窗口。
* .geometry(newGeometry=None) ，设置窗口的尺寸，参数 newGeometry 是一个几何字符串。

## 5. 通用方法

下面是每个控件都支持的方法。

* w.mainloop() ，主循环，处理各种事件，通常在所有静态控件新建完毕后调用，
* w.quit() ，结束主循环 `.mainloop()` ，程序退出
* w.bind(sequence=None, func=None, add=None) ，将当前控件上发生的事件与某些函数绑定，sequence 是描述事件的字符串
* w.bind_all(sequence=None, func=None, add=None)，将当前应用上所有控件发生的事件与某写函数绑定
* w.bind_class(className, sequence=None, func=None, add=None) ，将某一类控件发生的事件与某些函数绑定，className 是控件类的名称，比如 'Button'
* w.winfo_screenheight() ，返回屏幕垂直方向的分辨率
* w.winfo_screenwidth() ，返回屏幕水平方向的分辨率
* w.winfo_children() ，返回一个包含所有子控件的列表，从低到高排序
* w.configure(option=value, ...) ，设置一个或者多个属性

## 6. 标准属性
### 6.1. 坐标

Tkinter 的坐标系以左上角为原点，横轴是 x ：


![](./pics/2017-12-18_14.png)

Tkinter 还定义了一些常量，用于控制相对位置，比如标签内文字的对齐方向等，下面是这些常量的示意图：

![](./pics/2017-12-18_15.png)

### 6.2. 单位

许多控件的长度、宽度、或者其他尺寸的单位可以是像素、字符，也可以用其他单位描述，只需在数字的后面跟上单位即可：

| 单位 | 描述
| --- | ---
| c	 | 厘米
| i	| 英寸
| m | 毫米
| p | 打印机的点 
 
### 6.3. 颜色

Tkinter 中的颜色可以用 RGB 字符串表示：

| 字符串 | 描述
| --- | ---
| #rgb | 每种颜色占四位
| #rrggbb | 每种颜色占八位 
| #rrrgggbbb | 每种颜色占十二位

比如 '#FFF' 是白色，'#000000' 是黑色，'#FF0000' 是红色。还可以使用已经定义的标准颜色名称，比如 'white' ， 'black' ， 'red' ， 'green' ， 'blue' ， 'cyan' ， 'yellow' 和 'magenta' 。

### 6.4. 几何字符串

几何字符串是描述顶层窗口大小和位置的标准方法，通常的格式是 `'wxh±x±y'`，由三个部分组成：

* w 和 h 分别表示宽和高，单位是像素，用 x 连接，这个部分是必须的
* 如果后面跟着 +x ，表示窗口的左边框距离屏幕左边框 x 个像素，如果是 -x ，表示窗口的左边框超出屏幕左边框 x 个像素
* 如果后面还正常 +y ，表示窗口的上边框距离屏幕上边框 y 个像素，如果是 -y ，表示窗口的上边框超出屏幕上边框 y 个像素

## 7. 控制变量

Tkinter 的控制变量是一种特定的对象，它的行为类似 Python 的普通变量，就是值的容器。它的特殊之处是可以由一组控件共享，如果某个控制变量 c 调用 `c.set()` 方法改变了自己的值，那么所有使用 c 的控件都会自动更新。控制变量的作用是保存控件上的某些值。控制变量有三种：

    v = tk.DoubleVar()   # Holds a float; default value 0.0
    v = tk.IntVar()      # Holds an int; default value 0
    v = tk.StringVar()   # Holds a string; default value ''

控制变量有两个方法：

* .get() ，返回变量的值
* .set(value) ，设置变量的值

用到控制变量的控件包括：

| 控件 | 属性 | 类型
| --- | --- | ---
| Button | textvariable | StringVar
| Entry | textvariable | StringVar
| Label | textvariable | StringVar
| Checkbutton | variable | IntVar
| Menubutton | textvariable | StringVar

## 8. 焦点：引导键盘输入

某个控件被设为焦点（focus），意味着键盘输入会直接作用于这个控件。Tkinter 可以设置某个控件为默认焦点，也可以设置各种控件的焦点顺序，也就是用 Tab 键切换时的顺序。

## 9. 事件：对刺激做出反应

前面我们都在描述怎么绘制图形界面，下面我们讨论如今将控件与后台功能联系起来，让用户的操作得到实际的反馈。

事件（event）就是应用程序上发生的事情，比如键盘输入、鼠标单击或者双击，应用程序应该对此作出反应。很多控件都有一些内置的行为，比如按钮按下时会调用 command 指向的函数。Tkinker 允许为一个或者多个事件定义相应的处理方法，有三中绑定级别：

1. 单独绑定，为一个控件上可能发生的某些事件绑定一个方法：`w.bind(sequence=None, func=None, add=None)` ，比如在 canvas 控件里为 PageUp 按键绑定一个翻页功能的方法。
2. 分类绑定，为所用同类控件上可能发生的某些事件绑定一个方法：`w.bind_class(className, sequence=None, func=None, add=None)` ，比如双击鼠标时所有的按钮同时按下。
3. 应用绑定，为应用上所有控件可能发生的某些事件绑定一个犯法：`w.bind_all(sequence=None, func=None, add=None)` 。

Tkinter 用事件序列字符串（sequence） 的方式描述事件，一个字符串可以描述一个或者多个事件，字符串遵循如下格式：

    <[modifier-]...type[-detail]>

* 字符串由尖括号 <> 包围
* type 是必选项，指事件类型，例如按键，鼠标等
* modifier 是可选项，可以连续设置多个，与 type 组成混合体来描述组合键，例如按下 shift 的时候单击鼠标
* detail 是可选项，描述具体是哪个键盘按键、哪个鼠标按键。

下面是三个例子：

| sequence | 描述
| --- | ---
| Button-1 | 按下鼠标左键
| KeyPress-H | 按下键盘上的 H 键
| Control-Shift-KeyPress-H | 按下 control-shift-H 组合键

### 9.1. type

常用的事件类型：

| Name | Type | 描述
| --- | --- | ---
| Activate | 36 | 控件被激活，这个事件是由控件的 state 属性变化引起的
| Button | 4 | 按下鼠标，具体哪个键被按下由 detail 决定，按了几次由 modifier 决定
| ButtonRelease | 5 | 松开鼠标，通常松开时触发事件比按下时更好
| Configure | 22 | 控件的大小发生改变
| Deactivate | 37 | 控件的状态由激活变为不可用（灰色），这个事件是由控件的 state 属性变化引起的
| Destroy | 17 | 控件被毁灭
| Enter | 7 | 鼠标移动到了控件上
| Expose | 12 | 控件从被其他窗口遮挡的状态变为可见时
| FocusIn | 9 | 控件获得输入焦点时，这个事件可以由程序内部产生，比如调用 `.focus_set()`  时
| FocusOut | 10 | 输入焦点从控件上移开时，这个事件可以由程序内部产生
| KeyPress | 2 | 按下键盘按键，具体哪个键被按下由 detail 决定，按了几次由 modifier 决定
| KeyRelease | 3 | 松开键盘按键，
| Leave | 8 | 鼠标从控件上移开
| Map | 19 | 控件变为可见时，比如调用 `.grid()` 方法
| Motion | 6 | 在控件内移动鼠标
| MouseWheel | 38 | 上下移动鼠标滚轮，只在 Windows 和 macOS 下有效， Linux 不支持
| Unmap | 18 | 控件变为不可见状态，比如调用 `.grid_remove()` 方法
| Visibility | 15 | 应用程序窗口的一部分在屏幕上变为可见

### 9.2. modifier

所有可选的 modifier 名称：

| modifier | 描述
| --- | ---
| Alt | 按住 Alt 键
| Any | 表示任意的，用于概况一类事件，比如 '<Any-KeyPress>' 表示按下任意按键
| Control | 按住 control 键
| Double | 双击，即很短的时间内连续发生两次，例如 '<Double-Button-1>' 表示双击鼠标左键 
| Lock  | 按下 shift lock 键
| Shift | 按住 shift 键
| Triple | 三击，即很短的时间内连续发生三次

### 9.3. detail

对于鼠标事件，1 表示鼠标左键，3 表示鼠标右键。对于键盘事件，Tkinter 提供了多种方式识别按键，这几种方式都是 Event 类支持的属性 ：

* .keysym 表示按键的符号，有的按键有两个符号
* .keycode 表示按键的编码，但是这种编码没有区分同一按键上的不同符号，比如小键盘的数字 2 (KP_2) 和向下箭头 (KP_Down) 是同一个按键，编码都是 88 ，也无法区分大小写，所以 a 和 A 的编码是一样的
* .keysym_num 表示与按键符号相对应的编码

下表是美式 101-key 键盘通用字符集的部分符号：

| .keysym | .keycode | .keysym_num | Key
| --- | --- | --- | ---
| Alt_L | 64 | 65513 | The left-hand alt key
| Alt_R | 113 | 65514 | The right-hand alt key
| BackSpace | 22 | 65288 | backspace
| Cancel | 110 | 65387 | break
| Caps_Lock | 66 | 65549 | CapsLock
| Control_L | 37 | 65507 | The left-hand control key
| Control_R | 109 | 65508 | The right-hand control key
| Delete | 107 | 65535 | Delete
| Down | 104 | 65364 | ↓
| End | 103 | 65367 | end
| Escape | 9 | 65307 | esc
| Execute | 111 | 65378 | SysReq
| F1 | 67 | 65470 | Function key F1
| F2 | 68 | 65471 | Function key F2
| Fi | 66+i | 65469+i | Function key Fi
| F12 | 96 | 65481 | Function key F12
| Home | 97 | 65360 | home
| Insert | 106 | 65379 | insert
| Left | 100 | 65361 | ←
| Linefeed | 54 | 106 | Linefeed (control-J)
| KP_0 | 90 | 65438 | 0 on the keypad
| KP_1 | 87 | 65436 | 1 on the keypad
| KP_2 | 88 | 65433 | 2 on the keypad
| KP_3 | 89 | 65435 | 3 on the keypad
| KP_4 | 83 | 65430 | 4 on the keypad
| KP_5 | 84 | 65437 | 5 on the keypad
| KP_6 | 85 | 65432 | 6 on the keypad
| KP_7 | 79 | 65429 | 7 on the keypad
| KP_8 | 80 | 65431 | 8 on the keypad
| KP_9 | 81 | 65434 | 9 on the keypad
| KP_Add | 86 | 65451 | + on the keypad
| KP_Begin | 84 | 65437 | The center key (same key as 5) on the keypad
| KP_Decimal | 91 | 65439 | Decimal (.) on the keypad
| KP_Delete | 91 | 65439 | delete on the keypad
| KP_Divide | 112 | 65455 | / on the keypad
| KP_Down | 88 | 65433 | ↓ on the keypad
| KP_End | 87 | 65436 | end on the keypad
| KP_Enter | 108 | 65421 | enter on the keypad
| KP_Home | 79 | 65429 | home on the keypad
| KP_Insert | 90 | 65438 | insert on the keypad
| KP_Left | 83 | 65430 | ← on the keypad
| KP_Multiply | 63 | 65450 | × on the keypad
| KP_Next | 89 | 65435 | PageDown on the keypad
| KP_Prior | 81 | 65434 | PageUp on the keypad
| KP_Right | 85 | 65432 | → on the keypad
| KP_Subtract | 82 | 65453 | - on the keypad
| KP_Up | 80 | 65431 | ↑ on the keypad
| Next | 105 | 65366 | PageDown
| Num_Lock | 77 | 65407 | NumLock
| Pause | 110 | 65299 | pause
| Print | 111 | 65377 | PrintScrn
| Prior | 99 | 65365 | PageUp
| Return | 36 | 65293 | The enter key (control-M). The name Enter refers to a mouse-related event, not a keypress; see Section 54, “Events”
| Right | 102 | 65363 | →
| Scroll_Lock | 78 | 65300 | ScrollLock
| Shift_L | 50 | 65505 | The left-hand shift key
| Shift_R | 62 | 65506 | The right-hand shift key
| Tab | 23 | 65289 | The tab key
| Up | 98 | 65362 | ↑

## 10. ttk : 主题控件

从 Tk 8.5 开始，正式加入了 ttk 模块，这个模块可以替代大部分 Tkinter 原有的机制，而且带来了很多优势：

* 在 Tk 8.5 以前，开发者经常抱怨的就是 Tkinter 的 UI 风格无法适应操作系统，显得很难看。ttk 可以在自适应不同的操作系统 UI 风格，无需修改程序代码。
* 原有的控件都有一个  ttk 的版本，还增加了一些新的控件
* 带来了更加简化和易于操作的控件属性。


推荐使用如下方式导入 ttk 模块：

    from tkinter import ttk

这样的话，ttk.Label 就表示 Label 控件。

### 10.1. ttk.Button

按钮控件，原型：

    w = ttk.Button(parent, option=value, ...)

常用属性：

* command ，按下按钮是调用的函数
* image ，设置按钮上显示的图片
* text ，设置按钮上显示的文字
* compound ，如果同时设置了 image 和 text ，该属性设置了 image 相对于 text 的位置，有四个可选值：tk.TOP (image 在 text 上面) ，tk.BOTTOM (image 在 text 下面) ，tk.LEFT (image 在 text 左边) ，tk.RIGHT (image 在 text 右边)
* textvariable ，控制变量 StringVal 
* width ，按钮的宽度，单位是字符个数，如果按钮显示的是图片，则单位是像素
* underline ，设置一个数字 n ，按钮上的第 n 个字符会显示一条下划线
* style ，原 Tkinter 的样式属性都被这个属性代替了

出来通用方法，它还有一个自己的方法：

* .invoke() ，调用 command 指定的函数。

### 10.2. ttk.Entry

输入框，函数原型：

    w = ttk.Entry(parent, option=value, ...)

常用属性：

* width ，输入框能够容纳的字符数，默认是 20
* show，默认情况下，输入的字符会直接显示，如果是密码，需要隐藏，可以要求输入的字符都显示为星号： `show='*'`
* justify ，输入框内文本的对齐方式，默认是左对齐 justify=tk.LEFT ，还可选 tk.CENTER 和 tk.RIGHT
* validate ，设置检查输入框内容的时机
* validatecommand ，设置一个回调函数，负责检查输入框的内容
* textvariable ，为该属性设置一个控制变量 StringVar 类的实例，就可以用 v.get() 方法取回输入框中内容，或者用 v.set(value) 设置，v 就是这个实例
* style ，原 Tkinter 的样式属性都被这个属性代替了

ttk.Entry  支持所有 ttk 的通用方法和 tk.Entry 的方法。

### 10.3. ttk.Combobox

带下拉菜单的输入框，函数原型：

    w = ttk.Combobox(parent, option=value, ...)

常用属性：

* exportselection ，默认情况下，选中的内容会自动复制到剪贴板，设置 `exportselection=0` 可以关闭这个特性
* height ，设置下拉菜单中选项的最大行数，默认是 20 ，如果超过这个值，会自动出现滚动条
* justify ，输入框内文本的对齐方式，默认是左对齐 justify=tk.LEFT ，还可选 tk.CENTER 和 tk.RIGHT
* postcommand ，设置一个回调函数，当用户点击下拉菜单是会调用，可用于修改 values 属性
* textvariable ，为该属性设置一个控制变量 StringVar 类的实例，就可以用 v.get() 方法取回输入框中内容，或者用 v.set(value) 设置，v 就是这个实例
* validate ，设置检查输入框内容的时机
* validatecommand ，设置一个回调函数，负责检查输入框的内容
* values，设置一个字符串序列，作为下拉菜单中的选项
* width ，输入框能够容纳的字符数，默认是 20
* style ，原 Tkinter 的样式属性都被这个属性代替了

ttk.Combobox 支持所有 ttk 的通用方法和 tk.Entry 的方法，此外还支持：

* .current([index]) ,
* .set(value) ，设置空间输入框中的值为 value

ttk.Combobox 的状态会显示不同的行为特性。控件状态由通用方法 `.instate()` 和 `.state()` 设置。如果控件处于 disabled 状态，用户无法改变控件的内容；如果空间处于 !disabled & readonly 状态，用户可以通过下拉菜单改变空间内容，但不能直接输入。

### 10.4. ttk.Frame

框架控件，函数原型：

    w = ttk.Frame(parent, option=value, ...)

### 10.5. ttk.Label

标签控件，函数原型：

    w = ttk.Label(parent, option=value, ...)

### 10.6. ttk.LabelFrame

带标签的框架，函数原型：

    w = ttk.LabelFrame(parent, option=value, ...)

### 10.7. ttk.Notebook

标签页控件，函数原型：

    w = ttk.Notebook(parent, option=value, ...)

### 10.8. ttk.Menubutton

下拉菜单，函数原型：

    w = ttk.Menubutton(parent, option=value, ...)

## 11. ttk 的样式和主题

绘制 ttk 控件包含三个层面的抽象概念：

1. theme 表示一个应用中所有控件的设计主题
2. style 描述了一种控件本身的显示方式，一个 theme 是由多种 style 组成的，你可以使用内置的 style ，也可以新建自己的 style 。
3. 每个 style 都是有一个或者多个 element 组成的，一个按钮的 style 通常有四个 element ：外边框，聚焦时的颜色变化，内边距，按钮标签（文本或者图片）：

    ![](./_image/2017-12-25-13-28-07.png)

下面依次讨论如何寻找、使用和定制这几层样式。

### 11.1. 寻找并使用 theme

与样式相关的操作都需要新建一个 `ttk.Style()` 类的实例，例如获取所有可用的 theme 列表： 

    >>> from tkinter import ttk
    >>> s=ttk.Style()
    >>> s.theme_names()
    ('aqua', 'clam', 'alt', 'default', 'classic')

`.theme_names()` 会返回一个元组，包含了所有可用的 theme 。如果要查看当前默认的 theme ，直接调用 `.theme_use()` ，在参数里加上 theme 名就可以改变当前的 theme ：

    >>> s.theme_use()
    'aqua'
    >>> s.theme_use('default')
    >>> s.theme_use()
    'default'

### 11.2. 使用和定制 style

对于一个给定的 theme ，为每一种控件都定义了默认的 style ，本质上是一个类，每个 style 类名就是控件名加上前缀 "T" ，下表是 ttk 控件对应的 style 名称：

| Widget class | Style name
| --- | ---
| Button | TButton
| Checkbutton | TCheckbutton
| Combobox | TCombobox
| Entry | TEntry
| Frame | TFrame
| Label | TLabel
| LabelFrame | TLabelFrame
| Menubutton | TMenubutton
| Notebook | TNotebook
| PanedWindow | TPanedwindow (not TPanedWindow!)
| Progressbar | Horizontal.TProgressbar or Vertical.TProgressbar, depending on the orient option.
| Radiobutton | TRadiobutton
| Scale | Horizontal.TScale or Vertical.TScale, depending on the orient option.
| Scrollbar | Horizontal.TScrollbar or Vertical.TScrollbar, depending on the orient option.
| Separator | TSeparator
| Sizegrip | TSizegrip
| Treeview | Treeview (not TTreview!)

运行时可以调用控件的 `.winfo_class()` 方法获得当前使用的 style 类名：

    >>> b=ttk.Button(None)
    >>> b.winfo_class()
    'TButton'
    
style 类名有两种格式：

1. 对应内置的 sytle 都是一个单词，例如 'TButton' 或者 'TFrame'
2. 在内置 style 之上新建的 style 采用这样的格式： 'newName.oldName' ，例如为输入日期的 Entry 控件新建一个 style 可以命名为 'Date.TEntry' 

每个 style 都定义了一套相应的属性，例如按钮有一个 foreground 属性用于设置按钮上文字的颜色。可以调用 `ttk.Style()` 类的 `.configure()` 方法调节这些属性，第一个参数是 style 类名，之后是要修改的属性和相应的值，例如把按钮上的文字改成绿色：

    s.configure('TButton', foreground='green')

这个方法还可以用来新建 style ，第一个参数定义新 style 类的名称 'newName.oldName' ，例如新建一个 Style ，按钮上的文字是红褐色：

    s = ttk.Style()
    s.configure('Kim.TButton', foreground='maroon')

然后就可以用这个新的 style 新建一个按钮：

    self.b = ttk.Button(self, text='Friday', style='Kim.TButton',command=self._fridayHandler)

你甚至可以构建一套多级 style 。例如新建一个名叫 'Panic.Kim.TButton' 的 style ，它会继承 'Kim.TButton' 的所有属性，ttk 要使用某个属性时，首先在 'Panic.Kim.TButton' 寻找，如果没找到，会上溯到 'Kim.TButton' ，如果还找不到，再上溯到 'TButton' 中寻找。

还存在一个 root style 叫做 '.' ，配置这个 style 的某个属性会对所有控件生效。假设我们想要所有的文本都使用  12-point Helvetica 字体，可以这样配置：

    s = ttk.Style()
    s.configure('.', font=('Helvetica', 12))

### 11.3. element

一个控件是由多种 element 组成的，控件就像一个“空腔”，腔体内的空间由 element 填充。以 classic theme 为例，一个按钮拥有四个同心 element ，从外都内分别是 focus highlight ， border ， padding 和 label 。每个 element 都有一个 'sticky' 属性，它的作用是告诉这个 element 如何填充当前的腔体，如果一个 element 的 sticky='ew' ，意味着这个 element 应该左右方向撑开，紧贴腔体左右边。

大部分内置的 style 使用 layout 概念来组织腔体内的 element ，要获取某个 style 内的 element 显示方式，可以调用 `.layout()` 方法：
    
    S.layout(styleName)

该函数返回一个列表，列表内的元素都是描述 element 显示方式的元组，元组的格式是 (eltName, d) ，eltName 是一个字符串， element 的名称，d 是一个字典，描述 element 显示方式的一些属性，比如：

* 'sticky' ，属性取值是一个字符串，描述当前 element 在相对父 element 的位置，可以为空，或者有 'n' ， 's' ， 'e' 和 'w' 四个字符组成，分别代表四个方式的对齐方式
* 'side' ，如果当前 element 拥有多个子 element ，该属性的取值定义了这些子 element 的对齐方式，可选 'left' ， 'right' ， 'top' 或者 'bottom'
* 'children' ，如果当前 element 下还有子 element ，可以使用相同格式的列表描述

下面以 classic theme 的按钮控件为例分析它的 Layout：

    >>> from tkinter import ttk
    >>> s = ttk.Style()
    >>> s.theme_use('classic')
    >>> b = ttk.Button(None,text="Yo")
    >>> bClass = b.winfo_class()
    >>> bClass
    'TButton'
    >>> layout = s.layout('TButton')
    >>> layout
    [('Button.highlight', {'sticky': 'nswe', 'children': [('Button.border', {'sticky': 'nswe', 'border': '1', 'children': [('Button.padding', {'sticky': 'nswe', 'children': [('Button.label', {'sticky': 'nswe'})]})]})]})]

这里我们新建了一个按钮，但是没有显示出来，要让它在窗口显示需要调用 `.grid()` 方法。Button 控件的 style 是 TButton ，它的 element 分为四层：

    [('Button.highlight', {'sticky': 'nswe', 'children': 
        [('Button.border', {'sticky': 'nswe', 'border': '1', 'children': 
            [('Button.padding', {'sticky': 'nswe', 'children': 
                [('Button.label', {'sticky': 'nswe'})]}
            )]}
        )]}
    )]

有外到内：

1. 最外层是 highlight ，sticky='nswe' 表示四个方向都撑满
2. 第二层是 border ，它有一个 border='1' 的属性，表示边框宽度一个像素
3. 第三层是 padding ，表示内边距，默认是 0 
4. 最里面是 label ，显示按钮上的文字或者图片，也是四个方向撑满

每个 element 都由一个字典描述各自的属性，这些属性的名字都是沿用自 Tkinter ，都可以用 `s.configure()` 方法配置。要获取这些属性的名字可以调用：

    S.element_options(elementName)

函数返回一个列表：

    >>> d = s.element_options('Button.highlight')
    >>> d
    ('highlightcolor', 'highlightthickness')

要找出某个属性的值可以调用：

    s.lookup(layoutName, optName)

继续前面的例子：

    >>> s.lookup('Button.highlight', 'highlightthickness')
    1
    >>> s.lookup('Button.highlight', 'highlightcolor')
    '#d9d9d9'
    >>> s.element_options('Button.label')
    ('compound', 'space', 'text', 'font', 'foreground', 'underline', 'width', 'anchor', 'justify', 'wraplength', 'embossed', 'image', 'stipple', 'background')
    >>> s.lookup('Button.label', 'foreground')
    'black'


## 12. ttk 的通用方法

* w.cget(option) ，返回某个属性的值
* w.configure(option=value, ...) ，设置某个属性的值，如果没有参数，它会返回一个字典，记录了该控件所有属性，属性的值保持在一个元组，格式 (name, dbName, dbClass, default, current)，例如：
    
        >>> from tkinter import ttk
        >>> b=ttk.Button(text="Yo")
        >>> b.configure()
        {'takefocus': ('takefocus', 'takeFocus', 'TakeFocus', '', 'ttk::takefocus'), 'command': ('command', 'command', 'Command', '', ''), 'default': ('default', 'default', 'Default', <index object: 'normal'>, <index object: 'normal'>), 'text': ('text', 'text', 'Text', '', 'Yo'), 'textvariable': ('textvariable', 'textVariable', 'Variable', '', ''), 'underline': ('underline', 'underline', 'Underline', -1, -1), 'width': ('width', 'width', 'Width', '', ''), 'image': ('image', 'image', 'Image', '', ''), 'compound': ('compound', 'compound', 'Compound', <index object: 'none'>, <index object: 'none'>), 'padding': ('padding', 'padding', 'Pad', '', ''), 'state': ('state', 'state', 'State', <index object: 'normal'>, <index object: 'normal'>), 'cursor': ('cursor', 'cursor', 'Cursor', '', ''), 'style': ('style', 'style', 'Style', '', ''), 'class': ('class', '', '', '', '')}
* .state(stateSpec=None) ，获取、设置或者清空当前的状态

## 13. ttk 的控件状态

ttk 的控件有一套 state flags，用于指示控件的状态，这些状态都可以编程打开或者关闭，下表是各种状态的含义：

| state | 描述
| --- | ---
| active | 鼠标指针正处于控件内
| alternate | 该状态为应用程序保留
| background | Under Windows or MacOS, the widget is located in a window that is not the foreground window.
| disabled | 禁用控件
| focus | 控件处于聚焦状态
| invalid | 控件的内容无效
| pressed | 控件被按下
| readonly | 只读
| selected | 控件被选中

很多方法都通过一个 stateSpec 参数来访问 state 。这个参数可以是以下的值：

* A single state name such as 'pressed'. A ttk.Button widget is in this state, for example, when the mouse cursor is over the button and mouse button 1 is down.
* A single state name preceded with an exclamation point (!); this matches the widget state only when that state is off. For example, a stateSpec argument '!pressed' specifies a widget that is not currently being pressed.
* A sequence of state names, or state names preceded by an '!'. Such a stateSpec matches only when all of its components match. For example, a stateSpec value of ('!disabled', 'focus') matches a widget only when that widget is not disabled and it has focus.

## 14. 模块化编程

前面我们都是在主程序里，用函数一步步新建控件，绘制界面，如果界面很复杂，这种方式就变的非常麻烦，结构也不清晰，难以维护。一个好的编程方法应该模块化的，按界面的布局划分不同的模块，实现不同的类，每个类里集成了模块上的所有控件，实现对控件的操作方法，然后这个模块就可以新建不同的实例，放在不同的位置。通常用户新建的类可以从 tk.Frame 继承，下面是简单的例子：

    import tkinter as tk
    from tkinter import ttk 
    
    class application(ttk.Frame):     #新建 application 类，继承了 ttk.Frame
        def __init__(self, parent=None):    #初始化函数，根据模块所处的位置设置父类，默认为空
            ttk.Frame.__init__(self, parent)
            self.grid()    #显示这个模块
            self._createWidgets()   #新建模块上的控件
        def _createWidgets(self):
            self.button = ttk.Button(self, text='Quit', command=self.quit)
            self.button.grid()
    
    window = tk.Tk()    #新建一个窗口
    window.title('Sample application')
    app = application(window)  #在窗口上放一个 application 模块
    window.mainloop()

## 参考

* [Tkinter 8.5 reference: a GUI for Python](http://infohost.nmt.edu/tcc/help/pubs/tkinter/web/index.html)
* [TkDocs](http://www.tkdocs.com/tutorial/index.html)
* [pyinstaller Docs](https://pyinstaller.readthedocs.io/en/stable/)

