##############################
RTCP App
##############################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** RTCP Application
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
==========================
APP 数据包旨在用于开发新应用程序和新功能时的实验用途，无需注册数据包类型值。 具有无法识别名称的 APP 数据包应该被忽略。

经过测试并且如果证明更广泛的使用是合理的，建议重新定义每个 APP 数据包，而不使用子类型和名称字段，并使用 RTCP 数据包类型向 IANA 注册。


.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P| subtype |   PT=APP=204  |             length            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                           SSRC/CSRC                           |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                          name (ASCII)                         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                   application-dependent data                ...
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+



* version (V), padding (P), length:
    As described for the SR packet (see Section 6.4.1).

* subtype: 5 bits
    May be used as a subtype to allow a set of APP packets to be
    defined under one unique name, or for any application-dependent
    data.

* packet type (PT): 8 bits
    Contains the constant 204 to identify this as an RTCP APP packet.


RTCP 的 payload type 为 204，项目计数与扩展相关。 然后，它包含一个 32 位 SSRC 或 CSRC，它以同样依赖于扩展的方式与之关联。

然后有一个 32 位字段，其中包含一个 ASCII 字符串，该字符串是扩展名。 该名称用于标识相关扩展名的格式，因此应选择唯一的。 例如 "REMB"。

然后，RTCP 数据包的其余部分的格式由相关扩展定义，如名称所标识，这也定义了项目计数和 SSRC/CSRC 的用途。


Feedback
====================

RFC4585 中定义了 RTCP 反馈消息，它添加了协商和发送可用于响应媒体问题的 RTCP 反馈的机制。 这些反馈消息由RTP媒体流的接收者发送。 特别是用于请求新视频关键帧的两条消息(PLI/FIR)在使用视频时极其重要。

RTCP Feedback 大体可以分为以下三类：

* Transport layer FB messages 传输层的反馈消息
* Payload-specific FB messages 特定荷载的反馈消息
* Application layer FB messages 应用层的反馈消息



.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P|   FMT   |       PT      |          length               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of packet sender                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of media source                         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   :            Feedback Control Information (FCI)                 :
   :                                                               :

           Figure 3: Common Packet Format for Feedback Messages



PT 荷载类型有如下分类

.. code-block::

            Name   | Value | Brief Description
         ----------+-------+------------------------------------
            RTPFB  |  205  | Transport layer FB message
            PSFB   |  206  | Payload-specific FB message
            APPFB  |  207  | Application-specific FB message



接下来是反馈消息的数据包发送方的 SSRC 的 32 位字段（例如，与发送方报告或接收方报告中的报告方 SSRC 相同的值），

后面是媒体源的 SSRC：RTP 媒体流是 由正在提供反馈的反馈消息的发送者接收。

最后是反馈控制信息（FCI）部分，其内容和长度取决于反馈消息的类型。

RFC4585 和 RFC5104 定义了许多反馈消息的类型。

PLI/FIR
--------------------------
PLI 和 FIR 消息具有不同的语义含义。 PLI(Picture Loss Indication )图片丢失指示反馈消息表示解码视频帧所需的一个或多个数据包已丢失，而 FIR(Full Intra Request)完整帧内请求反馈消息明确请求关键帧。

然而，由于几乎所有接收方对 PLI 的响应都是发送关键帧，因此许多实现可互换地使用这两种消息类型。 从技术上讲，PLI 意味着在由于丢失而需要关键帧时发送，而 FIR 则在由于未收到关键帧而需要关键帧时发送（例如，在关键帧丢失的流开始时），但许多实现都对待它们 可以互换，并且确实具有相同的代码来处理接收任一消息。

实现请求关键帧的方法是通过可丢失的传输通道（例如基于 UDP 的 RTP）发送视频的基本要求，而 PLI/FIR 是该领域最常用的方法。 一般在媒体协商时会都支持这两种反馈消息， PLI 更为常用。

NACK
---------------------------
处理数据包丢失的另一种机制是通用 NACK 消息，它与 PLI 类似，但允许发送方准确指定哪些 RTP 数据包未成功接收。 在最简单的情况下，这可以作为提示关键帧的另一种机制，但更复杂的媒体发送方可以选择重新传输丢失的数据包。 NACK 最常用于WebRTC 设备，而PLI/FIR 往往用于SIP 设备。

TMMBR/TMMBN
---------------------------
TMMBR 和 TMMBN 是与比特率控制相关的反馈消息，在媒体弹性章节中详细讨论。 注意TMMBN 消息的不寻常之处在于，虽然大多数反馈消息是由 RTP 媒体流的接收方发送的，但 TMMBN 消息是作为响应于接收 TMMBR 消息的反馈而发送的，因此是由媒体发送方发送的。

TMMBR 和 TMMBN 消息最常见于 SIP 设备中。 WebRTC 设备倾向于使用名为“接收器估计最大比特率”(REMB) 的应用程序级消息， 近年来逐步转向 Transport Wide Congestion Control Feedback 