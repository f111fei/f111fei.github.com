title: gulp流式操作
categories: nodejs
date: 2016-04-09 17:26:41
tags: [nodejs,gulp]
---

对于很多刚刚接触[gulp](https://github.com/gulpjs/gulp)的人来说，常常觉得gulp中的stream操作不可理解。本篇将介绍stream在gulp中的应用，探究gulp中的流式操作。

一般来说gulp插件开发或者自定义任务都需要借助一些stream的包装模块。比较常用的有[event-stream](https://github.com/dominictarr/event-stream) 和 [through2](https://github.com/rvagg/through2)。

<!--more-->

下面通过一个简单的task来熟悉这两个模块的用法。先得到如下目录结构：

	├── node_modules
	│   ├── gulp
	│   ├── through2
	│   └── event-stream
	├── media
	│   ├── one
	│   │	└── 1.txt
	│   └── two
	│		├── 2.txt
	│		└── 3.txt
	├── gulpfile.js
	└── package.json

我们的目标是将所有的txt文件合并成一个文件out.txt，并输出到目录dist。

首先创建gulp任务：

	var es = require('event-stream');
	var through = require('through2');
	var rimraf = require('rimraf');
	var gulp = require('gulp');

	function use_es_through() {
		//TODO
	}

	function use_es_map() {
		//TODO
	}
	
	function use_through2_obj() {
		//TODO	
	}

	function concat(fn) {
		return function () {
			return gulp.src(['media/**/*.txt'])
				.pipe(fn())
				.pipe(gulp.dest('dist'));
		};
	}
	
	gulp.task('clean', function (cb) {
		rimraf('dist', cb);
	});
	
	gulp.task('concat1', ['clean'], concat(use_es_through));
	gulp.task('concat2', ['clean'], concat(use_es_map));
	gulp.task('concat3', ['clean'], concat(use_through2_obj));

这里用到了`gulp.task`定义了4个任务。用法为：

    gulp.task(name[, deps], fn)

`name` 任务的名字，之后可以通过 `gulp %taskname%` 的方式来执行该任务。

`deps` 一个包含任务列表的数组，这些任务会在你当前任务运行之前完成。

`fn` 该函数定义任务所要执行的一些操作。如果该函数接受一个callback参数，当任务结束时需要调用callback，如上`clean`任务的用法。该函数也可以返回一个`stream`或者`Promise`对象，`concat`这个函数便是返回的`stream`对象。

`concat`接受一个function参数，执行实际的合并操作。这个function返回一个`WritableStream`作为`pipe`的参数。这里定义了`use_es_through`， `use_es_map`， `use_through2_obj`三个函数演示stream的操作。

### vinyl文件系统

虽然gulp使用的是stream，但却不是普通的Node Stream，实际上，gulp(以及gulp插件)用的应该叫做[Vinyl File Object Stream](https://github.com/gulpjs/vinyl)。这里的Vinyl，是一种虚拟文件格式。Vinyl主要用两个属性来描述文件，它们分别是路径(`path`)及内容(`contents`)。具体来说，Vinyl并不神秘，它仍然是js对象。Vinyl官方给了这样的示例：

	var File = require('vinyl');
	
	var coffeeFile = new File({
	  cwd: "/",
	  base: "/test/",
	  path: "/test/file.coffee",
	  contents: new Buffer("test = 123")
	});

从这段代码可以看出，Vinyl是Object，`path`和`contents`也正是这个Object的属性。

File的`contents`可以是Stream或者Buffer。一般来说在gulp中，都是一个Buffer对象。在gulp的插件规范中，对于`contents`是Stream的情况也是要做判断的，表示该插件是否支持Stream的File对象。如：

	// we don't do streams (yet)
    if (file.isStream()) {
      this.emit('error', new PluginError('gulp-concat',  'Streaming not supported'));
      cb();
      return;
    }

通过`path`和`base`可以得到一个新的属性`relative`，表示相对与基本目录的相对路径。

关于File的更多属性及方法请参考[官方文档](https://github.com/gulpjs/vinyl#constructoroptions)。

gulp管道中传输的数据单位就是File对象。通过修改File属性的path或者contents来实现最终效果。


### event-stream

#### through (write?, end?)

一般用法如下：

	es.through(function write(data) {
	    this.emit('data', data);
	  },
	  function end () { //optional
	    this.emit('end');
	  })

`write` 管道中每有一个data数据都会调用此方法。接受一个data参数，在方法体里面可以对data进行操作，最后通过 `this.emit('data', data)` 将数据提交，否则数据无法进入下一个`pipe`操作。在gulp中，这里的data即是上文所说的File对象。注意到write方法并没有callback参数，所以该方法是**同步**的，最好**不要在该方法里面包含异步操作**。例如像下面这样就是错误的：

	es.through(function write(data) {
		  var self = this;
		  // 执行异步的操作
		  setTimeout(function() {
			self.emit('data', data);
		  }, 10);
	  },
	  function end () { //optional
	    this.emit('end');
	  })

`end` 在所有数据完成了pipe之后调用，只会调用一次。最后应当加上 `this.emit('end');` 表示调用已结束，但是这里就可以在调用了一个异步方法之后派发end事件。

	gulp.task('default', function () {
		return gulp.src(['media/**/*.txt'])
			.pipe(es.through(function (file) {
				gutil.log('write: ' + file.relative);
				this.emit('data', file);
			}, function () {
				var self = this;
				setTimeout(function () {
					gutil.log('It is end');
					self.emit('end');
				}, 1000);
			}))
			.pipe(gulp.dest('dist'));
	});

以上代码将media将所有txt文件复制到dist目录下，这里插入了一个`es.through`方法来输出gulp的执行顺序。执行`gulp`，输出如下：

	[00:34:13] Starting 'default'...
	[00:34:13] write: one\1.txt
	[00:34:13] write: two\2.txt
	[00:34:13] write: two\3.txt
	[00:34:14] It is end
	[00:34:14] Finished 'default' after 1.03 s

可以看到`es.through`的write方法被执行了3次，最后才会执行end方法，并且直到派发了end事件才会结束。

`es.through`的这两个参数都是可选参数。

	es.through();

等价于

	es.through(function(data) {
		this.emit('data', data);
	}, function() {
		this.emit('end');
	});


我们再来看一下如何使用`es.through`将这三个文件合并成一个，代码如下：

	function use_es_through() {
		var contents = [];
	
		return es.through(function (file) {
			gutil.log('I am: ' + file.relative);
			contents.push(file.contents);
			contents.push(new Buffer('\n'));
		}, function () {
			var joinedContents = Buffer.concat(contents);
			var output = new File();
			output.contents = joinedContents;
			output.path = 'out.txt';
			this.emit('data', output);
			
			gutil.log('It is concated');
			this.emit('end');
		});
	}

在write方法中并没有使用`this.emit('data', file);`提交当前的文件，只是将文件的`contents`保存到一个数组中。在最后的end方法中，将所有的contents使用`Buffer.concat`合并，并构造一个File对象，设置`contents`为合并后的内容，然后设置`path`，最后调用`this.emit('data', output);`(也可以换成`this.push(output);`)。

执行`gulp concat`，输出如下：

	[00:36:47] Starting 'clean'...
	[00:36:47] Finished 'clean' after 4.67 ms
	[00:36:47] Starting 'concat1'...
	[00:36:47] I am: one\1.txt
	[00:36:47] I am: two\2.txt
	[00:36:47] I am: two\3.txt
	[00:36:47] It is concated
	[00:36:47] Finished 'concat1' after 25 ms

#### map (asyncFunction)

这个方法解决了`es.through`中的write不能异步的问题。

	var es = require('event-stream')
	es.map(function (data, callback) {
	  //transform data
	  // ...
	  callback(null, data)
	})

当异步/同步操作完成时，一定要调用callback。callback的第一个参数为一个error或者null。第二个参数为返回的数据。

使用`es.map`实现文件合并

	function use_es_map() {
		var contents = [];
		return es.map(function (file, cb) {
			gutil.log('I am: ' + file.relative);
			contents.push(file.contents);
			contents.push(new Buffer('\n'));
			cb();
		}).pipe(es.through(null, function () {
			var joinedContents = Buffer.concat(contents);
			var output = new File();
			output.contents = joinedContents;
			output.path = 'out.txt';
			this.emit('data', output);

			gutil.log('It is concated');
			this.emit('end');
		}));
	}

运行`gulp connat2`。输出结果如下：

	[00:38:52] Starting 'clean'...
	[00:38:52] Finished 'clean' after 6.25 ms
	[00:38:52] Starting 'concat2'...
	[00:38:52] It is concated
	[00:38:52] Finished 'concat2' after 29 ms

仔细看下输出结果会发现没有`es.map`中的输出信息，也就是`es.map`的回调并没有执行。再看一下输出目录dist，居然出现了3个txt文件，而且out.txt内容是空的。Oh My Bug。

查看一下node关于pipe的定义：

	export class Readable extends events.EventEmitter implements NodeJS.ReadableStream {
		pipe<T extends NodeJS.WritableStream>(destination: T, options?: { end?: boolean; }): T;
	}

`Readable`的`pipe`方法接受一个`WritableStream`的对象参数，最后返回的就是这个参数`WritableStream`。`es.through`和`es.map`返回的都是一个`ReadWriteStream`对象，所以既可以作为`pipe`的参数，也能使用`pipe`方法，实现链式调用。

上面的那段错误代码，返回的实际上就是`es.through`的结果，等价于：

	function use_es_map() {
		var contents = [];
		return es.through(null, function () {
			var joinedContents = Buffer.concat(contents);
			var output = new File();
			output.contents = joinedContents;
			output.path = 'out.txt';
	
			this.emit('data', output);
			this.emit('end');
		});
	}

那怎么样才能使用`es.map`实现这个合并呢？

	function use_es_map() {
		var contents = [];
	
		var input = es.through();
		var output = input
			.pipe(es.map(function (file, cb) {
				gutil.log('I am: ' + file.relative);
				contents.push(file.contents);
				contents.push(new Buffer('\n'));
				cb();
			}))
			.pipe(es.through(null, function () {
				var joinedContents = Buffer.concat(contents);
				var output = new File();
				output.contents = joinedContents;
				output.path = 'out.txt';
				this.emit('data', output);
				
				gutil.log('It is concated');
				this.emit('end');
			}));
		return es.duplex(input, output);
	}

简化成伪代码：

	var input = es.through();
	var output = input
		.pipe(ReadWriteStream1)
		.pipe(ReadWriteStream2);
	return es.duplex(input, output);

同样这段代码也等价于：

	var input = es.through();
	var output = ReadWriteStream2；
	input
		.pipe(ReadWriteStream1)
		.pipe(output);
	return es.duplex(input, output);

这里有一个`es.duplex`方法。

#### duplex (writeStream, readStream)

这个函数返回一个新的`ReadWriteStream`对象，由第一个参数作为writeStream，第二个参数作为readStream。

当接收到来自`gulp.src`的数据(3个txt的File对象)时，流入到input中，通过两个pipe加工处理，输出为output(out.txt)。同时output又作为可读取的输入流，pipe到`gulp.dest`中。

> PS: 这段可能比较难以理解，请自行脑补管道中数据的流动过程。


用好`event-stream`中的这三个方法，妈妈再也不用担心我不会gulp了。更多`event-stream`的用法请参阅[官网文档](https://github.com/dominictarr/event-stream)

### gulp中流的执行顺序

下面再通过一个例子来说明下gulp中的执行顺序：

	gulp.task('default', function () {
		var first;
	
		return gulp.src(['media/**/*.txt'])
			.pipe(es.through(function (file) {
				gutil.log('1: ' + file.relative);
				if (!first) {
					first = file;
				} else {
					this.emit('data', file);
				}
			}, function () {
				var self = this;
				gutil.log('It is first end');
				setTimeout(function () {
					self.emit('data', first);
					self.emit('end');
				}, 1000);
			}))
			.pipe(es.map(function (file, cb) {
				gutil.log('2: ' + file.relative);
				setTimeout(function () {
					cb(null, file);
				}, 2000);
			}))
			.pipe(es.through(function (file) {
				gutil.log('3: ' + file.relative);
				this.emit('data', file);
			}, function () {
				gutil.log('It is last end');
				this.emit('end');
			}))
			.pipe(gulp.dest('dist'));
	});

这里使用了3个pipe，结果如下：

	[00:36:51] Starting 'default'...
	[00:36:51] pipe1: one\1.txt
	[00:36:51] pipe1: two\2.txt
	[00:36:51] pipe2: two\2.txt
	[00:36:51] pipe1: two\3.txt
	[00:36:51] pipe2: two\3.txt
	[00:36:51] It is first end
	[00:36:52] pipe2: one\1.txt
	[00:36:53] pipe3: two\2.txt
	[00:36:53] pipe3: two\3.txt
	[00:36:54] pipe3: one\1.txt
	[00:36:54] It is last end
	[00:36:54] Finished 'default' after 3.04 s

可以得出以下结论：

- 如果在write方法中不提交数据，那么数据不会出现在下一个pipe的write中。
- 数据在管道中的流动速度是不确定的，特别是遇到了异步方法，先处理的数据在某个步骤之后可能会落后于某个后处理的数据。 
- 每一个数据在管道中是按照pipe的顺序流动的。即`pipe1 -> pipe2 -> pipe3`
- 当遇到了异步方法(如`es.map`)，会触发end。即`pipe1 -> pipe2(异步) -> pipe1(end)`
- 在end方法中也可以派发data事件，提交数据。并且提交的数据会进入下一个pipe。即`pipe1(end)(this.push(data)) -> pipe2`


### through2

`through2`的用法与`event-stream`类似

	function use_through2_obj() {
		var contents = [];
	
		return through.obj(function (file, enc, cb) {
			gutil.log('I am: ' + file.relative);
			contents.push(file.contents);
			contents.push(new Buffer('\n'));
			cb();
		}, function (cb) {
			var joinedContents = Buffer.concat(contents);
			var output = new File();
			output.contents = joinedContents;
			output.path = 'out.txt';
			this.push(output);
	
			gutil.log('It is concated');
			cb();
		});
	}

主要区别有：

- `through`使用`push`方法或者`callback`的第二个参数提交数据。`event-stream`除了使用以上方法还可以使用`emit`来提交数据。
- `through`天生就是异步的，所有参数都需要一个callback回调表示是否完成。而`event-stream`的某些api的使用方法也支持同步。


其实本篇实现的合并功能已经有现成的插件支持，可以看看[gulp-concat](https://github.com/contra/gulp-concat)这个插件的源码学习一下。


**示例项目**：

[下载地址](https://coding.net/u/xzper/p/xzper/git/raw/master/.hexo_source/source/resource/2016/05/gulp-stream-test.zip)


**参考文章**：

[Gulp 中文网](http://www.gulpjs.com.cn/)

[探究Gulp的Stream](http://www.codesec.net/view/193349.html)

[Gulp.js深入讲解](http://ju.outofmemory.cn/entry/69523)
