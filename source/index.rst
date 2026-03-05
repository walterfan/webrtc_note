.. webrtc_book documentation master file

=======================================
WebRTC 学习笔记
=======================================


.. include:: links.ref
.. include:: tags.ref
.. include:: abbrs.ref


.. mermaid::

   mindmap
     root((WebRTC))
       基础
         浏览器架构
         WebRTC API
         信令与 SDP
         媒体捕获
       传输
         ICE/STUN/TURN
         DTLS/SRTP
         RTP/RTCP
         SCTP/DataChannel
       媒体
         音频处理
         视频编解码
         拥塞控制
         QoS 策略
       源码
         构建编译
         GCC 实现
         Pacer 模块
         OFDM 检测
       实践
         SFU 架构
         Janus/Pion
         安全与加密
       工具
         FFmpeg
         GStreamer
         Wireshark


============= =============================================
**摘要**       WebRTC 实时通信技术学习笔记
**作者**       Walter Fan
**分类**       学习笔记
**状态**       持续更新中
**更新日期**   |date|
**许可证**     |CC-BY-NC-ND|
============= =============================================


简介
=======================================

本笔记系统地记录了 WebRTC (Web Real-Time Communication) 技术的学习过程，涵盖从基础概念到源码分析的完整知识体系。

WebRTC 是一项开源技术，使浏览器和移动应用能够通过简单的 API 实现实时音视频通信和数据传输，无需安装插件。

**本笔记包含以下内容：**

- **WebRTC 简明教程** — 4 周学习路线，快速入门
- **WebRTC 基础** — API、信令、SDP、媒体捕获等核心概念
- **WebRTC 传输** — ICE、DTLS、SRTP、RTP/RTCP、DataChannel 等协议
- **WebRTC 媒体** — 音视频编解码、拥塞控制、QoS 策略
- **WebRTC 源码分析** — Chromium WebRTC 源码深度解读
- **WebRTC 实践** — SFU 架构、开源项目实战
- **WebRTC 工具** — 开发调试常用工具
- **关联技术** — 数字信号处理、多媒体基础等


目录
=======================================

.. toctree::
   :maxdepth: 2
   :caption: 目录

   0.tutorial/index
   1.basic/index
   2.transport/index
   3.media/index
   4.code/index
   5.practice/index
   6.tool/index
   7.misc/index


索引
==================

* :ref:`genindex`
* :ref:`search`
