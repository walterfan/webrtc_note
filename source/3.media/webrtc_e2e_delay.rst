################################
WebRTC E2E Delay
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** WebRTC E2E Delay
**Category** Learning note
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:


概述
===========================   


在网上会议中，张三和李四在会议中进行视频聊天。 张三的声音从麦克风中传入，视频从摄像头中传入，李四要过一段时间才能听到声音，看到图像，这个时间差是视频会议中的关键指标。我们称为端到端延迟。

端到端延迟 = 接收端的播放时间 - 发送端的捕获时间

麻烦的事情在于, 时间在发送端和接收端的时间基准是不一致的, 这就要参考 RTCP SR 中给出了发送端的 NTP 时间, 通过这个时间， 将接收端的 NTP 时间基准转换为发送端的

端到端延迟 = (接收端的播放时间 - delta - RTT/2) - 发送端的捕获时间

.. code-block:: javascript

   e2e_delay = receiver_playout_time - sender_capture_time
   receiver_capture_time = sender_capture_time + ntp_delta
   e2e_delay = receiver_playout_time - receiver_capture_time
   ntp_delta = received_time - ntp_time_in_sr - rtt/2


Media Stats
============================

estimatedPlayoutTimestamp
----------------------------
type: DOMHighResTimeStamp

This is the estimated playout time of this receiver's track.

The playout time is the NTP timestamp of the last playable audio sample or video frame that has a known timestamp
(from an RTCP SR packet mapping RTP timestamps to NTP timestamps), extrapolated with the time elapsed since it was ready to be played out.

This is the "current time" of the track in NTP clock time of the sender and can be present even if there is no audio currently playing.

This can be useful for estimating how much audio and video is out of sync for two tracks from the same source,

audioTrackStats.estimatedPlayoutTimestamp - videoTrackStats.estimatedPlayoutTimestamp.



Absolute Capture Time
=============================
The Absolute Capture Time extension is used to stamp RTP packets with a NTP timestamp showing when the first audio or video frame in a packet was originally captured. The intent of this extension is to provide a way to accomplish audio-to-video synchronization when RTCP-terminating intermediate systems (e.g. mixers) are involved.

Name: "Absolute Capture Time"; "RTP Header Extension for Absolute Capture Time"


Data layout overview
-------------------------------

Data layout of the shortened version of abs-capture-time with a 1-byte header + 8 bytes of data:


.. code-block::

   0                   1                   2                   3
   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ID   | len=7 |     absolute capture timestamp (bit 0-23)     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |             absolute capture timestamp (bit 24-55)            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ... (56-63)  |
   +-+-+-+-+-+-+-+-+

Data layout of the extended version of abs-capture-time with a 1-byte header + 16 bytes of data:



.. code-block::


   0                   1                   2                   3
   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ID   | len=15|     absolute capture timestamp (bit 0-23)     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |             absolute capture timestamp (bit 24-55)            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ... (56-63)  |   estimated capture clock offset (bit 0-23)   |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |           estimated capture clock offset (bit 24-55)          |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ... (56-63)  |
   +-+-+-+-+-+-+-+-+


Absolute capture timestamp
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Absolute capture timestamp is the NTP timestamp of when the first frame in a packet was originally captured. This timestamp MUST be based on the same clock as the clock used to generate NTP timestamps for RTCP sender reports on the capture system.

It's not always possible to do an NTP clock readout at the exact moment of when a media frame is captured. A capture system MAY postpone the readout until a more convenient time. A capture system SHOULD have known delays (e.g. from hardware buffers) subtracted from the readout to make the final timestamp as close to the actual capture time as possible.

This field is encoded as a 64-bit unsigned fixed-point number with the high 32 bits for the timestamp in seconds and low 32 bits for the fractional part. This is also known as the UQ32.32 format and is what the RTP specification defines as the canonical format to represent NTP timestamps.

Estimated capture clock offset
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Estimated capture clock offset is the sender's estimate of the offset between its own NTP clock and the capture system's NTP clock. The sender is here defined as the system that owns the NTP clock used to generate the NTP timestamps for the RTCP sender reports on this stream. The sender system is typically either the capture system or a mixer.

This field is encoded as a 64-bit two’s complement signed fixed-point number with the high 32 bits for the seconds and low 32 bits for the fractional part. It’s intended to make it easy for a receiver, that knows how to estimate the sender system’s NTP clock, to also estimate the capture system’s NTP clock:

.. code-block::

   Capture NTP Clock = Sender NTP Clock + Capture Clock Offset



Examples
==========================



Reference
==========================
* https://github.com/w3ctag/design-reviews/issues/493
* https://github.com/w3c/webrtc-extensions/blob/main/explainer.md
* https://github.com/w3c/webrtc-stats/pull/538/files
* https://janus.conf.meetecho.com/docs/rtp_8h.html#a55faec3441b03350eec0f9b39e8b79bf