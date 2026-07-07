
##############################
WebRTC OveruseFrameDetector
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ================================
**Abstract** WebRTC 过载检测与自适应降级
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ================================



.. contents::
   :local:

概述
=============

用户设备性能差异很大——高端桌面、低端手机、虚拟机等。
当视频编码的复杂度超过设备能力时，编码帧率下降、延迟增大，用户体验急剧恶化。

**OveruseFrameDetector** 是 WebRTC 中负责检测 CPU 过载的核心组件。
它通过监控编码耗时与采集间隔的比率，判断编码器是否跟不上采集速度，
然后触发自适应降级（降低分辨率或帧率）。

.. code-block:: text

   摄像头采集 (30fps = 33ms 间隔)
       │
       ▼
   ┌──────────────────────────┐
   │   OveruseFrameDetector   │
   │                          │
   │   编码占用率 = 编码耗时   │
   │                ────────  │
   │                采集间隔   │
   │                          │
   │   占用率 > 阈值 → 过载   │
   │   占用率 < 阈值 → 欠载   │
   └────────┬─────────────────┘
            │
            ▼
   ┌──────────────────────────┐
   │   QualityScaler /        │
   │   AdaptationController   │
   │                          │
   │   过载 → 降分辨率/帧率   │
   │   欠载 → 升分辨率/帧率   │
   └──────────────────────────┘


关键指标
==============

**编码占用率（Encode Usage）**

.. code-block:: text

   encode_usage = encode_duration / capture_interval

- ``encode_duration``：编码一帧所消耗的时间
- ``capture_interval``：两次采集之间的时间间隔（30fps 时约 33ms）

当 ``encode_usage`` 接近或超过 1.0 时，说明编码已经跟不上采集，必须降级。

两个指标都使用 **指数加权移动平均（EWMA）** 进行平滑，避免瞬时波动导致频繁升降级。


检测状态
==============

OveruseFrameDetector 输出三种状态：

.. list-table::
   :header-rows: 1
   :widths: 20 30 50

   * - 状态
     - 条件
     - 动作
   * - **Overuse**
     - 编码占用率持续高于上限阈值
     - 触发降级（降分辨率或帧率）
   * - **Underuse**
     - 编码占用率持续低于下限阈值
     - 触发升级（恢复分辨率或帧率）
   * - **Normal**
     - 编码占用率在阈值范围内
     - 维持当前设置


降级策略
==============

当检测到过载时，WebRTC 提供三种降级策略（通过 ``DegradationPreference`` 配置）：

.. list-table::
   :header-rows: 1
   :widths: 25 35 40

   * - 策略
     - 行为
     - 适用场景
   * - ``MAINTAIN_FRAMERATE``
     - 优先保帧率，降低分辨率
     - 视频通话（人脸运动需要流畅）
   * - ``MAINTAIN_RESOLUTION``
     - 优先保分辨率，降低帧率
     - 屏幕共享、文档展示（清晰度优先）
   * - ``BALANCED``
     - 平衡帧率与分辨率
     - 通用场景

在 JavaScript 中可以通过 ``RTCRtpSender.setParameters()`` 的 ``degradationPreference`` 设置：

.. code-block:: javascript

   const sender = pc.getSenders().find(s => s.track?.kind === 'video');
   const params = sender.getParameters();
   params.degradationPreference = 'maintain-framerate';
   await sender.setParameters(params);

通过 ``getStats()`` 可以监控当前的降级状态：

.. code-block:: javascript

   const stats = await pc.getStats();
   stats.forEach(report => {
       if (report.type === 'outbound-rtp' && report.kind === 'video') {
           console.log('qualityLimitationReason:', report.qualityLimitationReason);
           // "none" | "cpu" | "bandwidth" | "other"
           console.log('qualityLimitationDurations:', report.qualityLimitationDurations);
           // { none: 10.5, cpu: 2.3, bandwidth: 0, other: 0 }
       }
   });


核心代码结构
==============

.. code-block:: text

   video/adaptation/
   ├── encode_usage_resource.h/cc    ← CPU 过载检测资源
   ├── overuse_frame_detector.h/cc   ← 核心检测逻辑
   ├── quality_scaler_resource.h/cc  ← QP 质量检测资源
   └── video_stream_encoder_resource_manager.h/cc  ← 统一管理

``OveruseFrameDetector`` 的关键接口：

.. code-block:: c++

   class OveruseFrameDetector {
   public:
       // 每次编码完成后调用，传入编码耗时信息
       void FrameSent(uint32_t timestamp,
                      int64_t time_sent_in_us,
                      int64_t capture_time_us,
                      absl::optional<int> encode_duration_us);

       // 获取当前检测结果
       // 通过 AdaptationObserverInterface 回调通知
       // void AdaptUp() / void AdaptDown()
   };


与 QualityScaler 的关系
============================

除了 CPU 过载检测，WebRTC 还有 **QualityScaler**，它通过监控编码器输出的 QP（Quantization Parameter）值来判断是否需要降级：

- QP 过高 → 画质已经很差 → 降低分辨率让编码器有更多比特处理每个像素
- QP 过低 → 画质很好，编码器有余力 → 可以尝试提高分辨率

两者协同工作，CPU 和 QP 任一触发过载都会导致降级。


参考资料
==================

- `OveruseFrameDetector 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/overuse_frame_detector.h>`_
- `EncodeUsageResource 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/encode_usage_resource.h>`_
- `QualityScalerResource 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/quality_scaler_resource.h>`_
- `VideoStreamEncoderResourceManager 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/video_stream_encoder_resource_manager.h>`_
