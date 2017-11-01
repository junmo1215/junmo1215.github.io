---
date: 2016-12-22 21:25
status: public
title: '[笔记]Rethinking the Library OS from the Top Down'
layout: post
tag: [操作系统, OS]
categories: [paper]
description: 
---

[原文链接](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/asplos2011-drawbridge.pdf)

* 目录 
{:toc}

# 简介

本文用新的方式重新讨论了一个旧的操作系统架构——library OS。

library OS主要解决以下几个问题：
- 一个是与VM相同，希望能同一个应用程序运行在不同的操作系统上
- 另一个是希望有一个方法能方便的维护应用程序，比如之前很多XP系统的应用程序不能很好的兼容win7系统，大部分原因是这些应用程序有部分直接调用了系统的API，系统变化后API改变造成需要修改应用程序。LibOS希望能将这部分抽象化，类似于针对不同的系统能提供同一套API接口，保持API接口统一，更换操作系统的时候只需要统一维护这些LibOS就可以了。
- 还有可以方便的让应用程序在不同的电脑中切换，比如说在电脑A中编辑一个excel，中途需要切换到电脑B，通过library OS可以直接将整个程序的运行状态都切换到B中，而不是仅仅将数据迁移。

这种做法的中心思想是将LibOS和主机的OS相互分离，这种设计的好处在于:
- 将LibOS和主机的OS强封装，使得这两个在独自更新演进的时候没有太多的历史包袱，能够快速和独立的进行各自的升级
- 能够跨计算机迁移各个应用程序的运行状态，这点感觉有点像将整个LibOS和应用程序全部打包，由于这两个都不太大，所以能够实现跨计算机，而现有的OS架构不能达到这个效果的原因是应用程序的一部分运行数据在kernel层面，没有将这个与应用程序切割开，所以想要打包的话需要将整个OS都打包起来，由于体积过于庞大所以目前行不通，不过VMWare的迁移技术已经基本实现这个了，这个就是讲整个系统打包起来去另外一个计算机上接着运行，能减少程序宕掉的概率
- 能够更好的保护系统和应用程序的完整性，将系统的职能和应用程序的职能划分清楚，然后每个应用程序之间都是相互独立的，只能通过LibOS层面来进行相互通信，有点像目前的IOS系统里面将应用程序相互分离。

paper作者他们团队后面将windows7系统实作出了LibOS架构的模式，得出结论：有可能从功能丰富的商业操作系统构建一个运行主要应用程序的LibOS。

# Windows7架构

在之前windows架构中，一个应用程序可以直接调用win32 API(kernel32, user32, gdi32, ws2_32, ole32)，win32 api通过ntdll来操纵硬件。
win32k 实现窗口事件消息队列、重叠窗口、光栅化、字体管理和渲染、鼠标和键盘输入事件队列和共享剪贴板。

## DLL(Dynamic link libraries)

动态链接库提供了一种模块化的思想，无论是操作系统还是应用程序都能通过动态链接库提供一些功能和数据，当几个应用程序同时使用dll中的同一个功能的时候，也能节省memory的开销，虽然每个应用程序都复制了一份DLL中的数据，但是程序这一部分在是由这几个应用程序共享的。可以简单的理解为程序只往内存中加载了一次（其实准确来说可能不止一次，OS在回收memory page或者进行memory swap的时候可能会从内存中将这些代码剔除出去，下次有需要使用的时候会重新加载），但是每个应用程序用到的变量都会在自己独立的空间中重新声明一份。

目前windows的系统API接口就是以DLL的形式提供给应用程序使用的，所有的进程都能动态的链接到Windows的API

## Windows NT kernel

windows系统的kernel层面能访问所有的硬件资源，在保护内存区上执行代码。x86的硬体架构提供了四种CPU的优先级，从ring 0到ring 3，windows系统只使用了0和3，用户态的程序运行在ring 3，核心态的运行在ring 0

kernel指的是内核，处理多处理器同步，线程与中断的调度与分派，自陷处理，异常分派，在启动时初始化设备驱动程序等。作为整个操作系统的核心部分，处理的问题基本不能由第三方的软件或者LibOS来替代。严格地说，内核并不是计算机系统中必要的组成部分。程序可以直接地被调入计算机中执行；这样的设计，说明了设计者不希望提供任何硬件抽象和操作系统的支持；它常见于早期计算机系统的设计中。

## System Call

系统调用是执行系统核心代码的一种方式，用户编写的应用程序运行在ring 3上，但是类似于IO的操作或者进程间的通信都需要有ring 0的权限，这时就需要通过system call来执行ring 0的代码，这部分代码一般是操作系统已经实现好，提供调用的接口给应用程序。system call和普通的库函数调用非常类似，主要的区别在于system call是系统提供的，由操作系统的内核运行在ring 0，普通的库函数由函数库或者用户自己提供，运行于用户态。可以看做是系统层面的API

# Drawbridge

之前的应用程序，比如excel是调用比如user32.dll、gdi32.dll、kernel32.dll这些api，由这些dll调用更深层的ntdll.dll，最终是由ntdll来调用ntoskrnl.dll。还有一个方式是上面那些win32的dll直接调用win32k.dll。这两种方式都通过了user mode和kernel mode的边界。

Drawbridge提供了另外一种方式，将应用程序到kernel之间的内容包装在一起，抽象为一个library OS，应用程序调用LibOS的接口，由LibOS调用system call。有一个不同的是Drawbridge将UNIX Server、Device Driver、File Server提到了User mode，kernel中只留了Basic IPC、VM和Scheduling的功能，引入libos后的系统架构为：

![drawbridge_architecture](http://7xrop1.com1.z0.glb.clouddn.com/paper/drawbridge_architecture.png)

![drawbridge_architecture2](http://7xrop1.com1.z0.glb.clouddn.com/paper/drawbridge_architecture2.png)

上图中左边为windows7的系统架构，右边为drawbridge的架构，一部分内容提到user mode后需要考虑这部分内容的安全性，在LibOS与kernel之间有一个security monitor，用于保证LibOS传入指令的安全性。

这里提出了一个OS as a Service的概念，在OS中定义了三种services类型;hardware services、user services和application services。Hardware services包含OS kernel和设备驱动，设备驱动抽象并且多样化了包含文件系统和TCP/IP网络堆栈这样的硬件；User services包括用户图形界面、剪贴板之类的；Application Services包含API的实作，有frameworks，common UI controls，language runtimes等。

利用Drawbridge的架构能使程序达到安全隔离的效果，并且程序运行状态在LibOS中，可以整体打包到另外一台电脑继续运行，应用程序不再过度依赖操作系统的API，能够达到长期兼容的效果。

# LibOS与其他类似技术的区别

## VM

相似点在于能方便的迁移应用程序

其他系统的应用程序使用LibOS技术目前的情况是需要修改源代码，去掉使用OS API的部分改为使用LibOS的API，而如果使用VM的话一般可以直接运行相关系统的应用程序

Drawbridge比VM更加轻量，开销更小。不需要重新安装一个操作系统，VM实际上是在一个操作系统中运行另外一个操作系统，应用程序到硬件之间经过了操作系统-VM-host OS，这很大程度上会影响性能，不过现在VMware对这部分进行了一些改进，有些指令如果可以直接在host OS中运行，会直接传给host OS执行这些指令，减少过程中的开销。不过总体上而言，VM的开销还是大于LibOS。

## Container

比如Docker和Wine这种类型，这个是模拟应用程式运行所需的环境，本质上是模拟出操作系统的一些特性，程序跑在模拟出来的操作系统上，Container的模拟没有模拟硬件，这种方式没有实际作出一个OS，只是运行在Container中的应用程序认为自己运行在另一个OS中。差不多相当于Container模拟了相应OS的API，然后将相应的指令传给host OS执行。Container不支持应用程序状态的迁移，但是比起VM比较轻量级。

# 参考

1. [drawbridge.pptx](https://users.cs.duke.edu/~chase/cps510/slides/drawbridge.pdf)
2. [Drawbridge: A new form of virtualization for application sandboxing \| Going Deep \| Channel 9](https://channel9.msdn.com/Shows/Going+Deep/Drawbridge-An-Experimental-Library-Operating-System)
3. [Windows NT体系结构 - 维基百科，自由的百科全书](https://zh.wikipedia.org/zh-cn/Windows_NT%E4%BD%93%E7%B3%BB%E7%BB%93%E6%9E%84)
4. [内核 - 维基百科，自由的百科全书](https://zh.wikipedia.org/wiki/%E5%86%85%E6%A0%B8)
5. [Application Virtualization 是什麼 ?](http://www.arthurtoday.com/2011/08/application-virtualization.html)
