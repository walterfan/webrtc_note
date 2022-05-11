################################
WebRTC Metrics
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** WebRTC Metrics
**Category** Learning note
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:



Overview
======================
WebRTC 提供了 `webrtc_stats`_, 包含了诸多层面的指标, 浏览器提供了 `getStats()` API， Native SDK 需要调用类似的接口。

我们如果要计算在一段区间内的 metrics , 还需要做些计算。因为大多数的指标都是线性增长的，所以要把上一次取得的数据缓存下来，将这一次取得的指标减去上一次的指标

例如:

.. code-block::

    packetsSent = currentPacketsSent - previousPacketsSent

    frameRateReceived = (currentFramesReceived - previousFramesReceived)/(currentTimeMs - previousTimeMs)/1000



.. _webrtc_stats: ../1.basic/webrtc_stats.html



Considerations for Selecting RTCP Extended Report (XR) Metrics for the WebRTC Statistics API
===============================================================================================

* network impact metrics,
* application impact metrics, and
* recovery metrics


* RFC3611 RTP Control Protocol Extended Reports (RTCP XR)
* rfc6958 burst/gap loss metric reporting
* rfc7003 burst/gap discard metric reporting
* rfc6776 Measurement Identity and Information Reporting Using a SDES Item and an RTCP Extended Report (XR) Block
