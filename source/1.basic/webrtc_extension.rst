########################
WebRTC extension
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Extension
**Authors**  Walter Fan
**Status**   WIP as draft
**Category** LearningNote
**Updated**  |date|
============ ==========================

.. contents::
    :local:

Overview
=========================

根据 `RFC3550`_ 和 `RFC8285`_, 我们可以定义若干 RTP 扩展头, 用于各种不同的用途。

除了一些标准的 RTP header, 比如 audio level , WebRTC 还定义了一些其他的扩展头

* abs-send-time
* abs-capture-time
* color-space
* playout-delay
* transport-wide-cc-02
* video-content-type
* video-timing
* inband-cn
* video-layers-allocation00


refer to https://webrtc.googlesource.com/src/+/refs/heads/main/docs/native-code/rtp-hdrext

audio extension
-------------------------

::

    a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level
    a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
    a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
    a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
    a=extmap:5 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id
    a=extmap:6 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id


video extension
--------------------------

::

    a=extmap:1 urn:ietf:params:rtp-hdrext:toffset
    a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
    a=extmap:3 urn:3gpp:video-orientation
    a=extmap:4 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
    a=extmap:5 http://www.webrtc.org/experiments/rtp-hdrext/playout-delay
    a=extmap:6 http://www.webrtc.org/experiments/rtp-hdrext/video-content-type
    a=extmap:7 http://www.webrtc.org/experiments/rtp-hdrext/video-timing
    a=extmap:8 http://www.webrtc.org/experiments/rtp-hdrext/color-space
    a=extmap:9 urn:ietf:params:rtp-hdrext:sdes:mid
    a=extmap:10 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id
    a=extmap:11 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id

new extension
---------------------------
* `abs-capture-time`_

::

    a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-capture-time


Video Layers Allocation
---------------------------


The goal of this extension is for a video sender to provide information about the target bitrate, resolution and frame rate of each scalability layer in order to aid a selective forwarding middlebox to decide which layer to relay.

* Name: “Video layers allocation version 0”

* Formal name: http://www.webrtc.org/experiments/rtp-hdrext/video-layers-allocation00

* Status: This extension is defined here to allow for experimentation.

In a conference scenario, a video from a single sender may be received by several recipients with different downlink bandwidth constraints and UI requirements.

To allow this, a sender can send video with several scalability layers and a middle box can choose a layer to relay for each receiver.

This extension support temporal layers, multiple spatial layers sent on a single rtp stream (SVC), or independent spatial layers sent on multiple rtp streams (simulcast).


refer to https://webrtc.googlesource.com/src/+/refs/heads/main/docs/native-code/rtp-hdrext/video-layers-allocation00


Reference
====================

* `RTP Header Extension`_
* `WebRTC Extensions`_
* `webrtc extensions explain`_

.. _abs-capture-time: https://webrtc.googlesource.com/src/+/refs/heads/main/docs/native-code/rtp-hdrext/abs-capture-time/
.. _Frame Marking RTP Header Extension: https://tools.ietf.org/id/draft-ietf-avtext-framemarking-09.html
.. _RTP Header Extension: https://github.com/webrtc/webrtc-org/tree/gh-pages/experiments/rtp-hdrext

.. _webrtc extensions explain: https://w3c.github.io/webrtc-extensions/explainer.html