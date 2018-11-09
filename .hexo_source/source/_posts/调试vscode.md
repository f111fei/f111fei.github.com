title: 调试vscode
categories: nodejs
date: 2015-11-29 13:27:11
tags: [nodejs,vscode]
---
在调试vscode之前，有必要先了解一下vscode的运行过程。

#### vscode的启动过程

electron是vscode的内核，vscode的启动类在package.json中定义

	"main": "./out/vs/workbench/electron-main/bootstrap"

electron启动时通过`atom.asar`这个文件，加载package.json中定义的main脚本启动程序。

如果搜索vscode的项目文件列表，你会发现其他位置还有一个bootstrap文件

	./out/bootstrap.js

其实这个也是启动类，只不过是PluginHost的启动类。


<!--more-->


#### 插件运行机制

和许多ide和流行的文本编辑器一样，vscode也具备插件系统。只不过vscode的插件加载运行机制和其他的程序不同。

如果在开启了vscode的情况下查看任务管理器，可以发现有很多的code进程。vscode里面的代码在不同的进程里面执行，并使用process.send 或者 socket 实现进程通信。

vscode的插件系统就是在一个单独的进程里面运行。然后插件进程和主进程进行通信，来实现插件功能。关于插件进程的启动，有兴趣的可以查看源代码

	// src/vs/workbench/services/thread/electron-browser/threadService.ts

	// Run Plugin Host as fork of current process
	this.pluginHostProcessHandle = cp.fork(uri.parse(require.toUrl('bootstrap')).fsPath, ['--type=pluginHost'], opts);

#### 调试类型

由于vscode的代码是在不同进程里面分开运行的，调试也得分开进行。

vscode里面主要有三种环境： Main， PluginHost， ExtensionHost

##### Main

主进程环境是最容易调试的，直接选择菜单栏 Help - Toggle Developer Tools

![](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/11/7.png)

打开开发者工具，就可以直接使用chrome的调试功能查看和调试源代码了。

![](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/11/8.png)

不过可能由于打开这个面板的时机比较晚，会错过一些启动类代码的执行。不过通过切换工作空间，来重新执行一般加载过程，在这之前打断点就行了。

还有一种用vscode/chrome调试vscode主进程的办法。打开vscode，使用从git clone下来的vscode文件夹作为工作空间目录。修改.vscode文件夹中默认的`launch.json`文件，最后改为

	{
		"name": "Attach to VSCode",
		"type": "node",
		"request": "attach",
		"port": 9222,
		"sourceMaps": true,
		"outDir": "out"
	}

注意第二行type字段用从chrome改为node。因为默认安装包里面没有vscode-chrome-debug插件，所以不支持启动chrome的调试，我们直接用vscode本身的代替就行了。

ps: vscode-chrome-debug插件的GitHub地址

	https://github.com/Microsoft/vscode-chrome-debug

然后使用命令行在其他目录启动一个要调试的vscode进程, 断点在第一行，设置端口为9222。

	"D:/workSpace/vscode/vscode/.build\electron/CodeOSS.exe" --debug-brk=9222 .



- CodeOSS.exe的路径根据实际路径替换，如果使用上一篇里面使用符号链接的方式构建的，CodeOSS.exe可以换成发行版的code.exe这个文件。

- 注意要加最后面的那个 `.` 参数，表示使用当前目录作为工作空间。

- 端口号也可以不改，使用`launch.json`里面另外的Attach to Extension Host这个配置就行了，不过不建议，因为这个配置的端口号是5870有可能会和之后调试插件进程的默认端口号冲突。

最后在一开始打开的那个vscode里面切换到调试面板，选择 Attach to VSCode。

![](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/11/9.png)

按下F5或者点击调试按钮，程序就会Attach9222端口，并停在第一行了。之后在其他地方设置断点就行了。支持直接在ts文件上打断点，因为默认的编译参数是开启了sourceMap选项的。


##### PluginHost

由于插件进程是从主进程启动的，想要直接调试有点困难。我翻遍了官方的教程也没有找到相关文档。后来被我从源代码里面找到了其中的秘密。

	// Run Plugin Host as fork of current process
	this.pluginHostProcessHandle = cp.fork(uri.parse(require.toUrl('bootstrap')).fsPath, ['--type=pluginHost'], opts);

这时启动插件进程的语句，粗看只有一个 `--type=pluginHost` 的额外参数。实际上还有其他参数隐藏在了`opts.execArgv`里面。 继续追踪threadService.ts里面对execArgv操作，找到这样的一个方法。

	private resolveExecArgv(config: IConfiguration, clb: (execArgv: any) => void): void {
		// Check for a free debugging port
		if (typeof config.env.debugPluginHostPort === 'number') {
			return ports.findFreePort(config.env.debugPluginHostPort, 10 /* try 10 ports */, (port) => {
				...
				return clb(['--nolazy', (config.env.debugBrkPluginHost ? '--debug-brk=' : '--debug=') + port]);
			});
		}
		...
	}


`config.env.debugBrkPluginHost`关键的关键就是这个属性了。如果为true则会添加一个`--debug-brk`的参数。

node里面`--debug-brk`参数表示在程序的第一行设置断点。那么想办法找到对`config.env.debugBrkPluginHost`这个属性赋值的地方，就可以在插件进程的第一行设置断点，再使用Attach功能，监听`config.env.debugBrkPluginHost`指定端口就可以调试插件进程了。

最后在

	src/vs/workbench/electron-main/env.ts

这个文件里面找到了设置代码

	let debugBrkPluginHostPort = parseNumber(args, '--debugBrkPluginHost', 5870);
	let debugPluginHostPort: number;
	let debugBrkPluginHost: boolean;
	if (debugBrkPluginHostPort) {
		debugPluginHostPort = debugBrkPluginHostPort;
		debugBrkPluginHost = true;
	} else {
		debugPluginHostPort = parseNumber(args, '--debugPluginHost', 5870, isBuilt ? void 0 : 5870);
	}

答案出来了，就是在启动vscode的时候加一个`--debugBrkPluginHost`的参数。当然也可以指定一个端口号，不指定就使用默认5870。

剩下的步骤基本和上面使用vscode调试主进程的一样。在其他目录，使用命令行

	code . --debugBrkPluginHost

打开一个要调试的vscode，这时vscode的的主进程启动，插件进程断点在了第一行，等待Attach连接到5870端口。

然后使用从git clone下来的vscode文件夹作为工作空间目录，打开另外一个vscode的调试面板，将配置切换成 Attach to Extension Host， 使用F5开启调试。会自动断点在插件进程入口的第一行

![](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/11/10.png)

- code命令实际上是调用的发行版安装目录下bin/code.js。之前如果调试主进程使用code命令开启要调试的vscode，断点会停在code.js的第一行，这样就没法在主进程的代码里面断点了。这里可以使用code命令是因为不需要调试主进程。

##### ExtensionHost

用户开发的Extension的调试。这个本来是最简单的，因为官方的插件项目示例，里面已经自动生成了配置，在开发插件时直接按F5启动extensionHost类型的调试设置就可以调试用户的插件了。

但是由于是发行版的vscode，vscode本身的源代码被混淆压缩了，只能调试用户的插件代码，没法调试vscode自身的代码。就像下面这样，如果会提示Source is not available。

![](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/11/11.png)

如果想要显示vscode的源码，可以使用上一篇提到的[创建符号链接的办法](http://xzper.com/2015/11/29/%E7%BC%96%E8%AF%91vscode/#mklink)，让vscode始终使用源代码运行。不知道有没有直接通过修改`launch.json`文件来指定源代码目录的方法。


附：
这里加一些比较有用的启动参数


-  --debugBrkPluginHost 调试插件进程并在插件进程的第一行位置断点，该参数指定一个端口号，默认值为5870。
-  -logPluginHostCommunication 在控制台输出主进程和插件进程的通讯消息
-  --extensionDevelopmentPath 指定开发版的插件路径 




----------


参考链接：

[How-to-Contribute](https://github.com/Microsoft/vscode/wiki/How-to-Contribute)

[Extending Visual Studio Code](https://code.visualstudio.com/docs/extensions/overview)