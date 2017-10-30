---
date: 2017-10-22 12:14
status: public
title: '[实作]TDLearning in 2584-fibonacci (一)、搭建基础框架'
layout: post
tag: [机器学习, 强化学习, TDLearning, 2584-fibonacci]
categories: [machine-learning]
description: 
---

[TOC]

# 2584-fibonacci game

2584-fibonacci是一个类似于2048的游戏，只是游戏中的数值从2的倍数换成了fibonacci数列，合并规则有一点点的修改，具体可以尝试一下在线版的游戏体验一下。熟悉2048的话应该很容易上手。

这个代码是[吳毅成教授](http://java.csie.nctu.edu.tw/~icwu/chindex.html)开设的TCG（电脑对局理论，Theory of Computer Games）课程project，从0开始（助教这次提供了框架）一步步实现AI自己玩2584，最终的胜率（达到2584）差不多在95%以上。

涉及的知识点目前有：
- C++基本语法
- Temporal Difference Learning
- N-Tuple Networks

文章地址： <http://junmo.farbox.com/post/ji-qi-xue-xi/-shi-zuo-tdlearning-in-2584-fibonacci-da-jian-ji-chu-kuang-jia>

代码地址： <https://github.com/junmo1215/rl_games/tree/master/2584_C%2B%2B>

> 由于后面几个project持续在做，所以获取的代码应该是后面几个project版本的代码，可以根据签入记录获取对应的版本。代码也许有略微差异，但是应该不影响理解。

# 搭建2584框架

这份代码中把游戏看作是两个玩家的对局（一个是实际操作的玩家player，动作空间是{slide up, down, left, right}，另一个是游戏引擎evil，可以在空白的地方随机放置方块，概率分布是 1:90%， 2:10%）。游戏开始时evil根据概率分布随机放置两个方块tile，然后player和evil轮流进行自己的回合，直到player上下左右都划不动的时候判断游戏结束。

代码结构：
- 2584.cpp（入口函数，控制游戏整体流程）
- action.h（将player或者evil的动作应用在棋盘上）
- agent.h（实现player和evil的细节，这两个类都继承自agent类）
- board.h（定义棋盘以及游戏的规则）
- statistic.h（记录历史盘面的对局信息，并且统计胜率等）

# 2584.cpp(游戏流程)

跟基本的RL写法类似，游戏初始的时候解析一些定义的参数，结束的时候保存等。中间是实现的逻辑：

``` cpp
while (!stat.is_finished()) {
    play.open_episode("~:" + evil.name());
    evil.open_episode(play.name() + ":~");
    stat.open_episode(play.name() + ":" + evil.name());
    board game = stat.make_empty_board();
    while (true) {
        agent& who = stat.take_turns(play, evil);
        action move = who.take_action(game);
        if (move.apply(game) == -1) break;
        stat.save_action(move);
        if (who.check_for_win(game)) break;
    }
    agent& win = stat.last_turns(play, evil);
    stat.close_episode(win.name());

    play.close_episode(win.name());
    evil.close_episode(win.name());
}
```

其中stat会有一个值定义了这次要跑多少局游戏（player要挂掉多少次），一个外层的while循环就是一局游戏，每个循环的前三行是传信息到相关的类里面新的一局游戏开始了。主要是为了后面学习作准备，后面学习是每局游戏结束后更新相关weight进行学习。

然后新建一个空的盘面就开始内层的while循环，直到游戏结束跳出循环。目前跳出循环的代码会在玩家根据策略选择一个尽可能可行的动作，但是这个动作不可行的话就判断游戏结束。因为2584这个游戏最终一定是玩家会挂掉，游戏最后player进行一个动作，evil放置一个方块填满整个局面，player尝试四个action都不能改变局面就会导致游戏失败。

# action.h

这个文件中的代码比较简单，除了构造函数外几个基本的函数如下（name函数是把player或者evil的操作转换成容易理解的字符串，展示讯息使用的，这里没有列出来）

``` cpp
int apply(board& b) const {
    if ((0b11 & opcode) == (opcode)) {
        // player action (slide up, right, down, left)
        return b.move(opcode);
    } else if (b(opcode & 0x0f) == 0) {
        // environment action (place a new tile)
        b(opcode & 0x0f) = (opcode >> 4);
        return 0;
    }
    return -1;
}

static action move(const int& oper) {
    return action(oper);
}

// 这里把序号和位置放在了一起，最后四位表示放置的位置(0000~1111)，前面是数列的索引
static action place(const int& tile, const int& pos) {
    return action((tile << 4) | (pos));
}
```

其中比较需要注意的是place这个函数只表示evil在盘面的某个位置放置特定数值的方块，move仅提供给玩家移动。最后的返回值都是一个action类型的实例，最后会通过apply函数真正作用在盘面上，所以apply函数中会在一开始进行判断，当前这个action是player的还是evil的，然后返回这个action的reward，evil的回合reward永远是0，因为只产生一个新的方块，没有合并方块。

> 这里需要注意的是，在这个游戏中，tile仅表示数列的索引，而不是上面的数值，比如方块3和方块5合并产生8，由于{3, 5, 8}的索引分别是{3, 4, 5}，所以游戏内部的逻辑是第三个方块和第四个方块合并产生了第五个方块。这份代码中只有显示和计算得分的地方才会把索引转换成对应的数值。

> 比如上面的place函数表示的逻辑是把特定的方块放在局面特定的位置，就是用的序号代表的方块而不是数值。例如action::place(5, 0)表示的是在盘面的左上角放置数值为8的方块。

> 具体盘面的索引和数列的索引参照board.h

# agent.h

这个类中定义了player和evil的行动策略，并且在后续会加入对行动策略的训练达到学习的效果。

在这个project中，暂时采用最原始的随机方法来进行游戏，由于这个project还没有涉及到学习策略，所以不需要关注open_episode和close_episode函数，check_for_win目前没有用到，之前提到过判断游戏结束的标志是player找不到合法的动作就判定游戏结束。

所以这个project中关注的是两个子类的take_action函数。

## rndenv类（evil的类别，表示游戏引擎）

``` cpp
virtual action take_action(const board& after) {
    int space[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
    std::shuffle(space, space + 16, engine);
    for (int pos : space) {
        if (after(pos) != 0) continue;
        std::uniform_int_distribution<int> popup(0, 9);
        int tile = popup(engine) ? 1 : 2;
        return action::place(tile, pos);
    }
    return action();
}
```

> 这里参数中写的是after，应该是为了后面的project中考虑，在project2中会用TDLearning学习player的行动策略，在每次player进行步骤之后会记录下行动前后的局面，那个地方使用的就是before和after，并且那个after刚好和这个表示的意义相同，evil就是在player的after基础上行动的。

## player类（表示一般意义上的玩家）

``` cpp
virtual action take_action(const board& before) {
    int opcode[] = { 0, 1, 2, 3 };
    std::shuffle(opcode, opcode + 4, engine);
    for (int op : opcode) {
        board b = before;
        if (b.move(op) != -1) return action::move(op);
    }
    return action();
}
```

这里采用了随机的动作，只是如果当前随机的动作不能移动局面，则会开始下一个随机的动作。只有在所有action都不合法的情况下才会返回一个空的action，并且这个action在apply到局面上的时候会产生-1的reward，代表游戏结束。

里面的for循环代表一个个尝试action，其中的逻辑是假想一个与当前局面一样的局面，在应用了这个action后局面会产生一个reward，如果不是-1表示这个动作是可行的，就直接返回这个动作作为选定的动作，如果reward是-1则表示这个动作不可行，继续尝试下一个动作。

由于这个函数里面的局面是假想的（新建了一个board示例并初始化为before一样的值），尝试的动作一直应用在这个新的board里面，所以原先的那个局面并没有变化，原先局面是在2584.cpp文件中的```move.apply(game)```这句话中才改变的。

# board.h

这个文件中没有太多的修改，基本上是把助教提供的2048的规则运用在2584上面，修改的地方只有合并的规则，合并后的得分以及输出时候要把数列从2048换成fibonacci。

这个文件中原有的逻辑是只实现一个向左移动的函数，然后其他方向的移动通过转动和翻转盘面来实现。基本上只需要看懂向左移动的函数就差不多了，这个函数里面用了一种很巧妙的方式实现了，一开始不好理解的话在纸上稍微画一排模拟一下循环里面的步骤就好理解了。

``` cpp
bool can_combine(int& tile, int& hold){
    // 合并规则是两个值在数列中相邻或者同时为1的时候可以合并
    return (tile == 1 && hold == 1) || abs(tile - hold) == 1;
}

int move_left() {
    board prev = *this;
    int score = 0;
    for (int r = 0; r < 4; r++) {
        auto& row = tile[r];
        int top = 0, hold = 0;
        for (int c = 0; c < 4; c++) {
            int tile = row[c];
            if (tile == 0) continue;
            row[c] = 0;
            if (hold) {
                if (can_combine(tile, hold)) {
                    tile = (tile > hold) ? tile : hold;
                    row[top++] = ++tile;
                    // 得分改成了生成的方块的值
                    score += (fibonacci[tile]);
                    hold = 0;
                } else {
                    row[top++] = hold;
                    hold = tile;
                }
            } else {
                hold = tile;
            }
        }
        if (hold) tile[r][top] = hold;
    }
    return (*this != prev) ? score : -1;
}
```

其他需要修改的部分是往输出流中写当前盘面需要把数列换成fibonacci。

``` cpp
friend std::ostream& operator <<(std::ostream& out, const board& b) {
    char buff[32];
    out << "+------------------------+" << std::endl;
    for (int r = 0; r < 4; r++) {
        std::snprintf(buff, sizeof(buff), "|%6u%6u%6u%6u|",
            (fibonacci[b[r][0]]),
            (fibonacci[b[r][1]]),
            (fibonacci[b[r][2]]),
            (fibonacci[b[r][3]]));
        out << buff << std::endl;
    }
    out << "+------------------------+" << std::endl;
    return out;
}
```

这个文件中其他的部分都没有作修改，有些不好理解的地方可以尝试在纸上画画就蛮好懂：

``` cpp
int move_right() {
    reflect_horizontal();
    int score = move_left();
    reflect_horizontal();
    return score;
}
int move_up() {
    rotate_right();
    int score = move_right();
    rotate_left();
    return score;
}
int move_down() {
    rotate_right();
    int score = move_left();
    rotate_left();
    return score;
}

void transpose() {
    for (int r = 0; r < 4; r++) {
        for (int c = r + 1; c < 4; c++) {
            std::swap(tile[r][c], tile[c][r]);
        }
    }
}

void reflect_horizontal() {
    for (int r = 0; r < 4; r++) {
        std::swap(tile[r][0], tile[r][3]);
        std::swap(tile[r][1], tile[r][2]);
    }
}

void reflect_vertical() {
    for (int c = 0; c < 4; c++) {
        std::swap(tile[0][c], tile[3][c]);
        std::swap(tile[1][c], tile[2][c]);
    }
}

/**
* rotate the board clockwise by given times
*/
void rotate(const int& r = 1) {
    switch (((r % 4) + 4) % 4) {
    default:
    case 0: break;
    case 1: rotate_right(); break;
    case 2: reverse(); break;
    case 3: rotate_left(); break;
    }
}

void rotate_right() { transpose(); reflect_horizontal(); } // clockwise
void rotate_left() { transpose(); reflect_vertical(); } // counterclockwise
void reverse() { reflect_horizontal(); reflect_vertical(); }
```

# statistic.h

这个文件中记录最近的局面细节，并进行统计。首先需要了解类里面的一些变量：
- count： 是指的当前进行了多少盘游戏
- limit： 记录多少场游戏的细节（一开始因为没有这个参数导致记录的太多内存不够，project 2中加入了这个可选参数）
- block： 每进行多少场游戏输出一次统计信息
- total： 在运行程序的时候指定的这次需要运行多少局游戏

基本上理解了上面几个变量就可以读懂这个文件的代码了。

统计信息的格式长这样：

``` cpp
/**
* show the statistic of last 'block' games
*
* the format would be
* 10000	avg = 46172, max = 137196, ops = 218817
*	233 	100%	(0.1%)
*	377 	99.9%	(0.2%)
*  	610 	99.7%	(1.5%)
*	987 	98.2%	(4.7%)
*	1597	93.5%	(32%)
*	2584	61.5%	(41.2%)
*	4181	20.3%	(17.7%)
*	6765	2.6%	(2.6%)
*
* where (assume that block = 1000)
*  '10000': current index (n)
*  'avg = 46172': the average score of saved games is 46172
*  'max = 137196': the maximum score of saved games is 137196
*  'ops = 218817': the average speed of saved games is 218817
*  '61.5%': 61.5% (615 games) reached 2584-tiles in saved games (a.k.a. win rate of 2584-tile)
*  '41.2%': 41.2% (412 games) terminated with 2584-tiles (the largest) in saved games
*/
```

产生这个信息的函数是show()，要把里面的代码修改成2584的代码：

``` cpp
void show() const {
    int block = std::min(data.size(), this->block);
    size_t sum = 0, max = 0, opc = 0, stat[POSSIBLE_INDEX] = { 0 };
    uint64_t duration = 0;
    auto it = data.end();
    for (int i = 0; i < block; i++) {
        auto& path = *(--it);
        board game;
        size_t score = 0;
        for (const action& move : path)
            score += move.apply(game);
        sum += score;
        max = std::max(score, max);
        opc += (path.size() - 2) / 2;
        int tile = 0;
        for (int i = 0; i < 16; i++)
            tile = std::max(tile, game(i));
        stat[tile]++;
        duration += (path.tock_time() - path.tick_time());
    }
    float avg = float(sum) / block;
    float coef = 100.0 / block;
    float ops = opc * 1000.0 / duration;
    std::cout << count << "\t";
    std::cout << "avg = " << unsigned(avg) << ", ";
    std::cout << "max = " << unsigned(max) << ", ";
    std::cout << "ops = " << unsigned(ops) << std::endl;
    // t表示的是数列的序号
    // stat[i]: 数列中第i个元素是这次游戏中最大值的次数
    // c表示的是在这个循环里面一共统计了多少次最大次数，按照block=1000的情况就是c不会大于1000
    for (int t = 0, c = 0; c < block; c += stat[t++]) {
        if (stat[t] == 0) continue;
        int accu = std::accumulate(stat + t, stat + POSSIBLE_INDEX, 0);
        std::cout << "\t" << fibonacci[t] << "\t" << (accu * coef) << "%";
        std::cout << "\t(" << (stat[t] * coef) << "%)" << std::endl;
    }
    std::cout << std::endl;
}
```

其中POSSIBLE_INDEX是2584游戏中可能达到的最大索引，2048的最大索引就是16（理论上应该是17）,但是2584会远远比这个大，具体是多少没有算，应该在24左右，这边预留的是32。

> 关于2048的索引最大值，模板代码中采用的方式是1作为第一个索引，对应的值是2（可以参照模板中evil的take_action，以及原本statistic中的show函数），理论上2048出现的最大方块的值是131072，对应的索引应该是17,但是由于这个值一旦出现游戏就结束（因为格子必然已经塞满了）并且出现的概率特别特别低，所以为了节省空间就不考虑这个出现的情况了。

# 运行

至此游戏主要内容已经搭建完成，编译后就可以运行查看结果了

> windows需要安装g++（我用的好像叫做TMD-GCC），并且复制mingw32-make.exe文件为make.exe，否则不识别make指令，如果不使用makefile可以忽略这一步

在命令行中切到代码所在的目录。新建makefile：

```
all:
	g++ -std=c++0x -O3 -g -Wall -fmessage-length=0 -o 2584 2584.cpp 
clean:
	rm 2584
```

执行（由于这里用的随机策略，所以跑很多局没有意义，用1000局看下效果就行了，统计结果存在了stat.bin文件中）：

``` sh
./2584 --save=stat.bin --total=1000
```

> 可选参数解释：
> - total: 最多进行的游戏局数
> - block: 每多少局输出统计信息
> - limit: 最多保存多少局的详细信息
> - load: 读取统计信息和weights的位置
> - save: 保存统计信息和weights的位置
> - summary: 结束时是否输出统计信息

查看测试程序和速度(似乎只有ubuntu系统能跑)：

测试程序的用法可以参照测试的说明文档

``` sh
./test/2584-judge --load=stat.bin --check
./test/2584-judge --load=stat.bin --check --check
./test/2584-speed
```

# 参考

1. [I-Chen Wu, Ph.D. Homepage](http://java.csie.nctu.edu.tw/~icwu/chindex.html)
2. [游戏2048的理论最高分是多少？ - 知乎](https://www.zhihu.com/question/23089100)
3. [TDM-GCC wikipedia](https://en.wikipedia.org/wiki/TDM-GCC)