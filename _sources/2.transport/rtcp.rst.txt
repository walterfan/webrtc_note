###################
WebRTC RTCP Usage
###################

.. toctree::
   :maxdepth: 1
   :caption: 目录

   rtcp_sr
   rtcp_rr
   rtcp_xr


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC RTCP Usage
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



Overview
===================


RTCP 即 RTP Control Protocol , 也就是是 RTP 控制协议，在会话中给所有与会者定期传送控制数据包，其分发的机制和媒体数据包一致，传统上与 RTP 包通过不同的端口传输，
在 WebRTC 中的通常做法是 RTP 与 RTCP 复用相同的端口。


RTCP 主要实现四大功能

1. 提供数据传输质量的反馈
2. 为 RTP 源携带一个持久的传输层标识， 称为 CNAME (Canonical name)
3. 控制和调整 RTCP 的传输间隔
4. 传达会话控制信息


RTCP 在多媒体终端的源端与目的端之间交换指定的消息，主要有以下几种
  * RR: Receiver Report 接收者报告
  * SR: Sender Report 发送者报告
  * SDES: Source Description 源端信息描述，包含 CNAME
  * BYE: 表示离开会话
  * APP: 应用程序指定的功能


.. csv-table:: RTCP Packet
   :header: "类型", "缩写", "名称“， ”参考文档"
   :widths: 20, 20, 30, 30

    200, SR, Sender Report, `RFC3550`_
    201, RR, Receiver Report, `RFC3550`_
    202, SDES, Source Description, `RFC3550`_
    203, BYE, Goodbye, `RFC3550`_
    204, APP, Application defined, `RFC3550`_
    205, RTPFB, Generic RTP feedback, `RFC4585`_
    206, PSFB, Payload specfic feedback, `RFC4585`_
    207, XR, Extended Report, `RFC3611`_


RTCP compound packet
----------------------------------------------------------


An individual RTP participant SHOULD send only one compound RTCP  packet per report interval in order for the RTCP bandwidth per participant to be estimated correctly.


If there are too many sources to fit all the necessary RR packets into one compound RTCP packet without exceeding the maximum transmission unit (MTU) of the network path, then only the subset that will fit into one MTU SHOULD be included in each interval.

The subsets SHOULD be selected round-robin across multiple intervals so that all sources are reported.

It is RECOMMENDED that translators and mixers combine individual RTCP packets from the multiple sources they are forwarding into one compound packet whenever feasible in order to amortize the packet overhead


An example RTCP compound packet as might be produced by a mixer is shown in Fig. 1.

If the overall length of a compound packet would exceed the MTU of the network path, it SHOULD be segmented into multiple shorter compound packets to be transmitted in separate packets of the underlying protocol.

This does not impair the RTCP bandwidth estimation because each compound packet represents at least one distinct participant.


.. code-block::

   if encrypted: random 32-bit integer
   |
   |[--------- packet --------][---------- packet ----------][-packet-]
   |
   |                receiver            chunk        chunk
   V                reports           item  item   item  item
   --------------------------------------------------------------------
   R[SR #sendinfo #site1#site2][SDES #CNAME PHONE #CNAME LOC][BYE##why]
   --------------------------------------------------------------------
   |                                                                  |
   |<-----------------------  compound packet ----------------------->|
   |<--------------------------  UDP packet ------------------------->|

   #: SSRC/CSRC identifier

              Figure 1: Example of an RTCP compound packet



RTCP Transmission Interval
----------------------------------------------

For audio we use a configurable interval (default: 5 seconds)

For video we use a configurable interval (default: 1 second) for a BW smaller than 360 kbit/s,
technicaly we break the max 5% RTCP BW for video below 10 kbit/s but that should be extremely rare


From RFC 3550

MAX RTCP BW is 5% if the session BW

    A send report is approximately 65 bytes inc CNAME
    A receiver report is approximately 28 bytes

The RECOMMENDED value for the reduced minimum in seconds is 360 divided by the session bandwidth in kilobits/second.

This minimum is smaller than 5 seconds for bandwidths greater than 72 kb/s.

If the participant has not yet sent an RTCP packet (the variable initial is true),
the constant Tmin is set to half of the configured interval.

The interval between RTCP packets is varied randomly over the range [0.5,1.5] times the calculated interval to avoid unintended synchronization of all participants

if we send

If the participant is a sender (we_sent true), the constant C is set to the average RTCP packet size (avg_rtcp_size) divided by 25% of the RTCP bandwidth (rtcp_bw), and the constant n is set to the number of senders.

if we receive only

If we_sent is not true, the constant C is set to the average RTCP packet size divided by 75% of the RTCP bandwidth.
The constant n is set to the number of receivers (members - senders).  If the number of senders is greater than 25%, senders and receivers are treated together.

reconsideration NOT required for peer-to-peer "timer reconsideration" is employed.

This algorithm implements a simple back-off mechanism which causes users to hold back RTCP packet transmission if the group sizes are increasing.

n = number of members
C = avg_size/(rtcpBW/4)

3. The deterministic calculated interval Td is set to max(Tmin, n*C).

4. The calculated interval T is set to a number uniformly distributed
between 0.5 and 1.5 times the deterministic calculated interval.

5. The resulting value of T is divided by e-3/2=1.21828 to compensate
for the fact that the timer reconsideration algorithm converges to
a value of the RTCP bandwidth below the intended average

200 Sender Report
-----------------------------------------------

`RTCP SR <rtcp_sr.html>`_



201 Receiver Report
-----------------------------------------------

`RTCP RR <rtcp_rr.html>`_


202 Source Description RTCP Packets (SDES)
------------------------------------------------

A SDES packet consists of a SDES header and a variable number of chunks for the described sources. Each chunk in turn consists of a SSRC/CSRC identifier and a collection of SDES items. SDES items themselves consists of a SDES item type code (8 bits), a length field (8 bits) and as much text octets as the length field indicates.

SDES Header

.. code-block::

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |V=2|P|    SC   |  PT=SDES=202  |            length L           |
    +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
    |                          SSRC/CSRC_1                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           SDES items                          |
    |                              ...                              |
    +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
    |                          SSRC/CSRC_2                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           SDES items                          |
    |                              ...                              |
    +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

* V, P, PT, L: As described for SR packets, with the packet type code set to 202.
* SC: 5 bits, The number of SSRC/CSRC chunks contained in this SDES packet.

The different SDES items are encoded according to a type-length-value scheme. Currently, CNAME, NAME, EMAIL, PHONE, LOC, TOOL, NOTE, and PRIV items are defined in [RFC1889].
The CNAME item is mandatory in every SDES packet, which in turn is mandatory part of every compound RTCP packet.
Like the SSRC identifier, a CNAME must differ from the CNAMEs of every other session participants. But instead of choosing the CNAME identifier randomly, the CNAME should allow both a person or a program to locate the source by means of the CNAME contents.


.. code-block::

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |    CNAME=1    |     length    | user and domain name         ...
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+




203 Goodbye RTCP Packets (BYE)
-----------------------------------

A participant sends a BYE packet to indicate that one or more sources are no longer active, optionally giving a reason for leaving.

.. code-block::

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |V=2|P|    SC   |   PT=BYE=203  |            length L           |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           SSRC/CSRC                           |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    :                              ...                              :
    +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
    |     length    |               reason for leaving (opt)       ...
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

* V, P, PT, L, SSRC/CSRC: As described for SR packets, with the packet type code 202 set.
* SC:5 bits, The number of SSRC/CSRC identifiers contained in this BYE packet.



Reference
=================
* `RFC4585`_: Extended RTP Profile for Real-time Transport Control Protocol (RTCP)-Based Feedback (RTP/AVPF)
* `RFC3605`_: Real Time Control Protocol (RTCP) attribute in  Session Description Protocol (SDP)
* `RFC5506`_: Support for Reduced-Size Real-Time Transport Control Protocol (RTCP): Opportunities and Consequences