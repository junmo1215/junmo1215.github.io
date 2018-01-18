---
date: 2018-1-18 01:35
status: public
title: '[实作]TDLearning in 2584-fibonacci (五)、实作evil对抗自己的AI'
layout: post
tag: [机器学习, 强化学习, TDLearning, 2584-fibonacci]
categories: [machine-learning]
description: 
---

* 目录
{:toc}

# 2584-fibonacci game

涉及的知识点目前有：
- 2584的基本规则
- C++基本语法
- Temporal Difference Learning
- N-Tuple Networks
- expectimax search
- bitboard
- temporal coherence learning(TCL)

文章地址： <https://junmo1215.github.io/machine-learning/2018/01/18/practice-TDLearning-in-2584-fibonacci-5th.html>

代码地址： <https://github.com/junmo1215/rl_games/tree/master/2584_C%2B%2B>

> 由于后面几个project持续在做，所以获取的代码应该是后面几个project版本的代码，可以根据签入记录获取对应的版本。代码也许有略微差异，但是应该不影响理解。

# 作业要求

这次作业里面没有新的知识，只是把原来实作player的那部分算法往evil里面移植一份。改动比较大的部分是之前很多写在player类里面的内容要改到agent里面去了。

至于--shell指令是期末对战的时候才会用到的，直接按照助教提供的代码就行了，需要替换掉TODO的那两行，但是还是没太明白应该怎么改。单机跑自己的player对抗自己的evil已经没有问题了

# 共用weights

在player决定每一步怎么行动的时候，会参照weights的信息来评估当前盘面，然后使用expectimax search来搜寻未来的几步。所以evil最好也是能拿到这个信息，才能比较有针对性的对抗player。

所以首先需要把一些函数都移到agent类里面去，让player和evil都能访问到这些函数。

``` cpp
class agent {
public:
	agent(const std::string& args = "") {}
	virtual ~agent() {}
	virtual void open_episode(const std::string& flag = "") {}
	virtual void close_episode(const std::string& flag = "") {}
	virtual action take_action(const board& b) { return action(); }
	virtual bool check_for_win(const board& b) { return false; }

public:
	virtual std::string name() const { return property.at("name"); }
	virtual std::string role() const { return property.at("role"); }
	virtual void notify(const std::string& msg) {}

	const static std::array<std::array<int, TUPLE_LENGTH>, TUPLE_NUM> indexs;

	static std::vector<weight> weights;
	static std::vector<weight> weightsE;
	static std::vector<weight> weightsA;

	static void save_weights(const std::string& path) {}
	virtual float get_after_expect(const board& after, const int& search_deep){}
	virtual float get_before_expect(const board& before, const int& search_deep){}

protected:
	typedef std::string key;
	struct value {};
	std::map<key, value> property;

	float board_value(const board& b){}
	long get_feature(const board& b, const std::array<int, TUPLE_LENGTH> index){}
	virtual void load_weights(const std::string& path) {}

public:
	virtual void init_network(){}
};
```

这边大部分的函数我都去掉了具体的实现，代码上跟之前的差不多，印象中没有改什么，只是直接搬到外面了。

需要注意的问题大概只有如果是自己电脑上player对战自己的evil，那些weights加起来内存占用大概就是11G，我的12G内存的电脑显然没有办法跑起来两份weights，所以采用的方法是player和evil读取同一份weights。

简单的做法是在load的时候判断weights是不是空的，如果不是空的表明之前已经load过了，这边就直接return

# 实作evil

作业要求中evil能决定的只有棋盘落子的位置，不能决定落子的概率，也就是说在evil看到这个盘面的时候，只能根据分析，决定我要下在那里，但是至于下下去的tile是1还是3就没有办法确定了。

目前没有用到什么博弈论的知识，思路上只是简单地采取了这个策略：对于某个局面，尝试所有能落子的位置，然后直接选取落子后盘面估值最小的那个。因为这个估值是对于player而言的得分的判断，evil的目的是希望player得分尽可能低。

基本上只需要改变```take_action```这个函数就可以了，因为evil不涉及学习的过程。我这份代码里面train的过程都是在player里面。

``` cpp
virtual action take_action(const board& after) {
    int space[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };

    float min_expect = -MIN_FLOAT;
    int best_pos = -1;
    for(int pos : space){
        if(after(pos) != 0) continue;

        float temp_expect = get_before_expect(after, 1);
        if(temp_expect < min_expect){
            min_expect = temp_expect;
            best_pos = pos;
        }
    }

    if(best_pos != -1){
        std::uniform_real_distribution<> popup(0, 1);
        int tile;
        try{
            // 这里是为了适配最后的联机对战，可以不用管
            // 联机对战的时候是对战平台传过来一个tile=1或者3
            tile = int(property.at("tile"));
        }
        catch(std::out_of_range&){
            tile = (popup(engine) > 0.25) ? 1 : 3;
        }
        return action::place(tile, best_pos);
    }

    return action();
}
```

# 其他细节

对C++不是很熟悉是我写这一系列project最大的障碍，有两个问题大概都查了一个多小时。这次卡住的问题是把weights移到agent里面的时候打算变成static的。然而C++在类里面写```static int n```只是声明，并不是定义，编译的时候还是找不到n是什么，这种情况需要在类的外面再加上n的定义。

拿这次我踩的坑来举例，我想在agent类里面有几个静态变量

需要首先在类里面声明：

``` cpp
static std::vector<weight> weights;
static std::vector<weight> weightsE;
static std::vector<weight> weightsA;
```

因为赋值的时候是在player或者evil的构造函数里面，所以这里没有赋值，并且这里也不能赋值

这时候编译会报错，类似于下面这种提示：

```
$ make all
g++ -std=c++0x -O3 -g -Wall -fmessage-length=0 -o 2584 2584.cpp
PATH_TO_USER_DIR\AppData\Local\Temp\ccpJofYw.o:2584.cpp:(.rdata$.refptr._ZN5agent8weightsEE[.refptr._ZN5agent8weightsEE]+0x0): undefined reference to `agent::weightsE'
PATH_TO_USER_DIR\AppData\Local\Temp\ccpJofYw.o:2584.cpp:(.rdata$.refptr._ZN5agent8weightsAE[.refptr._ZN5agent8weightsAE]+0x0): undefined reference to `agent::weightsA'
PATH_TO_USER_DIR\AppData\Local\Temp\ccpJofYw.o:2584.cpp:(.rdata$.refptr._ZN5agent7weightsE[.refptr._ZN5agent7weightsE]+0x0): undefined reference to `agent::weights'
collect2.exe: error: ld returned 1 exit status
makefile:2: recipe for target 'all' failed
make: *** [all] Error 1
```

查找C++的文档可以找到原因：

> 类的静态成员不关联到类的对象：它们是拥有静态存储期的独立对象，或仅在程序中于命名空间定义一次的常规函数。**```static``` 关键词仅与静态成员的在类定义中的声明一同使用，但不与该静态成员的定义一同使用**

简单来讲上面的那几行代码只是声明，并没有定义weights

解决办法就是在类的外面加上定义：

``` cpp
class agent {
public:
    // 声明
	static std::vector<weight> weights;
	static std::vector<weight> weightsE;
	static std::vector<weight> weightsA;
}

// 类的外面定义
std::vector<weight> agent::weights;
std::vector<weight> agent::weightsE;
std::vector<weight> agent::weightsA;
```

# 运行结果

加上这个evil之后连到达10946都困难了

下面是训练了100000场的结果，不知道最后能不能去打比赛：

``` sh
100000  avg = 41496, max = 188381, ops = 15017
        21      100%    (0.1%)
        55      99.9%   (0.1%)
        89      99.8%   (0.4%)
        144     99.4%   (0.7%)
        233     98.7%   (1.3%)
        377     97.4%   (2.5%)
        610     94.9%   (5.1%)
        987     89.8%   (12%)
        1597    77.8%   (20.3%)
        2584    57.5%   (27.5%)
        4181    30%     (22.6%)
        6765    7.4%    (7%)
        10946   0.4%    (0.4%)
```

# 参考

1. [chessprogramming - General Setwise Operations](https://chessprogramming.wikispaces.com/General+Setwise+Operations)
2. [moporgic/TDL2048-Demo: Temporal Difference Learning for Game 2048 (Demo)](https://github.com/moporgic/TDL2048-Demo)
3. [Mastering 2048 with Delayed Temporal Coherence Learning, Multi-Stage Weight Promotion, Redundant Encoding and Carousel Shaping](https://arxiv.org/pdf/1604.05085.pdf)
4. [静态成员 - cppreference.com](http://zh.cppreference.com/w/cpp/language/static)
