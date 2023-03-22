##############################
WebRTC REMB Code
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC REMB
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
======================================

* RTP extension: abs_send_time
* RTCP extension: REMB
* delay based controller on receiver side
* loss based controller on sender side

Controller
=======================================
* ReceiveSideCongestionController
* RembThrottler
* RembSender

.. code-block::


   // This class represents the congestion control state for receive
   // streams. For send side bandwidth estimation, this is simply
   // relaying for each received RTP packet back to the sender. While for
   // receive side bandwidth estimation, we do the estimation locally and
   // send our results back to the sender.
   class ReceiveSideCongestionController : public CallStatsObserver {
   public:
   ReceiveSideCongestionController(
         Clock* clock,
         RemoteEstimatorProxy::TransportFeedbackSender feedback_sender,
         RembThrottler::RembSender remb_sender,
         NetworkStateEstimator* network_state_estimator);

   ~ReceiveSideCongestionController() override {}

   void OnReceivedPacket(const RtpPacketReceived& packet, MediaType media_type);

   // TODO(perkj, bugs.webrtc.org/14859): Remove all usage. This method is
   // currently not used by PeerConnections.
   virtual void OnReceivedPacket(int64_t arrival_time_ms,
                                 size_t payload_size,
                                 const RTPHeader& header);
   // Implements CallStatsObserver.
   void OnRttUpdate(int64_t avg_rtt_ms, int64_t max_rtt_ms) override;

   // This is send bitrate, used to control the rate of feedback messages.
   void OnBitrateChanged(int bitrate_bps);

   // Ensures the remote party is notified of the receive bitrate no larger than
   // `bitrate` using RTCP REMB.
   void SetMaxDesiredReceiveBitrate(DataRate bitrate);

   void SetTransportOverhead(DataSize overhead_per_packet);

   // Returns latest receive side bandwidth estimation.
   // Returns zero if receive side bandwidth estimation is unavailable.
   DataRate LatestReceiveSideEstimate() const;

   // Removes stream from receive side bandwidth estimation.
   // Noop if receive side bwe is not used or stream doesn't participate in it.
   void RemoveStream(uint32_t ssrc);

   // Runs periodic tasks if it is time to run them, returns time until next
   // call to `MaybeProcess` should be non idle.
   TimeDelta MaybeProcess();

   private:
   void PickEstimator(bool has_absolute_send_time)
         RTC_EXCLUSIVE_LOCKS_REQUIRED(mutex_);

   Clock& clock_;
   RembThrottler remb_throttler_;
   RemoteEstimatorProxy remote_estimator_proxy_;

   mutable Mutex mutex_;
   std::unique_ptr<RemoteBitrateEstimator> rbe_ RTC_GUARDED_BY(mutex_);
   bool using_absolute_send_time_ RTC_GUARDED_BY(mutex_);
   uint32_t packets_since_absolute_send_time_ RTC_GUARDED_BY(mutex_);
   };


生成和发送 REMB 消息
---------------------------------------

根据所接收到的 RTP packet 中的 abs_send_time, 以及所接收到的时间

.. uml::

   MediaChannel->WebRtcVideoChannel: OnPacketReceived
   WebRtcVideoChannel->Call: DeliverPacket
   Call->Call: DeliverRtp
   Call->Call: NotifyBweOfReceivedPacket(const RtpPacketReceived& packet,
   Call->ReceiveSideCongestionController: OnReceivedPacket
   ReceiveSideCongestionController-> RemoteBitrateEstimatorAbsSendTime : IncomingPacket




接收和解析 REMB 消息
---------------------------------------

这里应用了观察者模式， 当 `rtcp_receiver` 收到了 REMB 或者 TMMBR 消息后，可以通知观察者 `rtcp_bandwidth_observer`


.. epigraph::

   A receiver, translator, or mixer uses the Temporary Maximum Media Stream Bit Rate Request (TMMBR, "timber") to request a sender to limit the maximum bit rate for a media stream

rtcp_bandwidth_observer 然后再通知 `NetworkController`


* rtp_transport_controller_send.cc

.. code-block:: c++

   std::unique_ptr<NetworkControllerInterface> controller_
      RTC_GUARDED_BY(task_queue_) RTC_PT_GUARDED_BY(task_queue_);

   void RtpTransportControllerSend::OnReceivedEstimatedBitrate(uint32_t bitrate) {
      RemoteBitrateReport msg;
      msg.receive_time = Timestamp::Millis(clock_->TimeInMilliseconds());
      msg.bandwidth = DataRate::BitsPerSec(bitrate);
      task_queue_.RunOrPost([this, msg]() {
         RTC_DCHECK_RUN_ON(&task_queue_);
         if (controller_)
            PostUpdates(controller_->OnRemoteBitrateReport(msg));
      });
   }

之后回调到 GoogCcNetworkController 也就 GCC 的核心类

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

* third_party/webrtc/modules/congestion_controller/goog_cc/send_side_bandwidth_estimation.cc

.. code-block:: c++

   void SendSideBandwidthEstimation::UpdateReceiverEstimate(Timestamp at_time,
                                                            DataRate bandwidth) {
      // TODO(srte): Ensure caller passes PlusInfinity, not zero, to represent no
      // limitation.
      receiver_limit_ = bandwidth.IsZero() ? DataRate::PlusInfinity() : bandwidth;
      ApplyTargetLimits(at_time);
   }


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

   void SendSideBandwidthEstimation::ApplyTargetLimits(Timestamp at_time) {
      UpdateTargetBitrate(current_target_, at_time);
   }

   DataRate SendSideBandwidthEstimation::GetUpperLimit() const {
      DataRate upper_limit = delay_based_limit_;
      if (disable_receiver_limit_caps_only_)
         upper_limit = std::min(upper_limit, receiver_limit_);
      return std::min(upper_limit, max_bitrate_configured_);
   }


注：这里的 GetUpperLimit() 中应用了 REMB 设定的最大带宽， 和当前带宽的最大值进行比较，取其较小的值进行速率调整



.. code-block:: c++

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


Algorigthm
=======================================

* pre-filtering 预先过滤
* arrival-time filter 到达时间过滤器
* over-use detector 过度使用检测器
* rate-control 速率控制器


由于延迟梯度的测量精度很小, 为了避免网络噪音带来的误差, 利用了卡尔曼滤波来平滑延迟梯度的测量结果。

WebRTC的实现中, 并不是单纯的测量单个数据包彼此之间的延迟梯度, 而是将数据包按发送时间间隔和到达时间间隔分组, 计算组间的整体延迟梯度。分组规则是：

1. 发送时间间隔小于5ms的数据包被归为一组,

   这是由于WebRTC的发送端实现了一个平滑发送模块, 该模块的发送间隔是5ms发送一批数据包。

2. 到达时间间隔小于5ms的数据包被归为一组

   这是由于在wifi网络下, 某些wifi设备的转发模式是, 在某个固定时间片内才有机会转发数据包, 这个时间片的间隔可能长达100ms, 造成的结果是100ms的数据包堆积, 并在发送时形成burst, 这个busrt内的所有数据包就会被视为一组。

为了计算延迟梯度, 除了接收端要反馈每个媒体包的接受状态, 同时发送端也要记录每个媒体包的发送状态, 记录其发送的时间值。在这个情况下abs-send-time扩展不再需要。


Key metrics
------------------------
* inter-group delay variaration:

.. code-block::

  d(i) = w(i) = m(i) - v(i)

1) Pre-filtering to handle delay transients caused by channel outages
2) Arrival-time filter: use kalman filter to estimate m(i)


Class and Snippets
==========================

modules
------------------------
* `congestion_controller`_
* `remote_bitrate_estimator`_

.. _congestion_controller: https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/congestion_controller/
.. _remote_bitrate_estimator: https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/remote_bitrate_estimator

classes
-----------------------
* RemoteBitrateEstimatorAbsSendTime



.. code-block:: cpp


   // Instantiate RBE for Time Offset or Absolute Send Time extensions.
   void ReceiveSideCongestionController::PickEstimator() {
      if (using_absolute_send_time_) {
         rbe_ = std::make_unique<RemoteBitrateEstimatorAbsSendTime>(&remb_throttler_,
                                                                     &clock_);
      } else {
         rbe_ = std::make_unique<RemoteBitrateEstimatorSingleStream>(
            &remb_throttler_, &clock_);
      }
   }

   void ReceiveSideCongestionController::OnReceivedPacket(
         int64_t arrival_time_ms,
         size_t payload_size,
         const RTPHeader& header) {
      remote_estimator_proxy_.IncomingPacket(arrival_time_ms, payload_size, header);
      if (!header.extension.hasTransportSequenceNumber) {
         // Receive-side BWE.
         MutexLock lock(&mutex_);
         PickEstimatorFromHeader(header);
         rbe_->IncomingPacket(arrival_time_ms, payload_size, header);
      }
   }


接收方带宽估算的核心代码参见 `remote_bitrate_estimator_abs_send_time.cc`_


.. _remote_bitrate_estimator_abs_send_time.cc : https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/remote_bitrate_estimator/remote_bitrate_estimator_abs_send_time.cc;l=230


* Sender pseudocode code

(send_side_bandwidth_estimation.cc):


.. code-block::

 onFeedbackFromReceiver(lossRate):

    if (lossRate < 2%) video_bitrate *= 1.08

    if (lossRate > 10%) video_bitrate *= (1 - 0.5 * lossRate)

    if (video_bitrate > bwe) video_bitrate = bwe;
