---
date: 2020-10-29 23:32
status: public
title: '[实作]制作自己的ESP8266名片'
layout: post
tag: [硬件, ESP8266]
categories: [project]
description: 
---

* 目录 
{:toc}

## 关于

这个项目我最初是看到了这个项目（[businesscard-linux](https://github.com/thirtythreeforty/businesscard-linux)）觉得很酷炫，然而没有进一步了解，直到某天看到立创（[16块钱做了张ESP8266「名片」V1.2](https://lceda.cn/Giftina/ESP8266_CARD) [@Giftina](https://lceda.cn/Giftina)）上有人做了个类似的东西，瞅了瞅觉得应该可行，于是开始尝试照着别人的加上自己摸索着试试。

这个项目的想法还是跟别人的一样定位是一张名片，两边的丝印印上自己的基本信息以及板子的信息。原始的项目是名片插电脑上之后，使用串口执行python或者玩两个小游戏的彩蛋，但是感觉对用户的定位还是偏高（比如我之前就不知道串口是啥），因此我设计的使用场景是上电后将名片变成一个无线接入点（Access Point, AP），其他设备连上指定的WiFi后，通过页面能看到储存在卡片中的内容，通过网页将里面的信息展示出来。

刚好立创上的这个项目使用的是[ESP8266](https://www.espressif.com/zh-hans/products/socs/esp8266)，这个芯片的特点是便宜、有WiFi功能、有一些方便开发的固件。有WiFi功能意味着没准可以作为AP或者客户端使用，另外还有4M的flash，里面存网页的需求应该也可以满足。

## Demo

外观：

![20201029_1]({{ site.url }}/images/20201029_1.png)

连接卡片WiFi，浏览器打开192.168.1.155

![20201029_7]({{ site.url }}/images/20201029_7.png)

## 硬件

由于没有硬件基础，板子抄过来之后元件什么的都没有改动（感谢大佬[@Giftina](https://lceda.cn/Giftina)的开源）。只改了改丝印上面的文字和二维码就拿去打样了，也体验了一下[立创EDA](https://lceda.cn/)和[深圳嘉立创](https://www.jlc.com/)的流程，感觉太强啦。

> 正面微信二维码中间的头像需要PS处理一下，要不然制版会很奇怪，导入图片的时候就能发现问题。

![20201029_2]({{ site.url }}/images/20201029_2.png)

在立创上改完板子丝印之后可以下载Gerber文件，直接在嘉立创上面下单打样就可以了，其他的元器件都可以在立创上使用BOM单购买。

不过这个板子有个问题，USB接触不太好，所以每次插到USB口之后得塞点卡片固定住防止接触不良，不过使用Type-C口没有这个问题（Type-C口真的是太难焊接了）。

## 系统

名片本身其实就是一个ESP8266开发板，所以直接使用网上ESP8266的教程就可以了。

一般来说有三种开发方式可供选择：
- [NodeMCU](https://nodemcu.readthedocs.io/en/release/) + lua
- [MicroPython](https://docs.micropython.org/en/latest/esp8266/tutorial/intro.html) + python
- [Arduino](https://github.com/esp8266/Arduino) + C

这里我选择的是使用lua开发

首先是下载固件然后烧录到卡片里，烧录工具使用的是官方的（[flash_download_tool_v3.8.5_1.zip](https://www.espressif.com/sites/default/files/tools/flash_download_tool_v3.8.5_1.zip)），需要注意的是烧录的时候需要按住Flash键，然后开始烧录的时候按下reset键才会烧录进去，否则会一直等待确认信号。这时候烧录工具控制台一直打印`....._____.....____`

> 不过有些板子改了这部分电路，好像不需要按按键也可以烧录了，取决于对应的板子

波特率选择115200（上传代码时候波特率为9600），先点击擦除然后再开始烧录

![20201029_3]({{ site.url }}/images/20201029_3.png)

将固件烧录到卡片里面之后，就可以使用lua进行开发了，这里使用了[NodeMCU-Tool](https://github.com/andidittrich/NodeMCU-Tool)这个项目，他能将代码上传到卡片里，执行卡片中的lua文件，以及串口交互等，足够满足这个项目需求。

NodeMCU-Tool支持的指令：

``` sh
λ node ./nodemcu-tool.js --help
Usage: nodemcu-tool [options] [command]

Options:
  -V, --version                output the version number
  -p, --port <port>            Serial port device name e.g. /dev/ttyUSB0, COM1 (default: null)
  -b, --baud <baudrate>        Serial Port Baudrate in bps, default 115200 (default: null)
  --silent                     Enable silent mode - no status messages are shown
  --connection-delay <delay>   Connection delay between opening the serial device and starting the communication (default: null)
  --debug                      Enable debug mode - all status messages + stacktraces are shown
  --io-debug                   Enable io-debug mode - logs all serial rx/tx messages (requires enabled debug mode)
  -h, --help                   output usage information

Commands:
  fsinfo [options]             Show file system info (current files, memory usage)
  run <file>                   Executes an existing .lua or .lc file on NodeMCU
  upload [options] [files...]  Upload Files to NodeMCU (ESP8266) target
  download <file>              Download files from NodeMCU (ESP8266) target
  remove <file>                Removes a file from NodeMCU filesystem
  mkfs [options]               Format the SPIFFS filesystem - ALL FILES ARE REMOVED
  terminal [options]           Opens a Terminal connection to NodeMCU
  init                         Initialize a project-based Configuration (file) within current directory
  devices [options]            Shows a list of all available NodeMCU Modules/Serial Devices
  reset [options]              Execute a Hard-Reset of the Module using DTR/RTS reset circuit
  *
```

上传代码如果报错的话，先检查设备是否识别出来，如果识别出来了还报错可以看下这个issue <https://github.com/AndiDittrich/NodeMCU-Tool/blob/master/docs/Reset_on_Connect.md>

``` sh
nodemcu-tool.cmd upload --connection-delay 300 wifi.lua webserver.lua led.lua init.lua Welcome.html
```

> 工具地址：
> - [Flash 下载工具（ESP8266 & ESP32 & ESP32-S2）](https://www.espressif.com/zh-hans/support/download/other-tools)
> - [NodeMCU-Tool](https://github.com/andidittrich/NodeMCU-Tool)

## 软件

软件部分就是比较简单的了，在启动的时候负责设置WiFi，启动网站和打开LED灯指示卡片已经启动成功了。

所以有一个启动脚本和三个功能脚本，脚本的大致流程还比较简单，照着网站的API写基本就可以实现，代码放在了GitHub上，功能脚本对应三个文件[wifi.lua](https://github.com/junmo1215/ESP8266-businesscard/blob/main/wifi.lua)、[webserver.lua](https://github.com/junmo1215/ESP8266-businesscard/blob/main/webserver.lua)、[led.lua](https://github.com/junmo1215/ESP8266-businesscard/blob/main/led.lua)

然后在init.lua中依次执行这三个文件实现对应的功能，这边的init.lua写的比较复杂

``` lua
-- 编译并删除源文件
for i = 1, #filename_list do
    filename = filename_list[i] .. ".lua"
    if file.open(filename) then
        file.close()
        print("Compile file " .. filename .. "...")
        node.compile(filename)
        print("Remove file " .. filename .. "...")
        file.remove(filename)
    end
end
```

主要是检查下`.lua`文件是否存在，存在的话编译成`.lc`文件并删除源文件，下次就可以直接执行不用编译了。lua文件原本不用编译也可以直接执行，个人感觉这个编译是针对lua做了优化，方便ESP8266直接运行机器码。

代码都放在了这个项目中 <https://github.com/junmo1215/ESP8266-businesscard>

主要的代码还比较简单，只有一个`led.lua`跟硬件有点关系，这个脚本是用来启动WiFi和网站后，将下面的LED灯点亮的。

通过硬件原理图可以看到这个灯一边是3.3V电平，另一边是GPIO4，所以点亮的方式就是给GPIO4设置低电平就可以了。

![20201029_4]({{ site.url }}/images/20201029_4.png)

不过NodeMCU中IO序号和GPIO序号有一个映射关系，控制的IO口序号是2（<https://nodemcu.readthedocs.io/en/release/modules/gpio/>）

| IO index | ESP8266 pin | IO index | ESP8266 pin |
| -: | :-: | -: | :-: |
| 0 | GPIO16 | 7 | GPIO13 |
| 1 | GPIO5 | 8 | GPIO15 |
| 2 | GPIO4 | 9 | GPIO3 |
| 3 | GPIO0 | 10 | GPIO1 |
| 4 | GPIO2 | 11 | GPIO9 |
| 5 | GPIO14 | 12 | GPIO10 |
| 6 | GPIO12 |  |

> **D0(GPIO16) can only be used as gpio read/write. No support for open-drain/interrupt/pwm/i2c/ow.**

所以对应led开启和关闭的代码就是

``` lua
LED_PIN = 2
gpio.mode(LED_PIN, gpio.OUTPUT)

led_on = function()
    gpio.write(LED_PIN, gpio.LOW)
end

led_off = function()
    gpio.write(LED_PIN, gpio.HIGH)
end
```

上电后启动WiFi，设置自身IP为192.168.1.155，启动web服务器监听80端口，客户端连接后访问192.168.1.155，实现最终展示效果：

![20201029_6]({{ site.url }}/images/20201029_6.png)

## 随缘更新系列

### 电源指示灯等稳定后就关闭（未完成）

目前电源指示灯是长亮的，没有办法通过GPIO控制，感觉开机启动完成之后关闭掉就好了，这个功能需要改PCB

![20201029_5]({{ site.url }}/images/20201029_5.png)

### 网页使用域名访问（未完成）

目前需要通过一个IP访问到卡片中的网页，IP是内置的，感觉改成域名稍好一点

### 连接WiFi后自动弹出首页（未完成）

现在连接WiFi后要打开浏览器，输入IP才能显示页面，看能否做到自动弹出

## 参考

- [My Business Card Runs Linux](https://www.thirtythreeforty.net/posts/2019/12/my-business-card-runs-linux/#source-code)
- [我的名片能运行Linux和Python，还能玩2048小游戏，成本只要20元 - 量子位](https://zhuanlan.zhihu.com/p/99495680)
- [16块钱做了张ESP8266「名片」V1.2](https://lceda.cn/Giftina/ESP8266_CARD)
- [ESP8266 Wi-Fi MCU I 乐鑫科技](https://www.espressif.com/zh-hans/products/socs/esp8266)
- [立创EDA](https://lceda.cn/)
- [深圳嘉立创](https://www.jlc.com/)
- [NodeMCU-Tool](https://github.com/andidittrich/NodeMCU-Tool)
- [NodeMCU Documentation](https://nodemcu.readthedocs.io/en/release/)
