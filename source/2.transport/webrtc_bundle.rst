###########################
WebRTC Bundle
###########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Bundle
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

What
=======================
RFC8843 defines a new Session Description Protocol (SDP) Grouping Framework extension called 'BUNDLE'.
The extension can be used with the SDP offer/answer mechanism to negotiate the usage of a  single transport (5-tuple) for sending and receiving media described by multiple SDP media descriptions ("m=" sections).

Such transport is referred to as a BUNDLE transport, and the media is referred to as  bundled media.
The "m=" sections that use the BUNDLE transport form a BUNDLE group.

It sends all media flows (those m= lines in the SDP) using the same “5 tuple”, meaning from the same IP and port, to the same IP and port, and over the same transport protocol.


How
=======================

In the JavaScript APIs for WebRTC, there is a configuration parameter called RTCConfiguration that is passed into the constructor when a new Peer Connection is created.

This object has properties for setting the STUN and TURN servers (iceServers), for indicating which paths to use for transport (iceTransportPolicy), for setting the peer identity policy (peerIdentity), and for controlling how BUNDLE is to be used (bundlePolicy).  Here is an example use of bundlePolicy:

.. code-block::

    myConfig = {bundlePolicy: “max-bundle”};
    pc = new RTCPeerConnection(myConfig);

There are three valid values that can be set for this policy:
* max-bundle,
* max-compat, and
* balanced.

In all cases the browser will attempt to bundle all tracks together over one connection (meaning a specific local IP/port and remote IP/port).

The different policy values affect what happens if the peer does not support BUNDLE.

So, if the peer does not support BUNDLE:

* max-bundle instructs the browser to pick one media track to negotiate and will only send that one
* max-compat instructs the browser to separate each track into its own connection
* balanced instructs the browser to pick two tracks to send — one audio and one video.  This is the default

Note that max-compat is the most likely to be backwards compatible with non-BUNDLE-aware legacy devices.


Why
=======================

One obvious benefit of doing this is reducing the ICE negotiation time as the number of ICE candidates is reduced.

While there are clear benefits to using one single BUNDLE for all media flows when possible, there are sometimes requirements to separate media flows.

For example: to separate audio from video and bundle each media type. In this example this would result in 2 SDP BUNDLEs.

简介
========================
回顾一下这张经典的图

.. image:: https://upload-images.jianshu.io/upload_images/1598924-a0b7b8dd85776b92.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240

我改了一下 audio 和 video 的 codec, 现在 Opus 和 H.264 用的比较多 Web
API 中最主要的就是 MediaStream, RTCPeerConnection 和 DataChannel.

在两个端点之间所传输的消息有这样几种

.. image:: https://upload-images.jianshu.io/upload_images/1598924-305ba0be176396bc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240

媒体数据一般都是优先走 UDP

::

         0                   1                   2                   3
         0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        |           Source Port          |        Destination port      |
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        |               Length           |        Checksum              |
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        |                                                               |
        |                        data octets ...                        |
        |                                                               |
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

1. 区分 STUN, DTLS 和 RTP 包
============================

注: 这里提到的 RTP 包括 RTP, RTCP, SRTP, SRTCP

在 UDP 传输通道上会跑 STUN, DTLS 和 RTP(SRTP)
的数据，我们首先要区分这几种数据

-  STUN 消息头如下

::

         0                   1                   2                   3
         0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        |0 0|     STUN Message Type     |         Message Length        |
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        |                         Magic Cookie                          |
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        |                                                               |
        |                     Transaction ID (96 bits)                  |
        |                                                               |
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

-  DTLS 消息，包含 SRTP 密钥的传输及用于 Datat Channel 的 SCTP 消息

::

    struct {
           ContentType type;
           ProtocolVersion version;
           uint16 epoch;                                     // New field
           uint48 sequence_number;                           // New field
           uint16 length;
           opaque fragment[DTLSPlaintext.length];
    } DTLSPlaintext;

::

         0                   1                   2                   3
         0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        | ContentType |        Version     |        epoch               |
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        |                         sequence_number                       |
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        |    sequence_number              |         length              |
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        |                                                               |
        |                     opaque fragment                           |
        |                                                               |
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

-  RTP 消息，包含音频或视频的媒体数据, SRTP 的头与 RTP 头是相同的

::

       0                   1                   2                   3
       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |V=2|P|X|  CC   |M|     PT      |       sequence number         |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                           timestamp                           |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |           synchronization source (SSRC) identifier            |
      +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
      |            contributing source (CSRC) identifiers             |
      |                             ....                              |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

-  RTCP 包括各种报告和反馈消息， SRTCP 的头与 RTCP 头是相同的

::


           0                   1                   2                   3
           0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
          +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
          |V=2|P| RC/FMT  |       PT      |             length            |
          +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
          |                         SSRC of sender                        |
          |                              ...                              |

我们从包头的第一个字节就能够区分

::

                      +----------------+
                      | 127 < B < 192 -+--> forward to RTP
                      |                |
          packet -->  |  19 < B < 64  -+--> forward to DTLS
                      |                |
                      |       B < 2   -+--> forward to STUN
                      +----------------+

代码示例如下:

::

    if((buffer[0]==0) || (buffer[0]==1))
         return stun; // STUN packet

    if((buffer[0]>=128) && (buffer[0]<=191))
         return rtp; // RTP packet

    if((buffer[0]>=20)  && (buffer[0]<=64))
         return dtls; // DTLS packet  

2. 区分 RTP 和 RTCP
===================

在一个端口上传输 RTP 和 RTCP 包会面临 payload 冲突的问题。RTCP
头的第二个字节是 payload type, RTP 头的第二个字节的低 7 位是 payload
type, RFC 5761 总结了一下，有如下冲突

-  RTP 有效载荷类型 64-65 与原始“H.261 视频流的 RTP 有效载荷格式”（由
   RFC 2032 定义，由 RFC 4587 废弃）中定义的（过时的）RTCP FIR 和 NACK
   数据包冲突。

-  RTP 有效载荷类型 72-76 与 RTP 规范 (RFC3550) 中定义的 RTCP
   SR、RR、SDES、BYE 和 APP 数据包冲突。

-  RTP 有效负载类型 77-78 与 RTP/AVPF 配置文件 (RFC 4585) 中定义的 RTCP
   RTPFB 和 PSFB 数据包冲突。

-  RTP 负载类型 79 与 RTCP 扩展报告 (XR) (RFC 3611) 数据包冲突。

-  RTP 有效负载类型 80 与“具有单播反馈的单源多播会话的 RTCP 扩展”(RFC
   5760) 中定义的接收器摘要信息 (RSI) 数据包冲突。

也就是 RTP payload type 64 ~ 95 会和 RTCP 有冲突，所以根据 RFC3551
RTP/AVP profile 的规定，RFC 5761 建议 RTP payload 64 ~ 95 不要再使用，
RTP 的动态 payload type 的选择最好在 96 ~ 127 之间

3. 区分不同的媒体流
===================

传统上，一个传输通道只传输一路媒体流，其 RTP 包 的 SSRC
也用来标识这路媒体流。 RTCP 会使用一个单独的传输 媒体协商的 SDP 中的一个
m-line 也只包含一路或者一对(包括重传 RTX 的媒体流 )媒体流。

WebRTC 中为避免过多地使用 NAT
技术来穿透防火墙，可用多路复用技术在一个传输通道中传输多路媒体，包括RTCP,
重传的媒体流。

一个传输通道（五元组: protocol, srcHost, srcPort, destHost,
destPort）中包含多路媒体流，也就是有多个 m-line。而一个 m-line
中也可包含多个 ssrc, 即通过联播 Simulcast 技术让 MediaStream 包含多个
MediaStreamTrack（分辨率或码率不同）。

那么如何辨别这些 MediaStream 和 MediaStreamTrack 呢？ SSRC 和 Payload
Type 显然不够，因为 SSRC 会变化，Payload Type 会重复。

WebRTC 将这些媒体流放在一个 bundle group 中， 通过 mid 来标识媒体流
MediaStream, 通过 rid 来标识媒体流中不同的 MediaStreamTrack,
例如来自相同源的不同质量，分辨率或帧率的流

::

   v=0
   o=- 708564895714429943 2 IN IP4 127.0.0.1
   s=-
   t=0 0
   a=group:BUNDLE 0 1 2 3 4
   a=extmap-allow-mixed
   a=msid-semantic: WMS rb3Uanb7CQq8HfZe0gexpjwoNCQai0AbUoQB
   m=audio 9 UDP/TLS/RTP/SAVPF 111 63 103 104 9 0 8 106 105 13 110 112 113 126
   c=IN IP4 0.0.0.0
   a=rtcp:9 IN IP4 0.0.0.0
   a=ice-ufrag:u8aT
   a=ice-pwd:nTH+98fL7o+XacAd//X7uStI
   a=ice-options:trickle
   a=fingerprint:sha-256 6E:FD:8F:7C:E7:6B:DF:2B:6F:D6:32:B6:A6:00:62:D5:7E:4E:11:91:91:37:95:BE:2C:00:3F:B2:67:6F:DF:3C
   a=setup:actpass
   a=mid:0
   //...省略若干属性
   a=ssrc:104648773 cname:XQRmiLwREWI1CiN0
   a=ssrc:104648773 msid:rb3Uanb7CQq8HfZe0gexpjwoNCQai0AbUoQB fc805128-e98d-47d2-a9a6-b8976c91a404
   a=ssrc:104648773 mslabel:rb3Uanb7CQq8HfZe0gexpjwoNCQai0AbUoQB
   a=ssrc:104648773 label:fc805128-e98d-47d2-a9a6-b8976c91a404

   m=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127 121 125 107 108 109 124 120 123 119 35 36 41 42 114 115 116
   c=IN IP4 0.0.0.0
   a=rtcp:9 IN IP4 0.0.0.0
   a=ice-ufrag:u8aT
   a=ice-pwd:nTH+98fL7o+XacAd//X7uStI
   a=ice-options:trickle
   a=fingerprint:sha-256 6E:FD:8F:7C:E7:6B:DF:2B:6F:D6:32:B6:A6:00:62:D5:7E:4E:11:91:91:37:95:BE:2C:00:3F:B2:67:6F:DF:3C
   a=setup:actpass
   a=mid:1
   //...省略若干属性
   a=rtcp-mux
   //...省略若干属性
   a=rid:high send
   a=rid:middle send
   a=rid:low send
   a=simulcast:send high;middle;low

   m=audio 9 UDP/TLS/RTP/SAVPF 111 63 103 104 9 0 8 106 105 13 110 112 113 126
   c=IN IP4 0.0.0.0
   a=rtcp:9 IN IP4 0.0.0.0
   a=ice-ufrag:u8aT
   a=ice-pwd:nTH+98fL7o+XacAd//X7uStI
   a=ice-options:trickle
   a=fingerprint:sha-256 6E:FD:8F:7C:E7:6B:DF:2B:6F:D6:32:B6:A6:00:62:D5:7E:4E:11:91:91:37:95:BE:2C:00:3F:B2:67:6F:DF:3C
   a=setup:actpass
   a=mid:2
   //...省略若干属性
   a=rtcp-mux

   //...省略若干属性

   m=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 102 122 127 121 125 107 108 109 124 120 123 119 35 36 37 38 39 40 41 42 114 115 116 43
   c=IN IP4 0.0.0.0
   a=rtcp:9 IN IP4 0.0.0.0
   a=ice-ufrag:u8aT
   a=ice-pwd:nTH+98fL7o+XacAd//X7uStI
   a=ice-options:trickle
   a=fingerprint:sha-256 6E:FD:8F:7C:E7:6B:DF:2B:6F:D6:32:B6:A6:00:62:D5:7E:4E:11:91:91:37:95:BE:2C:00:3F:B2:67:6F:DF:3C
   a=setup:actpass
   a=mid:3
   //...省略若干属性
   a=rtcp-mux
   a=rtcp-rsize
   //...省略若干属性

   m=application 9 UDP/DTLS/SCTP webrtc-datachannel
   c=IN IP4 0.0.0.0
   a=ice-ufrag:u8aT
   a=ice-pwd:nTH+98fL7o+XacAd//X7uStI
   a=ice-options:trickle
   a=fingerprint:sha-256 6E:FD:8F:7C:E7:6B:DF:2B:6F:D6:32:B6:A6:00:62:D5:7E:4E:11:91:91:37:95:BE:2C:00:3F:B2:67:6F:DF:3C
   a=setup:actpass
   a=mid:4
   a=sctp-port:5000
   a=max-message-size:262144

RTP 包 会带上 mid 和 rid 的扩展头

::

   0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |       0xBE    |    0xDE       |           length=3            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ID   | L=0   |     mid       |  ID   |  L=1  |   rid
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
         ...data   |    0 (pad)    |    0 (pad)    |  ID   | L=3   |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                          other extension                      |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

这样我们就能够通过 mid 和 rid 来区分不同的媒体流

| 注意:
| 1) mid 通常用来区分不同的媒体源（麦克风，摄像头或共享屏幕），而 rid
  通常用来区分来自一个媒体源所发送的不同质量的媒体流 2) mid 和 rid
  并不会始终附加在 RTP 包中，通常只会在开头一直到收到第一个 RTCP RR 包

4. 关联 RTCP 与 RTP 数据包到相应的 media session(m-line)
========================================================

RTCP 消息一般是用来控制或反馈相应媒体会话(media session )的 RTP 流的,
如何将 RTCP 与相应的 RTP 流关联起来呢，尤其在多路复用的场景中。RTP
包头里有 SSRC, RTCP 包里也有 SSRC,
似乎关联起来也不难，其实很麻烦，因为每个media session 中由于支持
simulcast 会有多个 SSRC。 更好的方法是用一个 ID 将它们联系起来:

1) 在 RTP 头里加上 mid 扩展，设置为 media session 中指明的 mid
2) 在 RTCP 包中设置 SDES 的 mid item 为 media session 中指明的 mid

..

   Offerers and answerers `RFC3264`_ can associate identification-tags
   with “m=” sections within offers and answers, using the procedures
   in `RFC5888`_. Each identification-tag uniquely represents an “m=”
   section.

-  defines a new SDP attribute, "bundle-only", which can be used to
   request that a specific “m=” section (and the associated media) be
   used only if kept within a BUNDLE group.
-  updates RFC 3264 [`RFC3264`_], to also allow assigning a zero port
   value to an “m=” section in cases where the media described by the
   “m=” section is not disabled or
   rejected.\ ` <https://www.rfc-editor.org/rfc/rfc8843#section-1.3-2.2>`__
-  defines a new RTCP [`RFC3550`_] SDES item, ‘MID’, and a new RTP SDES
   header extension that can be used to associate RTP streams with “m=”
   sections.\ ` <https://www.rfc-editor.org/rfc/rfc8843#section-1.3-2.3>`__
-  updates [`RFC7941`_] by adding an exception, for the MID RTP header
   extension, to the requirement regarding protection of an SDES RTP
   header extension carrying an SDES item for the MID RTP header
   extension.

.. image:: https://upload-images.jianshu.io/upload_images/1598924-48580b2c2b25de20.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240

参考资料
========

-  `RFC3550 <https://tools.ietf.org/html/rfc3550>`__: RTP 核心协议
-  `RFC3711`_: SRTP 安全的 RTP
-  `RFC5761`_: Multiplexing RTP Data and Control Packets on a Single
   Port
-  `RFC7941 <https://www.rfc-editor.org/rfc/rfc7941.html>`__: RTP Header
   Extension for the RTP Control Protocol (RTCP) Source Description
   Items - 旧版为 draft-ietf-avtext-sdes-hdr-ext-07
-  `RFC8843`_: Negotiating Media Multiplexing Using the Session
   Description Protocol(SDP)
-  `RFC8851`_: RTP Payload Format Restrictions - 旧版为
   draft-ietf-mmusic-rid-15
-  `RFC8852`_: RTP Stream Identifier Source Description (SDES)
   draft-ietf-avtext-rid-09
-  `RFC8853`_: Using Simulcast in Session Description Protocol (SDP) and
   RTP Sessions
-  `RFC8858`_: Indicating Exclusive Support of RTP and RTP Control
   Protocol (RTCP) Multiplexing Using the Session Description Protocol
   (SDP)
-  `RFC8860`_: Sending Multiple Types of Media in a Single RTP Session
-  `RFC8872`_: Guidelines for Using the Multiplexing Features of RTP to
   Support Multiple Media Streams
-  `RFC 8834`_: Media Transport and Use of RTP in WebRTC
-  `RFC 5245`_: Interactive Connectivity Establishment (ICE): A Protocol
   for Network Address Translator (NAT) Traversal for Offer/Answer
   Protocols
-  `RFC 8445`_: Interactive Connectivity Establishment (ICE): A Protocol
   for Network Address Translator (NAT) Traversal
-  `RFC 8489`_: Session Traversal Utilities for NAT (STUN)
-  `RFC 5766`_: Traversal Using Relays around NAT (TURN):Relay
   Extensions to Session Traversal Utilities for NAT (STUN)
-  `RFC 5888`_: The Session Description Protocol (SDP) Grouping
   Framework



.. _RFC5888: https://www.rfc-editor.org/rfc/rfc8843#RFC5888
.. _RFC8851: https://www.rfc-editor.org/rfc/rfc8851.html
.. _RFC 8834: https://tools.ietf.org/html/rfc8834
.. _RFC 5245: http://tools.ietf.org/html/rfc5245
.. _RFC 8445: https://tools.ietf.org/html/rfc8445
.. _RFC 8489: https://tools.ietf.org/html/rfc8489
.. _RFC 5766: https://tools.ietf.org/html/rfc5766
.. _RFC 5888: https://tools.ietf.org/html/rfc5888

