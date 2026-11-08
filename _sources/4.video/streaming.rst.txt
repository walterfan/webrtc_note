===============
Streaming
===============

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** 流媒体技术
**Authors**  Walter Fan
**Status**   v1
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
======================

流媒体（Streaming）是一种将音视频数据以连续流的方式传输和播放的技术，
用户无需等待整个文件下载完成即可开始观看或收听。

从技术发展历程来看，流媒体经历了几个重要阶段：

1. **下载后播放**（1990s 早期）：用户必须完全下载文件后才能播放，体验极差
2. **渐进式下载**（Progressive Download）：边下载边播放，但不支持实时直播
3. **RTSP/RTP 流媒体**（2000s）：真正的流式传输，支持点播和直播
4. **HTTP 自适应流**（2010s）：HLS、DASH 等基于 HTTP 的方案，CDN 友好
5. **超低延迟流**（2020s）：WebRTC、LL-HLS、SRT 等，延迟降至亚秒级

流媒体的核心挑战在于：如何在有限的网络带宽下，以尽可能低的延迟，
提供尽可能高的音视频质量。


流媒体需求
======================

一个完善的流媒体系统需要满足以下需求：

1. **边下边放（Streaming Playback）**

   用户不需要等待整个文件下载完成就可以开始播放。
   这要求服务端能够按时间顺序分段发送数据，客户端能够边接收边解码播放。
   关键技术包括分片（Segmentation）和缓冲管理（Buffer Management）。

2. **点播随机访问（Random Access / Seek）**

   用户可以从视频的任意位置开始播放，也可以在播放过程中跳转到任意时间点。
   这要求视频有合理的关键帧间隔（GOP），服务端支持基于时间的定位（Range Request 或 RTSP PLAY）。

3. **直播实时观看（Live Streaming）**

   用户可以在任意时间加入直播，从当前时间点开始观看。
   直播场景对延迟有严格要求：

   - 传统直播（HLS）：6-30 秒延迟
   - 低延迟直播（LL-HLS/SRT）：1-3 秒延迟
   - 超低延迟（WebRTC）：< 500ms 延迟

4. **自适应码率（Adaptive Bitrate, ABR）**

   根据用户的网络带宽和设备能力，自动选择合适的视频质量。
   当网络变差时降低码率避免卡顿，网络恢复时提升码率改善画质。
   ABR 是现代流媒体系统的标配功能。

5. **弱网流畅播放（Resilience）**

   在网络抖动、丢包、带宽波动等不理想条件下，仍能保持流畅播放。
   技术手段包括：自适应缓冲、FEC 前向纠错、重传、降级策略等。

6. **CDN 分发支持（CDN Compatibility）**

   支持通过 CDN（Content Delivery Network）进行大规模分发。
   基于 HTTP 的协议（HLS、DASH）天然适合 CDN 缓存和分发。
   基于 UDP 的协议（RTP、SRT、WebRTC）需要专门的媒体 CDN。

7. **安全加密（Content Protection）**

   支持内容加密和 DRM（Digital Rights Management），防止未授权访问和盗版。
   常见方案包括 AES-128 加密、Widevine、FairPlay、PlayReady 等。


流媒体协议详解
======================

MPEG-TS
--------------------

MPEG Transport Stream（MPEG-TS，ISO/IEC 13818-1）是一种传输流容器格式：

- **包结构**：固定 188 字节/包（或 204 字节含 FEC），以 0x47 同步字节开头
- **PID（Packet Identifier）**：13 位标识符，区分不同的数据流
- **PSI 表**：PAT（Program Association Table）和 PMT（Program Map Table）描述节目结构
- **特点**：抗误码能力强，适合广播和不可靠网络传输
- **应用**：数字电视广播（DVB）、HLS 的 TS 切片

::

    ┌──────────────────────────────────────────────┐
    │ Sync │ PID  │ Adaptation │ Payload           │
    │ 0x47 │ 13b  │ Field      │ (PES/PSI data)    │
    │ 1B   │      │ (optional) │                   │
    └──────────────────────────────────────────────┘
    ←──────────── 188 bytes ──────────────────────→

RTSP/RTP
--------------------

RTSP（Real Time Streaming Protocol，RFC 7826）是一个应用层信令协议，
配合 RTP/RTCP 进行媒体传输：

- **信令与媒体分离**：RTSP 负责控制（播放、暂停、定位），RTP 负责媒体数据传输
- **端口**：RTSP 默认 554 端口（TCP），RTP 使用动态端口（UDP）
- **典型交互流程**：

::

    Client                          Server
      │                               │
      │──── DESCRIBE rtsp://... ────>│  # 获取媒体描述 (SDP)
      │<─── 200 OK (SDP) ──────────│
      │                               │
      │──── SETUP (transport) ──────>│  # 建立传输通道
      │<─── 200 OK ────────────────│
      │                               │
      │──── PLAY ──────────────────>│  # 开始播放
      │<─── 200 OK ────────────────│
      │<════ RTP Media Data ════════│  # 媒体数据流
      │                               │
      │──── TEARDOWN ──────────────>│  # 结束会话
      │<─── 200 OK ────────────────│

- **应用场景**：安防监控（ONVIF）、IP 摄像头、传统点播系统

RTMP
--------------------

RTMP（Real-Time Messaging Protocol）是 Adobe 开发的流媒体协议：

- **基于 TCP**：默认端口 1935，保证可靠传输
- **Chunk Stream**：将消息分割为固定大小的 chunk（默认 128 字节），支持多路复用
- **消息类型**：音频（8）、视频（9）、数据（18/15）、命令（20/17）
- **握手**：C0/S0 → C1/S1 → C2/S2 三步握手
- **变体**：RTMPS（TLS 加密）、RTMPE（加密）、RTMPT（HTTP 隧道）
- **延迟**：通常 1-3 秒
- **现状**：虽然 Flash 已淘汰，但 RTMP 仍是推流（Ingest）的事实标准

.. code-block:: bash

    # FFmpeg RTMP 推流
    ffmpeg -re -i input.mp4 \
        -c:v libx264 -preset veryfast -b:v 2000k \
        -c:a aac -b:a 128k \
        -f flv rtmp://server/live/stream_key

HLS
--------------------

HLS（HTTP Live Streaming）是 Apple 提出的基于 HTTP 的自适应流媒体协议（RFC 8216）：

- **原理**：将媒体流切割为小的 TS 或 fMP4 片段（Segment），通过 M3U8 播放列表索引
- **两级播放列表**：
  - Master Playlist：列出不同码率/分辨率的变体流
  - Media Playlist：列出具体的媒体片段 URL
- **片段时长**：通常 2-10 秒，影响延迟
- **延迟分析**：延迟 ≈ 片段时长 × 3（至少缓冲 3 个片段），通常 6-30 秒

.. code-block:: text

    # Master Playlist
    #EXTM3U
    #EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
    360p/playlist.m3u8
    #EXT-X-STREAM-INF:BANDWIDTH=2000000,RESOLUTION=1280x720
    720p/playlist.m3u8
    #EXT-X-STREAM-INF:BANDWIDTH=5000000,RESOLUTION=1920x1080
    1080p/playlist.m3u8

    # Media Playlist
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-TARGETDURATION:6
    #EXT-X-MEDIA-SEQUENCE:100
    #EXTINF:6.0,
    segment100.ts
    #EXTINF:6.0,
    segment101.ts
    #EXTINF:6.0,
    segment102.ts

**LL-HLS（Low-Latency HLS）**：Apple 在 2019 年推出的低延迟 HLS 扩展：

- 使用 Partial Segments（部分片段），每个约 200ms-1s
- 支持 Blocking Playlist Reload（阻塞式播放列表刷新）
- 支持 Preload Hints（预加载提示）
- 延迟可降至 2-4 秒

DASH
--------------------

DASH（Dynamic Adaptive Streaming over HTTP，ISO/IEC 23009-1）是国际标准化的自适应流协议：

- **MPD（Media Presentation Description）**：XML 格式的媒体描述文件，类似 HLS 的 M3U8
- **片段格式**：ISO BMFF（fMP4）或 MPEG-TS
- **自适应码率**：客户端根据网络状况在不同 Representation 之间切换
- **结构层次**：Period → AdaptationSet → Representation → Segment

.. code-block:: xml

    <MPD type="dynamic" minBufferTime="PT2S">
      <Period>
        <AdaptationSet mimeType="video/mp4" segmentAlignment="true">
          <Representation id="720p" bandwidth="2000000"
                          width="1280" height="720">
            <SegmentTemplate media="video_720p_$Number$.m4s"
                             initialization="video_720p_init.mp4"
                             duration="4000" timescale="1000"/>
          </Representation>
          <Representation id="360p" bandwidth="800000"
                          width="640" height="360">
            <SegmentTemplate media="video_360p_$Number$.m4s"
                             initialization="video_360p_init.mp4"
                             duration="4000" timescale="1000"/>
          </Representation>
        </AdaptationSet>
      </Period>
    </MPD>

**LL-DASH（Low-Latency DASH）**：使用 CMAF（Common Media Application Format）
和 Chunked Transfer Encoding 实现低延迟，可达 2-5 秒。

SRT
--------------------

SRT（Secure Reliable Transport）是 Haivision 开源的低延迟传输协议：

- **基于 UDP**：使用 UDT（UDP-based Data Transfer）协议栈
- **ARQ 重传**：选择性重传丢失的包，而非 TCP 的全序重传
- **AES 加密**：内置 AES-128/256 加密
- **延迟控制**：可配置的延迟缓冲（latency buffer），通常 120ms-8s
- **FEC 支持**：可选的前向纠错
- **应用场景**：跨公网的高质量视频传输、远程制作、贡献链路

.. code-block:: bash

    # FFmpeg SRT 推流
    ffmpeg -re -i input.mp4 \
        -c:v libx264 -b:v 4000k \
        -c:a aac -b:a 128k \
        -f mpegts "srt://server:9000?streamid=live/stream1&latency=200000"

HTTP-FLV
--------------------

HTTP-FLV 是通过 HTTP 长连接传输 FLV 格式数据的方案：

- **原理**：HTTP chunked transfer encoding + FLV 容器
- **延迟**：1-3 秒，比 HLS 低很多
- **优点**：复用 HTTP 基础设施，CDN 友好，浏览器通过 flv.js 支持
- **缺点**：不支持自适应码率，依赖 MSE（Media Source Extensions）

WebRTC
--------------------

WebRTC 用于流媒体传输时具有独特优势：

- **超低延迟**：端到端延迟 < 500ms，适合实时互动
- **P2P/SFU**：支持点对点和服务器转发两种架构
- **WHIP/WHEP**：标准化的 HTTP 推流/拉流协议
- **自适应**：内置拥塞控制和码率自适应
- **缺点**：大规模分发需要 SFU 集群，成本较高


协议对比
======================

.. list-table:: 流媒体协议对比
   :header-rows: 1
   :widths: 12 10 12 12 12 12 12 18

   * - 协议
     - 传输层
     - 延迟
     - 自适应
     - 浏览器
     - CDN
     - 加密
     - 典型场景
   * - RTSP/RTP
     - UDP/TCP
     - 1-2s
     - ✗
     - ✗
     - ✗
     - SRTP
     - 安防监控
   * - RTMP
     - TCP
     - 1-3s
     - ✗
     - ✗
     - RTMPS
     - ✓
     - 推流 Ingest
   * - HLS
     - HTTP
     - 6-30s
     - ✓
     - ✓
     - ✓
     - AES-128
     - 大规模直播/点播
   * - LL-HLS
     - HTTP
     - 2-4s
     - ✓
     - ✓
     - ✓
     - AES-128
     - 低延迟直播
   * - DASH
     - HTTP
     - 6-30s
     - ✓
     - ✓
     - ✓
     - CENC
     - 点播/直播
   * - SRT
     - UDP
     - 0.1-8s
     - ✗
     - ✗
     - ✗
     - AES
     - 贡献链路
   * - HTTP-FLV
     - HTTP
     - 1-3s
     - ✗
     - flv.js
     - ✓
     - ✗
     - 低延迟直播
   * - WebRTC
     - UDP
     - <0.5s
     - ✓
     - ✓
     - 专用
     - DTLS-SRTP
     - 实时互动


自适应码率 (ABR)
======================

ABR（Adaptive Bitrate Streaming）是现代流媒体系统的核心技术，
客户端根据网络状况动态选择合适的码率档位。

ABR 算法分类
--------------------

1. **基于吞吐量（Throughput-based）**

   测量最近几个片段的下载速度，选择不超过估计带宽的最高码率。
   简单直接，但对带宽波动敏感。

2. **基于缓冲区（Buffer-based）**

   根据播放缓冲区的水位选择码率：缓冲区满时选高码率，缓冲区低时选低码率。
   代表算法：BBA（Buffer-Based Approach）。

3. **混合算法（Hybrid）**

   结合吞吐量和缓冲区信息。代表算法：BOLA（Buffer Occupancy based Lyapunov Algorithm）、
   MPC（Model Predictive Control）。

4. **基于学习（Learning-based）**

   使用机器学习（如强化学习）预测最优码率选择。代表：Pensieve（MIT）。

码率阶梯 (Bitrate Ladder)
-----------------------------

码率阶梯定义了可用的编码档位：

.. list-table:: 典型码率阶梯
   :header-rows: 1
   :widths: 20 20 20 20 20

   * - 分辨率
     - 帧率
     - 视频码率
     - 音频码率
     - 总码率
   * - 426×240
     - 30fps
     - 400 kbps
     - 64 kbps
     - 464 kbps
   * - 640×360
     - 30fps
     - 800 kbps
     - 96 kbps
     - 896 kbps
   * - 854×480
     - 30fps
     - 1.5 Mbps
     - 128 kbps
     - 1.6 Mbps
   * - 1280×720
     - 30fps
     - 3.0 Mbps
     - 128 kbps
     - 3.1 Mbps
   * - 1920×1080
     - 30fps
     - 6.0 Mbps
     - 192 kbps
     - 6.2 Mbps
   * - 1920×1080
     - 60fps
     - 8.0 Mbps
     - 192 kbps
     - 8.2 Mbps

Netflix 等平台使用 Per-Title Encoding，根据内容复杂度为每个视频定制码率阶梯。


低延迟流媒体
======================

低延迟是流媒体技术的重要发展方向，不同场景对延迟有不同要求：

.. list-table:: 延迟需求分级
   :header-rows: 1
   :widths: 25 20 55

   * - 延迟级别
     - 范围
     - 典型场景
   * - 超低延迟
     - < 500ms
     - 视频通话、连麦互动、云游戏
   * - 低延迟
     - 1-3s
     - 电商直播、体育博彩、在线拍卖
   * - 中等延迟
     - 3-10s
     - 游戏直播、教育直播
   * - 标准延迟
     - 10-30s
     - 大规模直播、点播

降低延迟的关键技术：

- **更小的片段**：HLS/DASH 片段从 10s 缩短到 1-2s，LL-HLS 使用 200ms 部分片段
- **Chunked Transfer**：HTTP chunked encoding 允许片段生成过程中就开始传输
- **推送机制**：HTTP/2 Server Push、WebSocket 推送，减少轮询延迟
- **UDP 传输**：SRT、WebRTC 使用 UDP 避免 TCP 的队头阻塞和重传延迟
- **边缘计算**：在 CDN 边缘节点进行转码和切片，减少回源延迟


CDN 与流媒体分发
======================

CDN 是大规模流媒体分发的基础设施：

::

    ┌──────────┐     ┌──────────┐     ┌──────────┐
    │  Origin  │────>│  Edge    │────>│  Client  │
    │  Server  │     │  Node    │     │          │
    └──────────┘     └──────────┘     └──────────┘
         │                │
         │           ┌──────────┐     ┌──────────┐
         │           │  Edge    │────>│  Client  │
         │           │  Node    │     │          │
         │           └──────────┘     └──────────┘
         │                │
         └───────────┌──────────┐     ┌──────────┐
                     │  Edge    │────>│  Client  │
                     │  Node    │     │          │
                     └──────────┘     └──────────┘

- **边缘节点缓存**：HLS/DASH 的 HTTP 片段天然适合 CDN 缓存
- **回源策略**：边缘节点缓存未命中时向源站请求，多级缓存减少回源
- **就近接入**：DNS 或 Anycast 将用户路由到最近的边缘节点
- **媒体 CDN**：针对 RTMP、SRT、WebRTC 等非 HTTP 协议的专用 CDN


流媒体服务器
======================

.. list-table:: 常见流媒体服务器对比
   :header-rows: 1
   :widths: 15 20 20 20 25

   * - 服务器
     - 语言
     - 支持协议
     - 许可证
     - 特点
   * - SRS
     - C++
     - RTMP/HLS/WebRTC/SRT/GB28181
     - MIT
     - 功能全面，中国社区活跃
   * - Nginx-RTMP
     - C
     - RTMP/HLS
     - BSD
     - 轻量，Nginx 模块
   * - MediaMTX
     - Go
     - RTSP/RTMP/HLS/WebRTC/SRT
     - MIT
     - 零配置，多协议
   * - Janus
     - C
     - WebRTC/SIP
     - GPL-3.0
     - WebRTC 网关
   * - mediasoup
     - C++/Node.js
     - WebRTC
     - ISC
     - SFU，高性能
   * - Wowza
     - Java
     - 全协议
     - 商业
     - 企业级，功能最全


FFmpeg 流媒体命令
======================

FFmpeg 是流媒体开发中最常用的工具：

.. code-block:: bash

    # 1. RTMP 推流
    ffmpeg -re -i input.mp4 \
        -c:v libx264 -preset veryfast -tune zerolatency -b:v 2000k \
        -c:a aac -b:a 128k \
        -f flv rtmp://localhost/live/stream

    # 2. 生成 HLS 切片
    ffmpeg -re -i input.mp4 \
        -c:v libx264 -b:v 2000k \
        -c:a aac -b:a 128k \
        -hls_time 6 -hls_list_size 10 -hls_flags delete_segments \
        -f hls /var/www/html/live/stream.m3u8

    # 3. 多码率 HLS（自适应码率）
    ffmpeg -re -i input.mp4 \
        -map 0:v -map 0:v -map 0:v -map 0:a \
        -c:v libx264 -c:a aac \
        -b:v:0 800k -s:v:0 640x360 \
        -b:v:1 2000k -s:v:1 1280x720 \
        -b:v:2 5000k -s:v:2 1920x1080 \
        -b:a 128k \
        -var_stream_map "v:0,a:0 v:1,a:0 v:2,a:0" \
        -master_pl_name master.m3u8 \
        -f hls -hls_time 6 -hls_list_size 10 \
        stream_%v/playlist.m3u8

    # 4. SRT 推流
    ffmpeg -re -i input.mp4 \
        -c:v libx264 -b:v 4000k \
        -c:a aac -b:a 128k \
        -f mpegts "srt://server:9000?streamid=live/stream&latency=200000"

    # 5. RTSP 拉流转 RTMP
    ffmpeg -rtsp_transport tcp -i rtsp://camera/stream \
        -c copy -f flv rtmp://server/live/camera1

    # 6. 录制直播流
    ffmpeg -i rtmp://server/live/stream \
        -c copy -f segment -segment_time 3600 \
        -strftime 1 recording_%Y%m%d_%H%M%S.mp4

    # 7. 低延迟推流参数
    ffmpeg -re -i input.mp4 \
        -c:v libx264 -preset ultrafast -tune zerolatency \
        -x264-params "keyint=30:min-keyint=30:scenecut=0" \
        -b:v 2000k -maxrate 2500k -bufsize 1000k \
        -c:a aac -b:a 128k \
        -f flv rtmp://server/live/low_latency


参考文献
======================

* RFC 7826 - Real-Time Streaming Protocol Version 2.0
* RFC 8216 - HTTP Live Streaming
* ISO/IEC 23009-1 - Dynamic Adaptive Streaming over HTTP (DASH)
* ISO/IEC 13818-1 - MPEG Transport Stream
* SRT Protocol - https://github.com/Haivision/srt
* FFmpeg Documentation - https://ffmpeg.org/documentation.html
* Apple HLS Authoring Specification - https://developer.apple.com/documentation/http-live-streaming
* DASH Industry Forum - https://dashif.org/
* flv.js - https://github.com/bilibili/flv.js
