.. _network_resilience:

================================
综合抗弱网策略
================================

.. contents:: 目录
   :local:
   :depth: 2

概述
====

实时通信中的网络问题从来不是单一的——丢包、抖动、延迟、带宽不足往往同时出现。单独使用 FEC、NACK 或 Jitter Buffer 都不够，需要多种机制**协同工作**才能在弱网环境下维持可接受的通话质量。

本节讨论如何将前面章节介绍的各种 QoS 技术组合成一个完整的抗弱网策略。

抗弱网技术栈
=============

.. mermaid::

   flowchart TD
     subgraph 发送端
       A[编码器] --> B[码率自适应<br/>根据 CC 调整]
       B --> C[FEC 编码<br/>冗余保护]
       C --> D[Pacer<br/>平滑发送]
     end

     subgraph 网络
       D --> E[丢包/抖动/延迟]
     end

     subgraph 接收端
       E --> F[NACK<br/>请求重传]
       E --> G[FEC 解码<br/>恢复丢包]
       F --> H[Jitter Buffer<br/>吸收抖动]
       G --> H
       H --> I[PLC<br/>丢包隐藏]
       I --> J[解码器]
       J --> K[播放]
     end

     subgraph 反馈环路
       F -.->|NACK| D
       H -.->|RTCP RR/REMB/TWCC| A
     end

各层防线
---------

.. list-table::
   :header-rows: 1
   :widths: 10 20 25 20 25

   * - 层级
     - 技术
     - 作用
     - 延迟代价
     - 带宽代价
   * - 1
     - 码率自适应
     - 避免拥塞
     - 无
     - 降低码率
   * - 2
     - FEC
     - 前向恢复丢包
     - 无额外延迟
     - 10-100% 冗余
   * - 3
     - NACK/RTX
     - 重传恢复丢包
     - +1 RTT
     - 重传包
   * - 4
     - Jitter Buffer
     - 吸收抖动
     - +40-200ms
     - 无
   * - 5
     - PLC
     - 隐藏残余丢包
     - 无
     - 无

FEC 与 NACK 的配合
====================

FEC 和 NACK 不是互斥的，而是互补的：

.. code-block:: text

   场景分析：

   低延迟 + 低丢包（RTT < 100ms, loss < 5%）：
     → NACK 为主，FEC 为辅
     → NACK 能在 1 RTT 内恢复，FEC 处理 NACK 来不及的情况

   高延迟 + 中丢包（RTT > 200ms, loss 5-15%）：
     → FEC 为主，NACK 为辅
     → RTT 太高，NACK 重传可能来不及播放
     → FEC 无额外延迟，更适合

   高丢包（loss > 15%）：
     → 强 FEC + NACK + 降码率
     → 需要大量冗余，同时降低源码率腾出带宽

   突发丢包（burst loss）：
     → FEC 效果差（连续丢包可能把 FEC 包也丢了）
     → NACK + 交织（interleaving）更有效

WebRTC 的策略
--------------

WebRTC 中音频和视频使用不同的策略：

**音频**：

- Opus in-band FEC（默认开启）
- RED 冗余（RFC 2198）
- NACK 通常不用于音频（延迟敏感）
- NetEQ PLC 作为最后防线

**视频**：

- NACK/RTX 为主（视频帧大，FEC 开销高）
- FlexFEC 或 ULP-FEC 保护关键帧
- PLI/FIR 请求新关键帧
- 冻结最后一帧作为 PLC

码率自适应策略
===============

拥塞控制（GCC/REMB/TWCC）估计可用带宽后，编码器需要决定如何分配：

.. code-block:: text

   可用带宽 = 估计带宽 × 安全系数（0.85-0.95）

   分配优先级：
   1. 音频编码（固定，如 32 kbps）
   2. 视频 FEC（根据丢包率动态调整）
   3. 视频编码（剩余带宽）

   视频码率 = 可用带宽 - 音频码率 - FEC 开销

   FEC 冗余率根据丢包率调整：
   - 丢包 < 2%:  FEC = 0%（关闭）
   - 丢包 2-5%:  FEC = 10-20%
   - 丢包 5-10%: FEC = 20-50%
   - 丢包 > 10%: FEC = 50-100%

降级策略
---------

当带宽严重不足时，按优先级降级：

.. code-block:: text

   1. 降低视频分辨率（1080p → 720p → 480p → 360p）
   2. 降低视频帧率（30fps → 15fps → 7fps）
   3. 关闭视频，只保留音频
   4. 降低音频码率（32kbps → 16kbps → 8kbps）
   5. 切换到窄带模式

Jitter Buffer 与 FEC/NACK 的联动
==================================

Jitter Buffer 的目标延迟需要考虑 NACK 重传的时间：

.. code-block:: text

   如果启用 NACK：
     JB 目标延迟 >= RTT + 处理时间
     这样 NACK 重传的包有机会在播放前到达

   如果只用 FEC：
     JB 目标延迟 = 抖动估计值
     不需要额外等待重传

   实际中：
     JB 目标延迟 = max(抖动估计, NACK 等待时间)

弱网场景实战
=============

场景 1：WiFi 环境（抖动大，偶发丢包）
---------------------------------------

.. code-block:: text

   特征：RTT 20-50ms, 丢包 1-5%, 抖动 20-100ms
   策略：
   - 音频：Opus FEC 开启，JB 自适应（60-150ms）
   - 视频：NACK 为主，关键帧 FEC 保护
   - CC：TWCC，快速响应带宽变化

场景 2：4G 移动网络（延迟中等，丢包波动）
-------------------------------------------

.. code-block:: text

   特征：RTT 50-150ms, 丢包 2-10%, 抖动 30-150ms
   策略：
   - 音频：Opus FEC + RED 双重保护
   - 视频：FEC + NACK 混合，FEC 比重增加
   - CC：GCC，保守估计带宽
   - 降级：准备降分辨率和帧率

场景 3：跨国通话（高延迟）
---------------------------

.. code-block:: text

   特征：RTT 200-400ms, 丢包 1-3%, 抖动 50-200ms
   策略：
   - 音频：Opus FEC 为主（NACK 来不及）
   - 视频：FEC 为主，NACK 仅用于关键帧
   - JB：较大的目标延迟（200-300ms）
   - CC：保守模式，避免过度探测

场景 4：极端弱网（高丢包 + 高抖动）
-------------------------------------

.. code-block:: text

   特征：RTT 100-300ms, 丢包 15-30%, 抖动 100-500ms
   策略：
   - 关闭视频，只保留音频
   - 音频：Opus 8kbps + 强 FEC（100% 冗余）
   - JB：大缓冲（300-500ms），接受高延迟
   - PLC：频繁触发，质量下降但保持连通

监控指标
========

综合抗弱网策略需要监控以下指标：

.. list-table::
   :header-rows: 1
   :widths: 25 35 40

   * - 指标
     - 含义
     - 告警阈值
   * - RTT
     - 往返延迟
     - > 300ms
   * - Packet Loss Rate
     - 丢包率
     - > 5%
   * - Jitter
     - 网络抖动
     - > 50ms
   * - FEC Recovery Rate
     - FEC 恢复成功率
     - < 80%
   * - NACK Rate
     - NACK 请求频率
     - > 10 次/秒
   * - PLC Rate
     - PLC 触发率
     - > 3%
   * - JB Delay
     - Jitter Buffer 延迟
     - > 200ms
   * - Encode Bitrate
     - 编码码率
     - 持续低于最低可用值
   * - Frame Drop Rate
     - 视频丢帧率
     - > 5%

小结
====

抗弱网不是单一技术能解决的问题，而是一个**系统工程**：

1. **预防**：码率自适应避免拥塞
2. **冗余**：FEC 提前准备恢复数据
3. **补救**：NACK 重传丢失的包
4. **缓冲**：Jitter Buffer 吸收抖动
5. **兜底**：PLC 隐藏无法恢复的丢包

这五层防线需要协同工作，根据网络状况动态调整各自的参数。好的实时通信系统，就是在延迟、质量和可靠性之间找到最佳平衡点。
