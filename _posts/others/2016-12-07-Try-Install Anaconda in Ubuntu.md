---
layout: post
date: 2016-12-07 18:10
status: public
title: '[折腾]Ubuntu安装Anaconda'
categories: [others]
tags: []
description: 
---

# 说明

自从有一次改变了win10控制台里面的一个编码问题之后（好像是默认编码改成了uft-8），python再也不能好好的跑在我的win10上面了，控制台启动python、pip会出错，具体错误是"LookupError: unknown encoding: cp65001"，然后由于这些天我的系统里面docker什么的都崩了，所以干脆安装了一个ubuntu。之前几乎没有用过Ubuntu，安装软件过程中也是遇到了一些坑，所以把安装Anaconda中遇到的问题记录下来，方便下次查找。
> 当然上面提到的编码问题还是有解决办法的，但是我不会彻底处理这个问题，一个解决方案是在控制台中执行这两行：chcp 65001 和 set PYTHONIOENCODING=utf-8，具体原因不懂。但是由于每次都要这么执行，所以不想折腾，干脆装双系统。

# 安装Anaconda
安装Anaconda的原因是想用Jupyter notebook，然而安装界面提示:
> For new users, we **highly recommend** installing Anaconda. Anaconda conveniently installs Python, the Jupyter Notebook, and other commonly used packages for scientific computing and data science.

加上之前有人推荐过Anaconda，之后安装tensorflow说不定用的上，所以就安装了，其实步骤还比较简单。

在官网(<https://www.continuum.io/downloads>)下载Anaconda，硬盘中是一个脚本（类似于windows里面的bat）会指导安装步骤，在Terminal中切到脚本所在的目录执行就行了

``` sh
cd Downloads
bash Anaconda3-4.2.0-Linux-x86_64.sh 
```
然后会出现许可条款，输入yes后确认安装目录和是否加入PATH（类似windows中的环境变量）
接着就能安装完成了，确认是否安装成功可以**新开一个窗口**然后执行
`conda list`，如果可以识别这个指令表明安装成功。安装完成后参照这个链接中的提示执行下面指令升级Anaconda：<https://mas-dse.github.io/startup/anaconda-ubuntu-install/>
``` sh
conda update --all --yes
```

由于我下载的是python3.5版本的，安装成功后，系统里面python版本直接变成了3.5，有时候需要执行python2.7的代码会比较麻烦，所以创建了一个python2的环境,在terminal中执行：
``` sh
conda create --name python2 python=2
```
其中python2是这个环境的名字，可以换成别的，后面python=2是指定环境中python的版本，这个链接(<http://conda.pydata.org/docs/py2or3.html>)里面给的例子是python3的(`conda create --name snakes python=3`)，没有尝试过其他的选项。
创建成功后可以通过`conda info --envs`指令看目前的conda环境信息。

![conda_info](http://7xrop1.com1.z0.glb.clouddn.com/others/conda_info.png)

然后就可以进入python2的环境执行python2.7的代码了：

![python_version](http://7xrop1.com1.z0.glb.clouddn.com/others/python_version.png)

> 在windows系统中执行 `activate [name]` 进入虚拟环境 `deactivate` 退出

# 打开ipython notebook

然后执行`ipython notebook`就能打开Jupyter，然而好像不管从python2还是python3环境进入，Jupyter中的python版本都是3.5的：

![python_version_in_jupyter](http://7xrop1.com1.z0.glb.clouddn.com/others/python_version_in_jupyter.png)

这个原因应该是刚刚创建的python2环境没有安装ipython notebook，因此需要在python2中先安装一个ipython
``` sh
conda install notebook ipykernel
ipython kernel install --user
```
但是我在python2环境中安装ipython的时候出现了问题

![trouble_install_ipython](http://7xrop1.com1.z0.glb.clouddn.com/others/trouble_install_ipython.png)

网上看到的说法是没有安装backports.shutil_get_terminal_size并且有人安装这个之后问题解决了，然而我安装的时候提示已经存在，卸载后重新安装结果也是一样，并且pip list中能看到这个是已经安装了的。

![exists_shutil_get_terminal_size_in_python2](http://7xrop1.com1.z0.glb.clouddn.com/others/exists_shutil_get_terminal_size_in_python2.png)

继续搜索发现有个方法(<http://abelxu.blog.51cto.com/9909959/1852263>)是找到报错的那个代码，修改引用的模块，改为shutil_backports，尝试了一下问题解决了

![change_terminal_py](http://7xrop1.com1.z0.glb.clouddn.com/others/change_terminal_py.png)

目前效果是从Python2环境中进入ipython notebook发现python版本为2.7，外部ipython中版本正常，实现了不同python版本的效果

![ipython_with_python2_7](http://7xrop1.com1.z0.glb.clouddn.com/others/ipython_with_python2_7.png)


# 参考
1. [Windows cmd encoding change causes Python crash - stackoverflow](http://stackoverflow.com/questions/878972/windows-cmd-encoding-change-causes-python-crash)
1. [Install Anaconda on Ubuntu (Python) - youtube](https://www.youtube.com/watch?v=jo4RMiM-ihs)
1. [Jupyter Documentation](https://jupyter.readthedocs.io/en/latest/install.html)
1. [Download Anaconda](https://www.continuum.io/downloads)
1. [Anaconda and iPython Notebook Install Instructions - Ubuntu](https://mas-dse.github.io/startup/anaconda-ubuntu-install/)
1. [Managing Python](http://conda.pydata.org/docs/py2or3.html)
1. [Using both Python 2.x and Python 3.x in IPython Notebook](http://stackoverflow.com/questions/30492623/using-both-python-2-x-and-python-3-x-in-ipython-notebook)
1. [ImportError: No module named shutil_get_terminal_size #9815](https://github.com/ipython/ipython/issues/9815)
1. [安装ipython报错"ImportError: No module named shutil_get_terminal_size"](http://abelxu.blog.51cto.com/9909959/1852263)