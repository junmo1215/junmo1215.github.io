---
date: 2017-12-2 17:40
status: public
title: '[实作]TDLearning in 2584-fibonacci (三)、在2x3的盘面上完成expectimax search'
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
- **expectimax search**

文章地址： <https://junmo1215.github.io/machine-learning/2017/12/02/practice-TDLearning-in-2584-fibonacci-3rd.html>

代码地址： <https://github.com/junmo1215/rl_games/tree/master/2584_C%2B%2B>

> 由于后面几个project持续在做，所以获取的代码应该是后面几个project版本的代码，可以根据签入记录获取对应的版本。代码也许有略微差异，但是应该不影响理解。

这个project大概是这个系列里面最简单的了，懂这个算法的话应该一晚上就做完了。

# 基础框架

这次的作业要求是给定一个state，给出这个state的估值。由于2x3的盘面比较小，2584在这个盘面上可能达到的最大值是第12个索引（对应数字是233），估值依然是看做一个float的数值，如果用穷举占用的内存大小为（把每一格中的数看做一个13进制的数，所以用6个13进制的数可以表示盘面的所有可能情况）：

$$
13^6 * 32bit = 154457888bit \approx 18.41MB
$$

可以发现穷举法在这个情况下是可行的，于是可以考虑递归的做法，假设我们知道下一个盘面的估值，求这个盘面的估值就很简单了。

所以这个project的大概思路是在程序启动的时候穷举完所有的可能，计算出各种盘面的估值存到一个数组中，然后没输入一个盘面的信息，给出这个盘面的估值。如果盘面信息不可能达到就返回-1。

# 实作代码

这次基本上跟这个算法有关的只有两个地方：初始化的时候遍历所有可能情况，把所有盘面的结果记录在一个数组中；针对每个输入去数组中查找值并返回结果。

由于project要求回答每个输入是否可能达到，并且很多盘面的情况不太容易判断，当时纠结这个逻辑想了一个多小时，后来干脆把after_state和before_state分别存在了两个不同的数组中，因为已经遍历了所有可能情况，所以不在数组中的一定就是不可能达到的盘面了

## 初始化代码

把before_state（马上轮到玩家操作的盘面）的估值放在变量expects中，after_state（玩家操作之后的盘面）的估值放在变量after_expects中。这两个数组的大小都是 $ SIZE = 13^6 $ ，然后要模拟开局的所有可能，然后开始一层层递归，如果对应的盘面已经搜索过了就直接返回估值，否则就计算这个盘面的估值。

``` cpp
solver(const std::string& args) {
    // 初始化这两个数组，因为这个估值不会是负数所以就直接设置成-1了
    expects = new float[SIZE];
    after_expects = new float[SIZE];
    for(long i = 0; i < SIZE; i++){
        // moves[i] = -1;
        expects[i] = -1.0;
        after_expects[i] = -1.0;
    }

    // 模拟所有可能的初始盘面
    for(int pos1 = 0; pos1 < max_pos; pos1++){
        for(int tile1 = 1; tile1 < 3; tile1++){

            for(int pos2 = pos1 + 1; pos2 < max_pos; pos2++){
                for(int tile2 = 1; tile2 < 3; tile2++){
                    board2x3 board;
                    action::place(tile1, pos1).apply(board);
                    action::place(tile2, pos2).apply(board);
                    // 开始递归给数组赋值
                    get_before_expect(board);
                }
            }
        }
    }

    std::cout << "solver is initialized." << std::endl << std::endl;
}
```

## get_before_expect 和 get_after_expect

在before_state的情况下，玩家每个操作是由玩家自己决定的，所以每个状态的期望值都是确定的，原则是选择值最高的那个动作，直接把这个动作的reward和after_state的期望值作为这个盘面的期望。

对于after_state，由于没有办法知道游戏会往哪个空的方块放置什么值，所以只能根据对应的概率算出这个盘面的期望。

``` cpp
float get_before_expect(board2x3 board){
    int index = get_index(board);

    if(expects[index] > -1)
        return expects[index];

    float expect = 0.0;
    float best_expect = MIN_FLOAT;
    bool is_moved = false;

    // 模拟四种动作
    for(int op: {3, 2, 1, 0}){
        board2x3 b = board;
        int reward = b.move(op);
        if(reward != -1){
            expect = get_after_expect(b) + reward;
            if(expect > best_expect){
                is_moved = true;
                best_expect = expect;
            }
        }
    }

    // 有可能对于这个盘面其实已经挂掉了需要重新开始游戏
    // 这时候就设置这个盘面的期望为0
    // 这也可以看成是递归的终止条件
    if(is_moved){
        expects[index] = best_expect;
    }
    else{
        expects[index] = 0;
    }

    return expects[index];
}

float get_after_expect(board2x3 board){
    int index = get_index(board);

    if(after_expects[index] > -1)
        return after_expects[index];

    float temp_expects[2] = {0, 0};
    // 游戏可能放置值为1或者2的方块
    for(int i: {1, 2}){
        float expect = 0;
        int count = 0;
        // 寻找所有空的格子并放置方块
        for(int j = 0; j < max_pos; j++){
            board2x3 b = board;
            int result = action::place(i, j).apply(b);
            if(result != -1){
                expect += get_before_expect(b);
                count++;
            }
        }
        temp_expects[i - 1] = expect / count;
    }

    // 按照随机的概率计算期望值
    float result = temp_expects[0] * 0.9 + temp_expects[1] * 0.1;
    after_expects[index] = result;

    return result;
}
```

## 针对输入返回结果

由于前面两个数组中已经储存了所有可能的情况，这里就不需要考虑太多相关逻辑了，只需要限制每个方块是否超过最大的索引就行（防止将不可能的盘面编码到正常的盘面或者是超出数组范围），剩下的事情就只需要查表就好。

``` cpp
answer solve2x3(const board2x3& state, state_type type = state_type::before) {
    int temp_tile;
    for(int i = 0; i < row; i++){
        for(int j = 0; j < column; j++){
            temp_tile = state[i][j];
            // 排除盘面上不可能出现的数字
            if(temp_tile >= max_index || temp_tile < 0)
                return -1;
        }
    }

    if(type.is_before() && is_legal_before_state(state)){
        return get_before_expect(state);
    }
    else if(type.is_after() && is_legal_after_state(state)){
        return get_after_expect(state);
    }
    return -1;
}

bool is_legal_after_state(board2x3 board){
    return after_expects[get_index(board)] != -1;
}

bool is_legal_before_state(board2x3 board){
    return expects[get_index(board)] != -1;
}
```

# 最终效果

编译后执行2584sol：

``` sh
2584-Solver: 2584sol

solver is initialized.
```

输入几组测试数据看下效果：

``` sh
b 2 2 0 0 0 0
= 1422.339233
b 0 0 0 0 2 2
= 1422.339233
a 0 0 0 0 2 2
= 1422.339233
a 2 0 2 0 0 0
= 1422.339233
a 10 0 0 0 0 1
= -1
a 0 0 0 0 1 2
= 1424.364258
b 1 1 0 0 0 1
= 1426.366089
b 33 32 31 30 29 28
= -1
a 2 2 2 2 2 2
= -1
```

> 由于float精度的问题，这个实作中误差在小数点后三位都是可以接受的，但是超过这个范围就一定是代码有问题了。

测试代码也是只有Ubuntu系统能跑，具体用法参照这个文件： \test\pr-3\instruction.txt

# 2584-fibonacci全部文章地址

1. [[实作]TDLearning in 2584-fibonacci (一)、搭建基础框架](https://junmo1215.github.io/machine-learning/2017/10/22/practice-TDLearning-in-2584-fibonacci-1st.html)
2. [[实作]TDLearning in 2584-fibonacci (二)、实现TD0](https://junmo1215.github.io/machine-learning/2017/11/27/practice-TDLearning-in-2584-fibonacci-2nd.html)
3. [[实作]TDLearning in 2584-fibonacci (三)、在2x3的盘面上完成expectimax search](https://junmo1215.github.io/machine-learning/2017/12/02/practice-TDLearning-in-2584-fibonacci-3rd.html)
4. [[实作]TDLearning in 2584-fibonacci (四)、expectimax search、TCL、bitboard](https://junmo1215.github.io/machine-learning/2018/01/11/practice-TDLearning-in-2584-fibonacci-4th.html)
5. [[实作]TDLearning in 2584-fibonacci (五)、实作evil对抗自己的AI](https://junmo1215.github.io/machine-learning/2018/01/18/practice-TDLearning-in-2584-fibonacci-5th.html)

# 参考

1. [SP14 CS188 Lecture 7 -- Expectimax Search and Utilities.pptx (Page 18 - 19)](http://ai.berkeley.edu/slides/Lecture%207%20--%20Expectimax%20Search%20and%20Utilities/SP14%20CS188%20Lecture%207%20--%20Expectimax%20Search%20and%20Utilities.pptx)
