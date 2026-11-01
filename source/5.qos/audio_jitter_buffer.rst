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
**Status**   v3
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
======================

在实时音视频通信中，抖动缓冲区（Jitter Buffer）是接收端最关键的组件之一。网络传输的不确定性导致 RTP 数据包到达时间不均匀，而音频播放器需要以恒定速率消费数据。Jitter Buffer 就是连接这两者的桥梁——它将网络的"不规则"转化为播放器的"规则"。

一个设计良好的 Jitter Buffer 需要在两个矛盾的目标之间取得平衡：

- **低延迟**\ ：缓冲越少，端到端延迟越低，对话体验越好
- **低丢包**\ ：缓冲越多，能容忍的网络抖动越大，丢包率越低

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
   - Si, Sj: 包 i 和包 j 的媒体采样时刻（RTP timestamp）

   抖动的指数加权移动平均：
   J(i) = J(i-1) + (|D(i-1,i)| - J(i-1)) / 16

这里的 RTP timestamp 表示媒体采样时刻，不是网络发送时刻；计算时必须将
接收时间与 RTP timestamp 转成相同单位，并处理 timestamp 回绕。
例如 Opus 的 RTP 时钟为 48 kHz，960 ticks 对应 20 ms。
RFC 3550 的 ``J`` 是平滑后的到达间隔偏差，不等于应该设置的播放缓冲时长。

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

.. mermaid::

   flowchart LR
     Enc[编码] --> P1["P1 延迟 20ms"]
     Enc --> P2["P2 延迟 35ms"]
     Enc --> P3["P3 延迟 15ms"]
     Enc --> P4["P4 延迟 50ms"]
     P1 --> JB[Jitter Buffer]
     P2 --> JB
     P3 --> JB
     P4 --> JB
     JB --> Dec[解码]
     Dec --> Play[播放]

.. mermaid::

   sequenceDiagram
     participant S as 发送端
     participant J as Jitter Buffer
     participant P as 播放
     S->>J: P1 发送 0ms / 到达 20ms
     S->>J: P2 发送 20ms / 到达 60ms
     S->>J: P3 发送 40ms / 到达 55ms
     S->>J: P4 发送 60ms / 到达 110ms
     Note over J: 乱序、间隔不均匀
     J->>P: P1 播放 80ms
     J->>P: P2 播放 100ms
     J->>P: P3 播放 120ms
     J->>P: P4 播放 140ms
     Note over P: 重排后均匀播放

核心功能
--------------------

Jitter Buffer 的核心功能包括：

1. **吸收到达时间变化**\ ：缓冲数据包，将不规则的到达转化为规则的播放
2. **数据包重排序**\ ：将乱序到达的包按序列号重新排列
3. **流同步**\ ：延迟一个流以匹配另一个流的播放（如音视频唇同步）
4. **延迟首包解码**\ ：等待足够的缓冲后再开始播放
5. **判定丢包**\ ：确定哪些包已丢失，触发丢包隐藏（PLC）
6. **去重**\ ：丢弃重复到达的数据包


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

直方图法统计相对于媒体进度的到达延迟，而不是直接把消息间隔当作缓冲目标：

1. 把接收时间和媒体时间转换成同一时间单位，计算相对到达延迟
2. 用有限窗口或衰减直方图维护分布，必要时统计一个区间内的峰值
3. 取某个百分位作为候选目标，再施加上下限及重排等约束
4. 用实际迟到率、欠载率验证候选值，百分位本身不保证未来所有播放区间的连续性

可参考 WebRTC 的
`UnderrunOptimizer <https://raw.githubusercontent.com/webrtc-mirror/webrtc/main/modules/audio_coding/neteq/underrun_optimizer.cc>`_
和 `DelayManager <https://raw.githubusercontent.com/webrtc-mirror/webrtc/main/modules/audio_coding/neteq/delay_manager.cc>`_。
具体参数和实现随版本变化；下面的分布仅用于说明百分位的含义。

.. code-block:: text

   相对到达延迟直方图示例：

   频率
   │
   │     ██
   │    ████
   │   ██████
   │  ████████
   │ ██████████
   │████████████  ██
   └──────────────────→ 相对到达延迟 (ms)
    15 20 25 30 35 40 45 50

   P95 = 40ms → 候选目标延迟约 40ms，再施加边界及安全余量

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
     - 协调欠载和重排优化器，估计目标延迟
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

**加速播放（Accelerate）**\ ：当缓冲区水位过高时，通过 WSOLA（Waveform Similarity Overlap-Add）算法丢弃部分音频样本，在不改变音调的前提下缩短播放时间。

**减速播放（PreemptiveExpand）**\ ：当缓冲区水位过低时，通过 WSOLA 算法插入重复的音频样本，拉长播放时间以等待更多包到达。

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
     - 延迟分布的百分位，用于计算候选目标延迟
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
- **移动网络**\ ：适当增大 ``max_delay``\ ，因为移动网络抖动通常更大
- **WiFi 网络**\ ：注意 WiFi 的突发抖动特性，确保峰值检测开启


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

上表是通用观测指标，WebRTC 的 ``getStats()`` 提供其中部分指标及累计计数。
按照 `WebRTC Statistics 规范 <https://www.w3.org/TR/webrtc-stats/#dom-rtcinboundrtpstreamstats-jitterbufferdelay>`_，
``jitterBufferDelay`` 与 ``jitterBufferTargetDelay`` 都是以秒计的累计值，
需要除以 ``jitterBufferEmittedCount`` 才得到平均延迟。下面输出从统计起点开始的平均值：

.. code-block:: javascript

   try {
     const stats = await peerConnection.getStats();
     stats.forEach(report => {
       if (report.type !== 'inbound-rtp' || report.kind !== 'audio') return;
       const count = report.jitterBufferEmittedCount;
       if (count > 0 && Number.isFinite(report.jitterBufferDelay)) {
         console.log('Mean buffer delay (ms):',
           1000 * report.jitterBufferDelay / count);
       }
       if (count > 0 && Number.isFinite(report.jitterBufferTargetDelay)) {
         console.log('Mean target delay (ms):',
           1000 * report.jitterBufferTargetDelay / count);
       }
       if (report.totalSamplesReceived > 0 &&
           Number.isFinite(report.concealedSamples)) {
         console.log('Concealment rate (%):',
           100 * report.concealedSamples / report.totalSamplesReceived);
       }
     });
   } catch {
     console.error('Audio statistics unavailable');
   }

观察最近一个采样区间时，应对同一个 stats ID 的累计值作差，例如
``1000 * delta(jitterBufferDelay) / delta(jitterBufferEmittedCount)``。
分母为零、字段不支持或计数重置时跳过该区间。WebSocket TTS 的自建队列不会自动出现在
``RTCPeerConnection.getStats()`` 中，需要使用后文的客户端埋点。


实现示例：RTP 的播放截止时间
==========================================

对于 RTP，需要按扩展后的序列号/媒体时间戳存包，并按媒体时间线播放。
下面只展示固定目标延迟下的核心循环；解码、FEC、PLC 和时间缩放应由成熟的媒体模块完成。

.. code-block:: text

   on_validated_rtp(packet, arrival_ms):
       # 先校验 SSRC、payload type、长度、时间戳跳变及队列容量
       seq, ts = unwrap_with_bounded_reorder_window(packet)
       if duplicate(seq):
           return
       if next_play_ts is set and packet_end(ts) <= next_play_ts:
           return
       packets.insert_bounded(seq, ts, packet)

   start_playout(first_ts, first_arrival_ms):
       media_origin = first_ts
       wall_origin_ms = first_arrival_ms + target_delay_ms
       next_play_ts = first_ts

   on_audio_deadline(now_ms):
       deadline_ms = wall_origin_ms + 1000.0 * (
           next_play_ts - media_origin) / rtp_clock_rate
       if now_ms < deadline_ms:
           return                         # 尚未到当前媒体帧的截止时间
       frame = decode_next_frame_or_fec(packets, next_play_ts)
       if frame is missing:
           frame = plc_one_frame()        # 截止时间到了就推进，不无限等包
       output(frame)
       next_play_ts += frame_duration_in_rtp_ticks

``next_play_ts`` 在启动前应标记为未设置，此时只存包、不做迟到判断。
即使当前包缺失也要推进播放时间线；迟到包不能让已播放的时间线倒退。
目标延迟的变化需要重新规划播放或使用时间缩放，不能只修改一个数字就期望缓冲自动增加。


实战：WebSocket 接收 TTS 音频并连续播放
================================================

TTS 链路应拆成：**生成 → 发送 → 接收 → 解码/转换 → PCM 队列 → 音频设备输出**。
下面以一条 WebSocket over TCP 连接上的单个 TTS turn 为例。
根据 `RFC 6455 <https://www.rfc-editor.org/rfc/rfc6455#section-1.2>`_，
WebSocket 建立在 TCP 上，连接内的数据按序交付。
TCP 重传和队头阻塞会表现为一段时间没有消息，随后连续收到多个消息。
此时主要任务是平滑供给、限制积压和处理断流，而不是重排网络包。

先确定播放策略
----------------------------

.. list-table:: RTP 与 TTS 播放策略
   :header-rows: 1
   :widths: 25 35 40

   * - 问题
     - 实时 RTP
     - 本例的 WebSocket TTS
   * - 缺少下一段音频
     - 到截止时间后 PLC，媒体时间继续推进
     - 输出短暂静音并重新蓄水，保留随后到达的完整语音
   * - 迟到数据
     - 过了播放截止时间通常丢弃
     - 同一 turn 的后续内容仍要播放，不能按网络迟到直接丢弃
   * - 缓冲过多
     - 可通过时间缩放降低实时延迟
     - 优先背压；随意丢 chunk 会丢字，直接改采样率会变调
   * - 用户打断
     - 按媒体会话策略处理
     - 取消旧 turn，清空尚未输出的音频，拒绝旧请求的异步结果

本例选择 **内容完整优先**：欠载时暂停媒体进度，设备时钟仍前进。
如果业务要求严格跟随实时墙钟，应另行定义过期内容丢弃规则，不能混用这两种策略。

协议：音频时间戳与发送时间分开
--------------------------------------------

协议先协商格式，再传输有界的二进制音频消息。一个 chunk 可以是 10、20、40 ms，
也可以长度不固定；播放算法按采样帧数计算，不能假定“一包就是一次设备回调”。
这里的一个 sample frame 包含所有声道在同一采样时刻的样本。

.. code-block:: text

   START:
       request_id, format = pcm_s16le, sample_rate = 24000, channels = 1
   AUDIO:
       request_id, seq, sample_start, frame_count, payload
       # seq 从 0 递增；sample_start 是本 turn 内第一帧的偏移
       # 可选 server_generated_mono_ms、server_send_mono_ms，仅用于服务端追踪
   END:
       request_id, next_seq, total_frames
       # 结束标记与 AUDIO 共用有序通道，必须在最后一个 AUDIO 后发送
   CREDIT:
       request_id, credit_until_frame
       # 接收端授予的累计可发送媒体范围，后文解释
   CANCEL:
       request_id

24 kHz、16-bit、单声道、20 ms PCM 的换算：

.. code-block:: text

   frame_count = 24000 * 20 / 1000 = 480 frames
   payload_bytes = 480 * 1 * 2 = 960 bytes
   duration_ms = 1000.0 * frame_count / sample_rate
   ready_ms = 1000.0 * unread_pcm_frames / sample_rate

``sample_start`` 是媒体位置，不是服务端发送时间；两端不需要时钟同步就能检查媒体连续性。
压缩音频不能按字节数推算时长：应先按编解码器规则分帧并流式解码，使用实际解码出的帧数。
若设备为 48 kHz 而 TTS 为 24 kHz，应先有状态地重采样，再按输出采样率维护 PCM 队列。
不要把任意 MP3/Opus 字节片段当成独立音频文件解码。

还可以记录 ``arrival_gap_ms = arrival[n] - arrival[n-1]``，以及
``media_step_ms = 1000 * (sample_start[n] - sample_start[n-1]) / sample_rate``。
两者之差为有符号的供给节奏偏差：正值表示相对媒体进度到达变慢，负值可能只是 TTS 提前生成。
它混合了生成、传输及本地调度影响，不能直接称为单向网络延迟，也不能简单取其 P95 作为水位。
本例使用实际欠载反馈调节目标，先把“已准备多少音频”与“已消费多少音频”核算正确。

缓冲状态与参数
----------------------------

.. mermaid::

   stateDiagram-v2
     [*] --> PREFILL
     PREFILL --> PLAYING: 达到启动水位或收到 END
     PLAYING --> REBUFFER: 本次回调供给不足且尚未 END
     REBUFFER --> PLAYING: 达到恢复水位或收到 END
     PLAYING --> DRAINING: END 后最后一帧提交给设备
     DRAINING --> DONE: 输出时钟确认尾帧已消费
     PREFILL --> DONE: 空音频且收到 END

所有活动状态都允许转入 ``CANCELLED`` 或 ``ERROR``，图中省略这些连线。
``DRAINING`` 表示软件队列已空，但设备可能还在播放最后一段音频。

以下数值是实验起点，不是协议或 NetEQ 的默认值：

.. list-table:: TTS 实验参数
   :header-rows: 1
   :widths: 30 20 50

   * - 参数
     - 起始值
     - 用途
   * - ``target_ms``
     - 60 ms
     - 首次启动和欠载恢复的最低 PCM 水位
   * - ``min_target_ms / max_target_ms``
     - 40 / 200 ms
     - 自适应目标范围，不是队列容量
   * - ``capacity_ms``
     - 2000 ms
     - 硬容量，限制内存及未播放音频量
   * - ``max_chunk_ms``
     - 200 ms
     - 限制单消息大小和一次处理工作量
   * - ``buffer_wait_timeout_ms``
     - 2000 ms
     - 启动/恢复超过此时间仍不足时终止并报告
   * - ``idle_timeout_ms``
     - 10000 ms
     - 未收到有效 AUDIO/END 的最长等待时间
   * - ``max_turn_audio_ms / max_turn_wall_ms``
     - 120000 / 180000 ms
     - 分别限制单次内容长度及请求存活时间

生产环境应按实际生成速度和网络分布调参，长文本可拆成多个 turn。
短句不足 60 ms 时，收到 END 后必须直接播放尾部，不能一直等水位达到阈值。

伪代码一：接收、校验与入队
--------------------------------------------

信任边界是远端消息进入本地解码器/队列的位置。传输使用经过认证的 ``wss://``，
服务端校验 Origin 和请求归属，并限制消息速率及并发请求数。
接收端在分配/解码前校验消息类型、大小、格式和整数范围；所有队列都必须有界。
遥测仅记录本地生成的 trace ID、计数与时间，不记录文本、原始音频或认证信息。

下面是 **算法伪代码，不是可直接运行的线程实现**。为便于阅读，状态转换视为串行原子操作。
实际实现中网络/解码线程只向有界 SPSC 环形缓冲写入，音频线程负责读取；
控制命令、目标值和计数通过原子快照或有界消息通道交换。
异步解码必须保留接收顺序，不能让后完成的旧任务覆盖新 turn。

.. code-block:: text

   begin_turn(local_request_id, now_ms):
       # now_ms 取客户端发起请求的单调时钟时刻
       # active 初始为 NONE；切换 turn 前先取消旧播放
       if active is not NONE:
           cancel_turn(active)
       # 新建不可复用的 generation；旧 decoder/回调也绑定旧 generation
       active = new_generation(local_request_id)
       Fs = 24000                         # 本例设备与 TTS 采样率相同
       fifo = preallocated_pcm_ring(frames = Fs * 2)
       state = PREFILL
       eos = false
       next_seq = received_frames = rendered_frames = 0
       target_ms = 60
       underrun_count = underrun_frames = 0
       last_underrun_ms = NONE
       started_ms = waiting_since_ms = last_receive_ms = now_ms
       stable_play_ms = 0
       first_render_context_time = last_render_end_context_time = NONE
       first_receive_ms = first_enqueue_ms = NONE
       credit_until_frame = fifo.capacity
       send_credit_from_control_thread(active, credit_until_frame)

   on_audio(message, generation, receive_ms):
       if generation != active or state in {CANCELLED, ERROR, DONE, DRAINING}:
           return
       if not valid_audio_schema_and_size(message):
           fail_turn(BAD_MESSAGE); return
       if message.request_id != active.request_id:
           return                         # 旧请求或不属于本 turn
       if eos:
           fail_turn(AUDIO_AFTER_END); return
       if message.seq < next_seq:
           return                         # 协议允许的已接收消息重放，不能再次入队
       if message.seq != next_seq or message.sample_start != received_frames:
           fail_turn(DISCONTINUITY); return
       n = message.frame_count             # 有界正整数；使用检查溢出的算术
       if n > Fs * 200 / 1000 or message.payload.bytes != n * 2:
           fail_turn(BAD_PCM_LENGTH); return
       end_frame = checked_add(received_frames, n)
       if end_frame > Fs * 120 or end_frame > credit_until_frame:
           fail_turn(LIMIT_EXCEEDED); return
       pcm = convert_s16le_to_pcm(message.payload)  # 有界转换，异常转 ERROR
       if not fifo.try_write_all(pcm):
           fail_turn(OVERFLOW); return      # 不静默丢词，不无限扩容
       if first_receive_ms is NONE:
           first_receive_ms = receive_ms
           first_enqueue_ms = monotonic_ms()
       received_frames = end_frame
       next_seq += 1
       last_receive_ms = receive_ms

   on_end(message, generation, receive_ms):
       if generation != active or state in {CANCELLED, ERROR, DONE, DRAINING}:
           return
       if not valid_end_schema_and_size(message):
           fail_turn(BAD_MESSAGE); return
       if message.request_id != active.request_id:
           return
       if message.next_seq != next_seq or message.total_frames != received_frames:
           fail_turn(INCOMPLETE_STREAM); return
       eos = true                          # 同一 END 重复到达可幂等接受
       last_receive_ms = receive_ms

``valid_audio_schema_and_size`` 必须只接受已协商的格式，检查字段类型、
``seq/sample_start/frame_count`` 的范围和消息总字节数；``frame_count`` 必须大于零。
二进制解析和 PCM 转换失败都转入 ``ERROR`` 并释放该 turn 的资源。
WebSocket 正常连接内出现序号跳跃通常意味着应用层漏发、路由错误或解码乱序，
本例选择报错；连接断开也不等于 END。没有显式续传协议时，重连应创建新 turn。

伪代码二：由音频设备时钟驱动播放
------------------------------------------------

由音频回调提供 ``N`` 个输出采样帧的需求，允许一次跨越多个网络 chunk，
也允许只消费某个 chunk 的一部分。不能用 ``setInterval(20 ms)`` 模拟音频设备时钟。
浏览器可使用 AudioWorklet；根据
`Web Audio 的渲染模型 <https://www.w3.org/TR/webaudio/#rendering-loop>`_，
应按实际输出数组长度处理，不把网络 chunk 长度写死为回调长度。

.. code-block:: text

   render(output, N, context_time, now_ms):
       output.fill(0)                      # output 已预分配；始终交足 N 帧
       if state in {CANCELLED, ERROR, DONE, DRAINING}:
           return

       if state in {PREFILL, REBUFFER}:
           needed = ceil(Fs * target_ms / 1000)
           if fifo.readable_frames < needed and not eos:
               return                     # 等待时只输出静音，不消费媒体帧
           if eos and fifo.readable_frames == 0:
               if last_render_end_context_time is NONE:
                   state = DONE           # 合法的空音频；没有首次出声事件
               else:
                   state = DRAINING       # END 可能晚于最后一次正常回调
               return
           state = PLAYING

       copied = fifo.read_into(output, min(N, fifo.readable_frames))
       # read_into 会推进环形缓冲读指针，保留尚未读完的 chunk 尾部
       if copied > 0:
           if first_render_context_time is NONE:
               first_render_context_time = context_time
           rendered_frames += copied      # 只计真实媒体；补零不推进媒体位置
           last_render_end_context_time = context_time + copied / Fs

       if eos and fifo.readable_frames == 0:
           state = DRAINING                # 最后一块不足 N 的尾部补零是正常结束
       elif copied < N:
           underrun_count += 1             # 每次 PLAYING -> REBUFFER 只计一次
           underrun_frames += N - copied
           last_underrun_ms = now_ms
           target_ms = min(200, target_ms + 20)
           stable_play_ms = 0
           waiting_since_ms = now_ms
           state = REBUFFER
       else:
           stable_play_ms += 1000.0 * N / Fs
           if stable_play_ms >= 10000:
               target_ms = max(40, target_ms - 5)
               stable_play_ms = 0

这个基础算法通过“欠载后等待更多数据”真正增加缓冲，不会在播放中凭空增加音频。
稳定播放 10 秒才减少 5 ms，欠载立即增加 20 ms，避免频繁改变阈值。
降低目标只影响下一次启动/恢复，不会自动消除现有积压；若需要连续调水位，
可在此基础上加入有界的 WSOLA 时间缩放，单独评估清晰度和延迟收益。
本例的静音会形成可听停顿，它不是高质量 PLC；生产实现可在停顿/恢复边缘做短淡出淡入，
但不要重复一整块 TTS 语音来掩盖停顿，否则可能听到重复音节。

回调内只做有界读写、补零和计数，不做网络请求、日志格式化、阻塞锁、内存分配或解码。
``underrun_frames`` 只计首次缺口；如要统计完整中断时长，还需累计 REBUFFER
期间的输出帧数。启动静音和 END 尾部补零不能算作欠载。

伪代码三：背压、超时与打断
--------------------------------------------

使用累计 credit 可以限制“已发出但尚未消费”的媒体范围，避免 pause 消息送达前
仍有大量在途数据。服务端只允许发送满足
``sample_start + frame_count <= credit_until_frame`` 的 AUDIO，且同样限制自身待发队列。
END/CANCEL 等控制消息不消耗音频 credit。

.. code-block:: text

   control_tick(now_ms, device_output_context_time):
       if state in {CANCELLED, ERROR, DONE}:
           return
       if now_ms - started_ms > 180000:
           fail_turn(TURN_TIMEOUT); return
       if state == DRAINING:
           if device_output_context_time >= last_render_end_context_time:
               state = DONE
               emit_metadata_only(playback_completed)
           return
       if state in {PREFILL, REBUFFER} and now_ms - waiting_since_ms > 2000:
           fail_turn(BUFFER_WAIT_TIMEOUT); return
       if not eos and now_ms - last_receive_ms > 10000:
           fail_turn(STREAM_STALLED); return
       new_credit = min(Fs * 120, rendered_frames + fifo.capacity)
       if new_credit > credit_until_frame:
           credit_until_frame = new_credit
           send_credit_from_control_thread(active, new_credit)

   cancel_turn(generation):
       if generation != active:
           return
       state = CANCELLED                   # 先禁止继续提交旧音频
       invalidate_generation(active)
       clear_fifo_and_decoder_via_control_command(generation)
       stop_or_mute_scheduled_old_audio(generation)
       send_cancel_from_control_thread(generation)

   fail_turn(reason):
       # reason 是固定错误码；不包含原始消息、音频或文本
       cancel_turn(active)
       state = ERROR
       emit_metadata_only(reason)

累计 credit 是单调增加的，服务端不能把它理解成“这次再多发这么多帧”。
``rendered_frames`` 表示已离开软件队列的帧，因此此方案约束的是接收队列及在途音频，
设备内部仍有少量已提交音频。若服务端不支持背压，应选择有界暂存、分段请求或明确报错，
不要静默删掉任意音频片段。服务端受 credit 限制而暂停的区间，也应从生成性能统计中区分出来。

打断时要同时停止旧解码任务、清 PCM 队列并处理已安排的设备播放；
只清 WebSocket 接收队列仍会听到残留语音。已经交给硬件的样本通常无法完全撤回，
因此需要测量 ``cancel_to_silence_ms``。所有网络错误和设备错误都应进入同一清理路径。

如何测量“收到”和“听到”
--------------------------------------------

客户端所有事件用同一个单调时钟记录；服务端另记自己的生成和发送事件。
不要直接相减两台机器上的 ``performance.now()``，也不要把 RTT/2 当作准确的单向延迟。

.. list-table:: 建议的 trace 与计算方式
   :header-rows: 1
   :widths: 30 40 30

   * - 指标
     - 定义
     - 排查方向
   * - ``ttfa_receive_ms``
     - 首个有效音频接收时刻 - 客户端请求发起时刻
     - 首包生成及传输；本例直接传 PCM
   * - ``ttfa_ready_ms``
     - 首个可播放 PCM 入队时刻 - 请求发起时刻
     - 包含解码/转换；压缩音频时尤其有用
   * - ``first_play_ms``
     - 首帧设备输出估计时刻 - 请求发起时刻
     - 用户等待首音的体验
   * - ``ready_ms``
     - ``1000 * fifo.readable_frames / Fs``
     - 软件缓冲水位，不包含设备内部缓存
   * - ``playout_wait_ms``
     - 某媒体帧的输出时刻 - 该帧入队时刻
     - 真实排队等待；不能直接用当前水位替代
   * - ``underrun_count / rebuffer_ms``
     - 欠载事件数 / 启动后等待恢复的总时长
     - 卡顿频率与严重程度
   * - ``queue_growth_ms_per_sec``
     - 一段时间内 ready_ms 的增量 / 墙钟秒数
     - 长期供给/消费不匹配或正常的提前生成
   * - ``RTF``
     - 服务端实际生成耗时 / 生成音频时长
     - 持续 RTF > 1 时平均供给赶不上实时播放

收到首个压缩字节不代表已经收到可解码的一帧；务必区分 receive 与 ready。
同样，``first_render_context_time`` 只表示提交给音频图的时刻。
浏览器可以利用
`AudioContext.getOutputTimestamp() <https://www.w3.org/TR/webaudio/#dom-audiocontext-getoutputtimestamp>`_
把接近当前输出位置的音频时间映射到本地 performance 时间：

.. code-block:: text

   stamp = audio_context.getOutputTimestamp()
   # stamp.contextTime 的单位为秒；performanceTime 的单位为毫秒
   estimated_first_output_ms = stamp.performanceTime + 1000 * (
       first_render_context_time - stamp.contextTime)

等待有效输出时间戳，在首帧附近采集映射；距离很远时估计误差会变大。
尾帧完成也应依据设备输出时钟确认，而不是在收到 END 或 FIFO 变空时立即报告。
这是设备输出时间的估计，精确到物理扬声器的出声时刻仍需回环录音或外部测量。
若接收端再把音频送往 FreeSWITCH/SIP/RTP，应另建一个接收、转发、下游实际播放的 trace。

为什么只看消息间隔会误判
--------------------------------------------

假设每包 20 ms，回调为 10 ms，目标水位为 60 ms：

.. code-block:: text

   时刻       事件                               事件后的 ready_ms
   100 ms     收到 chunk 0                       20，PREFILL
   105 ms     收到 chunk 1                       40，PREFILL
   110 ms     收到 chunk 2，随后回调消费 10 ms    50，PLAYING
   115 ms     收到 chunk 3                       70
   120 ms     回调消费 10 ms                     60
   130 ms     回调消费 10 ms                     50
   140 ms     收到 chunk 4，随后消费 10 ms       60
   150 ms     回调消费 10 ms                     50
   160 ms     收到 chunk 5，随后消费 10 ms       60

115 到 140 ms 的消息间隔是 25 ms，但播放没有欠载。若从 160 ms 起一直没有新包，
170 至 220 ms 的六次回调耗尽 60 ms，230 ms 的回调才触发一次欠载并进入 REBUFFER。
这时目标从 60 增加到 80 ms，新的数据累计到 80 ms 才恢复；
如果先收到 END，则立即播放剩余尾部。应同时观察水位曲线和欠载事件，而不是只看间隔标准差。

用录制轨迹验证算法
--------------------------------------------

先录制不含内容的 ``arrival_offset_ms, seq, sample_start, frame_count, END``，
再用虚拟单调时钟按实际设备帧长重放到达与 render 事件。同一时刻的事件顺序必须固定，
并分别测试“先到达”和“先回调”的边界。建议至少覆盖：

.. list-table:: 可重复的验收场景
   :header-rows: 1
   :widths: 30 40 30

   * - 输入
     - 预期行为
     - 断言/观察
   * - 稳定流：每 20 ms 到达 480 帧，持续 10 秒
     - 达到启动水位后连续播放
     - 无欠载；END 后 rendered_frames == received_frames
   * - 突发流：每 100 ms 连续到达五个 20 ms chunk
     - 等待初始突发后连续消费
     - ready_ms 呈锯齿状；不能把突发次数计为丢包
   * - 播放中停发 300 ms，再恢复
     - 水位耗尽后只记录一次欠载，蓄水后继续播放
     - 目标上升；内容不丢、不重复；中断时长被记录
   * - 只有 30 ms 音频，随后 END
     - 不等 60 ms 水位，播放完整短句
     - 尾部补零不算欠载；设备输出尾帧后完成
   * - 20 ms chunk 配合每回调 128 帧
     - 单包跨多次回调，回调也可跨包读取
     - 输出帧顺序与源一致；没有每包舍入造成的漂移
   * - 服务端提前生成数十秒音频
     - credit 阻止无限发送；不支持 credit 时明确报错
     - fifo 始终不超过容量；服务端队列同样有界
   * - 重复 seq、跳号、错误长度、非法 END、断线无 END
     - 重复消息不重复播放；其他协议错误终止
     - 无越界、无无限等尾部、无错误的完成事件
   * - 打断后旧解码结果/旧消息继续到达
     - 旧 generation 全部失效
     - 新 turn 没有旧音频混入；记录 cancel_to_silence_ms
   * - 持续 RTF = 1.2，或接收线程阻塞
     - 有限预缓冲最终仍可能耗尽
     - 不能把持续供给不足误判为仅需增大目标水位

用带递增编号的合成 PCM 帧验证顺序和总帧数，再用语音试听停顿、淡入淡出及打断。
统计首音延迟 P50/P95、欠载次数、恢复时长及水位 P95，按网络类型和设备分组比较。
每次实验只调整一个参数：先固定 60 ms 建立基线，再启用自适应，并比较新增首音延迟
是否换来了更少的停顿。有限缓冲只能吸收有限停顿，无法修复长期供给速度不足。


常见问题与解决方案
============================

下表主要针对 RTP/NetEQ；WebSocket TTS 的欠载、背压和打断处理见前文，
不能通过给 TCP 音频流“启用 RTP FEC”来解决。

.. list-table:: 常见问题排查
   :header-rows: 1
   :widths: 25 35 40

   * - 问题
     - 可能原因
     - 解决方案
   * - 延迟过高
     - 目标延迟设置过大；网络抖动持续偏高
     - 降低 ``max_delay``\ ；检查网络质量；降低 ``histogram_quantile``
   * - 音频断续/卡顿
     - 缓冲区过小；丢包率过高
     - 增大 ``max_delay``\ ；检查网络丢包；启用 FEC
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


实现 RTP Jitter Buffer 的步骤
==========================================

总结实现一个音频 Jitter Buffer 的关键步骤：

1. **理解抖动概念**\ ：抖动是由于网络拥塞、丢包或其他因素导致的音频包到达时间的变化。

2. **设计缓冲区结构**\ ：通常使用按时间戳排序的优先队列或有序映射。

3. **设置缓冲区大小**\ ：根据需求确定合适的缓冲区大小，较大的缓冲区可以处理更大的抖动变化，但会引入额外延迟。

4. **接收和存储包**\ ：按序列号或时间戳存储到缓冲区，正确处理乱序包。

5. **估计播放时间**\ ：使用接收包的时间戳估计每个包的播放时间。

6. **调度包播放**\ ：由音频设备时钟驱动消费，按播放截止时间决定正常解码、FEC 或 PLC。

7. **处理迟到或丢失的包**\ ：使用插值、外推或丢包隐藏技术。

8. **动态调整缓冲区大小**\ ：监控网络状况，动态调整缓冲区大小。

9. **持续更新缓冲区**\ ：定期移除已播放的包，添加新到达的包。

10. **实现错误恢复机制**\ ：考虑 FEC 或重传等额外的错误恢复机制。

11. **测试和优化**\ ：在各种网络条件下测试，调优缓冲区大小、播放时间和错误恢复参数。


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
