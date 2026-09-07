################################################
TURN
################################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =========================================
**Abstract** Traversal Using Relays around NAT
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ =========================================



.. contents::
   :local:


Overview
================

As described in [RFC5128] and [RFC4787], hole punching techniques will fail if both hosts are behind NATs that are not well behaved.

For example, if both hosts are behind NATs that have a mapping behavior of "address-dependent mapping" or "address- and port- dependent mapping" (see Section 4.1 of [RFC4787]), then hole punching  techniques generally fail.


TURN (Traversal Using Relays around NAT), that allows a host behind a NAT (called the "TURN client") to request that another host (called the "TURN server") act as a relay.  The client can arrange for the server to relay packets to and from certain other hosts (called "peers"), and the client can control aspects of how the relaying is done. 



If TURN is used with ICE [RFC8445], then the relayed transport address and the IP addresses and ports of the peers are included in  the ICE candidate information that the rendezvous protocol must  carry.



TURN specs
------------------------------
* RFC 5766 - base TURN specs
* RFC 6062 - TCP relaying TURN extension
* RFC 6156 - IPv6 extension for TURN
* RFC 7443 - ALPN support for STUN & TURN
* RFC 7635 - oAuth third-party TURN/STUN authorization
* DTLS support (http://tools.ietf.org/html/draft-petithuguenin-tram-turn-dtls-00)
* Mobile ICE (MICE) support (http://tools.ietf.org/html/draft-wing-tram-turn-mobility-02)
* TURN REST API (http://tools.ietf.org/html/draft-uberti-behave-turn-rest-00)
* Origin field in TURN (Multi-tenant TURN Server) (https://tools.ietf.org/html/draft-ietf-tram-stun-origin-06)
* TURN Bandwidth draft specs (http://tools.ietf.org/html/draft-thomson-tram-turn-bandwidth-01)
* TURN-bis (with dual allocation) draft specs (http://tools.ietf.org/html/draft-ietf-tram-turnbis-04)


Terminology
==================
* Server-Reflexive Transport Address: A transport address on the "external side" of a NAT.  

This address is allocated by the NAT to correspond to a specific host transport address.

* Allocation:

The relayed transport address granted to a client through an Allocate request, along with related state, such as permissions and expiration timers.

* Channel:

A channel number and associated peer transport address. Once a channel number is bound to a peer's transport address, the client and server can use the more bandwidth-efficient ChannelData message to exchange data.

* Permission:

The IP address and transport protocol (but not the port) of a peer that is permitted to send traffic to the TURN server and have that traffic relayed to the TURN client. The TURN server will only forward traffic to its client from peers that match an existing permission.

Basic flow
==================

.. mermaid::

   flowchart LR
     TC["TURN Client<br/>198.51.100.2:49721"]
     NAT1[NAT]
     TS["TURN Server<br/>192.0.2.15:3478"]
     REL["Relayed Address<br/>192.0.2.15:50000"]
     NAT2[NAT]
     PA["Peer A Host<br/>203.0.113.2:49582"]
     PASRX["Peer A Server-Reflexive<br/>192.0.2.150:32102"]
     PB["Peer B<br/>192.0.2.210:49191"]
     CSRX["Client Server-Reflexive<br/>192.0.2.1:7000"]
     TC --> NAT1 --> TS
     NAT1 -.-> CSRX
     TS --- REL
     TS --> NAT2 --> PA
     NAT2 -.-> PASRX
     TS --> PB



TURN, as defined in this specification, always uses UDP between the server and the peer.  

However, this specification allows the use of any one of UDP, TCP, Transport Layer Security (TLS) over TCP, 
or Datagram Transport Layer Security (DTLS) over UDP to carry the TURN messages between the client and the server.

.. code-block::

           +----------------------------+---------------------+
           | TURN client to TURN server | TURN server to peer |
           +============================+=====================+
           |            UDP             |         UDP         |
           +----------------------------+---------------------+
           |            TCP             |         UDP         |
           +----------------------------+---------------------+
           |        TLS-over-TCP        |         UDP         |
           +----------------------------+---------------------+
           |       DTLS-over-UDP        |         UDP         |
           +----------------------------+---------------------+

                                 Table 1


Allocation
================

.. mermaid::

   sequenceDiagram
     participant Client as TURN client
     participant Server as TURN server
     participant PeerA as Peer A
     participant PeerB as Peer B

     Client->>Server: Allocate request invalid or missing credentials
     Server-->>Client: Allocate failure 401 Unauthenticated
     Client->>Server: Allocate request valid credentials
     Server-->>Client: Allocate success 192.0.2.15:50000
     Client->>Server: Refresh request
     Server-->>Client: Refresh success resp


Send Mechanism
==================

.. mermaid::

   sequenceDiagram
     participant Client as TURN client
     participant Server as TURN server
     participant PeerA as Peer A
     participant PeerB as Peer B

     Client->>Server: CreatePermission req Peer A
     Server-->>Client: CreatePermission success resp
     Client->>Server: Send ind Peer A
     Server->>PeerA: data
     PeerA->>Server: data
     Server-->>Client: Data ind Peer A
     Client->>Server: Send ind Peer B
     Note over Server: dropped no permission
     PeerB->>Server: data
     Note over Server: dropped

Channel
====================


.. mermaid::

   sequenceDiagram
     participant Client as TURN client
     participant Server as TURN server
     participant PeerA as Peer A
     participant PeerB as Peer B

     Client->>Server: ChannelBind req Peer A to 0x4001
     Server-->>Client: ChannelBind succ resp
     Client->>Server: 0x4001 data
     Server->>PeerA: data
     PeerA->>Server: data
     Server-->>Client: 0x4001 data
     Client->>Server: Send ind Peer A
     Server->>PeerA: data
     PeerA->>Server: data
     Server-->>Client: 0x4001 data


TURN specs
=============================

* RFC 5766 - base TURN specs
* RFC 6062 - TCP relaying TURN extension
* RFC 6156 - IPv6 extension for TURN

* `RFC8656`_ - Traversal Using Relays around NAT (TURN):
  Relay Extensions to Session  Traversal Utilities for NAT (STUN)

* RFC 7443 - ALPN support for STUN & TURN
* RFC 7635 - oAuth third-party TURN/STUN authorization
* DTLS support (http://tools.ietf.org/html/draft-petithuguenin-tram-turn-dtls-00).
* Mobile ICE (MICE) support (http://tools.ietf.org/html/draft-wing-tram-turn-mobility-02).
* TURN REST API (http://tools.ietf.org/html/draft-uberti-behave-turn-rest-00)
* Origin field in TURN (Multi-tenant TURN Server) (https://tools.ietf.org/html/draft-ietf-tram-stun-origin-06)
* TURN Bandwidth draft specs (http://tools.ietf.org/html/draft-thomson-tram-turn-bandwidth-01)
* TURN-bis (with dual allocation) draft specs (http://tools.ietf.org/html/draft-ietf-tram-turnbis-04).

STUN specs
=============================

* RFC 3489 - "classic" STUN
* RFC 5389 - base "new" STUN specs
* RFC 5769 - test vectors for STUN protocol testing
* RFC 5780 - NAT behavior discovery support
* RFC 7443 - ALPN support for STUN & TURN
* RFC 7635 - oAuth third-party TURN/STUN authorization

Supported ICE and related specs
==========================================================
* RFC 5245 - ICE
* RFC 5768 – ICE–SIP
* RFC 6336 – ICE–IANA Registry
* RFC 6544 – ICE–TCP
* RFC 5928 - TURN Resolution Mechanism


client-to-TURN-server protocols
==========================================================

* UDP (per RFC 5766)
* TCP (per RFC 5766 and RFC 6062)
* TLS (per RFC 5766 and RFC 6062): TLS1.0/TLS1.1/TLS1.2; ECDHE is supported.
* DTLS (http://tools.ietf.org/html/draft-petithuguenin-tram-turn-dtls-00): DTLS versions 1.0 and 1.2.
* SCTP (experimental implementation).

Supported relay protocols
=========================================================
UDP (per RFC 5766)
TCP (per RFC 6062)


.. _RFC8656: https://datatracker.ietf.org/doc/html/rfc8656