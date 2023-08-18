##############################
RTCP Sender Report
##############################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** RTCP SR
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
==========================

RTCP 最初由 RFC3550 定义，随后在 `RFC4585`_ "Extended RTP Profile for Real-time Transport Control Protocol (RTCP)-Based Feedback (RTP/AVPF)" 中对组合 RTCP 做出了一些规范。
`RFC5506`_ "Support for Reduced-Size Real-Time Transport Control Protocol (RTCP): Opportunities and Consequences" 规定了

术语
================================

RTCP packet
--------------------------------

Can be of different types, contains a fixed header part followed by structured elements depending on RTCP packet type.

Lower layer datagram:
--------------------------------

Can be interpreted as the UDP payload.  It may however, depending on the transport, be a TCP or Datagram Congestion Control Protocol (DCCP) payload or something else.

Synonymous to the "underlying protocol" defined in Section 3 in [RFC3550].


Compound RTCP packet
---------------------------------
A collection of two or more RTCP packets.

A compound RTCP packet is transmitted in a lower-layer datagram.  It  must contain at least an RTCP RR or SR packet and an SDES packet with the CNAME item.

Often "compound" is left out, the interpretation of RTCP packet is therefore dependent on the context.


Minimal compound RTCP packet
---------------------------------

A compound RTCP packet that contains the RTCP RR or SR packet and the SDES packet with the CNAME item  with a specified ordering.

(Full) compound RTCP packet
---------------------------------
A compound RTCP packet that conforms to the requirements on minimal compound RTCP packets and contains more RTCP packets.


Reduced-Size RTCP packet
---------------------------------
May contain one or more RTCP packets but does not follow the compound RTCP rules defined in Section 6.1 in  `RFC3550`_ and is thus neither a minimal nor a full compound RTCP.  See Section 4.1 for a full definition of `RFC5506`_


Sender Report RTCP Packets (SR)
=============================================
A Sender Report message consists of the header, the sender information block, a variable number of receiver report blocks, and potentially a profile-specific extensions.

The header
-------------------------------------------

.. code-block::

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |V=2|P|    RC   |   PT=SR=200   |             length L          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                         SSRC of sender                        |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

* V: version
* P: padding or not
* RC:5 bits, The number of reception report blocks contained in this packet.
* PT: 8 bits, The packet type constant 200 designates an RTCP SR packet.
* L: 16 bits, The length of this RTCP packet in 32-bit words minus one, including the header and any padding.
* SSRC: 32 bits, The synchronisation source identifier for the sender of this SR packet.


The sender information block 发送者信息块
------------------------------------------------------
.. code-block::

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |            NTP timestamp, most significant word NTS           |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |             NTP timestamp, least significant word             |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                       RTP timestamp RTS                       |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                   sender's packet count SPC                   |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                    sender's octet count SOC                   |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

* NTS: 64 bits, The NTP timestampgif indicates the point of time measured in wall clock time when this report was sent. In combination with timestamps returned in reception reports from the respective receivers, it can be used to estimate the round-trip propagation time to and from the receivers.

NTP 时间戳是一个 64 位字段，包含以网络时间协议 (NTP) 格式发送报告的时间，即 1970 年 1 月 1 日 00:00 UTC 等秒数，可通过许多标准库获得。 这通常称为挂钟时间。 前 32 位表示秒数，而第二个 32 位表示秒的小数部分。 RTCP 没有定义小数部分所需的精度，但它应该精确到至少毫秒，以便用于计算往返时间等目的。 请注意，虽然它使用 NTP 格式，但信息不必来自 NTP； 由于该值主要用于相对计算，因此只要实现对所有流上的发送方报告使用公共系统时钟，绝对精度并不是特别重要。

* RTS: 32 bits, The RTP timestamp resembles the same time as the NTP timestamp (above), but is measured in the same units and with the same random offset as the RTP timestamps in data packets. This correspondence may be used for intra- and inter-media synchronisation for sources whose NTP timestamps are synchronised, and may be used by media-independent receivers to estimate the nominal RTP clock frequency.

RTP 时间戳是一个 32 位字段，包含发送报告的时间，但采用 RTP 媒体流的单位/偏移量。 这允许在 RTP 数据包和挂钟时间之间建立关联。 实现时应该为发送者报告计算此值，而不是仅使用最近的 RTP 数据包时间戳，因为 RTCP 数据包和 RTP 数据包不会同时发送。

* SPC: 32 bits, The sender's packet count totals up the number of RTP data packets transmitted by the sender since joining the RTP session. This field can be used to estimate the average data packet rate.

Sender’s packet count 发送者的数据包计数是一个 32 位字段，包含自传输开始以来使用当前 SSRC 发送的 RTP 媒体数据包的总数。 因此，如果 SSRC 更改，计数应重置为 0。注意这是总计数，而不是自上一个 SR 以来的计数。

* SOC: 32 bits, The total number of payload octets (i.e., not including the header or any padding) transmitted in RTP data packets by the sender since starting up transmission. This field can be used to estimate the average payload data rate.

Sender’s octet count 发送方的八位字节计数是一个 32 位字段，包含自传输开始以来与当前 SSRC 一起发送的 RTP 有效负载数据（不包括标头、填充等）的总字节数。 如果 SSRC 更改，计数应重置为 0。再次注意这是总的计数，而不是自上一个 SR 以来的计数。


The receiver report blocks
-------------------------------------------
.. code-block::

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                 SSRC_1 (SSRC of first source)                 |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |fraction lost F|      cumulative number of packets lost C      |
    -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |         extended highest sequence number received  EHSN       |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                    inter-arrival jitter J                     |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                          last SR LSR                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                    delay since last SR DLSR                   |
    +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
    |                 SSRC_2 (SSRC of second source)                |
    :                               ...                             :
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

* SSRC_n: 32 bits, The SSRC identifier of the sender whose reception is reported in this block.
* F: 8 bits, The sender of the receiver report estimates the fraction of the RTP data packets from source SSRC_n that it assumes to be lost since it sent the previous SR or RR packet.
* C: 24 bits, The sender of a receiver report blocks also tries to estimate the total number of RTP data packets from source SSRC_n that have been lost since the beginning of reception. Packets that arrive late are not counted as lost, and the loss may be negative if there are duplicates.
* EHSN: 32 bits, The low 16 bits of the extended highest sequence number contain the highest sequence number received in an RTP data packet from source SSRC_n, and the most significant 16 bits extend that sequence number with the corresponding count of sequence number cycles.
* J: 32 bits, An estimate of the statistical variance of the RTP data packet inter-arrival time, measured in timestamp units and expressed as an unsigned integer.

The extensions
-------------------------------------------
.. code-block::

    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                  profile-specific extensions                  |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+




