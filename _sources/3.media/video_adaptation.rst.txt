######################
video adaptation
######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Video Adaptation
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=========

video 的编码或传输质量会受到网络带宽和设备能力的影响。

网络质量不佳，带宽受限，如果还要发送高质量的视频会很困难，因为质量越高，码率越大，所以我们需要降低传送的码率。
如果用户可以接受低质量的视频，那么这时候可以降低分辨率。如果用户不接受低质量视频，那么就需要忍受延迟，降低帧率或者有些丢帧。

另一方面，用于 WebRTC 应用的设备往往参差不齐，有高大上的 macbook pro, 也有老掉牙的老笔记本或台式机，或者轻便小巧的平板。
多媒体特别是视频的编解码是很耗费资源的, 这时候，需要根据设备的资源消耗情况，实时调整编码质量，如分辨率，帧率等，避免对系统资源主要是 CPU 的占用率过大。

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
--------------------
设备的计算和存储资源对于视频的编解码, 捕获和渲染是有很大影响的. 如果设备性能太差, 则不适合进行高分辨率和高帧率的视频编解码.

在 webrtc library 中的 video 模块中有一个子模块 adaption, 它主要有如下的类来适应设备和网络状态

EncodeUsageResource
~~~~~~~~~~~~~~~~~~~~~~~~~~
Handles interaction with the OveruseDetector.


QualityScaler
~~~~~~~~~~~~~~~~~~~~~~
QualityScaler runs asynchronously and monitors QP values of encoded frames.
It holds a reference to a QualityScalerQpUsageHandlerInterface implementation to signal an overuse or underuse of QP 
(which indicate a desire to scale the video stream down or up).

QualityScalerQpUsageHandlerInterface
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Reacts to QP being too high or too low. 

For best quality, when QP is high it is desired to decrease the resolution or frame rate of the stream and when QP is low it is desired to increase the resolution or frame rate of the stream.

Whether to reconfigure the stream is ultimately up to the handler, which is able to respond asynchronously.



Network adaptation
--------------------

WebRTC 有一个网络拥塞和带宽估计的模块, 当检测到网络带宽有变化的(over-use, under-use), 就可以来调整视频的分辨率或帧率


.. csv-table:: 分辨率对应的大约带宽
   :header: "bandwidth", "Resolution", "Comments"
   :widths: 30, 30, 30


   64kbps,   90p,	"160 x 90"
   128kbps,   180p,	"320 x 180"
   448kbps,   360p,	"640 x 360"
   1536kbps,   720p,	"1280 x 720"
   4mbps,   1080p,	"1920 x 1080, may more than 4mbps, 2mbps at least"
   12mbps,   2K,    "3840 × 2160, may more than 12mbps"
   20mbps,   4K,    "7680 × 4320, may more than 20mbps"



Reference
================
* `Webrtc video framerate/resolution 自适应 <https://xie.infoq.cn/article/50b7931b8a023f8ca7f25d4e9>`_
* `overuse_frame_detector <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/overuse_frame_detector.h>`_