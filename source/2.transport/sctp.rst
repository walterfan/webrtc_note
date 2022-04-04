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
* https://datatracker.ietf.org/doc/html/rfc4960