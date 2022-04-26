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
