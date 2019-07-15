---
date: 2019-7-14 13:57
status: public
title: '[教程]在树莓派中安装ROS和MAVROS'
layout: post
tag: [教程]
categories: [tutorial]
description: 
---

ROS和MAVROS安装记录和过程参考

* 目录 
{:toc}

树莓派的系统是`Raspbian GNU/Linux 10 (buster)`

# ROS

## 准备工作

### 1. 设置ROS安装源

``` sh
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
sudo -E apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
```

更新源

``` sh
sudo apt-get update
sudo apt-get upgrade
```

### 2. 安装Bootstrap依赖

``` sh
sudo apt-get install -y python-rosdep python-rosinstall-generator python-wstool python-rosinstall build-essential cmake
```

> 如果有的依赖没有找到，尝试换一个安装源试试<https://junmo1215.github.io/others/2019/07/11/Memo-Usage-of-RaspberryPi.html#%E6%9B%BF%E6%8D%A2%E8%BD%AF%E4%BB%B6%E6%BA%90>

### 3. 初始化rosdep

``` sh
sudo rosdep init
rosdep update
```

## 安装

### 1. 创建安装目录

``` sh
mkdir -p ~/ros_catkin_ws
cd ~/ros_catkin_ws
```

下载核心包

``` sh
rosinstall_generator ros_comm --rosdistro kinetic --deps --wet-only --tar > kinetic-ros_comm-wet.rosinstall
wstool init src kinetic-ros_comm-wet.rosinstall
```

### 2. 安装依赖

``` sh
mkdir -p ~/ros_catkin_ws/external_src
cd ~/ros_catkin_ws/external_src
wget http://sourceforge.net/projects/assimp/files/assimp-3.1/assimp-3.1.1_no_test_models.zip/download -O assimp-3.1.1_no_test_models.zip
unzip assimp-3.1.1_no_test_models.zip
cd assimp-3.1.1
cmake .
make
sudo make install
```

``` sh
cd ~/ros_catkin_ws
rosdep install -y --from-paths src --ignore-src --rosdistro kinetic -r --os=debian:buster
```

### 3. 安装boost 1.58

在新的rospack里面依赖这个库，使用手动安装

``` sh
mkdir boost
cd boost
wget https://nchc.dl.sourceforge.net/project/boost/boost/1.58.0/boost_1_58_0.tar.bz2
tar xvfo boost_1_58_0.tar.bz2

cd boost_1_58_0
./bootstrap.sh
sudo ./b2 install 
```

> 这个编译的时间可能会比较久

### 3. 编译

如果编译失败可以加上-j1试试（默认-j4）

``` sh
sudo ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release --install-space /opt/ros/kinetic
```

让结果生效

``` sh
source /opt/ros/kinetic/setup.bash

# 或者将这句话加到bashrc中
echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc
```

## 安装其他的包

### 1. 生成下载文件

``` sh
cd ~/ros_catkin_ws
rosinstall_generator ros_comm ros_control joystick_drivers --rosdistro kinetic --deps --wet-only --tar > kinetic-custom_ros.rosinstall
```

### 2. 使用wstool更新工作区

``` sh
wstool merge -t src kinetic-custom_ros.rosinstall
wstool update -t src
```

### 3. 安装新的包

``` sh
rosdep install --from-paths src --ignore-src --rosdistro kinetic -y -r --os=debian:buster
```

### 4. 编译工作区

``` sh
sudo ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release --install-space /opt/ros/kinetic
```

# MAVROS

``` sh
sudo apt-get install python-catkin-tools python-rosinstall-generator -y
```

## 创建安装目录

``` sh
mkdir -p ~/catkin_ws/src
cd ~/catkin_ws
catkin init
wstool init src
```

## 安装MAVLink

``` sh
rosinstall_generator --rosdistro kinetic mavlink | tee /tmp/mavros.rosinstall
```

## 安装MAVROS

``` sh
rosinstall_generator --upstream mavros | tee -a /tmp/mavros.rosinstall
```

## 创建工作区以及依赖

``` sh
wstool merge -t src /tmp/mavros.rosinstall
wstool update -t src -j4
rosdep install --from-paths src --ignore-src -y
```

> 如果这句执行失败的话，安装依赖后再次执行这三行指令  
> 可以参照<https://blog.csdn.net/lin_qc/article/details/88900139>的处理
> ``` sh
> for file_name in {geographic_msgs,uuid_msgs,nav_msgs,tf,control_toolbox,actionlib_msgs,realtime_tools,diagnostic_msgs,urdf,eigen_conversions,tf2_ros,dynamic_reconfigure,tf2_eigen,rosconsole_bridge,orocos_kdl,visualization_msgs,angles,tf2_py,tf2,tf2_msgs,urdf_parser_plugin,diagnostic_updater,control_msgs,trajectory_msgs,actionlib,rosbag_migration_rule}
do
   rosinstall_generator --rosdistro kinetic $file_name | tee -a /tmp/mavros.rosinstall
done
> ```
> 安装过程中看下有没有啥安装失败的，可以重复执行这个脚本

## 安装GeographicLib datasets

``` sh
wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh
./install_geographiclib_datasets.sh
```

## 编译

``` sh
catkin build
```

## 让结果生效

``` sh
source devel/setup.bash

# 或者将这句话加到bashrc中
echo "source ~/catkin_ws/devel/setup.bash" >> ~/.bashrc
```

# 参考

- [ROSberryPi/Installing ROS Kinetic on the Raspberry Pi - ROS Wiki](http://wiki.ros.org/ROSberryPi/Installing%20ROS%20Kinetic%20on%20the%20Raspberry%20Pi)
- [apt update fails / cannot install pkgs: key not working? - ROS Answers: Open Source Q&A Forum](https://answers.ros.org/question/325039/apt-update-fails-cannot-install-pkgs-key-not-working/)
- [mavros/mavros at master · mavlink/mavros](https://github.com/mavlink/mavros/tree/master/mavros#installation)
- [在树莓派上ROS MAVROS的安装使用 - Lin_QC的博客 - CSDN博客](https://blog.csdn.net/lin_qc/article/details/88900139)
