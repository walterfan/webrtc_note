################################
Bandwidth Probe
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Bandwidth Probe
**Category** Learning note
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:


概述
=========================

带宽探测（Bandwidth Probing）是 WebRTC 拥塞控制中的一个关键机制。
在实时通信中，发送端需要知道网络路径的可用带宽，以便选择合适的编码参数。
然而，仅靠被动观察（如延迟梯度、丢包率）来估计带宽存在一个根本性问题：
**如果发送端不发送足够多的数据，就无法探测到更高的可用带宽**。

这就是所谓的 "鸡和蛋" 问题：

- 要知道带宽有多大，需要发送更多数据来测试
- 但发送过多数据可能导致网络拥塞
- 拥塞控制算法倾向于保守，不会主动增加发送速率

带宽探测通过在短时间内以高于当前估计带宽的速率发送一组探测包（Probe Cluster），
来主动探测网络是否有更多的可用带宽。如果探测包能够以目标速率成功传输（没有显著的延迟增加或丢包），
则说明网络有更多的可用容量，可以提高发送码率。

.. code-block::

   带宽探测的基本流程:

   ┌──────────┐    发送探测包集合     ┌──────────┐
   │  发送端   │ ──────────────────► │  接收端   │
   │          │  (高于当前码率)       │          │
   │          │                      │          │
   │          │ ◄────────────────── │          │
   │          │   Transport-CC 反馈   │          │
   │          │                      │          │
   │ 分析探测  │                      │          │
   │ 结果     │                      │          │
   └──────────┘                      └──────────┘

   如果探测成功 → 提高估计带宽 → 可能触发更多探测
   如果探测失败 → 保持或降低估计带宽


何时进行探测（When）
=========================

带宽探测在以下场景中被触发：

* **网络连通时的初始探测（Initial probing at startup）**: 会话刚建立时，需要快速探测可用带宽，以便尽快提供最佳质量的音视频。
* **启用了定时 ALR 探测（Periodic ALR probing）**: 当应用处于 Application-Limited Region（应用受限区间）时，实际发送速率低于估计带宽，需要定期探测以确认带宽是否有变化。
* **估计带宽大幅下降后的恢复探测（Recovery after large bandwidth drop）**: 当估计带宽显著下降后又有恢复迹象时，通过探测快速恢复到更高的码率。
* **探测结果表明有更大容量（Probing results indicate greater capacity）**: 当前一次探测成功，表明网络可能有更多可用带宽时，触发进一步的探测。
* **分配带宽变化时（Allocation bitrate change）**: 当应用层请求的最大带宽发生变化时（例如新的视频流加入），可能触发探测。

.. note::

   ALR（Application-Limited Region）是指应用实际发送的数据量远低于拥塞控制允许的发送量的状态。
   ALR 区间在带宽使用率低于 ``kAlrStartUsageRatio`` 时开始，
   在带宽使用率高于 ``kAlrEndUsageRatio`` 时结束。
   这种设计是有意保守的，直到 ALR 区间的带宽调整被充分优化。


为什么需要探测（Why）
=========================

我们希望使用合适的音视频媒体参数在当前带宽下进行传输。
在某些情况下，如果不以更高的比特率进行探测，我们就无法知道是否有足够的带宽可用。

具体来说，带宽探测解决了以下问题：

1. **快速启动（Fast startup）**: 会话开始时，拥塞控制算法的初始估计通常很保守。如果不进行探测，可能需要很长时间才能达到网络的实际可用带宽，导致初始阶段的音视频质量很差。

2. **带宽恢复（Bandwidth recovery）**: 网络拥塞消除后，被动的拥塞控制算法（如 AIMD）的加性增长速度很慢。探测可以帮助快速恢复到更高的码率。

3. **ALR 状态下的带宽跟踪（Bandwidth tracking in ALR）**: 当应用发送的数据量远低于可用带宽时（例如屏幕共享中静态画面），被动估计无法准确反映实际可用带宽。探测可以保持对带宽的准确跟踪。

4. **避免带宽浪费（Avoid bandwidth waste）**: 如果不探测，发送端可能长期以低于实际可用带宽的码率发送，浪费了网络资源，降低了用户体验。


探测策略（How）
=========================

探测时会设置一个初始带宽，乘以不同的比例系数来发送。

指数探测（Exponential Probing）
----------------------------------------------

在会话开始时，使用指数探测策略快速探测可用带宽：

例如初始带宽为 300k，p1（first_exponential_probe_scale）= 3，p2（second_exponential_probe_scale）= 6

.. code-block::

   第一次探测: 300 × 3 = 900 kbps
   第二次探测: 300 × 6 = 1800 kbps

然后，每当我们得到一个比特率估计值至少是上一次发送探测的大小的 ``further_probe_threshold`` 倍时，
我们将发送另一个大小为 ``step_size`` 乘以新估计值的比特率。

.. code-block::

   初始探测流程:

   时间 ──────────────────────────────────────────►

   ┌─────────┐     ┌─────────┐     ┌─────────┐
   │ Probe 1 │     │ Probe 2 │     │ Probe 3 │
   │ 900kbps │     │1800kbps │     │ 根据结果  │
   └────┬────┘     └────┬────┘     └────┬────┘
        │               │               │
        ▼               ▼               ▼
   估计: 800kbps   估计: 1500kbps  估计: 2000kbps
   (> 900×0.7)    (> 1800×0.7)
   触发下一次探测   触发下一次探测    达到目标，停止


保守探测（Conservative Probing）
----------------------------------------------

在会话进行过程中，探测策略更加保守：

- 探测的目标码率不会远超当前估计带宽
- 探测间隔更长，避免频繁探测对正常传输的干扰
- 使用 ``further_exponential_probe_scale``（默认为 2）作为步进系数


ALR 探测（ALR Probing）
----------------------------------------------

当应用处于 Application-Limited Region 时，定期进行探测：

- 探测间隔由 ``alr_probing_interval`` 控制，默认为 5 秒
- 探测目标码率为当前估计带宽的 ``alr_probe_scale`` 倍，默认为 2 倍
- ALR 探测确保在应用发送量较低时，仍能跟踪网络带宽的变化


分配带宽变化探测（Allocation Probing）
----------------------------------------------

当应用层的带宽分配发生变化时（例如新增视频流），可能触发探测：

- 第一次探测：``first_allocation_probe_scale`` × 新分配带宽
- 第二次探测：``second_allocation_probe_scale`` × 新分配带宽
- 最大探测带宽受 ``allocation_probe_max`` 限制


探测集合机制（Probe Cluster）
=========================

探测的基本单位是 Probe Cluster（探测集合），每个探测集合包含一组以目标速率发送的数据包。

ProbeController 类
----------------------------

``ProbeController`` 是探测的核心控制器，负责决定何时探测、以什么速率探测：

.. code-block:: c++

   struct ProbeControllerConfig {
      explicit ProbeControllerConfig(const WebRtcKeyValueConfig* key_value_config);
      ProbeControllerConfig(const ProbeControllerConfig&);
      ProbeControllerConfig& operator=(const ProbeControllerConfig&) = default;
      ~ProbeControllerConfig();

      // These parameters configure the initial probes. First we send one or two
      // probes of sizes p1 * start_bitrate_bps_ and p2 * start_bitrate_bps_.
      // Then whenever we get a bitrate estimate of at least further_probe_threshold
      // times the size of the last sent probe we'll send another one of size
      // step_size times the new estimate.
      FieldTrialParameter<double> first_exponential_probe_scale;
      FieldTrialOptional<double> second_exponential_probe_scale;
      FieldTrialParameter<double> further_exponential_probe_scale;
      FieldTrialParameter<double> further_probe_threshold;

      // Configures how often we send ALR probes and how big they are.
      FieldTrialParameter<TimeDelta> alr_probing_interval;
      FieldTrialParameter<double> alr_probe_scale;

      // Configures the probes emitted by changed to the allocated bitrate.
      FieldTrialOptional<double> first_allocation_probe_scale;
      FieldTrialOptional<double> second_allocation_probe_scale;
      FieldTrialFlag allocation_allow_further_probing;
      FieldTrialParameter<DataRate> allocation_probe_max;
   };


Probe Cluster 的构成
----------------------------

一个 Probe Cluster 由一组探测包组成。每个探测包可以被分割成多个网络包以适应 MTU 限制。

发送的探测包中会有包信息块，包含了探测的信息：

.. code-block:: c++

    struct PacedPacketInfo {
        PacedPacketInfo();
        PacedPacketInfo(int probe_cluster_id,
                        int probe_cluster_min_probes,
                        int probe_cluster_min_bytes);

        bool operator==(const PacedPacketInfo& rhs) const;

        // TODO(srte): Move probing info to a separate, optional struct.
        static constexpr int kNotAProbe = -1;
        int send_bitrate_bps = -1;
        int probe_cluster_id = kNotAProbe;
        int probe_cluster_min_probes = -1;
        int probe_cluster_min_bytes = -1;
        int probe_cluster_bytes_sent = 0;
    };

每个 Probe Cluster 有以下约束：

- **最少包数（Min probes）**: 至少发送 ``kMinProbePacketsSent``（默认 5）个包
- **最短持续时间（Min duration）**: 至少持续 ``kMinProbeDurationMs``（默认 15 ms）
- **目标发送速率（Target bitrate）**: 以指定的目标比特率发送


探测包类型（Probe Packet Types）
----------------------------------------------

探测包可以使用以下类型的数据：

1. **Padding 包**: 纯填充数据，不携带有用信息。当没有足够的媒体数据时使用。
2. **RTX 重传包**: 利用 RTX（Retransmission）通道发送之前已发送过的数据包的副本。这样既完成了探测，又提供了冗余保护。
3. **正常媒体包**: 如果发送队列中有待发送的媒体数据，优先使用媒体数据进行探测，避免浪费带宽。

优先级顺序：正常媒体包 > RTX 重传包 > Padding 包


ProbeBitrateEstimator 类
----------------------------

``ProbeBitrateEstimator`` 根据探测包的反馈消息估算带宽。它分析每个 Probe Cluster 的发送和接收信息，
计算实际的传输速率：

.. code-block::

   探测结果分析:

   发送端记录:
   - 每个探测包的发送时间和大小
   - Probe Cluster 的总发送字节数和持续时间

   接收端反馈 (通过 Transport-CC):
   - 每个探测包的到达时间

   估算:
   - 发送速率 = 总发送字节数 / 发送持续时间
   - 接收速率 = 总接收字节数 / 接收持续时间
   - 估计带宽 = min(发送速率, 接收速率)

如果接收速率显著低于发送速率，说明网络无法支持目标探测速率，探测 "失败"。
如果接收速率接近发送速率，说明网络有足够的容量，探测 "成功"。


配置参数详解
=========================

初始默认值如下：

.. code-block:: c++

   // The minimum number probing packets used. 最少发送的探测包个数 5 个包
   constexpr int kMinProbePacketsSent = 5;

   // The minimum probing duration in ms. 最短探测的时间 15ms
   constexpr int kMinProbeDurationMs = 15;

   // Maximum waiting time from the time of initiating probing to getting
   // the measured results back.
   // 对发起的探测结果的最长等待时间, 默认为 1000ms
   constexpr int64_t kMaxWaitingTimeForProbingResultMs = 1000;

   // Value of `min_bitrate_to_probe_further_bps_` that indicates
   // further probing is disabled.
   // 是否进行进一步的探测
   constexpr int kExponentialProbingDisabled = 0;

   // Default probing bitrate limit. Applied only when the application didn't
   // specify max bitrate.
   // 默认的探测带宽限制, 如果应用程序没有指定最大带宽,默认为 5m bps
   constexpr int64_t kDefaultMaxProbingBitrateBps = 5000000;

   // If the bitrate drops to a factor `kBitrateDropThreshold` or lower
   // and we recover within `kBitrateDropTimeoutMs`, then we'll send
   // a probe at a fraction `kProbeFractionAfterDrop` of the original bitrate.
   // 如果带宽在 kBitrateDropTimeoutMs(默认为 5000ms) 时长下降到原先的
   // kBitrateDropThreshold（默认为 66%) 或更低，
   // 我们会发送一个大小为原先带宽的 kProbeFractionAfterDrop(默认系数为 0.85) 比率的探测包.
   constexpr double kBitrateDropThreshold = 0.66;
   constexpr int kBitrateDropTimeoutMs = 5000;
   constexpr double kProbeFractionAfterDrop = 0.85;

   // Timeout for probing after leaving ALR. If the bitrate drops significantly,
   // (as determined by the delay based estimator) and we leave ALR, then we will
   // send a probe if we recover within `kLeftAlrTimeoutMs` ms.
   // 在离开应用受限区间(ALR) 的超时 kAlrEndedTimeoutMs(默认为 3 秒) 后,
   // 如果带宽显著降低,而且我们离开了 ALR,
   // 那么到达 kLeftAlrTimeoutMs 的时长我们会发送一个探测包
   constexpr int kAlrEndedTimeoutMs = 3000;

   // This is a limit on how often probing can be done when there is a BW
   // drop detected in ALR.
   // 在 ALR 中当有一个带宽下降时对于探测完成频率的限制
   constexpr int64_t kMinTimeBetweenAlrProbesMs = 5000;

   // The expected uncertainty of probe result (as a fraction of the target probe
   // bitrate). Used to avoid probing if the probe bitrate is close to our current
   // estimate.
   // 不确定的探测结果, 它是对于目标探测带宽的比率,
   // 用来在探测带宽接近当前估计时避免还在探测
   constexpr double kProbeUncertainty = 0.05;

   // Use probing to recover faster after large bitrate estimate drops.
   // 特性开关: 在有大幅带宽下降时用探测来快速恢复
   constexpr char kBweRapidRecoveryExperiment[] =
      "WebRTC-BweRapidRecoveryExperiment";

   // 特性开关: 在到达配置的最大分配带宽后不再探测
   // Never probe higher than configured by OnMaxTotalAllocatedBitrate().
   constexpr char kCappedProbingFieldTrialName[] = "WebRTC-BweCappedProbing";


ProbeControllerConfig 默认值
----------------------------------------------

.. code-block:: c++

   ProbeControllerConfig::ProbeControllerConfig(
         const WebRtcKeyValueConfig* key_value_config)
         : first_exponential_probe_scale("p1", 3.0),
            second_exponential_probe_scale("p2", 6.0),
            further_exponential_probe_scale("step_size", 2),
            further_probe_threshold("further_probe_threshold", 0.7),
            alr_probing_interval("alr_interval", TimeDelta::Seconds(5)),
            alr_probe_scale("alr_scale", 2),
            first_allocation_probe_scale("alloc_p1", 1),
            second_allocation_probe_scale("alloc_p2", 2),
            allocation_allow_further_probing("alloc_probe_further", false),
            allocation_probe_max("alloc_probe_max", DataRate::PlusInfinity()) {
         //...
    }

参数说明：

.. list-table:: ProbeController 配置参数
   :header-rows: 1
   :widths: 30 15 55

   * - 参数名
     - 默认值
     - 说明
   * - first_exponential_probe_scale (p1)
     - 3.0
     - 第一次指数探测的比例系数
   * - second_exponential_probe_scale (p2)
     - 6.0
     - 第二次指数探测的比例系数
   * - further_exponential_probe_scale (step_size)
     - 2.0
     - 后续探测的步进系数
   * - further_probe_threshold
     - 0.7
     - 触发进一步探测的阈值（估计值/上次探测值）
   * - alr_probing_interval
     - 5 秒
     - ALR 探测的时间间隔
   * - alr_probe_scale
     - 2.0
     - ALR 探测的比例系数
   * - first_allocation_probe_scale (alloc_p1)
     - 1.0
     - 分配变化时第一次探测的比例系数
   * - second_allocation_probe_scale (alloc_p2)
     - 2.0
     - 分配变化时第二次探测的比例系数
   * - allocation_probe_max
     - 无限大
     - 分配探测的最大比特率


探测与拥塞控制的交互
=========================

带宽探测与拥塞控制算法（如 GCC）紧密协作：

.. code-block::

   ┌─────────────────────────────────────────────────────┐
   │                  GccNetworkController                │
   │                                                     │
   │  ┌──────────────┐    ┌──────────────────────────┐   │
   │  │ProbeController│───►│    PacingController       │   │
   │  │ (决定何时探测) │    │ (按目标速率发送探测包)     │   │
   │  └──────┬───────┘    └──────────────────────────┘   │
   │         │                                           │
   │         │ 探测结果                                   │
   │         ▼                                           │
   │  ┌──────────────────┐   ┌─────────────────────┐    │
   │  │ProbeBitrateEstim. │──►│DelayBasedBweEstimator│    │
   │  │ (分析探测结果)     │   │ (更新带宽估计)        │    │
   │  └──────────────────┘   └─────────────────────┘    │
   │                                                     │
   └─────────────────────────────────────────────────────┘

交互流程：

1. ``ProbeController`` 根据当前状态决定是否需要探测，以及探测的目标码率
2. ``PacingController`` 按照目标码率发送探测包（Probe Cluster）
3. 接收端通过 Transport-CC 反馈探测包的到达时间
4. ``ProbeBitrateEstimator`` 分析探测结果，计算探测带宽
5. 探测结果被输入到 ``DelayBasedBwe``，用于更新带宽估计
6. 如果探测成功（估计带宽显著高于当前值），可能触发进一步的探测

**重要注意事项**:

- 探测期间，拥塞控制算法会特殊处理探测包的反馈，不会因为探测导致的短暂延迟增加而错误地降低带宽估计
- 探测结果的等待时间有上限（``kMaxWaitingTimeForProbingResultMs``，默认 1000 ms），超时则认为探测失败
- 探测的目标码率不会超过应用层设置的最大带宽限制


Application Limited Region
================================

ALR（Application-Limited Region）检测器用于判断当前是否处于应用受限状态：

.. uml::

   @startuml
   struct AlrDetectorConfig {

      double bandwidth_usage_ratio = 0.65;
      double start_budget_level_ratio = 0.80;
      double stop_budget_level_ratio = 0.50;
      std::unique_ptr<StructParametersParser> Parser();
   }

   class AlrDetector {

      void OnBytesSent(size_t bytes_sent, int64_t send_time_ms);

      void SetEstimatedBitrate(int bitrate_bps);

      absl::optional<int64_t> GetApplicationLimitedRegionStartTime() const;

      const AlrDetectorConfig conf_;

      absl::optional<int64_t> last_send_time_ms_;

      IntervalBudget alr_budget_;

      absl::optional<int64_t> alr_started_time_ms_;

      RtcEventLog* event_log_;
   }

   AlrDetectorConfig --o AlrDetector
   @enduml

ALR 检测的工作原理：

- ``AlrDetector`` 维护一个 ``IntervalBudget``（区间预算），跟踪实际发送量与估计带宽之间的差异
- 当实际发送量持续低于估计带宽的 ``start_budget_level_ratio``（默认 80%）时，进入 ALR 状态
- 当实际发送量恢复到估计带宽的 ``stop_budget_level_ratio``（默认 50%）以上时，退出 ALR 状态
- 在 ALR 状态下，``ProbeController`` 会定期触发探测，以确保带宽估计的准确性

ALR 状态的典型场景：

- 屏幕共享中的静态画面（编码后数据量很小）
- 低运动场景的视频通话
- 音频通话中没有视频流
- 应用层主动限制了发送码率


总结
=========================

带宽探测是 WebRTC 拥塞控制中不可或缺的组成部分。它解决了被动拥塞控制算法无法主动发现更高可用带宽的问题，
通过在关键时刻（启动、恢复、ALR）发送探测包来快速准确地估计网络容量。

关键要点：

1. **探测是主动的**: 不同于被动的拥塞控制，探测主动发送额外数据来测试网络容量
2. **探测是有策略的**: 不同场景使用不同的探测策略（指数探测、保守探测、ALR 探测）
3. **探测是有限制的**: 探测有最大码率限制、最小间隔限制，避免对网络造成过大冲击
4. **探测与拥塞控制协作**: 探测结果被输入到拥塞控制算法中，共同决定最终的发送码率


参考资料
=========================

* `GCC - A Google Congestion Control Algorithm for Real-Time Communication <https://tools.ietf.org/html/draft-ietf-rmcat-gcc-02>`_
* `RFC 8698 - An Overview of the IETF RMCAT Program <https://tools.ietf.org/html/rfc8698>`_
* `WebRTC 源码 - ProbeController <https://source.chromium.org/chromium/chromium/src/+/master:third_party/webrtc/modules/congestion_controller/goog_cc/probe_controller.cc>`_
* `WebRTC 源码 - ProbeBitrateEstimator <https://source.chromium.org/chromium/chromium/src/+/master:third_party/webrtc/modules/congestion_controller/goog_cc/probe_bitrate_estimator.cc>`_
* `WebRTC 源码 - AlrDetector <https://source.chromium.org/chromium/chromium/src/+/master:third_party/webrtc/modules/congestion_controller/goog_cc/alr_detector.cc>`_
* https://codereview.webrtc.org/2504023002
* https://bugs.chromium.org/p/webrtc/issues/detail?id=4350
* https://chromium.googlesource.com/external/webrtc.git/+/01b488831bf7cb3276d8bdfbe0204dfbdbbba725
