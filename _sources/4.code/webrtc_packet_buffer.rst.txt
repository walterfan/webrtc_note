##############################
WebRTC Packet Buffer
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Packet Buffer
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============
从网络上收到的包, 可能会丢失, 可能会乱序, 为了减轻网络抖动 Jitter 造成的音视频不流畅, 接收缓冲是必不可少的.

* Audio Jitter Buffer
* Video Jitter Buffer


Video jitter buffer
===========================

Module: video_coding
* class VCMJitterBuffer
* class PacketBuffer
* class H264PacketBuffer