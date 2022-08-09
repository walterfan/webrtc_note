########################
WebRTC RTX
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC RTX
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


简介
=========================

RTP retransmission is an effective packet loss recovery technique for real-time applications with relaxed delay bounds.

`RFC4588`_ describes an RTP payload format for performing retransmissions.  Retransmitted RTP packets are sent in a separate stream from the original RTP stream.

发送方与接收方之间的丢包会显著地降低接收到的媒体质量。有好几种技术可以用来提高抗丢包的弹性：

* Forward error correction (FEC): 前向纠错
* Retransmissions 重传
* Interleaving 交织
  
`RFC2354`_ 对这些方法有所讨论
  
RTX 即 RTransmission, 用于丢包重传， 它使用不同的会话(session) 或者不同的 ssrc 来传送冗余的 RTP 包



术语
===================================

* CSRC: contributing source.

* Original packet:

  an RTP packet that carries user data sent for the first time by an RTP sender.

* Original stream:

  the RTP stream of original packets.

* Retransmission packet:

  an RTP packet that is to be used by the receiver instead of a lost original packet.
  Such a retransmission packet is said to be associated with the original RTP packet.

* Retransmission request:

  a means by which an RTP receiver is able to request that the RTP sender should send a retransmission packet
  for a given original packet.  Usually, an RTCP NACK packet as specified in is used as retransmission request
  for lost packets.

* Retransmission stream:

  the stream of retransmission packets associated with an original stream.

* Session-multiplexing:

  scheme by which the original stream and the associated retransmission stream are sent into two different RTP sessions.

* SSRC: synchronization source.

* SSRC-multiplexing:

  scheme by which the original stream and the retransmission stream are sent in the same RTP session with different SSRC values.


Requirements and Design Rationale for a Retransmission Scheme
======================================================================

The use of retransmissions in RTP as a repair method for streaming media is appropriate in those scenarios with relaxed delay bounds and where full reliability is not a requirement.

The RTP retransmission scheme defined in this document is designed to
   fulfill the following set of requirements:

   1. It must not break general RTP and RTCP mechanisms.
   2. It must be suitable for unicast and small multicast groups.
   3. It must work with mixers and translators.
   4. It must work with all known payload types.
   5. It must not prevent the use of multiple payload types in a
      session.
   6. In order to support the largest variety of payload formats, the
      RTP receiver must be able to derive how many and which RTP packets
      were lost as a result of a gap in received RTP sequence numbers.

      This requirement is referred to as sequence number preservation.
      Without such a requirement, it would be impossible to use
      retransmission with payload formats, such as conversational text
      [9] or most audio/video streaming applications, that use the RTP
      sequence number to detect lost packets.

Retransmission Payload Format
===================================
.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                         RTP Header                            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |            OSN                |                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               |
   |                  Original RTP Packet Payload                  |
   |                                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+



重传请求
-------------------------
* NACK 可用来请求发送方重传


拥塞控制
-------------------------
拥塞导致丢包，丢包会重传，重传导致拥塞更严重，这样会生成恶性循环，所以需要考虑一个可接受的发送速率。

对于原始数据流和重传数据流的 packet rate 及 bitrate

* 总的传输速率必须控制在允许的带宽之内
* 在媒体质量要求很高的情况下，严重的拥塞需要降低原始流的发送速率之后再发送 RTX 包
* 某些环境下，比如无线网络，丢包并不是由拥塞导致的，发送 RTX 包是很用的


RTX Payload format MIME Type
-----------------------------------------
* rtx: Retransmission
* rtx-time
* apt: associated payload type 将重传的 payload type 和 RTX 的 payload type 关联起来



参考资料
=========================
* RFC4588: `RTP Retransmission Payload Format`_
* RFC4585: `Extended RTP Profile for RTCP-Based Feedback`_
* `Implement RTX for WebRTC`_
* RFC2198: RED -  Redundant Audio Data


.. _Implement RTX for WebRTC: https://bugzilla.mozilla.org/show_bug.cgi?id=1164187
.. _RTP Retransmission Payload Format: https://tools.ietf.org/html/rfc4588
.. _Extended RTP Profile for RTCP-Based Feedback: https://datatracker.ietf.org/doc/html/rfc4585
