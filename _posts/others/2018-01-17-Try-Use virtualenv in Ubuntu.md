---
layout: post
date: 2018-1-17 17:31
status: public
title: '[折腾]在Ubuntu系统中使用virtualenv和jupyter'
categories: [others]
tags: []
description: 
---

* 目录 
{:toc}

# 安装virtualenv

``` sh
# python2
pip install virtualenv

# python3
pip3 install virtualenv
```

> 如果pip没有安装需要安装pip：```sudo apt-get install python-pip python-dev```

# 新建环境

``` sh
virtualenv ENVNAME -p /path/to/python
```

用这个指定python版本号跟anaconda有点不一样，这里只能指定电脑里面有的Python版本

比如执行：

``` sh
virtualenv test_env -p python
```

test_env里面的版本跟Ubuntu本身的Python版本相同，可以通过```which python```查看具体路径

# 删除环境

直接删除掉test_env这个文件夹就可以了。

# 激活环境

``` sh
source PATH_TO_ENV/bin/activate
```

# 安装jupyter notebook

安装jupyter

> 建议电脑上只安装一个jupyter，这时候的kernel版本不重要，后面可以安装特定版本的kernel，所以执行这个指令的时候pip使用Ubuntu本身的pip3

``` sh
pip install jupyter
```

安装kernel

``` sh
pip install ipykernel
python -m ipykernel install --user --name=my-virtualenv-name
```

后面一句新建kernel的时候，kernel里面的Python版本会根据这个指令的Python来，如果不加```--user```需要输入sudo密码，但是加了sudo会使用Ubuntu的默认python 

# 设置jupyter允许其他电脑连接

这部分主要按照官方文档来的，可以直接参考文档: <http://jupyter-notebook.readthedocs.io/en/stable/public_server.html>

## 找到配置文件

查看配置文件路径：

``` sh
jupyter --paths
```

默认是在~/.jupyter/文件夹下有个配置文件```jupyter_notebook_config.py```

如果不存在使用指令创建一个

``` sh
jupyter notebook --generate-config
```

## 设定密码

然后修改c.NotebookApp.password这一行，改成自己设定的加密后的密码，比如：

``` python
c.NotebookApp.password = u'sha1:67c9e60bb8b6:9ffede0825894254b2e042ea597d771089e11aed'
```

后面这一长串加密的密码可以通过python指令得到：

``` python
from notebook.auth import passwd
passwd()
```

然后输入自己想要设定的密码就行了

## 其他设定

还是在```jupyter_notebook_config.py```文件中，修改下面这两行：

``` py
# 监听的ip和是否打开浏览器
c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False
```

## 设置SSL连接

到上面一步，其实已经可以使用其他电脑连接了，但是为了确保安全可以使用ssl连接

> 设置ssl连接的方式不太会，等研究了之后再补充

# 参考

1. [Installation — virtualenv 15.1.0 documentation](https://virtualenv.pypa.io/en/stable/installation/)
2. [Using a virtualenv in an IPython notebook  PythonAnywhere help](https://help.pythonanywhere.com/pages/IPythonNotebookVirtualenvs/)
3. [Running a notebook server — Jupyter Notebook 5.3.1 documentation](http://jupyter-notebook.readthedocs.io/en/stable/public_server.html)
