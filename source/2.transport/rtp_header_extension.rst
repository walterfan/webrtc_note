##############################
WebRTC RTP Header extension
##############################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC RTP
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
==========================

在 `RFC5285 <https://datatracker.ietf.org/doc/html/rfc5285>`_ 中定义了 RTP 头的扩展方法
WebRTC 默认使用 One Byte 扩展。

0xBEDE (the first version of this specification was written on the feast day of the Venerable Bede)
Therefore, the  value zero in this field indicates that one byte of data follows, 
and a value of 15 (the maximum) indicates element data of 16 bytes


One-byte header profile
---------------------------------


.. code-block::

    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ 
    | 0xBE         |0xDE            |          length               | 
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

注意，这里的 length 表示 Header Extension的字节长度 x 4：

Total_extension_length = length * 4 bytes 


一个 One Byte Header的示例：

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |       0xBE    |    0xDE       |           length=3            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |  ID   | L=0   |     data      |  ID   |  L=1  |   data...
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ...data   |    0 (pad)    |    0 (pad)    |  ID   | L=3   |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                          data                                 |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

首先是0xBEDE固定字段开头，接着length长度为3，说明后面跟着3x4字节长度的header extension 。
对于第一个header extension：L=0，表示data长度为1字节。
对于第二个header extension：L=1，表示data长度为2字节。由于按4字节对齐，所以接着是值为0的填充数据。
最后一个header extension：L=3，表示data长度为4字节。


Two-bytes header profile
---------------------------------
.. code-block::

    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ 
    | 0x100                 |appbits| |       length                |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

注意，这里的 length 表示 Header Extension的字节长度 x 4：

Total_extension_length = length * 4 bytes 


一个 Two Bytes Header的示例：

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |       0x10    |    0x00       |           length=3            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |      ID       |     L=0       |     ID        |     L=1       |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |       data    |    0 (pad)    |       ID      |      L=4      |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                          data                                 |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

* 首先"defined by profile"字段为0x1000，length为3，后面跟着3x4字节长度扩展，
* 对于第一个header extension：L=0，数据长度为0，
* 对于第二个header extension：L=1，data长度为1，接着是填充数据，
* 对于第三个header extension：L=4，后面跟着4字节长度数据。





Absolute Send Time
==============================
refer to https://webrtc.googlesource.com/src/+/main/docs/native-code/rtp-hdrext/abs-send-time/README.md

The Absolute Send Time extension is used to stamp RTP packets with a timestamp showing the departure time from the system that put this packet on the wire (or as close to this as we can manage). Contact solenberg@google.com for more info.

* Name: “Absolute Sender Time” ; “RTP Header Extension for Absolute Sender Time”

* Formal name: http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time

SDP “a= name”: “abs-send-time” ; this is also used in client/cloud signaling.

Not unlike RTP with TFRC

* Wire format: 1-byte extension, 3 bytes of data. total 4 bytes extra per packet (plus shared 4 bytes for all extensions present: 2 byte magic word 0xBEDE, 2 byte # of extensions). Will in practice replace the “toffset” extension so we should see no long term increase in traffic as a result.

* Encoding: Timestamp is in seconds, 24 bit 6.18 fixed point, yielding 64s wraparound and 3.8us resolution (one increment for each 477 bytes going out on a 1Gbps interface).

* Relation to NTP timestamps: abs_send_time_24 = (ntp_timestamp_64 >> 14) & 0x00ffffff ; NTP timestamp is 32 bits for whole seconds, 32 bits fraction of second.

Notes: Packets are time stamped when going out, preferably close to metal. Intermediate RTP relays (entities possibly altering the stream) should remove the extension or set its own timestamp.



Absolute Capture Time
==============================
refer to https://webrtc.googlesource.com/src/+/main/docs/native-code/rtp-hdrext/abs-capture-time/README.md

The Absolute Capture Time extension is used to stamp RTP packets with a NTP timestamp showing when the first audio or video frame in a packet was originally captured. The intent of this extension is to provide a way to accomplish audio-to-video synchronization when RTCP-terminating intermediate systems (e.g. mixers) are involved.

Name: “Absolute Capture Time”; “RTP Header Extension for Absolute Capture Time”

Formal name: http://www.webrtc.org/experiments/rtp-hdrext/abs-capture-time

Status: This extension is defined here to allow for experimentation. Once experience has shown that it is useful, we intend to make a proposal based on it for standardization in the IETF.

Contact chxg@google.com for more info.

RTP header extension format


Transport-Wide Congestion Control
============================================================
refer to https://webrtc.googlesource.com/src/+/main/docs/native-code/rtp-hdrext/transport-wide-cc-02/README.md

This RTP header extension is an extended version of the extension defined in https://tools.ietf.org/html/draft-holmer-rmcat-transport-wide-cc-extensions-01

* Name: “Transport-wide congenstion control 02”

* Formal name: http://www.webrtc.org/experiments/rtp-hdrext/transport-wide-cc-02

* Status: This extension is defined here to allow for experimentation. Once experience has shown that it is useful, we intend to make a proposal based on it for standardization in the IETF.

The original extension defines a transport-wide sequence number that is used in feedback packets for congestion control. The original implementation sends these feedback packets at a periodic interval. The extended version presented here has two changes compared to the original version:

Feedback is sent only on request by the sender, therefore, the extension has two optional bytes that signals that a feedback packet is requested.
The sender determines if timing information should be included or not in the feedback packet. The original version always include timing information.


RTP header extension format
-----------------------------------------

Data layout overview
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Data layout of transport-wide sequence number 1-byte header + 2 bytes of data:

.. code-block::

    0                   1                   2
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |  ID   | L=1   |transport-wide sequence number |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

Data layout of transport-wide sequence number and optional feedback request 1-byte header + 4 bytes of data:

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |  ID   | L=3   |transport-wide sequence number |T|  seq count  |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |seq count cont.|
    +-+-+-+-+-+-+-+-+

Data layout details
------------------------

The data is written in the following order,

* transport-wide sequence number (16-bit unsigned integer)
* feedback request (optional) (16-bit unsigned integer)

  If the extension contains two extra bytes for feedback request, this means that a feedback packet should be generated and sent immediately. The feedback request consists of a one-bit field giving the flag value T and a 15-bit field giving the sequence count as an unsigned number.
  - If the bit T is set the feedback packet must contain timing information.
  - seq count specifies how many packets of history that should be included in the feedback packet. If seq count is zero no feedback should be be generated, which is equivalent of sending the two-byte extension above. This is added as an option to allow for a fixed packet header size.