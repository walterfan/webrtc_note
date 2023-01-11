################################################
Interactive Connectivity Establishment
################################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =========================================
**Abstract** Interactive Connectivity Establishment 
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ =========================================



.. contents::
   :local:


Ovewview
================
`RFC8445`_ Interactive Connectivity Establishment (ICE) 交互式连接建立是一个网络地址转换 NAT 穿透的协议


NAT
======================
NAT 是指路由器把本地私有子网IP地址转换称公网 IP 地址的过程。
ICE/STUN/TURN 主要是解决如何在各自内网中的客户端之间如何连接

根据最少限制性到最多限制性来排序可以分为：

* Full cone（全锥型）
* Address-restricted cone （地址限制型锥形）
* Port-restricted cone（端口限制型锥型）
* Symmetric（对称型）

ICE procedure
=========================
1. Candidate gathering
* STUN
* TURN
2. Prioritisation
3. Exchange
4. Connectivity checks
5. Coordination
6. Communication


ICE candidae
=========================

ICE candiate type

* host: Host Candidate

  A candidate obtained by binding to a specific port from an IP address on the host.
  This includes IP addresses on physical interfaces and logical ones, such as ones obtained through VPNs.

* srflx: Server-Reflexive Candidate

  A candidate whose IP address and port are a binding allocated by a NAT for an ICE agent after it sends a
  packet through the NAT to a server, such as a STUN server.

* prflx: Peer-Reflexive Candidate

  A candidate whose IP address and port are a binding allocated by a NAT for an ICE agent after it sends a
  packet through the NAT to its peer.

* relay: Relayed Candidate

  A candidate obtained from a relay server, such as a TURN server.


TCP Candidates with Interactive Connectivity Establishment (ICE)
===========================================================================


ICE defines a mechanism for  NAT traversal for multimedia communication protocols based on the offer/answer model of session negotiation.

The ICE Candidate can also be TCP-based , refer to RFC6544 and RFC4571

.. code-block::

                       +----------+
                       |          |
                       |    App   |
            +----------+----------+     +----------+----------+
            |          |          |     |          |          |
            |   STUN   |  (D)TLS  |     |   STUN   |    App   |
            +----------+----------+     +----------+----------+
            |                     |     |                     |
            |      RFC 4571       |     |      RFC 4571       |
            +---------------------+     +---------------------+
            |                     |     |                     |
            |         TCP         |     |         TCP         |
            +---------------------+     +---------------------+
            |                     |     |                     |
            |         IP          |     |         IP          |
            +---------------------+     +---------------------+

              Figure 1: ICE TCP Stack with and without (D)TLS


Framing RTP and RTCP Packets over TCP
============================================================

参见 RFC4571

* The Framing Method

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    ---------------------------------------------------------------
   |             LENGTH            |  RTP or RTCP packet ...       |
    ---------------------------------------------------------------

        Figure 1: The bit field definition of the framing method


The session descriptions in Figures 3 and 4 define a TCP RTP/AVP  session.


.. code-block::

   v=0
   o=first 2520644554 2838152170 IN IP4 first.example.net
   s=Example
   t=0 0
   c=IN IP4 192.0.2.105
   m=audio 9 TCP/RTP/AVP 11
   a=setup:active
   a=connection:new

          Figure 3: TCP session description for the first participant


.. code-block::

   v=0
   o=second 2520644554 2838152170 IN IP4 second.example.net
   s=Example
   t=0 0
   c=IN IP4 192.0.2.94
   m=audio 16112 TCP/RTP/AVP 10 11
   a=setup:passive
   a=connection:new

          Figure 4: TCP session description for the second participant



Reference
================

* `RFC8445`_: Interactive Connectivity Establishment (ICE): A Protocol for Network Address Translator (NAT) Traversal 

* _RFC8445: https://datatracker.ietf.org/doc/html/rfc8445