########################
WebRTC RED
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC RED
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


简介
=========================

RED 即 REDundant coding 冗余编码， 它是一种 RTP 荷载格式，在 RFC 2198 中定义，用于音视频数据的冗余编码. 最早它是用来

The primary motivation of sending redundant data is to be able to recover packets lost under lossy network conditions.

If a packet is lost then the missing information may be reconstructed at the receiver from the redundant data that arrives in the following packet(s).

The use of RED is negotiated in the SDP as an additional payload type and when used the audio/video RTP packets are packaged using RED format with a 6 bytes header, before the primary and secondary payloads conveying the actual audio/video packet and the redundant information.


RED was standardized more than 20 years ago in RFC 2198, and was initially conceived as a simple RTP payload format to implement Redundant Audio Data. Since then, due to its simplicity and flexibility it ended up being used for way more than just audio: we mentioned text streams already, but it’s also used in the Chrome ulpfec implementation for video, for instance. That said, audio is what it was born for, and so it made sense to see if it could still be of help in the WebRTC ecosystem as well.

As a format, it’s quite trivial: it basically allows you to packetize, within the payload of a single RTP packet, multiple frames that you’d normally send in different RTP packets instead. It performs that by listing a series of block headers at the beginning, each containing some relevant information (including the block length), which are then followed by the actual frame payloads in sequence. The following diagram from the RFC shows this more clearly in a visual way:


SDP 扩展
===========================

.. code-block:: 

       m=audio 12345 RTP/AVP 121 0 5
       a=rtpmap:121 red/8000/1
       a=fmtp:121 0/5


Packet 数据包格式
===========================

.. code-block::


    0                   1                    2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3  4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |F|   block PT  |  timestamp offset         |   block length    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+



* F： （1 bits），之后是否还有其他 RED Header

  - 1: 之后还有其他RED Header，
  - 0: 最后一个RED Header

* block PT：7 bits长度，表示该RED Header对应的冗余编码类型
* timeoffset： 14 bits长度，表示无符号长度时间戳偏移，该偏移是相对于RTP Header的时间戳。用无符号长度做偏移意味着冗余编码数据必须在发送完原始数据后才能发送
* block length: 10 bits长度，表示该RED Header对应编码数据块长度，该长度包含RED Header字段


对于RTP包中最后一个RED Header，可以忽略block length以及timestamp。因为它们可以从RTP Fixed Header以及整个RTP包长度计算得到。最后一个RED Header结构如下：

.. code-block::

    0 1 2 3 4 5 6 7
    +-+-+-+-+-+-+-+-+
    |0|   Block PT  |
    +-+-+-+-+-+-+-+-+


* example

.. code-block::


    0                   1                    2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3  4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P|X| CC=0  |M|      PT     |   sequence number of primary  |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |              timestamp  of primary encoding                   |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |           synchronization source (SSRC) identifier            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |1| block PT=7  |  timestamp offset         |   block length    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |0| block PT=5  |                                               |
   +-+-+-+-+-+-+-+-+                                               +
   |                                                               |
   +                LPC encoded redundant data (PT=7)              +
   |                (14 bytes)                                     |
   +                                               +---------------+
   |                                               |               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +
   |                                                               |
   +                                                               +
   |                                                               |
   +                                                               +
   |                                                               |
   +                                                               +
   |                DVI4 encoded primary data (PT=5)               |
   +                (84 bytes, not to scale)                       +
   /                                                               /
   +                                                               +
   |                                                               |
   +                                                               +
   |                                                               |
   +                                               +---------------+
   |                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


Reference
============================
* https://datatracker.ietf.org/doc/html/rfc2198
* https://blog.jianchihu.net/webrtc-research-redundant-rtp-payload-fec.html
* https://www.meetecho.com/blog/opus-red/
* https://webrtchacks.com/red-improving-audio-quality-with-redundancy/
* https://webrtc.github.io/samples/src/content/peerconnection/audio/