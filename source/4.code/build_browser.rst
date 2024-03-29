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

Mac 上需要运行

.. code-block::

   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer




.. code-block::

   mkdir chromium && cd chromium
   caffeinate fetch chromium
   cd src
   gclient runhooks
   gn args out/Default
   gn gen out/Default
   autoninja -C out/Default chrome


其中, `gn args out/Default` 这一步中编辑如下的配置文件， 以回忆编译速度

.. code-block::

   # Set build arguments here. See `gn help buildargs`.
   is_debug = false
   dcheck_always_on = false
   is_official_build = true

   symbol_level=1
   blink_symbol_level=0
   v8_symbol_level=0

   enable_nacl = false

   proprietary_codecs = true
   ffmpeg_branding = "Chrome"
   chrome_pgo_phase = 0

启动时可以使用

.. code-block::

   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --enable-logging --v=0 --vmodule=*/webrtc/*=1 --use-fake-device-for-media-stream --use-file-for-fake-video-capture=/Users/yafan/Downloads/FourPeople_1280x720_60.y4m

* 参见 https://support.google.com/chrome/a/answer/6271282?hl=zh-Hans&ref_topic=6314967#zippy=%2Cmac
* 日志文件位于 `~/Library/Application Support/Chromium/chrome_debug.log`

Linux 系统
-----------------------
参见


* `build_instructions`_
* `debugging tips`_


.. code-block::

   git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
   export PATH="$PATH:/home/ubuntu/depot_tools"
   mkdir ~/chromium && cd ~/chromium
   fetch --nohooks chromium
   cd src
   ./build/install-build-deps.sh
   gclient runhooks
   gn args out/Default

   gn gen out/Default

   autoninja -C out/Default chrome


* 为了提高编译速度， 在 gn 的参数文件中填入如下编译参数

.. code-block::


   blink_symbol_level=0
   dcheck_always_on = false
   is_official_build = true

   is_debug = false
   enable_nacl = false

   proprietary_codecs = true
   ffmpeg_branding = "Chrome"

.. _build_instructions: https://chromium.googlesource.com/chromium/src/+/refs/heads/main/docs/linux/build_instructions.md
.. _debugging tips: https://chromium.googlesource.com/chromium/src/+/refs/heads/main/docs/linux/debugging.md


启动测试

.. code-block::

   cd /home/ubuntu/chromium/src/out/Default
   ./chrome --enable-logging --v=0 --vmodule=*/webrtc/*=1 \
   --use-fake-device-for-media-stream \
   --use-file-for-fake-video-capture=/home/ubuntu/reference_less_video_test_file.y4m


Log file 位于 `~/.config/chromium/chrome_debug.log`

.. code-block::

   mkdir ~/chromium && cd ~/chromium
   fetch --nohooks chromium
   cd src
   ./build/install-build-deps.sh
   gclient runhooks
   gn args out/Default # make args.gn as below
   gn gen out/Default
   autoninja -C out/Default chrome

* out/default/args.gn

.. code-block::

   is_debug = false
   dcheck_always_on = false
   is_official_build = true

   symbol_level=1
   blink_symbol_level=0
   v8_symbol_level=0

   is_debug = false
   enable_nacl = false

   proprietary_codecs = true
   ffmpeg_branding = "Chrome"


* 编译和执行相关的单元测试


.. code-block::

   autoninja -C out/Default unit_tests
   out/Default/unit_tests --gtest_filter="PushClientTest.*"


Build Chrome on mac
=======================


Building Chrome on a Mac can be a complex process, but here are the basic steps you can follow:

1. Install Xcode: Before you start, make sure you have Xcode installed on your Mac. You can download Xcode from the App Store or from the Apple Developer website.

2. Install depot_tools: depot_tools is a set of tools that you'll need to download the Chrome source code and manage the build process. You can install depot_tools by following these steps:

  - Open Terminal and navigate to the folder where you want to install depot_tools.

  - Run the following command: git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

  - Add depot_tools to your PATH environment variable by running the following command: export PATH=$PATH:/path/to/depot_tools

3. Download the Chrome source code: Once you have depot_tools installed, you can download the Chrome source code by running the following command in Terminal: fetch --nohooks chromium

4. Install the build dependencies: Before you can build Chrome, you'll need to install the build dependencies by running the following command in Terminal: cd chromium && ./build/install-build-deps.sh

5. Generate the build files: Once the build dependencies are installed, you can generate the build files by running the following command in Terminal: gn gen out/Default

6. Build Chrome: Finally, you can build Chrome by running the following command in Terminal: ninja -C out/Default chrome

The build process can take a long time, depending on your computer's performance. Once the build is complete, you should have a fully functional version of Chrome that you built yourself.

构建 Firefox
=======================

1. Install Xcode: Before you start, make sure you have Xcode installed on your Mac. You can download Xcode from the App Store or from the Apple Developer website.

2. Install Mercurial: Mercurial is a version control system that you'll need to download the Firefox source code. You can install Mercurial by running the following command in Terminal: brew install mercurial

.. code-block::

   brew install autoconf@2.13 mercurial ccache rustup-init gpg nodejs npm

3. Download the Firefox source code: Once you have Mercurial installed, you can download the Firefox source code by running the following command in Terminal:

.. code-block::

   hg clone https://hg.mozilla.org/mozilla-central

4. Install the build dependencies: Before you can build Firefox, you'll need to install the build dependencies by running the following command in Terminal:

.. code-block::

   ./mach bootstrap

5. Generate the build files: Once the build dependencies are installed, you can generate the build files by running the following command in Terminal:

.. code-block::

    ./mach configure

6. Build Firefox: Finally, you can build Firefox by running the following command in Terminal:

.. code-block::

   ./mach build

https://firefox-source-docs.mozilla.org/setup/macos_build.html