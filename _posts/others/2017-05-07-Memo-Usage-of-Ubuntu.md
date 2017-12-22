---
layout: post
date: 2017-05-07 15:10
status: public
title: '[参考]Ubuntu使用记录'
categories: [others]
tags: []
description: 
---

记录一些自己用到的Ubuntu零碎知识点

使用的系统是ubuntu 16.04 LTS

![20170507_1]({{ site.url }}/images/20170507_1.png)

* 目录 
{:toc}

# 修改环境变量

修改 /etc/environment 文件，直接添加`变量名='变量值'`的方式修改，不需要export，这个文件修改的是整个系统的环境。

> 修改这个文件需要root权限，可以在terminal中使用vim修改，也可以复制到其他地方然后粘贴回etc文件夹。
> 粘贴命令可以使用：`sudo cp -f '/home/junmo/桌面/environment' '/etc/environment' `

参考：
- [设置Linux环境变量的方法和区别_Ubuntu_给力星](http://www.powerxing.com/linux-environment-variable/)

# 命令行安装软件

执行指令：

``` sh
sudo dpkg -i [名称].deb
```

> **注：dpkg命令无法自动解决依赖关系。如果安装的deb包存在依赖包，则应避免使用此命令，或者按照依赖关系顺序安装依赖包。**

参考：
- [ubuntu下如何用命令行运行deb安装包 - windtail - 博客园](http://www.cnblogs.com/windtail/archive/2012/06/02/2623175.html)

# 删除Ubuntu升级后旧的内核文件

每次Ubuntu更新的时候会下载新的内核文件，但是安装之后并没有自动删除旧的文件，导致Ubuntu的这个分区会磁盘空间不足

首先使用```dpkg --get-selections|grep linux-image```找到内核文件

![20170507_2]({{ site.url }}/images/20170507_2.png)

使用```sudo apt-get remove linux-image-{版本号}-generic```删除对应的文件（注意修改版本号）

![20170507_3]({{ site.url }}/images/20170507_3.png)

删除之后再查看就会发现删除的这个被标记为了deinstall

![20170507_4]({{ site.url }}/images/20170507_4.png)

> 实际操作的时候不需要每删除一个就使用```dpkg --get-selections|grep linux-image```查看一下，在删除之后会提示还有哪些旧的文件，按照删除过程中给的信息就行了，或者直接去/boot目录中看还有哪些剩余
不过不确定版本号最大的那个能不能删除，没有做过测试

参考：
- [ubuntu boot空间不足的解决方法](http://blog.csdn.net/yypony/article/details/17260153)


# 重新安装后的操作

> 这部分是个人习惯，仅作为备忘

1. 修改快捷键
	- 启动终端（系统设置 - 键盘 - 快捷键）
	- 切换输入法（系统设置 - 文本输入）
2. 修改电源选项（系统设置 - 电源）
3. 修改窗口菜单栏位置（系统设置 - 外观 - 行为 - 显示窗口菜单）
4. 开启工作区（系统设置 - 外观 - 行为 - 开启工作区）
5. 修改终端复制粘贴快捷方式（终端菜单栏 - 编辑 - 首选项 - 快捷键）
6. 调整输入法
	- System Settings - Language Support - Keyboard input method system 改成fcitx
7. 安装git，同步.gitconfig文件（C:\Users\MyLogin\.gitconfig -> ~/.gitconfig）

# 查看以及杀掉进程

查看名字中包含python的进程：

``` sh
ps -ef | grep python
```

![20170507_5]({{ site.url }}/images/20170507_5.png)

第二列为进程的pid，杀掉进程的指令是：```kill -s 9 [pid]```

执行后没有输出就表明结束进程成功

参考：
- [Linux中Kill进程的N种方法](http://blog.csdn.net/smarxx/article/details/6664219)

# 查看内存(memory)使用量

可以使用htop

安装：

``` sh
sudo apt-get install htop
```

使用：

``` sh
htop
```

# Python包安装

## 常用

下面这些是可以直接安装的，目前没有发现什么问题：
- numpy
- tensorflow/tensorflow_gpu
- matplotlib

``` sh
pip install numpy
```

## scipy

安装之前或之后需要安装pil或者pillow，否则无法使用imread

``` sh
pip install pillow
pip install scipy
```

## gym

``` sh
sudo apt-get install -y python-numpy python-dev cmake zlib1g-dev libjpeg-dev xvfb libav-tools xorg-dev python-opengl libboost-all-dev libsdl2-dev swig

pip install gym[all]
```

## opencv

``` sh
pip install opencv-python
```

> 还有一种安装方式是： <http://www.pyimagesearch.com/2016/10/24/ubuntu-16-04-how-to-install-opencv/> 似乎是编译源码的安装方式，不知道使用上有什么区别

参考：
- [cannot import name imread · Issue #1 · Newmu/stylize](https://github.com/Newmu/stylize/issues/1)
- [openai/gym: A toolkit for developing and comparing reinforcement learning algorithms.](https://github.com/openai/gym#installing-everything)
- [opencv-python 3.3.0.10 : Python Package Index](https://pypi.python.org/pypi/opencv-python)

# screen使用

新建并且指定screen名字：

To create a new screen with the name foo, use

``` sh
screen -S foo
```

Then to reattach it, run

``` sh
screen -r foo  # or use -x, as in
screen -x foo  # for "Multi display mode" (see the man page)
```

列出所有screen：

``` sh
screen -ls
```

参考：
- [linux - How to assign name for a screen? - Stack Overflow](https://stackoverflow.com/questions/3202111/how-to-assign-name-for-a-screen)

