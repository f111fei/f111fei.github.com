title: vscode编译和调试nodejs/typescript项目
categories: nodejs
date: 2015-11-29 00:46:30
tags: [vscode,nodejs]
---
vscode是微软最新推出的使用[atom](https://github.com/atom/atom "atom")的[electron](https://github.com/atom/electron "electron")技术开发的新一代文本编辑器。

同时最近也在GitHub([https://github.com/Microsoft/vscode](https://github.com/Microsoft/vscode))上开源了。

本文简单的教大家如何使用vscode的构建和调试功能。

<!--more-->

### 构建项目
vscode使用**task.json**来配置项目的构建过程。

打开命令面板(Ctrl+Shift+P)选择Run Build Task(Ctrl+Shift+B)

![](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/11/1.png)

如果当前工作空间没有**task.json**配置文件此时会出现提示

![](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/11/2.png)

选择 Configure Task Runner 自动创建**task.json**。该配置文件在工作空间的.vscode目录下，这个目录也是存放vscode配置的文件夹。

vscode默认的task配置文件中给出了执行tsc 和 gulp模板配置。简单介绍一下**task.json**的写法

	{
		"version": "0.1.0",
	
		// 要使用的命令或者可执行文件的路径
		"command": "tsc",
	
		// 对应command参数，是否是一个命令，否则为执行文件路径
		"isShellCommand": true,
	
		// 是否在执行task任务时显示控制台窗口
		"showOutput": "always",
	
		// 对应command参数指定程序的参数
		"args": ["-p", "src", "--allowJs", "-w"],
	
		// 不太明白这个，基本用不到
		"problemMatcher": "$tsc",
	}

另外还有更多参数和用法可以参照下面的官方文档

[https://code.visualstudio.com/docs/editor/tasks](https://code.visualstudio.com/docs/editor/tasks)

配置好了之后使用默认的快捷键Ctrl+Shift+B即可执行编译。

### 运行和调试项目
vscode默认支持nodejs，ts，js等项目的调试。使用**launch.json**p配置调试参数。

调试启动调试的默认快捷键是F5， 如果没有**launch.json**则会弹窗提示选择调试环境，并自动创建**launch.json**。

![](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/11/3.png)

以调试node项目为例，简单说明下**launch.json**的写法

	{
		"version": "0.2.0",
		"configurations": [
			{
				// 启动配置的名称。每个程序可能有多个启动配置
				// 此名称将显示在调试面板的下拉框中
				"name": "Launch",
				// 配置的类型，默认有三种类型(node,momo,extensionHost)
				// 可以通过插件来自定义更多的类型
				"type": "node",
				// 请求类型, launch表示启动程序调试，attach表示监听某一端口进行调试
				"request": "launch",
				// node程序的入口脚本路径(相对于工作空间)
				"program": "./out/bootstrap.js",
				"stopOnEntry": false,
				// 接在program指定js后面的参数
				"args": [],
				// 程序的启动位置
				"cwd": ".",
				// 启动程序的路径, 如果为null则使用默认的node
				"runtimeExecutable": null,
				// 传递给node的参数
				"runtimeArgs": [
					"--nolazy",
					"--es_staging",
					"--harmony-proxies"
				],
				// 程序启动时设置的环境变量
				"env": {
					"NODE_ENV": "development"
				},
				"externalConsole": false,
				// 是否使用sourceMaps
				"sourceMaps": true,
				// 如果使用sourceMaps，js脚本所在的路径
				"outDir": "./out"
			},
			{
				"name": "Attach",
				"type": "node",
				// attach表示监听某一端口进行调试
				"request": "attach",
				// 要监听的端口
				"port": 5858,
				// 是否使用sourceMaps
				"sourceMaps": true,
				// 如果使用sourceMaps，js脚本所在的路径
				"outDir": "./out"
			}
		]
	}

这里面对应了launch和attach两个配置任务。说下两者的区别。

launch实际上是启动一个node执行指定代码，同时可以在vscode里面打断点调试。以上述配置为例，实际执行的命令为

	node --debug-brk=30001 --nolazy --es_staging --harmony-proxies out\bootstrap.js 

端口号是随机的，vscode能打断点调试是因为他内部监听了这个端口，并与node通讯实现调试。

attach就是监听的任务。例如**其他程序**启动了一个node应用并使用了--debug-brk参数开启了5858端口使程序暂停在了第一行。此时启动attach任务，就可以监听到这个端口，并在**vscode里面**调试这个node应用了。

附上一张vscode调试面板的截图

![](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/11/debugging_hero.png)

有关如何调试的教程

[https://code.visualstudio.com/docs/editor/debugging](https://code.visualstudio.com/docs/editor/debugging)

