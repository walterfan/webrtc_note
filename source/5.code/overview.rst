#################
WebRTC 源码分析
#################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Source
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents:: Contents
   :local:


Source code
=============
1. 安装 Chromium 软件库工具.
   
   参见 
   * `WebRTC 开发依赖软件 <webrtc-prerequisite-sw_>`_
   * `安装 WebRTC 开发工具  <webrtc-depot-tools_>`_
  
2. 下载 WebRTC 源码
       
.. code-block:: bash

   $ mkdir webrtc-checkout
   $ cd webrtc-checkout
   $ fetch --nohooks webrtc
   $ gclient sync


3. 更新源码到你自己的分支

.. code-block:: bash

   $ git checkout main
   $ git pull origin main
   $ gclient sync
   $ git checkout my-branch
   $ git merge main

4. 构建

先要安装 `ninja 构建工具 <ninja-tool_>`_ 这一构建工具, 通过它来生成构建脚本

在 Linux 系统上，比较简单的方法是运行 `./build/install-build-deps.sh`

.. code-block:: bash

   $ cd src
   $ python build/util/lastchange.py build/util/LASTCHANGE
   # generate project files using the defaults (Debug build)
   $ gn gen out/Default
   # clean all build artifacts in a directory but leave the current GN configuration untouched
   $ gn clean out/Default
   $ ninja -C out/Default

在 windows 系统上，建议安装 visual studio 和 windows 10 SDK
(注意一定要在系统设置中选择 Windows SDK , 再选择修改，安装 debugging tool)

.. code-block::

   gn gen --ide=vs out\Default

然后用 visual studio 打开 out\Default\all.sln

Modules
=============

* async_audio_processing
* audio_coding
* audio_device
* audio_mixer
* audio_processing
* congestion_controller
* desktop_capture
* include
* pacing
* remote_bitrate_estimator
* rtp_rtcp
* third_party
  - fft
  - g711
  - g722
  - portaudio
* utility
* video_capture
* video_coding
* video_processing


Treasure in code
========================

* `overuse_frame_detector`_
  - webrtc/video/adaptation

* `congestion control`
  - webrtc/modules/congestion_controller/

* remote_bitrate_estimator
  - webrtc/modules/remote_bitrate_estimator/


构建工具
====================
Ninja
--------------------
Ninja is yet another build system. It takes as input the interdependencies of files (typically source code and output executables) and orchestrates building them, quickly.


Run ninja. By default, it looks for a file named build.ninja in the current directory and builds all out-of-date targets. You can specify which targets (files) to build as command line arguments.

There is also a special syntax target^ for specifying a target as the first output of some rule containing the source you put in the command line, if one exists. For example, if you specify target as foo.c^ then foo.o will get built (assuming you have those targets in your build files).

gn
--------------------
The meta-build system used to generate build files for Google Chrome and related projects (v8, node.js), as well as Google Fuchsia. gn can generate Ninja files for all platforms supported by Chrome.

CMake
--------------------
A widely used meta-build system that can generate Ninja files on Linux as of CMake version 2.8.8. Newer versions of CMake support generating Ninja files on Windows and Mac OS X too.


测试
====================

* Chrome command line flags that are useful for WebRTC-related testing:

.. code-block::
      
   --allow-file-access-from-files allows getUserMedia() to be called from file:// URLs.

   --disable-gesture-requirement-for-media-playback removes the need to tap a <video> element to start it playing on Android.

   --use-fake-ui-for-media-stream avoids the need to grant camera/microphone permissions.

   --use-fake-device-for-media-stream feeds a test pattern to getUserMedia() instead of live camera input.

   --use-file-for-fake-video-capture=path/to/file.y4m feeds a Y4M test file to getUserMedia() instead of live camera input.

Reference
====================
* `Chromium Code Search`_
* `Webrtc video framerate/resolution 自适应 <https://xie.infoq.cn/article/50b7931b8a023f8ca7f25d4e9>`_
* https://ninja-build.org/manual.html


.. _Chromium Code Search: https://source.chromium.org/chromium/chromium/src
.. _ninja-tool: https://ninja-build.org/
.. _webrtc-prerequisite-sw: https://webrtc.googlesource.com/src/+/main/docs/native-code/development/prerequisite-sw/index.md
.. _webrtc-depot-tools: https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up

.. _overuse_frame_detector: ./webrtc_overuse_frame_decoder.html
.. _congestion control: ./webrtc_congestion_control.html