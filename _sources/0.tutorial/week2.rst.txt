################################
第二周：传输协议深入
################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**摘要**     WebRTC 简明教程 · 第二周
**作者**     Walter Fan
**状态**     持续更新中
**更新日期** |date|
============ =============================

.. contents::
    :local:

学习目标
==========================

本周结束后，你应该能够：

- ✅ 理解 ICE/STUN/TURN 的连接建立机制
- ✅ 掌握 DTLS/SRTP 的安全传输原理
- ✅ 读懂 RTP/RTCP 数据包的结构
- ✅ 用 Wireshark 抓包分析 WebRTC 通信

.. tip::

   本周协议名词多、细节多，容易学偏。建议抓住主线：先理解每个协议解决什么问题、出现在什么阶段，再深入报文格式。
   初学者如果觉得一周消化不完，可以拉长到两周，先掌握 ICE 和 RTP/RTCP，再补 DTLS/SRTP 和 DataChannel。


每日计划
==========================

Day 1：NAT 穿越 — ICE/STUN/TURN
------------------------------------

**目标**：理解 WebRTC 如何在复杂网络环境下建立连接

**学习内容**：

- NAT 的类型和对 P2P 通信的影响
- STUN：获取公网地址
- TURN：中继转发
- ICE：综合 STUN 和 TURN 的连接建立框架
- ICE Candidate 的收集和优先级

**动手练习**：

- 用公共 STUN 服务器（如 ``stun:stun.l.google.com:19302``）获取自己的公网地址
- 在 ``chrome://webrtc-internals`` 中观察 ICE Candidate 的收集过程

**学习提示**：

- 重点区分 host / srflx / relay 三类 candidate 的含义
- 理解 TURN 为什么"更可靠但成本更高"
- ICE 连接失败通常是网络连通性问题，而不是代码 bug

**参考阅读**：:doc:`../2.transport/ice` · :doc:`../2.transport/stun` · :doc:`../2.transport/turn`


Day 2：安全传输 — TLS/DTLS/SRTP
------------------------------------

**目标**：理解 WebRTC 的安全机制

**学习内容**：

- TLS 和 DTLS 的区别（TCP vs UDP）
- DTLS 握手过程
- SRTP：加密的 RTP
- 密钥协商：DTLS-SRTP

**动手练习**：

- 用 Wireshark 抓包，找到 DTLS 握手的过程
- 对比加密前后的 RTP 包内容

**学习提示**：

- 把握分层关系：DTLS 负责握手和密钥协商，SRTP 负责加密媒体传输
- WebRTC 强制要求加密，这是和传统 RTP 的重要区别

**参考阅读**：:doc:`../2.transport/tls` · :doc:`../2.transport/dtls` · :doc:`../2.transport/srtp`


Day 3：媒体传输 — RTP 协议
--------------------------

**目标**：掌握实时媒体传输的核心协议

**学习内容**：

- RTP 包头结构（版本、负载类型、序列号、时间戳、SSRC）
- RTP 负载格式
- RTP 头部扩展
- RTP Keepalive 机制

**动手练习**：

- 用 Wireshark 捕获 RTP 包，逐字段分析包头
- 观察音频和视频 RTP 包的区别（负载类型、时间戳增量）

**学习提示**：

- 序列号用于检测丢包和排序，时间戳用于播放同步——两者缺一不可
- SSRC 用于区分同一连接上的不同媒体流

**参考阅读**：:doc:`../2.transport/rtp` · :doc:`../2.transport/rtp_header_extension` · :doc:`../2.transport/rtp_keepalive`


Day 4：控制反馈 — RTCP 协议
--------------------------

**目标**：理解 RTCP 如何为 QoS 提供反馈

**学习内容**：

- RTCP 的作用和类型
- SR（Sender Report）和 RR（Receiver Report）
- SDES、BYE、APP
- RTCP XR（Extended Report）
- RTCP 复合包

**动手练习**：

- 在 Wireshark 中过滤 RTCP 包，分析 SR 和 RR 的内容
- 观察丢包率、抖动等统计数据

**学习提示**：

- RTCP 不传媒体数据，它的角色是告诉对方"我收得怎么样"
- 先掌握 SR、RR、NACK、PLI 的用途，格式细节可以在实际排障时再查

**参考阅读**：:doc:`../2.transport/rtcp` · :doc:`../2.transport/rtcp_sr` · :doc:`../2.transport/rtcp_rr` · :doc:`../2.transport/rtcp_xr`


Day 5：数据通道与多路复用
--------------------------

**目标**：掌握 DataChannel 和传输层优化

**学习内容**：

- SCTP 协议基础
- WebRTC DataChannel 的实现
- WebSocket 与 DataChannel 的对比
- 传输多路复用（BUNDLE）

**动手练习**：

- 用 DataChannel 实现一个简单的文字聊天功能
- 在已有的 P2P 视频通话中加入 DataChannel

**参考阅读**：:doc:`../2.transport/sctp` · :doc:`../2.transport/webrtc_data_channel` · :doc:`../2.transport/websocket` · :doc:`../2.transport/webrtc_multiplex` · :doc:`../2.transport/webrtc_bundle`


Day 6-7：实战 — Wireshark 抓包分析
--------------------------------------

**目标**：完成本周的里程碑项目 🎯

**实战任务**：

对第一周的 P2P 视频通话进行完整的抓包分析：

1. 安装 Wireshark，配置 WebRTC 相关的过滤器
2. 发起一次视频通话，完整抓包
3. 分析以下内容：

   - STUN Binding Request/Response
   - DTLS 握手过程（ClientHello → ServerHello → ...）
   - RTP 音频包和视频包
   - RTCP SR/RR 报告

4. 写一份分析报告，回答以下问题：

   - 抓到了哪些类型的 candidate？
   - 媒体流什么时候开始发送？
   - 连接建立过程中有哪些关键协议切换？
   - 如果这次通话失败，应该从哪一段开始排查？

**参考阅读**：:doc:`../8.tool/wireshark` · :doc:`../8.tool/tcpdump`

**检查清单**：

- [ ] 能用 Wireshark 过滤出 STUN 包
- [ ] 能识别 DTLS 握手的各个阶段
- [ ] 能区分 RTP 音频包和视频包
- [ ] 能从 RTCP RR 中读出丢包率和抖动


常见卡点
==========================

**现象：抓到了很多 UDP 包，但分不清协议类型**

- 先识别 STUN（固定的 magic cookie），再找 DTLS（握手包），最后看 RTP/RTCP
- 善用 Wireshark 的协议过滤器

**现象：概念太多记不住**

- 回到时间线梳理：采集 → 信令 → ICE → DTLS → 媒体流
- 每个协议对应链路上的一个阶段，按顺序理解最不容易混淆

**现象：不知道怎么排障**

- 先用 ``chrome://webrtc-internals`` 看状态变化，再对照 Wireshark 抓包
- 两个工具互相印证，比单独使用一个效率高很多


详细参考
==========================

本周的学习内容对应手册的 :doc:`../2.transport/index` 章节，包含以下主题：

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - 主题
     - 说明
   * - :doc:`../2.transport/overview`
     - 传输概论
   * - :doc:`../2.transport/ice`
     - ICE 连接建立
   * - :doc:`../2.transport/stun`
     - STUN 协议
   * - :doc:`../2.transport/turn`
     - TURN 中继
   * - :doc:`../2.transport/tls`
     - TLS 协议
   * - :doc:`../2.transport/dtls`
     - DTLS 协议
   * - :doc:`../2.transport/srtp`
     - SRTP 加密传输
   * - :doc:`../2.transport/rtp`
     - RTP 协议
   * - :doc:`../2.transport/rtcp`
     - RTCP 协议
   * - :doc:`../2.transport/sctp`
     - SCTP 协议
   * - :doc:`../2.transport/webrtc_data_channel`
     - DataChannel
   * - :doc:`../2.transport/webrtc_multiplex`
     - 传输多路复用
   * - :doc:`../2.transport/webrtc_bundle`
     - BUNDLE 机制
