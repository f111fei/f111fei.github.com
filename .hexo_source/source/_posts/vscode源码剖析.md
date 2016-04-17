title: vscode源码剖析
categories: nodejs
date: 2016-04-17 00:37:03
tags: [vscode,nodejs]
---

vscode作为微软推出的现代编辑器已经在GitHub上[开源](https://github.com/Microsoft/vscode)了。用过vscode的人都纷纷表示速度极快，秒杀同为使用[Electron](https://github.com/electron/electron)架构的[Atom](https://github.com/atom/atom)。这次我们从源码级别来剖析为何vscode快速，高效。

<!--more-->

## Electron

`Electron` 是基于 `Node.js` 和 `Chromium` 的跨平台桌面应用开发框架。使用 `JavaScipt`，`HTML`，`CSS` 真正将 `Node.js` 带到了前端。`Electron` 通过 `BrowserWindow` 可以创建一个本地窗口，并加载一个`HTML`文档，`BrowserWindow`中的内容就是一个浏览器窗口，不仅能创建`DOM`元素，同时能使用任意的Node模块，并且还可以通过`IPC`与主进程通讯。

## 多进程

每一个 `Electron` 应用都对应一个主进程(main process)， 主进程通过`BrowserWindow`创建的每个本地窗口对应一个渲染进程(renderer process)。

![](http://xzper.qiniudn.com/2016/04/1.png)

### 主进程

vscode的主进程主要负责创建窗口和菜单，生命周期管理，自动更新等与系统相关的功能。

### 渲染进程

绝大多数代码都是运行在渲染进程中的，渲染进程负责界面的显示，响应用户操作。前面说到在浏览器中也可以使用Node模块，渲染进程还通过Node创建了一个插件子进程，负责插件的初始化。另外渲染进程还可以创建Worker执行一些复杂的计算，比如markdown的解析。

### 插件进程

每一个渲染进程同时也对应一个插件进程，插件运行在单独的进程不会对渲染进程造成影响，这也是vscode比atom要快的原因。Atom中插件是直接运行在渲染进程中的，所以当插件很多的时候会卡。同时又由于vscode的插件运行在一个普通的Node进程中，所以对UI的操作能力是比较弱的，这点不及Atom。

## VSCode Loader

[VSCode Loader](https://github.com/Microsoft/vscode-loader)是类似于 [RequireJS](https://github.com/requirejs/requirejs) 的一个异步加载模块([AMD](https://github.com/amdjs/amdjs-api/wiki/AMD))。所有的TypeScript源码都被编译成了使用AMD规范的js文件，使用时通过这个loader加载。

虽然主进程(Node进程)是使用CommonJS规范的，但是在浏览器中的代码加载是异步的，所以使用AMD是没有争议的。在vscode中的一些核心代码，基本库都是用TypeScript编写的，也会被编译成AMD规范的js，这些基本代码也会被主进程用到，所以主进程里面也用到了这个loader。同理，插件进程和Worker都会使用这个loader加载代码。

VSCode Loader不仅实现了类似RequireJS的[模块加载](https://github.com/Microsoft/vscode/blob/master/src/vs/loader.js)功能，还附带几个插件可以加载css([css.js](https://github.com/Microsoft/vscode/blob/master/src/vs/css.js))和[文档](https://github.com/Microsoft/vscode/blob/master/src/vs/text.js)，以及实现[多语言](https://github.com/Microsoft/vscode/blob/master/src/vs/nls.js)。


## 项目结构

vscode的主要目录结构如下:

	├── build                 // gulp打包编译相关脚本
	├── node_modules          // 依赖模块
	├── src                   // 源代码和素材(ts,js,css,svg,html等)
	│	├── typings           // 常用模块定义
	│	├── vs
	│	│	├── base         // 核心模块，常用库和基本组件
	│	│	├── editor       // 编辑器模块
	│	│	├── languages    // 默认编辑器语言支持
	│	│	├── platform     // 核心功能接口定义和基本实现
	│	│	├── workbench    // 业务逻辑功能实现
	│	│	├── loader.js    // vscode loader
	│	│	└── vscode.d.ts  // 插件API定义
	│	└── main.js          // 主进程入口
	├── gulpfile.js          // gulp打包编译入口
	├── product.json         // 产品描述文件
	└── package.json



### [base](https://github.com/Microsoft/vscode/tree/master/src/vs/base)

base包封装了大量API，实现常用功能。在vscode中目录结构都是都是按照browser，common，node，electron的方式划分的。

- browser 实现浏览器相关的功能。
- common 实现不依赖node模块的基本功能。
- node 实现需要node模块支持的功能，比如文件操作。
- electron 实现需要electron api的功能，比如ipc通讯。

#### [browser](https://github.com/Microsoft/vscode/tree/master/src/vs/base/browser)

browser中实现了一个简单的UI库，包括 `Button`，`CheckBox`，`List`，`Scrollbar`等常用组件。并且封装了一套类似JQuery的DOM操作API(参见 [dom.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/browser/dom.ts) 和 [builder.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/browser/dom.ts))。

#### [common](https://github.com/Microsoft/vscode/tree/master/src/vs/base/common)

common包中封装了大量实用工具类。如

- [arrays.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/common/arrays.ts)，[strings.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/common/strings.ts)，[objects.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/common/objects.ts) 封装了一套类似underscore的api。
- [uri.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/common/uri.ts) 和 [paths.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/common/paths.ts) 实现了路径解析功能。
- [winjs.base.js](https://github.com/Microsoft/vscode/blob/master/src/vs/base/common/winjs.base.js) 实现了一个功能强大的Promise。

另外还有很多其他的工具类，每一个模块的耦合度都很低，基本都可以单独拿出来用，学习起来也和容易。这里就不一一介绍了。

#### [node](https://github.com/Microsoft/vscode/tree/master/src/vs/base/node)

node包中封装了一些node实现的功能。如

- [extfs.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/node/extfs.ts) 和 [pfs.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/node/pfs.ts) 封装了文件操作相关的api。
- [request.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/node/request.ts) 封装了网络请求的api，能方便的发送网络请求，加载json，下载文件。
- [service.cp.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/node/service.cp.ts) 和 [service.net.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/node/service.net.ts) 封装了socket和进程通讯的api。
- [zip.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/base/node/zip.ts) 封装了解压缩文件的操作

#### [parts](https://github.com/Microsoft/vscode/tree/master/src/vs/base/parts)

这个包额外定义了一些复杂的UI组件，tree 和 quickopen。

### [editor](https://github.com/Microsoft/vscode/tree/master/src/vs/editor) and [language](https://github.com/Microsoft/vscode/tree/master/src/vs/language)

本篇主要了解vscode基本框架的结构，这两包作为编辑器功能的主要实现，这里面的逻辑太复杂就不细说了。

### [platform](https://github.com/Microsoft/vscode/tree/master/src/vs/platform) and [workbench](https://github.com/Microsoft/vscode/tree/master/src/vs/workbench)

vscode中基本所有的具体功能实现代码都在这两包中。platform主要定义了一些服务的接口和简单实现，workbench则实现了这些接口，并且创建了一个工作台，构建了一个完整界面结构。


----------

下面从程序入口开始，从源码一步一步来看vscode是怎样运行起来的。

## 启动主进程

Eletron通过[package.json](https://github.com/Microsoft/vscode/blob/master/package.json)中的[main字段](https://github.com/Microsoft/vscode/blob/master/package.json#L8)来定义应用入口。[main.js](https://github.com/Microsoft/vscode/blob/master/src/main.js) 是vscode的入口。

### 初始化loader

这个模块是一个壳，主要解析多语言配置，然后初始化loader，通过loader加载 [main.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-main/main.ts)。

	// Load our code once ready
	app.once('ready', function () {
		var nlsConfig = getNLSConfiguration();
		process.env['VSCODE_NLS_CONFIG'] = JSON.stringify(nlsConfig);
		require('./bootstrap-amd').bootstrap('vs/workbench/electron-main/main');
	});

这里的 [bootstrap-amd.js](https://github.com/Microsoft/vscode/blob/master/src/bootstrap-amd.js) 负责创建一个loader，实现异步加载。

	loader.config({
		baseUrl: uriFromPath(path.join(__dirname)),
		catchError: true,
		nodeRequire: require,
		nodeMain: __filename,
		'vs/nls': nlsConfig
	});
	
	......
	
	exports.bootstrap = function (entrypoint) {
		if (!entrypoint) {
			return;
		}
	
		loader([entrypoint], function () { }, function (err) { console.error(err); });
	};

### 解析命令行参数

在 [main.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-main/main.ts) 中依赖一个 [env](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-main/env.ts) 的模块

	import env = require('vs/workbench/electron-main/env');

该模块负责命令行参数的解析，以及读取 [package.json](https://github.com/Microsoft/vscode/blob/master/package.json) 和 [product.json](https://github.com/Microsoft/vscode/blob/master/product.json) 保存软件的一些基本信息，主要变量如下：

	// 是否是发行版
	export const isBuilt = !process.env.VSCODE_DEV;
	// 应用程序根目录
	export const appRoot = path.dirname(uri.parse(require.toUrl('')).fsPath);
	// 产品配置
	export const product: IProductConfiguration = productContents;
	// 程序版本
	export const version = app.getVersion();
	// 命令行参数
	export const cliArgs = parseCli();
	// 数据文件目录
	export const appHome = app.getPath('userData');
	// setting文件路径
	export const appSettingsPath = path.join(appSettingsHome, 'settings.json');
	// keybindings文件路径
	export const appKeybindingsPath = path.join(appSettingsHome, 'keybindings.json');
	// 用户插件目录
	export const userExtensionsHome = cliArgs.extensionsHomePath || path.join(userHome, 'extensions');

### 初始化管理器

在main.ts的main方法中，初始化了主进程中的各个管理器

	// Lifecycle
	lifecycle.manager.ready();

	// Load settings
	settings.manager.loadSync();

	// Propagate to clients
	windows.manager.ready(userEnv);

	// Install Menu
	menu.manager.ready();

	.....

	// Setup auto update
	UpdateManager.initialize();

- [lifecycle](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-main/lifecycle.ts) 负责管理软件的生命周期，派发`onBeforeQuit`等事件。
- [setting](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-main/settings.ts) 负责管理用户设置和快捷键绑定的读取和存储。
- [windows](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-main/windows.ts) 负责窗口的创建和管理，非常核心的一个模块。
- [menus](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-main/menus.ts) 负责菜单栏的创建。
- [update-manager](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-main/update-manager.ts) 自动更新功能。

以上管理器中大量使用了Eletron的 `ipc` 模块发送接收渲染进程的消息，来实现主进程和渲染进程的交互。

### 打开第一个窗口

在main.ts的main方法的最后

	// Open our first window
	if (env.cliArgs.openNewWindow && env.cliArgs.pathArguments.length === 0) {
		windows.manager.open({ cli: env.cliArgs, forceNewWindow: true, forceEmpty: true }); // new window if "-n" was used without paths
	} else if (global.macOpenFiles && global.macOpenFiles.length && (!env.cliArgs.pathArguments || !env.cliArgs.pathArguments.length)) {
		windows.manager.open({ cli: env.cliArgs, pathsToOpen: global.macOpenFiles }); // mac: open-file event received on startup
	} else {
		windows.manager.open({ cli: env.cliArgs, forceNewWindow: env.cliArgs.openNewWindow, diffMode: env.cliArgs.diffMode }); // default: read paths from cli
	}

调用了 `windows` 模块的 `open` 方法打开了第一个窗口。这里调用了 `env.cliArgs` 获取命令行参数传递给 `open` 方法来实现不同的打开方式。

在 `open` 方法中创建一个了 `VSCodeWindow` 实例，并且通过 `toConfiguration` 方法创建了一个 `IWindowConfiguration` 的对象。

`IWindowConfiguration` 中定义了大量的 `env` 中的信息，包括环境变量，命令行参数，软件信息等。在之后 `IWindowConfiguration` 会作为参数传递给 `VSCodeWindow` 的 `load` 方法。

`VSCodeWindow` 包装了一个 `BrowserWindow` 对象。`load` 方法调用 `getUrl` 加载了一个的 [html文件](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-browser/index.html)。

	private getUrl(config: IWindowConfiguration): string {
		let url = require.toUrl('vs/workbench/electron-browser/index.html');

		// Config
		url += '?config=' + encodeURIComponent(JSON.stringify(config));

		return url;
	}

可以看到 `IWindowConfiguration` 被序列化成字符串作为参数传递给了 `index.html`。由于在浏览器进程要获取主进程中 `env` 模块的数据比较复杂(需要使用 `ipc` 通讯)。所以这里直接将一些基本信息打包成config传递给了浏览器进程。这时浏览器窗口才正式打开并初始化。

## 启动浏览器

### 初始化loader

浏览器的入口在 [index.html](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-browser/index.html) 中。与主进程类似这里也对loader进行了初始化并加载浏览器主模块 [main](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-browser/main.ts) 。主要代码如下：

	// 解析config参数
	var args = parseURLQueryArgs();
	var configuration = JSON.parse(args['config']);
	......
	// loader的加载根目录
	var rootUrl = uriFromPath(configuration.appRoot) + '/out';
	// 加载loader
	createScript(rootUrl + '/vs/loader.js', function() {
		// 多语言配置
		var nlsConfig;
		try {
			var config = process.env['VSCODE_NLS_CONFIG'];
			if (config) {
				nlsConfig = JSON.parse(config);
			}
		} catch (e) {
		}
		if (!nlsConfig) {
			nlsConfig = { availableLanguages: {} };
		}
		// 配置loader
		require.config({
			baseUrl: rootUrl,
			'vs/nls': nlsConfig,
			recordStats: configuration.enablePerformance
		});
		......
		require([
			// 项目正式发布后大多数的js都被合并进了workbench.main.js中
			'vs/workbench/workbench.main',
			'vs/nls!vs/workbench/workbench.main',
			'vs/css!vs/workbench/workbench.main'
		], function() {
			timers.afterLoad = new Date();

			// 浏览器主模块
			var main = require('vs/workbench/electron-browser/main');

			// config作为参数，调用startup启动主模块
			main.startup(configuration, globalSettings).then(function() {
				mainStarted = true;
			}, function(error) { onError(error, enableDeveloperTools) });
		});
	});

### 初始化工作台

在 [main](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-browser/main.ts) 模块的 `startup` 方法中进一步加工 `config`，并创建了一个 `workspace`。

	export function startup(environment: IMainEnvironment, globalSettings: IGlobalSettings): winjs.TPromise<void> {
	
		// 将主进程中的环境变量合并到浏览器进程
		assign(process.env, environment.userEnv);
	
		// Shell Configuration
		let shellConfiguration: IConfiguration = {
			env: environment
		};
		......
		let shellOptions: IOptions = {
			......
		};
		......
		// Open workbench
		return openWorkbench(getWorkspace(environment), shellConfiguration, shellOptions);
	}

	function getWorkspace(environment: IMainEnvironment): IWorkspace {
		if (!environment.workspacePath) {
			return null;
		}
		......
		let workspace: IWorkspace = {
			'resource': workspaceResource,
			'id': platform.isLinux ? realWorkspacePath : realWorkspacePath.toLowerCase(),
			'name': folderName,
			'uid': platform.isLinux ? folderStat.ino : folderStat.birthtime.getTime(),
			'mtime': folderStat.mtime.getTime()
		};
	
		return workspace;
	}

这里的 `environment` 就是上文的 `config`。 `IWorkspace` 记录了当前打开的文件夹路径等信息(当打开单文件时 `IWorkspace` 不存在)。

	function openWorkbench(workspace: IWorkspace, configuration: IConfiguration, options: IOptions): winjs.TPromise<void> {
		let eventService = new EventService();
		let contextService = new WorkspaceContextService(eventService, workspace, configuration, options);
		let configurationService = new ConfigurationService(contextService, eventService);
	
		return configurationService.initialize().then(() => {
				......
				let shell = new WorkbenchShell(document.body, workspace, {
					configurationService,
					eventService,
					contextService
				}, configuration, options);
				shell.open();
				......
		});
	}

在 `openWorkbench` 创建了三个基本服务(Service)，并将 `config`，`workspace` 等参数传给 `WorkbenchShell` 。`WorkbenchShell` 获取html文档的 `body` 节点准备创建界面。

### 初始化服务

[WorkbenchShell](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-browser/shell.ts) 主要负责初始化各服务(Service)，并创建了一个 `Workbench` 完成界面的初始化工作。

常用的Service比如

- IStorageService 浏览器进程数据的持久化存储与读取。
- IWorkspaceContextService 获取工作空间数据和config等基本配置信息。
- IKeybindingService 管理快捷键相关的注册。
- IFileService 封装了文件操作的相关API，并实现 `FileWatcher` 功能。
- IExtensionService 管理插件的初始化，加载和交互。
- IInstantiationService 负责创建实例对象，这个Service比较重要，下面单独说明。

`initInstantiationService` 方法中创建了各个服务，并返回 `IInstantiationService`。

##### IInstantiationService

在vscode中随处可见 `IInstantiationService` 的应用。以 `CloseWindowAction` 为例

	export class CloseWindowAction extends Action {
	
		public static ID = 'workbench.action.closeWindow';
		public static LABEL = nls.localize('closeWindow', "Close Window");
	
		constructor(id: string, label: string, @IWindowService private windowService: IWindowService) {
			super(CloseWindowAction.ID, label);
		}
	
		public run(): TPromise<boolean> {
			this.windowService.getWindow().close();
	
			return TPromise.as(true);
		}
	}

在构造函数(`constructor`)中，后面的参数写法比较特殊

	@IWindowService private windowService: IWindowService

使用了 `@IWindowService` 这种decorate语法。当要创建 `CloseWindowAction` 这个实例时，可以使用 `IInstantiationService` 只需要传入前两个参数，在`IInstantiationService` 中能获取所有的其他服务对象， `windowService` 这个参数由 `IInstantiationService` 传入。

	this.instantiationService.createInstance(CloseWindowAction, CloseWindowAction.ID， CloseWindowAction.LABEL);

### 创建Workbench

[WorkbenchShell](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/electron-browser/shell.ts) 的 `createContents` 方法还创建了一个 `Workbench` 负责整个界面的创建。

	private createContents(parent: Builder): Builder {
		......
		// Instantiation service with services
		let instantiationService = this.initInstantiationService();
		......
		// Workbench
		this.workbench = new Workbench(workbenchContainer.getHTMLElement(), this.workspace, this.configuration, this.options, instantiationService);
		this.workbench.startup({
			onServicesCreated: () => {
				this.initExtensionSystem();
			},
			onWorkbenchStarted: () => {
				this.onWorkbenchStarted();
			}
		});
		......
	}

`Workbench` 是 `IPartService` 的具体实现。vscode由多个Part组成。
- activitybar 是最左边(也可以设置到右边)的选项卡。目前有 `Explore`，`Search`，`Git`，`Debug` 这4个选项卡。
- sidebar 是activitybar选中的内容。
- editor 是最主要的编辑器部分。
- statusbar 是下方的状态栏。
- panel 是状态栏上方的面板选项卡，目前主要有 `output`，`debug`，`errorlist` 等几个面板。
- quickopen 是悬浮在中上方的弹出界面，常用的命令面板(F1)就是一个`quickopen widget`。

![](http://xzper.qiniudn.com/2016/04/2.png)


下面的代码展示了各个part的创建，并添加到显示列表。

	private renderWorkbench(): void {
		......
		// Create Parts
		this.createActivityBarPart();
		this.createSidebarPart();
		this.createEditorPart();
		this.createPanelPart();
		this.createStatusbarPart();

		// Create QuickOpen
		this.createQuickOpen();

		// Add Workbench to DOM
		this.workbenchContainer.build(this.container);
	}


## 扩展点的注册和实现

vscode中几乎每个部分都是可扩展的。例如最常见的有快捷键命令的注册，编辑器类型的扩展，扩展输出面板Channel。下面以 `ViewletRegistry` 为例，分析 `activitybar` 和 `sidebar` 上面的 `Explore` 文件浏览器是如何显示的。

### contribution

通常情况下以 `.contribution` 结尾的模块，都用作扩展点的注册。由于一般情况下这些模块不会被其他模块依赖，所以要提供一个入口来加载这些模块，这个入口就是 [workbench.main](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/workbench.main.js)。

其中 `Explore` 文件浏览器的注册是在 [files.contribution](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/parts/files/browser/files.contribution.ts) 中定义的。

	// Register Viewlet
	(<ViewletRegistry>Registry.as(ViewletExtensions.Viewlets)).registerViewlet(new ViewletDescriptor(
		'vs/workbench/parts/files/browser/explorerViewlet',
		'ExplorerViewlet',
		VIEWLET_ID,
		nls.localize('explore', "Explorer"),
		'explore',
		0
	));
	
	(<ViewletRegistry>Registry.as(ViewletExtensions.Viewlets)).setDefaultViewletId(VIEWLET_ID);

`explorerViewlet` 模块是 `Explore` 的界面显示入口。

### registry

platform 中定义了 `IRegistry` 接口及实现。

	export interface IRegistry {
	
		/**
		 * Adds the extension functions and properties defined by data to the
		 * platform. The provided id must be unique.
		 * @param id a unique identifier
		 * @param data a contribution
		 */
		add(id: string, data: any): void;
	
		/**
		 * Returns true iff there is an extension with the provided id.
		 * @param id an extension idenifier
		 */
		knows(id: string): boolean;
	
		/**
		 * Returns the extension functions and properties defined by the specified key or null.
		 * @param id an extension idenifier
		 */
		as(id: string): any;
		as<T>(id: string): T;
	}

`add` 添加一个注册点， `as` 方法获取一个注册点对象。

[viewlet](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/browser/viewlet.ts) 模块添加了 `ViewletRegistry`。

	Registry.add(Extensions.Viewlets, new ViewletRegistry());

之后可以通过 `Registry.as(Extensions.Viewlets)` 获取 `ViewletRegistry` 注册不同的 `Viewlet`。

### 实现注册功能

所有的注册信息储存在 `ViewletRegistry` 中，使用时通过 `getViewlet` 或者 `getViewlets` 方法获取。 [activitybarPart](https://github.com/Microsoft/vscode/blob/master/src/vs/workbench/browser/parts/activitybar/activitybarPart.ts) 实现了注册点的读取，并填充 `ActionBar`，显示出来。

	private createViewletSwitcher(div: Builder): void {

		// Viewlet switcher is on top
		this.viewletSwitcherBar = new ActionBar(div, {
			.......
		});
		this.viewletSwitcherBar.getContainer().addClass('position-top');

		// Build Viewlet Actions in correct order
		let activeViewlet = this.viewletService.getActiveViewlet();
		let registry = (<ViewletRegistry>Registry.as(ViewletExtensions.Viewlets));
		let viewletActions: Action[] = registry.getViewlets()     // 获取注册的viewlets
			.sort((v1: ViewletDescriptor, v2: ViewletDescriptor) => v1.order - v2.order)
			.map((viewlet: ViewletDescriptor) => {
				let action = this.instantiationService.createInstance(ViewletActivityAction, viewlet.id + '.activity-bar-action', viewlet);
				......
				return action;
			});

		// Add to viewlet switcher
		this.viewletSwitcherBar.push(viewletActions, { label: true, icon: true });
	}

类似的这种扩展点还有很多，如:
- IWorkbenchActionRegistry 注册一个action和快捷键，并出现在命令面板中。
- IEditorRegistry 注册一种编辑器。
- IConfigurationRegistry 注册设置项。
- IActionBarRegistry 注册右键菜单。


这种通过注册扩展点的架构方式，使得vscode整体变得很容易扩展。


## VSCode PK Atom

vscode整体架构给人一种很清晰明了的感觉。多进程从主进程到浏览器，从浏览器到插件系统，服务驱动，可扩展的结构。

另外无论是UI组件还是工具和加载器都是自身实现的，没有借助第三方模块，使得耦合性和性能都得到了很好的保障。这也是vscode速度比Atom快的原因。

尽管扩展vscode自身是很容易的，但是目前vscode开放的插件接口还是极其有限。由于为了保证渲染进程的安全和速度，插件是一个单独的Node进程，插件进程无法创建UI，这一点使得vscode的插件开放没有Atom灵活，很多需要借助UI的插件功能也无法实现。

## 结语

微软大法好