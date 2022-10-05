#################
WebRTC 构建工具
#################

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
Ninja
--------------------
Ninja is yet another build system. It takes as input the interdependencies of files (typically source code and output executables) and orchestrates building them, quickly.


Run ninja. By default, it looks for a file named build.ninja in the current directory and builds all out-of-date targets. You can specify which targets (files) to build as command line arguments.

There is also a special syntax target^ for specifying a target as the first output of some rule containing the source you put in the command line, if one exists. For example, if you specify target as foo.c^ then foo.o will get built (assuming you have those targets in your build files).

gn
--------------------
The meta-build system used to generate build files for Google Chrome and related projects (v8, node.js), as well as Google Fuchsia. gn can generate Ninja files for all platforms supported by Chrome.

refer to
* https://gn.googlesource.com/gn/+/HEAD/docs/quick_start.md
* https://www.chromium.org/developers/gn-build-configuration/

Passing build arguments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Set build arguments on your build directory by running:

.. code-block::

   gn args out/my_build



Cross-compiling to a target OS or architecture
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Run gn args out/Default (substituting your build directory as needed) and add one or more of the following lines for common cross-compiling options.


.. code-block::

   target_os = "chromeos"
   target_os = "android"

   target_cpu = "arm"
   target_cpu = "x86"
   target_cpu = "x64"

.gn
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.gn 文件是 GN build 的 “源文件”，在这里可以做各种条件判断和配置，gn 会根据这些配置生成特定的 ninja 文件。

.gn 文件中可以使用预定义的参数，比如 is_debug ， target_os ， rtc_use_h264 等。

.gn 中可以 import .gni 文件。


CMake
--------------------
A widely used meta-build system that can generate Ninja files on Linux as of CMake version 2.8.8. Newer versions of CMake support generating Ninja files on Windows and Mac OS X too.


