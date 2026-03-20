################################
第一周：WebRTC 基础入门
################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**摘要**     WebRTC 简明教程 · 第一周
**作者**     Walter Fan
**状态**     持续更新中
**更新日期** |date|
=============================  =============================

.. contents::
    :local:

学习目标
==========================

本周结束后，你应该能够：

- ✅ 理解 WebRTC 的核心概念和架构
- ✅ 掌握 WebRTC API 的基本用法
- ✅ 理解信令和 SDP 协商流程
- ✅ 完成一个 P2P 视频通话 Demo

.. tip::

   第一周是整个教程的基石。如果你是初学者，务必确保本周的里程碑项目跑通后再进入下一周。
   节奏慢一点没关系，但不要跳过实践环节。


每日计划
==========================

Day 1：WebRTC 是什么
--------------------------

**目标**：建立对 WebRTC 的整体认知

**学习内容**：

- WebRTC 的历史和发展
- WebRTC 的核心能力：音视频通话、屏幕共享、数据传输
- WebRTC 的架构：浏览器端 vs 服务器端
- WebRTC 涉及的标准和规范

**动手练习**：

- 打开 Chrome，访问 https://appr.tc 体验一次 WebRTC 通话
- 打开 ``chrome://webrtc-internals``，观察通话过程中的统计数据

**思考问题**：

- WebRTC 为什么需要信令服务器？
- 音视频数据是通过信令传输的吗？
- WebRTC 为什么需要 ICE？

**参考阅读**：:doc:`../1.basic/overview` · :doc:`../1.basic/web_browser` · :doc:`../1.basic/webrtc_spec`


Day 2：WebRTC API 入门
--------------------------

**目标**：掌握三大核心 API

**学习内容**：

- ``getUserMedia`` — 获取摄像头和麦克风
- ``RTCPeerConnection`` — 建立点对点连接
- ``RTCDataChannel`` — 传输任意数据
- WebRTC 的关键元素和实体

**动手练习**：

- 写一个网页，用 ``getUserMedia`` 获取摄像头画面并显示
- 尝试获取不同分辨率和帧率的视频流

**参考阅读**：:doc:`../1.basic/webrtc_api` · :doc:`../1.basic/webrtc_elements` · :doc:`../1.basic/webrtc_entities`


Day 3：媒体捕获与录制
--------------------------

**目标**：掌握媒体采集的各种方式

**学习内容**：

- 摄像头和麦克风的捕获（Media Capture）
- 屏幕共享（Screen Capture）
- 媒体录制（MediaRecorder API）

**动手练习**：

- 实现屏幕共享功能
- 实现录制功能，把视频保存为 WebM 文件

**参考阅读**：:doc:`../1.basic/media_capture` · :doc:`../1.basic/screen_capture` · :doc:`../1.basic/media_record`


Day 4：信令与 SDP
--------------------------

**目标**：理解 WebRTC 连接建立的核心机制

**学习内容**：

- 为什么需要信令服务器
- SDP（Session Description Protocol）的结构和含义
- Offer/Answer 模型
- ICE Candidate 的交换

**动手练习**：

- 用 ``console.log`` 打印出 SDP 内容，逐行分析
- 手动复制粘贴 SDP 完成一次 "手动信令" 的连接

**学习提示**：

- 理解 SDP 不需要逐字段背诵，重点掌握 Offer/Answer 模型和 ICE Candidate 交换的流程
- "手动信令"（手动复制粘贴 SDP）是理解信令流程最直观的方式

**参考阅读**：:doc:`../1.basic/webrtc_signal` · :doc:`../1.basic/webrtc_sdp` · :doc:`../1.basic/webrtc_flow`


Day 5：WebRTC 呼叫流程
--------------------------

**目标**：串联整个连接建立过程

**学习内容**：

- 完整的 WebRTC 呼叫流程（从 createOffer 到媒体流通）
- WebRTC 扩展能力
- WebRTC 统计信息（getStats API）

**动手练习**：

- 画一张 WebRTC 呼叫的时序图
- 用 ``getStats()`` 获取连接的实时统计数据

**参考阅读**：:doc:`../1.basic/webrtc_flow` · :doc:`../1.basic/webrtc_extension` · :doc:`../1.basic/webrtc_stats`


Day 6-7：实战 — P2P 视频通话
-------------------------------

**目标**：完成本周的里程碑项目 🎯

**实战任务**：

搭建一个完整的 P2P 视频通话应用：

1. 用 Node.js + WebSocket 搭建一个简单的信令服务器
2. 前端实现 ``getUserMedia`` + ``RTCPeerConnection``
3. 通过信令服务器交换 SDP 和 ICE Candidate
4. 实现双向视频通话

.. tip::

   如果你是初学者，可以先用两个标签页 + 手动复制 SDP 的方式跑通连接，建立直观感受后再实现信令服务器。

**参考阅读**：:doc:`../1.basic/video_chat` · :doc:`../1.basic/webrtc_capacity`

**检查清单**：

- [ ] 能获取本地摄像头画面
- [ ] 能通过信令服务器交换 SDP
- [ ] 能看到对方的视频画面
- [ ] 能正常挂断和重新连接


常见卡点
==========================

**现象：摄像头打不开**

- 检查浏览器是否授予了摄像头权限
- 确认页面是通过 HTTPS 或 localhost 访问的
- 检查设备是否被其他应用占用

**现象：本地有画面，远端没画面**

- 检查是否调用了 ``addTrack`` 添加本地流
- 检查对端是否监听了 ``ontrack`` 事件
- 检查 SDP 和 ICE Candidate 是否成功交换

**现象：看不懂 SDP**

- 第一轮重点关注：媒体类型（audio/video）、编解码器列表、ICE candidate、DTLS 指纹
- 其余字段可以在后续学习中逐步理解


详细参考
==============================================================

本周的学习内容对应手册的 :doc:`../1.basic/index` 章节，包含以下主题：

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - 主题
     - 说明
   * - :doc:`../1.basic/overview`
     - WebRTC 概论
   * - :doc:`../1.basic/web_browser`
     - 浏览器中的 RTC
   * - :doc:`../1.basic/webrtc_spec`
     - WebRTC 标准、协议和规范
   * - :doc:`../1.basic/webrtc_api`
     - WebRTC API 详解
   * - :doc:`../1.basic/webrtc_elements`
     - WebRTC 核心元素
   * - :doc:`../1.basic/webrtc_entities`
     - WebRTC 实体
   * - :doc:`../1.basic/webrtc_flow`
     - WebRTC 呼叫流程
   * - :doc:`../1.basic/media_capture`
     - 媒体捕获
   * - :doc:`../1.basic/screen_capture`
     - 屏幕共享
   * - :doc:`../1.basic/media_record`
     - 媒体录制
   * - :doc:`../1.basic/webrtc_signal`
     - WebRTC 信令
   * - :doc:`../1.basic/webrtc_sdp`
     - SDP 协议
   * - :doc:`../1.basic/webrtc_stats`
     - WebRTC 统计
   * - :doc:`../1.basic/video_chat`
     - 视频聊天实例
