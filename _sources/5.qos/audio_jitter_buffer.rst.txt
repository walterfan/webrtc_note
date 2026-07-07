.. _audio_jitter_buffer:

#####################
Jitter Buffer
#####################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Audio Jitter Buffer
**Authors**  Walter Fan
**Status**   v2
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
======================

在实时音视频通信中，抖动缓冲区（Jitter Buffer）是接收端最关键的组件之一。网络传输的不确定性导致 RTP 数据包到达时间不均匀，而音频播放器需要以恒定速率消费数据。Jitter Buffer 就是连接这两者的桥梁——它将网络的"不规则"转化为播放器的"规则"。

一个设计良好的 Jitter Buffer 需要在两个矛盾的目标之间取得平衡：

- **低延迟**：缓冲越少，端到端延迟越低，对话体验越好
- **低丢包**：缓冲越多，能容忍的网络抖动越大，丢包率越低

ITU-T G.114 建议单向延迟应低于 150ms 以获得可接受的对话体验。150ms 到 400ms 之间用户能感知到延迟但仍可接受，超过 600ms 则不可接受。


抖动的类型与度量
======================

抖动（Jitter）是由网络路径上的排队、争用和序列化效应引起的数据包传输延迟的变化。一般而言，在慢速或严重拥塞的链路上更可能发生更高级别的抖动。

抖动分类
--------------------

根据 ITU-T 的分类，抖动可分为三种类型：

**(i) A 类 – 恒定抖动（Constant Jitter）**

数据包到数据包通过网络传输延迟变化的大致恒定水平。这是最常见的抖动类型，通常由网络设备的固有处理延迟差异引起。

**(ii) B 类 – 瞬态抖动（Transient Jitter）**

以单个数据包可能引起的大量增量延迟为特征。通常由突发的网络事件引起，如路由器队列溢出。

**(iii) C 类 – 短期延迟变化（Short-term Delay Variation）**

特点是延迟的增加持续了一定数量的数据包，并且可能伴随着数据包到数据包延迟变化的增加。C 类抖动通常与拥塞和路由变化有关。

抖动度量
--------------------

RFC 3550 定义了 RTP 抖动的计算方法——基于相邻包的到达间隔差异：

.. code-block:: text

   D(i,j) = (Rj - Ri) - (Sj - Si)

   其中：
   - Ri, Rj: 包 i 和包 j 的接收时间
   - Si, Sj: 包 i 和包 j 的发送时间（RTP timestamp）

   抖动的指数加权移动平均：
   J(i) = J(i-1) + (|D(i-1,i)| - J(i-1)) / 16

常用的抖动度量指标包括：

.. list-table:: 抖动度量指标
   :header-rows: 1
   :widths: 25 75

   * - 指标
     - 说明
   * - Mean Jitter
     - 平均抖动，反映整体网络稳定性
   * - Max Jitter
     - 最大抖动，决定缓冲区的最小容量
   * - Jitter Percentile (P95/P99)
     - 百分位抖动，用于自适应算法的目标延迟计算
   * - Inter-arrival Jitter (RFC 3550)
     - RTCP SR/RR 中报告的抖动值


抖动缓冲区的工作原理
============================

网络以异步方式传递 RTP 数据包，延迟各不相同。为了以合理的质量播放音频流，接收端需要将可变延迟转换为恒定延迟。

基本工作流程
--------------------

.. code-block:: text

   发送端                    网络                     接收端
   ┌──────┐                                    ┌──────────────┐
   │ 编码 │──→ [P1] ──→ ···延迟 20ms··· ──→   │              │
   │      │──→ [P2] ──→ ···延迟 35ms··· ──→   │ Jitter       │ ──→ 解码 ──→ 播放
   │      │──→ [P3] ──→ ···延迟 15ms··· ──→   │ Buffer       │
   │      │──→ [P4] ──→ ···延迟 50ms··· ──→   │              │
   └──────┘                                    └──────────────┘

   时间轴示意（20ms 帧间隔）：

   发送时刻:  |--P1--|--P2--|--P3--|--P4--|--P5--|--P6--|
              0     20     40     60     80    100    120 ms

   到达时刻:  |P1|    |P3| |P2|        |P4|  |P5||P6|
              20      55   60          110   120 125 ms
              (乱序、间隔不均匀)

   播放时刻:  |--P1--|--P2--|--P3--|--P4--|--P5--|--P6--|
              80    100    120    140    160    180    200 ms
              (经过 Jitter Buffer 重排后，均匀播放)

核心功能
--------------------

Jitter Buffer 的核心功能包括：

1. **吸收到达时间变化**：缓冲数据包，将不规则的到达转化为规则的播放
2. **数据包重排序**：将乱序到达的包按序列号重新排列
3. **流同步**：延迟一个流以匹配另一个流的播放（如音视频唇同步）
4. **延迟首包解码**：等待足够的缓冲后再开始播放
5. **判定丢包**：确定哪些包已丢失，触发丢包隐藏（PLC）
6. **去重**：丢弃重复到达的数据包


固定抖动缓冲区 vs 自适应抖动缓冲区
==========================================

固定抖动缓冲区（Fixed Jitter Buffer）
------------------------------------------

固定抖动缓冲区使用预设的固定延迟值：

- 延迟固定不变
- 不需要计算抖动统计信息
- 实现简单
- 当抖动变化较大时，语音质量会受到影响

示例配置：

.. code-block:: text

   缓冲区最大容量 = 100ms
   播放延迟 = 40ms（缓冲区中至少有 40ms 数据时开始播放）

自适应抖动缓冲区（Adaptive Jitter Buffer）
----------------------------------------------

自适应抖动缓冲区根据实时网络状况动态调整延迟：

- 延迟根据抖动实时变化动态调整
- 关键技术：时间缩放（Time Scaling）——在不影响语音质量的前提下调整播放时间

  - 对语音包进行缩放（加速/减速播放）
  - 对静音包进行缩放（拉伸/压缩静音段）

- 实现复杂度较高
- 使用良好的时间缩放算法，语音质量不会受到大幅抖动变化的影响

.. list-table:: 固定 vs 自适应 Jitter Buffer 对比
   :header-rows: 1
   :widths: 20 40 40

   * - 特性
     - 固定 Jitter Buffer
     - 自适应 Jitter Buffer
   * - 延迟
     - 固定，可能偏高
     - 动态调整，通常更低
   * - 实现复杂度
     - 低
     - 高
   * - 网络适应性
     - 差
     - 好
   * - 语音质量
     - 稳定网络下好
     - 各种网络下都较好
   * - 适用场景
     - 网络稳定的局域网
     - 互联网、移动网络


自适应抖动缓冲区算法
============================

自适应 Jitter Buffer 的核心是 **目标延迟估计** （Target Delay Estimation），即动态计算最优的缓冲延迟。

直方图法（Histogram-based）
---------------------------------

WebRTC 的 NetEQ 使用直方图法来估计目标延迟：

1. 维护一个到达间隔时间（IAT）的直方图
2. 每收到一个包，更新直方图
3. 根据直方图的某个百分位（如 95th percentile）确定目标延迟
4. 目标延迟 = 使得 95% 的包能在播放前到达的最小缓冲时间

.. code-block:: text

   IAT 直方图示例：

   频率
   │
   │     ██
   │    ████
   │   ██████
   │  ████████
   │ ██████████
   │████████████  ██
   └──────────────────→ 到达间隔 (ms)
    15 20 25 30 35 40 45 50

   P95 = 40ms → 目标延迟 = 40ms

指数加权移动平均法（EWMA）
---------------------------------

另一种常用方法是使用 EWMA 来平滑抖动估计：

.. code-block:: text

   jitter_estimate = α * |actual_delay - expected_delay| + (1 - α) * jitter_estimate
   target_delay = mean_delay + k * jitter_estimate

   其中：
   - α: 平滑因子（通常 0.01 ~ 0.1）
   - k: 安全系数（通常 2 ~ 4，对应不同的丢包容忍度）

峰值检测法
---------------------------------

对于突发抖动（B 类），需要特殊处理：

1. 检测到达间隔的突变（超过阈值的跳变）
2. 区分是持续性变化还是瞬态峰值
3. 对瞬态峰值使用更快的衰减，避免不必要的延迟增加


WebRTC NetEQ 中的 Jitter Buffer
==========================================

NetEQ 是 WebRTC 中负责音频接收端处理的核心模块，其中的 Jitter Buffer 实现是业界最成熟的自适应方案之一。

核心组件
--------------------

.. list-table:: NetEQ 核心类
   :header-rows: 1
   :widths: 30 70

   * - 类名
     - 职责
   * - ``PacketBuffer``
     - 存储接收到的 RTP 包，按时间戳排序
   * - ``DelayManager``
     - 管理目标延迟的计算，维护 IAT 直方图
   * - ``DecisionLogic``
     - 根据缓冲区状态决定播放策略（正常/加速/减速/丢包隐藏）
   * - ``Accelerate``
     - 加速播放算法，通过丢弃部分样本缩短音频
   * - ``PreemptiveExpand``
     - 减速播放算法，通过插入样本拉长音频
   * - ``Expand``
     - 丢包隐藏（PLC），生成替代音频
   * - ``Merge``
     - 将 PLC 生成的音频与真实音频平滑过渡
   * - ``Normal``
     - 正常播放模式

播放决策逻辑
--------------------

NetEQ 的 ``DecisionLogic`` 在每个 10ms 帧周期做出以下决策：

.. code-block:: text

   if (buffer_level > target_delay + threshold):
       → Accelerate（加速播放，降低缓冲区水位）
   elif (buffer_level < target_delay - threshold):
       if (next_packet_available):
           → PreemptiveExpand（减速播放，等待更多包到达）
       else:
           → Expand（丢包隐藏，生成替代音频）
   elif (next_packet_available):
       → Normal（正常解码播放）
   else:
       → Expand（丢包隐藏）

加速与减速播放
--------------------

**加速播放（Accelerate）**：当缓冲区水位过高时，通过 WSOLA（Waveform Similarity Overlap-Add）算法丢弃部分音频样本，在不改变音调的前提下缩短播放时间。

**减速播放（PreemptiveExpand）**：当缓冲区水位过低时，通过 WSOLA 算法插入重复的音频样本，拉长播放时间以等待更多包到达。

WSOLA 的关键是找到波形相似的位置进行拼接，避免产生可听的失真：

.. code-block:: text

   原始波形:  ~~~∧~~~∨~~~∧~~~∨~~~∧~~~∨~~~
   加速后:    ~~~∧~~~∨~~~~~~~∨~~~∧~~~∨~~~  (去掉一个周期)
   减速后:    ~~~∧~~~∨~~~∧~~~∧~~~∨~~~∧~~~∨~~~  (重复一个周期)


关键参数与调优
============================

.. list-table:: Jitter Buffer 关键参数
   :header-rows: 1
   :widths: 25 15 60

   * - 参数
     - 典型值
     - 说明
   * - ``min_delay``
     - 0 ms
     - 最小缓冲延迟，设为 0 表示由算法自动决定
   * - ``max_delay``
     - 500 ms
     - 最大缓冲延迟上限，防止延迟无限增长
   * - ``target_delay``
     - 动态
     - 由 DelayManager 根据网络状况动态计算
   * - ``histogram_quantile``
     - 0.95
     - IAT 直方图的百分位，用于计算目标延迟
   * - ``max_packets_in_buffer``
     - 200
     - 缓冲区最大包数，防止内存溢出
   * - ``accelerate_threshold``
     - 2 帧
     - 缓冲区水位超过目标延迟多少帧时触发加速
   * - ``preemptive_expand_threshold``
     - 1 帧
     - 缓冲区水位低于目标延迟多少帧时触发减速
   * - ``peak_detection``
     - 开启
     - 是否启用峰值检测以处理突发抖动

调优建议
--------------------

- **低延迟场景** （如游戏语音）：降低 ``histogram_quantile`` 到 0.90，接受更高的丢包率换取更低延迟
- **高质量场景** （如音乐直播）：提高 ``histogram_quantile`` 到 0.99，增加缓冲以减少丢包
- **移动网络**：适当增大 ``max_delay``，因为移动网络抖动通常更大
- **WiFi 网络**：注意 WiFi 的突发抖动特性，确保峰值检测开启


性能指标
============================

评估 Jitter Buffer 性能的关键指标：

.. list-table:: 性能指标
   :header-rows: 1
   :widths: 30 70

   * - 指标
     - 说明
   * - Buffer Delay
     - 当前缓冲延迟（ms），反映实时延迟水平
   * - Target Delay
     - 目标缓冲延迟（ms），算法计算的最优值
   * - Concealment Rate
     - 丢包隐藏比率（%），反映丢包对音质的影响
   * - Accelerate Rate
     - 加速播放比率（%），过高说明缓冲区经常过满
   * - Decelerate Rate
     - 减速播放比率（%），过高说明缓冲区经常过空
   * - Packet Loss Rate
     - 丢包率（%），包括网络丢包和缓冲区溢出丢包
   * - Late Packet Rate
     - 迟到包比率（%），到达时已过播放时间的包
   * - Reorder Rate
     - 乱序率（%），需要重排序的包比例

在 WebRTC 中，这些指标可通过 ``getStats()`` API 获取：

.. code-block:: javascript

   const stats = await peerConnection.getStats();
   stats.forEach(report => {
     if (report.type === 'inbound-rtp' && report.kind === 'audio') {
       console.log('Jitter Buffer Delay:', report.jitterBufferDelay);
       console.log('Jitter Buffer Target Delay:', report.jitterBufferTargetDelay);
       console.log('Concealed Samples:', report.concealedSamples);
       console.log('Total Samples Received:', report.totalSamplesReceived);
       console.log('Concealment Rate:',
         report.concealedSamples / report.totalSamplesReceived * 100, '%');
     }
   });


实现示例
============================

以下是一个简化的自适应 Jitter Buffer 伪代码：

.. code-block:: cpp

   class AdaptiveJitterBuffer {
   public:
       // 插入收到的 RTP 包
       void InsertPacket(const RtpPacket& packet) {
           uint32_t seq = packet.sequence_number();
           uint32_t ts = packet.timestamp();

           // 计算到达间隔
           if (last_arrival_time_ > 0) {
               int64_t arrival_delta = now_ms() - last_arrival_time_;
               int64_t send_delta = (ts - last_timestamp_) / sample_rate_hz_ * 1000;
               int64_t iat = arrival_delta - send_delta;  // 到达间隔偏差
               UpdateHistogram(iat);
               UpdateTargetDelay();
           }
           last_arrival_time_ = now_ms();
           last_timestamp_ = ts;

           // 按时间戳排序插入缓冲区
           buffer_.Insert(packet);
       }

       // 获取下一帧用于播放
       PlayoutDecision GetNextFrame(AudioFrame* frame) {
           int buffer_level = buffer_.BufferLevel();

           if (buffer_level > target_delay_ + accelerate_threshold_) {
               // 缓冲区过满，加速播放
               return Accelerate(frame);
           } else if (buffer_level < target_delay_ - preemptive_threshold_) {
               if (buffer_.HasNextPacket()) {
                   return PreemptiveExpand(frame);  // 减速播放
               } else {
                   return Expand(frame);  // 丢包隐藏
               }
           } else if (buffer_.HasNextPacket()) {
               return Normal(frame);  // 正常播放
           } else {
               return Expand(frame);  // 丢包隐藏
           }
       }

   private:
       void UpdateHistogram(int64_t iat) {
           // 更新 IAT 直方图
           int bucket = iat / bucket_size_ms_;
           histogram_[bucket]++;
           total_count_++;

           // 老化：降低旧数据的权重
           if (total_count_ > max_count_) {
               for (auto& [k, v] : histogram_) {
                   v = v * decay_factor_;
               }
               total_count_ *= decay_factor_;
           }
       }

       void UpdateTargetDelay() {
           // 根据直方图的 P95 计算目标延迟
           int cumulative = 0;
           int threshold = total_count_ * quantile_;  // quantile_ = 0.95
           for (auto& [bucket, count] : histogram_) {
               cumulative += count;
               if (cumulative >= threshold) {
                   target_delay_ = bucket * bucket_size_ms_;
                   break;
               }
           }
           // 限制在 [min_delay_, max_delay_] 范围内
           target_delay_ = std::clamp(target_delay_, min_delay_, max_delay_);
       }

       PacketBuffer buffer_;
       std::map<int, int> histogram_;
       int target_delay_ = 60;       // ms
       int min_delay_ = 0;           // ms
       int max_delay_ = 500;         // ms
       int accelerate_threshold_ = 20; // ms
       int preemptive_threshold_ = 10; // ms
       double quantile_ = 0.95;
       double decay_factor_ = 0.998;
       int64_t last_arrival_time_ = 0;
       uint32_t last_timestamp_ = 0;
       int sample_rate_hz_ = 48000;
       int total_count_ = 0;
       int max_count_ = 1000;
       int bucket_size_ms_ = 5;
   };


常见问题与解决方案
============================

.. list-table:: 常见问题排查
   :header-rows: 1
   :widths: 25 35 40

   * - 问题
     - 可能原因
     - 解决方案
   * - 延迟过高
     - 目标延迟设置过大；网络抖动持续偏高
     - 降低 ``max_delay``；检查网络质量；降低 ``histogram_quantile``
   * - 音频断续/卡顿
     - 缓冲区过小；丢包率过高
     - 增大 ``max_delay``；检查网络丢包；启用 FEC
   * - 咔嗒声/爆音
     - PLC 算法质量差；加速/减速拼接不平滑
     - 使用 WSOLA 算法；增加交叉淡入淡出
   * - 单向音频
     - 缓冲区溢出；时间戳不连续
     - 检查 RTP 时间戳；增大缓冲区容量
   * - 音调变化
     - 时间缩放算法不当
     - 使用基于基频的 WSOLA；避免简单的样本丢弃/重复
   * - 缓冲区持续增长
     - 发送端时钟漂移；采样率不匹配
     - 检查时钟同步；确认编解码器采样率一致


实现 Jitter Buffer 的步骤
============================

总结实现一个音频 Jitter Buffer 的关键步骤：

1. **理解抖动概念**：抖动是由于网络拥塞、丢包或其他因素导致的音频包到达时间的变化。

2. **设计缓冲区结构**：通常使用按时间戳排序的优先队列或有序映射。

3. **设置缓冲区大小**：根据需求确定合适的缓冲区大小，较大的缓冲区可以处理更大的抖动变化，但会引入额外延迟。

4. **接收和存储包**：按序列号或时间戳存储到缓冲区，正确处理乱序包。

5. **估计播放时间**：使用接收包的时间戳估计每个包的播放时间。

6. **调度包播放**：根据估计的播放时间启动播放定时器。

7. **处理迟到或丢失的包**：使用插值、外推或丢包隐藏技术。

8. **动态调整缓冲区大小**：监控网络状况，动态调整缓冲区大小。

9. **持续更新缓冲区**：定期移除已播放的包，添加新到达的包。

10. **实现错误恢复机制**：考虑 FEC 或重传等额外的错误恢复机制。

11. **测试和优化**：在各种网络条件下测试，调优缓冲区大小、播放时间和错误恢复参数。


参考资料
============================

- RFC 3550: RTP: A Transport Protocol for Real-Time Applications
- RFC 3551: RTP Profile for Audio and Video Conferences
- ITU-T G.114: One-way transmission time
- ITU-T G.131: Talker echo and its control
- WebRTC NetEQ 源码: ``modules/audio_coding/neteq/``
- WebRTC DelayManager: ``modules/audio_coding/neteq/delay_manager.cc``
- WebRTC DecisionLogic: ``modules/audio_coding/neteq/decision_logic.cc``
- `Adaptive Playout Mechanisms for VoIP <https://ieeexplore.ieee.org/document/1498486>`_
- `The Effect of Jitter Buffer Algorithms on VoIP Quality <https://dl.acm.org/doi/10.1145/1031607.1031612>`_
