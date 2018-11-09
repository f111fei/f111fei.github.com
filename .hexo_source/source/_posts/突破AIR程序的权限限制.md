title: 突破AIR程序的权限限制
categories: ActionScript3
date: 2015-01-24 13:27:45
tags:
---
AIR中有些API在没有权限的情况下是不生效的，甚至不报错也没没有任何提示。例如文件系统中对敏感目录的文件操作，File.applicationDirectory这个API的文档是这样说的

> 出于安全原因，不推荐修改应用程序目录中的内容，有些平台上的操作系统会阻止此操作。
如果要存储特定于应用程序的数据，请考虑使用应用程序存储目录 (File.applicationStorageDirectory)。

可以看到File.applicationDirectory这个目录是无法保证有权限写入的。这篇文章讲解如何在Windows和Mac下突破这一限制，能获取系统中任何目录的操作权限。

<!--more-->

解决这个问题基本思路是想办法让程序获得管理员所有权，一旦程序有了权限就可以肆无忌惮了。但是，一个没有权限的程序在运行时是无法提升权限的，只能在程序启动时，赋予权限。也就是说要想让程序有权限，必须通过另一个程序。假设我们的AIR程序叫A，这个可以提升其他AIR程序权限的程序叫elevate，调用elevate，传入A的路径，启动A就行了。这里有两种方案：

1.使用一个壳，壳启动时调用elevate以管理员方式启动A，这样A就获得了权限。

2.启动A，这时A是没有权限的，然后A调用elevate，启动程序B，由B来执行一切需要权限的敏感操作。

elevate这个程序在为其他程序申请权限的时候是需要认证的。在Windows7及其以上，如果用户开启了用户账户控制(UAC)，那么会弹出提示框，让用户点击确认的。在Mac上是需要输入用户密码，来完成授权的。那么方案1，程序A在启动时，会提示用户确认，然后一劳永逸，A想干啥就干啥了。方案2，程序A只有在需要进行敏感操作时就会提示用户确认，如果B在执行完任务后退出了，那么下次需要权限时又得确认了。两种方案各有好处。我们最终选用了方案B，毕竟程序启动时来那么一个提示框对用户体验不太好。

说了这么多，下面祭出大杀器elevate。

Windows下使用下面提供的elevate.exe。
Mac下使用下面提供的elevate.scpt。

有了elevate在AIR下使用NativeProcess启动elevate，并传入参数。用法如下：

	/**
	 * 以管理员方式执行程序
	 * @param exePath 要执行的程序路径
	 * @param args 要传入的参数
	 */
	public function run(exePath:String , exeArgs:Vector.<String> = null):void
	{
		var elevateFolder:File = File.applicationDirectory.resolvePath("bin");
		var nativeProcess:NativeProcess = new NativeProcess();
		var nativeProcessInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
		var args:Vector.<String> = new Vector.<String>();
		if(Capabilities.os.indexOf("Mac OS")>=0)
		{
			nativeProcessInfo.executable = new File("/usr/bin/osascript");
			args.push(elevateFolder.resolvePath("elevate.scpt").nativePath);
			args.push(exePath);
		}
		else
		{
			if(Capabilities.os.indexOf("XP")<0)
			{
				//非xp系统直接调用elevate申请权限
				nativeProcessInfo.executable = elevateFolder.resolvePath("elevate.exe");
				args.push(exePath);
			}
			else
			{
				//xp系统下没有UAC，直接运行目标程序即可
				nativeProcessInfo.executable = new File(exePath);
			}
		}
		if(exeArgs)
			args = args.concat(exeArgs);
		nativeProcessInfo.arguments = args;
		nativeProcess.start(nativeProcessInfo);
	}

如果觉得这种传参调用不好用，可以改一下。在目标程序启动后，可以实现A程序与B程序的进程通讯。A向B程序相互发消息就更加灵活了。我们的方案是把B程序也做成一个AIR应用，这样就可以使用LocalConnection实现两个AIR程序的通讯了。


elevate的下载地址,有兴趣的可以hack下:

Windows：[elevate.exe](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/01/elevate.zip)

Mac：[elevate.scpt](https://raw.githubusercontent.com/f111fei/f111fei.github.com/master/.hexo_source/source/resource/2015/01/elevate.scpt)