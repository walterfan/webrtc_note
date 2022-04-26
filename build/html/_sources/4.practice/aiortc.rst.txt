##############
aiortc
##############


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** aiortc
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
===============
aiortc is a library for Web Real-Time Communication (WebRTC) and Object Real-Time Communication (ORTC) in Python. It is built on top of asyncio, Python's standard asynchronous I/O framework.

The API closely follows its Javascript counterpart while using pythonic constructs:

* promises are replaced by coroutines
* events are emitted using pyee.EventEmitter


main features
---------------
* SDP generation / parsing
* Interactive Connectivity Establishment, with half-trickle and mDNS support
* DTLS key and certificate generation
* DTLS handshake, encryption / decryption (for SCTP)
* SRTP keying, encryption and decryption for RTP and RTCP
* Pure Python SCTP implementation
* Data Channels
* Sending and receiving audio (Opus / PCMU / PCMA)
* Sending and receiving video (VP8 / H.264)
* Bundling audio / video / data channels
* RTCP reports, including NACK / PLI to recover from packet loss


Quick start
========================


* install aiortc

.. code-block:: Python

    # pip install aiohttp aiortc opencv-python

* try example

1) transfer file via data channel

   - https://github.com/aiortc/aiortc/tree/main/examples/datachannel-filexfer

2) Establishing audio, video and a data channel with a browser. It also performs some image processing on the video frames using OpenCV.

   - https://github.com/aiortc/aiortc/tree/main/examples/server

Reference
=======================
* Code repo: git@github.com:aiortc/aiortc.git
* Docuemnts: https://aiortc.readthedocs.io/en/latest/
* Examples: https://github.com/aiortc/aiortc/tree/main/examples