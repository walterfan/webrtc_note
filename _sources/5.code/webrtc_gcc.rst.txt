####################
WebRTC GCC
####################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC GCC
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============



构建 libwebrtc
==============

首先，我们来下载和构建 webrtc library, 你需要一个 VPN 来下载所需的软件和源码


#. 安装 Chromium 软件库工具.

参见 


* WebRTC 开发依赖软件 `webrtc-prerequisite-sw <https://webrtc.googlesource.com/src/+/main/docs/native-code/development/prerequisite-sw/index.md>`_
* 安装 WebRTC 开发工具  `webrtc-depot-tools <https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up>`_


#. 下载 WebRTC 源码

.. code-block::


      $ mkdir webrtc-checkout
      $ cd webrtc-checkout
      $ fetch --nohooks webrtc
      $ gclient sync --force


#. 更新源码到你自己的分支

.. code-block::


      $ git checkout main
      $ git pull origin main
      $ gclient sync
      $ git checkout my-branch
      $ git merge main


#. 构建

先要安装 ninja 构建工具 `ninja-tool <https://ninja-build.org/>`_ 这一构建工具, 通过它来生成构建脚本

在 Linux 系统上，比较简单的方法是运行 ``./build/install-build-deps.sh``

.. code-block::

      $ cd src
      $ python build/util/lastchange.py build/util/LASTCHANGE
      # generate project files using the defaults (Debug build)
      $ gn gen out/Default
      # clean all build artifacts in a directory but leave the current GN configuration untouched
      $ gn clean out/Default
      $ ninja -C out/Default

在 windows 系统上，建议安装 visual studio 和 windows 10 SDK

注意:

1）一定要在系统设置中选择 Windows SDK , 再选择修改，安装 debugging tool)
2）为了使用本地安装的 visual studio, 需要先设置一下环境变量 ``set DEPOT_TOOLS_WIN_TOOLCHAIN=0``

.. code-block::

      gn gen --ide=vs out\Default

然后用 visual studio 打开 out\Default\all.sln

拥塞控制相关代码
================

拥塞控制的相关代码在 webrtc 代码的两个模块中


* `remote_bitrate_estimator <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/remote_bitrate_estimator>`_ 基于 REMB 的旧版本，基本已经废弃了，其中几个类在新版本中也有使用
* `congestion_controller <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/congestion_controller>`_ 基于 Transport Wide CC 的新版本，新旧版本中接收端的估算逻辑移到了发送端，其中的卡尔曼滤波算法也改成了线性回归算法


* 接收端的带宽评估接口是 ReceiveSideCongestionController


.. image:: https://upload-images.jianshu.io/upload_images/1598924-cb06cd8ea70d25c9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :target: https://upload-images.jianshu.io/upload_images/1598924-cb06cd8ea70d25c9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :alt: 



* 
  发送端的拥塞控制的核心类是 GoogCcNetworkController

   它实现了核心接口 NetworkControllerInterface


.. image:: https://upload-images.jianshu.io/upload_images/1598924-2ebd3d1098f90c3f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :target: https://upload-images.jianshu.io/upload_images/1598924-2ebd3d1098f90c3f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :alt: 


.. list-table::
   :header-rows: 1

   * - method
     - parameter
     - description
   * - OnNetworkAvailability
     - NetworkAvailability
     - 当网络连接有效或无效时
   * - OnNetworkRouteChange
     - NetworkRouteChange
     - 当网络地址更改时
   * - OnProcessInterval
     - ProcessInterval
     - 定时回调，以检查网络
   * - OnRemoteBitrateReport
     - RemoteBitrateReport
     - 当收到 REMB RTCP 消息时回调
   * - OnRoundTripTimeUpdate
     - RoundTripTimeUpdate
     - 当 RTT 更改时回调（可通过 RTCP RR）
   * - OnSentPacket
     - SentPacket
     - 当发出一个 RTP 包时
   * - OnReceivedPacket
     - ReceivedPacket
     - 当收到一个 RTP 包时
   * - OnStreamsConfig
     - StreamsConfig
     - 当有媒体流相关的配置更新时
   * - OnTargetRateConstraints
     - TargetRateConstraints
     - 当目标速率约束更改时
   * - OnTransportLossReport
     - 
     - 当收到 TransportLossReport 时
   * - OnTransportPacketsFeedback
     - TransportPacketsFeedback
     - 当收到 TransportPacketsFeedback 时
   * - OnNetworkStateEstimate
     - NetworkStateEstimate
     - 当网络状态估计更新时，还在开发中


* 相关的辅助类有:

.. list-table::
   :header-rows: 1

   * - Class
     - Responsibility
     - Collaborator
     - Comments
   * - ProbeController
     - 控制探测的启动以估计初始信道容量。 当应用程序调整最大比特率时，也还支持在会话期间进行探测。
     - ProbeClusterConfig， ProbeControllerConfig
     - 在初始阶段，及网络带宽有较大变化时都会启动探测
   * - ProbeBitrateEstimator
     - 根据 RTCP TWCC feedback计算探测码率，探测包按照cluster进行划分，根据所属的cluster以及发送和接收信息，通过发送和接收的数据大小比判断是否到达链路上限
     - AggregatedCluster, PacketResult
     - 探测包传输的大小除以探测时长就是探测的比特率
   * - AcknowledgedBitrateEstimator
     - 估算当前的吞吐量
     - PacketResult, BitrateEstimator
     -
   * - BitrateEstimator
     - 使用滑动窗口 + 贝叶斯方法计算当前发送吞吐量
     - AcknowledgedBitrateEstimator
     - 
   * - DelayBasedBwe
     - 基于延迟预估码率
     - InterArrivalDelta, TrendlineEstimator
     -
   * - TrendlineEstimator
     - 使用线性回归计算当前网络拥堵情况
     - TrendlineEstimatorSettings, BandwidthUsage
     -
   * - AimdRateControl
     - 通过TrendLine预测出来的网络状态对码率进行 AIMD(加增乘减)方式调整
     - LinkCapacityEstimator
     - 
   * - SendSideBandwidthEstimation
     - 基于丢包计算预估码率，结合延迟预估码率，得到最终的目标码率
     - LossBasedBandwidthEstimation/LossBasedBweV2, RttBasedBackoff, LinkCapacityTracker
     - 基于丢失的带宽估算, 再加上之前基于延迟的估算综合考虑
   * - CongestionWindowPushbackController
     - 基于当前的rtt设置一个时间窗口，同时基于当前的码率设置当前时间窗口下的数据量，通过判断当前窗口的使用量，如果使用量过大的时候，降低编码时使用的目标码率，加速窗口消退，减少延迟
     - 
     - 主要用于视频编码
   * - AlrDetector
     - 应用(码率)受限检测，检测当前的发送码率是否和目标码率由于编码器等原因相差过大受限了，受限情况下会触发带宽预测过程的特殊处理
     - AlrDetectorConfig
     -


.. image:: https://upload-images.jianshu.io/upload_images/1598924-31af95f0fbb185be.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :target: https://upload-images.jianshu.io/upload_images/1598924-31af95f0fbb185be.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :alt: GCC


核心的数据结构是


.. image:: https://upload-images.jianshu.io/upload_images/1598924-2c24a2c314300daf.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :target: https://upload-images.jianshu.io/upload_images/1598924-2c24a2c314300daf.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :alt: 


主要方法
========

OnRemoteBitrateReport
---------------------

.. code-block::

    NetworkControlUpdate GoogCcNetworkController::OnRemoteBitrateReport(
       RemoteBitrateReport msg) {
     if (packet_feedback_only_) {
       RTC_LOG(LS_ERROR) << "Received REMB for packet feedback only GoogCC";
       return NetworkControlUpdate();
     }
     bandwidth_estimation_->UpdateReceiverEstimate(msg.receive_time,
                                                   msg.bandwidth);
     BWE_TEST_LOGGING_PLOT(1, "REMB_kbps", msg.receive_time.ms(),
                           msg.bandwidth.bps() / 1000);
     return NetworkControlUpdate();
   }

   void SendSideBandwidthEstimation::UpdateReceiverEstimate(Timestamp at_time,
                                                            DataRate bandwidth) {
     // TODO(srte): Ensure caller passes PlusInfinity, not zero, to represent no
     // limitation.
     receiver_limit_ = bandwidth.IsZero() ? DataRate::PlusInfinity() : bandwidth;
     ApplyTargetLimits(at_time);
   }

   void SendSideBandwidthEstimation::ApplyTargetLimits(Timestamp at_time) {
     UpdateTargetBitrate(current_target_, at_time);
   }

   // 这里会限制  new_bitrate 在最大带宽 UpperLimit 和最小带宽 min_bitrate_configured 之间
   void SendSideBandwidthEstimation::UpdateTargetBitrate(DataRate new_bitrate,
                                                         Timestamp at_time) {
     new_bitrate = std::min(new_bitrate, GetUpperLimit());
     if (new_bitrate < min_bitrate_configured_) {
       MaybeLogLowBitrateWarning(new_bitrate, at_time);
       new_bitrate = min_bitrate_configured_;
     }
     current_target_ = new_bitrate;
     MaybeLogLossBasedEvent(at_time);
     link_capacity_.OnRateUpdate(acknowledged_rate_, current_target_, at_time);
   }

   // 这里应用了指数平滑移动平均法来应用新的 bitrate, 这个指数 alpha = exp(-delta/tracking_rate)
   void LinkCapacityTracker::OnRateUpdate(absl::optional<DataRate> acknowledged,
                                          DataRate target,
                                          Timestamp at_time) {
     if (!acknowledged)
       return;
     DataRate acknowledged_target = std::min(*acknowledged, target);
     if (acknowledged_target.bps() > capacity_estimate_bps_) {
       TimeDelta delta = at_time - last_link_capacity_update_;
       double alpha = delta.IsFinite() ? exp(-(delta / tracking_rate.Get())) : 0;
       capacity_estimate_bps_ = alpha * capacity_estimate_bps_ +
                                (1 - alpha) * acknowledged_target.bps<double>();
     }
     last_link_capacity_update_ = at_time;
   }

OnTransportPacketsFeedback
--------------------------

这个方法用来 处理传输通道的 RTP 包的 TWCC RTCP Feedback, 这个带宽估计的主要流程，另外写篇笔记详细讲讲

主要配置
========

对于带宽探测，在 ProbeControllerConfig  类 有如下的配置：

一开始发送一或二组探测包，大小为 p1 * start_bitrate\ *bps* , p2 * start_bitrate\ *bps*
默认为 3 * 300kbps = 900kbps, 6 * 300kpbs = 1.8mbps


* ProbeContollerConfig

.. code-block::

  struct ProbeControllerConfig {
  explicit ProbeControllerConfig(const WebRtcKeyValueConfig* key_value_config);
  ProbeControllerConfig(const ProbeControllerConfig&);
  ProbeControllerConfig& operator=(const ProbeControllerConfig&) = default;
  ~ProbeControllerConfig();

  // These parameters configure the initial probes. First we send one or two
  // probes of sizes p1 * start_bitrate\ *bps* and p2 * start_bitrate\ *bps*.
  // Then whenever we get a bitrate estimate of at least further_probe_threshold
  // times the size of the last sent probe we'll send another one of size
  // step_size times the new estimate.
  FieldTrialParameter\ :raw-html-m2r:`<double>` first_exponential_probe_scale;
  FieldTrialOptional\ :raw-html-m2r:`<double>` second_exponential_probe_scale;
  FieldTrialParameter\ :raw-html-m2r:`<double>` further_exponential_probe_scale;
  FieldTrialParameter\ :raw-html-m2r:`<double>` further_probe_threshold;

  // Configures how often we send ALR probes and how big they are.
  FieldTrialParameter\ :raw-html-m2r:`<TimeDelta>` alr_probing_interval;
  FieldTrialParameter\ :raw-html-m2r:`<double>` alr_probe_scale;

  // Configures the probes emitted by changed to the allocated bitrate.
  FieldTrialOptional\ :raw-html-m2r:`<double>` first_allocation_probe_scale;
  FieldTrialOptional\ :raw-html-m2r:`<double>` second_allocation_probe_scale;
  FieldTrialFlag allocation_allow_further_probing;
  FieldTrialParameter\ :raw-html-m2r:`<DataRate>` allocation_probe_max;
  };


* PacerConfig 控制 Pacer 发送的速度， 在指定的时间窗口 time_window 内只发送 data_windows 的数据

.. code-block::

    struct PacerConfig {
      Timestamp at_time = Timestamp::PlusInfinity();
      // Pacer should send at most data_window data over time_window duration.
      DataSize data_window = DataSize::Infinity();
      TimeDelta time_window = TimeDelta::PlusInfinity();
      // Pacer should send at least pad_window data over time_window duration.
      DataSize pad_window = DataSize::Zero();
      DataRate data_rate() const { return data_window / time_window; }
      DataRate pad_rate() const { return pad_window / time_window; }
    };

.. code-block::

   //ProbeClusterConfig 控制探测包的个数，目标速率及时长， 一组为一个 cluster, 通过会有两个以上的 cluster

  struct ProbeClusterConfig {
    Timestamp at_time = Timestamp::PlusInfinity();
    DataRate target_data_rate = DataRate::Zero();
    TimeDelta target_duration = TimeDelta::Zero();
    int32_t target_probe_count = 0;
    int32_t id = 0;
  };


* TargetTransferRate 目标传输速率， 包括目标速率及稳定的目标速率

.. code-block::

  struct NetworkEstimate {
    Timestamp at_time = Timestamp::PlusInfinity();
    // Deprecated, use TargetTransferRate::target_rate instead.
    DataRate bandwidth = DataRate::Infinity();
    TimeDelta round_trip_time = TimeDelta::PlusInfinity();
    TimeDelta bwe_period = TimeDelta::PlusInfinity();

    float loss_rate_ratio = 0;
  };

  struct TargetTransferRate {
    Timestamp at_time = Timestamp::PlusInfinity();
    // The estimate on which the target rate is based on.
    NetworkEstimate network_estimate;
    DataRate target_rate = DataRate::Zero();
    DataRate stable_target_rate = DataRate::Zero();
    double cwnd_reduce_ratio = 0;
  };


* NetworkControlUpdate 是网络控制器的更新状态，包括几个可选项
  - congestion_window 拥塞窗口
  - pacer_config 发送步进设置
  - probe_cluster_configs 探测群组的设置
  - target_rate 估算出的目标速率，也就是带宽

.. code-block::


  // Contains updates of network controller command state. Using optionals to
  // indicate whether a member has been updated. The array of probe clusters
  // should be used to send out probes if not empty.
  struct NetworkControlUpdate {
    NetworkControlUpdate();
    NetworkControlUpdate(const NetworkControlUpdate&);
    ~NetworkControlUpdate();
    absl::optional\ :raw-html-m2r:`<DataSize>` congestion_window;
    absl::optional\ :raw-html-m2r:`<PacerConfig>` pacer_config;
    std::vector\ :raw-html-m2r:`<ProbeClusterConfig>` probe_cluster_configs;
    absl::optional\ :raw-html-m2r:`<TargetTransferRate>` target_rate;
  };



主要流程
===================

带宽探测流程
-------------------

   当网络状态发生变化，或者带宽大小发生比较大的变化，都会触发带宽探测, NetworkControlUpdate 的设置反馈到 Pacer 模块, 然后 Pacer 创建探测包, 主要是由 BitrateProber 类来生成 SentPacket 中的 PacedPacketInfo


.. code-block::

    void PacedSender::CreateProbeCluster(DataRate bitrate, int cluster\ *id) {
        MutexLock lock(&mutex*\ );
        return pacing\ *controller*.CreateProbeCluster(bitrate, cluster_id);
    }

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

    struct SentPacket {
      Timestamp send_time = Timestamp::PlusInfinity();
      // Size of packet with overhead up to IP layer.
      DataSize size = DataSize::Zero();
      // Size of preceeding packets that are not part of feedback.
      DataSize prior_unacked_data = DataSize::Zero();
      // Probe cluster id and parameters including bitrate, number of packets and
      // number of bytes.
      PacedPacketInfo pacing_info;
      // True if the packet is an audio packet, false for video, padding, RTX etc.
      bool audio = false;
      // Transport independent sequence number, any tracked packet should have a
      // sequence number that is unique over the whole call and increasing by 1 for
      // each packet.
      int64_t sequence_number;
      // Tracked data in flight when the packet was sent, excluding unacked data.
      DataSize data_in_flight = DataSize::Zero();
    };



.. image:: https://upload-images.jianshu.io/upload_images/1598924-8826a38061b1dc20.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :target: https://upload-images.jianshu.io/upload_images/1598924-8826a38061b1dc20.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :alt: 



Related Classes
=========================================

* RtpTransportControllerSend::PostUpdates
* Call::OnTargetTransferRate
* BitrateAllocator::AllocateBitrate
  - LowRateAllocation
  - NormalRateAllocation
  - MaxRateAllocation

* BitrateAllocatorObserver::OnBitrateUpdated
* VideoSendStreamImpl
* VideoStreamEncoder
* VideoBitrateAllocation
