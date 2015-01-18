title: AIR中一些隐藏特性
categories: ActionScript3
date: 2015-01-17 21:52:01
tags:
---
分享一下在使用AIR开发跨平台应用的几个坑。在此之前不得不说，stackoverflow这个网站帮了我很多。每次遇到一些棘手的技术问题寻找答案未果的情况下，stackoverflow总能找到令人满意的答案。这里分享两个我遇到的一些问题。

<!--more-->

**1.打印异常堆栈信息**

当产品发布时，没人能保证程序百分之百稳定运行。难免会有一些bug，而用户遇到了bug需要反馈的时候，报错的堆栈信息如果能够得到保留能省很多事。所幸AIR有这样的API能输出堆栈信息。看下面这段代码。

    loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR,errorHandle);

	protected function errorHandle(event:UncaughtErrorEvent):void
    {
        var message:String; 
        if (event.error is Error) { 
            message = Error(event.error).message; 
            message+="\n"+Error(event.error).getStackTrace();
        } else if (event.error is ErrorEvent) { 
            message = ErrorEvent(event.error).text;
        } else { 
            message = event.error.toString(); 
        } 
    }

当时这样做每次得到的结果却是这样的

	at xxx/uncaughtErrorHandler()

堆栈显示不全，但这不是我们想要的结果。解决办法就是将下面这一行

	message+="\n"+Error(event.error).getStackTrace();

改为

	message+="\n"+event.error.getStackTrace();

去掉强制转换就行了。


----------


**2.重启AIR程序**

重启AIR程序，这个问题似乎很好解决，百度或者Google之，发现几乎所有的相关文章都介绍了使用ProductManager的相关api实现。具体的实现参考[http://blog.domlib.com/articles/577.html](http://blog.domlib.com/articles/577.html)

可是这个方法有时并不管用。

比如嵌入运行时的本地AIR程序，这种程序需要在应用程序描述文件里面配置

    <supportedProfiles>extendedDesktop</supportedProfiles>

打包好的程序在Windows下面是一个exe程序，mac下是一个app文件夹。这种程序的重启似乎有点麻烦，不过下面的代码确实能使程序重启。

	var id:String = NativeApplication.nativeApplication.applicationID;
	var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
	if(Capabilities.os.indexOf("Mac OS")>=0)
		info.executable = new File(File.applicationDirectory.nativePath).parent.resolvePath("MacOS/"+id);
	else
		info.executable = File.applicationDirectory.resolvePath(id+".exe");
	var process:NativeProcess = new NativeProcess();
	process.start(info);
	NativeApplication.nativeApplication.exit();

没错，先打开程序，然后立马执行退出就是重启。不过这种方式之所以生效还是有一定道理的，NativeProcess是系统级的东西，系统执行的时候有一定延迟，而exit是立马就生效的。