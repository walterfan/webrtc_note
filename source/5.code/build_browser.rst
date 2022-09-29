####################
WebRTC 构建浏览器
####################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Build Tools
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. contents:: Contents
   :local:


构建工具
====================

首先需要安装 depot tools

.. code-block::

   git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
   export PATH="$PATH:/path/to/depot_tools"
   # if you install it on the home folder , do not use ~
   export PATH="$PATH:${HOME}/depot_tools"

构建 Chrome
====================

Mac 系统
-------------------
https://chromium.googlesource.com/chromium/src/+/master/docs/mac_build_instructions.md

Mac 上需要 Xcode `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

.. code-block::

   mkdir chromium && cd chromium
   caffeinate fetch chromium
   cd src
   gn gen out/Default
   autoninja -C out/Default chrome

启动时可以使用

.. code-block::

   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --enable-logging --v=0 --vmodule=*/webrtc/*=1

参见 https://support.google.com/chrome/a/answer/6271282?hl=zh-Hans&ref_topic=6314967#zippy=%2Cmac


Linux 系统
-----------------------
参见 https://chromium.googlesource.com/chromium/src/+/refs/heads/main/docs/linux/build_instructions.md

.. code-block::

   mkdir ~/chromium && cd ~/chromium
   fetch --nohooks chromium
   cd src
   ./build/install-build-deps.sh
   gclient runhooks
   gn args out/Default
   gn gen out/Default
   autoninja -C out/Default chrome

* out/default/args.gn

.. code-block::

   is_debug = false
   dcheck_always_on = false
   is_official_build = true

   is_debug = false
   enable_nacl = false

   proprietary_codecs = true
   ffmpeg_branding = "Chrome"


* 编译和执行相关的单元测试


.. code-block::

   autoninja -C out/Default unit_tests
   out/Default/unit_tests --gtest_filter="PushClientTest.*"


构建 Firefox
=======================

https://firefox-source-docs.mozilla.org/setup/macos_build.html