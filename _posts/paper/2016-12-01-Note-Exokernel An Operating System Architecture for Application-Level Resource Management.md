---
date: 2016-12-01 01:54
status: public
title: '[笔记]Exokernel An Operating System Architecture for Application-Level Resource Management'
layout: post
tag: [操作系统, OS]
categories: [paper]
description: 
---

[原文链接](https://pdos.csail.mit.edu/6.828/2008/readings/engler95exokernel.pdf)

* 目录 
{:toc}

# 简介
传统的操作系统定义了软件与硬件之间的接口，由于一般情况下这些接口是适用于很多硬体的，所以会显得非常臃肿，并且效率会很低。整体上是限制了application的性能、灵活性和功能。所以这篇paper提出了一种新的作业系统架构：Exokernel，这种架构提供应用程序层面的硬件资源管理，也就是说在某种程度上允许软件直接操纵硬件资源。将安全性与抽象分离，使得操作系统的不可覆盖部分不做任何事情，而是安全地复用硬件。这是通过将抽象移动到称为“库操作系统”（libOSes）的不可信用户空间库来实现的，这些库被链接到应用程序并代表它们调用操作系统。

paper作者他们认为软件能更加了解自己想要的硬件接口是什么样的（Applications know better than the OS what the goal of their resource management decisions should be and therefore, they should be given as much control as possible over those decisions.），软件开发人员能基于软件的功能性和性能要求创造特定的实现。因此Exokernel将保护和管理分离开了, Exokernel有点像是传统的作业系统中把Library OS抽出来剩下的那一部分。传统的操作系统会提供一些硬件的抽象给软件，而这个是没有提供的，只负责系统保护和系统资源复用相关的服务。

> 这种设计还有一些其他的优点：
> - 随着在应用程序空间中完成更多的事情，内核交叉的数量减少
> - 随着内核内部状态和数据结构最小化，内核交叉本身的成本降低
> - 更容易地改变现有抽象或引入新的抽象，使系统的灵活性增加

# 安全性问题

Exokernel通过一种叫做Secure Bindings的机制来保护资源，通过secure bindings，libOS能与资源绑定在一起，从资源的使用中将授权分离出来。这个机制由三个基础的技术来实现的：hardware mechanisms，software caching and downloading application code。
- hardware mechanisms：硬件机制。适当的硬件支持允许将安全绑定作为低级保护操作来进行，使得可以有效地检查稍后的操作而不依赖于高级授权信息。比如文件服务器可以向应用程序提供各个物理页面，更简单的硬件支持是TLB条目，包含了LibOS中page table从虚拟地址到物理地址的映射。
- software caching：secure bindings能够被缓存。举个例子，exokernel能使用大的软件TLB（转译后备缓冲器Translation Lookaside Buffer 也称作页表缓存）能缓存不适用于硬件TLB的转义地址。软件TLB能被视为常用secure bindings的缓存。
- downloading code：不受信任的代码通过代码检查和沙箱组合而变得安全。 这个技术允许应用程序的线程执行在kernel层。这样做可以提升性能，原因是消除了kernel的耦合，并且可以对这部分代码的执行时间设置界限。一个downloading code的例子是Application-specific Safe Handlers（ASHs）

> ASHs与包过滤器（packet filter）结合起来用于网络包的接收，ASHs是不受信任的应用程序级消息处理程序，它们被下载到内核中，通过代码检查和沙箱的组合安全，并在消息到达时执行。 其他上下文中的问题（例如，磁盘I / O）是类似的。<br/>
ASHs主要有以下四个能力：
> - dynamic message vectoring 动态消息向量化。 ASH控制消息在内存中的复制，因此可以消除所有中间副本，这是快速网络系统的祸根
> - Dynamic integrated layer processing(ILP) 动态集成层处理
> - Message initiation 消息启动。ASHs可以发起消息发送，允许低延迟消息答复
> - Control initiation 控制启动。ASH执行一般计算。这种能力允许它们在接收消息时执行控制操作，实现传统活动消息或远程锁定获取等计算操作。

# 结论
1. 简单和有限数量的exokernel模型允许他们的实现非常有效率
1. 因为exokernel模型是快速的，所以可以有效地实现硬件资源的低级别安全复用。
1. 传统的操作系统抽象能在应用程序级别有效的实现
1. 应用程序仅修改库就能创建抽象的特殊目的实现

# 最后
这个篇paper是1995年写的，但是这个系统直到目前都没有商业化，个人感觉主要难度在于libOS很难开发并且按照作者的想法是不能共用的（要是不同的硬体能共用一套libOS就跟现在的操作系统没有什么大的区别了），虽然paper中提到了Exokernel和LibOS各自的职责，但是相应的接口规范还是没有标准，如果有很多家公司生产出的Exokernel采用的是不一样的接口，LibOS会造成混乱，application也很难写很难维护。感觉推广这个系统需要硬件有一个标准或者使用同样接口的硬件，这样能使LibOS共用，增强系统的稳定性（比如Apple）。然后提供kernel级别的接口标准，不同的系统采用同样的接口，方便应用程序的开发人员，否则这部分不统一会导致应用程序需要针对每个系统出一个版本，最后会很难维护。如果这两个问题解决之后其实还是挺看好这个架构的，最后可能会出现几种主流的硬件配置，然后很多操作系统的厂家会针对一些特定化的功能出一些LibOS内置在系统里面，应用程序根据不同的需求选择不同的LibOS调用，确实能提升性能并且会更方便移植一些，应用程序的开发也会变的比较简单（不同硬件和系统上使用相同标准的LibOS，流行了之后开源的或者大公司自己写感觉都不太困难）。

# 参考
1. [Notes on "Exokernel: An Operating System Architecture for Application-Level Resource Management" By Athanasios Kyparlis](http://www.cs.cornell.edu/Info/Courses/Spring-97/CS614/exo.html)
1. [wiki: Exokernel](https://zh.wikipedia.org/wiki/Exokernel)
1. [wiki: TLB](https://zh.wikipedia.org/wiki/%E8%BD%89%E8%AD%AF%E5%BE%8C%E5%82%99%E7%B7%A9%E8%A1%9D%E5%8D%80)
1. [Lec-02: ExoKernel与操作系统架构](https://unitial.gitbooks.io/csp/content/lec-02.html)
1. [Exokernel](http://wiki.osdev.org/Exokernel)