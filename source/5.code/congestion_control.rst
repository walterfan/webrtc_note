:orphan:

##############################
WebRTC Congestion Control
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Congestion Control
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

Overview
=============
拥塞控制的相关代码在 webrtc 代码的两个模块中

* `remote_bitrate_estimator`_ 基于 REMB 的旧版本，基本已经废弃了，其中几个类在新版本中也有使用
* `congestion_controller`_ 基于 Transport Wide CC 的新版本，新旧版本中接收端的估算逻辑移到了发送端，其中的卡尔曼滤波算法也改成了线性回归算法

.. _remote_bitrate_estimator: https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/remote_bitrate_estimator
.. _congestion_controller: https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/congestion_controller


Receiver side congestion controller
------------------------------------------
兼容旧版本的 REMB 消息，由接收方来指定最大的传输带宽

.. code-block::

    rtc_library("congestion_controller") {
      visibility = [ "*" ]
      configs += [ ":bwe_test_logging" ]
      sources = [
        "include/receive_side_congestion_controller.h",
        "receive_side_congestion_controller.cc",
        "remb_throttler.cc",
        "remb_throttler.h",
      ]

      deps = [
        "..:module_api",
        "../../api/transport:field_trial_based_config",
        "../../api/transport:network_control",
        "../../api/units:data_rate",
        "../../api/units:time_delta",
        "../../api/units:timestamp",
        "../../rtc_base/synchronization:mutex",
        "../pacing",
        "../remote_bitrate_estimator",
        "../rtp_rtcp:rtp_rtcp_format",
      ]


sender side congestion controller
------------------------------------------
发送端的拥塞控制逻辑，主要控制类是 GoogleCcNetworkController

其依赖项有

* ProbeController : 探测控制器，通过目标码率判断下次是否探测，探测码率大小
* ProbeBitrateEstimator : 根据feedback计算探测码率，PacingController中会将包按照cluster进行划分，transport-CC报文能得到包所属的cluster以及发送和接收信息，通过发送和接收的数据大小比判断是否到达链路上限从而进行带宽探测
* AcknowledgedBitrateEstimator : 估算当前的吞吐量
* BitrateEstimator :使用滑动窗口 + 卡尔曼滤波计算当前发送吞吐量
* DelayBasedBwe : 基于延迟预估码率
* TrendlineEstimator : 使用线性回归计算当前网络拥堵情况
* AimdRateControl : 通过TrendLine预测出来的网络状态对码率进行 AIMD(加增乘减)方式调整
* SendSideBandwidthEstimation : 基于丢包计算预估码率，结合延迟预估码率，得到最终的目标码率
* CongestionWindowPushbackController : 基于当前的rtt设置一个时间窗口，同时基于当前的码率设置当前时间窗口下的数据量，通过判断当前窗口的使用量，如果使用量过大的时候，降低编码时使用的目标码率，加速窗口消退，减少延迟
* AlrDetector : 应用(码率)受限检测，检测当前的发送码率是否和目标码率由于编码器等原因相差过大受限了，受限情况下会触发带宽预测过程的特殊处理

config classes
=================================
* NetworkControllerConfig

.. code-block:: c++

   // Use StreamsConfig for information about streams that is required for specific
   // adjustments to the algorithms in network controllers. Especially useful
   // for experiments.
   struct StreamsConfig {
      StreamsConfig();
      StreamsConfig(const StreamsConfig&);
      ~StreamsConfig();
      Timestamp at_time = Timestamp::PlusInfinity();
      absl::optional<bool> requests_alr_probing;
      absl::optional<double> pacing_factor;

      // TODO(srte): Use BitrateAllocationLimits here.
      absl::optional<DataRate> min_total_allocated_bitrate;
      absl::optional<DataRate> max_padding_rate;
      absl::optional<DataRate> max_total_allocated_bitrate;
   };

   struct TargetRateConstraints {
      TargetRateConstraints();
      TargetRateConstraints(const TargetRateConstraints&);
      ~TargetRateConstraints();
      Timestamp at_time = Timestamp::PlusInfinity();
      absl::optional<DataRate> min_data_rate;
      absl::optional<DataRate> max_data_rate;
      // The initial bandwidth estimate to base target rate on. This should be used
      // as the basis for initial OnTargetTransferRate and OnPacerConfig callbacks.
      absl::optional<DataRate> starting_rate;
   };

   // Configuration sent to factory create function. The parameters here are
   // optional to use for a network controller implementation.
   struct NetworkControllerConfig {
      // The initial constraints to start with, these can be changed at any later
      // time by calls to OnTargetRateConstraints. Note that the starting rate
      // has to be set initially to provide a starting state for the network
      // controller, even though the field is marked as optional.
      TargetRateConstraints constraints;
      // Initial stream specific configuration, these are changed at any later time
      // by calls to OnStreamsConfig.
      StreamsConfig stream_based_config;

      // Optional override of configuration of WebRTC internals. Using nullptr here
      // indicates that the field trial API will be used.
      const WebRtcKeyValueConfig* key_value_config = nullptr;
      // Optional override of event log.
      RtcEventLog* event_log = nullptr;
   };

* GoogCcConfig

.. code-block:: c++

   struct GoogCcConfig {
      std::unique_ptr<NetworkStateEstimator> network_state_estimator = nullptr;
      std::unique_ptr<NetworkStatePredictor> network_state_predictor = nullptr;
      bool feedback_only = false;
   };

main classes
=================================

GoogleCcNetworkController
---------------------------------


DelayBasedBwe
---------------------------------
基于延迟的带宽估计模块，主要方法为 `IncomingPacketFeedbackVector`, 其结果为 `DelayBasedBwe::Result` 

其中根据 OWDV 单向延迟变化 进行趋势估算的类为 TrendlineEstimator

.. code-block::

   class DelayBasedBwe {
      public:
      struct Result {
         Result();
         ~Result() = default;
         bool updated;
         bool probe;
         DataRate target_bitrate = DataRate::Zero();
         bool recovered_from_overuse;
         bool backoff_in_alr;
      };

      explicit DelayBasedBwe(const WebRtcKeyValueConfig* key_value_config,
                              RtcEventLog* event_log,
                              NetworkStatePredictor* network_state_predictor);

      DelayBasedBwe() = delete;
      DelayBasedBwe(const DelayBasedBwe&) = delete;
      DelayBasedBwe& operator=(const DelayBasedBwe&) = delete;

      virtual ~DelayBasedBwe();

      Result IncomingPacketFeedbackVector(
            const TransportPacketsFeedback& msg,
            absl::optional<DataRate> acked_bitrate,
            absl::optional<DataRate> probe_bitrate,
            absl::optional<NetworkStateEstimate> network_estimate,
            bool in_alr);

      //...


      }

TrendlineEstimator
-----------------------
以线性回归和最小二乘法计算 OWDV 的趋势，自变量是时间，因变量是 OWDV, 其计算出来的斜率要和设定的阈值进行比较




ALRDetector
-----------------------

ALR（Application limited region detector）该模块也属于 gcc 的一个子模块

其大概原理就是检查 SentRate/EstimatedRate - 发送速率与估算速率的百分比

当小于 kAlrStartUsagePercent (60%)，认为网络受限，需要启动 probe 重新探测带宽，

当大于 kAlrEndUsagePercent (70%)，认为网络不会恢复了,需要启动下次 probe 探测


CongestionWindowPushbackController
---------------------------------------------
This class enables pushback from congestion window directly to video encoder.
When the congestion window is filling up, the video encoder target bitrate will be reduced accordingly to accommodate the network changes. To avoid pausing video too frequently, a minimum encoder target bitrate threshold is used to prevent video pause due to a full congestion window.

BitrateEstimator
---------------------------------------------
Computes a bayesian estimate of the throughput given acks containing the arrival time and payload size.
Samples which are far from the current estimate or are based on few packets are given a smaller weight, as they are considered to be more likely to have been caused by, e.g., delay spikes unrelated to congestion.



unit tests
==================

* run unit tests
  
.. code-block::

   ./out/Default/modules_unittests --gtest_filter="GoogCcNetworkControllerTest*"

Reference
==================
* https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/encode_usage_resource.h
* https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/overuse_frame_detector.h

