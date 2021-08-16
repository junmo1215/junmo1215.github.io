---
date: 2021-8-7 16:46
status: public
title: '[实作]移植Linux系统到SMT32MP157开发板'
layout: post
tag: [Linux]
categories: [project]
description: 
---

* 目录 
{:toc}

# 关于

硬件是正点原子买的STM32MP157开发板，尝试把系统跑起来之后实现一些自己的想法。整个过程到不难，照着教程慢慢做还好，自己做一遍的目的是大致了解下系统起来的过程，以及自己定制一个系统，后续如果有什么要改的也比较方便。

硬件介绍以及主要参考的教程：<http://www.openedv.com/docs/boards/arm-linux/zdyzmp157.html>

这个板子核心板部分比较小：

![20210807_1]({{ site.url }}/images/20210807_1.png)

加上外设之后，感觉功能还是比较丰富的

![20210807_2]({{ site.url }}/images/20210807_2.png)

这个开发板买来的时候是带了系统的，也可以直接用他们的系统，我这里是选择了自己编译。

# 系统烧录

由于正点原子这边已经提供了系统镜像之类的，我们先来了解下编译出来的系统怎么烧录进去。

这里介绍的是使用 STM32CubeProgrammer 将系统烧录到EMMC，这个工具是ST官方的烧录软件。

烧录的时候，需要拨动开发板的拨码为USB模式，并且Type-C线接到USB_OTG口。

![20210807_3]({{ site.url }}/images/20210807_3.png)

连接上开发板后，打开STM32CubeProgrammer，选择对应USB口，选择tsv文件（我这里用的我自己的）

![20210807_4]({{ site.url }}/images/20210807_4.png)

> tsv这个文件大致上是指定开发板烧录后的分区和大小，以及哪些分区需要烧录或者跳过。

确认没问题之后点击Download下载等待烧录完成就行了。

> 烧录完成后启动记得拨码开关拨到EMMC启动的位置  
> 烧录的时候尽量用USB3.0的口接开发板，速度会快很多

# 系统编译

通过烧录的图里面，我们可以发现需要这么四个文件：
- tf-a-stm32mp157d-atk-trusted.stm32
- u-boot.stm32
- bootfs.ext4
- rootfs.ext4

这四个文件的烧录地址从低到高，启动顺序也是一样，首先是板子里面内置的ROM，ROM里面是ST编写的代码，在芯片内部的ROM部分，是无法更改的，我们上面烧录的时候也没办法烧录这部分。ROM启动时候会根据选择（这块板子上是读取BOOT0~BOOT2这三个引脚的电平（烧录之前拨动的那个拨码开关））决定从哪个启动设备读取FSBL（First Stage Boot Loader）代码。

这个板子的FSBL代码对应烧录的`tf-a-stm32mp157d-atk-trusted.stm32`文件，如果tf-a部分的打印没有关掉的话，大致上的输出如下：

![20210807_5]({{ site.url }}/images/20210807_5.png)

这部分的主要工作大概是初始CPU频率、时钟之类的，然后指定内存大小等

后面的启动阶段就是uboot，这个阶段开始初始化各种DeviceTree，然后引导kernel启动，kernel中包含各种硬件驱动的适配。kernel最后调用init进程，这个进程会帮忙启动用户空间的各种程序，比如`/etc/init.d/`下面配置的这些。这一系列启动完成之后，整个系统就跑起来了。可以看出在这个板子上大致上的流程是（这只是其中一种可能的启动链路）：ST的ROM程序 -> tf-a -> uboot -> kernel -> 用户态

## tf-a

ROM的代码不需要我们修改，也办法修改，就从tf-a开始。

### stm32wrapper4dbg

编译tf-a用到了[stm32wrapper4dbg](https://github.com/STMicroelectronics/stm32wrapper4dbg)工具，下载之后执行make命令，会在当前目录生成stm32wrapper4dbg文件，为了方便可以把这个文件加入PATH中，或者复制到/usr/bin目录

``` sh
git clone https://github.com/STMicroelectronics/stm32wrapper4dbg.git
cd stm32wrapper4dbg
make
sudo cp stm32wrapper4dbg /usr/bin
```

### 交叉编译器

除此之外还有交叉编译器也是需要的，编译器是把C源代码翻译成机器码，机器码又根据CPU指令集不同会不一样，比如我们一般的x86架构的电脑编译出来的C程序是不能直接运行在ARM架构上的，但是用交叉编译器就可以把源码翻译成指定架构可以识别的机器码。比如这里用的交叉编译器arm-none-linux-gnueabihf-gcc就能把C语言的源码编译成这个开发板能直接执行的程序。

这里我们直接下载解压就可以用了，把解压后的编译器放在/usr/local/arm目录并加到PATH中

``` sh
mkdir -p /usr/local/arm/
cd /usr/local/arm/
# 这里要注意编译机的架构，这里下载的是x86-64的，如果编译机不是这个架构需要去找其他的版本
curl https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz --output /usr/local/arm/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz
tar -vxf gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz
export PATH=$PATH:/usr/local/arm/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf/bin
```

### 编译tf-a

这部分代码直接用的正点原子改好的版本，解压后修改Makefile里面的交叉编译器，然后编译：

``` sh
tar -xvf tf-a-stm32mp-2.2.r1-gd5cfc8c-v1.1.tar.bz2
sed -i -e 's/CROSS_COMPILE=arm-ostl-linux-gnueabi-/CROSS_COMPILE=arm-none-linux-gnueabihf-/' ./Makefile.sdk
cd tf-a-stm32mp-2.2.r1
make -f ../Makefile.sdk all
```

编译之后在tf-a源码的上级目录的build/trusted/文件夹下就可以找到需要的产物：tf-a-stm32mp157d-atk-trusted.stm32

## uboot

uboot这部分主要工作也是适配这个开发板，但是正点原子也已经做了这部分工作了，直接用了他的源码，解压编译就行

``` sh
tar -vxf u-boot-stm32mp-2020.01-gd3f2b20a-v1.2.tar.bz2
make distclean
make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- stm32mp157d_atk_defconfig
make V=1 ARCH=arm  CROSS_COMPILE=arm-none-linux-gnueabihf- DEVICE_TREE=stm32mp157d-atk all
```

在当前目录下的`u-boot.stm32`就是需要的编译产物

> tf-a和uboot本身是开源的，然后半导体公司（比如ST等）用这些工具会支持上自己家的芯片方案，所以才有了上面这几个从ST官网下载的tf-a和uboot，然后这个板子是正点原子参照ST官方支持的STM32MP157 EVK开发板，所以又有了一套正点原子修改的tf-a和uboot，这份和ST维护的那个区别就是多支持了这几块板子。上面这两个我没什么特殊的需求，直接用了正点原子支持的这个版本。

## Linux

Linux源码中一部分工作就是适配不同的硬件驱动。内核中会有一个框架以及对一些硬件或者特性的支持，但是支持的这些内容可能不适用于这块板子，因此ST公司提供的源码中还包含一些适配的patch文件。

![20210807_6]({{ site.url }}/images/20210807_6.png)

在编译源码前需要打上这些patch，编出来的kernel才能适配这个板子，并且要使用上对应的.config文件

``` sh
# 解压源码
tar -vxf linux-5.4.31.tar.xz
cd linux-5.4.31.tar.xz

# 打patch
for p in `ls -l ../*.patch`;
do
    patch -p1 < $p;
done

# 使用对应的config
for f in `ls -l ../fragment*.config`;
do
    scripts/kconfig/merge_config.sh -m -r .config $f;
done 
yes '' | make ARCH=arm oldconfig
```

然后就可以编译ST打过patch的linux内核了

``` sh
make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- distclean
make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- stm32mp1_atk_defconfig
make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- uImage dtbs LOADADDR=0XC2000040 -j4 # 后面的j4可以根据编译机配置修改
```

内核编译的结果是uImage文件和各种device tree（我们要用的是stm32mp157d-atk.dtb），但是烧录是用的bootfs.ext4，所以还需要制作出这个镜像。

``` sh
DIST_DIR=/mnt/images/ # 这个路径只是个临时挂载点，可以更改
mkdir -p ${DIST_DIR}
dd if=/dev/zero of=${DIST_DIR}bootfs.ext4 bs=1M count=10
mkfs.ext4 -L bootfs ${DIST_DIR}bootfs.ext4
mkdir -p ${DIST_DIR}bootfs
mount ${DIST_DIR}bootfs.ext4 ${DIST_DIR}bootfs
cp -f ${DIST_DIR}uImage ${DIST_DIR}bootfs
cp -f ${DIST_DIR}stm32mp157d-atk.dtb ${DIST_DIR}bootfs
umount ${DIST_DIR}bootfs
rm -rf ${DIST_DIR}bootfs
```

内核启动的时候，能看到类似的打印就是启动成功了

![20210807_7]({{ site.url }}/images/20210807_7.png)

> 接下来可以根据打印内容排查启动不成功的问题（一般硬件相比ST官方维护的板子没有什么改动的话能正常启动成功）

## 根文件系统

内核编译出的文件是`bootfs.ext4`，烧录需要的文件还差一个`rootfs.ext4`，这部分是根文件系统，也就是我们平常看到的这部分内容：

![20210807_8]({{ site.url }}/images/20210807_8.png)

如果没有根文件系统的话，内核启动到一定阶段会直接报错：

![20210807_9]({{ site.url }}/images/20210807_9.png)

这是在uboot下没有配置bootargs参数，内核不知道根文件系统在哪。

解决这个问题首先需要制作一个根文件系统，常用的根文件系统有[Busybox](https://www.busybox.net/)和[Buildroot](https://buildroot.org/)，Busybox在单一的可执行文件中提供了精简的Unix工具集，可运行于多款POSIX环境的操作系统，简单来说，就是他提供了一些我们常用的命令，不需要文件系统来做这部分工作了。

那我们常用的ping命令举例，可以看到他其实是个指向busybox的软链接。直接在系统里面执行busybox可以看到下面这些命令都是他提供的。

![20210807_10]({{ site.url }}/images/20210807_10.png)

而Buildroot更像是一个框架，帮你完整的构建一个Linux环境（不过这里只用到了根文件系统这部分。Kernel和uboot都使用之前编译的）除了Busybox的功能外，还带有一些类似于用户名密码，init脚本等功能。用来订制系统比较方便，我们自己增加功能也可以借助于这个框架。

Buildroot也提供了一套图形化可配置的工具，可以在Buildroot根目录执行`make menuconfig`打开，并在这个界面勾选和取消选择一些功能。

除了设置编译器、工具链、初始用户名密码外（这部分可以参照正点原子的《STM32MP1嵌入式Linux驱动开发指南》中19.2部分进行配置），还可以在系统中增加自己的功能，方便烧录进去就能使用自己的功能，在很多机器都需要同一个功能的时候比较方便，不需要一个个安装。

上面功能配置完成后，将配置项保存为stm32mp1_atk_defconfig，然后可以进行编译了。

``` sh
make stm32mp1_atk_defconfig
make
```

编译产物中有`rootfs.ext4`就是最后可以烧录使用的文件。

# 往系统中增加自定义功能

## 增加C语言写的进程

在`buildroot\package\`下面新增helloworld文件夹，增加`helloworld.mk`文件

``` makefile
# 版本，源码路径
HELLOWORLD_VERSION:= 1.0.0
HELLOWORLD_SITE:= $(CURDIR)/package/helloworld/src
HELLOWORLD_SITE_METHOD:=local
HELLOWORLD_INSTALL_TARGET:=YES

# 编译命令（详细的编译命令在/package/helloworld/src目录下）使用的是这里传进去的编译器
define HELLOWORLD_BUILD_CMDS
	$(MAKE) CC="$(TARGET_CC)" LD="$(TARGET_LD)" -C $(@D) all
endef

# 安装命令，放在系统的/bin目录下，文件名为helloworld（后面要编译出这个文件）
define HELLOWORLD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/helloworld $(TARGET_DIR)/bin
endef

# 安装后的权限
define HELLOWORLD_PERMISSIONS
	/bin/helloworld f 4755 0 0 - - - - -
endef

$(eval $(generic-package))
```

增加一个`Config.in`文件，内容如下（注意缩进使用）：

```
config BR2_PACKAGE_HELLOWORLD
	bool "helloworld"
	help
	    This is a demo to add own package.
```

在文件中增加这个包的配置

``` diff
diff --git a/buildroot/package/Config.in b/buildroot/package/Config.in
index 5304ab141..0db8657df 100644
--- a/buildroot/package/Config.in
+++ b/buildroot/package/Config.in
@@ -2510,4 +2510,8 @@ menu "Text editors and viewers"
        source "package/vim/Config.in"
 endmenu

+menu "own package"
+       source "package/helloworld/Config.in"
+endmenu
+
 endmenu
```

然后在buildroot的根目录使用`make menuconfig`就可以找到这个包了。

![20210807_11]({{ site.url }}/images/20210807_11.png)

> 这里的helloworld-cpp在后面会增加  
> 除了make menuconfig进行配置外，也可以直接改stm32mp1_atk_defconfig文件。

``` diff
+#
+# own package
+#
+BR2_PACKAGE_HELLOWORLD=y
+
```

这里配置完之后，可以编译自定义的包了。不过这里还会编译失败，因为没有写源码。

源码这里写个简单的helloworld，在`buildroot/package/helloworld/src/`文件夹下新建`helloworld.c`和`Makefile`

helloworld.c

``` c
#include <stdio.h>

int main() {
    printf("hello world");
    return 0;
}
```

Makefile

``` makefile
OPT    = -O2
DEBUG  = -g
OTHER  = -Wall -Wno-deprecated
CFLAGS = $(OPT) $(OTHER)
INCDIR = -I
LIBDIR = -L
LIBS =
APP=helloworld
SRCS=helloworld.c

all:
	$(CC) -o $(APP) $(SRCS) $(CFLAGS) $(LIBDIR) $(INCDIR) $(LIBS)
clean:
	rm $(APP)
```

Makefile中的`$(CC)`就是在helloworld.mk中赋值的，使用的是外边传进来的`TARGET_CC`，编译buildroot观察输出可以发现工具链被使用的是`arm-none-linux-gnueabihf-gcc`，这个编译语句实际上是下面这个（红框框起来的部分）

![20210807_12]({{ site.url }}/images/20210807_12.png)

> 通过这个打印也可以看到安装等命令，编不过调试的时候看这些命令比较有帮助

**修改源码后，需要删除`buildroot\output\build\helloworld-1.0.0`文件夹才会重新编译（文件夹名称是package名称加版本号）**

## 增加C++写的进程

C++进程与C进程类似，只是需要指定编译器用C++的就行，其他的与C语言的包类似。这里给出`.mk`文件的差异

`diff -uN buildroot/package/helloworld/helloworld.mk buildroot/package/helloworld-cpp/helloworld-cpp.mk`

``` diff
--- buildroot/package/helloworld/helloworld.mk  2021-08-16 23:00:58.093352382 +0800
+++ buildroot/package/helloworld-cpp/helloworld-cpp.mk  2021-08-01 22:31:27.492340589 +0800
@@ -1,28 +1,24 @@
 ################################################################################
 #
-# helloworld
+# helloworld-cpp
 #
 ################################################################################

-# 版本，源码路径
-HELLOWORLD_VERSION:= 1.0.0
-HELLOWORLD_SITE:= $(CURDIR)/package/helloworld/src
-HELLOWORLD_SITE_METHOD:=local
-HELLOWORLD_INSTALL_TARGET:=YES
+HELLOWORLD_CPP_VERSION:= 1.0.0
+HELLOWORLD_CPP_SITE:= $(CURDIR)/package/helloworld-cpp/src
+HELLOWORLD_CPP_SITE_METHOD:=local
+HELLOWORLD_CPP_INSTALL_TARGET:=YES

-# 编译器
-define HELLOWORLD_BUILD_CMDS
-       $(MAKE) CC="$(TARGET_CC)" LD="$(TARGET_LD)" -C $(@D) all
+define HELLOWORLD_CPP_BUILD_CMDS
+       $(MAKE) CXX="$(TARGET_CXX)" LD="$(TARGET_LD)" -C $(@D) all
 endef

-# 安装命令
-define HELLOWORLD_INSTALL_TARGET_CMDS
-       $(INSTALL) -D -m 0755 $(@D)/helloworld $(TARGET_DIR)/bin
+define HELLOWORLD_CPP_INSTALL_TARGET_CMDS
+       $(INSTALL) -D -m 0755 $(@D)/helloworld_cpp $(TARGET_DIR)/bin
 endef

-# 安装后的权限
-define HELLOWORLD_PERMISSIONS
-       /bin/helloworld f 4755 0 0 - - - - -
+define HELLOWORLD_CPP_PERMISSIONS
+       /bin/helloworld_cpp f 4755 0 0 - - - - -
 endef

 $(eval $(generic-package))
\ No newline at end of file
```

## 直接在根文件系统中新增文件

有时候我们直接想放一个文件在根文件系统中而不用编译，使用package有点麻烦，需要写很多的INSTALL_TARGET_CMDS，Buildroot针对这个需求提供了一种方式，就是使用overlay（其实还有POST_BUILD等方式）

overlay可以看做是一个文件系统，覆盖在了原本的根文件系统上。可以指定一个或者多个文件夹作为overlay，直接配置BR2_ROOTFS_OVERLAY配置项即可。

> 推荐的配置是`board/<company>/<boardname>/rootfs-overlay`，猜测是为了方便不同的板子在一个工程下方便配置。这里我为了方便直接放在了package下面的rootfs-overlay文件夹下。

初始情况下，Buildroot制作的文件系统只会显示一个`#`，不能显示当前路径和用户名，可以在根文件系统的`/etc/profile.d/`目录下增加一个文件设置PS1变量修改这个行为。文件名无所谓，需要可执行权限。

``` diff
diff --git a/buildroot/configs/stm32mp1_atk_defconfig b/buildroot/configs/stm32mp1_atk_defconfig
index 36e26bb78..3bfbaf5a5 100644
--- a/buildroot/configs/stm32mp1_atk_defconfig
+++ b/buildroot/configs/stm32mp1_atk_defconfig
@@ -473,7 +473,7 @@ BR2_GENERATE_LOCALE=""
 # BR2_SYSTEM_ENABLE_NLS is not set
 # BR2_TARGET_TZ_INFO is not set
 BR2_ROOTFS_USERS_TABLES=""
-BR2_ROOTFS_OVERLAY=""
+BR2_ROOTFS_OVERLAY="package/rootfs-overlay"
 BR2_ROOTFS_POST_BUILD_SCRIPT=""
 BR2_ROOTFS_POST_FAKEROOT_SCRIPT=""
 BR2_ROOTFS_POST_IMAGE_SCRIPT=""
diff --git a/buildroot/package/rootfs-overlay/etc/profile.d/showHostnameAndPath.sh b/buildroot/package/rootfs-overlay/etc/profile.d/showHostnameAndPath.sh
new file mode 100644
index 000000000..71eeb9cf7
--- /dev/null
+++ b/buildroot/package/rootfs-overlay/etc/profile.d/showHostnameAndPath.sh
@@ -0,0 +1,6 @@
+#!/bin/sh
+
+PS1='[\u@\h]:\w$ '
+export PS1
```

修改之后的效果：

![20210807_13]({{ site.url }}/images/20210807_13.png)

# 参考

- [硬件介绍以及主要参考的教程](http://www.openedv.com/docs/boards/arm-linux/zdyzmp157.html)
- [Busybox](https://buildroot.org/)
- [Buildroot](https://buildroot.org/)
- [STM32MP157 microprocessors (MPU)](https://www.st.com/zh/microcontrollers-microprocessors/stm32mp157.html)
- [The Buildroot user manual](https://buildroot.org/downloads/manual/manual.html)
