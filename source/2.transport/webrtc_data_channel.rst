##################################################
WebRTC Data Channel
##################################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** SCTP protocol
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

简介
=======================================

WebRTC 的 Data Channel 被设计用来在两个端点之间传输非音视频之类的媒体流外的数据，例如文本数据，控制命令。
这样无需经过由服务器的信令通道中转，效率较高。当然，通过服务器中转也没问题。

RTCDataChannel 接口表示一个网络通道，可用于任意数据的双向对等传输。 每个数据通道都与一个 RTCPeerConnection 相关联，每个对等连接理论上最多可以有 65,534 个数据通道（实际限制可能因浏览器而异）。

发起方如果要创建数据通道并要求远程对等方加入您，可调用 `RTCPeerConnection 的 createDataChannel()` 方法。
应答方会接收到一个数据通道事件（其类型为 RTCDataChannelEvent），以告知其数据通道已添加到连接中。


Non-media data is handled by using the Stream Control Transmission Protocol (SCTP) `RFC4960`_ encapsulated in DTLS.  
DTLS 1.0 is defined in `RFC4347`_; the present latest version,  DTLS 1.2, is defined in `RFC6347`_; 
and an upcoming version, DTLS 1.3, is defined in `DTLS1.3`_.


.. code-block::

              +----------+
              |   SCTP   |
              +----------+
              |   DTLS   |
              +----------+
              | ICE/UDP  |
              +----------+

      Figure 1: Basic Stack Diagram


Data Channel Establishment Protocol 
================================================

The Data Channel Establishment Protocol is a simple, low-overhead way to establish bidirectional data channels over an SCTP association with a consistent set of properties.

The set of consistent properties includes:

*  reliable or unreliable message transmission.  
   In case of unreliable transmissions, the same level of unreliability is used.

*  in-order or out-of-order message delivery.

*  the priority of the data channel.

*  an optional label for the data channel.

*  an optional protocol for the data channel.

*  the streams.


DATA_CHANNEL_OPEN Message
-----------------------------------------

This message is initially sent using the data channel on the stream used for user messages.

.. code-block::

      0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |  Message Type |  Channel Type |            Priority           |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |                    Reliability Parameter                      |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |         Label Length          |       Protocol Length         |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     \                                                               /
     |                             Label                             |
     /                                                               \
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     \                                                               /
     |                            Protocol                           |
     /                                                               \
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+



* Message Type: 1 byte (unsigned integer)
 
  This field holds the IANA-defined message type for the DATA_CHANNEL_OPEN message.  
  The value of this field is 0x03, as specified in Section 8.2.1 of `RFC8832`_


.. code-block:: 

    +===================+===========+===========+
    | Name              | Type      | Reference |
    +===================+===========+===========+
    | Reserved          | 0x00      | RFC 8832  |
    +-------------------+-----------+-----------+
    | Reserved          | 0x01      | RFC 8832  |
    +-------------------+-----------+-----------+
    | DATA_CHANNEL_ACK  | 0x02      | RFC 8832  |
    +-------------------+-----------+-----------+
    | DATA_CHANNEL_OPEN | 0x03      | RFC 8832  |
    +-------------------+-----------+-----------+
    | Unassigned        | 0x04-0xfe |           |
    +-------------------+-----------+-----------+
    | Reserved          | 0xff      | RFC 8832  |
    +-------------------+-----------+-----------+


* Channel Type: 1 byte (unsigned integer)

.. code-block:: 

    +================================================+======+===========+
    | Name                                           | Type | Reference |
    +================================================+======+===========+
    | DATA_CHANNEL_RELIABLE                          | 0x00 | RFC 8832  |
    +------------------------------------------------+------+-----------+
    | DATA_CHANNEL_RELIABLE_UNORDERED                | 0x80 | RFC 8832  |
    +------------------------------------------------+------+-----------+
    | DATA_CHANNEL_PARTIAL_RELIABLE_REXMIT           | 0x01 | RFC 8832  |
    +------------------------------------------------+------+-----------+
    | DATA_CHANNEL_PARTIAL_RELIABLE_REXMIT_UNORDERED | 0x81 | RFC 8832  |
    +------------------------------------------------+------+-----------+
    | DATA_CHANNEL_PARTIAL_RELIABLE_TIMED            | 0x02 | RFC 8832  |
    +------------------------------------------------+------+-----------+
    | DATA_CHANNEL_PARTIAL_RELIABLE_TIMED_UNORDERED  | 0x82 | RFC 8832  |
    +------------------------------------------------+------+-----------+
    | Reserved                                       | 0x7f | RFC 8832  |
    +------------------------------------------------+------+-----------+
    | Reserved                                       | 0xff | RFC 8832  |
    +------------------------------------------------+------+-----------+
    | Unassigned                                     | rest |           |
    +------------------------------------------------+------+-----------+



示例
----------------------------------------

.. code-block:: javascript

    // Offerer side
    var pc = new RTCPeerConnection(options);
    var channel = pc.createDataChannel("chat");
    channel.onopen = function(event) {
      channel.send('Hi you!');
    }
    channel.onmessage = function(event) {
      console.log(event.data);
    }

    // Answerer side
    var pc = new RTCPeerConnection(options);
    pc.ondatachannel = function(event) {
      var channel = event.channel;
        channel.onopen = function(event) {
        channel.send('Hi back!');
      }
      channel.onmessage = function(event) {
        console.log(event.data);
      }
    }


    //Alternatively, more symmetrical out-of-band negotiation can be used, using an agreed-upon id (0 here):

    // Both sides

    var pc = new RTCPeerConnection(options);
    var channel = pc.createDataChannel("chat", {negotiated: true, id: 0});
    channel.onopen = function(event) {
      channel.send('Hi!');
    }
    channel.onmessage = function(event) {
      console.log(event.data);
    }



SCTP
==========================================
Data Channel 背后使用的协议是 SCTP

数据通信通过 TCP/TLS 就足够了， 为什么还要 SCTP, 可能是因为 TCP 是面向流的，始终有序和可靠的传输，而我们还想要一种面向消息的，并且可以控制优先级和可靠性的连接， 乱序或者有点丢失也能接受。


SCTP 是基于 DTLS 之上的， 面向消息的， 支持多流，优先级及可靠性可控的连接协议。

假设我们通过一个连接传送流媒体以及控制命令，如果通过 TCP , 包丢失了就要重传，乱序了也一样。SCTP 就可以不一样，流媒体的包可以丢失，控制命令的包不能丢失


它为用户提供以下服务：

- 确认用户数据的无错误非重复传输，
- 数据分段以符合发现的路径 MTU 大小，
- 在多个流中按顺序传递用户消息，使用单个用户的到达顺序交付选项消息，
- 可选地将多个用户消息捆绑到单个 SCTP 数据包，和
- 通过支持多宿主实现网络级容错在关联的一端或两端。

SCTP 的设计包括适当的拥塞避免行为以及对洪水和伪装攻击的抵抗力。



基于消息的多流协议
===============================

SCTP applications submit data for transmission in messages (groups of bytes) to the SCTP transport layer. SCTP places messages and control information into separate chunks (data chunks and control chunks), each identified by a chunk header. 

The protocol can fragment a message into multiple data chunks, but each data chunk contains data from only one user message. SCTP bundles the chunks into SCTP packets. The SCTP packet, which is submitted to the Internet Protocol, consists of a packet header, SCTP control chunks (when necessary), followed by SCTP data chunks (when available).


参考资料
==================
* `RFC4960`_ : Stream Control Transmission Protocol
* `RFC6525`_ : Stream Control Transmission Protocol (SCTP) Stream Reconfiguration
* `RFC8831`_ : WebRTC Data Channels
* `RFC8832`_ : WebRTC Data Channel Establishment Protocol
* `RFC8260`_ : Stream Schedulers and User Message Interleaving for the Stream Control Transmission Protocol
* `RFC8261`_ : Datagram Transport Layer Security (DTLS) Encapsulation of SCTP Packets
* `RFC3758`_ : Stream Control Transmission Protocol (SCTP) Partial Reliability Extension
* `RFC7496`_ : Additional Policies for the Partially Reliable Stream Control Transmission Protocol Extension