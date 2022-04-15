##############################
WebRTC SCTP library
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC SCTP library
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

Overview
=============
WebRTC 的 data channel 使用了 SCTP 协议, 提供数据传输通道, 为安全起见, 其 SCTP 依赖 DTLS 进行安全加密传输。

SCTP 是一种面向消息的可靠传输协议, 直接支持在 IP 或 UDP 之上运行的多宿主, 并支持 v4 和 v6 版本。

与 TCP 一样, SCTP 提供可靠的、面向连接的数据传输和拥塞控制。 与 TCP 不同, SCTP 还提供消息边界保存、有序和无序消息传递、多流和多宿主。 通过使用校验和和序列号来检测数据损坏、数据丢失和数据重复。 应用选择性重传机制来纠正数据的丢失或损坏。


SCTP 相关的协议和扩展很多, 最主要的有两个

* `RFC6458`_: Sockets API Extensions for the Stream Control Transmission Protocol (SCTP)

* `RFC4960`_: Stream Control Transmission Protocol



起先, WebRTC 使用了开源的 `usrsctp <https://github.com/sctplab/usrsctp>`_, 后期改成了自己实现的 `dcsctp <https://bugs.chromium.org/p/webrtc/issues/detail?id=12614>`_

.. pull-quote::

   Starting with Chrome M95 for the Canary and Dev channels, we’re going to start to rollout the DcSCTP library for the SCTP transport used by WebRTC’s Data Channels.

   It is a new implementation with a focus on security and compatibility with the previous implementation. No action should be required on your part and the transition should be transparent for users. Please have a look at the previous PSA for more information.


   To force enable the feature in Chrome, use the command line flag --force-fieldtrials="WebRTC-DataChannel-Dcsctp/Enabled/“, and --force-fieldtrials="WebRTC-DataChannel-Dcsctp/Disabled/" to force disable it and revert to the previous implementation.

   -- Florent Castelli


   WebRTC is starting to experiment with a new SCTP implementation called dcSCTP with the goal to migrate from usrsctp in the second half of this year.

   The new implementation is an in-tree C++ implementation that is consistent with all other code in WebRTC. It’s designed to only implement the parts of SCTP that are used by Data Channels in WebRTC and with security as the highest priority.

   By having a small, modern and well integrated SCTP implementation, it will be possible to provide a better experience for both media and data, more quickly iterate and experiment with new features and provide a better security architecture with much less cost of maintenance compared to the current setup.

   In the initial release, the library is considered to be feature complete with some known limitations:

   The congestion control algorithm hasn’t been fully tuned, so performance may be slightly worse compared to usrsctp, but should generally be on par.

   No support for I-DATA (RFC8260). This has never been enabled in Chromium/Chrome for usrsctp and this is negotiated in the SCTP association setup.

   Both will be fixed in future releases.

   The library is located in //net/dcsctp and is used by the SCTP Transport at //media/sctp/dcsctp_transport.h, but please note that API stability is not yet guaranteed.

   It is also available in Chrome using the feature flag --force-fieldtrials="WebRTC-DataChannel-Dcsctp/Enabled/" in Chrome Canary from version 92.0.4502.0.

   We appreciate any bug reports to be filed at bugs.webrtc.org (DataChannel component) for the dcSCTP library and its transport, and at crbug.com (Blink>WebRTC>DataChannel) for bugs visible through the Chrome/Chromium JS API.

   We would like to thank Michael Tüxen for all his past and current support for the usrsctp library, which has been a core component for WebRTC. We would not be the platform we are today without all of Michael's efforts.