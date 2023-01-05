:orphan:

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
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:



When
=========================
* network available at startup 在启动时网络连通时
* enable periodic ALR probing 启用了定时 ALR 探测
* large drop in estimated bandwidth 发现评估的带宽有大幅衰减
* probing results indicate channel has greater capacity 探测结果揭示有更大的容量

Note:

ALR is Application-Limited Region, ALR region start when bandwidth usage drops below kAlrStartUsageRatio and ends when it raises above kAlrEndUsageRatio.
This is intentionally conservative at the moment until BW adjustments of application limited region is fine tuned.

Why
=========================
We want to use appropriate video/audio media parameters to transmission under the current bandwidth
We did not know whether there is enough bandwidth that we want if we do not probe with higher bitrate in some cases

How
=========================

* 探测时会设置一个初始带宽, 乘以不同的比例系数来发送

例如初始带宽为 300k, p1(first_exponential_probe_scale)=3, p2(second_exponential_probe_scale)=6

然后，每当我们得到一个比特率估计值至少是上一次发送探测的大小的 further_probe_threshold 倍时，我们将发送另一个大小为 step_size 乘以新估计值的比特率。

   第一次为 300 3 = 900 kbps
   第二次为 300 6 = 1800 kbps

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


初始的缺省值如下

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
   // 如果带宽在 kBitrateDropTimeoutMs(默认为 5000ms) 时长下降到原先的 kBitrateDropThreshold（默认为 66%)　或更低，
   // 我们会发送一个大小为原先带宽的 kProbeFractionAfterDrop(默认系数为 0.85) 比率的探测包.
   constexpr double kBitrateDropThreshold = 0.66;
   constexpr int kBitrateDropTimeoutMs = 5000;
   constexpr double kProbeFractionAfterDrop = 0.85;

   // Timeout for probing after leaving ALR. If the bitrate drops significantly,
   // (as determined by the delay based estimator) and we leave ALR, then we will
   // send a probe if we recover within `kLeftAlrTimeoutMs` ms.
   // 在离开应用受限区间(ALR) 的超时 kAlrEndedTimeoutMs(默认为 3 秒) 后, 如果带宽显著降低,而且我们离开了 ALR, 那么到达 kLeftAlrTimeoutMs 的时长 我们会发送一个探测包
   constexpr int kAlrEndedTimeoutMs = 3000;

   // This is a limit on how often probing can be done when there is a BW
   // drop detected in ALR.
   //  在 ALR 中当有一个带宽下降时 对于探测完成频率的限制
   constexpr int64_t kMinTimeBetweenAlrProbesMs = 5000;

   // The expected uncertainty of probe result (as a fraction of the target probe
   // bitrate). Used to avoid probing if the probe bitrate is close to our current
   // estimate.
   // 不确定的探测结果, 它是对于目标探测带宽的比率, 用来在探测带宽接近当前估计时避免还在探测
   constexpr double kProbeUncertainty = 0.05;

   // Use probing to recover faster after large bitrate estimate drops.
   // 特性开关: 在有大幅带宽下降时用探测来快速恢复
   constexpr char kBweRapidRecoveryExperiment[] =
      "WebRTC-BweRapidRecoveryExperiment";
   // 特性开关: 在到达配置的最大分配带宽后不再探测
   // Never probe higher than configured by OnMaxTotalAllocatedBitrate().
   constexpr char kCappedProbingFieldTrialName[] = "WebRTC-BweCappedProbing";


Related Code
---------------------------------------------------------
* ProbeControllerConfig

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




* ProbeController 根据当前网络状况控制何时,如何进行带宽探测


* ProbeBitrateEstimator 根据探测包的反馈消息,估算带宽

A probe cluster consists of a set of probes. Each probe in turn can be divided into a number of packets to accommodate the MTU on the network.

Probe Cluster 探测集合包含一组探测，每一个探测依次可被分割成一些包来符合网络中的 MTU 限制，

发送的探测包中会有包信息块,包含了探测的信息

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


Application Limited Region
================================

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


Reference
=========================
* https://codereview.webrtc.org/2504023002
* https://bugs.chromium.org/p/webrtc/issues/detail?id=4350
* https://chromium.googlesource.com/external/webrtc.git/+/01b488831bf7cb3276d8bdfbe0204dfbdbbba725