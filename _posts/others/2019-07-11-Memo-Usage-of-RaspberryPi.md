---
layout: post
date: 2019-7-11 00:39
status: public
title: '[参考]树莓派使用记录'
categories: [others]
tags: []
description: 
---

入手了树莓派，记录下一些琐碎的东西

* 目录 
{:toc}

# 开启ssh

``` sh
sudo raspi-config
```

Interfacing Options - P2 SSH - 开启

# 常用软件

- vim （文本编辑器）
- xrdp （可以使用Windows远程桌面操纵树莓派）

# 替换软件源

Debian版本：buster

``` sh
# 编辑 `/etc/apt/sources.list` 文件，删除原文件所有内容，用以下内容取代：
deb http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ buster main non-free contrib
deb-src http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ buster main non-free contrib

# 编辑 `/etc/apt/sources.list.d/raspi.list` 文件，删除原文件所有内容，用以下内容取代：
deb http://mirrors.tuna.tsinghua.edu.cn/raspberrypi/ buster main ui

# 然后执行以下指令更新软件源列表
sudo apt-get update
```

# 查看树莓派版本 

``` sh
getconf LONG_BIT        # 查看系统位数
uname -a            # kernel 版本
/opt/vc/bin/vcgencmd  version   # firmware版本
strings /boot/start.elf  |  grep VC_BUILD_ID    # firmware版本
cat /proc/version       # kernel
cat /etc/os-release     # OS版本资讯
cat /etc/issue          # Linux distro 版本
cat /etc/debian_version     # Debian版本编号
```

# 安装samba

``` sh
sudo apt-get install samba samba-common-bin
cd /etc/samba
sudo vim smb.conf
```

> 配置参考： <https://junmo1215.github.io/others/2017/05/07/Memo-Usage-of-Ubuntu.html#%E5%AE%89%E8%A3%85samba>

# 参考

- [Raspbian 镜像站使用帮助 清华大学开源软件镜像站 Tsinghua Open Source Mirror](https://mirror.tuna.tsinghua.edu.cn/help/raspbian/)
- [查看树莓派版本 aoenian](https://aoenian.github.io/2018/05/20/rasp-versions/)
