##################################################
Stream Control Transmission Protocol (SCTP)
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

数据通信通过 TCP/TLS 就足够了， 为什么还要 SCTP, 可能是因为 TCP 是面向流的，始终有序和可靠的传输，而我们还想要一种面向消息的，并且可以控制优先级和可靠性的连接， 乱序或者有点丢失也能接受。

SCTP 是基于 DTLS 之上的， 面向消息的， 支持多流，优先级及可靠性可控的连接协议。

假设我们通过一个连接传送流媒体以及控制命令，如果通过 TCP , 包丢失了就要重传，乱序了也一样。SCTP 就可以不一样，流媒体的包可以丢失，控制命令的包不能丢失



SCTP is a reliable transport protocol operating on top of a connectionless packet network such as IP.  

It offers the following services to its users:

--  acknowledged error-free non-duplicated transfer of user data,

--  data fragmentation to conform to discovered path MTU size,

--  sequenced delivery of user messages within multiple streams, with
    an option for order-of-arrival delivery of individual user
    messages,

--  optional bundling of multiple user messages into a single SCTP
    packet, and

--  network-level fault tolerance through supporting of multi-homing
    at either or both ends of an association.

The design of SCTP includes appropriate congestion avoidance behavior
and resistance to flooding and masquerade attacks.



基于消息的多流协议
===============================

SCTP applications submit data for transmission in messages (groups of bytes) to the SCTP transport layer. SCTP places messages and control information into separate chunks (data chunks and control chunks), each identified by a chunk header. 

The protocol can fragment a message into multiple data chunks, but each data chunk contains data from only one user message. SCTP bundles the chunks into SCTP packets. The SCTP packet, which is submitted to the Internet Protocol, consists of a packet header, SCTP control chunks (when necessary), followed by SCTP data chunks (when available).


参考资料
==================
* https://datatracker.ietf.org/doc/html/rfc4960