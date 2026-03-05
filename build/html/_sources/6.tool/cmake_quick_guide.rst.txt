
####################
CMake Quick Guide
####################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** CMake Quick Guide
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
====================

CMake 是一个跨平台的构建系统生成器，通过 ``CMakeLists.txt`` 文件描述项目的构建规则，
然后生成对应平台的原生构建文件 (如 Makefile、Visual Studio 工程、Ninja 文件等)。
虽然 WebRTC 本身使用 GN + Ninja 构建，但许多基于 WebRTC 的应用项目使用 CMake。


基本语法
====================

CMake 使用命令式语法，命令不区分大小写 (但惯例小写)，参数用空格或分号分隔。

.. code-block:: cmake

   # 设置最低 CMake 版本
   cmake_minimum_required(VERSION 3.16)

   # 定义项目名称和语言
   project(MyWebRTCApp VERSION 1.0 LANGUAGES CXX)

   # 设置 C++ 标准
   set(CMAKE_CXX_STANDARD 17)
   set(CMAKE_CXX_STANDARD_REQUIRED ON)

   # 定义变量
   set(SRC_DIR ${CMAKE_SOURCE_DIR}/src)

   # 条件判断
   if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
     message(STATUS "Building on Linux")
   elseif(APPLE)
     message(STATUS "Building on macOS")
   endif()

   # 循环
   foreach(src main.cpp peer.cpp signaling.cpp)
     message(STATUS "Source: ${src}")
   endforeach()


CMakeLists.txt 结构
========================

一个典型的 CMakeLists.txt 包含以下部分：

.. code-block:: cmake

   # 1. 项目声明
   cmake_minimum_required(VERSION 3.16)
   project(WebRTCDemo LANGUAGES CXX)

   # 2. 选项和配置
   option(USE_H264 "Enable H.264 support" ON)
   option(BUILD_TESTS "Build unit tests" OFF)

   # 3. 查找依赖
   find_package(PkgConfig REQUIRED)
   pkg_check_modules(WEBRTC REQUIRED libwebrtc)
   find_package(OpenSSL REQUIRED)

   # 4. 添加源文件
   set(SOURCES
     src/main.cpp
     src/peer_connection.cpp
     src/signaling_client.cpp
     src/video_capturer.cpp
   )

   # 5. 定义目标
   add_executable(webrtc_demo ${SOURCES})

   # 6. 设置头文件路径
   target_include_directories(webrtc_demo PRIVATE
     ${CMAKE_SOURCE_DIR}/include
     ${WEBRTC_INCLUDE_DIRS}
   )

   # 7. 链接库
   target_link_libraries(webrtc_demo PRIVATE
     ${WEBRTC_LIBRARIES}
     OpenSSL::SSL
     OpenSSL::Crypto
     pthread
   )

   # 8. 编译选项
   target_compile_definitions(webrtc_demo PRIVATE
     WEBRTC_POSIX
     WEBRTC_LINUX
   )


常用命令
====================

目标定义
-----------

.. code-block:: cmake

   # 可执行文件
   add_executable(app main.cpp)

   # 静态库
   add_library(mylib STATIC lib.cpp)

   # 动态库
   add_library(mylib SHARED lib.cpp)

   # 头文件库 (header-only)
   add_library(mylib INTERFACE)

依赖管理
-----------

.. code-block:: cmake

   # 查找系统安装的库
   find_package(Threads REQUIRED)

   # 使用 pkg-config
   find_package(PkgConfig REQUIRED)
   pkg_check_modules(OPUS REQUIRED opus)

   # 使用 FetchContent 下载依赖
   include(FetchContent)
   FetchContent_Declare(json
     GIT_REPOSITORY https://github.com/nlohmann/json.git
     GIT_TAG v3.11.2
   )
   FetchContent_MakeAvailable(json)

安装规则
-----------

.. code-block:: cmake

   install(TARGETS webrtc_demo DESTINATION bin)
   install(FILES include/api.h DESTINATION include)


WebRTC 相关构建示例
========================

以下是一个链接 WebRTC 静态库的完整示例：

.. code-block:: cmake

   cmake_minimum_required(VERSION 3.16)
   project(WebRTCApp LANGUAGES CXX)

   set(CMAKE_CXX_STANDARD 17)

   # WebRTC 源码路径
   set(WEBRTC_SRC_DIR "/path/to/webrtc/src" CACHE PATH "WebRTC source")
   set(WEBRTC_BUILD_DIR "${WEBRTC_SRC_DIR}/out/Release" CACHE PATH "WebRTC build")

   add_executable(webrtc_app
     src/main.cpp
     src/conductor.cpp
     src/peer_connection_client.cpp
   )

   target_include_directories(webrtc_app PRIVATE
     ${WEBRTC_SRC_DIR}
     ${WEBRTC_SRC_DIR}/third_party/abseil-cpp
     ${WEBRTC_SRC_DIR}/third_party/libyuv/include
   )

   # WebRTC 编译宏定义
   target_compile_definitions(webrtc_app PRIVATE
     WEBRTC_POSIX
     WEBRTC_LINUX
     NDEBUG
   )

   # 链接 WebRTC 静态库和系统依赖
   target_link_libraries(webrtc_app PRIVATE
     ${WEBRTC_BUILD_DIR}/obj/libwebrtc.a
     dl pthread rt
     X11 Xext Xdamage Xfixes Xcomposite Xrandr
   )

构建和运行：

.. code-block:: bash

   mkdir build && cd build
   cmake .. -DWEBRTC_SRC_DIR=/path/to/webrtc/src
   cmake --build . -j$(nproc)
   ./webrtc_app


参考资料
====================
* CMake 官方文档: https://cmake.org/cmake/help/latest/
* CMake Tutorial: https://cmake.org/cmake/help/latest/guide/tutorial/
* WebRTC 构建系统: https://gn.googlesource.com/gn/
