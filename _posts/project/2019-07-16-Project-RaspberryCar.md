---
date: 2019-7-16 22:14
status: public
title: '[实作]树莓派打造小车'
layout: post
tag: [硬件, Raspberry]
categories: [project]
description: 
---

* 目录 
{:toc}

# 关于

刚开始接触树莓派，想了解一下怎么跟其他的硬件互动的，就打算做个简单的项目熟悉一下能实现的效果。

目前只实现了基本的控制，找了一个讨巧的办法是手机或者电脑用ssh，输入指令控制小车的功能。后面加入了无线手柄控制的功能，不过由于是手柄本身带有的无线收发器，所以虽然是无线手柄，代码跟有线的一样写，简化了很多工作。

# 整体架构

硬件部分有三块板子，可以理解成三个模块：电机，控制，电源

<!-- 代码：<https://github.com/junmo1215/rpi_car> -->

整体架构如下

![rpi_l298n]({{ site.url }}/images/20190716_1.png)

最终成品：

![20190716_8]({{ site.url }}/images/20190716_8.png)

# 硬件

## L298N

L298N是电机驱动模块，通过IN1 ~ IN4的电位不同控制电机的正转和反转，另外还有两个跳帽编号是enableA和enableB，开启了这两个才能控制电机的转或者不转

![20190716_2]({{ site.url }}/images/20190716_2.png)

> L298N一开始enableA和enableB是用跳帽连接起来的，需要把跳帽去掉，一边接树莓派接受控制信号，另一边悬空就行。

由于L298N模块是只能控制两个电机，所以有四个电机的话，可以考虑左边两个电机接OUT1和OUT2，右边两个接OUT3和OUT4。需要注意的是由于不同电机性能不同，可能导致相同电压造成的转速不同，也就是说同一侧的轮子转速可能会不一样。不过感觉差距不太大的话影响还好，实际测试发现小车还是能走直线的，所以真的遇到了这个问题，可以考虑加一块L298N，调整一个参数，让同一侧的轮子转速相同。或者干脆直接只接两个电机。

电机的转速控制一般是采用脉冲宽度调制（Pulse width modulation，PWM），简单来说就是改变单位时间高电平的占空比来达到不同电压控制的方法。

占空比的简单示意图

![20190716_3]({{ site.url }}/images/20190716_3.png)

## 控制部分

控制部分目前采用的是树莓派，不过小车的话用arduino也足够了，后续也有把控制部分换成arduino的想法。基本原理都是用程序控制引脚的电平高低。

树莓派上面有40个引脚，除了几个固定的电平之外，大部分都是GPIO引脚（能控制电平高低的引脚），编号如下：

![20190716_4]({{ site.url }}/images/20190716_4.png)

或者也可以在树莓派中执行`gpio readall`查看

![20190716_5]({{ site.url }}/images/20190716_5.png)

这里使用的是5,6,13,19这几个引脚接L298N的IN1 ~ IN4用来控制电平高低，20和21分别接enableA和enableB，作为PWM引脚控制电机转速。基本是代码控制，接线部分比较简单。

## 电源部分

电源部分一开始没有使用单独的板子，用移动电源给树莓派供电，但是树莓派电力不够驱动电机，因此单独接了两节18650电池驱动电机。电源的正负极分别接在L298N的+12V和GND（接地）。

L298N正常工作的情况下，输出电压与输入电压是相同的，因此OUT1与OUT2的电压差应该是8V左右（两节18650电池串联的电压），一开始有段时间接上线之后，OUT1与OUT2之间的电压差始终只有3V，但是18650电池都是有电的，找了资料后才发现是由于L298N和树莓派没有共地。L298N供电的5V如果是用另外电源供电的话，（即不是和单片机的电源共用），那么需要将单片机的GND和模块上的GND连接在一起，只有这样单片机上过来的逻辑信号才有个参考0点。

这个时候如果代码没有问题，小车已经可以正常工作了，不过还是发现移动电源太占地方，所以想尝试电池给树莓派直接供电的方式。

网上看到有人用L298N的5V输出给树莓派供电的方法，因为L298N在输入电压小于12V的情况下，能对外提供5V的供电，但是输入电压大于12V就不能对外供电了。我这边输入电压是8V左右所以理论上可以这么接。线路图大概是这样

![20190716_6]({{ site.url }}/images/20190716_6.png)

然后我试了一下，基本上起不来，不确定原因是啥，大概是树莓派的功耗有点大，L298N没有办法稳定向外提供5V的电压，导致L298N挂掉了。最后还是买了块稳压模块解决的问题，稳压模块拿到的时候先要调整电位器，让输出电压在5V，考虑到接触电阻的损耗，我是多调了一点点，在5.1V左右。

![20190716_7]({{ site.url }}/images/20190716_7.png)

# 软件

软件部分使用的是python，手柄控制车子行动，通过差速实现车子转弯。由于我的无线手柄带一个接收器，所以插在树莓派的USB口上就行了，也就是说无线信号的接收和发送部分不需要自己代码实现，把这个手柄当一个普通的USB有线手柄就行。

所以接下来要处理的事情只有两个：实现一个小车的类，提供小车各种运动的接口；接受手柄信号并控制小车运动。

## Car

这个类里面有三个主要维护的变量：base_speed、left_rate、right_rate。base_speed表示小车直线行驶的速度，把这个速度作为基准，需要小车往左转时，右边轮胎的速度保持base_speed，左边轮胎的速度变为left_rate * base_speed，由于left_rate值在0到1之间，所以会导致左边的速度小于右边轮胎，从而形成差速达到转弯的效果。

这个类的代码：

``` py
class Car():
    # 树莓派接L298N的enable A/B的引脚
    ENABLE_A = 20
    ENABLE_B = 21
    # IN1 ~ 4的引脚编号
    INS = [6, 5, 13, 19]
    def __init__(self):
        # 初始化引脚
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(Car.ENABLE_A, GPIO.OUT)
        GPIO.setup(Car.ENABLE_B, GPIO.OUT)
        for in_number in Car.INS:
            GPIO.setup(in_number, GPIO.OUT)

        self.pwm_left = GPIO.PWM(Car.ENABLE_A, 80)
        self.pwm_left.start(0)
        self.pwm_right = GPIO.PWM(Car.ENABLE_B, 80)
        self.pwm_right.start(0)

        self.motor_left = Car.INS[:2]
        self.motor_right = Car.INS[2:]

        self.state = {
            "base_speed": 0,
            "left_rate": 1,
            "right_rate": 1
        }

    def __del__(self):
        self.pwm_left.stop()
        self.pwm_right.stop()
        GPIO.cleanup()

    @staticmethod
    def __motor_forward(motor):
        # 控制电机转动，下面两个类似，省去了实现
        GPIO.output(motor[0], GPIO.HIGH)
        GPIO.output(motor[1], GPIO.LOW)
    # def __motor_backward(motor):
    # def __motor_stop(motor):

    def forward(self):
        Car.__motor_forward(self.motor_left)
        Car.__motor_forward(self.motor_right)
    # def back(self):
    # def stop(self):

    def left(self, rate):
        """
        左转弯的时候，右边轮胎速度不变，左边速度为右边速度 * rate
        rate值为0到1之间
        """
        self.state["left_rate"] = rate

    def right(self, rate):
        self.state["right_rate"] = rate

    def speed(self, val):
        self.state["base_speed"] = val
        self.pwm_left.ChangeDutyCycle(val * self.state["left_rate"])
        self.pwm_right.ChangeDutyCycle(val * self.state["right_rate"])

    def get_status(self):
        return self.state["base_speed"], \
            self.state["base_speed"] * self.state["left_rate"], \
            self.state["base_speed"] * self.state["right_rate"]
```

## 接收手柄信号并且对小车下发指令

这里用的pygame，实现的比较粗糙，其中方向用的是左边摇杆，油门按键是R2，刹车按键是L2。所以能实现连续值的输入

主要代码如下：

``` py
# 定义油门，刹车，转弯在手柄上的按键
ACCELERATOR = 5
BREAK = 2
TURN = 0

while True:
    # 读取按键值
    accelerator_axis = joystick.get_axis(ACCELERATOR)
    break_axis = joystick.get_axis(BREAK)
    turn_axis = joystick.get_axis(TURN)

    # 将按键值影射到0到100
    speed_forward = axis_value_to_speed(accelerator_axis)
    speed_backward = axis_value_to_speed(break_axis)
    speed_delta = speed_forward - speed_backward

    # 方向控制
    if turn_axis < 0:
        car.left(1 + turn_axis)
        car.right(1)
    elif turn_axis > 0:
        car.right(1 - turn_axis)
        car.left(1)
    else:
        car.left(1)
        car.right(1)

    # 速度控制
    if speed_forward > speed_backward:
        car.forward()
        car.speed(speed_delta)
    elif speed_forward < speed_backward:
        car.back()
        car.speed(-speed_delta)
    else:
        car.stop()
```

# 参考

- [GPIO - Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/usage/gpio/)
- [L298N 驱动模块驱动电机以及供电注意 - 米兰百分百](http://www.milan100.com/article/show/2440)
