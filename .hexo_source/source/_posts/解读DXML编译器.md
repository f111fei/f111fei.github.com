title: 解读DXML编译器
categories: [FlexLite,ActionScript3]
date: 2014-07-02 16:22:49
tags: 
---

DXML就是FlexLite中由FlexLiteStdio生成的皮肤文件，类似于Flex中的MXML。实际上区别没多少，可能最大的区别就是MXML支持Script脚本。DXML架构设计对编写各类UI编辑器，各类代码生成工具都有很好的参考价值。这里主要分析DXML编译器是如何将DXML文件转换为as代码。

<!--more-->

**1.如何使用DXML编译器**

DXML编译器在源代码在FlexLiteExtends中的org.flexlite.domCompile包下。导入相应的类后，先导入配置文件manifest.xml(这个文件可以在FlexLiteStdio的安装目录的bin文件夹下可以找到，也可以通过ManifestUtil这个类生成)。这是一个全局静态属性，导入代码如下:

	DXMLCompiler.configData = manifestXml;

然后创建一个DXMLCompiler实例，调用compile方法得到编译后的结果:

	var compiler:DXMLCompiler = new DXMLCompiler();
	var result:String  = compiler.compile(buttonSkinXml , "Button");

完整的代码如下:

	public class DXMLCompilerTest extends Sprite
	{
		[Embed(source="resource/xml/flexlite-manifest.xml" , mimeType = "application/octet-stream")]
		private var manifest:Class;

		[Embed(source="resource/xml/ButtonSkin.dxml" , mimeType = "application/octet-stream")]
		private var buttonSkin:Class;

		public function DXMLCompilerTest()
		{
			super();

			var manifestBy:ByteArray = new manifest();
			//flexlite-manifest.xml对象
			var manifestXml:XML = XML(manifestBy.readUTFBytes(manifestBy.length));

			var buttonSkinBy:ByteArray = new buttonSkin();
			//ButtonSkin.dxml对象
			var buttonSkinXml:XML = XML(buttonSkinBy.readUTFBytes(buttonSkinBy.length));

			//flexlite-manifest框架清单文件
			DXMLCompiler.configData = manifestXml;

			var compiler:DXMLCompiler = new DXMLCompiler();
			var result:String  = compiler.compile(buttonSkinXml , "Button");
			trace(result);
		}
	}

**2.配置文件manifest**

manifest是由编译器使用的配置文件，定义了编译器能识别的各类组件。

    <componentPackage crc32="a32782dd">
		<component id="ArrayCollection" p="org.flexlite.domUI.collections.ArrayCollection" s="flash.utils.Proxy" d="source" array="true"/>
		<component id="Button" p="org.flexlite.domUI.components.Button" s="org.flexlite.domUI.components.supportClasses.ButtonBase" show="true"/>
		<component id="ButtonBase" p="org.flexlite.domUI.components.supportClasses.ButtonBase" s="org.flexlite.domUI.components.SkinnableComponent" d="label" state="up,over,down,disabled"/>
		<component id="Group" p="org.flexlite.domUI.components.Group" s="org.flexlite.domUI.components.supportClasses.GroupBase" d="elementsContent" show="true" array="true"/>
    </componentPackage>

以上节选自flexlite-manifest.xml。manifest.xml由各类component组成，包括但不限于UI组件。主要是用来配置对dxml文件中可能出现的节点的定义供编译器解析。component节点对应编译器中的Component类，各个属性解释如下

**id**，这个组件的短名ID，对应Component的id属性

**p**，组件的完整类名，对应Component的className属性

**s**，父级类名，对应Component的superClass属性

**d**，默认属性，对应Component的defaultProp属性，这个实际就是表示这个组件的子节点对应的属性

**array**，默认属性是否为数组类型，对应Component的isArray属性

**states**，视图状态列表，对应Component的states属性

比如：

	<dx:Group left="16" right="16" top="41" id="contentGroup" bottom="42"/>
		<dx:Label text="标签" size="14" maxWidth="310" textColor="0xFFFFFF"/>
	</dx:Group>

这里有一个Group组件，然后对应一个子节点Label。那么Group的defaultProp也就是elementsContent这个属性对应的值是个数组，其中的一项就是Label。同理，比如ArrayCollection节点有子节点，那么source属性对应的值就是这些子节点。

**2. 代码定义CodeBase**

CodeBase是代码定义的基类，其中的toCode方法就是生成代码的关键。编译器中扩展了CodeBase实现了各种代码定义，比如注释，变量定义，参数定义，函数定义，类定义和代码块。这里挑几个重点的说:

**函数定义CpFunction**。一个函数主要由 修饰符(private,protected,public)，函数名 ，参数列表(CpArguments数组)和代码块(CpCodeBlock)组成。另外还有一些override，static之类的关键词标示符。

**代码块CpCodeBlock**。代码块就是函数中的内容，主要提供了一些添加语句的方法，比如 添加变量声明语句addVar，添加赋值语句addAssignment，添加一行代码addCodeLine等。开发者调用这些方法从而完成代码块的内容。

**类定义CpClass**。定义了一个类的代码，类的组成主要有 定义部分(例如:类注释， 类名，包名，修饰符，父类，接口)，导入包区块，构造函数，成员变量，成员函数。CpClass提供各种方法来完善这些内容，比如:导入包addImport，添加变量addVariable，添加函数addFunction。

有了这些，在完成类中各个区块的定义和赋值之后，调用toCode方法转换成as代码。

**3.解析配置文件DXMLConfig**

manifest.xml的解析交给DXMLConfig来完成，DXMLConfig解析完成后存储配置文件中的组件对应的基本属性已经映射关系。解析完成后，外界可以使用的主要方法有:
	/**
	 * 根据类的短名ID和命名空间获取完整类名(以"."分隔)
	 * @param id 类的短名ID
	 * @param ns 命名空间
	 */				
	function getClassNameById(id:String,ns:Namespace):String;

	/**
	 * 根据ID获取对应的默认属性
	 * @param id 类的短名ID
	 * @param ns 命名空间
	 * @return {name:属性名(String),isArray:该属性是否为数组(Boolean)}
	 */		
	function getDefaultPropById(id:String,ns:Namespace):Object;

	/**
	 * 获取指定属性的类型,返回基本数据类型："uint","int","Boolean","String","Number","Class"。
	 * @param prop 属性名
	 * @param className 要查询的完整类名
	 * @param value 属性值
	 */			
	function getPropertyType(prop:String,className:String,value:String):String;

**4.了解DXML文件结构**

在了解编译器是如何工作之前，需要了解DXML文件的结构。这里通过一个典型例子来了解DXML的结构。

	<xml version="1.0" encoding="utf-8">
	<dx:StateSkin width="100" xmlns:dx="http://www.flexlite.org/dxml/2012" xmlns:fs="http://www.flexlite.org/studio/2012">
		<fs:HostComponent name="org.flexlite.domUI.components.Button"/>
		<fs:Declarations>
			<dx:DropShadowFilter alpha="1.00" angle="0.00" blurY="4" color="0x000000" quality="1" blurX="4" hideObject="false" distance="0" inner="false" strength="10" knockout="false" id="__DropShadowFilter0"/>
		</fs:Declarations>
		<dx:states>
			<dx:State name="up"/>
			<dx:State name="over"/>
			<dx:State name="down"/>
			<dx:State name="disabled"/>
		</dx:states>
		<dx:UIAsset left="0" y="0" top="0" right="0" skinName="DXR__1C5D2D62" bottom="0" x="0" includeIn="disabled"/>
		<dx:UIAsset left="0" top="0" bottom="0" skinName="DXR__276F2CB5" right="0" includeIn="up"/>
		<dx:UIAsset left="0" top="0" bottom="0" skinName="DXR__7905FD81" right="0" includeIn="down"/>
		<dx:UIAsset left="0" top="0" bottom="0" skinName="DXR__F2888F03" right="0" includeIn="over"/>
		<dx:Label paddingTop="4" id="labelDisplay" horizontalCenter="0" text="按钮" size="14" textAlign="center" paddingBottom="4" filters="{[__DropShadowFilter0]}" paddingLeft="10" bold="false" textColor="0xFFFFCD" paddingRight="10" fontFamily="FZShaoEr-M11S" verticalCenter="0"/>
	</dx:StateSkin>

**根节点**。每个DXML文件对应一个as类，根节点就是这个类定义，在这里可以定义类的属性以及对应的值。另外这里还有命名空间NameSpace的定义。默认的命名空间有dx和fs。命名空间主要用来快速区别节点，从而快速过滤对节点执行对应操作。

**声明节点**。DXML中一些不可视的一些元素可以定义在声明节点中，作为fs:Declarations这个节点的子节点。上述例子中的阴影滤镜就是在这个节点中。

**States节点**。States定义了组件的各个状态。

**组件节点**。一般以dx开头的节点就是组件节点，当然组件节点也可以自定义(使用自定义组件所在的包作为新的命名空间，添加到根节点中)。这里可使用的组件是和manifest.xml中对应的。在组件节点中可以对组件的各个属性赋值。另外，组件节点有一些共有的特殊属性，比如: id 表示组件对应的实例名，includeIn，excludeFrom表示组件对应的状态。还有上面提到的，组件如果有子节点，那么这些子节点就是组件对应的默认值。

**5.DXML编译器**

**编译开始的准备工作**

在编译开始前，创建DXMLConfig实例解析manifest配置，读取dxml文件。创建一个CpClass实例currentClass。

**编译开始**

调用startCompile编译开始，通过getStateNames方法获取dxml中定义的所有状态并使用stateCode保存。然后为根节点加入currentState的属性并赋值。使用declarations保存dxml的声明节点。然后调用addIds方法遍历各个节点添加成员变量以及函数。最后是生成构造函数。

**导入包，添加import区块**

包的导入，并不是一次性导入，而是贯彻在整个编译过程中。通常在调用getPackageByNode这个方法时来添加import区块。因为每个节点一般对应一个class，这样在分析节点时就能获取到节点的className，从而导入。

**依据id添加成员变量，以及自动为组件添加id属性**

某些节点具有id属性，那么一般这个节点对应的实例就是这个类的成员变量，实例名就是这个id的值，调用createVarForNode方法将节点添加进成员变量列表。某些组件没有id属性，那么调用createIdForNode给每一个组件节点加上id属性，赋值也遵循一定规范不会重复。另外有些组件是只存在于某些特定状态下的，这时会使用stateIds记录下来，随后在构造函数里面单独实例化。以上过程的具体实现参考addIds这个方法，整个过程是递归的。

**创建构造函数**

函数的主要内容就是代码块，首先创建一个代码块实例。通过addAttributesToCodeBlock方法解析根节点的所有属性，并生成赋值语句。解析declarations的子节点，调用createFuncForNode为每一个子节点创建对应的方法。使用initlizeChildNode方法遍历组件的子组件，对组件的默认属性赋值。最后解析状态代码，完成所有状态的赋值。

简而言之，解析一个组件的大致思路就是，通过addAttributesToCodeBlock方法解析节点的属性并赋值，然后使用initlizeChildNode方法遍历节点的子节点为默认属性赋值。在initlizeChildNode方法中调用createFuncForNode，为每个子节点创建单独的函数。而createFuncForNode这个方法中又会调用addAttributesToCodeBlock和initlizeChildNode解析节点属性和为默认属性赋值，如此递归调用下去。

**重要方法解析**

**createVarForNode**

创建成员变量。一般带有id的组件节点都会被调用这个方法创建对应id的实例名变量。

**addAttributesToCodeBlock**

解析组件的属性并赋值。对应一些特殊属性比如id，includeIn，locked已经带有”.”操作符的属性是不理会的。这样获取一个keyList，读取对应的value，格式化key和value然后添加赋值语句。有些key比较特殊比如height，因为对应的值可能是一个百分比所以需要格式化key转换成percentHeight。格式化value就比较麻烦了，有些value是带”{}”的要去掉{}，有些特殊的key比如skinName对应的value可能是一个class，这些key-value的转换规则通过DXMLConfig的getPropertyType来获取。最后如果对应的值是一个id即成员变量，则需要延迟赋值，到那个成员变量的创建函数中赋值。

**initlizeChildNode**

某些组件含有子节点，这些子节点就是这个组件对应的默认属性的值。这个方法首先获取直接子节点directChild，然后调用createFuncForNode，为每个子节点创建单独的函数。最后生成默认属性的赋值语句。对于一些包含状态的子节点是会被过滤掉的，因为有专门的状态生成代码。

**createFuncForNode**

实际上创建构造函数也是实现了这个方法。先调用addAttributesToCodeBlock，然后调用initlizeChildNode。只是创建构造函数多了一个解析声明节点和解析状态的过程。这个方法有一个创建构造函数没有的过程就是，添加一个变量声明(实际上就是实例化这个节点对应的类)，为节点的id属性赋值为这个节点变量。原来还会在延迟赋值字典里面加入对应的延迟赋值语句。

**createStates**

这个是在创建构造函数时被调用的，主要用来解析视图状态代码。本身是一个递归函数。遍历所有的子节点，找到那些在特定状态下出现节点。分解成每一个CpState填充进stateCode。