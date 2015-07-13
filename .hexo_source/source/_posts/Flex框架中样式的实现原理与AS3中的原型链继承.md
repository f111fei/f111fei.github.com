title: Flex框架中样式的实现原理与AS3中的原型链继承
categories: ActionScript3
date: 2014-10-25 13:53:06
tags:
---
在Flex中setStyle这个特性特别好用，当一个容器Group的样式时，那么这个容器的子项的样式也会跟着起作用。比如设置Application的`fontSize`这个样式为20，那么如果不显式设置子项的`fontSize`，子项的字体大小就都会是20，而不用每次子项再去重复设置了，这个特性对于开发者来讲是至关重要的，能减少很多重复的代码。而这个特性的实现，离不开原型链继承这个重要概念。

<!--more-->

原型链继承这个词已经不是陌生词汇了，对于JS程序员来说更是再熟悉不过了。AS3作为一个面向对象的脚本语言，原型链继承早已淡出AS3程序员的视野。说到AS语言，其实AS1，AS2都很像JS，AS3则来了个180°转变，变成了面向对象了。早在AS1，AS2的时代，对象间的继承就是使用原型链继承的方式实现的，事实上这一特性也得到了保留，AS3也可以使用这种方式实现继承。

----------

下面我们来看一个神奇的DEMO来体会原型链继承。先上代码

	private function styleTest():void
	{
		var parentStyle:Object = 
			{
				"fontSize":12 , 
				"fontColor":0xffffff , 
				"fontFamily":"微软雅黑"
			};
		
		var childStyle:Object = addStyleToProtoChain(parentStyle);
		childStyle["fontSize"] = 20;
		childStyle["fontWeight"] = "bold";
		
		parentStyle["fontSize"] = 18;
		parentStyle["fontFamily"] = "宋体";
		
		trace("-----以下为parent的样式信息-----");
		traceObject(parentStyle);
		
		trace("-----以下为child的样式信息-----");
		traceObject(childStyle);
	}
	
	/**
	 * 将样式信息添加到原型链
	 * @param originalStyle 原始样式 
	 * @return 原始样式的子样式
	 */
	private function addStyleToProtoChain(originalStyle:Object):Object
	{
		var inheritStyle:Object;
		var factory:Function = function():void{};
		factory.prototype = originalStyle;
		inheritStyle = new factory();
		factory.prototype = null;
		return inheritStyle;
	}
	
	/**
	 * 打印排序后的对象的属性
	 */
	private function traceObject(obj:Object):void
	{
		var keys:Array = [];
		var valueMap:Object = {};
		
		for(var key:String in obj)
		{
			if(keys.indexOf(key)>=0)
				continue;
			keys.push(key);
			valueMap[key] = obj[key];
		}
		keys.sort();
		for each (key in keys)
		{
			trace(key+":"+valueMap[key]);
		}
	}

程序定义了两个对象`parentStyle`和`childStyle`来存储一些样式属性。通过`addStyleToProtoChain`将`parentStyle`加入到`childStyle`原型链中，然后不断改变这两个对象的属性，最后输出两个对象的结果。在答案揭晓之前我们先来分析一下每个属性的设置过程。

####`fontSize`
`fontSize`这个属性在`parentStyle`初始化时为12，后来在`childStyle`中设置为20，最后`parentStyle`中又重新设置为18。 那么最后childStyle的`fontSize`是多少呢?是12，还是20，还是18?

####`fontColor`
`fontColor`只有在`parentStyle`初始化时设置了一次为`0xffffff`,并没有在`childStyle`中设置，那么最终`childStyle`中会有这个属性吗?

####`fontFamily`
`fontFamily`被设置两次，初始化时为`微软雅黑`，后来设置成了`宋体`，都在`parentStyle`的属性中设置的。同样那么最终`childStyle`会有这个属性吗，有的话值是多少呢?是`微软雅黑`还是`宋体`?

####`fontWeight`
`fontWeight`这个属性只在`childStyle`进行了设置，那么最终`parentStyle`会有这个属性吗?

----------

那么答案揭晓，控制台输出如下：

    -----以下为parent的样式信息-----
    fontColor:16777215
    fontFamily:宋体
    fontSize:18
    -----以下为child的样式信息-----
    fontColor:16777215
    fontFamily:宋体
    fontSize:20
    fontWeight:bold

结果是否出人意料?

其实最终的结果可以可以归纳为child的改变不会影响parent的属性，而parent的属性改变**可能**会影响到child的属性。这个可能分两种情况，一种情况是child没有这个属性，parent改变了child就会跟着改变，再一种就是child有这个属性parent改变了不会影响child。

为什么`fontColor`，`fontFamily`这类的在`parentStyle`中定义，会在`childStyle`中出现呢，因为`childStyle`的原型链是`parentStyle`，当在自身找不到这个属性时，就会从原型链里面找，直到找到为止。

----------

我们再来看一下是如何将`parentStyle`设置成`childStyle`的原型链的。将`addStyleToProtoChain`执行的操作翻译过来就是下面这样

	var factory:Function = function():void{};
	factory.prototype = parentStyle;
	childStyle = new factory();
	factory.prototype = null;

----------

这种原型链的描述方式完全符合Flex样式的设计思想。Flex的每个组件都持有两套样式表，可继承的样式和不可继承的样式。不可继承的样式不做传递，可继承的样式会添加到原型链中。当一个容器的子组件被添加的时候，子组件的样式表会被重新初始化，将父级的样式表添加到自己的原型链，然后添加自己的样式。最终自己的样式改变不会影响父级，父级的样式改变，如果自己没有显式定义就会跟随父级改变。关于Flex样式的原理详细的可以看下面的参考文章。

本文代码下载: [Click Me](http://xzper.qiniudn.com/2014%2F10%2FStyleTest.zip)

参考文章：

[1] [Flex样式工作原理](http://blog.csdn.net/terryzero/article/details/4581459)

[2] [AS3 面向对象 高级话题](http://blog.csdn.net/holybozo/article/details/1345606)