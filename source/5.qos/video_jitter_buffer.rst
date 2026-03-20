.. _video_jitter_buffer:

============================
视频 Jitter Buffer
============================

.. contents:: 目录
   :local:
   :depth: 2

概述
====

视频 Jitter Buffer 与音频 Jitter Buffer 的目标相同——吸收网络抖动，保证平滑播放——但面临的挑战截然不同：

- 视频帧**大小差异巨大**：I 帧可能是 P 帧的 10-50 倍
- 一个视频帧通常**跨多个 RTP 包**，需要全部到齐才能解码
- 视频帧之间有**依赖关系**：P/B 帧依赖参考帧
- 视频对**延迟的容忍度**比音频稍高，但对**帧完整性**要求更严格

.. mermaid::

   flowchart TD
     A[RTP 包到达] --> B[包排序 + 去重]
     B --> C[帧组装<br/>收集同一帧的所有包]
     C --> D{帧完整?}
     D -->|是| E[放入解码队列]
     D -->|否| F{超时?}
     F -->|否| C
     F -->|是| G[标记为不完整<br/>请求重传或丢弃]
     E --> H[解码器]
     H --> I[渲染队列<br/>按时间戳播放]

与音频 Jitter Buffer 的差异
============================

.. list-table::
   :header-rows: 1
   :widths: 25 35 35

   * - 特性
     - 音频 Jitter Buffer
     - 视频 Jitter Buffer
   * - 缓冲单位
     - 单个 RTP 包 = 1 帧
     - 多个 RTP 包 = 1 帧
   * - 帧大小
     - 固定（如 160 bytes/20ms）
     - 变化极大（1KB - 100KB+）
   * - 帧间依赖
     - 无（每帧独立）
     - 有（P→I, B→I/P）
   * - 丢帧影响
     - 20ms 静音/PLC
     - 画面冻结/花屏/级联丢帧
   * - 缓冲深度
     - 40-200 ms
     - 0-500 ms
   * - 时间拉伸
     - 支持（加速/减速播放）
     - 不支持（只能丢帧/重复帧）

帧组装（Frame Assembly）
=========================

视频帧组装是 Jitter Buffer 的第一步——将属于同一帧的多个 RTP 包拼接成完整帧。

RTP 标记位
-----------

RTP 头部的 **M（Marker）位** 标记帧的最后一个包：

.. code-block:: text

   帧 N:
     RTP seq=100, ts=90000, M=0  ← 帧的第 1 个包
     RTP seq=101, ts=90000, M=0  ← 帧的第 2 个包
     RTP seq=102, ts=90000, M=1  ← 帧的最后一个包（M=1）

   帧 N+1:
     RTP seq=103, ts=93000, M=0  ← 新帧开始（时间戳变化）
     RTP seq=104, ts=93000, M=1

组装逻辑：

1. 按 RTP 时间戳分组（相同时间戳 = 同一帧）
2. 按序列号排序
3. 检查完整性：从第一个包到 M=1 的包，序列号连续
4. 拼接 payload 得到完整的编码帧

帧完整性判断
-------------

.. code-block:: go

   type FrameBuffer struct {
       timestamp  uint32
       packets    map[uint16][]byte  // seq -> payload
       firstSeq   uint16
       lastSeq    uint16             // M=1 的包
       hasFirst   bool
       hasLast    bool
   }

   func (f *FrameBuffer) IsComplete() bool {
       if !f.hasFirst || !f.hasLast {
           return false
       }
       // 检查从 firstSeq 到 lastSeq 的所有包都已收到
       expected := f.lastSeq - f.firstSeq + 1
       return uint16(len(f.packets)) == expected
   }

帧依赖管理
===========

视频帧之间的依赖关系决定了丢帧的影响范围：

.. code-block:: text

   I ← P ← P ← P ← I ← P ← P ← P
   |   |   |   |   |   |   |   |
   如果这个 P 帧丢失 ──┘
   后续的 P 帧都无法正确解码 ──────┘

关键帧（I 帧）保护
--------------------

I 帧丢失的代价最高（后续所有帧都受影响），因此需要特殊保护：

1. **FEC 保护**：对 I 帧使用更强的 FEC（如 FlexFEC）
2. **NACK 重传**：I 帧的包丢失时优先重传
3. **PLI/FIR 请求**：如果 I 帧无法恢复，请求发送端生成新的 I 帧

.. code-block:: text

   接收端检测到关键帧丢失：
   1. 发送 NACK 请求重传丢失的包
   2. 等待重传（超时 ~RTT）
   3. 如果重传失败，发送 PLI（Picture Loss Indication）
   4. 发送端收到 PLI，在下一个编码机会生成 I 帧

解码顺序 vs 显示顺序
----------------------

当使用 B 帧时，解码顺序和显示顺序不同：

.. code-block:: text

   显示顺序: I0  B1  B2  P3  B4  B5  P6
   解码顺序: I0  P3  B1  B2  P6  B4  B5

   Jitter Buffer 需要按解码顺序输出帧给解码器，
   解码器输出后再按显示顺序排列给渲染器。

WebRTC 通常不使用 B 帧（增加延迟），但在 SVC 和某些 H.264 配置中可能出现。

自适应缓冲策略
===============

视频 Jitter Buffer 的深度需要动态调整：

最小缓冲
---------

.. code-block:: text

   min_buffer = max(jitter_estimate, decode_time, render_time)

   其中：
   - jitter_estimate: 网络抖动估计（如 P95 抖动）
   - decode_time: 解码一帧所需时间
   - render_time: 渲染延迟

目标延迟
---------

WebRTC 的视频 Jitter Buffer（VCMJitterEstimator）使用卡尔曼滤波器估计帧到达时间的抖动：

.. code-block:: text

   帧间延迟模型：
     d(i) = t(i) - t(i-1)        // 帧间到达时间差
     D(i) = T(i) - T(i-1)        // 帧间发送时间差
     delta(i) = d(i) - D(i)      // 传输延迟变化

   卡尔曼滤波器估计 delta 的分布，
   目标缓冲深度 = 均值 + k × 标准差（k 通常取 2-3）

丢帧策略
=========

当缓冲区溢出或延迟过大时，需要丢弃帧来降低延迟：

.. list-table::
   :header-rows: 1
   :widths: 25 35 40

   * - 策略
     - 方法
     - 影响
   * - 丢弃最旧帧
     - 丢弃缓冲区头部的帧
     - 可能丢弃参考帧，导致级联错误
   * - 丢弃非参考帧
     - 只丢弃不被其他帧引用的帧
     - 影响最小，但降低帧率
   * - 跳到最新 I 帧
     - 丢弃所有旧帧，从最新 I 帧开始
     - 画面跳跃，但快速恢复
   * - 请求新 I 帧
     - 发送 PLI + 清空缓冲区
     - 需要等待 RTT + 编码时间

WebRTC 中的实现
=================

WebRTC 的视频 Jitter Buffer 实现在 ``modules/video_coding/`` 目录下：

- ``frame_buffer2.cc``：帧缓冲区管理
- ``jitter_estimator.cc``：抖动估计（卡尔曼滤波）
- ``timing.cc``：渲染时间计算
- ``packet_buffer.cc``：RTP 包缓冲和帧组装

关键流程：

.. code-block:: text

   PacketBuffer::InsertPacket()
     → 包排序、帧组装
     → FrameBuffer::InsertFrame()
       → 检查帧依赖（参考帧是否已解码）
       → JitterEstimator::UpdateEstimate()
       → Timing::RenderTimeMs() 计算渲染时间
       → 帧可解码时通知解码线程

小结
====

视频 Jitter Buffer 比音频复杂得多——它不仅要处理抖动，还要处理帧组装、帧依赖、丢帧策略等问题。理解这些机制，对于调优视频通话质量和排查画面卡顿问题至关重要。
