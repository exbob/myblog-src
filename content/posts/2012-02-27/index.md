---
title: X Window 架构概述
date: 2012-02-27T08:00:00+08:00
draft: false
toc:
comments: true
---


原文：

X Window System Architecture Overview HOWTO

<http://www.linuxdoc.org/HOWTO/XWindow-Overview-HOWTO/index.html>

Daniel Manrique

roadmr@entropia.com.mx

Translated By Bob

Email：<gexbob@gmail.com>

Blog：<http://shaocheng.li> 

***


修订历史

Revision 1.0.1  2001-05-22  Revised by: dm  一些语法修正，由Bill Staehle指出。

Revision 1.0    2001-05-20  Revised by: dm  初始发行。

本文档描述了X Window的架构，给出了对于X Window设计的更好理解, 包括X的组件，这些组件结合起来构成的可运行图形环境，这些组件作为窗口管理器该怎样选择，工具包和构件库，桌面环境。

***

## 1. 序言

这个文档的目的是提供一个 X-Window 系统架构的概述，希望人们更好的理解它为什么要这样设计，X 的组件是怎样组合起来形成一个可工作的图形环境，怎样选择这些组件。

我们探讨一些经常被提到的概念，如果没有相关的技术背景，这些概念可能被混淆，例如部件（widgets）和工具包（toolkits），窗口管理器（window managers）和桌面环境（desktop environments）。还提供了一些例子，展示了这些组件在日常使用的应用程序中如何相互作用。

这个文档故意写得不太偏重技术，它基于作者的经验知识，以非技术方式引入，它可以从各种意见中吸取营养，包括更深入的例子和解释，以及技术上的更正。作者欢迎所有关于这个文档的问题和意见，Email：<roadmr@entropia.com.mx> 。

<!-- more -->

## 2. 简介

回到UNIX还是新鲜事物的时代，大约是1970年，图形用户接口还是一个奇怪的东西，只被一个实验室（Xerox's PARC）使用。可是今天，任何操作系统只要想拥有竞争力，就必须有一个GUI子系统。GUI界面提供了良好的易用性。这不是UNIX所关心的，UNIX 有它的传统，某种程度来讲，多功能比易用性更好。但是，有几个原因使得 UNIX 系统需要有一个GUI。例如，UNIX 的多任务特性，在给定的时间内要运行多个程序。GUI 提供了多种控制方式，可以在同一时间在屏幕上显示多个运行的程序。所以，某些类型的信息更适合在图形界面上显示（有些甚至只能在图形界面上显示，例如pr0n和其他图形数据）。

历史上，UNIX有很多学术上的改进。一个好的例子是，70年代末加入了 BSD 网络代码，这是加州大学伯克利分校的工作成果。事实证明，X Window 系统也是一个学术项目的结果，即 MIT 的雅典娜项目，它成为了现代 UNIX（类UNIX系统）中大部分GUI子系统的基础，包括 Linux 和 BSD。

从一开始，UNIX就是一个多用户、多任务的分时操作系统。随着网络技术的加入，它还允许用户远程连接和执行任务。以前，这是通过串行终端或网络连接（telnet）完成的。

当开发UNIX下的GUI系统的时候，这些概念都被加入到了设计中。事实上，X是一个相当复杂的设计，这是经常被提到的一个缺点。可是，正因如此，它才是一个真正多功能的系统，当我们解释GUI的各个部分在UNIX下是怎样结合的时候，这些都会变的很清晰。

介绍X的架构之前，简单介绍一下它的历史，还有它是如果进入Linux系统的。

X是由雅典娜项目开发，在1984年发行。1988年，一个叫做“X Consortium ”的实体接手X，之后开始处理它的开发和发布。X规范是自由提供的，这个聪明的举动使X得到了很大程度的普及。下面介绍XFree86是什么。XFree86是我们在Linux系统上使用的X实体，XFree86也可以工作在其他操作系统上，例如BSD系列、OS/2和其他。尽管它的名字中带有86，它依然支持其他CPU架构。

## 3. X Window系统架构：概览

X被设计为客户端—服务器的架构（client-server）。应用软件作为客户端，他们通过服务器进行沟通和发布请求，当然也可以从服务器接受信息。

X server维护一个独立的显示控制器和处理来自client的请求。从这一点上来看，使用这种模式的优点是显而易见的。应用程序（client）只需要知道怎样同server沟通，而不需要关注实际图像显示设备的细节。最基本的，client会告诉server一些这样的东西：“画一条从这里到那里的线”，或者“显示一个文本字符串，使用这个字体，在屏幕的这个位置”。

这与只用图形库写应用没什么不同。但是，X模式更进一步。它不限制client和server在同处一台电脑。使用这个协议可以让client和server通过网络进行沟通，事实上，“进程间通信机制提供了可靠的字节流”。当然，更好的方法是使用TCP/IP协议。可以看到，X的模式是很强大的。一个经典的例子是，在Cray计算机上运行一个处理器密集阵应用程序，在Solaris 服务器上运行一个数据库监视器，在小型BSD邮件服务器上运行一个E-mail应用，在SGI服务器上运行一个可视化应用，然后，将以上这些都显示在我的Linux平台的屏幕上。

目前为止，我们已经看到X server是一个处理实际图形显示的东西。由于X server是运行在用户使用的实际计算机上，它的职责是处理所有与用户的交互。这包括监听鼠标和键盘。所有这些信息都要传达给client，还有对它进行响应。

X提供了一个库，称作Xlib，负责处理所有低级的client-server通信任务。很显然，client调用Xlib中的函数进行工作。

这样看来，一切都工作的很好。我们有一个server负责虚拟输出和数据输入，客户端应用程序，两者之间可以通过一种方法互相通信。假设client和server之间有一个互动，client可以让server在屏幕上分配一指定的矩形区域。作为client，我并不关心我被现实在屏幕的哪个位置，我只是告诉server“给我一个X乘以Y像素大小的区域”，然后调用函数执行类似“画一条从这里到那里的线”，“用户是否在我的屏幕范围内移动鼠标”等等。

## 4. 窗口管理器

可是，我们没有提到X server怎样处理client在屏幕现实范围内的操作（调用窗口）。显然，对于任何使用GUI的用户，对需要对“client windows”进行控制。通常情况下，你可以对窗口进行移动和排列；改变大小；最大化或最小化。那么，X server是怎样处理这些任务呢？答案是：不能。

X的设计原则之一就是“只提供机制，不提供策略”。所以，X server提供了一个操作窗口的方法（机制），并没有说怎样表现这种机制（策略）。

这些机制和策略可以归结为：有一个程序的责任是管理屏幕空间。这个程序决定了窗口的位置，为用户提供了控制窗口外观、位置和大小的机制，通常还会提供一些“装饰”，例如标题、边框和按钮，这些是我们对窗口本身的控制。这个控制窗口的程序称作“窗口管理器”。

“窗口管理器只是X的一个客户端程序——它不是X window系统的一部分，尽管它享有一些特权——所以，窗口管理器不是唯一的，而是有很多，它们提供了不同的用户与窗口的交互方式和不同的窗口布局、修饰、键盘和色调的风格。”

X的架构提供了用于窗口管理器执行这些窗口操作的方法，但确实没有提供一个窗口管理器。

另外，由于窗口管理器是一个外部元件，可以很容易的根据你的参数设定窗口，例如，你希望它看起来是什么样子，你想要它怎样执行，你想要它出现在哪里，等等。有些窗口管理器比较简单和丑陋（例如twm）；还有一些是华而不实的；还有介于两者之间的；fvwm, amiwm, icewm, windowmaker, afterstep, sawfish, kwm, 还有数不清的其他窗口管理器。每一种口味都有对应的窗口管理器。

窗口管理器是一个“meta-client”，最基本的使命是管理其他客户端程序。大部分窗口管理器会提供一些额外的设施（有些会提供很多）。 可是，有个功能是大部分窗口管理器都有的——启动应用程序的方法。有些窗口管理器会提供一个命令盒子，你可以在这里写标准命令（用于启动应用程序）。还有一些窗口管理器会提供某种类型的应用程序启动菜单。这些不是标准配置。由于X没有制度关于如何启动应用程序的策略，这项功能在客户端程序中实施。那么，通常情况下，窗口管理器所负责的这个功能（个体之间会由差异），它的唯一使命就是如果启动客户端应用程序，就像一个程序启动平台。当然，人们已经写了大量的“启动程序”的应用。

## 5. 客户端应用
下面让我们关注一些客户端程序。假设你想要从头开始写一个客户端程序，并且只用X提供的设施。你很快就会发现，Xlib是漂亮的斯巴达，想要在屏幕上放一个按钮、文本，或是为用户提供的漂亮空间（滚动条，单选框），这些事竟是令人恐怖的复杂。

幸运的是，有人为我们提供了一个库，可以解决这些控件的编程问题。这些控件通常称作“部件”（widget library ），所以，这个库称作“部件库”。我只需从库中调用一个带参数的函数就可以在屏幕上显示一个按钮。这些部件包括菜单、按钮、单选按钮、滚动条和画布。

“canvas”（画布）是一个有趣的部件，它是客户端上的一个子空间，我能在里面话一些东西。可以理解，我不能直接使用Xlib，那样会干扰部件库，这个库本身提供了在画布内画任意图像的方法。

由于部件库确实可以在屏幕上画各种元素，以及解释用户的输入动作，这个库要对每个客户端的外观和行为负责。从开发者的角度来看，部件库也有一些API（设置函数），定义了我想要用到的部件。

## 6. 部件库和工具包
原始的部件库是为雅典娜项目开发的，理所当然应该是雅典娜部件库，也被称作雅典娜部件。它非常基础，非常简陋，安装现在的标准来看，它的使用方便并不直观（例如，要移动一个滚动条或滑块，你不能拖动，你要点击右边的按钮让它向上滑，或者点击左边的按钮让它向下滑），正因如此，现在几乎没有被使用了。

像窗口管理器一样，考虑到不同的设计目的，工具包（toolkit）也有很多种。最早的工具包之一是著名的Motif，这是开发软件基金会（OSF）的Motif图像环境的一部分，由一个窗口管理器和一个匹配工具包组成。OSF的历史超出了本文档的讨论范围。Motif工具包优于雅典娜部件，在80年代和90年代初使用广泛。

这些年，Motif不是一个受欢迎的选择。它不是免费的，如果你想要一个开发许可证（即用它编译你自己的程序），你需要向OSF Motif缴费，尽管可以发布一个针对Motif的二进制连接。至少对于Linux用户来说，最知名的Motif应用可能就是Netscape Navigator/Communicator。

有一段时间，Motif是唯一正常可用的工具包。有很多软件围绕着Motif。于是人们开始开发替代品，产生了丰富的工具包，例如XForms, FLTK等等。

已经有些时间没有听到Motif了，特别是在自由软件世界。原因是：就许可、性能（Motif被普遍认为像一头猪）和功能而言已经有了更好的替代品。

有一个知名并广泛使用的工具包是Gtk，它是GIMP项目专门设计用来替代Motif的。Gtk现在非常流行，因为它相对较轻，功能丰富，可扩展，而且完全免费。GIMP的0.6发行版的更新日志里包含了“Bloatif has been zorched ”，这句话是给Motif的臃肿的遗嘱。

另一个目前很流行的工具包是Qt。直到KDE项目的出现，它才开始出名，KDE利用了Qt的所有GUI元素。当然，我们不会深入Qt的许可问题和KDE/GNOME的分离性。Gtk说来话长，因为它的历史伴随着Motif的替换而变的很有趣。Qt没什么可说的，因为它真的很流行。

最后，另一个值得一提的替代品是LessTif，这个名字是对于Motif的双关语，LessTif的目标是成为免费的，兼容Motif API的替代品。并不清楚LessTif的目标已经达到了怎样的程度，倒不如帮助那些使用Motif代码的应用，在它们想要移植到其他的工具包时，有个一个免费的替代品。

## 7. 目前为止我们所拥有的
现在，我们已经知道，X有一个client-server架构，我们的应用程序就是client。在这个client-server架构的图形系统下，有多种可选的窗口管理器，它管理着我们的屏幕空间。client是我们真正完成工作的地方，而且，可以使用不同的工具包进行客户端编程。

困境就从这里产生了。各种窗口管理器使用各自不同的方法管理客户端，它们的功能和外观各不相同。同样的，由于每个客户端使用不同的工具包，它们的外观和性能也会不同。由于没有人说作者必须用同一个工具包写应用程序，下面这种情况很可能在用户运行程序是出现，比方说，六个不同的应用，都使用不同的工具包，那么它们的外观和性能也不同。这是由于应用之间的功能不一致而造成的困境。如果你一直使用一个用雅典娜组件写的程序，你会注意到，它和用Gtk所写的程序不太一样。通过使用这些外观和体验差别很大的应用，会让你记住是一个困境。这基本上否定了一个GUI环境的优势。

从技术角度来看，使用多种不同的工具包会增加对资源的占用。现代操作系统都支持动态链接库。这意味着，如果我有两三个使用Gtk的应用程序，还有一个Gtk动态链接库，那么这几个应用程序将共享这个Gtk。这样就节省了资源。另一方面，如果我有一个Gtk应用，一个Qt应用，一些基于雅典娜的程序，一个基于Motif的程序（例如Netscape），一个使用FLTK的程序，还有其他一些使用XForms，那我就要在内存中加载六个不同的库，每个库还要有一个不同的工具包。请记住，这些工具包提供的功能基本相同。

还用另外一些问题。每一种窗口管理器的启动程序的方式是不同的。有些窗口管理器有漂亮的启动程序菜单；有些则没有，它们希望我们打开一个程序启动箱，或者使用一个组合键，要不就是打开一个xterm，然后调用命令启动你的程序。所有，困境就是因为没有一个标准。

最后，我们的计划没有覆盖到一些GUI环境的细节。例如有效的配置，或者“控制面板”；还有图形文件管理器。当然，这些可以写成客户端应用。在典型的自由软件时尚中，有数百种文件管理器，数百种系统配置程序，可以想象，处理这些不同的软件组件将是更大的困境。

## 8. 桌面环境的救赎
先说一下桌面环境的概念是怎么来的。一个桌面环境应该提供一套设施和指导，用于规范我们之前提到的所有东西，以便我们前面提到的问题最小化。

桌面环境的概念对于Linux来说是新的东西，但是这些东西在其他操作系统（例如Windows和Mac OS）中本来就存在。例如，MacOS，它是最早的图形用户接口之一，为整个计算机会话提供了一个非常一致的感观。再例如，操作系统提供了很多我们前面提到的细节：它提供了一个默认的文件管理器，一个全系统控制面板，还有一个所有应用都使用的独立工具包（所以它们看起来都差不多）。应用窗口由系统（严格的将是窗口管理器）负责管理。最后，还有一套指南告诉开发者应该怎么表现他们的应用，如何设计外观和布局，以及根据系统中的其他应用设计外观。所有这些都是为了保证应用程序的一致性和易用性。

这引出了一个问题，“为什么X的开发者没有将桌面环境的事情放在首位？”。这是有道理的；毕竟，这样就可以避免前面提到的所有问题。答案就是，在X的设计过程中，它的设计者选择将它设计得尽可能的灵活。比如说，MacOS提供了大多数机制/策略规范，但是他们不鼓励人们玩弄这些东西，结果就是失去了多功能性，如果我不喜欢MacOS管理窗口的方式，或者工具包没有提供我需要的功能，我只能怪自己倒霉。X下就不会发生这样的事，灵活的代价就是更大的复杂性。

在Linux/Unix和X下，一切都归结于统一和坚持。以KDE为例，KDE包含一个单一的窗口管理器（kwm），负责管理和控制窗口的行为。它用了一个特定的图形工具包（Qt），以至于KDE应用的控制和外观都差不多。KDE提供了一套桌面环境库，这是Qt的扩展，用来完成一些常见的编程工作，例如创建菜单、“关于”框，编写工具栏，程序间通信，打印，选择文件，等等。这使得程序员的工作更加简单，并且标准化。KDE还为程序员提供了一套设计和行为指南，如果每个人都按照指南来做，那么KDE程序的外观和操作就会很相似。最后，KDE还为桌面环境提供一些组件，一个启动器面板（kpanel），一个标准的文件管理器，还有一个配置程序（控制面板），通过它可以全方位的控制计算机环境，比如设置桌面背景和标题栏的颜色。

KDE面板相当于Windows操作系统的任务栏。在这上面可以启动应用程序，还可以在上面显示将小程序（applets）。它还提供了大多数用户都离不开的实时时钟。

## 9. 特定桌面环境
我们以KDE为例，但它不是Unix系统上最早的桌面环境。最早的可能是CDE（Common Desktop Environment），OSF的另一个兄弟。根据CDE FAQ：“Common Desktop Environment是Unix的标准桌面，为最终用户、系统管理员和应用开发者提供一贯的跨平台服务。”可是，CDE没有足够丰富的功能和易用性。除了Motif，CDE几乎在自由软件世界消失了，最终被更好的平台替代。

在Linux下，最流行的桌面环境是KDE和GNOME，但是不止这两个。在网上可以轻易的搜索到半打桌面环境：GNUStep、ROX、GTK+XFce、UDE。它们都提供前面提到的基础功能。GNOME和KDE拥有来自社区和业界的最广泛的支持，所以它们是最优秀的之一，为用户和应用程序提供大量的服务。

我们提过在KDE下有很多提供特定服务的组件。作为一个好的桌面环境，GNOME在这方面也一样。最明显的差别是GNOME并不要求使用特定的窗口管理器（这方面KDE有kwm）。GNOME一直试图做到与窗口管理器无关，但是要承认，大多数用户与他们的窗口管理器联系紧密，而强迫他们使用不同的窗口管理器会损害他们的观众。GNOME原本青睐Enlightenment窗口管理器，现在它们更喜欢用Sawfish，但是GNOME控制面板一直有一个窗口管理器选择框。

除此以外，GNOME使用Gtk工具包，并且通过gnome-lib提供了一套高级功能和工具。GNOME有它自己的一套编程方法，可以确保兼容的应用之间行为一致；它提供了一个面板，一个文件管理器（gmc）和一个控制面板（gnome控制中心）。

## 10. 怎样把它们组合到一起
每个用户都可以自由的选择感觉最好的桌面环境。最终的结果是，如果你使用纯kde或纯gnome系统，整个环境的感观就非常一致；并且应用程序之间的沟通会更好。我们不可能在一个应用程序中使用多种不同的工具包。现代Linux桌面环境提供的设备还使用了一些其他的小技术，例如组件架构（KDE有Kparts，GNOME用Bonobo），它允许你在文字处理文档中嵌入表格或图表；还有整体打印设备，就像是Windows中的印刷背景；还有脚本语言，可以让更多的高级用户编写程序将多个应用结合到一起，让它们用有趣的方式进行协作。

在Unix的桌面环境概念中，一个程序可以在多个环境中运行。我可以想象在GNOME中用Konqueror，在KDE中用Gnumeric。它们只是程序而已。当然，一个桌面环境的整体理念是一致的，所以，坚持使用那些你喜欢的环境中的应用是有道理的。但是，如果你想要处理掉一个不太合适的应用，并且不影响环境中的其他部分，你完全可以自由的去做。

## 11. X系统中的一天
下面是一个例子，在Linux系统的桌面环境中，一个典型的GNOME会话是怎样运行的。假设它们工作在X之上。

当Linux系统启动X时，X server启动并初始化图形设备，然后等待客户端的应答。首先启动gnome-sessiong，并且设置工作会话。一个会话包括我同意打开的应用，它们在屏幕上的位置，等等。然后启动面板。面板通常出现在屏幕的底部，有点像桌面环境的仪表盘。我们可以用它来启动程序，看到正在运行的程序，还可以控制工作环境。然后，窗口管理器会启动。因为我们正在使用GNOME，无法确定是哪种窗口管理器，这里假设是Sawfish。最后，文件管理器启动。文件管理器负责处理桌面图标。至此，我的GNOME环境就完全准备好了。

到目前为止，所有启动的程序都是客户端，都连接到了X server。现在我们看到的X server和client是在同一台计算机上，但是就像我们前面看到的，这不是必须的。

现在，我们可以打开一个xterm来执行一些命令。当我们点击xterm图标时，面板会启动xterm程序。它是一个X client应用，所以，当它启动时会连接X server并显示它的界面。当X server为xterm分配屏幕空间时，它会让窗口管理器（Sawfish）为窗口装饰一个漂亮的标题栏，并决定它显示的位置。

让我们用一下浏览器。点击面板上的Netscape图标，启动一个浏览器。这个浏览器可不是GNOME的设备，它用的是Gtk工具包。所以，它和桌面环境中的其它部分不是特别协调。

接着打开“File”菜单。Motif在屏幕上提供了一个控制器，所以，Motif库的工作就是适当的调用相关的Xlib，为显示菜单在屏幕上绘制必要的元素，并且让我选择“exit”选项来关闭应用。

现在我们打开一个Gnumeric电子表格。有些时候我需要用到xterm，所以我点击它。Sawfish检测到了我的动作，然后对现有的窗口做些改变，将xterm放在了最上层，并且将焦点移动到xterm上面，这样我就可以在它上面工作了。

之后，我回到电子表格，想要打印这个文档。Gnumeric是一个GNOME应用，所以它可以使用GNOME环境提供的设备。当我打印时，Gnumeric调用gnome-print库，连接打印机并且打印。

## 12. 版权和许可
Copyright (c) 2001 by Daniel Manrique 

在自由软件社区发行的GNU Free Documentation License，Version1.1或之后版本的条款下（不包含不变章节、封面文字和封底文字），授予复制、发布和修改该文档的权限。在这里可以找到许可协议的衣服拷贝。
