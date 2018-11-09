title: 编译vscode
categories: nodejs
date: 2015-11-29 03:03:12
tags: [vscode,nodejs]
---
由于工作需要，最近开始研究vscode的源代码，这样就需要编译和调试vscode。

先从GitHub([https://github.com/Microsoft/vscode](https://github.com/Microsoft/vscode))上clone一下vscode的源代码，顺便去点个star吧。

<!--more-->

![](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/11/4.png)

看一下目录结构

- **.build** 是electron可执行文件的路径，clone出来的项目是不带这个文件夹的，需要build出来。后面会讲到。

- **.vscode** 官方人员应该是使用vscode作为的开发环境来调试和开发vscode的，所以提交了这个文件夹，里面包含了启动vscode单元测试，调试插件进程的一些配置。后面会讲解如何根据自身环境适当调整这些配置。

- **build** 编译vscode的一些自动化脚本。vscode是使用gulp来自动构建的

- **.out** 编译好的js脚本

- **scripts** 生成electron环境和npm install的脚本文件

- **src** ts源码路径

#### 1.安装依赖库

官网上面说需要安装Python v2.7 和 Visual Studio(Windows下)，其实不用也行，看下面讲解。

首先切换到vscode的项目根目录执行

	npm install -g mocha gulp
	scripts\npm install

以上步骤分别为安装gulp构建器 和 安装vscode的依赖库。安装完成后会在项目的根目录下生成node_modules文件夹。

执行此过程可能会遇到以下问题：

1. npm有可能由于网络原因被那啥了, 建议使用[淘宝的npm镜像服务](https://npm.taobao.org/ "淘宝的NPM镜像服务")，使用方法在首页。


2. node-gyp安装失败

![](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/11/5.png)

这个似乎是需要机器上有Visual Studio，这个东西的功能应该就是构建一些本机文件用的，安装失败没关系，我们可以从其他地方得到这些本机文件。

ps: 最近node-inspector老是安装不上也是因为这个的原因，有没有大神能告之解决办法。


#### 2.拷贝一些重要文件
在进行这个步骤之前你需要去官网下载一个发行版的vscode。这个以后大有用处。

之前安装依赖库的时候，node-gyp安装失败就是因为一个叫vscode-textmate模块依赖了node-gyp。如果在node_modules没有找到该模块，需要从发行版的vscode中拷贝到node_modules文件夹下。路径为

	C:\Program Files (x86)\Microsoft VS Code\resources\app\node_modules\vscode-textmate
 
请安装vscode的实际安装位置自行替换。


同理， 从安装的发行版vscode中找到node-debug， mono-debug两个插件，并拷贝到extensions目录下覆盖。

	C:\Program Files (x86)\Microsoft VS Code\resources\app\extensions\mono-debug
	C:\Program Files (x86)\Microsoft VS Code\resources\app\extensions\node-debug

这个步骤特别重要。git上的extensions目录里面这两个插件被标记成了placeholder，里面没有实际内容，插件实现是在另外的项目中。所以需要把实际的插件实现复制过来，**没有这个插件将无法使用vscode进行nodejs项目的调试**。附上这两个插件的项目地址：

	//node-debug和mono-debug插件的项目地址
	https://github.com/Microsoft/vscode-node-debug
	https://github.com/Microsoft/vscode-mono-debug

#### 3.编译源代码
这一步反倒很简单，vscode使用了gulp进行自动构建，只需要找vscode项目目录下，使用一行命令就行了。

	gulp watch

几分钟后编译完成，可能会有一个错误。

![](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/11/6.png)

要解决这个问题直接使用

	npm install run-in-terminal

安装一下这个模块就行了。

#### 4.生成electron环境

在项目根目录下执行

	scripts\code.bat

就可以生成程序的入口可执行文件并启动了。以后如果要使用调试版本的vscode，双击code.bat或者执行这个命令即可。这样启动的vscode，左上角的标题会带有
Code [OSS Build]

<a name="mklink"></a>

这个过程会下载electron的安装包，有可能会失败。不过不要紧, 下面讲解如何不使用electron 和 code.bat启动调试版本的vscode的办法。

找到vscode发行版的安装目录下的resources文件夹

	cd C:\Program Files (x86)\Microsoft VS Code\resources
	
将这个目录下的app文件夹重命名备份一下。然后创建一个链接到vscode项目目录的符号链接

	ren app app_backup
	mklink /D app D:\workSpace\vscode\vscode


`D:\workSpace\vscode\vscode` 这个目录是git clone下来的项目根目录，请自行替换。

这样运行发行版的vscode, 实际上就是运行从git上clone下来的项目里面的代码了。正常打开vscode就是调试版本的了。 我就是使用的这种符号链接的形式来偷天换日的。

