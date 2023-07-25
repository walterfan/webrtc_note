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

RED 即 REDundant coding 冗余编码,  它是一种 RTP 荷载格式, 在 RFC 2198 中定义, 用于音视频数据的冗余编码. 最早它是用来

发送冗余数据的主要动机是能够恢复在有损网络条件下丢失的数据包。

如果数据包丢失, 则可以在接收器处根据后续数据包中到达的冗余数据来重建丢失的信息。

RED 的使用在 SDP 中协商为附加负载类型, 并且在使用时, 音频/视频 RTP 数据包使用带有 6 字节标头的 RED 格式进行打包, 然后在传送实际音频/视频数据包和冗余数据包的主要和次要负载之前 信息。


RED 于 20 多年前在 RFC 2198 中进行了标准化, 最初被认为是一种简单的 RTP 有效负载格式, 用于实现冗余音频数据。

从那时起, 由于其简单性和灵活性, 它最终不仅仅用于音频: 我们已经提到了文本流, 但它也用于视频的 Chrome ulpfec 实现中。 也就是说, 音频是它诞生的目的, 因此看看它是否仍然可以在 WebRTC 生态系统中提供帮助是有意义的。

作为一种格式, 它非常简单: 它基本上允许您在单个 RTP 数据包的有效负载内对通常在不同 RTP 数据包中发送的多个帧进行打包。

它通过在开头列出一系列块头来执行此操作, 每个块头包含一些相关信息( 包括块长度), 然后按顺序跟随实际的帧有效负载。


Opus FEC
-----------------

Opus 中还包含来自 SILK 的 LBRR (Low Bit-Rate Redundancy)
Opus 是一种混合编解码器, 它使用 SILK 作为比特率谱的低端。
然而, Opus SILK 与 Skype 当年开源的原始 SILK 有很大不同, 用于前向纠错模式的 LBRR 部分也是如此。

在 Opus 中, 前向纠错不是简单地附加在原始音频帧之后, 而是在其之前并编码在比特流中。

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



* F:  ( 1 bits), 之后是否还有其他 RED Header

  - 1: 之后还有其他RED Header, 
  - 0: 最后一个RED Header

* block PT: 7 bits长度, 表示该RED Header对应的冗余编码类型

* timeoffset:  14 bits长度, 表示无符号长度时间戳偏移, 该偏移是相对于RTP Header的时间戳。

  用无符号长度做偏移意味着冗余编码数据必须在发送完原始数据后才能发送

* block length: 10 bits长度, 表示该RED Header对应编码数据块长度, 该长度包含RED Header字段


对于RTP包中最后一个RED Header, 可以忽略block length以及timestamp。因为它们可以从RTP Fixed Header以及整个RTP包长度计算得到。最后一个RED Header结构如下: 

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


Redundant distance
============================
所谓 Distance 是指冗余包的个数


Philipp Hancke 在 2020.8.20 中写过一篇 `RED Improving Audio Quality with Redundancy`_
做过一些相关的测试

.. _RED Improving Audio Quality with Redundancy: https://webrtchacks.com/red-improving-audio-quality-with-redundancy/

.. csv-table:: In 20% loss
   :header: "Senario", "concealment percentage"
   :widths: 85, 15

    no RED,	18%
    "no RED, OPUS FEC off",	20%
    "RED with distance 1, OPUS FEC on",	4%
    "RED with distance 2, OPUS FEC on",	0.7%


.. csv-table:: In 60% loss
   :header: "Senario", "concealment percentage"
   :widths: 85, 15

    no RED,	60%
    RED with distance 1,	32%
    RED with distance 2,	18%


这个 distance 可以是动态的, 我们在做测试时需要采用不同的丢包模式来测试

参见 http://www.voiptroubleshooter.com/indepth/burstloss.html
常见的丢包模型有:

* Periodic loss: 模拟周期性的丢包。按填写数量(设为x个), 每x个包, 就丢一个包(one packet is dropped per given number of packets)。
* Random loss(Bernoulli or Independent Model): 模拟随机丢包, 按给定丢包的概率, 随机丢包。
* Burst loss: 模拟根据给定的可能性进行丢包。当发生一个丢包事件时, 接着连续丢几个包( 丢包数量控制在最大(max)最小值(min)之间)。
* G-E loss(Gilbert-Elliott Models): 模拟发生数据包丢失遵循Gilbert-Elliot模型,

  由两个状态组成: 好的状态和坏的状态。可分别为这2个状态指定数据包丢失率,同时可设置网络传输在这两种状态的概率
  (And the network transit between the two states is at given transition probabilities)


Metrics
============================
concealedSamples/totalSamplesReceived

Reference
============================
* https://datatracker.ietf.org/doc/html/rfc2198
* https://blog.jianchihu.net/webrtc-research-redundant-rtp-payload-fec.html
* https://www.meetecho.com/blog/opus-red/
* https://webrtchacks.com/red-improving-audio-quality-with-redundancy/
* https://webrtc.github.io/samples/src/content/peerconnection/audio/