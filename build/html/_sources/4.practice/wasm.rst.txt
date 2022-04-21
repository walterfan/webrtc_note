######################
WebAssembly
######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebAssembly
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


Overview
========================


WebAssembly 的基本想法就是让浏览器加载由其他语言编译而成的二进制模块,并高效地解释和执行, 从而提高性能。

Javascript 之所以慢，一个重要原因就是它是解释执行的，

WebAssembly 简称 wasm 是一种新型的二进制代码格式， 浏览器可以用类似模块加载的方式来加载，解析和执行 wasm 文件。

wasm 描述一个内存安全的沙箱执行环境，可在 JavaScript 虚拟机中实现， 并遵循与 Web 应用一致的同源策略来保证其安全性。

相对 wasm 的二进制文件格式，它还有对应的 wat 可读文本格式。

.. figure:: ../_static/v8_pipeline_wasm.png
   :scale: 100 %
   :alt: V8 Pipeline Design + WASM


所有变量存储的数据类型都是在程序运行之前就已经确定，并在后续运行过程中无法更改。



核心原理
==================

Wasm 二进制模块以 magic number 和 version 开头, 之后的内容存放在不同的段 segment 中
Wasm 规范共定义了 12 种段 , 并分配了不同的 ID

1. 类型段(ID=1)
2. 导入(ID=2)和导出段(ID=7)
3. 函数(ID=3)和代码(ID=10)段
4. 表(ID=4)和元素(ID=9)段
5. 内存(ID=5)和数据(ID=11)段
6. 全局段(ID=6)
7. 起始段(ID=8)
8. 自定义段(ID=0)

Wasm 的特点是可以流式处理,边下载,边解码,验证和编译


工具链
==================


Emscripten
------------------

Emscripten is a complete compiler toolchain to WebAssembly, using LLVM, with a special focus on speed, size, and the Web platform

* 安装 emsdk

.. code-block::

   # Get the emsdk repo
   git clone https://github.com/emscripten-core/emsdk.git

   # Enter that directory
   cd emsdk

   # Fetch the latest version of the emsdk (not needed the first time you clone)
   git pull origin main

   # Download and install the latest SDK tools.
   ./emsdk install latest

   # Make the "latest" SDK "active" for the current user. (writes .emscripten file)
   ./emsdk activate latest

   # Activate PATH and other environment variables in the current terminal
   source ./emsdk_env.sh

   emcc -v

* 测试   

.. code-block:: cpp


   ./emcc hello_world.c
   //--------------------
   #include <stdio.h>

   int main() {
   printf("hello, world!\n");
   return 0;
   }


SIMD
==================

Reference
==================


* `WebAssembly Getting Started`_

.. _WebAssembly Getting Started: https://webassembly.org/getting-started/developers-guide/

* `Compiling an Existing C Module to WebAssembly`_

.. _Compiling an Existing C Module to WebAssembly: https://developer.mozilla.org/en-US/docs/WebAssembly/existing_C_to_wasm

* `Compiling a New C/C++ Module to WebAssembly`_

.. _Compiling a New C/C++ Module to WebAssembly: https://developer.mozilla.org/en-US/docs/WebAssembly/C_to_wasm


* `A comparison with WebAssembly`_.

.. _A comparison with WebAssembly: https://blog.sessionstack.com/how-javascript-works-a-comparison-with-webassembly-why-in-certain-cases-its-better-to-use-it-d80945172d79