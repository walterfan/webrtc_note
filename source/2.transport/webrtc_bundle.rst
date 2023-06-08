###########################
WebRTC Bundle
###########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Network Device Interface
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

What
=======================
RFC8843 defines a new Session Description Protocol (SDP) Grouping Framework extension called 'BUNDLE'.
The extension can be used with the SDP offer/answer mechanism to negotiate the usage of a  single transport (5-tuple) for sending and receiving media described by multiple SDP media descriptions ("m=" sections).

Such transport is referred to as a BUNDLE transport, and the media is referred to as  bundled media.
The "m=" sections that use the BUNDLE transport form a BUNDLE group.

It sends all media flows (those m= lines in the SDP) using the same “5 tuple”, meaning from the same IP and port, to the same IP and port, and over the same transport protocol.


How
=======================

In the JavaScript APIs for WebRTC, there is a configuration parameter called RTCConfiguration that is passed into the constructor when a new Peer Connection is created.

This object has properties for setting the STUN and TURN servers (iceServers), for indicating which paths to use for transport (iceTransportPolicy), for setting the peer identity policy (peerIdentity), and for controlling how BUNDLE is to be used (bundlePolicy).  Here is an example use of bundlePolicy:

.. code-block::

    myConfig = {bundlePolicy: “max-bundle”};
    pc = new RTCPeerConnection(myConfig);

There are three valid values that can be set for this policy:
* max-bundle,
* max-compat, and
* balanced.

In all cases the browser will attempt to bundle all tracks together over one connection (meaning a specific local IP/port and remote IP/port).

The different policy values affect what happens if the peer does not support BUNDLE.

So, if the peer does not support BUNDLE:

* max-bundle instructs the browser to pick one media track to negotiate and will only send that one
* max-compat instructs the browser to separate each track into its own connection
* balanced instructs the browser to pick two tracks to send — one audio and one video.  This is the default

Note that max-compat is the most likely to be backwards compatible with non-BUNDLE-aware legacy devices.


Why
=======================

One obvious benefit of doing this is reducing the ICE negotiation time as the number of ICE candidates is reduced.

While there are clear benefits to using one single BUNDLE for all media flows when possible, there are sometimes requirements to separate media flows.

For example: to separate audio from video and bundle each media type. In this example this would result in 2 SDP BUNDLEs.



Reference
=======================
* https://datatracker.ietf.org/doc/rfc8843/
* https://udn.realityripple.com/docs/Web/API/RTCConfiguration/bundlePolicy
* https://webrtcstandards.info/sdp-bundle/