.. _jitter_overview:

========================
网络抖动：成因与测量
========================

.. contents:: 目录
   :local:
   :depth: 2

概述
====

网络抖动（Jitter）是实时通信的头号敌人之一。它指的是数据包到达时间间隔的**不规则变化**——发送端以固定间隔发包（如每 20ms 一个），但接收端收到的间隔可能是 15ms、25ms、10ms、35ms……

对于语音和视频通信，抖动会导致：

- 音频断续、卡顿
- 视频帧不均匀、画面跳跃
- 唇音不同步
- 播放缓冲区溢出或欠载

抖动的成因
==========

.. mermaid::

   flowchart LR
     A[发送端<br/>均匀发包] --> B[网络路径]
     B --> C[接收端<br/>不均匀到达]

     subgraph 网络路径
       B1[路由器排队]
       B2[链路竞争]
       B3[路由变化]
       B4[WiFi 重传]
       B5[缓冲膨胀]
     end

1. **路由器排队延迟**

   路由器的输出队列是抖动的主要来源。当多个流竞争同一出口时，包在队列中等待的时间不确定。

2. **链路层竞争**

   WiFi 的 CSMA/CA 机制导致发送时机不确定；蜂窝网络的调度也引入变化。

3. **路由变化**

   BGP 路由收敛期间，连续的包可能走不同路径，延迟差异可达数十毫秒。

4. **缓冲膨胀（Bufferbloat）**

   网络设备中过大的缓冲区会吸收突发流量，但代价是增加延迟和抖动。

5. **操作系统调度**

   发送端和接收端的 OS 调度延迟也会贡献抖动，特别是在非实时操作系统上。

抖动的测量
==========

RFC 3550 定义
--------------

RTP 协议（RFC 3550）定义了 **interarrival jitter** 的计算方法，这是最广泛使用的抖动度量：

.. code-block:: text

   对于每对连续的 RTP 包 i 和 i-1：

   D(i, i-1) = (R_i - R_{i-1}) - (S_i - S_{i-1})

   其中：
     S_i = 包 i 的 RTP 时间戳（发送时间）
     R_i = 包 i 的到达时间（接收端本地时钟）

   D 就是"传输延迟的变化量"

   抖动用指数加权移动平均（EWMA）平滑：

   J(i) = J(i-1) + (|D(i, i-1)| - J(i-1)) / 16

这个公式的含义：

- ``D > 0``：包 i 比预期晚到（延迟增加）
- ``D < 0``：包 i 比预期早到（延迟减少）
- ``D = 0``：完美，无抖动
- 除以 16 是一个低通滤波器，平滑瞬时波动

RTCP SR/RR 中的抖动字段就是用这个公式计算的。

代码实现
---------

.. code-block:: go

   type JitterEstimator struct {
       jitter     float64
       lastTransit int64
       firstPacket bool
   }

   func (j *JitterEstimator) Update(rtpTimestamp uint32, arrivalTime int64, clockRate uint32) {
       // 将 RTP 时间戳转换为与到达时间相同的单位（微秒）
       sendTime := int64(rtpTimestamp) * 1000000 / int64(clockRate)
       transit := arrivalTime - sendTime

       if j.firstPacket {
           j.lastTransit = transit
           j.firstPacket = false
           return
       }

       d := transit - j.lastTransit
       j.lastTransit = transit

       if d < 0 {
           d = -d
       }

       // EWMA: J = J + (|D| - J) / 16
       j.jitter += (float64(d) - j.jitter) / 16.0
   }

其他抖动度量
-------------

.. list-table::
   :header-rows: 1
   :widths: 25 35 40

   * - 度量
     - 定义
     - 适用场景
   * - RFC 3550 Jitter
     - EWMA 平滑的传输延迟变化
     - RTCP 报告，通用
   * - P95/P99 Jitter
     - 第 95/99 百分位的延迟变化
     - 网络质量评估
   * - Max Jitter
     - 观测窗口内最大延迟变化
     - Jitter Buffer 设计
   * - Mean Jitter
     - 平均延迟变化
     - 长期趋势分析
   * - Jitter Range
     - max(delay) - min(delay)
     - 缓冲区大小估算

抖动与 Jitter Buffer
======================

Jitter Buffer 是对抗抖动的核心机制——在接收端引入一个缓冲区，将不均匀到达的包重新排列为均匀的播放流：

.. mermaid::

   flowchart LR
     A[网络<br/>不均匀到达] --> B[Jitter Buffer<br/>缓冲 + 重排]
     B --> C[播放器<br/>均匀播放]

     style B fill:#f9f,stroke:#333

缓冲区大小的权衡：

- **太小**：无法吸收抖动，导致欠载（underrun），播放卡顿
- **太大**：增加端到端延迟，影响交互体验

理想的缓冲区大小应该刚好覆盖网络抖动的范围。详见 :ref:`audio_jitter_buffer` 章节。

抖动对不同媒体的影响
======================

音频
-----

- 人耳对音频中断极其敏感，10ms 的间断就能感知
- 20ms 帧长的语音流，抖动超过 20ms 就会导致帧丢失
- Jitter Buffer 通常设置 40-200ms

视频
-----

- 视频帧间隔较大（33ms @30fps），对抖动的容忍度稍高
- 但视频帧通常跨多个 RTP 包，需要所有包到齐才能解码
- 关键帧（I 帧）丢失影响更大（后续 P/B 帧都无法解码）

实际网络中的抖动数据
=====================

典型网络环境的抖动参考值：

.. list-table::
   :header-rows: 1
   :widths: 30 20 20 30

   * - 网络类型
     - 平均抖动
     - P95 抖动
     - 说明
   * - 有线局域网
     - < 1 ms
     - < 2 ms
     - 几乎无抖动
   * - 企业 WiFi
     - 2-10 ms
     - 20-50 ms
     - 取决于负载
   * - 家庭 WiFi
     - 5-20 ms
     - 50-100 ms
     - 干扰较多
   * - 4G LTE
     - 10-30 ms
     - 50-150 ms
     - 调度引入抖动
   * - 5G NR
     - 5-15 ms
     - 20-50 ms
     - 改善明显
   * - 跨国互联网
     - 10-50 ms
     - 100-300 ms
     - 路由变化影响大
   * - 卫星链路
     - 20-100 ms
     - 200-500 ms
     - 高延迟 + 高抖动

监控与调试
==========

Chrome webrtc-internals
------------------------

在 Chrome 中访问 ``chrome://webrtc-internals``，可以看到：

- ``jitterBufferDelay``：Jitter Buffer 引入的延迟
- ``jitter``：RFC 3550 计算的抖动值
- ``packetsLost``：丢包数（高抖动常伴随丢包）

getStats() API
---------------

.. code-block:: javascript

   const stats = await peerConnection.getStats();
   stats.forEach(report => {
     if (report.type === 'inbound-rtp' && report.kind === 'audio') {
       console.log('Jitter:', report.jitter);
       console.log('JB Delay:', report.jitterBufferDelay);
       console.log('JB Emitted:', report.jitterBufferEmittedCount);
       // 平均 JB 延迟 = jitterBufferDelay / jitterBufferEmittedCount
     }
   });

小结
====

抖动是实时通信中不可避免的网络现象。理解它的成因和测量方法，是设计 Jitter Buffer、选择 FEC 策略、调优拥塞控制算法的基础。

后续章节将深入讲解音频和视频 Jitter Buffer 的设计，以及 WebRTC NetEQ 模块的实现。
