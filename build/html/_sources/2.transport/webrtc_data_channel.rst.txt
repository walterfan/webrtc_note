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



.. contents::
   :local:

简介
=======================================

WebRTC 的 Data Channel 被设计用来在两个端点之间传输非音视频之类的媒体流外的数据，例如文本数据，控制命令。
这样无需经过由服务器的信令通道中转，效率较高。当然，通过服务器中转也没问题。

RTCDataChannel 接口表示一个网络通道，可用于任意数据的双向对等传输。 每个数据通道都与一个 RTCPeerConnection 相关联，每个对等连接理论上最多可以有 65,534 个数据通道（实际限制可能因浏览器而异）。

发起方如果要创建数据通道并要求远程对等方加入您，可调用 `RTCPeerConnection 的 createDataChannel()` 方法。
应答方会接收到一个数据通道事件 (其类型为 RTCDataChannelEvent), 以告知其数据通道已添加到连接中。


.. code-block:: javascript

    var pc = new RTCPeerConnection();
    var dc = pc.createDataChannel("my channel");

    dc.onmessage = function (event) {
      console.log("received: " + event.data);
    };

    dc.onopen = function () {
      console.log("datachannel open");
    };

    dc.onclose = function () {
      console.log("datachannel close");
    };

WebRTC 的 data channel 定义主要在 RFC8831 - "WebRTC Data Channels" 进行了详细阐述
具体用到的协议 在 RFC8261 - "Datagram Transport Layer Security (DTLS) Encapsulation of SCTP Packets" 中有详述

.. code-block::

              +----------+
              |   SCTP   |
              +----------+
              |   DTLS   |
              +----------+
              | ICE/UDP  |
              +----------+

      Figure 1: Basic Stack Diagram


整个 WebRTC 所用到的协议栈如下, 一个 trasport 上会传输 STUN, SRTP, DTLS and SCTP 协议。 


.. code-block::

                  +------+------+------+
                  | DCEP | UTF-8|Binary|
                  |      | Data | Data |
                  +------+------+------+
                  |        SCTP        |
    +----------------------------------+
    | STUN | SRTP |        DTLS        |
    +----------------------------------+
    |                ICE               |
    +----------------------------------+
    | UDP1 | UDP2 | UDP3 | ...         |
    +----------------------------------+

SCTP
================================================

WebRTC 采用 SCTP 作为数据通道，在于它拥有这些重要的特性


*  Usage of TCP-friendly congestion control.
*  modifiable congestion control for integration with the SRTP media stream congestion control.
*  Support of multiple unidirectional streams, each providing its own notion of ordered message delivery.
*  Support of ordered and out-of-order message delivery.
*  Support of arbitrarily large user messages by providing fragmentation and reassembly.
*  Support of PMTU discovery.
*  Support of reliable or partially reliable message transport.


six already registered SCTP Payload Protocol Identifiers (PPIDs)

.. code-block::

       +======================+===========+===========+============+
       | Value                | SCTP PPID | Reference | Date       |
       +======================+===========+===========+============+
       | WebRTC String        | 51        | RFC 8831  | 2013-09-20 |
       +----------------------+-----------+-----------+------------+
       | WebRTC Binary        | 52        | RFC 8831  | 2013-09-20 |
       | Partial (deprecated) |           |           |            |
       +----------------------+-----------+-----------+------------+
       | WebRTC Binary        | 53        | RFC 8831  | 2013-09-20 |
       +----------------------+-----------+-----------+------------+
       | WebRTC String        | 54        | RFC 8831  | 2013-09-20 |
       | Partial (deprecated) |           |           |            |
       +----------------------+-----------+-----------+------------+
       | WebRTC String Empty  | 56        | RFC 8831  | 2014-08-22 |
       +----------------------+-----------+-----------+------------+
       | WebRTC Binary Empty  | 57        | RFC 8831  | 2014-08-22 |
       +----------------------+-----------+-----------+------------+





Data Channel Establishment Protocol (DCEP)
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



IANA has updated the PPID name from "WebRTC Control" to "WebRTC DCEP"

.. code-block::

          +=============+===========+===========+============+
           | Value       | SCTP PPID | Reference | Date       |
           +=============+===========+===========+============+
           | WebRTC DCEP | 50        | RFC 8832  | 2013-09-20 |
           +-------------+-----------+-----------+------------+


New Message Type Registry
-----------------------------

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


New Channel Type Registry
-----------------------------

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




Message Formats
-----------------------

DATA_CHANNEL_OPEN Message
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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


* channel type


.. code-block::

     +================================================+=============+
     | Channel Type                                   | Reliability |
     |                                                |  Parameter  |
     +================================================+=============+
     | DATA_CHANNEL_RELIABLE                          |   Ignored   |
     +------------------------------------------------+-------------+
     | DATA_CHANNEL_RELIABLE_UNORDERED                |   Ignored   |
     +------------------------------------------------+-------------+
     | DATA_CHANNEL_PARTIAL_RELIABLE_REXMIT           |  Number of  |
     |                                                |     RTX     |
     +------------------------------------------------+-------------+
     | DATA_CHANNEL_PARTIAL_RELIABLE_REXMIT_UNORDERED |  Number of  |
     |                                                |     RTX     |
     +------------------------------------------------+-------------+
     | DATA_CHANNEL_PARTIAL_RELIABLE_TIMED            | Lifetime in |
     |                                                |      ms     |
     +------------------------------------------------+-------------+
     | DATA_CHANNEL_PARTIAL_RELIABLE_TIMED_UNORDERED  | Lifetime in |
     |                                                |      ms     |
     +------------------------------------------------+-------------+


DATA_CHANNEL_ACK Message
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   This message is sent in response to a DATA_CHANNEL_OPEN_RESPONSE
   message.  It is sent on the stream used for user messages using the
   data channel.  Reception of this message tells the opener that the
   data channel setup handshake is complete.

.. code-block::

      0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |  Message Type |
     +-+-+-+-+-+-+-+-+

   Message Type: 1 byte (unsigned integer)

      This field holds the IANA-defined message type for the DATA_CHANNEL_ACK message.
      The value of this field is 0x02


SDP
===============================================
it is a sdp example that use sctp over dtls


.. code-block::

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


Multiple SCTP associations MAY be multiplexed over a single DTLS connection.
The SCTP port numbers are used for multiplexing and demultiplexing the SCTP associations carried over a single DTLS connection.




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





参考资料
==================
* Data channel tutorial: https://www.html5rocks.com/en/tutorials/webrtc/datachannels/

* `RFC4960`_ : Stream Control Transmission Protocol
* `RFC6525`_ : Stream Control Transmission Protocol (SCTP) Stream Reconfiguration
* `RFC8831`_ : WebRTC Data Channels
* `RFC8832`_ : WebRTC Data Channel Establishment Protocol
* `RFC8260`_ : Stream Schedulers and User Message Interleaving for the Stream Control Transmission Protocol
* `RFC8261`_ : Datagram Transport Layer Security (DTLS) Encapsulation of SCTP Packets
* `RFC3758`_ : Stream Control Transmission Protocol (SCTP) Partial Reliability Extension
* `RFC7496`_ : Additional Policies for the Partially Reliable Stream Control Transmission Protocol Extension