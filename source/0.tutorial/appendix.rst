################################
附录：工具、项目与扩展阅读
################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**摘要**     WebRTC 简明教程 · 附录
**作者**     Walter Fan
**状态**     持续更新中
**更新日期** |date|
============ =============================

.. contents::
    :local:


开源项目速查
==========================

学习 WebRTC 离不开这些优秀的开源项目。详细内容参见 :doc:`../7.practice/index`。

.. list-table::
   :header-rows: 1
   :widths: 15 15 70

   * - 项目
     - 语言
     - 说明
   * - `Janus Gateway <https://janus.conf.meetecho.com/>`_
     - C
     - 轻量级 WebRTC 服务器，插件化架构，支持 VideoRoom/SIP/Streaming 等
   * - `MediaSoup <https://mediasoup.org/>`_
     - Node.js/C++
     - 高性能 SFU，适合构建大规模视频会议
   * - `Pion <https://github.com/pion/webrtc>`_
     - Go
     - 纯 Go 实现的 WebRTC 栈，API 友好，适合服务端开发
   * - `coturn <https://github.com/coturn/coturn>`_
     - C
     - TURN/STUN 服务器，生产环境必备
   * - `aiortc <https://github.com/aiortc/aiortc>`_
     - Python
     - Python 的 WebRTC 实现，适合快速原型和测试
   * - `SRS <https://github.com/ossrs/srs>`_
     - C++
     - 流媒体服务器，支持 WebRTC/RTMP/HLS/SRT
   * - `OWT <https://github.com/open-webrtc-toolkit>`_
     - C++/JS
     - Intel 开源的 WebRTC 工具包

**参考阅读**：:doc:`../7.practice/janus` · :doc:`../7.practice/mediasoup` · :doc:`../7.practice/pion` · :doc:`../7.practice/coturn` · :doc:`../7.practice/aiortc` · :doc:`../7.practice/srs` · :doc:`../7.practice/owt`


常用工具速查
==========================

详细内容参见 :doc:`../8.tool/index`。

.. list-table::
   :header-rows: 1
   :widths: 15 85

   * - 工具
     - 用途
   * - **chrome://webrtc-internals**
     - Chrome 内置 WebRTC 调试工具，查看连接状态、统计数据、SDP 等
   * - **Wireshark**
     - 网络抓包分析，支持 RTP/RTCP/STUN/DTLS 协议解析
   * - **tcpdump**
     - 命令行抓包工具，配合 Wireshark 使用
   * - **FFmpeg**
     - 音视频处理瑞士军刀，编解码、转码、录制、推流
   * - **GStreamer**
     - 多媒体框架，支持 WebRTC 插件
   * - **SoX**
     - 命令行音频处理工具
   * - **iPerf**
     - 网络带宽测试工具
   * - **Linux TC**
     - 流量控制，模拟弱网环境（丢包、延迟、抖动）

**参考阅读**：:doc:`../8.tool/wireshark` · :doc:`../8.tool/tcpdump` · :doc:`../8.tool/ffmpeg` · :doc:`../8.tool/gstreamer` · :doc:`../8.tool/sox` · :doc:`../8.tool/iperf` · :doc:`../8.tool/tc`


关联技术
==========================

想要深入理解 WebRTC 的底层原理，这些基础知识会很有帮助。详细内容参见 :doc:`../9.misc/index`。

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 主题
     - 说明
   * - :doc:`../9.misc/signal`
     - 信号处理基础 — 理解音视频的数学本质
   * - :doc:`../9.misc/dsp`
     - 数字信号处理 — 傅里叶变换、滤波器等
   * - :doc:`../9.misc/kalman`
     - 卡尔曼滤波 — 拥塞控制中的核心算法
   * - :doc:`../9.misc/statistics`
     - 概率与统计 — QoS 指标分析的基础
   * - :doc:`../9.misc/multimedia`
     - 多媒体技术 — 音视频编解码的理论基础
   * - :doc:`../9.misc/security`
     - 安全技术 — DTLS、SRTP 背后的密码学
   * - :doc:`../9.misc/ai_and_webrtc`
     - AI 与 WebRTC — AI 降噪、超分辨率等前沿方向


核心 RFC 速查
==========================

.. list-table::
   :header-rows: 1
   :widths: 15 85

   * - RFC
     - 说明
   * - `RFC3550`_
     - RTP: A Transport Protocol for Real-Time Applications
   * - `RFC3711`_
     - The Secure Real-time Transport Protocol (SRTP)
   * - `RFC4566`_
     - SDP: Session Description Protocol
   * - `RFC8445`_
     - Interactive Connectivity Establishment (ICE)
   * - `RFC8825`_
     - Overview: Real-Time Protocols for Browser-Based Applications
   * - `RFC8829`_
     - JavaScript Session Establishment Protocol (JSEP)
   * - `RFC8831`_
     - WebRTC Data Channels
   * - `RFC8285`_
     - A General Mechanism for RTP Header Extensions
