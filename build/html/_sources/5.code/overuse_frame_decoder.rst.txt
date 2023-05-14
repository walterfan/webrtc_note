:orphan:

##############################
WebRTC OveruseFrameDetector
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC OveruseFrameDetector
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============

用户使用的设备千差万别,

视频的分辨率, 帧率过高可能会耗费大量的 CPU 资源, 如果用户的设备性能不高, 可能会造成应用程序


过载检测器, 分别对 cpu, qp, 分辨率进行状态检测, 通过与设定阈值比较, 高于就认为过载, 低于就认为欠载。


关键指标
==============

CPU usage (CPU使用率) 是指编码耗时/采集耗时的比率.

当该比值越大时，表示编码跟不上采集，达到了编码器的性能瓶颈，需要对编码进行降级；
反之，比值越小，表示编码能力有富余，还可以进行编码升级，提供更好的视频质量。换句话说，就是一个生产者与消费者的关系。


overuse frame detector
-----------------------------


cpu 检测器”, 通过编码器占用率与设定的阀值进行比较, 编码器占用率计算公式：

编码器占用率 = 编码时长/采集间隔, 具体的实现在 SendProcessingUsage1 类中, 编码时长与采集间隔

都用了指数加权移动平均法 (EWMA).

overuse policy
------------------------------
当发生过载时, WebRTC 提供了三种策略：

* MAINTAIN_FRAMERATE: 优先保帧率, 降低分辨率, 该模式的使用场景为视频模式。
* MAINTAIN_RESOLUTION: 优先保分辨率,降低帧率，使用场景为屏幕共享或者文档模式，对清晰度要求较高的场景。
* BALANCED: 平衡帧率与分辨率。 默认关闭，需要通过 WebRTC-Video-BalancedDegradation 开启。

Reference
==================
* https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/encode_usage_resource.h
* https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/overuse_frame_detector.h

