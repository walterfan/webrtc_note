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

.. code-block:: bash

    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    export PATH="$PATH:${HOME}/depot_tools"

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

先要安装 ninja 这一构建工具, 通过它来生成构建脚本

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

* 1) 一定要在系统设置中选择 Windows SDK , 再选择修改，安装 debugging tool)
* 2) 为了使用本地安装的 visual studio, 需要先设置一下环境变量 `set DEPOT_TOOLS_WIN_TOOLCHAIN=0`

.. code-block::

   gn gen --ide=vs out\Default --args='use_custom_libcxx=false'

然后用 visual studio 打开 out\Default\all.sln


GN 编译选项
--------------------------------
gn 支持的参数很多，例如

* clang_base_path="/usr" 
* clang_use_chrome_plugins=false
* treat_warnings_as_errors=false 
* rtc_build_ssl=false
* rtc_ssl_root="dummy"


在 ARM 平台上的编译

.. code-block::

   gn gen  out/mac --args='target_os="mac" is_debug=false target_cpu="arm64" rtc_include_tests=false rtc_build_tools=false rtc_build_examples=false'


   gn gen out/linux --args='use_custom_libcxx=false clang_base_path="/usr" clang_use_chrome_plugins=false treat_warnings_as_errors=false rtc_build_ssl=false rtc_ssl_root="dummy"'


配置文件
================================

webrtc.gni
-------------------------------

这个文件由其他  BUILD.gn 所包含，它包括了很多特性开关选项和模板, 例如

.. code-block::

   rtc_enable_bwe_test_logging = false


Build.gn
--------------------------------
* src/BUILD.gn

we can change the build configuration file to add some target


.. code-block::

   rtc_static_library("xxx") {
   # Only the root target and the test should depend on this.
   visibility = [
      "//:default",
   ]
   sources = []
   complete_static_lib = true
   suppressed_configs += [ "//build/config/compiler:thin_archive" ]
   deps = [
      "rtc_base",
      "..."
   ]

* src/build/config/compiler/BUILD.gn


e.g.

.. code-block::

   cflags_cc += [ "-std=gnu++2a" ]
   cflags += [ "-fdebug-compilation-dir=." ]
   #"-Wno-psabi"
   #"-Wno-unused-but-set-parameter",
   #"-Wno-unused-but-set-variable",

   #cflags += [ "-Wmax-tokens" ]
   #"-fuse-ctor-homing"



Reference
====================
* `Chromium Code Search`_
* `Webrtc video framerate/resolution 自适应 <https://xie.infoq.cn/article/50b7931b8a023f8ca7f25d4e9>`_
* `WebRTC native code <https://webrtc.googlesource.com/src/+/refs/heads/master/docs/native-code/index.md>`_
* `Ninja manual <https://ninja-build.org/manual.html>`_
* `ninja tool`_

.. _Chromium Code Search: https://source.chromium.org/chromium/chromium/src
.. _ninja tool: https://ninja-build.org/
.. _webrtc-prerequisite-sw: https://webrtc.googlesource.com/src/+/main/docs/native-code/development/prerequisite-sw/index.md
.. _webrtc-depot-tools: https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up
