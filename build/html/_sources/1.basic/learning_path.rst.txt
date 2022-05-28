######################
WebRTC Learning Path
######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC 概论
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================

.. contents::
   :local:

Learn WebRTC in 21 days
=======================================
Looks like an Impossible Mission, but we can do that on elementary level.


Week 1
=======================================
1. Learn WebRTC API and specs

  - `WebRTC API <webrtc_api.html>`_
  - `WebRTC Call Flow <webrtc_flow.html>`_
  - `HTML5 video and audio element <webrtc_elements.html>`_


2. Learn Restful, Websocket and Write an example of P2P call

  - Write a simple signal server
  - Write a simple webrtc client

3. Learn RTP and SDP

  - RFC3550: RTP: A Transport Protocol for Real-Time Applications
  - RFC4566: SDP: Session Description Protocol

4. Do testing and capture/analyze packets by tcpdump/wireshark

  - tcpdump
  - wireshark


5. Learn DTLS and SRTP

   - DTLS
   - SRTP

6. Learn ICE, STUN and TURN

 - `RFC8445`_: Interactive Connectivity Establishment (ICE): A Protocol for Network Address Translator (NAT) Traversal
 - `RFC8838`_: Trickle ICE: Incremental Provisioning of Candidates for the Interactive Connectivity Establishment (ICE) Protocol
 - STUN
 - TURN


7. Learn GStreamer and its basic plugins


Week 2
=======================================
1. Audio Basic

2. Audio Codec

3. Audio pipeline

4. Video Basic

5. Video Codec

6. Video pipeline

7. Try Gsteamer to construct audio and vidoe pipleline

Week 3
=======================================
1. Multi stream and simulcat

2. Congestion control methods

3. Feedback and retransmission:NACK, PLI and FIR

4. FEC

5. RTX and RED

6. Network impair and QoS testing

7. build libwebrtc and its sample, do some testing
