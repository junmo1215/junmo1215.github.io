---
date: 2018-1-11 15:33
status: public
title: '[实作]TDLearning in 2584-fibonacci (四)、expectimax search、TCL、bitboard'
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
- **bitboard**
- **temporal coherence learning(TCL)**

文章地址： <https://junmo1215.github.io/machine-learning/2018/01/11/practice-TDLearning-in-2584-fibonacci-4th.html>

代码地址： <https://github.com/junmo1215/rl_games/tree/master/2584_C%2B%2B>

> 由于后面几个project持续在做，所以获取的代码应该是后面几个project版本的代码，可以根据签入记录获取对应的版本。代码也许有略微差异，但是应该不影响理解。

# 基础框架

这次的作业要求是修改环境给出的规则：从之前的 { 80%: 1-tiles, 20%: 2-tiles } 改为 { 75%: 1-tiles, 25%: 3-tiles }。

这里直接改rndenv的概率就好了

``` cpp
virtual action take_action(const board& after) {
    int space[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
    std::shuffle(space, space + 16, engine);
    for (int pos : space) {
        if (after(pos) != 0) continue;
        std::uniform_real_distribution<> popup(0, 1);
        // 这里把概率以及对应的index改掉
        int tile = (popup(engine) > 0.25) ? 1 : 3;
        return action::place(tile, pos);
    }
    return action();
}
```

然后主要是后面的选做内容：
- 移植之前的expectimax search到正常的盘面上
- 修改board，从之前的array-board改成bitboard
- 将TDL修改为TCL(temporal coherence learning)

# 移植expectimax search

原理上与之前的一次project类似，只是由于盘面增大，没有办法使用穷举的方式得到每个盘面的期望

所以需要改成N-tuple network的估值，在代码中用get_after_except代表玩家操作之后盘面的期望值，get_before_except代表玩家操作前的期望值：

``` cpp
virtual float get_after_expect(const board& after, const int& search_deep){
    if(search_deep == 0)
        return board_value(after);

    float temp_expect_1 = 0;
    float temp_expect_3 = 0;
    for(int tile: {1, 3}){
        float expect = 0;
        int count = 0;
        for(int i = 0; i < 16; i++){
            board b = after;
            int apply_result = action::place(tile, i).apply(b);
            if(apply_result != -1){
                expect += get_before_expect(b, search_deep);
                count++;
            }
        }
        if(tile == 1)
            temp_expect_1 = expect / count;
        else if(tile == 3){
            temp_expect_3 = expect / count;
        }
    }

    float result = temp_expect_1 * 0.75 + temp_expect_3 * 0.25;
    return result;
}

virtual float get_before_expect(const board& before, const int& search_deep){
    float expect = 0;
    float best_expect = MIN_FLOAT;
    bool is_moved = false;

    for(int op: {0, 1, 2, 3}){
        board b = before;
        int reward = b.move(op);
        if(reward != -1){
            expect = get_after_expect(b, search_deep - 1) + reward;
            if(expect > best_expect){
                is_moved = true;
                best_expect = expect;
            }
        }
    }

    return is_moved ? best_expect : 0;
}
```

# 从array-board改成bitboard

首先解释一下这两个概念

在之前的project中，使用的就是array-board，也就是类似于下面这种：

``` cpp
/**
 * array-based board for 2584
 *
 * index (2-d form):
 * [0][0] [0][1] [0][2] [0][3]
 * [1][0] [1][1] [1][2] [1][3]
 * [2][0] [2][1] [2][2] [2][3]
 * [3][0] [3][1] [3][2] [3][3]
 *
 * index (1-d form):
 *  (0)  (1)  (2)  (3)
 *  (4)  (5)  (6)  (7)
 *  (8)  (9) (10) (11)
 * (12) (13) (14) (15)
 *
 */
```

无论是2-d的形式还是1-d的形式，本质上都是用一个array(或者vector等类似的概念)来表示的这个盘面，这样的做法很直观，get或者set其中某个位置的值的时候也很快。

而bitboard是另外一种形式，每个盘面有16个格子，每个格子最多有32种可能（如果是2048的话是16种可能），如果用2进制数来表示的话，2584个每个格子需要用5个位(bit)来存，16个格子就需要80个bit。所以在C++中可以考虑用两个数字来代表一个盘面：一个uint16_t和一个uint64_t

> 也可以自己做一个80个bit的数据类型，或者使用更大的类型，只是我的g++编译的时候似乎最多只认识uint64，其他的不知道要不要include什么实作好的类型

用数字代表一个盘面的好处是对于某些操作来讲会比较方便，只是2584似乎我做出来之后没有找到能优化很多的操作，所以我的最终版本里面是没有bitboard的。这里用其他的棋类举例：

假如给定一个盘面，需要判断五子棋是否有五个棋子连成一线，如果用array-board，需要取出要判断的颜色，然后得到很多坐标，再开始判断，这个操作会比较复杂。但是使用bitboard，一般是用两个数分别代表白棋和黑棋的位置，这里假设白棋盘面如下，要判断白棋是否胜利(为了简化采用 8*8 的棋盘，0表示这个位置没有白棋，1表示有白棋)：

``` cpp
// 这部分代码只是举例，真实情况代码不会这么写，并且没有验证过是否正确

/**
 * 0 0 0 0 0 0 0 0
 * 0 1 0 0 0 0 0 0
 * 0 0 1 0 0 0 1 0
 * 0 0 0 1 0 0 0 0
 * 1 0 0 0 1 0 0 0
 * 0 0 0 0 0 1 0 0
 * 1 1 0 0 0 0 0 0
 * 0 0 0 0 0 0 0 0
 */

// 假设当前盘面可以用uint64类型的变量b表示
if((b & b >> 1 & b >> 2 & b >> 3 & b >> 4) != 0)
    return "在水平方向有五颗棋子可以连成一条线";
if((b & b >> 8 & b >> 16 & b >> 24 & b >> 32) != 0)
    return "在竖直方向有五颗棋子可以连成一条线";
if((b & b >> 9 & b >> 18 & b >> 27 & b >> 36) != 0)
    return "在斜对角方向有五颗棋子可以连成一条线";
```

这种情况下，bitboard的操作远远比array-board要方便一些。

使用bitboard就可以用C++的各种移位操作来加快运算速度了，但是往往需要设计良好的bitboard。

虽然目前使用bitboard让速度变慢了，但还是在这里写下之前写的内容，当时还测试了一下变慢的原因

## bitboard设计

前面分析过一共有 $32^{16} = 2^{80}$ 种可能的盘面，所以需要80个bit来存。我的做法是用了两个数字来存，一个uint16_t，一个uint64_t

接下来就要把之前的一些函数都实作出来，包含构造函数、重载运算符、get、set、move(move_left, move_right, move_up, move_down)、show等。

## 构造函数

这里列了三个构造函数，其中_left表示高位，_right表示低位

``` cpp
bitboard() : _left(0), _right(0){}
bitboard(const uint64_t& right) : _left(0), _right(right){}
bitboard(const uint16_t& left, const uint64_t& right) : _left(left), _right(right) {}
```

## 重载运算符

主要是为了后面移位做准备，如果只是一个数字的话可以直接使用int的移位，但是两个数需要单独实现，下面列举部分实现的方法

或(```|```)、且(```&```)、反(```~```):

``` cpp
// 重载运算符 &
bitboard operator &(const bitboard& b) const{
    return bitboard(_left & b._left, _right & b._right);
}

// 重载运算符 |
bitboard operator |(const bitboard& b) const{
    return bitboard(_left | b._left, _right | b._right);
}

// 重载运算符 ~
bitboard operator ~() const{
    return bitboard(~_left, ~_right);
}

bool operator ==(const bitboard& b) const { return _left == b._left && _right == b._right; }
bool operator !=(const bitboard& b) const { return _left != b._left || _right != b._right; }
```

位运算，主要需要考虑一个数出界之后另一个数要补上的情况：

``` cpp
// 重载位运算
bitboard operator <<(const int& shift_num){
    if(shift_num == 0)
        return *this;
    bitboard result = *this;
    if(shift_num < 16){
        result._left <<= shift_num;
        result._left |= _right >> (64 - shift_num);
        result._right <<= shift_num;
    }
    else if(shift_num < 64) {
        result._left = _right >> (64 - shift_num);
        result._right <<= shift_num;
    }
    else {
        result._left = _right << (shift_num - 64);
        result._right = 0;
    }
    return result;
}

bitboard operator>>(const int& shift_num)
{
    if(shift_num == 0)
        return *this;
    bitboard result = *this;
    // 小于16和小于64的情况似乎要分开写，不知道是不是编译器参数设置的问题
    // 目前设置的情况下，下面结果可以看出问题
    // uint16_t a = 10;
    // for(int i = 0; i < 64; i++){
    //     cout << i << "\t" << (a >> i) << endl;
    // }
    if(shift_num < 16){
        result._right = (_right >> shift_num) | (uint64_t)_left << (64 - shift_num);
        result._left >>= shift_num;
    }
    else if(shift_num < 64){
        result._right = (_right >> shift_num) | (uint64_t)_left << (64 - shift_num);
        result._left = 0;
    }
    else{
        result._right = _left >> (shift_num - 64);
        result._left = 0;
    }
    return result;
}
```

直接读取(fetch)或者修改(place)一行：

``` cpp
/**
* get a 20-bit row
*/
uint32_t fetch(const int& i) const {
    bitboard b = *this;
    return ((b >> times_20[i]) & 0xfffff)._right;
}

/**
* set a 20-bit row
*/
void place(const int& i, const int& r) {
    *this = (*this & ~(bitboard(0xfffff) << times_20[i])) | (bitboard(r & 0xfffff) << times_20[i]); 
}
```

读取或者修改某一个tile：

``` cpp
/**
* get a 5-bit tile
*/
int at(const int& i) const {
    bitboard b = *this;
    return ((b >> times_5[i]) & 0x1f)._right;
}

/**
* set a 5-bit tile
*/
void set(const int& i, const int& t) {
    *this = (*this & ~(bitboard(0x1f) << times_5[i])) | (bitboard(t & 0x1f) << times_5[i]);
}
```

移动相关：

> 这中间用到了一个小技巧，就是开始的时候把所有可能的move_left的情况都存在一个uint32_t里面，并且记录下reward。之后就不需要每次重复移动的运算了，直接去查表就能得到结果了。比如有一行的四个格子的index是 0 2 2 3，用fetch取出这一行得到的uint32_t的数是 ```0b00000 00010 00010 00011```(这里用二进制表示，中间方便看就隔开了点)，然后左移计算结果是 ```0b00010 00100 00000 00000```, score_left是5（这次左移得到的分数），之后看到有一行是 0 2 2 3就能直接查出左移的结果和分数了，右移也是类似。下面的实作代码中就直接用了这个移动的结果(前面计算的这个过程没有放在下面)

``` cpp
/**
* apply an action to the board
* return the reward gained by the action, or -1 if the action is illegal
*/
int move(const int& opcode) {
    switch (opcode) {
    case 0: return move_up();
    case 1: return move_right();
    case 2: return move_down();
    case 3: return move_left();
    default: return -1;
    }
}

int move_left() {
    bitboard move = 0;
    bitboard prev = *this;
    int score = 0;
    lookup::find(fetch(0)).move_left(move, score, 0);
    lookup::find(fetch(1)).move_left(move, score, 1);
    lookup::find(fetch(2)).move_left(move, score, 2);
    lookup::find(fetch(3)).move_left(move, score, 3);
    *this = move;
    return (move != prev) ? score : -1;
}

int move_right() {
    bitboard move = 0;
    bitboard prev = *this;
    int score = 0;
    lookup::find(fetch(0)).move_right(move, score, 0);
    lookup::find(fetch(1)).move_right(move, score, 1);
    lookup::find(fetch(2)).move_right(move, score, 2);
    lookup::find(fetch(3)).move_right(move, score, 3);
    *this = move;
    return (move != prev) ? score : -1;
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
```

旋转，翻折(前面的move用到了，在array-board里面也有类似的代码，主要是简化move的实现)：

参考了2048的版本：

<https://github.com/moporgic/TDL2048-Demo/blob/master/2048.cpp>

``` cpp
/**
    * swap row and column
    * +------------------------+
    * |     1     3     7     2|
    * |     3     5     6     8|
    * |     1     2     5     7|
    * |     2     1     3     4|
    * +------------------------+
    * 
    * 变成下面这种
    * +------------------------+
    * |     1     3     1     2|
    * |     3     5     2     1|
    * |     7     6     5     3|
    * |     2     8     7     4|
    * +------------------------+
    * 
    * 
    */
void transpose() {
    bitboard result = *this;
    result = (result & bitboard(0xf83e, 0x7c1ff83e007c1f)) | ((result & bitboard(0x0, 0xf83e000000f83e0)) << 15) | ((result & bitboard(0x7c1, 0xf0000007c1f00000)) >> 15);
    result = (result & bitboard(0xffc0, 0xffc00003ff003ff)) | ((result & bitboard(0x0, 0xffc00ffc00)) << 30) | ((result & bitboard(0x3f, 0xf003ff0000000000)) >> 30);
    *this = result;
}

/**
    * horizontal reflection
    * +------------------------+       +------------------------+
    * |     1     3     7     2|       |     2     7     3     1|
    * |     3     5     6     8|       |     8     6     5     3|
    * |     1     2     5     7| ----> |     7     5     2     1|
    * |     2     1     3     4|       |     4     3     1     2|
    * +------------------------+       +------------------------+
    */
void reflect_horizontal() {
    bitboard result = *this;
    result = ((result & bitboard(1, 0xf0001f0001f0001f)) << 15) | ((result & bitboard(0x3e, 0x3e0003e0003e0)) << 5)
        | ((result & bitboard(0x7c0, 0x7c0007c0007c00)) >> 5) | ((result & bitboard(0xf800, 0xf8000f8000f8000)) >> 15);
    *this = result;
}

/**
    * vertical reflection
    * +------------------------+       +------------------------+
    * |     1     3     7     2|       |     2     1     3     4|
    * |     3     5     6     8|       |     1     2     5     7|
    * |     1     2     5     7| ----> |     3     5     6     8|
    * |     2     1     3     4|       |     1     3     7     2|
    * +------------------------+       +------------------------+
    */
void reflect_vertical() {
    bitboard result = *this;
    result = ((result & bitboard(0, 0xfffff)) << 60) | ((result & bitboard(0, 0xfffff00000)) << 20)
        | ((result & bitboard(0, 0xfffff0000000000)) >> 20) | ((result & bitboard(0xffff, 0xf000000000000000)) >> 60);
    *this = result;
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

## bitboard性能比较

这个bitboard的实作不知道是由于bug还是设计的问题，整体上效率比之前的array-board还要慢，后来我认为是移位的时候的问题（因为有一个tile被分在了_left和_right里面，_left的最低位 + _right的四个最高位拼起来才代表这个数字，导致取数到这附近的时候都和纠结）我用了两个uint64_t来表示盘面（每个uint64_t代表两行，这样能优化很多移位的代码）但是效率还是很慢

然后特地用代码测试了一下这两种方法用到的一些函数，具体结果已经找不到了，似乎是set跟at速度要慢一些，好像还包含一个reflect_vertical。推测可能是其他位置的代码中使用set和at比较多，所以整体上效率没有很高。

并且这个bitboard没有优化计算的问题，原始方法效率还可以。唯一使用的技巧就是上面提到的记录每一行左移和右移的结果，之后用查找代替了计算。

# temporal coherence learning(TCL)

这部分其实没有细看paper，只是照着paper里面的伪代码实现了一下，结果很简洁，效果很好。就只能按照我目前的理解，由于TDL的方式没有动态的更改learning rate，在学到后面的时候有点不太容易收敛（举个不太恰当的例子，比如某个状态离理想值只有0.001，但是learning rate是0.1就很尴尬了），所以就有人提出一种自动调整learning rate的算法，也就是TCL，用这种方式能在学习的过程中动态调整learning rate，也能在后面比较快的收敛。同样的时间内学习的速度更快。

通过TCL的公式也能大致看出来这个方法在做什么，针对每个状态添加了两个变量E和A，这两个变量的作用就是调整learning rate。每次迭代的同时也会改变这个状态的这两个数的值。

![20180111201726](http://7xrop1.com1.z0.glb.clouddn.com/others/machine-learning/20180111201726.png)

对应的代码也比较好改，这边只写出一个update的地方：

``` cpp
void train_weights(const board& b, const board& next_b, const int reward){
    float delta = reward + board_value(next_b) - board_value(b);
    for(int i = 0; i < TUPLE_NUM; i++){
        long feature = get_feature(b, indexs[i]);
        float temp_learning_rate;
        float a_feature = weightsA[i][feature];
        if(a_feature == 0)
            temp_learning_rate = 1;
        else
            temp_learning_rate = fabs(weightsE[i][feature]) / a_feature;

        weights[i][feature] += alpha * delta * temp_learning_rate;
        weightsE[i][feature] += delta;
        weightsA[i][feature] += fabs(delta);
    }
}
```

不过如果使用TCL的话内存的使用量是TDL的三倍，虽然训练速度会快一点，结果会好一点，但是由于内存限制需要把MAX_INDEX改小，这会导致结果变差，综合考虑有点不确定最好的结果是怎么样的，最后写完了之后也没有电脑跑结果就一直没有测试最终的分数。

# 2584-fibonacci全部文章地址

1. [[实作]TDLearning in 2584-fibonacci (一)、搭建基础框架](https://junmo1215.github.io/machine-learning/2017/10/22/practice-TDLearning-in-2584-fibonacci-1st.html)
2. [[实作]TDLearning in 2584-fibonacci (二)、实现TD0](https://junmo1215.github.io/machine-learning/2017/11/27/practice-TDLearning-in-2584-fibonacci-2nd.html)
3. [[实作]TDLearning in 2584-fibonacci (三)、在2x3的盘面上完成expectimax search](https://junmo1215.github.io/machine-learning/2017/12/02/practice-TDLearning-in-2584-fibonacci-3rd.html)
4. [[实作]TDLearning in 2584-fibonacci (四)、expectimax search、TCL、bitboard](https://junmo1215.github.io/machine-learning/2018/01/11/practice-TDLearning-in-2584-fibonacci-4th.html)
5. [[实作]TDLearning in 2584-fibonacci (五)、实作evil对抗自己的AI](https://junmo1215.github.io/machine-learning/2018/01/18/practice-TDLearning-in-2584-fibonacci-5th.html)

# 参考

1. [chessprogramming - General Setwise Operations](https://chessprogramming.wikispaces.com/General+Setwise+Operations)
2. [moporgic/TDL2048-Demo: Temporal Difference Learning for Game 2048 (Demo)](https://github.com/moporgic/TDL2048-Demo)
3. [Mastering 2048 with Delayed Temporal Coherence Learning, Multi-Stage Weight Promotion, Redundant Encoding and Carousel Shaping](https://arxiv.org/pdf/1604.05085.pdf)
