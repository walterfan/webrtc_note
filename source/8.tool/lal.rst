##########
LAL
##########


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =======================================
**Abstract** LAL 构建系统与依赖管理器
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ =======================================



.. contents::
   :local:


概述
==============

LAL（Language-Agnostic build system）是 Cisco 开源的一个严格的、语言无关的构建系统和依赖管理器，使用 Rust 编写。

在 WebRTC 相关的 C/C++ 项目开发中（如编译 libwebrtc、libopus、libopenh264 等），
LAL 可以帮助管理复杂的构建环境和依赖关系，确保跨团队、跨项目的构建一致性。

.. note::

   该项目目前已不再活跃维护，但其设计理念（Docker 化构建环境 + 严格版本控制 + 构建缓存）仍有参考价值。


核心特性
==============

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 特性
     - 说明
   * - 语言无关
     - ``lal build`` 在 Docker 容器中执行 ``BUILD`` 脚本，支持 cmake、autotools、cargo、go、python 等任何构建工具
   * - 构建缓存
     - 将构建产物发布到制品仓库（Artifactory），供下游依赖复用，避免重复编译
   * - 严格版本控制
     - ``lal verify`` 强制检查所有依赖是否在相同环境中构建、使用相同的版本
   * - 清单驱动
     - 使用 manifest 文件声明版本，自动生成 lockfile
   * - Docker 透明
     - 构建完全在 Docker 容器中进行，命令可见，环境可复现
   * - 灵活脚本
     - ``lal shell`` 和 ``lal script`` 提供便捷的容器内交互方式


工作原理
==============

.. code-block:: text

   ┌─────────────────────────────────────────────────────┐
   │                  开发者机器                           │
   │                                                     │
   │  manifest.json ─► lal fetch ─► 下载依赖              │
   │                    lal verify ─► 检查版本一致性       │
   │                    lal build ──┐                     │
   │                                │                     │
   │  ┌─────────────────────────────▼───────────────────┐ │
   │  │           Docker 容器 (构建环境)                  │ │
   │  │                                                 │ │
   │  │  ./BUILD 脚本                                    │ │
   │  │  ├── cmake / make / autotools                   │ │
   │  │  ├── cargo / go build                           │ │
   │  │  └── 生成构建产物                                │ │
   │  └─────────────────────────────────────────────────┘ │
   │                                                     │
   │  构建产物 ─► lal publish ─► Artifactory 制品仓库     │
   └─────────────────────────────────────────────────────┘


安装
==============

前置条件：

- Docker（v1.12+）
- Docker Registry 或 Artifactory 访问权限

.. code-block:: bash

   # 从源码构建（需要 Rust 工具链）
   git clone https://github.com/cisco/lal-build-manager.git
   cd lal-build-manager
   cargo build --release

   # 或者使用预编译的二进制文件
   # 参见 GitHub Releases 页面


基本用法
==============

项目初始化
--------------------------

一个 LAL 项目需要以下文件：

- ``manifest.json``：声明依赖及其版本
- ``BUILD``：构建脚本（可执行）
- ``.lal/config``：LAL 配置（构建环境、制品仓库等）

依赖管理
--------------------------

.. code-block:: bash

   # 获取依赖
   lal fetch

   # 验证依赖一致性
   lal verify

   # 查看依赖树
   lal status

构建
--------------------------

.. code-block:: bash

   # 在 Docker 容器中执行 BUILD 脚本
   lal build

   # 进入构建环境的交互式 Shell
   lal shell

   # 在构建环境中执行指定脚本
   lal script ./test.sh

发布
--------------------------

.. code-block:: bash

   # 将构建产物发布到制品仓库
   lal publish


manifest.json 示例
==============

.. code-block:: json

   {
     "name": "my-webrtc-lib",
     "version": "1.0.0",
     "environment": "ubuntu1804-gcc7",
     "dependencies": {
       "opus": "1.3.1",
       "openssl": "1.1.1",
       "srtp": "2.3.0"
     }
   }


WebRTC 相关应用场景
==========================

LAL 的设计理念特别适合 WebRTC C/C++ 项目的构建管理：

编译原生依赖
--------------------------

WebRTC 项目通常依赖多个 C/C++ 库：

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 库
     - 说明
   * - libopus
     - Opus 音频编解码器
   * - libopenh264
     - H.264 视频编解码器
   * - libsrtp
     - SRTP 加密传输
   * - openssl / boringssl
     - TLS/DTLS 加密
   * - libnice
     - ICE / STUN / TURN
   * - usrsctp
     - SCTP（DataChannel）

这些库版本之间可能存在兼容性问题，LAL 的严格版本验证机制可以在构建前发现不一致。

可复现的构建环境
--------------------------

WebRTC 的编译对工具链版本敏感（GCC/Clang 版本、系统库版本等）。
LAL 通过 Docker 容器提供完全一致的构建环境，消除"在我机器上能编译"的问题。

构建缓存加速
--------------------------

完整编译 libwebrtc 可能需要数十分钟甚至数小时。
LAL 的构建缓存机制可以将中间产物发布到 Artifactory，下游项目直接复用，大幅缩短 CI/CD 时间。


类似工具对比
==============

.. list-table::
   :header-rows: 1
   :widths: 20 20 60

   * - 工具
     - 语言
     - 特点
   * - LAL
     - Rust
     - Docker 构建环境 + 严格版本 + 构建缓存，已停止维护
   * - Bazel
     - Java
     - Google 出品，WebRTC (libwebrtc) 的官方构建系统之一
   * - GN + Ninja
     - C++
     - Chromium / libwebrtc 的实际构建系统
   * - CMake
     - C++
     - 最广泛使用的 C++ 构建系统
   * - Conan
     - Python
     - C/C++ 包管理器，与 CMake 集成好
   * - vcpkg
     - C++
     - Microsoft 出品的 C/C++ 包管理器


参考
==============

- LAL 源码: https://github.com/cisco/lal-build-manager
- LAL API 文档: https://cisco.github.io/lal-build-manager/lal/
- Cisco Code Exchange: https://developer.cisco.com/codeexchange/github/repo/cisco/lal-build-manager
