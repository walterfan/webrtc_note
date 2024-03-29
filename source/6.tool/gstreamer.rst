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
**Abstract** GStreamer
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
==============
GStreamer is a the multi-platform, modular, open-source, media streaming framework.

它是一个跨多平台，模块化的开源媒体流处理框架，功能强大。

多平台
----------------------
GStreamer 适用于所有主要操作系统，例如 Linux、Android、Windows、Max OS X、iOS，以及大多数 BSD、商业 Unix、Solaris 和 Symbian。

它已被移植到广泛的操作系统、处理器和编译器。 它在所有主要硬件架构上运行，包括 x86、ARM、MIPS、SPARC 和 PowerPC，在 32 位和 64 位以及小端或大端上运行。

GStreamer 可以桥接到其他多媒体框架，以便重用现有组件（例如编解码器）并使用平台输入/输出机制：

* Linux/Unix: OpenMAX-IL (via gst-omx)
* Windows: DirectShow
* Mac OS X: QuickTime

强大的核心库
--------------------------------------------

* 基于图的结构允许构建任意的流水线 pipeline
* 基于 GLib 2.0 对象模型进行面向对象设计和继承
* 小于 500KB 的紧凑型核心库，约 65 K 行代码
* 多线程 pipeline 的构建简单透明
* 为插件和应用程序开发人员提供干净、简单和稳定的 API
* 极其轻量级的数据传递意味着高性能和低延迟
* 为核心和插件/应用程序开发人员提供完整的调试系统
* 时钟确保全局的数据流之间的的同步（音视频同步）
* 通过服务质量 (qos) 确保在高 CPU 负载下获得最佳质量

智能的插件架构
--------------------------------------------

* 动态加载的插件提供 Element 和媒体类型，通过注册表缓存按需加载，类似于 ld.so.cache
* Element 接口处理所有已知类型的源 source、过滤器 filter 和接收器 sinks
* Capabilities 系统允许使用 MIME 类型和媒体特定属性验证元素兼容性
* Autoplugging 使用 Capabilities系统自动完成复杂路径匹配
* 可以通过将 pipeline 转储到 .dot 文件并从中创建 PNG 图像来可视化 pipeline
* 资源友好的插件不会浪费内存

多媒体技术的广泛覆盖
--------------------------------------------

GStreamers 功能可以通过新插件进行扩展。 下面列出的功能只是一个粗略的概述，使用了 GStreamers 自带的插件，不包括任何第三方插件。

* 容器格式 container formats: asf, avi, 3gp/mp4/mov, flv, mpeg-ps/ts, mkv/webm, mxf, ogg
* 流媒体 streaming: http, mms, rtsp
* 编码 codecs: FFmpeg, various codec libraries, 3rd party codec packs
* 元数据 metadata: native container formats with a common mapping between them
* 视频 video: various colorspaces, support for progressive and interlaced video
* 音频 audio: integer and float audio in various bit depths and multichannel configurations


可扩展的开发工具
--------------------------------------------

* gst-launch 是用于快速原型设计和测试的命令行工具，类似于 ecasound
* 有大量文档，包括部分完成的手册和插件编写者指南
* 每个模块中有大量测试程序和示例代码
* 可使用各种编程语言访问 GStreamer API

Installation
===============
Linux
---------------

.. code-block::

    sudo apt-get install -y gstreamer1.0-tools gstreamer1.0-nice gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-plugins-good libgstreamer1.0-dev git libglib2.0-dev libgstreamer-plugins-bad1.0-dev libsoup2.4-dev libjson-glib-dev

MacOS
---------------
可从下面的链接下载
https://gstreamer.freedesktop.org/documentation/installing/on-mac-osx.html?gi-language=c

安装后有如下文件:

* /Library/Frameworks/GStreamer.framework/: Framework's root path
* /Library/Frameworks/GStreamer.framework/Versions: path with all the versions of the framework
* /Library/Frameworks/GStreamer.framework/Versions/Current: link to the current version of the framework
* /Library/Frameworks/GStreamer.framework/Headers: path with the development headers
* /Library/Frameworks/GStreamer.framework/Commands: link to the commands provided by the framework, such as gst-inspect-1.0 or gst-launch-1.0

.. code-block::

   #include_path=/Library/Frameworks/GStreamer.framework/Headers
   export PATH=$PATH:/Library/Frameworks/GStreamer.framework/Versions/1.0/bin
   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/Library/Frameworks/GStreamer.framework/Versions/1.0/lib


Get started
===============

Tools
---------------
* gst-inspect 显示可用的插件及 element 列表
* gst-launch 运行 pipeline
* gst-typfind
* gst-codec-info
* gst-device-monitor


gst-launch
~~~~~~~~~~~~~~~

* 查看测试视频

.. code-block::

   gst-launch-1.0 videotestsrc ! videoconvert ! autovideosink


* 捕获麦克风并显示声音的波形

.. code-block::

   gst-launch-1.0 -v -m autoaudiosrc ! audioconvert ! wavescope style=3 shader=2 ! videoconvert ! autovideosink

* 播放 mp4 文件

.. code-block::

   gst-launch-1.0 playbin uri=file:///opt/webrtc_primer/material/obama_talk.mp4
   gst-launch-1.0 -v playbin uri=file:///`pwd`/obama_talk.mp4

* UDP 媒体流传输

.. code-block::

   # linux send h264 rtp stream:
   gst-launch-1.0 -v ximagesrc ! video/x-raw,framerate=20/1 ! videoscale ! videoconvert ! x264enc tune=zerolatency bitrate=500 speed-preset=superfast ! rtph264pay ! udpsink host=127.0.0.1 port=5000

   # Macos send h264 rtp stream:
   gst-launch-1.0 -v avfvideosrc capture-screen=true ! video/x-raw,framerate=20/1 ! videoscale ! videoconvert ! x264enc tune=zerolatency bitrate=500 speed-preset=superfast ! rtph264pay ! udpsink host=127.0.0.1 port=5000

   # receive h264 rtp stream:
   gst-launch-1.0 -v udpsrc port=5000 caps = "application/x-rtp, media=(string)video, clock-rate=(int)90000, encoding-name=(string)H264, payload=(int)96" ! rtph264depay ! decodebin ! videoconvert ! autovideosink



gst-inspect
~~~~~~~~~~~~~~

* view plugin videotestsrc

.. code-block::

   gst-inspect-1.0 videotestsrc

gst-discoverer
~~~~~~~~~~~~~~~

* check video file codec

.. code-block::

   gst-discoverer-1.0 ../../../material/obama_talk.mp4



基本概念
=========================

PIPELINE 流水线
-------------------------
A pipeline consists elements and links.
Elements can be put into bins of different sorts.
Elements, links and bins can be specified in a pipeline description in any order.

Elements 元素
--------------------------
ELEMENTTYPE [PROPERTY1 ...]

Creates an element of type ELEMENTTYPE and sets the PROPERTIES.



Bins 箱子
--------------------------
[BINTYPE.] ( [PROPERTY1 ...] PIPELINE-DESCRIPTION )
Specifies that a bin of type BINTYPE is created and the given properties are set. Every element between the braces is put into the bin. Please note the dot that has to be used after the BINTYPE. You will almost never need this functionality, it is only really useful for applications using the gst_launch_parse() API with 'bin' as bintype. That way it is possible to build partial pipelines instead of a full-fledged top-level pipeline.

Links 连接
--------------------------
[[SRCELEMENT].[PAD1,...]] ! [[SINKELEMENT].[PAD1,...]] [[SRCELEMENT].[PAD1,...]] ! CAPS ! [[SINKELEMENT].[PAD1,...]] [[SRCELEMENT].[PAD1,...]] : [[SINKELEMENT].[PAD1,...]] [[SRCELEMENT].[PAD1,...]] : CAPS : [[SINKELEMENT].[PAD1,...]]

Links the element with name SRCELEMENT to the element with name SINKELEMENT, using the caps specified in CAPS as a filter. Names can be set on elements with the name property. If the name is omitted, the element that was specified directly in front of or after the link is used. This works across bins. If a padname is given, the link is done with these pads. If no pad names are given all possibilities are tried and a matching pad is used. If multiple padnames are given, both sides must have the same number of pads specified and multiple links are done in the given order.
So the simplest link is a simple exclamation mark, that links the element to the left of it to the element right of it.
Linking using the : operator attempts to link all possible pads between the elements

Caps 能力
--------------------------
MEDIATYPE [, PROPERTY[, PROPERTY ...]]] [; CAPS[; CAPS ...]]

Creates a capability with the given media type and optionally with given properties. The media type can be escaped using " or '. If you want to chain caps, you can add more caps in the same format afterwards.

Properties 属性
--------------------------
NAME=[(TYPE)]VALUE
in lists and ranges: [(TYPE)]VALUE

Sets the requested property in capabilities. The name is an alphanumeric value and the type can have the following case-insensitive values:

- i or int for integer values or ranges
- f or float for float values or ranges
- b, bool or boolean for boolean values
- s, str or string for strings
- fraction for fractions (framerate, pixel-aspect-ratio)
- l or list for lists

If no type was given, the following order is tried: integer, float, boolean, string.
Integer values must be parsable by strtol(), floats by strtod(). FOURCC values may either be integers or strings. Boolean values are (case insensitive) yes, no, true or false and may like strings be escaped with " or '.
Ranges are in this format: [ VALUE, VALUE ]
Lists use this format: { VALUE [, VALUE ...] }


PIPELINE 示例
============================
The examples below assume that you have the correct plug-ins available. In general, "pulsesink" can be substituted with another audio output plug-in such as "alsasink" or "osxaudiosink" Likewise, "xvimagesink" can be substituted with "ximagesink", "glimagesink", or "osxvideosink". Keep in mind though that different sinks might accept different formats and even the same sink might accept different formats on different machines, so you might need to add converter elements like audioconvert and audioresample (for audio) or videoconvert (for video) in front of the sink to make things work.

Audio playback
--------------------------
Play the mp3 music file "music.mp3" using a libmpg123-based plug-in and output to an Pulseaudio device
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        gst-launch-1.0 filesrc location=music.mp3 ! mpegaudioparse ! mpg123audiodec ! audioconvert ! audioresample ! pulsesink

Play an Ogg Vorbis format file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        gst-launch-1.0 filesrc location=music.ogg ! oggdemux ! vorbisdec ! audioconvert ! audioresample ! pulsesink

Play an mp3 file or an http stream using GIO
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        gst-launch-1.0 giosrc location=music.mp3 ! mpegaudioparse ! mpg123audiodec ! audioconvert ! pulsesink

        gst-launch-1.0 giosrc location=http://domain.com/music.mp3 ! mpegaudioparse ! mpg123audiodec ! audioconvert ! audioresample ! pulsesink

Use GIO to play an mp3 file located on an SMB server
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        gst-launch-1.0 giosrc location=smb://computer/music.mp3 ! mpegaudioparse ! mpg123audiodec ! audioconvert ! audioresample ! pulsesink

Format conversion
--------------------------

Convert an mp3 music file to an Ogg Vorbis file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        gst-launch-1.0 filesrc location=music.mp3 ! mpegaudioparse ! mpg123audiodec ! audioconvert ! vorbisenc ! oggmux ! filesink location=music.ogg

Convert to the FLAC format
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        gst-launch-1.0 filesrc location=music.mp3 ! mpegaudioparse ! mpg123audiodec ! audioconvert ! flacenc ! filesink location=test.flac


Plays a .WAV file that contains raw audio data (PCM).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        gst-launch-1.0 filesrc location=music.wav ! wavparse ! audioconvert ! audioresample ! pulsesink

Convert a .WAV file containing raw audio data into an Ogg Vorbis or mp3 file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        gst-launch-1.0 filesrc location=music.wav ! wavparse ! audioconvert ! vorbisenc ! oggmux ! filesink location=music.ogg

        gst-launch-1.0 filesrc location=music.wav ! wavparse ! audioconvert ! lamemp3enc ! filesink location=music.mp3

Rips all tracks from compact disc and convert them into a single mp3 file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        gst-launch-1.0 cdparanoiasrc mode=continuous ! audioconvert ! lamemp3enc ! mpegaudioparse ! id3v2mux ! filesink location=cd.mp3

Rips track 5 from the CD and converts it into a single mp3 file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        gst-launch-1.0 cdparanoiasrc track=5 ! audioconvert ! lamemp3enc ! mpegaudioparse ! id3v2mux ! filesink location=track5.mp3

Using gst-inspect-1.0(1), it is possible to discover settings like the above for cdparanoiasrc that will tell it to rip the entire cd or only tracks of it. Alternatively, you can use an URI and gst-launch-1.0 will find an element (such as cdparanoia) that supports that protocol for you, e.g.:

.. code-block::

       gst-launch-1.0 cdda://5 ! lamemp3enc vbr=new vbr-quality=6 ! filesink location=track5.mp3

Records sound from your audio input and encodes it into an ogg file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        gst-launch-1.0 pulsesrc ! audioconvert ! vorbisenc ! oggmux ! filesink location=input.ogg

Video
----------------------
Display only the video portion of an MPEG-1 video file, outputting to an X display window
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        gst-launch-1.0 filesrc location=JB_FF9_TheGravityOfLove.mpg ! dvddemux ! mpegvideoparse ! mpeg2dec ! xvimagesink

Display the video portion of a .vob file (used on DVDs), outputting to an SDL window
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::
        
        gst-launch-1.0 filesrc location=/flflfj.vob ! dvddemux ! mpegvideoparse ! mpeg2dec ! sdlvideosink

Play both video and audio portions of an MPEG movie
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::
        
        gst-launch-1.0 filesrc location=movie.mpg ! dvddemux name=demuxer  demuxer. ! queue ! mpegvideoparse ! mpeg2dec ! sdlvideosink  demuxer. ! queue ! mpegaudioparse ! mpg123audiodec ! audioconvert ! audioresample ! pulsesink

Play an AVI movie with an external text subtitle stream
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


.. code-block::
        
        gst-launch-1.0 filesrc location=movie.mpg ! mpegdemux name=demuxer demuxer. ! queue ! mpegvideoparse ! mpeg2dec ! videoconvert ! sdlvideosink   demuxer. ! queue ! mpegaudioparse ! mpg123audiodec ! audioconvert ! audioresample ! pulsesink

This example also shows how to refer to specific pads by name if an element (here: textoverlay) has multiple sink or source pads.

.. code-block::
        
        gst-launch-1.0 textoverlay name=overlay ! videoconvert ! videoscale !  autovideosink   filesrc location=movie.avi ! decodebin ! videoconvert ! overlay.video_sink   filesrc location=movie.srt ! subparse ! overlay.text_sink

Play an AVI movie with an external text subtitle stream using playbin
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::
        
        gst-launch-1.0 playbin uri=file:///path/to/movie.avi suburi=file:///path/to/movie.srt

Network streaming
-------------------------

Stream video using RTP and network elements.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This command would be run on the transmitter

.. code-block::
        
        gst-launch-1.0 v4l2src ! video/x-raw,width=128,height=96,format=UYVY ! videoconvert ! ffenc_h263 ! video/x-h263 ! rtph263ppay pt=96 ! udpsink host=192.168.1.1 port=5000

Use this command on the receiver

.. code-block::
        
        gst-launch-1.0 udpsrc port=5000 ! application/x-rtp, clock-rate=90000,payload=96 ! rtph263pdepay queue-delay=0 ! ffdec_h263 ! xvimagesink

Diagnostic
-------------------------
Generate a null stream and ignore it (and print out details).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::
        
        gst-launch-1.0 -v fakesrc num-buffers=16 ! fakesink

Generate a pure sine tone to test the audio output
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::
        
        gst-launch-1.0 audiotestsrc ! audioconvert ! audioresample ! pulsesink

Generate a familiar test pattern to test the video output
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::
        
        gst-launch-1.0 videotestsrc ! xvimagesink

        gst-launch-1.0 videotestsrc ! ximagesink

Automatic linking
------------------------------
You can use the decodebin element to automatically select the right elements to get a working pipeline.

Play any supported audio format
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::
        
        gst-launch-1.0 filesrc location=musicfile ! decodebin ! audioconvert ! audioresample ! pulsesink

Play any supported video format with video and audio output.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Threads are used automatically. To make this even easier, you can use the playbin element:

.. code-block::
        
        gst-launch-1.0 filesrc location=videofile ! decodebin name=decoder decoder. ! queue ! audioconvert ! audioresample ! pulsesink   decoder. !  videoconvert ! xvimagesink

        gst-launch-1.0 playbin uri=file:///home/joe/foo.avi

Filtered connections
--------------------------------

These examples show you how to use filtered caps.

Show a test image and use the YUY2 or YV12 video format for this.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::
        
        gst-launch-1.0 videotestsrc ! 'video/x-raw,format=YUY2;video/x-raw,format=YV12' ! xvimagesink

Record audio and write it to a .wav file.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Force usage of signed 16 to 32 bit samples and a sample rate between 32kHz and 64KHz.

.. code-block::
        
        gst-launch-1.0 pulsesrc !  'audio/x-raw,rate=[32000,64000],format={S16LE,S24LE,S32LE}' ! wavenc ! filesink location=recording.wav


FAQ
===============

How to make a gstreamer plugin
-----------------------------------------
1) build develop environment

.. code-block::

   docker run --name gst_dev --rm -i -t -v `pwd`:/workspace restreamio/gstreamer:latest-dev-with-source /bin/bash

2) 定义存储数据的元素的结构
3) 定义这个元素的类
4) 定义这个元素的标准宏
5) 定义返回类型信息的标准函数
6) 注册这个元素


Reference
==============
* GStreamer document: https://gitlab.freedesktop.org/gstreamer/gst-docs.git
* GStreamer plugin guide: https://gstreamer.freedesktop.org/documentation/plugin-development/index.html?gi-language=c