###################
SRS
###################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Simple Realtime Server
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents:: Contents
   :local:

概述
====================

SRS（Simple Realtime Server，简单实时服务器）是一个高性能的开源实时流媒体服务器，由国内开发者 Winlin 创建并维护。SRS 支持多种流媒体协议，包括 RTMP、HLS、HTTP-FLV、WebRTC、SRT、GB28181 等，是国内使用最广泛的开源流媒体服务器之一。

SRS 的设计目标是 **简单高效**：采用单进程、协程（Coroutine）架构，基于 State-Threads（ST）库实现高并发，避免了多线程编程的复杂性。

支持协议
--------------------

SRS 支持的主要流媒体协议如下：

.. list-table::
   :header-rows: 1
   :widths: 15 20 15 50

   * - 协议
     - 传输方式
     - 典型延迟
     - 说明
   * - RTMP
     - TCP
     - 1-3 秒
     - 最经典的直播推流协议，兼容 OBS、FFmpeg 等主流推流工具
   * - HLS
     - HTTP
     - 5-10 秒
     - Apple 提出的流媒体协议，兼容所有浏览器和移动设备
   * - HTTP-FLV
     - HTTP
     - 1-3 秒
     - 基于 HTTP 长连接的 FLV 直播流，延迟低于 HLS
   * - WebRTC
     - UDP (DTLS/SRTP)
     - 200-500 毫秒
     - 支持 WHIP 推流和 WHEP 拉流，实现超低延迟直播
   * - SRT
     - UDP
     - 0.5-2 秒
     - Secure Reliable Transport，适用于不稳定网络环境下的推流
   * - GB28181
     - UDP/TCP (SIP+RTP)
     - 1-3 秒
     - 国标安防监控协议，用于接入 IPC 摄像头
   * - MPEG-DASH
     - HTTP
     - 5-10 秒
     - 国际标准自适应码率流媒体协议

**SRS 主要特性**:

* **RTMP**: 完整的 RTMP 推流和拉流支持，兼容 OBS、FFmpeg 等主流推流工具
* **HLS**: 支持 HLS 直播和点播，兼容所有浏览器和移动设备
* **HTTP-FLV**: 基于 HTTP 的 FLV 直播流，延迟低于 HLS
* **WebRTC**: 支持 WebRTC 推流（WHIP）和拉流（WHEP），实现超低延迟直播
* **SRT**: 支持 SRT（Secure Reliable Transport）协议，适用于不稳定网络环境
* **GB28181**: 支持国标 GB28181 协议，用于安防监控场景
* **HTTP API**: 提供丰富的 HTTP API 用于管理和监控
* **HTTP Callback**: 支持 HTTP 回调（Hooks），用于业务集成
* **录制**: 支持 FLV 和 HLS 录制
* **转码**: 支持通过 FFmpeg 进行转码
* **集群**: 支持 Origin-Edge 集群架构

设计哲学
--------------------

SRS 的设计哲学可以概括为以下几点：

1. **简单 (Simple)**: 单进程架构，避免多线程的复杂性。配置文件简洁直观，类似 Nginx 风格。
2. **高效 (Efficient)**: 基于 State-Threads 协程库，单进程即可处理数千并发连接，CPU 和内存利用率高。
3. **实用 (Practical)**: 专注于直播场景的核心需求，提供开箱即用的功能，而非追求大而全。
4. **开放 (Open)**: 完全开源（MIT 协议），提供丰富的 HTTP API 和 Callback 机制，方便与业务系统集成。
5. **协议网关 (Protocol Gateway)**: SRS 的核心价值之一是作为协议转换网关，将不同协议的流互相转换。


架构设计
====================

SRS 采用单进程、协程架构，基于 State-Threads（ST）库实现高并发：

.. code-block:: text

   ┌─────────────────────────────────────────────────────────┐
   │                    SRS Process                           │
   │                                                         │
   │  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
   │  │  RTMP     │  │  HTTP    │  │  WebRTC  │  ...        │
   │  │  Listener │  │  Listener│  │  Listener│             │
   │  └────┬─────┘  └────┬─────┘  └────┬─────┘             │
   │       │              │              │                    │
   │  ┌────┴──────────────┴──────────────┴─────┐            │
   │  │         State-Threads (Coroutine)       │            │
   │  │                                         │            │
   │  │  ┌─────────┐  ┌─────────┐  ┌────────┐ │            │
   │  │  │ Source   │  │ Source   │  │ Source  │ │            │
   │  │  │ (流 A)   │  │ (流 B)   │  │ (流 C)  │ │            │
   │  │  └─────────┘  └─────────┘  └────────┘ │            │
   │  └────────────────────────────────────────┘            │
   └─────────────────────────────────────────────────────────┘

单进程多协程 (State Threads)
---------------------------------

**State-Threads 协程模型**:

State-Threads（简称 ST）是一个轻量级的 C 语言协程库，最初由 Netscape 开发，后来被 SRS 采用并改进。
它的核心思想是：用同步的编程方式实现异步的 I/O 性能。

* 每个连接由一个协程（Coroutine）处理
* 协程在 I/O 等待时自动让出 CPU，无需显式的异步回调
* 编程模型类似同步阻塞，但实际是非阻塞的
* 单线程避免了锁竞争，简化了并发编程
* 性能优异：单进程可处理数千并发连接

.. code-block:: text

   传统多线程模型:
   ┌──────────┐  ┌──────────┐  ┌──────────┐
   │ Thread 1 │  │ Thread 2 │  │ Thread 3 │  ... (线程切换开销大, 需要锁)
   │ Conn A   │  │ Conn B   │  │ Conn C   │
   └──────────┘  └──────────┘  └──────────┘

   异步回调模型 (如 Node.js):
   ┌─────────────────────────────────────────┐
   │ Event Loop                               │
   │  callback(A) → callback(B) → callback(C) │  (回调地狱, 代码难维护)
   └─────────────────────────────────────────┘

   State-Threads 协程模型 (SRS):
   ┌─────────────────────────────────────────┐
   │ Single Thread                            │
   │  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
   │  │Coroutine│ │Coroutine│ │Coroutine│   │  (同步写法, 异步性能)
   │  │ Conn A  │ │ Conn B  │ │ Conn C  │   │  (无锁, 无线程切换)
   │  └─────────┘ └─────────┘ └─────────┘   │
   └─────────────────────────────────────────┘

高性能原理
---------------------------------

SRS 的高性能来源于以下几个方面：

1. **零拷贝转发**: SRS 在转发媒体数据时，尽量避免内存拷贝，直接将接收到的数据包转发给消费者。
2. **协程调度**: ST 协程的切换开销远小于线程切换（微秒级 vs 毫秒级），且不需要锁。
3. **GOP 缓存**: 缓存最近一个 GOP（Group of Pictures），新观众加入时可以立即看到画面，无需等待下一个关键帧。
4. **合并写入**: 对于 HLS 等需要写文件的场景，SRS 会合并多个小写入为一次大写入，减少磁盘 I/O。
5. **内存池**: 使用内存池管理媒体数据的内存分配，减少 malloc/free 的开销。

模块化设计
---------------------------------

SRS 的代码结构采用模块化设计：

**核心概念**:

* **Source**: 代表一个流（Stream），是 SRS 中的核心数据结构。每个推流地址对应一个 Source。
* **Consumer**: 代表一个拉流客户端。一个 Source 可以有多个 Consumer。
* **Publish**: 推流操作，将媒体数据写入 Source。
* **Play**: 拉流操作，从 Source 读取媒体数据。
* **Encoder**: 编码器模块，负责 HLS 切片、DVR 录制等。
* **Forwarder**: 转发器模块，负责将流转发到其他服务器。

.. code-block:: text

   SRS 模块架构:

   ┌─────────────────────────────────────────────────────┐
   │                   应用层 (App Layer)                  │
   │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐    │
   │  │ RTMP │ │ HTTP │ │ RTC  │ │ SRT  │ │GB28181│    │
   │  │Server│ │Server│ │Server│ │Server│ │Server │    │
   │  └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └──┬────┘    │
   │     │        │        │        │        │          │
   │  ┌──┴────────┴────────┴────────┴────────┴──┐       │
   │  │            Source Manager                │       │
   │  │  ┌────────┐  ┌────────┐  ┌────────┐    │       │
   │  │  │Source A│  │Source B│  │Source C│    │       │
   │  │  │Consumer│  │Consumer│  │Consumer│    │       │
   │  │  │Encoder │  │Encoder │  │Encoder │    │       │
   │  │  └────────┘  └────────┘  └────────┘    │       │
   │  └─────────────────────────────────────────┘       │
   │                                                     │
   │  ┌─────────────────────────────────────────┐       │
   │  │         State-Threads Runtime            │       │
   │  └─────────────────────────────────────────┘       │
   │                                                     │
   │  ┌─────────────────────────────────────────┐       │
   │  │         OS (epoll/kqueue)                │       │
   │  └─────────────────────────────────────────┘       │
   └─────────────────────────────────────────────────────┘


安装
====================

Docker 安装（推荐）
--------------------------

Docker 是最简单的安装方式：

.. code-block:: bash

   # 拉取并运行 SRS
   docker run --rm -it \
     -p 1935:1935 \
     -p 1985:1985 \
     -p 8080:8080 \
     -p 8000:8000/udp \
     registry.cn-hangzhou.aliyuncs.com/ossrs/srs:5 \
     ./objs/srs -c conf/docker.conf

   # 端口说明:
   # 1935: RTMP
   # 1985: HTTP API
   # 8080: HTTP Server (HLS/HTTP-FLV/WebRTC HTML)
   # 8000: WebRTC UDP (RTC media)

**Docker Compose 部署**:

.. code-block:: yaml

   # docker-compose.yml
   version: '3.8'

   services:
     srs:
       image: registry.cn-hangzhou.aliyuncs.com/ossrs/srs:5
       container_name: srs
       restart: unless-stopped
       ports:
         - "1935:1935"      # RTMP
         - "1985:1985"      # HTTP API
         - "8080:8080"      # HTTP Server
         - "8000:8000/udp"  # WebRTC
       volumes:
         - ./conf/srs.conf:/usr/local/srs/conf/srs.conf
         - ./objs:/usr/local/srs/objs
       environment:
         - CANDIDATE=your_public_ip
       command: ./objs/srs -c conf/srs.conf

源码编译安装
--------------------------

.. code-block:: bash

   git clone -b develop https://gitee.com/ossrs/srs.git
   cd srs/trunk/
   sudo apt install -y unzip tclsh pkg-config
   ./configure
   make

**编译选项说明**:

.. code-block:: bash

   # 查看所有编译选项
   ./configure --help

   # 启用 WebRTC 支持 (SRS 5.0 默认启用)
   ./configure --rtc=on

   # 启用 SRT 支持
   ./configure --srt=on

   # 启用 GB28181 支持
   ./configure --gb28181=on

   # 启用 FFmpeg 转码支持
   ./configure --ffmpeg-tool=on

   # 完整编译 (启用所有功能)
   ./configure --rtc=on --srt=on --gb28181=on --ffmpeg-tool=on
   make

各平台注意事项
--------------------------

**Ubuntu/Debian**:

.. code-block:: bash

   # 安装依赖
   sudo apt-get update
   sudo apt-get install -y git gcc g++ make unzip tclsh pkg-config

   # 如果需要 SRT 支持
   sudo apt-get install -y libssl-dev

**CentOS/RHEL**:

.. code-block:: bash

   # 安装依赖
   sudo yum install -y git gcc gcc-c++ make unzip tcl pkg-config

   # CentOS 7 需要升级 GCC (SRS 5.0 需要 C++14)
   sudo yum install -y centos-release-scl
   sudo yum install -y devtoolset-9
   scl enable devtoolset-9 bash

**macOS**:

.. code-block:: bash

   # 安装 Xcode Command Line Tools
   xcode-select --install

   # 使用 Homebrew 安装依赖
   brew install pkg-config openssl

   # 编译
   ./configure
   make

**启动和验证**:

.. code-block:: bash

   # 启动 SRS
   ./objs/srs -c conf/srs.conf

   # 查看 SRS 的状态
   ./etc/init.d/srs status

   # 或者看 SRS 的日志
   tail -n 30 -f ./objs/srs.log

   # 检查 HTTP API
   curl http://localhost:1985/api/v1/versions

   # 检查进程
   ps aux | grep srs


核心功能
====================

RTMP 推流/拉流配置
--------------------------

RTMP 是 SRS 最基础的协议支持，配置简单：

.. code-block:: nginx

   # conf/rtmp.conf
   listen              1935;
   max_connections     1000;
   daemon              off;
   srs_log_tank        console;

   vhost __defaultVhost__ {
       # RTMP 推流配置
       chunk_size      60000;
       in_ack_size     0;

       # GOP 缓存（减少首帧延迟）
       play {
           gop_cache       on;
           queue_length    10;
           mw_latency      100;
       }

       # 推流鉴权
       publish {
           mr          off;
       }
   }

**推流和拉流测试**:

.. code-block:: bash

   # 使用 FFmpeg 推流
   ffmpeg -re -i input.mp4 -c copy -f flv rtmp://localhost/live/stream1

   # 使用 OBS 推流
   # 服务器: rtmp://your-server-ip/live
   # 串流密钥: stream1

   # 使用 FFplay 拉流
   ffplay rtmp://localhost/live/stream1

   # 使用 VLC 拉流
   # 打开网络串流: rtmp://localhost/live/stream1

HLS 直播配置
--------------------------

HLS（HTTP Live Streaming）是兼容性最好的直播协议，所有浏览器和移动设备都支持：

.. code-block:: nginx

   vhost __defaultVhost__ {
       hls {
           enabled         on;
           hls_fragment    2;      # 每个 TS 分片时长（秒），越小延迟越低
           hls_window      10;     # HLS 窗口时长（秒），即 m3u8 中包含的分片总时长
           hls_path        ./objs/nginx/html;
           hls_m3u8_file   [app]/[stream].m3u8;
           hls_ts_file     [app]/[stream]-[seq].ts;
           hls_cleanup     on;     # 自动清理过期的 TS 文件
           hls_dispose     30;     # 无人观看时，多少秒后停止生成 HLS
           hls_wait_keyframe   on; # 每个 TS 分片以关键帧开头
       }
   }

**TS 切片参数调优**:

.. list-table::
   :header-rows: 1
   :widths: 25 25 50

   * - 参数
     - 推荐值
     - 说明
   * - hls_fragment
     - 2-5 秒
     - 越小延迟越低，但兼容性可能下降。iOS 建议 >= 2 秒
   * - hls_window
     - 10-30 秒
     - 播放列表中保留的总时长。太短可能导致播放卡顿
   * - hls_wait_keyframe
     - on
     - 确保每个 TS 分片以关键帧开头，避免花屏
   * - hls_cleanup
     - on
     - 自动清理过期 TS 文件，避免磁盘空间耗尽

**HLS 播放地址**: ``http://localhost:8080/live/stream1.m3u8``

HTTP-FLV 低延迟
--------------------------

HTTP-FLV 基于 HTTP 长连接传输 FLV 格式的直播流，延迟介于 RTMP 和 HLS 之间，
且不需要 Flash 插件：

.. code-block:: nginx

   vhost __defaultVhost__ {
       http_remux {
           enabled     on;
           mount       [vhost]/[app]/[stream].flv;
       }
   }

**HTTP-FLV 播放地址**: ``http://localhost:8080/live/stream1.flv``

**前端播放 HTTP-FLV**:

.. code-block:: html

   <!-- 使用 flv.js 播放 HTTP-FLV -->
   <script src="https://cdn.jsdelivr.net/npm/flv.js/dist/flv.min.js"></script>
   <video id="videoElement" controls autoplay></video>
   <script>
       if (flvjs.isSupported()) {
           const player = flvjs.createPlayer({
               type: 'flv',
               url: 'http://localhost:8080/live/stream1.flv'
           });
           player.attachMediaElement(document.getElementById('videoElement'));
           player.load();
           player.play();
       }
   </script>

WebRTC 推拉流 (WHIP/WHEP)
---------------------------------

SRS 从 v4 版本开始支持 WebRTC，v5 版本全面支持 WHIP/WHEP 标准协议：

.. code-block:: nginx

   # conf/rtc.conf
   listen              1935;
   max_connections     1000;
   daemon              off;
   srs_log_tank        console;

   http_server {
       enabled         on;
       listen          8080;
       dir             ./objs/nginx/html;
   }

   http_api {
       enabled         on;
       listen          1985;
   }

   rtc_server {
       enabled         on;
       listen          8000;  # UDP 端口
       # candidate 是 SRS 的公网 IP，客户端通过此 IP 连接
       candidate       $CANDIDATE;
   }

   vhost __defaultVhost__ {
       rtc {
           enabled     on;
           # 允许 RTC 到 RTMP 的转换
           rtmp_to_rtc on;
           rtc_to_rtmp on;
       }
       http_remux {
           enabled     on;
           mount       [vhost]/[app]/[stream].flv;
       }
       hls {
           enabled     on;
       }
   }

**RTC 配置参数详解**:

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - 参数
     - 默认值
     - 说明
   * - rtc.enabled
     - off
     - 是否启用 WebRTC 功能
   * - rtc.rtmp_to_rtc
     - off
     - 是否将 RTMP 流自动转换为 WebRTC 流
   * - rtc.rtc_to_rtmp
     - off
     - 是否将 WebRTC 流自动转换为 RTMP 流
   * - rtc.stun_timeout
     - 30
     - STUN 超时时间（秒）
   * - rtc.stun_strict_check
     - off
     - 是否严格检查 STUN 包
   * - rtc_server.candidate
     - \*
     - SRS 的公网 IP 地址，客户端通过此 IP 建立 WebRTC 连接
   * - rtc_server.listen
     - 8000
     - WebRTC UDP 监听端口

SRT 支持
--------------------------

SRT（Secure Reliable Transport）是 Haivision 开源的低延迟传输协议，特别适合在不稳定网络
（如公网、卫星链路）上进行实时视频传输：

.. code-block:: nginx

   # conf/srt.conf
   srt_server {
       enabled     on;
       listen      10080;
       maxbw       1000000000;
       connect_timeout     4000;
       peerlatency         0;
       recvlatency         120;  # 接收延迟（毫秒）
   }

   vhost __defaultVhost__ {
       srt {
           enabled     on;
           srt_to_rtmp on;  # SRT 流自动转换为 RTMP
       }
   }

**SRT 推流**:

.. code-block:: bash

   # 使用 FFmpeg 通过 SRT 推流
   ffmpeg -re -i input.mp4 -c copy -f mpegts \
     'srt://localhost:10080?streamid=#!::r=live/stream1,m=publish'

录制 DVR
--------------------------

SRS 支持将直播流录制为文件，用于回放和存档：

.. code-block:: nginx

   vhost __defaultVhost__ {
       dvr {
           enabled         on;
           dvr_path        ./objs/nginx/html/[app]/[stream].[timestamp].flv;
           dvr_plan        session;  # session: 整个推流录制为一个文件
                                     # segment: 按时间分段录制
           dvr_duration    30;       # segment 模式下每个文件的时长（秒）
           dvr_wait_keyframe   on;   # 每个录制文件以关键帧开头
       }
   }

转码 FFmpeg 集成
--------------------------

SRS 支持通过 FFmpeg 对直播流进行转码，例如调整分辨率、码率、编码格式等：

.. code-block:: nginx

   vhost __defaultVhost__ {
       transcode {
           enabled     on;
           ffmpeg      ./objs/ffmpeg/bin/ffmpeg;

           engine sd {
               enabled         on;
               vfilter {
               }
               vcodec          libx264;
               vbitrate        500;
               vfps            25;
               vwidth          640;
               vheight         360;
               vthreads        2;
               vprofile        baseline;
               vpreset         superfast;
               acodec          libfdk_aac;
               abitrate        64;
               asample_rate    44100;
               achannels       2;
               output          rtmp://127.0.0.1:[port]/[app]?vhost=[vhost]/[stream]_sd;
           }
       }
   }

转码后会生成一个新的流，例如原始流为 ``live/stream1``，转码后的流为 ``live/stream1_sd``。


WebRTC 集成
====================

SRS 的 WebRTC 集成是其最重要的特性之一，使得 SRS 可以作为 WebRTC 与传统直播协议之间的桥梁。

SRS WebRTC 架构
--------------------------

.. code-block:: text

   ┌─────────────────────────────────────────────────────────────┐
   │                    SRS WebRTC 架构                           │
   ├─────────────────────────────────────────────────────────────┤
   │                                                             │
   │  ┌──────────────┐                    ┌──────────────┐      │
   │  │  WebRTC      │   WHIP (HTTP POST) │              │      │
   │  │  Publisher   │───────────────────>│  HTTP API    │      │
   │  │  (Browser)   │   SDP Offer/Answer │  (Port 1985) │      │
   │  └──────┬───────┘                    └──────┬───────┘      │
   │         │                                    │              │
   │         │  DTLS + SRTP (UDP)                 │              │
   │         │                            ┌───────┴───────┐     │
   │         └───────────────────────────>│  RTC Server   │     │
   │                                      │  (Port 8000)  │     │
   │                                      │               │     │
   │                                      │  ICE-Lite     │     │
   │                                      │  DTLS 1.2     │     │
   │                                      │  SRTP         │     │
   │                                      └───────┬───────┘     │
   │                                              │              │
   │                                      ┌───────┴───────┐     │
   │                                      │    Source      │     │
   │                                      │  (RTP → RTMP) │     │
   │                                      └───────┬───────┘     │
   │                                              │              │
   │                    ┌─────────────────────────┼──────┐      │
   │                    │                         │      │      │
   │              ┌─────┴─────┐  ┌──────────┐  ┌─┴────┐ │      │
   │              │   RTMP    │  │   HLS    │  │ FLV  │ │      │
   │              │  Consumer │  │ Encoder  │  │Remux │ │      │
   │              └───────────┘  └──────────┘  └──────┘ │      │
   │                                                     │      │
   └─────────────────────────────────────────────────────────────┘

WHIP/WHEP 配置
--------------------------

WHIP（WebRTC-HTTP Ingestion Protocol）和 WHEP（WebRTC-HTTP Egress Protocol）是
标准化的 WebRTC 推拉流协议，通过简单的 HTTP POST 请求交换 SDP。

**WHIP 推流流程**:

.. code-block:: text

   Browser/Client                    SRS Server
        |                                |
        |--- HTTP POST /rtc/v1/whip ---->|  (Body: SDP Offer)
        |<-- 201 Created ----------------|  (Body: SDP Answer)
        |                                |
        |=== DTLS Handshake ============>|
        |=== SRTP Media ================>|  (推流)
        |                                |
        |  SRS 将 WebRTC 流转换为 RTMP/HLS/HTTP-FLV

**WHEP 拉流流程**:

.. code-block:: text

   Browser/Client                    SRS Server
        |                                |
        |--- HTTP POST /rtc/v1/whep ---->|  (Body: SDP Offer)
        |<-- 201 Created ----------------|  (Body: SDP Answer)
        |                                |
        |=== DTLS Handshake ============>|
        |<== SRTP Media =================|  (拉流)
        |                                |

RTMP ↔ WebRTC 转换
--------------------------

SRS 的一大优势是支持多种协议之间的自动转换：

.. code-block:: text

   推流端                    SRS                     拉流端
   ┌──────────┐         ┌──────────┐          ┌──────────┐
   │ WebRTC   │──WHIP──>│          │──RTMP───>│ VLC      │
   │ Browser  │         │          │──HLS────>│ Browser  │
   └──────────┘         │   SRS    │──FLV────>│ H5 Player│
                        │          │──WebRTC─>│ Browser  │
   ┌──────────┐         │          │          └──────────┘
   │ OBS/     │──RTMP──>│          │
   │ FFmpeg   │         └──────────┘
   └──────────┘

   支持的转换路径:
   - WebRTC → RTMP → HLS/HTTP-FLV
   - RTMP → WebRTC
   - SRT → RTMP → HLS/HTTP-FLV/WebRTC
   - GB28181 → RTMP → HLS/HTTP-FLV/WebRTC

**转换原理**:

当 ``rtc_to_rtmp`` 开启时，SRS 会将 WebRTC 推流的 RTP 包解封装，提取 H.264/Opus 裸数据，
然后重新封装为 RTMP FLV Tag 写入 Source。其他协议的 Consumer（HLS、HTTP-FLV）从 Source
读取数据时，就可以正常消费了。

反过来，当 ``rtmp_to_rtc`` 开启时，SRS 会将 RTMP 流的 H.264/AAC 数据提取出来，
将 H.264 封装为 RTP 包，将 AAC 转码为 Opus 后封装为 RTP 包，通过 SRTP 发送给 WebRTC 客户端。

.. note::

   RTMP 使用 AAC 音频编码，而 WebRTC 使用 Opus 编码。SRS 内部会自动进行 AAC ↔ Opus 的转码。
   视频编码（H.264）则不需要转码，只需要重新封装。

JavaScript 客户端示例
--------------------------

**WHIP 推流客户端**:

.. code-block:: javascript

   // 使用 WHIP 协议推流到 SRS
   async function publishByWhip(url) {
       const pc = new RTCPeerConnection();

       // 获取本地媒体流
       const stream = await navigator.mediaDevices.getUserMedia({
           video: { width: 1280, height: 720 },
           audio: true
       });
       stream.getTracks().forEach(track => pc.addTrack(track, stream));

       // 显示本地视频
       document.getElementById('localVideo').srcObject = stream;

       // 创建 Offer
       const offer = await pc.createOffer();
       await pc.setLocalDescription(offer);

       // 等待 ICE 收集完成
       await new Promise(resolve => {
           if (pc.iceGatheringState === 'complete') {
               resolve();
           } else {
               pc.addEventListener('icegatheringstatechange', () => {
                   if (pc.iceGatheringState === 'complete') resolve();
               });
           }
       });

       // 通过 HTTP POST 发送 SDP Offer
       const response = await fetch(url, {
           method: 'POST',
           headers: { 'Content-Type': 'application/sdp' },
           body: pc.localDescription.sdp
       });

       if (response.status !== 201) {
           throw new Error(`WHIP 推流失败: ${response.status}`);
       }

       const answerSdp = await response.text();
       await pc.setRemoteDescription({ type: 'answer', sdp: answerSdp });

       console.log('WHIP 推流成功');
       return pc;
   }

   // 使用示例
   const whipUrl = 'http://localhost:1985/rtc/v1/whip/?app=live&stream=livestream';
   publishByWhip(whipUrl);

**WHEP 拉流客户端**:

.. code-block:: javascript

   // 使用 WHEP 协议从 SRS 拉流
   async function playByWhep(url) {
       const pc = new RTCPeerConnection();

       pc.addTransceiver('video', { direction: 'recvonly' });
       pc.addTransceiver('audio', { direction: 'recvonly' });

       const offer = await pc.createOffer();
       await pc.setLocalDescription(offer);

       // 等待 ICE 收集完成
       await new Promise(resolve => {
           if (pc.iceGatheringState === 'complete') {
               resolve();
           } else {
               pc.addEventListener('icegatheringstatechange', () => {
                   if (pc.iceGatheringState === 'complete') resolve();
               });
           }
       });

       const response = await fetch(url, {
           method: 'POST',
           headers: { 'Content-Type': 'application/sdp' },
           body: pc.localDescription.sdp
       });

       if (response.status !== 201) {
           throw new Error(`WHEP 拉流失败: ${response.status}`);
       }

       const answerSdp = await response.text();
       await pc.setRemoteDescription({ type: 'answer', sdp: answerSdp });

       pc.ontrack = (event) => {
           console.log('收到远端轨道:', event.track.kind);
           document.getElementById('remoteVideo').srcObject = event.streams[0];
       };

       console.log('WHEP 拉流成功');
       return pc;
   }

   // 使用示例
   const whepUrl = 'http://localhost:1985/rtc/v1/whep/?app=live&stream=livestream';
   playByWhep(whepUrl);

SDP 交换（HTTP API 方式）
-------------------------------

除了 WHIP/WHEP，SRS 还支持通过 HTTP API 进行 SDP 交换：

.. code-block:: bash

   # WebRTC 推流
   curl -X POST http://srs.example.com:1985/rtc/v1/publish/ \
     -H 'Content-Type: application/json' \
     -d '{
       "api": "http://srs.example.com:1985/rtc/v1/publish/",
       "streamurl": "webrtc://srs.example.com/live/livestream",
       "sdp": "v=0\r\n..."
     }'

   # WebRTC 拉流
   curl -X POST http://srs.example.com:1985/rtc/v1/play/ \
     -H 'Content-Type: application/json' \
     -d '{
       "api": "http://srs.example.com:1985/rtc/v1/play/",
       "streamurl": "webrtc://srs.example.com/live/livestream",
       "sdp": "v=0\r\n..."
     }'

DTLS/SRTP 处理
--------------------------

SRS 内部实现了完整的 DTLS 握手和 SRTP 加密/解密：

* **DTLS**: 使用 OpenSSL 实现 DTLS 1.2 握手，建立安全通道
* **SRTP**: 使用 libsrtp 进行 RTP/RTCP 包的加密和解密
* **ICE**: 实现了 ICE-Lite 模式，简化了 ICE 连通性检查
* **STUN**: 处理 STUN Binding Request/Response

.. note::

   SRS 使用 ICE-Lite 模式，即 SRS 不主动发起连通性检查，只响应客户端的检查请求。
   这简化了服务端实现，但要求客户端必须是 Full ICE Agent（浏览器默认就是）。


集群部署
====================

Origin-Edge 架构
--------------------------

SRS 支持 Origin-Edge 集群架构，用于大规模直播分发：

.. code-block:: text

   推流端 ──RTMP──> Origin Server ──RTMP──> Edge Server 1 ──> 观众
                                   ──RTMP──> Edge Server 2 ──> 观众
                                   ──RTMP──> Edge Server 3 ──> 观众

   工作原理:
   1. 推流端将流推送到 Origin 服务器
   2. Edge 服务器在有观众请求时，自动从 Origin 拉流
   3. 同一个 Edge 上的多个观众共享一路从 Origin 拉取的流
   4. 无观众时 Edge 自动断开与 Origin 的连接

**Origin 配置**:

.. code-block:: nginx

   # origin.conf
   listen 1935;
   max_connections 1000;
   daemon off;
   srs_log_tank console;

   http_api {
       enabled on;
       listen 1985;
   }

   vhost __defaultVhost__ {
   }

**Edge 配置**:

.. code-block:: nginx

   # edge.conf
   listen 1935;
   max_connections 1000;
   daemon off;
   srs_log_tank console;

   http_api {
       enabled on;
       listen 1985;
   }

   vhost __defaultVhost__ {
       cluster {
           mode        remote;
           origin      192.168.1.100:1935;  # Origin 服务器地址
       }
   }

负载均衡
--------------------------

在 Edge 集群前面可以部署负载均衡器，将观众请求分发到不同的 Edge 服务器：

.. code-block:: text

   观众 ──> Load Balancer (Nginx/HAProxy) ──> Edge 1
                                           ──> Edge 2
                                           ──> Edge 3

**Nginx 负载均衡配置示例**:

.. code-block:: nginx

   # nginx.conf
   upstream srs_edges {
       server 192.168.1.101:1935;
       server 192.168.1.102:1935;
       server 192.168.1.103:1935;
   }

   server {
       listen 1935;
       proxy_pass srs_edges;
   }

   # HTTP-FLV 负载均衡
   upstream srs_http_edges {
       server 192.168.1.101:8080;
       server 192.168.1.102:8080;
       server 192.168.1.103:8080;
   }

   server {
       listen 8080;
       location /live/ {
           proxy_pass http://srs_http_edges;
           proxy_http_version 1.1;
           proxy_set_header Connection "";
       }
   }

SRS 还支持更复杂的集群模式，包括：

* **Origin Cluster**: 多个 Origin 服务器组成集群，通过 HTTP API 互相发现流
* **Edge Cluster**: 多个 Edge 服务器从 Origin 拉流，支持负载均衡
* **Forward**: 将流转发到其他 SRS 服务器或第三方 RTMP 服务器


监控与管理
====================

HTTP API
--------------------------

SRS 提供丰富的 HTTP API：

.. code-block:: bash

   # 获取版本信息
   curl http://localhost:1985/api/v1/versions

   # 获取所有流信息
   curl http://localhost:1985/api/v1/streams/

   # 获取所有客户端信息
   curl http://localhost:1985/api/v1/clients/

   # 踢掉指定客户端
   curl -X DELETE http://localhost:1985/api/v1/clients/{id}

   # 获取服务器摘要信息
   curl http://localhost:1985/api/v1/summaries

   # 获取系统资源使用情况
   curl http://localhost:1985/api/v1/rusages

   # 获取自身进程信息
   curl http://localhost:1985/api/v1/self_proc_stats

   # 获取系统进程信息
   curl http://localhost:1985/api/v1/system_proc_stats

**API 返回示例** (``/api/v1/streams``):

.. code-block:: json

   {
       "code": 0,
       "server": "vid-xxx",
       "streams": [
           {
               "id": "vid-xxx",
               "name": "livestream",
               "vhost": "vid-xxx",
               "app": "live",
               "live_ms": 1678901234567,
               "clients": 5,
               "frames": 12345,
               "send_bytes": 67890123,
               "recv_bytes": 12345678,
               "kbps": {
                   "recv_30s": 2048,
                   "send_30s": 10240
               },
               "publish": {
                   "active": true,
                   "cid": "vid-xxx"
               },
               "video": {
                   "codec": "H264",
                   "profile": "High",
                   "level": "3.1",
                   "width": 1280,
                   "height": 720
               },
               "audio": {
                   "codec": "AAC",
                   "sample_rate": 44100,
                   "channel": 2,
                   "profile": "LC"
               }
           }
       ]
   }

Console 管理界面
--------------------------

SRS 提供了一个内置的 Web 管理界面（Console），可以通过浏览器访问：

.. code-block:: text

   访问地址: http://localhost:8080/console/

   功能:
   - 查看服务器状态和版本信息
   - 查看所有活跃的流
   - 查看所有连接的客户端
   - 查看系统资源使用情况
   - 在线播放 RTMP/HLS/HTTP-FLV/WebRTC 流

Prometheus 监控集成
--------------------------

SRS 支持 Prometheus 指标导出，可以与 Grafana 配合实现可视化监控：

.. code-block:: nginx

   # 启用 Exporter
   exporter {
       enabled     on;
       listen      9972;  # Prometheus 抓取端口
   }

**Prometheus 配置**:

.. code-block:: yaml

   # prometheus.yml
   scrape_configs:
     - job_name: 'srs'
       static_configs:
         - targets: ['localhost:9972']
       scrape_interval: 10s

**常用监控指标**:

* ``srs_server_uptime``: 服务器运行时间
* ``srs_server_connections``: 当前连接数
* ``srs_stream_active``: 活跃流数量
* ``srs_stream_bitrate_recv``: 接收码率
* ``srs_stream_bitrate_send``: 发送码率

HTTP Callback（Hooks）
--------------------------

SRS 支持在关键事件发生时回调应用服务器：

.. code-block:: nginx

   vhost __defaultVhost__ {
       http_hooks {
           enabled         on;
           # 客户端连接时回调
           on_connect      http://localhost:8085/api/v1/clients;
           # 推流开始时回调（可用于鉴权）
           on_publish      http://localhost:8085/api/v1/streams;
           # 推流结束时回调
           on_unpublish    http://localhost:8085/api/v1/streams;
           # 拉流开始时回调
           on_play         http://localhost:8085/api/v1/sessions;
           # 拉流结束时回调
           on_stop         http://localhost:8085/api/v1/sessions;
           # HLS 切片生成时回调
           on_hls          http://localhost:8085/api/v1/hls;
       }
   }

**推流鉴权示例**:

.. code-block:: python

   # 应用服务器处理 on_publish 回调
   from flask import Flask, request, jsonify

   app = Flask(__name__)

   @app.route('/api/v1/streams', methods=['POST'])
   def on_publish():
       data = request.json
       stream_url = data.get('stream')
       token = data.get('param', '').replace('?token=', '')

       # 验证 token
       if verify_token(token):
           return jsonify({"code": 0})  # 允许推流
       else:
           return jsonify({"code": 1})  # 拒绝推流

   def verify_token(token):
       # 实现你的 token 验证逻辑
       valid_tokens = ['abc123', 'def456']
       return token in valid_tokens

   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=8085)


性能调优
====================

并发连接优化
--------------------------

.. code-block:: nginx

   # 增加最大连接数
   max_connections     10000;

   # 系统级优化 (Linux)
   # /etc/sysctl.conf
   # net.core.somaxconn = 65535
   # net.ipv4.tcp_max_syn_backlog = 65535
   # fs.file-max = 1000000

   # 进程级优化
   # /etc/security/limits.conf
   # * soft nofile 1000000
   # * hard nofile 1000000

带宽优化
--------------------------

.. code-block:: text

   带宽计算公式:
   总带宽 = 推流带宽 + 拉流带宽
   推流带宽 = 推流数 × 单路码率
   拉流带宽 = 拉流数 × 单路码率

   示例:
   - 1 路 1080p 推流 (4 Mbps) + 100 路拉流
   - 总带宽 = 4 + 100 × 4 = 404 Mbps

   优化策略:
   1. 使用 Edge 集群分担拉流带宽
   2. 使用 HLS + CDN 分发大规模观众
   3. 提供多码率选择 (转码)
   4. 使用 Simulcast (WebRTC 场景)

CPU 优化
--------------------------

.. code-block:: text

   CPU 消耗分析:
   - 纯转发 (RTMP/HTTP-FLV): CPU 消耗极低
   - HLS 切片: 需要写磁盘，有一定 CPU 消耗
   - WebRTC: DTLS/SRTP 加解密消耗较多 CPU
   - 转码: CPU 消耗最高 (FFmpeg)

   优化建议:
   1. 避免不必要的转码，尽量使用转封装
   2. WebRTC 场景使用硬件加速 (如果可用)
   3. 将转码任务分离到独立服务器
   4. 使用 SRS 的多进程模式 (通过多实例 + 负载均衡)

**性能基准参考**:

.. list-table::
   :header-rows: 1
   :widths: 30 20 20 30

   * - 场景
     - 并发数
     - CPU (4核)
     - 内存
   * - RTMP 纯转发
     - 3000+
     - < 30%
     - < 500 MB
   * - HTTP-FLV 转发
     - 3000+
     - < 30%
     - < 500 MB
   * - HLS 切片
     - 1000+
     - < 50%
     - < 1 GB
   * - WebRTC 转发
     - 500+
     - < 60%
     - < 1 GB
   * - RTMP → WebRTC 转换
     - 300+
     - < 70%
     - < 1 GB


常见场景
====================

超低延迟直播
--------------------------

适用于互动直播、在线教育、远程医疗等需要超低延迟的场景。端到端延迟可以控制在 200-500ms。

.. code-block:: text

   主播 (Browser) ──WebRTC WHIP──> SRS ──WebRTC WHEP──> 观众 (Browser)
                                        延迟: 200-500ms

**配置要点**:

.. code-block:: nginx

   rtc_server {
       enabled on;
       listen 8000;
       candidate $CANDIDATE;
   }

   vhost __defaultVhost__ {
       rtc {
           enabled     on;
           rtmp_to_rtc on;
           rtc_to_rtmp on;
       }
       play {
           gop_cache off;  # 关闭 GOP 缓存以降低延迟
       }
   }

连麦互动
--------------------------

连麦互动是直播中常见的场景，主播和观众可以进行实时音视频互动：

.. code-block:: text

   场景: 主播 A 和观众 B 连麦

   1. 主播 A 通过 WebRTC 推流到 SRS
   2. 观众 B 请求连麦，通过 WebRTC 推流到 SRS
   3. SRS 将两路流分别转发给对方 (WebRTC)
   4. 同时将两路流转换为 RTMP/HLS 供其他观众观看

   主播 A ──WebRTC──> SRS ──WebRTC──> 观众 B (连麦)
   观众 B ──WebRTC──> SRS ──WebRTC──> 主播 A (连麦)
                       │
                       ├──RTMP──> CDN ──HLS──> 普通观众
                       └──HTTP-FLV──> 普通观众

传统直播（RTMP 推流 + HLS/HTTP-FLV 拉流）
----------------------------------------------

适用于大规模直播场景，兼容性好，可以配合 CDN 分发。

.. code-block:: text

   主播 (OBS/FFmpeg) ──RTMP──> SRS ──HLS──────> 观众 (Browser/App)
                                    ──HTTP-FLV──> 观众 (H5 Player)
                                    延迟: HLS 5-10s, HTTP-FLV 1-3s

监控接入 (GB28181)
--------------------------

SRS 支持通过 GB28181 协议接入安防监控摄像头：

.. code-block:: text

   IPC 摄像头 ──GB28181 (SIP+RTP)──> SRS ──RTMP──> 录制/存储
                                          ──HLS──> Web 播放
                                          ──WebRTC──> 实时预览

**GB28181 配置**:

.. code-block:: nginx

   stream_caster {
       enabled     on;
       caster      gb28181;
       output      rtmp://127.0.0.1/live/[stream];
       listen      9000;
       sip {
           enabled     on;
           listen      5060;
           serial      34020000002000000001;
           realm       3402000000;
           ack_timeout     30;
           keepalive_timeout   120;
       }
   }

协议转换网关
--------------------------

SRS 可以作为协议转换网关，将一种协议的流转换为另一种协议：

.. code-block:: text

   WebRTC 推流 → RTMP → CDN 分发 (HLS/HTTP-FLV)
   RTMP 推流 → WebRTC 拉流 (超低延迟观看)
   SRT 推流 → RTMP → HLS/HTTP-FLV/WebRTC
   GB28181 摄像头 → RTMP → HLS/WebRTC (安防监控)


SRS vs 其他服务器
====================

.. list-table::
   :header-rows: 1
   :widths: 18 18 18 18 28

   * - 特性
     - SRS
     - nginx-rtmp
     - Janus
     - mediasoup
   * - 主要协议
     - RTMP/HLS/WebRTC/SRT
     - RTMP/HLS
     - WebRTC
     - WebRTC
   * - 架构
     - 单进程协程
     - 多进程
     - 多线程插件
     - 多 Worker
   * - WebRTC
     - ✓ (WHIP/WHEP)
     - ✗
     - ✓ (完整)
     - ✓ (完整)
   * - SFU 功能
     - 基础（1 对多）
     - ✗
     - ✓ (多对多)
     - ✓ (多对多)
   * - 协议转换
     - ✓ (强项)
     - 有限
     - 有限
     - 需自行实现
   * - 延迟
     - WebRTC < 500ms
     - HLS 5-10s
     - WebRTC < 200ms
     - WebRTC < 200ms
   * - 适用场景
     - 直播/协议转换
     - 传统直播
     - 视频会议
     - 视频会议
   * - 学习曲线
     - 低
     - 低
     - 中
     - 中

**选择建议**:

* **直播场景（1 对多）**: SRS 是最佳选择，支持多协议、协议转换、CDN 集成
* **视频会议（多对多）**: Janus 或 mediasoup 更适合，提供完整的 SFU 功能
* **混合场景**: SRS + mediasoup/Janus 组合使用


Quick Start
=====================

* 编译

.. code-block:: bash

    git clone -b develop https://gitee.com/ossrs/srs.git
    cd srs/trunk/
    sudo apt install -y unzip
    sudo apt install -y tclsh
    ./configure
    make


* 启动

.. code-block:: bash

    ./objs/srs -c conf/srs.conf

    # 查看SRS的状态
    ./etc/init.d/srs status

    # 或者看SRS的日志
    tail -n 30 -f ./objs/srs.log

* 测试推流

.. code-block:: bash

    sudo apt install ffmpeg
    ffmpeg -re -i ./doc/source.flv -c copy -f flv rtmp://localhost/live/livestream


* 用如下地址观察音视频流

    * RTMP (by VLC): ``rtmp://localhost/live/livestream``
    * H5(HTTP-FLV): ``http://localhost:8080/live/livestream.flv``
    * H5(HLS): ``http://localhost:8080/live/livestream.m3u8``
    * WebRTC: ``http://localhost:8080/players/whep.html?autostart=true``


参考文献
====================

* SRS 官方网站

  - https://ossrs.io/

* SRS GitHub 仓库

  - https://github.com/ossrs/srs

* SRS Wiki 文档

  - https://ossrs.io/lts/zh-cn/docs/v5/doc/introduction

* WHIP 协议规范

  - https://datatracker.ietf.org/doc/html/draft-ietf-wish-whip

* WHEP 协议规范

  - https://datatracker.ietf.org/doc/html/draft-murillo-whep

* State-Threads 库

  - http://state-threads.sourceforge.net/

* SRS Docker 镜像

  - https://hub.docker.com/r/ossrs/srs

* SRS 集群部署指南

  - https://ossrs.io/lts/zh-cn/docs/v5/doc/edge

* SRS WebRTC 文档

  - https://ossrs.io/lts/zh-cn/docs/v5/doc/webrtc

* flv.js 播放器

  - https://github.com/bilibili/flv.js

* Prometheus 监控

  - https://prometheus.io/

* Grafana 可视化

  - https://grafana.com/
