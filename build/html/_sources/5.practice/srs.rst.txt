###################
SRS
###################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Simple RTMP Server
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents:: Contents
   :local:

Overview
====================


Quick Start
=====================
* 编译

.. code-block::

    git clone -b develop https://gitee.com/ossrs/srs.git
    cd srs/trunk/
    sudo apt install -y unzip
    sudo apt install -y tclsh
    ./configure
    make


* 启动

.. code-block::

    ./objs/srs -c conf/srs.conf

    # 查看SRS的状态
    ./etc/init.d/srs status

    # 或者看SRS的日志
    tail -n 30 -f ./objs/srs.log

* 测试

.. code-block::

    sudo apt install ffmpge
    ffmpeg -re -i ./doc/source.flv -c copy -f flv rtmp://localhost/live/livestream


* 用如下地址观察音视频流

    * RTMP (by VLC): rtmp://localhost/live/livestream
    * H5(HTTP-FLV): http://localhost:8080/live/livestream.flv
    * H5(HLS): http://localhost:8080/live/livestream.m3u8