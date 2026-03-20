
##############################
Remote Bitrate Estimator
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ================================
**Abstract** 远端比特率估计器
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ================================



.. contents::
   :local:

概述
=============

RemoteBitrateEstimator 是 WebRTC 接收端带宽估计的核心组件。
它通过分析接收到的 RTP 包的到达时间和大小，估算网络可用带宽，
并检测网络是否过载（Overuse）。

在 GCC（Google Congestion Control）算法中，它属于 **基于延迟的估计器**（Delay-based estimator），
与发送端的基于丢包估计器协同工作。

.. code-block:: text

   ┌────────────────────────────────────────────────────┐
   │                    接收端                           │
   │                                                    │
   │  RTP 包到达                                        │
   │      │                                             │
   │      ▼                                             │
   │  ┌─────────────────────────────────┐               │
   │  │   InterArrival                  │               │
   │  │   计算包间到达时间差            │               │
   │  │   和发送时间差                  │               │
   │  └──────────┬──────────────────────┘               │
   │             │ (arrival_delta, send_delta)           │
   │             ▼                                      │
   │  ┌─────────────────────────────────┐               │
   │  │   OveruseEstimator              │               │
   │  │   Kalman 滤波估计传播延迟斜率   │               │
   │  └──────────┬──────────────────────┘               │
   │             │ (offset)                             │
   │             ▼                                      │
   │  ┌─────────────────────────────────┐               │
   │  │   OveruseDetector               │               │
   │  │   判断当前网络状态              │               │
   │  │   Normal / Overuse / Underuse   │               │
   │  └──────────┬──────────────────────┘               │
   │             │                                      │
   │             ▼                                      │
   │  ┌─────────────────────────────────┐               │
   │  │   AimdRateControl               │               │
   │  │   AIMD 算法调整估计比特率       │               │
   │  │   Overuse → 乘性降低 (×0.85)    │               │
   │  │   Underuse → 加性增加           │               │
   │  └──────────┬──────────────────────┘               │
   │             │                                      │
   │             ▼                                      │
   │  通过 REMB / TWCC 反馈给发送端                     │
   └────────────────────────────────────────────────────┘


带宽使用状态
==============

.. code-block:: c++

   enum class BandwidthUsage {
       kBwNormal = 0,      // 正常：可以适度增加发送率
       kBwUnderusing = 1,  // 欠载：网络有余量
       kBwOverusing = 2,   // 过载：网络拥塞，必须降低发送率
       kLast
   };


核心接口
==============

.. code-block:: c++

   class RemoteBitrateEstimator : public CallStatsObserver, public Module {
   public:
       // 每收到一个 RTP 包时调用
       // 更新带宽估计和过载检测
       virtual void IncomingPacket(int64_t arrival_time_ms,
                                   size_t payload_size,
                                   const RTPHeader& header) = 0;

       // 移除指定 SSRC 的流数据
       virtual void RemoveStream(uint32_t ssrc) = 0;

       // 获取最新的带宽估计值
       virtual bool LatestEstimate(std::vector<uint32_t>* ssrcs,
                                   uint32_t* bitrate_bps) const = 0;

       // 设置最小比特率下限
       virtual void SetMinBitrate(int min_bitrate_bps) = 0;

   protected:
       static const int64_t kProcessIntervalMs = 500;   // 处理间隔
       static const int64_t kStreamTimeOutMs = 2000;     // 流超时
   };


关键子模块
==============

InterArrival
--------------------------

计算包组（packet group）的到达时间差和发送时间差：

.. code-block:: text

   send_delta    = send_time[i] - send_time[i-1]
   arrival_delta = arrival_time[i] - arrival_time[i-1]
   delay_delta   = arrival_delta - send_delta

- ``delay_delta > 0``：包在网络中排队时间增加，可能过载
- ``delay_delta < 0``：包在网络中排队时间减少，网络有余量
- ``delay_delta ≈ 0``：网络稳定

OveruseEstimator
--------------------------

使用 **Kalman 滤波器** 对 delay_delta 序列进行平滑估计，
输出传播延迟的斜率（offset），过滤掉噪声和突发抖动。

OveruseDetector
--------------------------

将 Kalman 滤波器的输出与自适应阈值比较：

- ``offset > threshold`` → **Overuse**
- ``offset < -threshold`` → **Underuse**
- 其他 → **Normal**

阈值本身也是自适应的，会根据网络状况动态调整。

AimdRateControl
--------------------------

根据检测结果调整估计比特率（AIMD = Additive Increase Multiplicative Decrease）：

- **Overuse**：比特率 *= 0.85（乘性降低，快速退让）
- **Normal/Underuse**：比特率 += increment（加性增加，缓慢探测）

这与 TCP 的 AIMD 拥塞控制思想一致。


新旧版本演进
==============

.. list-table::
   :header-rows: 1
   :widths: 15 40 45

   * - 版本
     - 机制
     - 说明
   * - 旧版
     - REMB (Receiver Estimated Maximum Bitrate)
     - 接收端估计带宽，通过 RTCP REMB 反馈给发送端
   * - 新版
     - TWCC (Transport-Wide Congestion Control)
     - 接收端只反馈包到达时间，带宽估计移到发送端

现代 WebRTC 主要使用 TWCC，发送端的 ``SendSideBandwidthEstimation`` 取代了
接收端的 ``RemoteBitrateEstimator``。但理解 RemoteBitrateEstimator 的算法原理
对掌握 GCC 仍然至关重要，因为核心算法（InterArrival → Kalman → AIMD）未变。

详见 :doc:`webrtc_bwe_remb` 和 :doc:`../5.qos/webrtc_twcc`。


参考资料
==================

- `RemoteBitrateEstimator 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/remote_bitrate_estimator/>`_
- `AimdRateControl 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/remote_bitrate_estimator/aimd_rate_control.h>`_
- `InterArrival 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/remote_bitrate_estimator/inter_arrival.h>`_
- `CongestionController 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/congestion_controller/>`_
