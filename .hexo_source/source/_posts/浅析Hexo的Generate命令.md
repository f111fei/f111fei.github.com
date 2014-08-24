title: 浅析Hexo的Generate命令
date: 2014-08-17 06:54:10
categories: Hexo
tags: Hexo
---
[Hexo](https://github.com/hexojs/hexo)是一个轻量级的静态博客站点生成框架，使用NodeJS开发。经过我两个通宵的努力总算把这个东西研究了一个大概，这里拿来分享一下。


<!--more-->

##Processor 
[Processor](http://hexo.io/docs/plugins.html#Processor)决定文件按照何种方式处理。在lib/plugins/processor文件夹下可以看到默认的处理方式。Processor在该模块的index.js中注册，默认的有下面几种

1. **post** 当文件是可渲染的，并且在_posts文件夹下的处理方式
2. **post_assets** 当文件是不可渲染的，并且配置文件中的"post\_asset\_folder"属性存在，并且在\_posts文件夹下的处理方式 
3. **page** 文件不在_posts下，当文件是可渲染时的处理方式
4. **assets** 文件不在_posts下，当文件是不可渲染时的处理方式

另外隐藏文件是不会被处理的。Processor会读取文件文件信息调用Renderer，将处理后的文件内容以及相关信息写入数据库。以便Generator读取。

##Renderer
[Renderer](http://hexo.io/docs/plugins.html#Renderer)将源文件转换成最终结果。在lib/plugins/renderer文件夹下可以看到默认的Renderer。默认的转换格式有html,htm,swig,yml等。另外hexo安装时会默认安装md,ejs和stylus的Renderer。

##Generator
[Generator](http://hexo.io/docs/plugins.html#Generator)根据Processor处理的结果生成静态文件。在lib/plugins/generator文件夹下可以看到默认的Generator。主要有下面几种

    generator.register('archive', require('./archive'));
    generator.register('category', require('./category'));
    generator.register('home', require('./home'));
    generator.register('page', require('./page'));
    generator.register('post', require('./post'));
    generator.register('tag', require('./tag'));
    generator.register('asset', require('./asset'));

每一种Generator会根据数据库中的数据，对数据进一步加工生成最后的文件。比如post和page中的内容是html，在生成阶段会根据对应主题在html的基础上加上头尾。而asset类型的，这时数据库中只有文件信息还没有文件内容，这时asset生成器将处理方式存入hexo.route中在之后的生成阶段使用route记录的处理方式获取内容然后复制到目标位置。

##Box
[Box](http://hexo.io/api/classes/Box.html)遍历Source文件夹下的所有文件，将具体文件分派给对应的Processor处理。

##Model
[Model](http://hexo.io/api/classes/Model.html)是Hexo的数据库和数据模型，由Processor和Renderer写入数据，Generator读取数据。数据库是使用的warehouse, 主要的表有

      model.register('Asset', schema.Asset);
      model.register('Cache', schema.Cache);
      model.register('Category', schema.Category, require('../model/category'));
      model.register('Page', schema.Page);
      model.register('Post', schema.Post, require('../model/post'));
      model.register('Tag', schema.Tag, require('../model/tag'));

每次生成都会在根目录生成一个db.json，这个就是数据库的结构了。

##Theme

[Theme](http://hexo.io/api/classes/Theme.html)是连接Hexo核心库的桥梁。特别是在生成阶段当前主题进一步加工有Renderer生成的内容，生成最终的文件。

##Route
[Route](http://hexo.io/api/classes/Router.html)有一个叫routes的属性，这是一个由文件路径作为key，和一个Function作为value的Map。这个Function的返回值就是文件的content。在生成阶段Generator会将最终数据存入这个Map里面。


##总结Hexo Generate命令的工作流程
* 用户终端输入命令 hexo generate。hexo启动，完成各模块初始化。 代码参见： [lib/plugins/console/generate.js](https://github.com/hexojs/hexo/blob/master/lib/plugins/console/generate.js)。
* Box遍历source文件夹中的文件，将要处理的文件分类。代码参见：[lib/box/index.js](https://github.com/hexojs/hexo/blob/master/lib/box/index.js) 和 [lib/plugins/processor/index.js](https://github.com/hexojs/hexo/blob/master/lib/plugins/processor/index.js)。
* 各Processor处理对应文件，需要渲染的文件交由对应的Renderer渲染。并将渲染的数据写入数据库。代码参见：[lib/plugins/processor/](https://github.com/hexojs/hexo/tree/master/lib/plugins/processor) 和 [lib/post/](https://github.com/hexojs/hexo/tree/master/lib/post)。
* 各Generator根据数据库中的数据，根据对应主题进一步加工，将数据存入Route，最后写入目标位置。代码参见：[lib/plugins/generator/](https://github.com/hexojs/hexo/tree/master/lib/plugins/generator) 和 [lib/theme/index.js](https://github.com/hexojs/hexo/blob/master/lib/theme/index.js)。

##一个小插件
明白了基本原理之后，现在要实现一个小插件。需求是我现在的站点有一个文件夹project专门存放项目代码。但是每次hexo generate 都将public文件夹清空，然后写入文件。所以project文件夹要放在source下面。这样generate生成的时候就将project复制到public里面了。但是这又有一个问题，project我的项目文件夹不可避免的有代码，有些html文件他会自动加上页头和页尾，这个很不好。于是这个插件的功能就是在 _config.yml 配置一个参数允许自定义那些文件夹的内容是不需要渲染的直接复制到public文件夹。 基本思路就是 自定义一个processor，注册一个rule，只要是在这个列表中的文件就按照asset的方式处理。 附上插件地址 : <https://github.com/f111fei/hexo-processor-copyassets>


##题外:搭建NodeJS调试环境
具体的步骤看这里:<http://blog.domlib.com/articles/686.html>。

这里我补充一下如何调试Hexo，其他的使用命令行的NodeJS调试也是同理。首先当然要下载好Hexo的源代码。然后比如源代码目录是 E:/workspace/hexo/ ，然后在该目录下执行 

    cd E:/workspace/hexo/
    npm install -g 

安装一下，这一步是从npm服务器下载Hexo的依赖库，不然调试的时候会报错找不到依赖库。
然后创建一个Hexo站点(已经有的忽略下面这一步，直接cd到你的站点目录)

    cd E:/workSpace/
    hexo init xzper.com

创建一个站点，这里假定站点目录是 E:/workSpace/xzper.com/ 。然后按照上面的教程，安装好调试工具并启动。

    npm install -g node-inspector
    node-inspector


 输入 node-inspector 启动调试工具。 最后最关键的一步，我们要调试hexo generate这个命令，那么在命令行中输入 

    cd E:/workSpace/xzper.com/
    node --debug-brk=5858 E:/workSpace/hexo/bin/hexo generate

这时按照提示打开Chrome输入 <http://127.0.0.1:8080/debug?port=5858> 断点会停在程序入口第一行，接下来你爱在哪设置断点就在哪设置。


##吐槽
我本来就得了一看JS代码就不好的病。然后这次为了搞懂Hexo，先初步学习了一下NodeJS，教程在[这里](http://www.open-open.com/lib/view/1392611872538)，不得不说本来就很讨厌的JS，再加上NodeJS最大的卖点-异步编程，那各种逼格极高的回调函数，看的我心花怒放，累觉不爱了。