#################
WebRTC 源码构建
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

按照 https://webrtc.github.io/webrtc-org/native-code/development， 可以在 windows, mac 或 linux 上构建 webrtc library.

前提是你要能连接上 webrtc 的仓库，有些地方需要翻墙。

1. 安装 Chromium 软件库工具.
   
   参见 
   * `WebRTC 开发依赖软件 <webrtc-prerequisite-sw_>`_
   * `安装 WebRTC 开发工具  <webrtc-depot-tools_>`_
  
2. 下载 WebRTC 源码
       
.. code-block:: bash

   $ mkdir webrtc-checkout
   $ cd webrtc-checkout
   $ fetch --nohooks webrtc
   $ gclient sync --force


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

注意:

1）一定要在系统设置中选择 Windows SDK , 再选择修改，安装 debugging tool)
2）为了使用本地安装的 visual studio, 需要先设置一下环境变量 `set DEPOT_TOOLS_WIN_TOOLCHAIN=0`

.. code-block::

   gn gen --ide=vs out\Default

然后用 visual studio 打开 out\Default\all.sln


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


.gn
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.gn 文件是 GN build 的 “源文件”，在这里可以做各种条件判断和配置，gn 会根据这些配置生成特定的 ninja 文件。

.gn 文件中可以使用预定义的参数，比如 is_debug ， target_os ， rtc_use_h264 等。

.gn 中可以 import .gni 文件。


CMake
--------------------
A widely used meta-build system that can generate Ninja files on Linux as of CMake version 2.8.8. Newer versions of CMake support generating Ninja files on Windows and Mac OS X too.



Reference
====================
* `Chromium Code Search`_
* `Webrtc video framerate/resolution 自适应 <https://xie.infoq.cn/article/50b7931b8a023f8ca7f25d4e9>`_
* https://webrtc.googlesource.com/src/+/refs/heads/master/docs/native-code/index.md
* https://ninja-build.org/manual.html

.. _Chromium Code Search: https://source.chromium.org/chromium/chromium/src
.. _ninja-tool: https://ninja-build.org/
.. _webrtc-prerequisite-sw: https://webrtc.googlesource.com/src/+/main/docs/native-code/development/prerequisite-sw/index.md
.. _webrtc-depot-tools: https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up
.. _overuse_frame_detector: ./webrtc_overuse_frame_decoder.html
.. _congestion control: ./webrtc_cc.html