##############################
RTCP SDES
##############################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** RTCP Sender Description
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
==========================

A SDES packet consists of a SDES header and a variable number of chunks for the described sources. Each chunk in turn consists of a SSRC/CSRC identifier and a collection of SDES items. SDES items themselves consists of a SDES item type code (8 bits), a length field (8 bits) and as much text octets as the length field indicates.

SDES 可用于将附加的非媒体信息附加到 RTP 媒体流，例如电子邮件地址和电话号码。 实际上，如果需要的话，大部分信息可以在其他层（例如呼叫信令）中更好地传达，从而使 SDES 数据包的许多字段现在的相关性不如以前。

然而，CNAME 仍然是重要且强制性的，而且它也是一种易于扩展的数据包类型。

SDES Header
-------------------------

SDES 数据包包含常规包头，有效负载类型为 202，项目计数等于数据包中 SSRC/CSRC 块的数量，后跟零个或多个 SSRC/CSRC 块，其中包含有关特定 SSRC 或 CSRC，每个都与 32 位边界对齐。

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


SDES Items
-------------------------

不同的 SDES 项根据类型-长度-值方案进行编码。 目前，CNAME、NAME、EMAIL、PHONE、LOC、TOOL、NOTE 和 PRIV 项在 RFC1889 中有详细定义。

CNAME 项在每个 SDES 数据包中都是必需的，而 SDES 数据包又是每个复合 RTCP 数据包中的必需部分。

与 SSRC 标识符一样，CNAME 必须与其他会话参与者的 CNAME 不同。 但 CNAME 不应随机选择 CNAME 标识符，而应允许个人或程序通过 CNAME 内容来定位其来源。

.. code-block::

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |    CNAME=1    |     length    | user and domain name         ...
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


每个块包含一个 32 位 SSRC 或 CSRC，然后是零个或多个包含有关该 SSRC/CSRC 信息的项。

每个 item 由 8 位类型字段、8 位长度字段（不包括类型和长度的 2 个字节）和最多 255 个字节的值字段组成。

SDES Item 是连续的，不需要在 32 位边界上开始或终止，但整个块至少由一个空 (0) 字节终止，并且必须添加更多空字节以将块填充到 32 位边界。 位边界。 因此，一个结构良好的块末尾总是有 1 到 4 个空字节。 请注意，这些空字节是 SDES 项的一部分，因此在设置标头中的填充字节时不计为填充。

从技术上讲，值的内容是 UTF-8，尽管关心互操作性的实现可能希望使用 US-ASCII 来最大程度地减少接收者无法将值正确解释为 Unicode 的问题。

CNAME
~~~~~~~~~~~~~~~~~~~~
关键项是规范端点标识符 (Canonical End-Point Identifier, CNAME)，其类型值为 1。 CNAME 有几个关键用途：

* 它在 SSRC 之间提供一致的绑定，该绑定可以随时针对流进行更改。 CNAME 在整个呼叫过程中应该保持一致。
* CNAME 在 RTP 会话中的所有流中应该是唯一的。
* CNAME 是 RTP 流之间同步（例如，lip- sync 口型同步）的关键。