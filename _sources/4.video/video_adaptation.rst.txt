######################
video adaptation
######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Video Adaptation
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=========

视频自适应 (Video Adaptation) 是 WebRTC 中至关重要的机制之一。它使得视频通信能够在不同的网络条件和设备能力下，
动态调整视频的编码参数，以达到最佳的用户体验。

video 的编码或传输质量会受到网络带宽和设备能力的影响。

网络质量不佳，带宽受限，如果还要发送高质量的视频会很困难，因为质量越高，码率越大，所以我们需要降低传送的码率。
如果用户可以接受低质量的视频，那么这时候可以降低分辨率。如果用户不接受低质量视频，那么就需要忍受延迟，降低帧率或者有些丢帧。

另一方面，用于 WebRTC 应用的设备往往参差不齐，有高大上的 macbook pro, 也有老掉牙的老笔记本或台式机，或者轻便小巧的平板。
多媒体特别是视频的编解码是很耗费资源的, 这时候，需要根据设备的资源消耗情况，实时调整编码质量，如分辨率，帧率等，避免对系统资源主要是 CPU 的占用率过大。


为什么需要视频自适应
========================

视频自适应的必要性来自于以下几个方面：

1. **网络条件的动态变化**: 互联网的带宽并非恒定不变。用户可能从 Wi-Fi 切换到蜂窝网络，或者网络拥塞导致可用带宽骤降。
   如果视频编码器不能及时响应这些变化，就会导致严重的丢包、延迟增大和视频卡顿。

2. **设备能力的差异**: 参与 WebRTC 通话的设备性能差异巨大。高端桌面设备可以轻松处理 1080p@30fps 的编解码，
   而低端移动设备可能连 720p@15fps 都很吃力。编码器需要根据设备的 CPU 负载动态调整。

3. **内容类型的不同**: 摄像头采集的视频和屏幕共享的内容有着截然不同的特征。摄像头视频通常运动较多，
   对帧率敏感；屏幕共享通常是静态文本和图表，对分辨率（清晰度）更敏感。

4. **多方通话的资源竞争**: 在多方视频会议中，多路视频流共享有限的上行带宽和 CPU 资源，
   需要在各路流之间进行合理的资源分配。

5. **用户体验的平衡**: 在带宽受限时，是保持流畅的帧率还是保持清晰的分辨率？不同的应用场景有不同的偏好，
   自适应机制需要提供灵活的策略选择。


自适应的维度
========================

视频自适应主要在以下几个维度上进行调整：

分辨率自适应 (Spatial Adaptation)
------------------------------------

分辨率自适应通过降低或提高视频的空间分辨率来调整码率。当网络带宽不足或 CPU 负载过高时，
降低分辨率可以显著减少编码所需的码率和计算量。

WebRTC 中的分辨率降级策略采用分步降级的方式，常见的缩放比例包括：

* **3/4 缩放**: 例如从 1280x720 降至 960x540，码率大约降低 40%
* **1/2 缩放**: 例如从 1280x720 降至 640x360，码率大约降低 70%
* **1/4 缩放**: 例如从 1280x720 降至 320x180，码率大约降低 90%

分辨率的降级和升级并不是对称的。降级时可以较快地响应（避免网络拥塞恶化），
而升级时需要更加保守（避免频繁的分辨率切换导致视觉不适）。

在 WebRTC 内部，``VideoStreamEncoder`` 通过 ``VideoSourceRestrictions`` 来通知视频源
（通常是 ``VideoCaptureModule`` 或 ``VideoAdapter``）调整输出分辨率：

.. code-block:: cpp

   struct VideoSourceRestrictions {
     absl::optional<size_t> max_pixels_per_frame;
     absl::optional<size_t> target_pixels_per_frame;
     absl::optional<double> max_frame_rate;
   };

``QualityScaler`` 是分辨率自适应的核心组件之一。它通过监控编码后帧的 QP (Quantization Parameter) 值
来判断当前分辨率是否合适：

* 当 QP 持续偏高时，说明编码器在当前码率下难以维持当前分辨率的质量，应该降低分辨率
* 当 QP 持续偏低时，说明编码器有余力，可以尝试提高分辨率

不同编解码器的 QP 阈值不同：

.. csv-table:: 各编解码器的 QP 阈值
   :header: "Codec", "Low QP (可升级)", "High QP (需降级)"
   :widths: 20, 40, 40

   "VP8", "24", "95"
   "VP9", "27 (单层) / 55 (SVC)", "205 (单层) / 170 (SVC)"
   "H.264", "24", "37"
   "AV1", "40", "205"


帧率自适应 (Temporal Adaptation)
------------------------------------

帧率自适应通过降低视频的帧率来减少码率和 CPU 负载。这种方式保持了每一帧的清晰度，
但牺牲了视频的流畅性。

帧率降级的常见策略包括：

* **直接丢帧 (Frame Dropping)**: ``VideoAdapter`` 根据目标帧率，按照一定的间隔丢弃输入帧。
  例如从 30fps 降到 15fps，每隔一帧丢弃一帧。

* **Temporal Layer 丢弃**: 在使用 SVC (Scalable Video Coding) 或 temporal scalability 时，
  可以选择性地丢弃高层的 temporal layer，从而降低帧率。例如 VP8 的 temporal scalability
  支持 1/2/4 层，丢弃最高层可以将帧率减半。

帧率自适应的步进通常为：

* 30fps → 20fps → 15fps → 10fps → 7fps（最低限制）

在 ``VideoStreamEncoder`` 中，帧率限制通过 ``max_frame_rate`` 传递给 ``VideoAdapter``：

.. code-block:: cpp

   // VideoAdapter 中的帧率控制
   bool VideoAdapter::AdaptFrameResolution(
       int in_width, int in_height, int64_t in_timestamp_ns,
       int* cropped_width, int* cropped_height,
       int* out_width, int* out_height) {
     // 根据 max_framerate_ 决定是否丢弃当前帧
     if (max_framerate_ && !keep_frame_requester_.ShouldKeepFrame(
             in_timestamp_ns, *max_framerate_)) {
       return false;  // 丢弃此帧
     }
     // ... 分辨率调整逻辑
   }


码率/质量自适应 (Bitrate/Quality Adaptation)
------------------------------------------------

码率自适应是最直接的调整方式。当拥塞控制模块 (Congestion Controller) 估计出新的可用带宽时，
``BitrateAllocator`` 会重新分配各路视频流的目标码率，编码器据此调整编码参数。

码率调整涉及以下参数：

* **目标码率 (Target Bitrate)**: 编码器的目标输出码率，由拥塞控制模块决定
* **QP (Quantization Parameter)**: 量化参数，QP 越大压缩越狠，质量越差
* **编码复杂度 (Encoding Complexity)**: 某些编码器支持调整编码复杂度以平衡质量和 CPU 消耗

.. code-block:: cpp

   // 编码器码率设置
   void VideoStreamEncoder::OnBitrateUpdated(
       DataRate target_bitrate,
       DataRate stable_target_bitrate,
       DataRate link_allocation,
       uint8_t fraction_lost,
       int64_t round_trip_time_ms,
       double cwnd_reduce_ratio) {
     // 更新编码器的目标码率
     encoder_->SetRates(VideoEncoder::RateControlParameters(
         allocation, framerate_fps, link_allocation));
   }


内容类型自适应 (Content Type Adaptation)
--------------------------------------------

不同的内容类型需要不同的自适应策略：

**摄像头视频 (Camera Video)**:

* 运动较多，帧间差异大
* 对帧率敏感，低帧率会导致明显的卡顿感
* 默认策略通常是 ``MAINTAIN_FRAMERATE``，优先保持帧率
* 适当降低分辨率对用户体验影响较小

**屏幕共享 (Screen Share)**:

* 大部分时间是静态内容，偶尔有鼠标移动或窗口切换
* 对分辨率（清晰度）极其敏感，文字模糊会严重影响可读性
* 默认策略通常是 ``MAINTAIN_RESOLUTION``，优先保持分辨率
* 帧率可以很低（5-10fps）而不影响体验
* 通常使用 VP8/VP9 的 screen content coding 模式

.. code-block:: cpp

   // 根据内容类型设置自适应策略
   switch (content_hint) {
     case ContentHint::kFluid:
       // 视频内容，保帧率
       degradation_preference = DegradationPreference::MAINTAIN_FRAMERATE;
       break;
     case ContentHint::kDetailed:
     case ContentHint::kText:
       // 屏幕共享/文本内容，保分辨率
       degradation_preference = DegradationPreference::MAINTAIN_RESOLUTION;
       break;
     case ContentHint::kNone:
       // 使用默认策略
       break;
   }


自适应策略 (Degradation Preference)
========================================

对于视频的调整, 主要是调帧率和分辨率, 策略有 3 种

* MAINTAIN_FRAMERATE：保帧率，降分辨率，该模式的使用场景为视频模式。
* MAINTAIN_RESOLUTION: 保分辨率降帧率，使用场景为屏幕共享或者文档模式，对清晰度要求较高的场景。
* BALANCED: 平衡帧率与分辨率。

.. code-block::

   enum class DegradationPreference {
      // Don't take any actions based on over-utilization signals. Not part of the
      // web API.
      DISABLED,
      // On over-use, request lower resolution, possibly causing down-scaling.
      MAINTAIN_FRAMERATE,
      // On over-use, request lower frame rate, possibly causing frame drops.
      MAINTAIN_RESOLUTION,
      // Try to strike a "pleasing" balance between frame rate or resolution.
      BALANCED,
   };


DISABLED 模式
--------------------

``DISABLED`` 模式下，自适应机制完全关闭。编码器不会根据 CPU 或网络状况自动调整分辨率和帧率。
这种模式适用于对视频质量有严格要求且网络条件可控的场景，例如局域网内的高质量视频传输。

.. warning::

   使用 ``DISABLED`` 模式时需要格外小心。如果网络条件恶化，编码器不会自动降级，
   可能导致严重的丢包和延迟。


MAINTAIN_FRAMERATE 模式
--------------------------

在此模式下，当检测到过载时，系统优先降低分辨率以保持帧率。适用于视频通话等对流畅性要求较高的场景。

降级顺序示例（假设初始为 1280x720@30fps）：

1. 1280x720@30fps → 960x540@30fps（分辨率降一级）
2. 960x540@30fps → 640x360@30fps（分辨率再降一级）
3. 640x360@30fps → 320x180@30fps（分辨率继续降级）


MAINTAIN_RESOLUTION 模式
----------------------------

在此模式下，当检测到过载时，系统优先降低帧率以保持分辨率。适用于屏幕共享等对清晰度要求较高的场景。

降级顺序示例（假设初始为 1280x720@30fps）：

1. 1280x720@30fps → 1280x720@20fps（帧率降一级）
2. 1280x720@20fps → 1280x720@15fps（帧率再降一级）
3. 1280x720@15fps → 1280x720@10fps（帧率继续降级）


BALANCED 模式
--------------------

``BALANCED`` 模式试图在帧率和分辨率之间找到一个平衡点。它使用 ``BalancedDegradationSettings``
来定义在不同分辨率下的帧率下限：

.. code-block:: cpp

   // BalancedDegradationSettings 的默认配置
   // 当像素数 >= 921600 (1280x720) 时，最低帧率 7fps
   // 当像素数 >= 230400 (640x360) 时，最低帧率 10fps
   // 当像素数 >= 57600 (320x180) 时，最低帧率 15fps

降级逻辑：

1. 首先降低帧率到当前分辨率对应的最低帧率
2. 如果帧率已经到达下限，则降低分辨率
3. 降低分辨率后，帧率恢复到新分辨率对应的初始帧率
4. 重复上述过程


WebRTC 自适应流水线
========================

WebRTC 的视频自适应涉及多个模块的协作，形成一个完整的反馈控制回路：

.. code-block:: text

   ┌─────────────────┐     ┌──────────────────────┐     ┌───────────────────┐
   │  OveruseDetector │────▶│ AdaptationController │────▶│ VideoStreamEncoder│
   │  (CPU 过载检测)   │     │  (自适应决策)          │     │  (编码参数调整)     │
   └─────────────────┘     └──────────────────────┘     └───────────────────┘
           ▲                         ▲                           │
           │                         │                           │
   ┌───────┴─────────┐     ┌────────┴──────────┐               │
   │ Encode Time      │     │ QualityScaler     │               │
   │ (编码耗时统计)    │     │ (QP 质量监控)      │               │
   └─────────────────┘     └───────────────────┘               │
                                     ▲                           │
                                     │                           ▼
                            ┌────────┴──────────┐     ┌───────────────────┐
                            │ Encoded Frame QP   │◀────│ Video Encoder     │
                            │ (编码帧 QP 值)      │     │ (视频编码器)       │
                            └───────────────────┘     └───────────────────┘

核心组件说明：

**OveruseDetector (过载检测器)**

``OveruseDetector`` 通过监控视频帧的编码耗时来判断 CPU 是否过载。它使用 Kalman Filter
来估计编码耗时的趋势：

.. code-block:: cpp

   // OveruseDetector 的核心逻辑
   class OveruseFrameDetector {
    public:
     // 每帧编码完成后调用
     void FrameSent(uint32_t timestamp,
                    int64_t time_sent_in_ms,
                    int64_t capture_time_ms,
                    absl::optional<int> encode_duration_ms);

    private:
     // 使用 Kalman Filter 估计编码耗时趋势
     // 当编码耗时持续增长时，判定为 overuse
     // 当编码耗时持续下降时，判定为 underuse
     OveruseEstimator estimator_;
     double threshold_;  // 过载判定阈值
   };


**AdaptationController (自适应控制器)**

``VideoStreamEncoderResourceManager`` 是自适应控制的核心，它协调各种资源信号
（CPU、Quality、Bandwidth）并做出自适应决策：

.. code-block:: cpp

   // 资源使用状态
   enum class ResourceUsageState {
     kOveruse,   // 过载，需要降级
     kUnderuse,  // 欠载，可以升级
   };

   // VideoStreamEncoderResourceManager 管理多个 Resource
   // 每个 Resource 可以独立报告 overuse/underuse
   class VideoStreamEncoderResourceManager {
     void OnResourceUsageStateMeasured(
         rtc::scoped_refptr<Resource> resource,
         ResourceUsageState usage_state);
   };


**QualityScaler (质量缩放器)**

QualityScaler 是基于编码质量的自适应组件。它通过统计编码帧的 QP 值来判断是否需要调整分辨率：

.. code-block:: cpp

   class QualityScaler {
    public:
     // 报告编码帧的 QP 值
     void ReportQp(int qp, bool dropped);

    private:
     // 使用滑动窗口统计 QP 均值
     // 当 QP 均值 > high_qp_threshold 时，报告 overuse
     // 当 QP 均值 < low_qp_threshold 时，报告 underuse
     MovingAverage average_qp_;
     VideoEncoder::QpThresholds thresholds_;
   };


自适应触发条件
========================

视频自适应可以由以下几种条件触发：

CPU 过载 (CPU Overuse)
--------------------------

当视频编码耗时超过帧间隔的一定比例时，``OveruseFrameDetector`` 会判定为 CPU 过载。

判定逻辑：

* 编码耗时通过 Kalman Filter 进行平滑估计
* 当估计的编码耗时趋势超过阈值时，触发 overuse 信号
* 默认阈值约为帧间隔的 85%（即 30fps 时约 28ms）
* 连续多次检测到 overuse 才会触发降级，避免瞬时波动

.. code-block:: cpp

   // CPU 过载检测的关键参数
   struct CpuOveruseOptions {
     int high_encode_usage_threshold_percent = 85;  // 编码耗时占比阈值
     int frame_timeout_interval_ms = 1500;          // 帧超时间隔
     int min_frame_samples = 120;                   // 最小采样帧数
     int min_process_count = 3;                     // 最小处理次数
   };


带宽限制 (Bandwidth Limitation)
------------------------------------

当拥塞控制模块 (GCC/SendSideBWE) 检测到网络拥塞时，会降低估计的可用带宽。
``BitrateAllocator`` 据此重新分配各路流的码率。当分配的码率低于编码器在当前分辨率下的最低码率时，
会触发分辨率降级。

.. code-block:: cpp

   // 当码率不足以支撑当前分辨率时
   void VideoStreamEncoder::OnBitrateUpdated(...) {
     if (target_bitrate < min_bitrate_for_current_resolution) {
       // 触发 quality adaptation (降分辨率)
       quality_scaler_resource_->SetQpThresholds(...);
     }
   }


质量限制 (Quality Limitation)
------------------------------------

当编码器的 QP 值持续偏高时，说明在当前码率下无法维持当前分辨率的视频质量。
``QualityScaler`` 会触发降级信号。

这种情况通常发生在：

* 网络带宽突然下降，但分辨率还未来得及调整
* 视频内容突然变得复杂（如从静态画面切换到快速运动）
* 编码器性能不足以处理当前分辨率


qualityLimitationReason
--------------------------

WebRTC 的 Stats API 提供了 ``qualityLimitationReason`` 字段，用于报告当前视频质量受限的原因：

.. code-block:: javascript

   // 获取视频发送统计信息
   const stats = await peerConnection.getStats();
   stats.forEach(report => {
     if (report.type === 'outbound-rtp' && report.kind === 'video') {
       console.log('Quality limitation reason:', report.qualityLimitationReason);
       // 可能的值: "none", "cpu", "bandwidth", "other"

       console.log('Quality limitation durations:', report.qualityLimitationDurations);
       // 各种限制原因的累计时长 (ms)
       // { none: 15000, cpu: 2000, bandwidth: 3000, other: 0 }

       console.log('Adaptation changes:', report.qualityLimitationResolutionChanges);
       // 分辨率变化的次数
     }
   });


自适应迟滞 (Adaptation Hysteresis)
========================================

为了避免频繁的升降级切换（即 "振荡" 现象），WebRTC 的自适应机制引入了迟滞 (hysteresis) 策略：

降级与升级的不对称性
--------------------------

* **降级 (Step-down)**: 响应较快，通常在检测到 overuse 后很快执行降级。
  这是因为过载状态如果不及时处理，会导致用户体验急剧恶化。

* **升级 (Step-up)**: 响应较慢，需要持续检测到 underuse 一段时间后才执行升级。
  这是因为升级后如果立即又需要降级，会导致视频质量频繁波动。

冷却期 (Cooldown Period)
--------------------------

在执行一次降级或升级后，系统会进入一个冷却期，在此期间不会执行新的自适应操作：

* 降级后的冷却期通常较短（约 2-3 秒）
* 升级后的冷却期通常较长（约 5-10 秒）

.. code-block:: cpp

   // 自适应冷却期的实现
   // 在 ResourceAdaptationProcessor 中
   bool ResourceAdaptationProcessor::HasSufficientInputForAdaptation(
       const AdaptationConstraint& constraint) const {
     // 检查距离上次自适应操作是否已经过了足够的时间
     if (last_adaptation_time_ &&
         clock_->TimeInMilliseconds() - *last_adaptation_time_ <
             kMinTimeBetweenAdaptationsMs) {
       return false;
     }
     return true;
   }

QP 阈值的迟滞
--------------------------

``QualityScaler`` 的 QP 阈值也体现了迟滞设计：

* 降级阈值 (high_qp_threshold) 和升级阈值 (low_qp_threshold) 之间有较大的间隔
* 例如 VP8 的降级阈值为 95，升级阈值为 24，中间有很大的缓冲区
* 这确保了只有在质量确实很差或确实很好时才会触发自适应


webrtc api 层提供了自适应策略的设置接口，通过设置 videotrack 的 ContentHint 属性就可以了。

.. code-block::

  enum class ContentHint { kNone, kFluid, kDetailed, kText };


ContentHint 为 kDetailed/kText 暗示了编码器保持分辨率，降帧率，设置为 kFluid，暗示编码器保持帧率，示例：

.. code-block::

   void StartVideo(){
   			.....
        auto track = mSharedFactory->createVideoTrack(tag, source);
   			track->set_content_hint(webrtc::VideoTrackInterface::ContentHint::kFluid);
 }


Device adaptation
========================

设备的计算和存储资源对于视频的编解码, 捕获和渲染是有很大影响的. 如果设备性能太差, 则不适合进行高分辨率和高帧率的视频编解码.

在 webrtc library 中的 video 模块中有一个子模块 adaption, 它主要有如下的类来适应设备和网络状态

EncodeUsageResource
--------------------------

``EncodeUsageResource`` 封装了与 ``OveruseFrameDetector`` 的交互。它监控编码器的 CPU 使用情况，
并在检测到过载或欠载时通知 ``ResourceAdaptationProcessor``。

.. code-block:: cpp

   class EncodeUsageResource : public Resource,
                               public OveruseFrameDetectorObserverInterface {
    public:
     // 当 OveruseDetector 检测到过载时回调
     void AdaptUp() override {
       OnResourceUsageStateMeasured(ResourceUsageState::kUnderuse);
     }
     void AdaptDown() override {
       OnResourceUsageStateMeasured(ResourceUsageState::kOveruse);
     }
   };

其内部的 ``OveruseFrameDetector`` 使用以下算法：

1. 记录每帧的编码开始时间和结束时间
2. 计算编码耗时占帧间隔的比例 (encode usage)
3. 使用 Kalman Filter 对 encode usage 进行平滑估计
4. 当平滑后的 encode usage 超过阈值时，判定为 overuse
5. 当平滑后的 encode usage 低于阈值时，判定为 underuse


QualityScaler
--------------------------

QualityScaler runs asynchronously and monitors QP values of encoded frames.
It holds a reference to a QualityScalerQpUsageHandlerInterface implementation to signal an overuse or underuse of QP
(which indicate a desire to scale the video stream down or up).

``QualityScaler`` 的工作流程：

1. 编码器每编码一帧，将该帧的 QP 值报告给 ``QualityScaler``
2. ``QualityScaler`` 维护一个滑动窗口，统计最近 N 帧的 QP 均值
3. 定期（默认每秒）检查 QP 均值是否超出阈值范围
4. 如果 QP 均值 > high_threshold，报告 overuse（需要降分辨率）
5. 如果 QP 均值 < low_threshold，报告 underuse（可以升分辨率）

.. code-block:: cpp

   // QualityScaler 的采样窗口配置
   static constexpr int kSamplePeriodMs = 1000;  // 采样周期 1 秒
   // 降级需要连续多个采样周期都超过阈值
   // 升级需要连续更多个采样周期都低于阈值


QualityScalerQpUsageHandlerInterface
------------------------------------------

Reacts to QP being too high or too low.

For best quality, when QP is high it is desired to decrease the resolution or frame rate of the stream and when QP is low it is desired to increase the resolution or frame rate of the stream.

Whether to reconfigure the stream is ultimately up to the handler, which is able to respond asynchronously.


Network adaptation
========================

WebRTC 有一个网络拥塞和带宽估计的模块, 当检测到网络带宽有变化的(over-use, under-use), 就可以来调整视频的分辨率或帧率

网络自适应的完整流程：

1. **带宽估计**: GCC (Google Congestion Control) 或 SendSideBWE 持续估计可用带宽
2. **码率分配**: ``BitrateAllocator`` 根据估计带宽为各路视频流分配码率
3. **编码器调整**: ``VideoStreamEncoder`` 根据分配的码率调整编码参数
4. **分辨率/帧率调整**: 如果分配的码率不足以支撑当前分辨率，触发降级

.. code-block:: text

   Network Congestion
         │
         ▼
   GCC/SendSideBWE ──▶ Estimated Bandwidth
         │
         ▼
   BitrateAllocator ──▶ Per-stream Bitrate
         │
         ▼
   VideoStreamEncoder ──▶ Encoder Rate Control
         │
         ▼
   QualityScaler ──▶ Resolution/Framerate Adaptation


.. csv-table:: 分辨率对应的大约带宽
   :header: "bandwidth", "Resolution", "Comments"
   :widths: 30, 30, 30


   64kbps,   90p,	"160 x 90"
   128kbps,   180p,	"320 x 180"
   448kbps,   360p,	"640 x 360"
   1536kbps,   720p,	"1280 x 720"
   4mbps,   1080p,	"1920 x 1080, may more than 4mbps, 2mbps at least"
   12mbps,   2K,    "3840 × 2160, may more than 12mbps"
   20mbps,   4K,    "7680 × 4320, may more than 20mbps"


SFU 侧的自适应
========================

除了发送端的自适应，SFU (Selective Forwarding Unit) 也可以在服务器侧进行自适应：

Simulcast 层选择
--------------------------

在 Simulcast 模式下，发送端同时编码多路不同分辨率的视频流（通常 3 路）。
SFU 根据接收端的网络条件和显示需求，选择转发合适的层：

.. code-block:: text

   发送端编码:
   ┌─────────────────┐
   │ High:  1280x720  │ ──┐
   │ Mid:   640x360   │ ──┤──▶ SFU ──▶ 根据接收端条件选择转发
   │ Low:   320x180   │ ──┘
   └─────────────────┘

SFU 的层选择策略：

* 根据接收端的可用带宽选择最高可承受的层
* 根据接收端的显示窗口大小选择合适的分辨率
* 在网络波动时可以快速切换到低层，无需等待发送端重新编码

Temporal Layer 转发
--------------------------

对于支持 temporal scalability 的编码（如 VP8/VP9 的 temporal layers），
SFU 可以选择性地转发不同的 temporal layer：

* 转发所有层：接收端获得完整帧率
* 丢弃最高层：接收端帧率减半
* 只转发基础层：接收端获得最低帧率

这种方式的优势是不需要发送端做任何调整，SFU 可以为每个接收端独立决策。


JavaScript API 配置
========================

在 JavaScript 层面，可以通过以下方式配置视频自适应：

MediaTrackConstraints
--------------------------

.. code-block:: javascript

   // 设置视频采集约束
   const constraints = {
     video: {
       width: { ideal: 1280, max: 1920 },
       height: { ideal: 720, max: 1080 },
       frameRate: { ideal: 30, max: 60 },
       // 设置内容提示
     }
   };

   const stream = await navigator.mediaDevices.getUserMedia(constraints);
   const videoTrack = stream.getVideoTracks()[0];

   // 设置内容提示，影响自适应策略
   videoTrack.contentHint = 'motion';      // 类似 kFluid，保帧率
   // videoTrack.contentHint = 'detail';   // 类似 kDetailed，保分辨率
   // videoTrack.contentHint = 'text';     // 类似 kText，保分辨率


RTCRtpSender 参数
--------------------------

.. code-block:: javascript

   const sender = peerConnection.getSenders().find(s => s.track.kind === 'video');
   const params = sender.getParameters();

   // 设置 degradationPreference
   params.degradationPreference = 'maintain-framerate';
   // 可选值: 'maintain-framerate', 'maintain-resolution', 'balanced', 'disabled'

   // 调整编码参数
   params.encodings[0].maxBitrate = 2000000;  // 2 Mbps
   params.encodings[0].maxFramerate = 30;
   params.encodings[0].scaleResolutionDownBy = 1.0;  // 不缩放

   await sender.setParameters(params);


Simulcast 配置
--------------------------

.. code-block:: javascript

   // 配置 Simulcast 多层编码
   const transceiver = peerConnection.addTransceiver('video', {
     sendEncodings: [
       { rid: 'low', maxBitrate: 200000, scaleResolutionDownBy: 4.0 },
       { rid: 'mid', maxBitrate: 700000, scaleResolutionDownBy: 2.0 },
       { rid: 'high', maxBitrate: 2500000 },
     ]
   });


性能指标监控
========================

通过 WebRTC Stats API 可以监控视频自适应的各项指标：

.. code-block:: javascript

   async function monitorAdaptation(pc) {
     const stats = await pc.getStats();
     stats.forEach(report => {
       if (report.type === 'outbound-rtp' && report.kind === 'video') {
         // 当前质量受限原因
         console.log('qualityLimitationReason:', report.qualityLimitationReason);

         // 各种限制原因的累计时长
         console.log('qualityLimitationDurations:', report.qualityLimitationDurations);

         // 分辨率变化次数
         console.log('resolutionChanges:', report.qualityLimitationResolutionChanges);

         // 当前编码分辨率
         console.log('frameWidth:', report.frameWidth);
         console.log('frameHeight:', report.frameHeight);

         // 当前编码帧率
         console.log('framesPerSecond:', report.framesPerSecond);

         // 编码的总帧数
         console.log('framesEncoded:', report.framesEncoded);

         // 目标码率 vs 实际码率
         console.log('targetBitrate:', report.targetBitrate);

         // 丢弃的帧数（因为编码器来不及处理）
         console.log('hugeFramesSent:', report.hugeFramesSent);
       }
     });
   }

   // 定期监控
   setInterval(() => monitorAdaptation(peerConnection), 2000);

关键指标说明：

.. csv-table:: 自适应相关统计指标
   :header: "指标", "含义", "关注点"
   :widths: 30, 40, 30

   "qualityLimitationReason", "当前质量受限原因", "none/cpu/bandwidth/other"
   "qualityLimitationDurations", "各原因累计时长", "bandwidth 占比过高需关注"
   "qualityLimitationResolutionChanges", "分辨率变化次数", "频繁变化说明网络不稳定"
   "frameWidth/frameHeight", "当前编码分辨率", "与采集分辨率对比"
   "framesPerSecond", "当前编码帧率", "与目标帧率对比"
   "nackCount", "NACK 请求次数", "过多说明丢包严重"
   "pliCount", "PLI 请求次数", "过多说明关键帧丢失"


常见问题与调优
========================

1. **分辨率频繁切换**: 通常是因为网络带宽在临界值附近波动。可以通过增大迟滞区间或延长冷却期来缓解。

2. **CPU 过载导致帧率下降**: 检查是否有其他进程占用 CPU，或者考虑使用硬件编码器 (Hardware Encoder)。

3. **屏幕共享模糊**: 确保 ``contentHint`` 设置为 ``'detail'`` 或 ``'text'``，
   使自适应策略优先保持分辨率。

4. **低端设备卡顿**: 考虑降低初始分辨率，或使用 ``BALANCED`` 模式让系统自动找到合适的平衡点。

5. **Simulcast 层切换延迟**: SFU 在切换 Simulcast 层时可能需要等待关键帧。
   可以通过 PLI (Picture Loss Indication) 请求关键帧来加速切换。


Reference
================
* `Webrtc video framerate/resolution 自适应 <https://xie.infoq.cn/article/50b7931b8a023f8ca7f25d4e9>`_
* `overuse_frame_detector <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/overuse_frame_detector.h>`_
* `WebRTC Video Adaptation Source Code <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/>`_
* `RFC 7742`_ "WebRTC Video Processing and Codec Requirements"
* `W3C WebRTC Stats <https://www.w3.org/TR/webrtc-stats/>`_
* `WebRTC Ouality Scaler <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/video_coding/utility/quality_scaler.h>`_
* `Scalable Video Coding in WebRTC <https://webrtc.googlesource.com/src/+/refs/heads/main/docs/native-code/svc.md>`_
