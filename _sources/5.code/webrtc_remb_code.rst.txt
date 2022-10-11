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
