#################
Build Tools
#################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Build Tools
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

Overview
====================

Ninja 原意是忍者的意思，它是一个专注于速度的小型构建工具

Ninja
--------------------
Ninja 是一个构建系统。 它将文件的相互依赖关系（通常是源代码和输出可执行文件）作为输入，并快速编排构建它们。

运行Ninja，默认情况下，它会在当前目录中查找名为 build.ninja 的文件并构建所有过时的目标。 您可以指定要构建的目标（文件）作为命令行参数。

还有一个特殊的语法 target^ 用于将目标指定为某个规则的第一个输出，其中包含您在命令行中输入的源（如果存在）。 例如，如果您将目标指定为 foo.c^，那么 foo.o 将被构建（假设您的构建文件中有这些目标）。


gn
--------------------

用于为 Google Chrome 和相关项目（v8、node.js）以及 Google Fuchsia 生成构建文件的元构建系统。 gn 可以为 Chrome 支持的所有平台生成 Ninja 文件。

CMake
--------------------

自 CMake 版本 2.8.8 起，可以在 Linux 上生成 Ninja 文件的广泛使用的元构建系统。 较新版本的 CMake 也支持在 Windows 和 Mac OS X 上生成 Ninja 文件。



gn
===================



quick start
-------------------

.. code-block::

    git clone https://gn.googlesource.com/gn
    cd gn
    python build/gen.py
    ninja -C out
    # To run tests:
    out/gn_unittests

Setting up a build
-------------------------

Unlike some other build systems, with GN you set up your own build directories with the settings you want. This lets you maintain as many different builds in parallel as you need.

Once you set up a build directory, the Ninja files will be automatically regenerated if they're out of date when you build in that directory so you should not have to re-run GN.

To make a build directory:

.. code-block::

    gn gen out/my_build

Passing build arguments
--------------------------
Set build arguments on your build directory by running:

.. code-block::

    gn args out/my_build



Reference
====================
* https://gn.googlesource.com/gn/+/main/docs/quick_start.md