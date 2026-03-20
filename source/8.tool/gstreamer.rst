##########
GStreamer
##########


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. toctree::
   :maxdepth: 1
   :caption: Sections

   gstreamer_dev
   gstreamer_webrtc

============ ==========================
**Abstract** GStreamer 多媒体框架
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
==============

GStreamer 是一个跨平台、模块化的开源媒体流处理框架。
在 WebRTC 开发中，GStreamer 是一个强大的工具，可以用于：

- 构建音视频采集、编码、传输、解码、渲染的完整 pipeline
- 通过 ``webrtcbin`` 插件直接建立 WebRTC 连接
- RTP/RTCP 流的发送、接收和分析
- 音视频录制、转码和混流
- 搭建流媒体服务器原型


核心特性
==============

跨平台
----------------------
GStreamer 适用于所有主要操作系统：Linux、Android、Windows、macOS、iOS，
以及大多数 BSD、商业 Unix 等。支持 x86、ARM、MIPS、SPARC、PowerPC，32/64 位，大小端。

GStreamer 可以桥接到其他多媒体框架以重用现有组件：

- Linux: OpenMAX-IL (via gst-omx)
- Windows: DirectShow
- macOS: QuickTime / AVFoundation

强大的核心库
--------------------------------------------

- 基于图的结构允许构建任意的 pipeline
- 基于 GLib 2.0 对象模型进行面向对象设计和继承
- 紧凑型核心库（< 500KB，约 65K 行代码）
- 多线程 pipeline 构建简单透明
- 干净、稳定的 API
- 极轻量的数据传递，高性能低延迟
- 完整的调试系统
- 时钟确保全局数据流同步（音视频同步）
- QoS 机制确保高 CPU 负载下的最佳质量

智能的插件架构
--------------------------------------------

- 动态加载的插件提供 Element 和媒体类型
- Element 接口处理所有已知的 source、filter 和 sink
- Capabilities 系统验证 Element 兼容性
- Autoplugging 自动完成复杂路径匹配
- 可将 pipeline 导出为 ``.dot`` 文件进行可视化

广泛的媒体格式支持
--------------------------------------------

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 类别
     - 支持
   * - 容器格式
     - ASF, AVI, 3GP, MP4, MOV, FLV, MPEG-PS/TS, MKV, WebM, MXF, OGG
   * - 流媒体
     - HTTP, MMS, RTSP, RTP, RTMP, HLS, DASH
   * - 视频编解码
     - H.264, H.265, VP8, VP9, AV1, MPEG-2, Theora
   * - 音频编解码
     - Opus, Vorbis, AAC, MP3, FLAC, G.711, G.722, Speex
   * - 字幕
     - SRT, SSA/ASS, VTT


安装
===============

Linux (Debian/Ubuntu)
--------------------------

.. code-block:: bash

   sudo apt-get install -y \
     gstreamer1.0-tools \
     gstreamer1.0-plugins-base \
     gstreamer1.0-plugins-good \
     gstreamer1.0-plugins-bad \
     gstreamer1.0-plugins-ugly \
     gstreamer1.0-nice \
     gstreamer1.0-libav \
     libgstreamer1.0-dev \
     libgstreamer-plugins-bad1.0-dev \
     libglib2.0-dev \
     libsoup2.4-dev \
     libjson-glib-dev

macOS
--------------------------

从官网下载安装包：https://gstreamer.freedesktop.org/documentation/installing/on-mac-osx.html

安装后的文件布局：

- ``/Library/Frameworks/GStreamer.framework/`` — 框架根路径
- ``/Library/Frameworks/GStreamer.framework/Headers`` — 开发头文件
- ``/Library/Frameworks/GStreamer.framework/Commands`` — 命令行工具

.. code-block:: bash

   export PATH=$PATH:/Library/Frameworks/GStreamer.framework/Versions/1.0/bin
   export PKG_CONFIG_PATH=/Library/Frameworks/GStreamer.framework/Versions/1.0/lib/pkgconfig


基本概念
=========================

Pipeline
-------------------------

Pipeline 是 GStreamer 中最核心的概念，由多个 Element 通过 Link 连接而成：

.. code-block:: text

   [Source] → [Filter1] → [Filter2] → [Sink]

Element
--------------------------

Element 是 pipeline 的基本构建块。每个 Element 有一个特定功能：

.. list-table::
   :header-rows: 1
   :widths: 20 30 50

   * - 类型
     - 说明
     - 示例
   * - Source
     - 数据源，只有输出
     - ``filesrc``, ``v4l2src``, ``audiotestsrc``, ``udpsrc``
   * - Filter / Transform
     - 处理数据，有输入和输出
     - ``videoconvert``, ``x264enc``, ``opusenc``, ``rtph264pay``
   * - Sink
     - 数据消费者，只有输入
     - ``filesink``, ``autovideosink``, ``udpsink``, ``fakesink``

Pad
--------------------------

Pad 是 Element 的输入/输出端口：

- **Sink Pad**：数据输入
- **Source Pad**：数据输出
- **Sometimes Pad**：运行时才创建的动态 Pad（如 ``decodebin``）

Caps (Capabilities)
--------------------------

Caps 描述 Pad 能处理的媒体格式，用于 Element 之间的兼容性协商：

.. code-block::

   video/x-raw, format=I420, width=1280, height=720, framerate=30/1
   audio/x-raw, format=S16LE, rate=48000, channels=2
   application/x-rtp, media=video, encoding-name=H264, clock-rate=90000

Bin
--------------------------

Bin 是一组 Element 的容器，可以作为一个整体被操作。``GstPipeline`` 本身就是一个特殊的 Bin。


命令行工具
=========================

gst-launch-1.0
--------------------------

用于快速构建和测试 pipeline 的命令行工具。

**基本语法**：

.. code-block:: bash

   gst-launch-1.0 element1 ! element2 ! element3

``!`` 是连接符，将前一个 Element 的 source pad 连接到下一个 Element 的 sink pad。

gst-inspect-1.0
--------------------------

查看插件和 Element 的详细信息：

.. code-block:: bash

   # 列出所有可用插件
   gst-inspect-1.0

   # 查看特定 Element 的属性、Pad 和 Caps
   gst-inspect-1.0 webrtcbin
   gst-inspect-1.0 rtph264pay
   gst-inspect-1.0 opusenc

gst-discoverer-1.0
--------------------------

分析媒体文件的信息：

.. code-block:: bash

   gst-discoverer-1.0 video.mp4


常用 Pipeline 示例
============================

音频
--------------------------

.. code-block:: bash

   # 播放测试音频（正弦波）
   gst-launch-1.0 audiotestsrc ! audioconvert ! audioresample ! autoaudiosink

   # 采集麦克风并显示波形
   gst-launch-1.0 autoaudiosrc ! audioconvert ! wavescope style=3 ! videoconvert ! autovideosink

   # 录制麦克风到 WAV
   gst-launch-1.0 autoaudiosrc ! audioconvert ! audioresample ! wavenc ! filesink location=record.wav

   # 录制麦克风到 Opus/OGG
   gst-launch-1.0 autoaudiosrc ! audioconvert ! opusenc ! oggmux ! filesink location=record.ogg

视频
--------------------------

.. code-block:: bash

   # 显示测试视频
   gst-launch-1.0 videotestsrc ! videoconvert ! autovideosink

   # 播放 MP4 文件
   gst-launch-1.0 playbin uri=file:///path/to/video.mp4

   # 采集摄像头并显示
   gst-launch-1.0 v4l2src ! videoconvert ! autovideosink                    # Linux
   gst-launch-1.0 avfvideosrc ! videoconvert ! autovideosink                # macOS

   # 采集摄像头并编码为 H.264 写入文件
   gst-launch-1.0 v4l2src ! videoconvert ! x264enc tune=zerolatency ! \
     h264parse ! mp4mux ! filesink location=capture.mp4

格式转换
--------------------------

.. code-block:: bash

   # MP4 → WebM (VP8 + Vorbis)
   gst-launch-1.0 filesrc location=input.mp4 ! decodebin name=d \
     d. ! queue ! videoconvert ! vp8enc ! webmmux name=mux ! filesink location=output.webm \
     d. ! queue ! audioconvert ! vorbisenc ! mux.

   # WAV → Opus/OGG
   gst-launch-1.0 filesrc location=input.wav ! wavparse ! audioconvert ! opusenc ! oggmux ! filesink location=output.ogg


RTP 流传输
============================

GStreamer 对 RTP/RTCP 有非常完善的支持，是测试 WebRTC 传输层的利器。

发送 H.264 RTP 流
--------------------------

.. code-block:: bash

   # 发送端：摄像头 → H.264 编码 → RTP 打包 → UDP 发送
   gst-launch-1.0 v4l2src ! videoconvert ! \
     x264enc tune=zerolatency bitrate=500 speed-preset=superfast ! \
     rtph264pay pt=96 ! udpsink host=127.0.0.1 port=5004

   # 接收端：UDP 接收 → RTP 解包 → H.264 解码 → 显示
   gst-launch-1.0 udpsrc port=5004 \
     caps="application/x-rtp,media=video,clock-rate=90000,encoding-name=H264,payload=96" ! \
     rtph264depay ! decodebin ! videoconvert ! autovideosink

发送 VP8 RTP 流
--------------------------

.. code-block:: bash

   # 发送端
   gst-launch-1.0 videotestsrc ! videoconvert ! \
     vp8enc deadline=1 ! rtpvp8pay pt=96 ! udpsink host=127.0.0.1 port=5004

   # 接收端
   gst-launch-1.0 udpsrc port=5004 \
     caps="application/x-rtp,media=video,clock-rate=90000,encoding-name=VP8,payload=96" ! \
     rtpvp8depay ! decodebin ! videoconvert ! autovideosink

发送 Opus RTP 流
--------------------------

.. code-block:: bash

   # 发送端
   gst-launch-1.0 audiotestsrc ! audioconvert ! \
     opusenc ! rtpopuspay pt=111 ! udpsink host=127.0.0.1 port=5006

   # 接收端
   gst-launch-1.0 udpsrc port=5006 \
     caps="application/x-rtp,media=audio,clock-rate=48000,encoding-name=OPUS,payload=111" ! \
     rtpopusdepay ! opusdec ! audioconvert ! autoaudiosink

使用 rtpbin 做音视频同步
--------------------------

``rtpbin`` 可以管理多个 RTP/RTCP 会话，处理同步和 RTCP 报告：

.. code-block:: bash

   # 接收音视频 RTP 流并同步播放
   gst-launch-1.0 rtpbin name=rtpbin \
     udpsrc port=5004 caps="application/x-rtp,media=video,clock-rate=90000,encoding-name=H264" ! \
       rtpbin.recv_rtp_sink_0 \
     rtpbin. ! rtph264depay ! decodebin ! videoconvert ! autovideosink \
     udpsrc port=5006 caps="application/x-rtp,media=audio,clock-rate=48000,encoding-name=OPUS" ! \
       rtpbin.recv_rtp_sink_1 \
     rtpbin. ! rtpopusdepay ! opusdec ! audioconvert ! autoaudiosink


屏幕采集
============================

.. code-block:: bash

   # Linux (X11)
   gst-launch-1.0 ximagesrc ! videoconvert ! autovideosink

   # Linux (X11) 编码并发送 RTP
   gst-launch-1.0 ximagesrc ! video/x-raw,framerate=20/1 ! videoconvert ! \
     x264enc tune=zerolatency bitrate=1000 speed-preset=superfast ! \
     rtph264pay ! udpsink host=127.0.0.1 port=5004

   # macOS
   gst-launch-1.0 avfvideosrc capture-screen=true ! videoconvert ! autovideosink


调试技巧
============================

Pipeline 可视化
--------------------------

通过设置环境变量，可以将 pipeline 导出为 ``.dot`` 文件：

.. code-block:: bash

   export GST_DEBUG_DUMP_DOT_DIR=/tmp/dots
   gst-launch-1.0 videotestsrc ! autovideosink

   # 将 .dot 转为 PNG
   dot -Tpng /tmp/dots/*.dot -o pipeline.png

日志级别
--------------------------

.. code-block:: bash

   # 设置全局日志级别 (0=none, 1=ERROR, 2=WARNING, 3=FIXME, 4=INFO, 5=DEBUG, 9=MEMDUMP)
   GST_DEBUG=3 gst-launch-1.0 videotestsrc ! autovideosink

   # 只对特定模块开启详细日志
   GST_DEBUG=webrtc*:5,dtls*:5 gst-launch-1.0 ...

   # 输出到文件
   GST_DEBUG=4 GST_DEBUG_FILE=/tmp/gst.log gst-launch-1.0 ...

延迟测量
--------------------------

.. code-block:: bash

   # 显示 pipeline 延迟信息
   gst-launch-1.0 -v videotestsrc ! autovideosink 2>&1 | grep latency


FAQ
===============

如何查看支持的编解码器
-----------------------------------------

.. code-block:: bash

   # 列出所有可用的编码器
   gst-inspect-1.0 | grep -i enc

   # 列出所有 RTP payloader / depayloader
   gst-inspect-1.0 | grep -i rtp

如何开发 GStreamer 插件
-----------------------------------------

参见 :doc:`gstreamer_dev` 获取插件开发的详细指南。

如何用 GStreamer 做 WebRTC
-----------------------------------------

参见 :doc:`gstreamer_webrtc` 获取 ``webrtcbin`` 的使用方法和示例。


参考
==============

- GStreamer 官网: https://gstreamer.freedesktop.org/
- GStreamer 文档: https://gstreamer.freedesktop.org/documentation/
- GStreamer 插件开发指南: https://gstreamer.freedesktop.org/documentation/plugin-development/index.html
- GStreamer 源码: https://gitlab.freedesktop.org/gstreamer/gstreamer
- GStreamer 示例: https://gitlab.freedesktop.org/gstreamer/gst-examples
