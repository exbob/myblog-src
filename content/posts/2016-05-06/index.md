---
title: Start Developing iOS Apps (Swift)
date: 2016-05-06T08:00:00+08:00
draft: false
toc:
comments: true
---


原文：[Start Developing iOS Apps (Swift)](https://developer.apple.com/library/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/index.html)

Translated by Bob

2016-05-06

Blog：<http://shaocheng.li>

---


## 1. Get Start

### 1.1. Jump Right In

这是一个很好的 iPad/iPhone App 开发入门文档。这一系列课程可以逐步指导你写出第一个 App ，包括工具的使用、主要概念和实践。

每一节课都包含一个教程和你需要了解的概念。带领你一步一步创建一个简单的可运行 iOS App 。

在构建 APP 的过程中，你会学习到 iOS App 开发中所需的概念，更深入的理解 Swift 语言，了解到 Xcode 很多有用的特性。 

####About The Lessons

在这些课程中，你将构建一个名叫 FoodTracker 的 App 。App 中会显示一份美食列表，包含美食的名称、评价和图片。用户可以添加一个新的美食、删除或者编辑已经存在的美食。添加或者编辑时，会进入一个新的页面，那里可以填写美食的名称、评价和图片。

![](./pics_1.jpg)

第一节课是 playground ，playground 是 Xcode 的一种文件，可以让你在编辑代码的同时，立即看到代码执行的结果。其余的课程都是 Xcode project 文件。每节课的结尾提供下载，你可以下载后检查。

####Get the Tools

要开发本课程中的 iOS App ，需要一个 Mac 电脑(OSX 10.10 以上版本），运行最新的 Xcode ，Xcode 包含了设计、开发和调试 iOS App 所需的所有特性。 Xcode 还包含 iOS SDK ，它提供了 iOS 开发中所需的工具、编译器和框架。

本课程使用 Xcode 7.0 和 iOS SDK 9.0 。

### 1.2. Learn the Essentials of Swift

####Swift Language

[The Swift Programming Language 中文版](http://wiki.jikexueyuan.com/project/swift/)

####Swift and Cocoa Touch

Cocoa Touch 是开发 iOS App 的框架，Swift 可以与之无缝连接。本节课将帮助你了解怎样在 Swift 语言中使用 Cocoa Touch 。 

目前为止，你用到的都是来自 Swift 标准库的数据类型，例如 String 和 Array ：
    
    let sampleString: String = "hello"
    let sampleArray: Array = [1, 2, 3.1415, 23, 42]
    
>在 Xcode 中，按住 Option 键单击数据类型。

要开发 iOS App，只有标准库是不够的。最常用的 iOS App 开发框架是 UIKit 。UIKit 包含了大量有用的 UI 类。

要访问 UIKit ，先导入模块：

    import UIKit 

之后就可以用 Swift 语法调用 UIKit 的类型和方法：

    let redSquare = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
    redSquare.backgroundColor = UIColor.redColor()

你会在后面的章节遇到很多 UIKit 的类。

## 2. Building the UI

### 2.1. Build a Basic UI

本节课带你熟悉 Xcode 。你将熟悉 Xcode 项目的结构，并学习如何使用基本的项目控件。通过这节课，你要为 FoodTracker 制作一个简单的 UI ，就像下面这样：

![](./pics_2.jpg)

####Learning Objectives

这节课的学习目标是：

* 在 Xcode 中新建一个项目。
* 熟悉项目模板中主要文件的功能。
* 在 Xcode 中打开文件，并在各个文件之间切换。
* 在模拟器中运行 App 。
* 添加、移动 UI 元素，改变元素的尺寸。
* 编辑 UI 元素的属性。
* 用缩略图查看和重新布置 UI 元素。
* 预览 UI 界面。
* 更加用户设备的大小自动布局 UI 。

####Create a New Project

Xcode 包含若干内建的 App 模板，支持常用的集中 iOS App ，例如 Game、Single View Application 。这些模板大部分已经配置好了界面和源码文件，本节课就是从最基础的 Single View Application 模板开始。

1. 打开 Xcode ，欢迎界面如下：

    ![](~/15-22-28.jpg)

    如果没有出现欢迎界面，而是直接打开了项目窗口，不要紧张，可能之前已经创建或打开过一个项目，直接到一下步，通过菜单栏新建项目即可。

2. 在欢迎界面点击“Create a new Xcode project”，或者在菜单中选择 File > New > Project 。Xcode 会打开一个新窗口供你选择模板。

3. 在左边对话框中的 iOS 标签下选择 Application 。

4. 在主对话框中选择 Single View Application ，然后点击 Next 。

    ![](~/16-37-24.jpg)
5. 在新出现的对话框中，设置 App 的名称和其他选项：
    * Product Name: FoodTracker 。App 的名称。
    * Organization Name: 公司或组织的名称，可以不填。
    * Organization Identifier: 公司或组织的标识码，可以不填。
    * Bundle Identifier: 该项是根据前两项的内容自动生成的。
    * Language: Swift
    * Devices: Universal 。Universal 表示该 App 可以同时运行在 iPhone 和 iPad 。
    * Use Core Data: Unselected.
    * Include Unit Tests: Selected.
    * Include UI Tests: Unselected.

    ![](~/16-46-23.jpg)
    
6. 点击 Next 。

7. 在出现的对话框中，选择项目保存的位置，点击 Create 。Xcode 会在 workspace 窗口打开新建的项目。

    ![](~/21-27-11.jpg)
    在 wrokspace 窗口，有可能看到一条警告信息 “No code signing identities found” ，意思你还没有用 Xcode 做过 iOS 开放，不要紧，这节课后，这条警告就会消失。
    
####Get Familiar with Xcode

Xcode 拥有开放 App 所需的一切。它不仅组织了所有的项目文件，还提供了代码编辑器和 UI 控件，允许你创建和允许 App ，还提供了一个功能强大的调试器。

花一点时间熟悉一下 Xcode workspace 的主界面。界面中的这些区域在接下来的课程中都会用到。不必完全掌握，在后面的课程中遇到时，会有详细讲解。

![](./pics_3.jpg)

####Run Simulator

由于是基于模板新建的项目，基本的 App 环境以及自动生成了。即使你不写任何代码，也可以直接运行这个 Single View Application 模板。

可以用 Simulator （模拟器）来运行 App ，它可以让你预览 App 运行在设备上的样子和行为交互。

Simulator 可以模拟多种设备，例如各种尺寸的 iPhone、iPad 。本节课使用 iPhone 6 。

1. 在最上层 Toolbar 中的 Scheme 菜单中选择 iPhone 6 。Scheme 菜单用于设置 App 运行的设备。

    ![](~/22-43-30.jpg)

2. 点击左上角的 Run 按钮。
    
    ![](~/22-44-55.jpg)
    
    也可以选择 Product > Run ，或者直接按 Command-R 。
    
    如果是第一次运行 App ，Xcode 会询问你是否要打开 Mac 电脑的开发模式。开发模式下会允许 Xcode 访问 debug 特性时不用每次都输入密码。点击 Enable 。
    
    ![](~/22-49-47.jpg)
    
    如果你选择了 Don't Enable ，后面就要按提示输入密码。
    
3. 观察 Toolbar ，等待构建过程结束。Xcode 会在 Activity viewer 中显示构建过程的信息。

构建完成后，Simulator 会自动运行。第一次需要花一点时间。

Simulator 在 iPhone 6 模式下打开，然后在模拟出的 iPhone 中启动你的 App 。启动的过程中，会看到 App 的名字。

![](./pics_4.jpg)

然后，就会看到：

![](./pics_5.jpg)

现在，这个模板还没有任何内容，只显示一个空白界面。其他的模板会有更复杂的特性。理解各种模板的用途，对开发 App 是很重要的。

快速启动 Simulator 可以选择 Simulator > Quit Simulator ，或者按 Command-Q 。

####Review the Source Code

Single View Application 模板来自于几个源码文件，它们设置了 App 的环境。首先看一下 AppDelegate.swift 文件。

1. 在 navigator area 中打开 project navigator 。

    project navigator 显示了该项目的所有文件。如果你的 project navigator 没有打开，在 navigator selector 中点击最左的按钮，或者选择 View > Navigators > Show Project Navigator 。
    
    ![](~/23-13-49.jpg)
    
2. 点击 project navigator 中左边的倒三角可以展开所有文件。

3. 选择 AppDelegate.swift 。Xcode 会在 Editor area 中打开源码文件。

    ![](~/23-18-18.jpg)
    
    或者双击 AppDelegate.swift ，在一个独立的窗口中打开。
    
AppDelegate.swift 文件有两个主要的功能：
    
* 为 App 提供入口，并运行了一个传递输入事件的循环。这项工作是由 UIApplicationMain 属性(@UIApplicationMain)完成的， 它位于文件开头处. UIApplicationMain 新建了一个 application 对象，它负责管理 App 的整个生命周期和 app delegate 对象。
* 定义 AppDelegate 类, 它是 app delegate 对象的类型。 app delegate 创建了 App 的窗口，提供了一个响应 App 状态转换的地方。你可以在 AppDelegate 类中写一些自定义的代码。
    
AppDelegate 类只包含一个属性：window ，app delegate 用这个属性跟踪 App 的窗口。window 是可选类型（optional），所有它可能没有值（nil）。

    var window: UIWindow?
    
AppDelegate 类还包含了几个重要的方法，这些方法用于 application 对象与 app delegate 进行对话。

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    func applicationWillResignActive(application: UIApplication)
    func applicationDidEnterBackground(application: UIApplication)
    func applicationWillEnterForeground(application: UIApplication)
    func applicationDidBecomeActive(application: UIApplication)
    func applicationWillTerminate(application: UIApplication)
    
当 App 的状态发生变化时——例如启动、转入后台、退出—— application 对象就会调用 AppDelegate 中相应的方法做出回应。无需专门判断这些方法是否被调用，application 对象会帮你完成这个工作。

这些方法模板都是空实现，可以在里面添加自定义的代码，当它们被调用时就会执行。这节课不会用到自定义的 appdelegate 代码，所有不用修改 AppDelegate.swift 文件。

Single View Application 模板还有一个源文件 ViewController.swift 。在项目导航器中选择 ViewController.swift 查看文件内容。

![](./pics_6.jpg)

这个文件中定义了一个 UIViewController 的子类 ViewController 。这个类继承了 UIViewController 的所有行为。要覆盖或者扩展这些行为，需要重写 UIViewController 中定义的方法（例如 ViewController.swift 中重写了 viewDidLoad() 和 didReceiveMemoryWarning() 方法），或者自定义新的方法。

虽然模板自带了 didReceiveMemoryWarning() 方法，这节课并不会用到，所有删掉它。

现在，你的 ViewController.swift 文件变成了：

    import UIKit
     
    class ViewController: UIViewController {
        
        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view, typically from a nib.
        }    
    }

稍后会在这个文件中写你自己的代码。

####Open Your Storyboard

现在可以在 storyboard 上工作了。Storyboard 是 App 界面的虚拟表现，它展示了 App 屏幕上显示的内容和内容之间的交互关系。我们用 storyboard 设计 App 的界面和交互流程。你可以在设计过程中清楚的看到 App 的样子和交互关系，并且可以随时做出做出所见即所得的修改。

在项目导航器中选择 Main.storyboard ，Xcode 就会在 Interface Builder 中打开 storyboard 。storyboard 的背景是空白的，可以在上面添加布置各种 UI 元素。

![](./pics_7.jpg)

现在这个 storyboard 上包含了一个场景，相当于你的 App 显示在手机屏幕上的样子。场景左边的那个箭头叫做 storyboard entry point ，表示这个场景是 App 启动时第一个加载的。现在这个场景只有一个界面，由 view controller 管理。你会学到更多关于 view 和 view controller 的使用规则。

当你在 iPhone 6 模拟器上运行这个 App 时，这个场景上的界面就是最终在设备屏幕上看到的样子。但是会发现，这个场景的大小形状与 iPhone 6 的屏幕尺寸并不匹配。这是因为，这个场景是对于所有可支持设备的一般化表示，最终运行在具体设备上时，会自动调整到合适的尺寸。

####Build the Basic UI

现在可以开始构建基本的界面，做一个添加新菜的功能。

Xcode 提供了一个库，包含了按钮、文本框等可以添加到界面上的元素，还有一些不会显示出来的、定义 App 行为的元素，例如 view controller 和手势识别。

出现在 UI 上元素被称作 view 。它们为用户呈现 App 的内容。view 还有多种內建的行为，包括在屏幕上显示自身，对用户输入做出反应。

iOS 中的 View 对象的类型都是 UIView 或它的子类。很多 UIView 子类都有自己独特的显示方式和行为。现在，我们在场景中添加一个文本域，它属于 UITextField 类。一个文本域允许用户输入一行文本，这里用它来输入一道菜的名字。

1. 打开对象库（Object library）。

    打开对象库的按钮位于右边的 utility area 。如果没有看到对象库，单击它的按钮，库选择条的左起第三个按钮。（或者在菜单中选择 View > Utilities > Show Object Library)
    
    ![](~/19-18-34.jpg)
    
    会出现一个列表，列出了每个对象的名字、描述、图标。

2. 在对象库的 Filter field 中输入 text field 就可以找到它。
3. 将 text field 对象拖到场景中。

    ![](~/19-23-09.jpg)
    
    可以在  Editor > Canvas > Zoom 中选择放大或缩小场景。
    
4. 把 text field 拖到场景上半部分，左边线对齐的位置。如图：

    ![](~/19-28-29.jpg)

    蓝色的对齐线会帮助你定位。对齐线只有在拖动或改变对象大小是才能看到；当你放开对象时它就消失了。
    
5. 如果有必要，单击 text field ，激活 resize handle。

    Resize handle 是出现在 UI 元素四周的白色小方框，拖动它可以改变元素的大小。通过单击元素可以该元素的 resize handle 。如下图这样，已经单击选中的元素可以改变大小。
    
    ![](~/20-15-02.jpg)

6. 改变 text field 左右边框的位置，直到出现三条对齐线：左边对齐线、水平方向中心对齐线、右边对齐线。

    ![](~/20-20-39.jpg)

尽管场景上已经有了文本域，但是没有 help 信息告诉用户这里应该填什么。用 Text field 的 Placeholder 告诉用户在这里填入菜名。

1. 在 utility area 中打开 Text field 的属性检查器（Attributes inspector），在这里可以编辑 storyboard 中对象的属性。

    ![](~/20-28-12.jpg)
    
2. 找到 Placeholder ，输入 Enter meal name 。
3. 按回车键就可以在文本域中看到刚才输入的文本。

现在的界面是这样的：

![](./pics_8.jpg)

当用户选中文本域时会显示系统键盘，这里要配置一下系统键盘的属性，

1. 选中文本域。
2. 在属性检查器中找到 Return Key 并选择 Done 。这个设置会将键盘的 Return 键改为 Done 键。
3. 在属性检查器中勾选 Auto-enable Return Key 。这样的话，如果文本域中没有输入文本，用户是无法点击 Done 键的，这样可以确保用户不能设置空的菜名。

下一步，在场景顶部添加一个标签（UILabel）。标签没有交互，只能显示一段静态文本。为了帮助你理解怎样定义 UI 上元素之间的交互，你要配置这个标签，让它显示用户在文本域中输入的文字。这样可以练习如何获取并处理文本域中的输入信息。

1. 在对象库中输入 lable ，快速找到 Label 对象。
2. 把 Label 对象拖到场景中。
3. 把标签拖到文本域的左上方位置，左对齐，如图：

    ![](~/22-28-54.jpg)
4. 双击标签，输入 Meal Name 。
5. 按回车键，新文本就会显示在标签中。

场景变成了这个样子：

![](./pics_9.jpg)

现在，添加一个按钮（UIButton）。按钮是可交互的，所有，用户可以点击，然后触发定义好的事件。这里我们创建一个重置标签文本的事件。

1. 在对象库里输入 button 查找 Button 对象。
2. 把 Button 拖到场景中。
3. 将按钮拖到文本域的下方，左对齐，如图：

    ![](~/23-56-51.jpg)

4. 双击按钮，输入 Set Default Label Text 。
5. 按回车显示新文本。

此时，你的场景变成了这样：

    ![](~/23-59-04.jpg)

在 Outline view 中可以看到已经添加到场景中的所有元素，帮助你理解这些元素是如何在场景中布置的。

1. 在 storyboard 中找到 Outline view 按钮：
    
    ![](~/00-07-24.jpg)
2. 如果没有看到 Outline view ，请单击左下的 Outline view toggle 。 该按钮可以显示或隐藏 Outline view 。

Outline view 可以让你看清 storyboard 中给个对象的层次关系。在这个等级结构中可看到文本域、标签、按钮。为什么你添加的这些元素都位于 View 下，而不是其他的 view ？

view 不只是显示自己和接受用户输入，它们还可以作为其他 view 的容器。排列在这个等级结构中的 view 称作 view hierarchy 。它定义了 views 之间的布局关系。一个 view 里面的其他 views 叫做 subviews ，它的上一层 view 叫做 superview 。一个 view 可以有多个 subview ，但只能有一个 superview 。

![](./pics_10.jpg)

通常，每个场景都有自己的 view hierarchy 。每个 view hierarchy 的顶部是一个 content view 。现在这个场景中，content view 就是 View 。你在这个场景中添加的 view 都将是 View 的 subview 。

####Preview Your Interface

定期预览你的 App ，检查一下设计结果是否符合预期。用 assistant editor 可以在主编辑器傍边显示一个子编辑器，可以在这里预览 App 的用户界面。

1. 点击右上角的 Assistant 按钮打开 assistant editor 。

    ![](~/12-51-37.jpg)

2. 如果想要更多的工作空间，可以在右上角的工具条中隐藏 Navigator 和 Utilities ，还可以隐藏 outline view 。


    ![](~/12-55-37.jpg)
    
3. 在 assistant editor 顶部的选择器中选择 Automatic > Preview > Main.storyboard(Preview) 。

    ![](~/13-27-47.jpg)
    
    在预览中可以看到，文本域的右边没有完全显示，超出了有边框。这是为什么？
    
    ![](~/14-11-42.jpg)

我们构建的是一个可以适应各种尺寸 iPhone 和 iPad 的界面。在 storyboard 中看到的是界面大概的样子。现在，需要设置这个界面上的元素在不同大小的屏幕上该如何调整。例如，当界面缩小到 iPhone 大小时，文本域也要相应的缩小。当界面放大道 iPad 大小时，文本域也要放大。可以用 Auto Layout 设置这些行为。

####Adopt Auto Layout

Auto Layout 是一个强大的布局引擎，可以帮助你轻松的设计兼容布局。你只需要告诉 Auto Layout 想要如何摆放场景中的元素，引擎就会自动以最优的方式实现你的意图。描述你的意图要用到 constraints ，使用它来描述元素的相对位置，元素的大小，元素之间的缩放关系。

配合 Auto Layout 工作的工具是 stack view（UIStackView）。stack view 提供了一个高效的方式在水平或垂直方向排布多个元素。Stack view 让你借助 Auto Layout 的力量，创建可以适应设备方向、屏幕大小、或各种空间变化的 UI 。

可以轻松的将已经存在的 UI 元素包含到一个 stack view ，然后设定必要的限制，使得 stack view 在各种情况下都能正确的显示。

1. 点击右上角的 Standard 按钮回到主编辑器。

    ![](~/15-14-35.jpg)
    
2. 按住 Shift 键，同时选中文本域、标签和按钮。

    ![](~/15-15-43.jpg)

3. 在画布的右下角选择 Stack 按钮。（或者选择 Editor > Embed In > Stack View)

    ![](~/15-17-38.jpg)
    
    Xcode 会将这些 UI 元素包含到一个 stack view 中。Xcode 会分析现在的布局，计算出这些元素应该沿垂直方向叠放。
    
    ![](~/15-20-15.jpg)

4. 如果有必要，打开 Outline view ，选择 Stack View 对象。

    ![](~/15-23-53.jpg)

5. 在属性检查器的 spacing 中输入 12 ，按回车。你会看到 UI 元素的纵向空间被拉长了。

    ![](~/22-45-06.jpg)

6. 在画布右下角打开 Pin 菜单。

    ![](~/22-59-18.jpg)

7. 在 “Spacing to nearest neighbor” 上方，点击选中两个横向限制和纵向顶部限制。选中后会变成红色。

    ![](~/23-05-20.jpg)
    
    这些限制表示当前的 stack view 与周边 view 的边缘的距离。选中了 “Constrain to margins”，表示这些距离限制是相对于 margins 的，margins 是外边距，是 view 边缘外的一圈空白。
    
8. 在左右两个框中输入 0 ，在上面的框中输入 60 。
9. 在 Update Frames 下拉菜单中选择 Items of New Constraints 。如下图：

    ![](~/23-13-46.jpg)
10. 在 Pin 菜单中点击 Add 3 Constraints 按钮。

    ![](~/23-28-41.jpg)

界面就会变成这个样子：

![](./pics_11.jpg)

你会注意到文本域并没有扩大到场景右边缘，下面解决这个问题。

1. 在 storyboard 中选中文本域。
2. 在画布的右下角打开 Pin 菜单。

    ![](~/23-31-27.jpg)
    
3. 在 “Spacing to nearest neighbor” 上方，单击选中两个水平方向的限制，它们会变成红色。
4. 在左右两个框中输入 0 。
5. 在 Update Frames 下拉菜单中选择 Item of New Constraints ，如图：

    ![](~/23-35-30.jpg)

6. 在 Pin 菜单中点击 Add 2 Constraints 按钮。

    ![](~/23-36-14.jpg)
    
7. 选中文本域后，在 utility area 中打开 Size inspector 。你可以在这里编辑对象的大小和位置。

    ![](~/21-25-32.jpg)

8. 在 Intrinsic Size 的下拉菜单中选择 Placeholder。它位于 Size inspector 的底部，你要往下翻才能看到。文本域的大小由它的内容决定，通过定义 Intrinsic content size 来设定内容的最小数量，内容用占位符（Placeholder）填充。这时，文本域的内容只是占位符组成的字符串，但是用户输入的内容可以比占位符更长。

现在场景界面如下：

![](./pics_12.jpg)

检查时间：在模拟器中运行 App 。文本域完全不会超出屏幕边界了。你可以点击文本域内部，然后用键盘输入一些文本（可以按 Command-K 切换到软键盘）。如果旋转设备（Command-Left 或 Command-Right），或者在另一种设备上运行 App ，文本域会随着屏幕的变化而伸缩到合适的大小。注意，把屏幕横过来的时候状态栏会消失。

![](./pics_13.jpg)

如果没有得到你期望的结果，可以使用 Auto Layout 调试功能来解决问题。点击 Resolve Auto Layout Issues 图标，选择 Reset to Suggested Constraints ，Xcode 会将界面调整到一个合适的设定。或者点击 Resolve Auto Layout Issues 图标，选择 Clear Constraints，Xcode 会删除 UI 元素的所有限制，然后就可以重新设置。

![](./pics_14.jpg)

虽然没有在这个场景上做多少工作，但是已经有两基本的 UI 和功能。要确保你的布局是健壮的，并且可扩展，为后面的升级打下坚实的基础。

