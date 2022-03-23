########################
WebRTC FEC
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC FEC
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:


简介
=========================
目前在 WebRTC 中支持的 FEC 主要有以下两种，原理基本是用 XOR 的方法来进行错误恢复

* ULP FEC
* FLEX FEC


参考资料
=========================
* `RFC6015`_: RTP Payload Format for 1-D Interleaved Parity Forward Error Correction (FEC)
* `RFC8627`_: RTP Payload Format for Flexible Forward Error Correction (FEC)

.. _RFC6015: https://tools.ietf.org/html/rfc6015
.. _RFC8627: https://tools.ietf.org/html/rfc8627

