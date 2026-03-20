################################
第四周：QoS 与项目实战
################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**摘要**     WebRTC 简明教程 · 第四周
**作者**     Walter Fan
**状态**     持续更新中
**更新日期** |date|
============ =============================

.. contents::
    :local:

学习目标
==========================

本周结束后，你应该能够：

- ✅ 理解 WebRTC 的拥塞控制算法（GCC/TWCC）
- ✅ 掌握丢包恢复机制（FEC/NACK/RTX）
- ✅ 了解 Jitter Buffer 的工作原理
- ✅ 搭建一个基于 SFU 的多人会议系统

.. tip::

   本周是整个教程中难度最高的一周，同时涉及 QoS 理论和 SFU 工程实践。
   如果你是初学者，建议先用两周时间完成：第一周聚焦 QoS 概念和观察，第二周聚焦 SFU 部署和多人会议搭建。


每日计划
==========================

Day 1：QoS 概览与拥塞控制
--------------------------

**目标**：理解 WebRTC 如何应对网络波动

**学习内容**：

- WebRTC QoS 策略全景
- 拥塞控制的必要性
- GCC（Google Congestion Control）算法原理
- 基于延迟的带宽估计 vs 基于丢包的带宽估计

**动手练习**：

- 在 ``chrome://webrtc-internals`` 中观察带宽估计的变化曲线
- 用 Linux TC（Traffic Control）或 Network Link Conditioner 模拟弱网环境

**学习提示**：

- 把 QoS 指标和用户体感联系起来：码率下降 → 画面模糊，帧率下降 → 画面卡顿，延迟增大 → 交流不自然
- 弱网模拟是理解 QoS 最直观的方式

**参考阅读**：:doc:`../5.qos/webrtc_qos` · :doc:`../5.qos/webrtc_cc` · :doc:`../5.qos/webrtc_gcc`


Day 2：带宽估计与反馈
--------------------------

**目标**：深入理解带宽估计的实现机制

**学习内容**：

- REMB（Receiver Estimated Maximum Bitrate）
- TWCC（Transport-Wide Congestion Control）
- 带宽探测（Bandwidth Probing）
- 拥塞控制算法的评估方法

**动手练习**：

- 在 Wireshark 中找到 TWCC 反馈包
- 观察不同网络条件下带宽估计的收敛过程

**参考阅读**：:doc:`../5.qos/webrtc_remb` · :doc:`../5.qos/webrtc_twcc` · :doc:`../5.qos/webrtc_bw_probe` · :doc:`../5.qos/webrtc_cc_evaluation`


Day 3：丢包恢复机制
--------------------------

**目标**：掌握 WebRTC 对抗丢包的三板斧

**学习内容**：

- NACK — 请求重传丢失的包
- FEC（Forward Error Correction）— 前向纠错，不需要重传
- RTX（Retransmission）— 用独立的 SSRC 重传
- RED（Redundant Encoding）— 冗余编码
- RTCP 反馈消息：PLI、FIR、NACK

**动手练习**：

- 模拟 5% 丢包率，观察 NACK 和 FEC 的触发
- 对比开启/关闭 FEC 时的视频质量

**学习提示**：

- NACK 适合低延迟场景（如对话），FEC 适合不方便重传的场景
- 理解 NACK 和 FEC 的互补关系，是掌握 WebRTC QoS 的关键

**参考阅读**：:doc:`../5.qos/webrtc_fec` · :doc:`../5.qos/webrtc_rtx` · :doc:`../5.qos/webrtc_red` · :doc:`../5.qos/webrtc_feedback`


Day 4：Jitter Buffer 与端到端延迟
--------------------------------------

**目标**：理解实时通信中的延迟控制

**学习内容**：

- 什么是 Jitter（抖动）以及为什么需要 Jitter Buffer
- 音频 Jitter Buffer（NetEQ）
- 视频 Jitter Buffer
- 丢包隐藏（PLC）
- 端到端延迟的组成和优化
- WebRTC 质量指标体系

**动手练习**：

- 在 ``chrome://webrtc-internals`` 中观察 jitter 和 jitterBufferDelay
- 模拟高抖动网络，观察 Jitter Buffer 的自适应行为

**参考阅读**：:doc:`../5.qos/jitter_overview` · :doc:`../5.qos/audio_jitter_buffer` · :doc:`../5.qos/video_jitter_buffer` · :doc:`../5.qos/plc` · :doc:`../5.qos/webrtc_e2e_delay` · :doc:`../5.qos/webrtc_metrics`


Day 5：SFU 架构与开源项目
--------------------------

**目标**：了解多人会议的服务端架构

**学习内容**：

- MCU vs SFU vs Mesh 架构对比
- SFU 的工作原理
- 主流开源 SFU 项目：

  - **Janus Gateway** — C 语言，轻量级，插件化
  - **MediaSoup** — Node.js/C++，高性能
  - **Pion** — Go 语言，纯 Go 实现

- WHIP/WHEP 协议简介

**动手练习**：

- 用 Docker 部署一个 Janus Gateway
- 用 Janus VideoRoom 插件实现多人视频会议

**参考阅读**：:doc:`../7.practice/sfu` · :doc:`../7.practice/janus` · :doc:`../7.practice/mediasoup` · :doc:`../7.practice/pion` · :doc:`../2.transport/whip`


Day 6-7：实战 — 多人视频会议
--------------------------------------

**目标**：完成本周的里程碑项目 🎯

**实战任务**：

搭建一个完整的多人视频会议系统：

1. 选择一个 SFU（推荐 Janus 或 MediaSoup）
2. 部署 SFU 服务器（可以用 Docker）
3. 实现前端：

   - 加入/离开房间
   - 多路视频显示
   - 静音/关闭摄像头
   - 屏幕共享

4. （可选）加入 DataChannel 实现文字聊天

.. tip::

   如果你是初学者，可以先跑通 SFU 自带的官方示例（如 Janus VideoRoom Demo），
   在理解架构之后再尝试自定义前端。搭建多人会议系统不必从零开始，站在开源项目的肩膀上更高效。

**参考阅读**：:doc:`../7.practice/janus_plugins` · :doc:`../7.practice/overview` · :doc:`../7.practice/webrtc_security`

**检查清单**：

- [ ] SFU 服务器能正常启动
- [ ] 多个用户能加入同一个房间
- [ ] 每个用户能看到其他人的视频
- [ ] 能正常静音和关闭摄像头
- [ ] （加分）支持屏幕共享


常见卡点
==========================

**现象：弱网模拟环境搭建困难**

- macOS 用户可以使用 Network Link Conditioner
- Linux 用户用 ``tc`` 命令即可模拟丢包、延迟、抖动
- 也可以在 Chrome DevTools 中使用网络限速功能做初步观察

**现象：SFU 部署失败**

- 优先使用 Docker 部署，减少环境依赖问题
- 注意 HTTPS 证书和端口映射的配置
- 先跑通 SFU 自带的 Demo，再做自定义开发

**现象：QoS 概念太抽象**

- 一切 QoS 机制最终都映射到用户体感：清晰度、流畅度、延迟
- 在弱网环境下对比有无 QoS 的效果，建立直观感受


详细参考
==========================

本周的学习内容对应手册的 :doc:`../5.qos/index` 和 :doc:`../7.practice/index` 章节：

**QoS 与网络对抗**

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - 主题
     - 说明
   * - :doc:`../5.qos/webrtc_qos`
     - QoS 策略概览
   * - :doc:`../5.qos/webrtc_cc`
     - 拥塞控制
   * - :doc:`../5.qos/webrtc_gcc`
     - GCC 算法
   * - :doc:`../5.qos/webrtc_twcc`
     - TWCC 反馈
   * - :doc:`../5.qos/webrtc_fec`
     - 前向纠错
   * - :doc:`../5.qos/webrtc_rtx`
     - 重传机制
   * - :doc:`../5.qos/webrtc_feedback`
     - RTCP 反馈
   * - :doc:`../5.qos/jitter_overview`
     - Jitter Buffer 概览
   * - :doc:`../5.qos/webrtc_e2e_delay`
     - 端到端延迟
   * - :doc:`../5.qos/webrtc_metrics`
     - 质量指标

**WebRTC 实践**

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - 主题
     - 说明
   * - :doc:`../7.practice/sfu`
     - SFU 架构
   * - :doc:`../7.practice/janus`
     - Janus Gateway
   * - :doc:`../7.practice/janus_plugins`
     - Janus 插件
   * - :doc:`../7.practice/mediasoup`
     - MediaSoup
   * - :doc:`../7.practice/pion`
     - Pion WebRTC
   * - :doc:`../7.practice/coturn`
     - coturn TURN 服务器
   * - :doc:`../7.practice/webrtc_security`
     - WebRTC 安全


进阶方向
==========================

完成四周学习后，你已经具备了 WebRTC 的基础能力。接下来可以根据兴趣选择深入方向：

.. list-table::
   :header-rows: 1
   :widths: 20 40 40

   * - 方向
     - 内容
     - 参考章节
   * - 🔬 源码分析
     - 深入 Chromium WebRTC 源码，理解 GCC、Pacer、NetEQ 等模块的实现
     - :doc:`../6.code/index`
   * - 🛠️ 工具精通
     - 熟练使用 FFmpeg、GStreamer、Wireshark 等工具
     - :doc:`../8.tool/index`
   * - 📐 理论深入
     - 数字信号处理、卡尔曼滤波、统计学等数理基础
     - :doc:`../9.misc/index`
   * - 🤖 AI + WebRTC
     - AI 降噪、超分辨率、智能带宽分配等前沿方向
     - :doc:`../9.misc/ai_and_webrtc`
