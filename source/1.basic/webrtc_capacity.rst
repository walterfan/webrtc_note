######################
WebRTC 客户端能力
######################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC 客户端能力
**Authors**  Walter Fan
**Status**   WIP as draft
**Category** LearningNote
**Updated**  |date|
============ ==========================

.. contents::
    :local:


概论
============

在客户端, CPU, GPU, 内存及显示器可能千差万别, 对于一些低端设备, 在视频编解码及渲染会有一些限制.
浏览器提供了一些基本的 API

例如:

* Navigator.deviceMemory

Returns the amount of device memory in gigabytes.
This value is an approximation given by rounding to the nearest power of 2 and dividing that number by 1024.

* Navigator.hardwareConcurrency:

Returns the number of logical processor cores available.


Performance API
---------------------------

The Performance API offers built-in metrics which are specialized subclasses of PerformanceEntry.
This includes entries for resource loading, event timing, first input delay (FID), and more.


OveruseFrameDetector
--------------------------
参见 WebRTC OveruseFrameDetector


Reference
==========================

* https://developer.chrome.com/en/docs/web-platform/webgpu/

.. _WebRTC OveruseFrameDetector: ../5.code/WebRTC OveruseFrameDetector