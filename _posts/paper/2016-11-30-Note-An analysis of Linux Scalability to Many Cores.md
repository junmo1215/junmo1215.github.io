---
layout: post
date: 2016-11-30 15:44
status: public
title: '[笔记]An analysis of Linux Scalability to Many Cores'
tag: [操作系统, OS]
categories: [paper]
description: 
---

[原文链接](https://pdos.csail.mit.edu/papers/linux:osdi10.pdf)

* 目录 
{:toc}

# 摘要
这篇paper探讨传统的kernel设计能否使应用程序scale
在48核的计算机上运行七个现有的application，发现随着core数量的增加，性能并没有呈线性增长（理想状况下，48个core的处理效率应该是一个core的48倍），并且最终结果的表现很不理想。
然后作者进一步分析了造成这个瓶颈的原因，到底是kernel问题、应用程序本身的问题还是硬件造成的瓶颈。然后整理出一些目前Linux kernel（Linux 2.6.35-rc5, released on July 12, 2010）的问题并通过修改3000多行代码优化这些问题，然后在优化后的kernel（patched kernel，简称PK）与原先的kernel（stock kernel）上跑这些应用程序，比较性能的结果。
最后的结果表明，这个版本的kernel有scalability的问题，但是比较容易修复（大的架构没有修改，只改动了3002行代码）（至少能修复到在48核的情况下不是因为kernel问题造成瓶颈）

# 实作要点
用来测试的七个应用程序（MOSBENCH）是Exim、Memcached、Apache、PostgreSQL、gmake、the Psearchy file indexer、MapReduce library
硬件是一个48核的计算机，通过禁用一些核来测量不同数量的core时，软件执行的效率。
为了避免disk I/O造成的瓶颈，采用了In-memory的file system（tmpfs）
步骤基本上是跑应用程序、发现瓶颈、分析原因、修改应用程序或者kernel、接着跑应用程序然后分析

# 贡献
- 分析了7个目前（2010年）跑在Linux上应用程序的scalability，发现原生的Linux限制了scalability，分析了目前kernel中这些瓶颈的原因。修改了3002行代码，16个优化项。大部分的修改都能增加多线程application的scalability。分析了优化kernel之后还存在的瓶颈原因（应用程序本身的问题或者是硬件限制）。
- 推出了sloppy counters
- 描述了一些增加应用程序scalability的技术
- 通过这些应用程序在stock和PK上的运行测试，证明没有直接的原因放弃传统的kernel设计来提升scalability

# kernel 优化的技术
## Multicore packet processing
参照[这个链接](http://www.jianshu.com/p/14104a1a0821)多核数据包处理部分

## Sloppy counters
假设有一个变量a，在global中有一个对应于这个变量的计数器，每当有core引用这个变量的时候计数器就 +1，每当有core停止对这个变量的引用，global计数器的值就 -1。然后计数器的读数就是所有core中引用这个变量的数量总和。
没有这个技术时存在的问题是：很多线程用这个变量然后释放会造成global计数器在不停的加减，随着core数量的增多性能必然会持续下降。
然后这篇paper作者观察到的现象是，kernel很少需要释放object，并且很少需要知道引用次数的真实值。所以推出了一个叫做Sloppy counters的技术，大致思路就是引用了全局的这个变量的时候用完了先不告诉global已经用完了，global计数器的值现在先不变。比如core 0 现在引用这个变量，告诉global我有个线程引用了这个，global的计数器 +1，然后在core 0的这个线程用完了之后不通知global，而是将释放的东西放在core 0 中，造成的结果是core 0中的计数器 +1，global中计数器不变。如果刚好core 0 中有另外一个线程要引用这个变量了，就可以直接从core 0 刚刚存下的地方取，不需要经过global，能增加一些性能。其他core中也是大概类似的步骤，这样虽然global中的计数器值一般会偏大（比如没有线程在引用这个变量，只有core 0 的计数器记录着1，global中计数器也记录的是1，但是实际应该是0），但是在不在意这个值的情况下是能够提升性能的。
不过这个方法也有一个缺陷，在需要知道global计数器的真实值的时候，需要一个个的询问每个core，让每个core的计数器清零，core越多的时候这个步骤花的时间也就越多。

## Lock-free
Lock-free是一个算法，用来确保竞争共享资源的线程不会由于互斥而无限期的推迟其执行
``` c
template <class T>
bool CAS(T* addr, T expected, T value){
    if(*addr == expected){
        *addr = value;
        return true;
    }
    return false;
}
```
由于硬件的原子性能保证上面的这个函数一次性执行完并且中间没有其他线程插入
以map的查找和update为例：
之前使用lock的方式：
``` c
// WRRMMap的一个基于锁的实现
template <class K, class V>

class WRRMMap {
   Mutex mtx_;
   Map<K, V> map_;

public:
   V Lookup(const K& k) {
      Lock lock(mtx_);
      return map_[k];
   }

   void Update(const K& k,
         const V& v) {
      Lock lock(mtx_);
      map_[k] = v;
   }
};
```

使用free-lock的方式：
``` c
// WRRMMap的首个锁无关的实现
// 只有当你有GC的时候才行
template <class K, class V>

class WRRMMap {
   Map<K, V>* pMap_;

public:
   V Lookup (const K& k) {
      // 瞧，没有锁！
      return (*pMap_) [k];
   }

   void Update(const K& k,
         const V& v) {
      Map<K, V>* pNew = 0;
      do {
         Map<K, V>* pOld = pMap_;
         delete pNew;
         pNew = new Map<K, V>(*pOld);
         (*pNew) [k] = v;
      } while (!CAS(&pMap_, pOld, pNew));
      // 别 delete pMap_;
   }
};
```
**后面基于free-lock的方式有一些注意事项，参考中第二点的链接**
这种做法的优点在于读的操作比较多的情况下性能会提高很多，不会由于core数量增加造成竞争lock的概率加大。并且避免了死锁问题，不管有多少个core中的多少个线程在进行update的操作，至少有一个能成功的执行下去，整体的进度还是在向前走。而lock中有死锁的话这个就无法达到。
不过如果有个线程运气足够差，也可能每次修改都发现这个值已经被改过了，这个线程就要重复读旧的值，update，将旧的值与这个地址当前的值比较的这个步骤。可能就这个线程而言执行的时间会变长，但是整体上这个方式在这种情况下scalability更好

## Per-core data structure
无论使用什么样的lock方式，都会造成线程之间的竞争和等待。有一个方式就是把很少会修改的数据放在每个core自己的cache中，减少这种情况发生的概率。
比如在这篇paper的实作中用这种方法优化了lookup_mnt函数，因为global mount table很少会修改，所以采用了每个core存储这个core自己的mount cache的方式
优化之前和之后的代码如下：
``` c
//优化之前：
struct vfsmount *lookup_mnt(struct path *path){
    struct vfsmount *mnt;
    spin_lock(&vfsmount_lock);
    mnt = hash_get(mnts, path);
    spin_unlock(&vfsmount_lock);
    return mnt;
 }
 
 //优化之后：
 struct vfsmount *lookup_mnt(struct path *path){
    struct vfsmount *mnt;
    if ((mnt = hash_get(percore_mnts[cpu()], path)))
        return mnt;
    spin_lock(&vfsmount_lock);
    mnt = hash_get(mnts, path);
    spin_unlock(&vfsmount_lock);
    hash_put(percore_mnts[cpu()], path, mnt);
    return mnt;
}
```
虽然优化之前的代码较短，但是由于core的数量较多，实际测量时发现在10秒内，spin_lock这个函数中能执行400到5000次循环，主要是Lock造成的不scalability，改用下面这个方式之后，每次先尝试从每个core自己的cache中读取，找不到再去global的mount table，能减少lock竞争的情况发生。

## false sharing
cache中有一个cache line的概念，是cache的最小单元，当一个cache line中有一点改动，整个cache line就会被标记为modify。
举个例子：
``` c
struct foo {
    int x;
    int y; 
};

static struct foo f;

/* The two following functions are running concurrently: */

int sum_a(void)
{
    int s = 0;
    int i;
    for (i = 0; i < 1000000; ++i)
        s += f.x;
    return s;
}

void inc_b(void)
{
    int i;
    for (i = 0; i < 1000000; ++i)
        ++f.y;
}
```
后面两个方法a和b是同时执行的，在a里面是读取f.x的值，原本可以只从cache中读到这个值，但是由于b方法中会修改f.y，而f.x和f.y在同一个cache line的话，b方法每次会将这个cache line变成modify状态，导致a取值的时候不从cache中读取，性能反而会下降。
解决办法包括：尽量使f.x和f.y不在一个cache line中，修改f.y的时候不会影响到f.x；或者每个线程创建本地拷贝，结束后再修改f.y的值。
后面一点在这个例子中就是不要每次读f.x或f.y，先读一遍存到变量中，然后在update的最后才修改f.y的值。

# 实作部分
Figure 3中揭示了修改kernel前后的scalability差异，大部分的scalability在修改kernel后都有提升，而gmake是原本的scalability就挺好的，所以几乎没有什么效果。

## Exim
stock在一个core增加到两个core的时候，throughput下降的原因是kernel中数据结构不能共用导致瓶颈的产生（The many kernel data structures that are not shared with one core but must be shared(with cache misses) with two cores）
PK在一个core增加到两个core时下降的原因主要是应用程式引起的对directory lock 的竞争
Throughput持续下降的原因是lookup_mnt函数在多线程中效率较低，PK中修复这个问题后情况有改善

## memcached
paper的这部分提到了memcached遇到的三个瓶颈的原因以及解决方案
但是修复了kernel中这些问题之后，Throughput有一定的提升但是走势仍然相同，这时候是受到了硬件的制约

## Apache
原因和解决方案与memcached相似
修复了kernel中的问题之后效果提升明显，但是后面部分（40个core附近）下降速度变快原因是网卡的分发跟不上请求的速度。受硬件限制

## PostgreSQL
PostgreSQL自身的设计中有一个row-level和table-level的lock，导致core增加到一定程度的时候，stock上实作的性能下降很厉害
修复应用程序的这个问题之后，在read-only的workload情况下，效果不明显是因为很少触发到这个lock，在95%read + 5%write的情况下效果有一定程度的改善
优化kernel后整体的throughput有明显提升

## gmake
gmake的scalability很好
整个图形不是水平的因为在编译开始和结束后还是有一些串行化的操作导致线程之间会有影响，平均性能是随着核的增加而下降的，gmake大多数的时间都在编译，每个core之间没有相互影响，所以scalability很好

## Psearchy/pedsort
system time很少而user time很多，大部分时间都花在user mode 里面了，所以瓶颈主要是由应用程序引起的

## Metis
解决方法是使用2Mbyte的super-page

# 结论
从实作的结果可以看出，虽然修改了kernel之后大部分的应用程式还是存在瓶颈，但是分析原因都可以归结为应用程序自身的问题或者硬件的问题。所以目前扩展到48核的情况下，都很容易通过kernel很小的改动提升scalability，不需要重新研究系统新的设计来提升scalability。


# 参考

1. [A Comprehensive Presentation on 'An Analysis of Linux Scalability  to Many Cores](https://zh.scribd.com/document/179812254/A-Comprehensive-Presentation-on-An-Analysis-of-Linux-Scalability-to-Many-Cores)
2. [锁无关的(Lock-Free)数据结构——在避免死锁的同时确保线程继续](http://blog.csdn.net/pongba/article/details/588638)
3. [False sharing](https://en.wikipedia.org/wiki/False_sharing)