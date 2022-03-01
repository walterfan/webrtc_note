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


核心接口
===============

.. code-block:: c++


    class NetworkControllerInterface {
    public:
      virtual ~NetworkControllerInterface() = default;

      // Called when network availabilty changes.  -- 当网络有效或无效时
      ABSL_MUST_USE_RESULT virtual NetworkControlUpdate OnNetworkAvailability(NetworkAvailability) = 0;
      // Called when the receiving or sending endpoint changes address.  -- 当网络地址更改时
      ABSL_MUST_USE_RESULT virtual NetworkControlUpdate OnNetworkRouteChange(NetworkRouteChange) = 0;
      // Called periodically with a periodicy as specified by
      // NetworkControllerFactoryInterface::GetProcessInterval.  -- 定时回调，以检查网络
      ABSL_MUST_USE_RESULT virtual NetworkControlUpdate OnProcessInterval( ProcessInterval) = 0;
      // Called when remotely calculated bitrate is received.    -- 当收到 REMB RTCP 消息时回调
      ABSL_MUST_USE_RESULT virtual NetworkControlUpdate OnRemoteBitrateReport(RemoteBitrateReport) = 0;
      // Called round trip time has been calculated by protocol specific mechanisms.  -- 当 RTT 更改时回调（可通过 RTCP RR）
      ABSL_MUST_USE_RESULT virtual NetworkControlUpdate OnRoundTripTimeUpdate(RoundTripTimeUpdate) = 0;
      // Called when a packet is sent on the network.  -- 当发出一个 RTP 包时
      ABSL_MUST_USE_RESULT virtual NetworkControlUpdate OnSentPacket(SentPacket) = 0;
      // Called when a packet is received from the remote client. -- 当收到一个 RTP 包时
      ABSL_MUST_USE_RESULT virtual NetworkControlUpdate OnReceivedPacket(ReceivedPacket) = 0;
      // Called when the stream specific configuration has been updated.  -- 当有流相关的配置更新时
      ABSL_MUST_USE_RESULT virtual NetworkControlUpdate OnStreamsConfig(StreamsConfig) = 0;
      // Called when target transfer rate constraints has been changed.  -- 当目标速率约束更改时
      ABSL_MUST_USE_RESULT virtual NetworkControlUpdate OnTargetRateConstraints(TargetRateConstraints) = 0;
      // Called when a protocol specific calculation of packet loss has been made.  -- 当收到 TransportLossReport 时
      ABSL_MUST_USE_RESULT virtual NetworkControlUpdate OnTransportLossReport(TransportLossReport) = 0;
      // Called with per packet feedback regarding receive time.  -- 当收到 TransportPacketsFeedback 时
      ABSL_MUST_USE_RESULT virtual NetworkControlUpdate OnTransportPacketsFeedback(TransportPacketsFeedback) = 0;
      // Called with network state estimate updates. -- 当网络状态估计更新时，还在开发中
      ABSL_MUST_USE_RESULT virtual NetworkControlUpdate OnNetworkStateEstimate(NetworkStateEstimate) = 0;
    };


我们比较关心的方法是

* OnTransportLossReport 传输通道的丢失报告
* OnTransportPacketsFeedback 传输通道的 RTP 包的状态反馈报告

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


.. list-table:: congestion controller classes
   :widths: 25 25 25 25
   :header-rows: 1

   * - Class
     - Responsibility
     - Collablorator
     - Comments
   * - ProbeController
     - 探测控制器，通过目标码率判断下次是否探测，探测码率大小
     - ProbeControllerConfig 
     - 探测是在开始阶段，及特定的网络状态和条件下触发的

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

config classes 配置类
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

Controller classes
=================================

GoogleCcNetworkController
---------------------------------
It is the first class of congestion controller 

.. code-block::

  $ ./out/Default/modules_unittests --gtest_filter="GoogCcNetworkControllerTest.*"
  [ RUN      ] GoogCcNetworkControllerTest.InitializeTargetRateOnFirstProcessInterval
  [ RUN      ] GoogCcNetworkControllerTest.ReactsToChangedNetworkConditions
  [ RUN      ] GoogCcNetworkControllerTest.OnNetworkRouteChanged
  [ RUN      ] GoogCcNetworkControllerTest.ProbeOnRouteChange
  [ RUN      ] GoogCcNetworkControllerTest.UpdatesDelayBasedEstimate
  [ RUN      ] GoogCcNetworkControllerTest.PaceAtMaxOfLowerLinkCapacityAndBwe

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

Estimator classes
=======================
* probe_bitrate_estimator
* acknowledged_bitrate_estimator

* robust_throughput_estimator
* trendline_estimator


TrendlineEstimator
-----------------------
以线性回归和最小二乘法计算 OWDV 的趋势，自变量是时间，因变量是 OWDV, 其计算出来的斜率要和设定的阈值进行比较


code analysis
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code::


  // Returns the estimated trend k multiplied by some gain.
  // 0 < k < 1   ->  the delay increases, queues are filling up
  //   k == 0    ->  the delay does not change
  //   k < 0     ->  the delay decreases, queues are being emptied
  double trendline_slope() const { return trendline_ * threshold_gain_; }

  // Update the estimator with a new sample. The deltas should represent deltas
  // between timestamp groups as defined by the InterArrival class.
  void Update(double recv_delta_ms,
                                double send_delta_ms,
                                int64_t arrival_time_ms) {
    const double delta_ms = recv_delta_ms - send_delta_ms;
    ++num_of_deltas_;
    if (num_of_deltas_ > kDeltaCounterMax)
      num_of_deltas_ = kDeltaCounterMax;
    if (first_arrival_time_ms == -1)
      first_arrival_time_ms = arrival_time_ms;

    // Exponential backoff filter. -- 指数退避滤波器
    accumulated_delay_ += delta_ms;
    BWE_TEST_LOGGING_PLOT(1, "accumulated_delay_ms", arrival_time_ms,
                          accumulated_delay_);
    smoothed_delay_ = smoothing_coef_ * smoothed_delay_ +
                      (1 - smoothing_coef_) * accumulated_delay_;
    BWE_TEST_LOGGING_PLOT(1, "smoothed_delay_ms", arrival_time_ms,
                          smoothed_delay_);

    // Simple linear regression. -- 简单线性回归
    delay_hist_.push_back(std::make_pair(
        static_cast<double>(arrival_time_ms - first_arrival_time_ms),
        smoothed_delay_));
    if (delay_hist_.size() > window_size_)
      delay_hist_.pop_front();
    if (delay_hist_.size() == window_size_) {
      // Only update trendline_ if it is possible to fit a line to the data.
      trendline_ = LinearFitSlope(delay_hist_).value_or(trendline_);
    }

    BWE_TEST_LOGGING_PLOT(1, "trendline_slope", arrival_time_ms, trendline_);
  }

  //计算线性回归的斜率，传入的是一个列表，其元素是一对数据：
  //x 是到达时间 arrival_time_ms: 组内最后一个包的到达时间 - 组内第一个包的到达时间
  //y 是 OWDV=recv_delta_ms - send_delta_ms 单向延迟变化: RTP 包组的接收延迟变化 - 发送延迟变化
  rtc::Optional<double> LinearFitSlope(
      const std::deque<std::pair<double, double>>& points) {
    RTC_DCHECK(points.size() >= 2);
    // Compute the "center of mass".
    double sum_x = 0;
    double sum_y = 0;
    for (const auto& point : points) {
      sum_x += point.first;
      sum_y += point.second;
    }
    double x_avg = sum_x / points.size();
    double y_avg = sum_y / points.size();
    // Compute the slope k = \sum (x_i-x_avg)(y_i-y_avg) / \sum (x_i-x_avg)^2
    double numerator = 0;
    double denominator = 0;
    for (const auto& point : points) {
      numerator += (point.first - x_avg) * (point.second - y_avg);
      denominator += (point.first - x_avg) * (point.first - x_avg);
    }
    if (denominator == 0)
      return rtc::Optional<double>();
    return rtc::Optional<double>(numerator / denominator);
  }



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

* `Webrtc Rtp/rtcp  <https://xie.infoq.cn/article/8a8ad2f8170d0072941c2aa9e>`_
* `webrtc 即时带宽评估器 BitrateEstimator <https://xie.infoq.cn/article/2f944089023274ef0ac6eabd8>`_