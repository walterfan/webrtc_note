######################
Aiortc library
######################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** aiortc library
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:


Overview
========================


Signal
========================

信令通道的主要功能是交换 SDP 和 Candidate

.. code-block:: python

    def create_signaling(args):
        """
        Create a signaling method based on command-line arguments.
        """
        if args.signaling == "tcp-socket":
            return TcpSocketSignaling(args.signaling_host, args.signaling_port)
        elif args.signaling == "unix-socket":
            return UnixSocketSignaling(args.signaling_path)
        else:
            return CopyAndPasteSignaling()


datachannel
=========================
* offer

.. code-block::

    v=0
    o=- 3860702636 3860702636 IN IP4 0.0.0.0
    s=-
    t=0 0
    a=group:BUNDLE 0
    a=msid-semantic:WMS *
    m=application 55755 DTLS/SCTP 5000
    c=IN IP4 10.140.202.80
    a=mid:0
    a=sctpmap:5000 webrtc-datachannel 65535
    a=max-message-size:65536
    a=candidate:bcdcd0d77830c06b899667d1432cdd1b 1 udp 2130706431 10.140.202.80 55755 typ host
    a=candidate:0a02eb4cf64a7c80c396dc8996ae84dc 1 udp 2130706431 2001:420:5899:1252:2837:7baa:38d1:6375 58942 typ host
    a=end-of-candidates
    a=ice-ufrag:j8I1
    a=ice-pwd:AbyIZUKw1AeWitiEDfVZ7M
    a=fingerprint:sha-256 AA:9E:FF:30:84:B0:56:59:35:2F:20:C6:37:3D:29:92:4E:8E:76:C7:4F:C2:78:CA:38:EC:69:B5:71:AE:9A:A6
    a=setup:actpass


* answer

.. code-block::


    v=0
    o=- 3860704408 3860704408 IN IP4 0.0.0.0
    s=-
    t=0 0
    a=group:BUNDLE 0
    a=msid-semantic:WMS *
    m=application 63629 DTLS/SCTP 5000
    c=IN IP4 10.140.202.80
    a=mid:0
    a=sctpmap:5000 webrtc-datachannel 65535
    a=max-message-size:65536
    a=candidate:bcdcd0d77830c06b899667d1432cdd1b 1 udp 2130706431 10.140.202.80 63629 typ host
    a=candidate:0a02eb4cf64a7c80c396dc8996ae84dc 1 udp 2130706431 2001:420:5899:1252:2837:7baa:38d1:6375 60972 typ host
    a=end-of-candidates
    a=ice-ufrag:EbS2
    a=ice-pwd:ngG0BJGSJgQpbglkHxo8tx
    a=fingerprint:sha-256 F3:D3:48:D2:BC:97:83:A9:88:34:30:B9:9A:2F:1A:C4:F5:DF:B4:C1:8D:89:CE:63:E9:37:1F:B7:57:54:48:8E
    a=setup:active



RTP packet 处理
========================

* https://github.com/aiortc/aiortc/blob/main/src/aiortc/rtp.py

对于 RTP 的打包和解包应用了 `Python Structure module`_`



'>BBHL{payload}s'


.. _Python Structure module: https://docs.python.org/3/library/struct.html