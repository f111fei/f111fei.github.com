title: 从2048游戏谈PureMVC
categories: 框架
date: 2014-04-27 02:03:56
tags:
---

最近2048比较火，然后我又正好在学习pureMVC，之前对于pureMVC的了解只停留在理论上，正好拿这个游戏来练练手。废话不多说，游戏预览：[2048](http://xzper.qiniudn.com/2014/04/2048flexlite/Main.html)

<!--more-->

**1.MVC的基本运行原理**

![mvc结构图](http://xzper.qiniudn.com/2014/04/mvc结构图.png)

<span style="font-family: 微软雅黑;"><span>图：</span></span><span><span style="font-family: Calibri;">MVC</span><span style="font-family: 微软雅黑;">结构图（实线——&gt;表示依赖；虚线</span><span style="font-family: Calibri;">----&gt;</span><span style="font-family: 微软雅黑;">表示事件</span><span style="font-family: Calibri;">/</span></span><span style="font-family: 微软雅黑;"><span>通知等</span><span>）</span></span>

*   **模型（Model）** 用于封装与应用程序的业务逻辑相关的数据以及对数据的处理方法。“模型”有对数据直接访问的权力，例如对数据库的访问。“模型”不依赖“视图”和“控制器”，也就是说，模型不关心它会被如何显示或是如何被操作。但是模型中数据的变化一般会通过一种刷新机制被公布。为了实现这种机制，那些用于监视此模型的视图必须事先在此模型上注册，从而，视图可以了解在数据模型上发生的改变。（比较：[观察者模式](http://zh.wikipedia.org/wiki/%E8%A7%82%E5%AF%9F%E8%80%85%E6%A8%A1%E5%BC%8F "观察者模式")（[软件设计模式](http://zh.wikipedia.org/wiki/%E8%BD%AF%E4%BB%B6%E8%AE%BE%E8%AE%A1%E6%A8%A1%E5%BC%8F "软件设计模式")））

*   **视图(View)** 能够实现数据有目的的显示（理论上，这不是必需的）。在视图中一般没有程序上的逻辑。为了实现视图上的刷新功能，视图需要访问它监视的数据模型（Model），因此应该事先在被它监视的数据那里注册。

*   **控制器(Controller)** 起到不同层面间的组织作用，用于控制应用程序的流程。它处理事件并作出响应。“事件”包括用户的行为和数据模型上的改变。

**2.pureMVC中的Proxy,Mediator,Command**

*   **Proxy数据层(Model)** 由于数据不关心视图是如何显示的，所以如果数据改变了引起了视图的改变，为了做到解耦，Proxy通过sendNotification方法向视图(Mediator)或者控制器(Command)发送通知，而不是获取视图实例调用里面的方法，通知发出去了Proxy的任务就完成了。另外Proxy通常还提供一些公共方法(public function)供控制器(Command)直接调用，从而改变数据（**注意：Proxy是不接收Notification的**）。
*   **Mediator视图层(View)** 中介器(Mediator)持有对应视图的引用，他负责接收消息和发送消息，所以一般情况下Mediator只含有处理消息和发送消息的代码，不会有复杂的逻辑处理，逻辑处理放在视图组件(viewComponent)里面（**注意：如果你的Mediator含有过多的公共方法不用想肯定有问题** ）。当数据改变，Mediator收到消息时，调用viewComponent暴露的公共方法，处理视图的改变。另外，Mediator可以为视图组件添加事件监听器(addEventListener),发送消息(sendNotification)通知控制器(Command)视图的改变，而不是直接调用Proxy的公共方法改变数据。
*   **Command控制器(Controller)** 这个的使用比较灵活。最常用的就是收到Mediator发来的消息，调用Proxy的公共方法改变数据。还有可能是收到某一个Proxy的消息，调用另外一个Proxy改变数据等等。他起到了一个桥梁的作用。协调Mediator和Proxy，Proxy1和Proxy2，Mediator1和Mediator2。所以Command也不应该有复杂的逻辑。

**3.从实例学习pureMVC**

先来看下工程目录结构

![2048工程结构](http://xzper.qiniudn.com/2014/04/2048工程结构.png)

**1.xxxPrepCommand** 框架初始化时，注册对应必须的Command和Proxy。（另外说下由于FlexLite的组件需要在CreateComplete才能获取皮肤实例，所以Mediator的注册都是在viewComponent中完成的）

**2.GameCommand** 处理各类事务。比如 玩家按下了方向键，收到消息调用GridProxy的移动方法改变数据，比如GridProxy移动格子分数改变了，通知GameCommand 调用GameProxy的更新分数方法改变分数，比如处理重置游戏的事务，通知各个数据模块重置数据

**3.GameProxy** 处理游戏数据，比如更新分数，处理游戏结果

**4.GridProxy** 这个游戏的核心数据，操作每一个格子的数据，通知视图格子的移动，添加，删除，重置

**5.ApplicationMediator** 监听键盘事件发送消息到GameCommand通知移动

**6.MainGameMediator** 接收消息，调用MainGameUI的方法处理格子的移动，添加，删除，重置，以及接收游戏结果，显示结果面板

**7.****MainMenuMediator** 接收更新分数的消息，调用MainGameUI的方法更新分数与重置

**8.ResultWindowMediator** 发送游戏重置的消息，以及自销毁。这是一个短生命的Mediator

其实这个游戏本来一开始我是用Flex开发的，最后完成的时候发现swf太大加载太慢，于是换成了比较小巧的FlexLite。整个移植过程没有动Model和Controller的一行代码，Mediator改动的也很少。充分说明了MVC的代码重用和关注点分离。这也是我用pureMVC的初次尝试，可能理解还有很多不到位和错误的地方，在此抛砖引玉。最后附上源代码下载：

FlexLite版：[2048flexlite](http://xzper.qiniudn.com/2014/04/2048flexlite.rar)

Flex版：[2048flex](http://xzper.qiniudn.com/2014/04/2048flex.rar)

参考文章：

[1] [http://www.cnblogs.com/skynet/archive/2012/12/29/2838303.html](http://www.cnblogs.com/skynet/archive/2012/12/29/2838303.html)