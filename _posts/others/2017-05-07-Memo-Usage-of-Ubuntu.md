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
	- 启动终端（系统设置(System Settings) - 键盘(Keyboard) - 快捷键(Shortcuts)）
	- 切换输入法（系统设置(System Settings) - 文本输入(Text Entry)）
2. 修改电源选项（系统设置 - 电源）
3. 修改窗口菜单栏位置（系统设置(System Settings) - 外观(Appearance) - 行为(Behavior) - 显示窗口菜单(Show the menus for a window)）
4. 开启工作区（系统设置(System Settings) - 外观(Appearance) - 行为(Behavior) - 开启工作区(Enable workspaces)）
5. 修改终端复制粘贴快捷方式（终端菜单栏 - 编辑(Edit) - 首选项(Preferences) - 快捷键(Shortcuts)）
6. 调整输入法
	- System Settings - Language Support - Keyboard input method system 改成fcitx
	- Text Entry中增加input source(Pinyin)
7. 安装git，同步.gitconfig文件（C:\Users\MyLogin\.gitconfig -> ~/.gitconfig）
8. 安装ssh server, screen, htop, terminator, vscode
9. 设置默认编辑器为vim`echo export EDITOR=/usr/bin/vim >> ~/.bashrc `

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

如果出现mujoco-py相关的安装错误，先试试 ```pip install -U 'mujoco-py<1.50.2,>=1.50.1'```

如果仍然不成功，再尝试源码安装：

``` sh
git clone https://github.com/openai/mujoco-py  
cd mujoco-py  
pip install -e . --no-cache  
```

接下来再安装openAI gym应该就没有问题了

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

配置screen允许滚动：
编辑~/.screenrc增加下面两句话
```
termcapinfo xterm* ti@:te@
termcapinfo xterm|xterms|xs|rxvt 'hs:ts=\E]2;:fs=07:ds=\E]2;screen07'
```

参考：
- [linux - How to assign name for a screen? - Stack Overflow](https://stackoverflow.com/questions/3202111/how-to-assign-name-for-a-screen)
- [使screen支持滚动 - Beauty of Life, Beauty of CS](http://rex-shen.net/%E4%BD%BFscreen%E6%94%AF%E6%8C%81%E6%BB%9A%E5%8A%A8/)
- [scrolling - Is there a way to make Screen scroll like a normal terminal? - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/43229/is-there-a-way-to-make-screen-scroll-like-a-normal-terminal)
- [How to scroll in GNU Screen - SaltyCrane Blog](https://www.saltycrane.com/blog/2008/01/how-to-scroll-in-gnu-screen/)

# 安装 ssh server(OpenSSH Server)

## 1. 安装

``` sh
sudo apt-get install openssh-server
```

## 2. 取消root登入权限

``` sh
sudo vi /etc/ssh/sshd_config
```

找到 PermitRootLogin 设定，改为 No

> vi 指令:
> - i (insert)  由游標之前加入資料。
> - x  刪除游標所在該字元。
> - X  刪除游標所在之前一字元。

## 3. 重启ssh服务

``` sh
sudo /etc/init.d/ssh restart
```

## 4. 连接

连接的时候会比较之前的key，如果重新安装了ssh的话会更改原有的key，导致连接的时候会提示：

``` sh
$ ssh username@*ip_address_or_hostname*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ECDSA key sent by the remote host is
SHA256: .....
Please contact your system administrator.
Add correct host key in .ssh/known_hosts to get rid of this message.
Offending ECDSA key in .ssh/known_hosts:
ECDSA host key for *ip_address_or_hostname* has changed and you have requested strict checking.
Host key verification failed.
```

由于这边知道是因为重新安装导致可KEY更改，所以直接清除掉原有的key就行了

``` sh
ssh-keygen -R *ip_address_or_hostname*
```

windows的清除方法是直接修改文件

``` sh
# %USERPROFILE% 指的是用户主目录，就是存放下载、文档那些目录的地方
cd /d "%USERPROFILE%"
cd .ssh\ # or cd ssh\
vim known_hosts
```

参考：
- [Ubuntu 安裝和啟用 SSH 登入 Read more: http://www.arthurtoday.com/2010/08/ubuntu-ssh.html#ixzz52BJpHvwh](http://www.arthurtoday.com/2010/08/ubuntu-ssh.html)
- [vi指令說明(完整版)](http://www2.nsysu.edu.tw/csmlab/unix/vi_command.htm)
- [verification - ssh remote host identification has changed - Stack Overflow](https://stackoverflow.com/questions/20840012/ssh-remote-host-identification-has-changed)

# terminator使用

安装：

``` sh
sudo apt-get install terminator
```

更换主题：

将别人的配置文件替换自己的 ~/.config/terminator/config

主题推荐：
- https://github.com/fangwentong/dotfiles/blob/master/ubuntu-gui/terminator/config
	> 需要安装Monaco字体 (http://blog.wentong.me/2014/05/add-fonts-to-your-linux/)

参考：
- [使用Terminator增强你的终端 Wentong's Blog](http://blog.wentong.me/2014/05/work-with-terminator/)
- [dotfiles/config at master · fangwentong/dotfiles](https://github.com/fangwentong/dotfiles/blob/master/ubuntu-gui/terminator/config)

# 安装python3.6

Ubuntu 16.04 默认安装的是2.7和3.5版本的python

如果需要再加上一个3.6版本的python，可以单独安装：

``` sh
sudo add-apt-repository ppa:jonathonf/python-3.6
sudo apt-get update
sudo apt-get install python3.6
```

这时候电脑就有三个版本的Python了

``` sh
$ python -V
Python 2.7.12
$ python3 -V
Python 3.5.2
$ python3.6 -V
Python 3.6.3
```

参考：

- [16.04 - How do I install Python 3.6 using apt-get? - Ask Ubuntu](https://askubuntu.com/questions/865554/how-do-i-install-python-3-6-using-apt-get/865569#865569)
- [virtualenv - How to install Python 3.6 in virtual environment? - Ask Ubuntu](https://askubuntu.com/questions/881042/how-to-install-python-3-6-in-virtual-environment)

# 安装Samba

Ubuntu安装Samba server，Windows使用共享文件夹的方法

## 1. 安装：

``` sh
sudo apt update
sudo apt install samba
```

## 2. 配置：

编辑配置文件`/etc/samba/smb.conf`

```
# 参考配置
[home]
comment = home
path = /home/junmo
read only = no
browseable = yes
```

> [home] : 可以理解成配置的名字，之后会通过这个名字访问到path中配置的文件夹  
> path: 文件夹路径

## 3. 新建用户(后面会使用这个用户访问指定的文件夹)

``` sh
# 如果配置的用户不是Ubuntu用户，可能需要将共享目录的权限改为777
# sudo chmod 777 /home/junmo
sudo smbpasswd -a username
```

## 4. 然后启动smb server

``` sh
sudo service smbd restart
```

> 如果是centos系统，可能需要配置防火墙放行规则以及SeLinux  
> `setenforce 0`

windows电脑添加网络路径：

文件管理器中新增网络位置，URL填写`\\{ip}\{name}`

![20170507_6]({{ site.url }}/images/20170507_6.png)

> Win10如果连不上的话可以尝试这个解决方案（不确定什么原因）
> 1. 以管理员权限打开Windows的PowerShell
> 2. 执行`sc.exe config lanmanworkstation depend= bowser/mrxsmb10/nsi`和`sc.exe config mrxsmb20 start= disabled`然后重启电脑

参考：

- [Install and Configure Samba Ubuntu tutorials](https://tutorials.ubuntu.com/tutorial/install-and-configure-samba#0)
- [Cannot connect to Linux Samba share from Windows 10 - Server Fault](https://serverfault.com/questions/720332/cannot-connect-to-linux-samba-share-from-windows-10)
- [Not discovering Ubuntu server on network](https://social.technet.microsoft.com/Forums/en-US/26e5fd75-f3ab-4ffe-ace4-ed4ba96f82e5/not-discovering-ubuntu-server-on-network?forum=win10itpronetworking)
- [How to detect, enable and disable SMBv1, SMBv2, and SMBv3 in Windows and Windows Server](https://support.microsoft.com/en-us/help/2696547/detect-enable-disable-smbv1-smbv2-smbv3-in-windows-and-windows-server)
- [CentOS 7下Samba服务器的安装与配置 - Muscleape - 博客园](https://www.cnblogs.com/muscleape/p/6385583.html)

# 控制台通过代理使用wget和curl

``` sh
export http_proxy=http://proxyAddress:port
export https_proxy=http://proxyAddress:port
```

> 在网上看到了socks5代理的写法，但是测试好像不成功就没有继续纠结了

如果在使用`sudo + 命令`的时候也需要使用代理，可以修改`/etc/sudoers`文件实现

在Defaults env_reset后面加上

``` sh
Defaults env_keep = "http_proxy https_proxy ftp_proxy DISPLAY XAUTHORITY"
# 也可以只加上
# Defaults env_keep = "http_proxy https_proxy
```

参考

- [让终端走代理的几种方法 fazero](https://blog.fazero.me/2015/09/15/%E8%AE%A9%E7%BB%88%E7%AB%AF%E8%B5%B0%E4%BB%A3%E7%90%86%E7%9A%84%E5%87%A0%E7%A7%8D%E6%96%B9%E6%B3%95/)
- [networking - How to run "sudo apt-get update" through proxy in commandline? - Ask Ubuntu](https://askubuntu.com/questions/7470/how-to-run-sudo-apt-get-update-through-proxy-in-commandline)

# Docker使用

docker加入用户组（避免每次docker之前要加上sudo）  
（当前账户重新登录生效）

``` sh
sudo usermod -aG docker $USER
```

重启docker

```
sudo service docker restart
```

使用portainer

```
docker volume create portainer_data
docker run -d -p 7001:8000 -p 8001:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
```
