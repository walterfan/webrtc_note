###################
WebRTC RTCP Usage
###################

.. toctree::
   :maxdepth: 1
   :caption: 目录

   rtcp_sr
   rtcp_rr
   rtcp_sdes
   rtcp_bye
   rtcp_app
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


RTCP 消息通常使用与其附带的 RTP 消息相同的传输方式发送，按照惯例，RTP 在偶数端口上接收，RTCP 在奇数端口上接收。

RFC3605 中定义的“a=rtcp”属性允许接收方通告在与 RTP 不同的 IP 和/或端口上接收 RTCP，但是不是所有设备对此都支持。

RFC5761 定义了通过“a=rtcp-mux”属性将 RTP 和 RTCP 复用到同一端口，这也是在 WebRTC 中的通常做法。

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




由于每个 RTCP 数据包头都包含长度参数，因此单个 RTCP 数据包可以包含多个 RTCP 消息，这称为复合 RTCP 数据包。 每个消息都可以单独处理，并且数据包内消息的顺序没有意义。 如果需要，给定类型的消息可以出现多次。

RFC3550要求所有 RTCP 消息都作为两个或多个消息的复合数据包发送，第一个消息始终是 SR 或 RR 消息，第二个消息始终是包含 CNAME 的 SDES 消息。 即使发送 RTCP 数据包的设备尚未接收或发送任何媒体，情况也是如此，在这种情况下，初始消息必须是具有零 Recevier block 的 RR。

为了发送 BYE 或 PLI 反馈消息，RTCP 发送方必须构建包含 SR 或 RR 消息、SDES 消息、然后是 BYE 或 PLI 消息的 RTCP 数据包。

RFC4585 建议使用最小复合 RTCP 数据包，该数据包不包含额外的 RR，并将 SDES 消息限制为仅 CNAME，但实际上大多数实现不需要额外的 RR 或使用 CNAME 之外的 SDES 项目，所以这种优化实际意义不大。

对于正常的 RTCP 传输来说，这一要求并不太繁重，即使在使用反馈消息时，这种情况通常也相对不频繁。 然而，如果实现选择使用具有更高传输速率的专有 RTCP 消息传递，compound 要求所施加的额外带宽可能会造成严重后果。 在这种情况下，实现可能会选择发送不符合 RFC3550 compound 要求的 RTCP 数据包，但在这样做时应注意解复用，并且只有在使用这些特定于应用程序的消息时才应这样做； 应按照 compound 要求发送标准消息。


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
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
If the participant is a sender (we_sent true), the constant C is set to the average RTCP packet size (avg_rtcp_size) divided by 25% of the RTCP bandwidth (rtcp_bw), and the constant n is set to the number of senders.

if we receive only
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
If we_sent is not true, the constant C is set to the average RTCP packet size divided by 75% of the RTCP bandwidth.
The constant n is set to the number of receivers (members - senders).  If the number of senders is greater than 25%, senders and receivers are treated together.

reconsideration NOT required for peer-to-peer "timer reconsideration" is employed.

This algorithm implements a simple back-off mechanism which causes users to hold back RTCP packet transmission if the group sizes are increasing.

.. code-block::

    n = number of members
    C = avg_size/(rtcpBW/4)

1. The deterministic calculated interval Td is set to max(Tmin, n*C).

2. The calculated interval T is set to a number uniformly distributed
between 0.5 and 1.5 times the deterministic calculated interval.

3. The resulting value of T is divided by e-3/2=1.21828 to compensate
for the fact that the timer reconsideration algorithm converges to
a value of the RTCP bandwidth below the intended average


上述规则有点复杂， 其目的是为了应对分布式会议，其中服务器在所有参与者之间传播 RTCP，需要防止 RTCP 的带宽占用在具有大量参与者的会议中过高。

其实在现代的在线会议中，媒体服务器通常不会以这种方式转发所有 RTCP，并且参与者信息一般通过信令层进行共享。 所有很多系统并没有实现 RFC3550 中定义的上述规则。 相反，它们使用一个相对静态的传输间隔（通常为 1 ~ 5 秒），发送 SR/RR 和 SDES，然后根据需要发送反馈消息和 BYE。

200 Sender Report
-----------------------------------------------

`RTCP SR <rtcp_sr.html>`_



201 Receiver Report
-----------------------------------------------

`RTCP RR <rtcp_rr.html>`_


202 Source Description RTCP Packets (SDES)
------------------------------------------------

`RTCP SDES <rtcp_sdes.html>`_


203 Goodbye RTCP Packets (BYE)
-----------------------------------

`RTCP Bye <rtcp_bye.html>`_


204 Goodbye RTCP Packets (BYE)
-----------------------------------

`RTCP Bye <rtcp_bye.html>`_


Reference
=================
* `RFC4585`_: Extended RTP Profile for Real-time Transport Control Protocol (RTCP)-Based Feedback (RTP/AVPF)
* `RFC3605`_: Real Time Control Protocol (RTCP) attribute in  Session Description Protocol (SDP)
* `RFC5506`_: Support for Reduced-Size Real-Time Transport Control Protocol (RTCP): Opportunities and Consequences