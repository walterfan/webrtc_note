########################
WebRTC FEC
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC FEC
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:


简介
=========================

FEC 即 Forward Error Correction 前向纠错，如果网络由于拥塞或中断丢失了一些媒体数据包，由于发送端通过 FEC 也发了一些冗余包，这样接收方依然能够正常地恢复和解码

目前在 WebRTC 中支持的 FEC 主要有以下两种，原理基本是用 XOR 的方法来进行错误恢复

* ULP FEC
* FLEX FEC

奇偶校验 FEC Parity FEC
========================

最简单的 FEC 是异或 (XOR) 奇偶校验方案。 方案如下：

* 发送方确定受修复数据包保护的源数据包组（固定大小）。
* 发送方通过对这些数据包组执行 XOR 操作来生成修复数据包。
* 发送方将源包和修复包发送给接收方
* 在接收端，如果数据包丢失，它会尝试恢复数据包。


有几种类型的奇偶校验 FEC 方案：

* 单维：一个数据包只能用于一组源数据包。 例如，行（非交错）和列（交错）。
* 多维：一个数据包可以用于多组源数据包。 例如，楼梯图案等。



Example
=========================

* Offer SDP

.. code-block::


    v=0
    o=- 4616755491246903017 2 IN IP4 127.0.0.1
    s=-
    t=0 0
    a=group:BUNDLE 0 1
    a=extmap-allow-mixed
    a=msid-semantic: WMS stream_id
    m=audio 9 RTP/AVPF 111 63 103 104 9 102 0 8 106 105 13 110 112 113 126
    c=IN IP4 0.0.0.0
    a=rtcp:9 IN IP4 0.0.0.0
    a=ice-ufrag:xoX+
    a=ice-pwd:KTYSyS/M3a+9MltQ9vjeqfGQ
    a=ice-options:trickle
    a=mid:0
    a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level
    a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
    a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
    a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
    a=sendrecv
    a=msid:stream_id audio_label
    a=rtcp-mux
    a=rtpmap:111 opus/48000/2
    a=rtcp-fb:111 transport-cc
    a=fmtp:111 minptime=10;useinbandfec=1
    a=rtpmap:63 red/48000/2
    a=fmtp:63 111/111
    a=rtpmap:103 ISAC/16000
    a=rtpmap:104 ISAC/32000
    a=rtpmap:9 G722/8000
    a=rtpmap:102 ILBC/8000
    a=rtpmap:0 PCMU/8000
    a=rtpmap:8 PCMA/8000
    a=rtpmap:106 CN/32000
    a=rtpmap:105 CN/16000
    a=rtpmap:13 CN/8000
    a=rtpmap:110 telephone-event/48000
    a=rtpmap:112 telephone-event/32000
    a=rtpmap:113 telephone-event/16000
    a=rtpmap:126 telephone-event/8000
    a=ssrc:248689302 cname:sKdWEXdSPhisX/aG
    a=ssrc:248689302 msid:stream_id audio_label
    a=ssrc:248689302 mslabel:stream_id
    a=ssrc:248689302 label:audio_label
    m=video 9 RTP/AVPF 96 97 98 99 100 101 35 36 124 123 127
    c=IN IP4 0.0.0.0
    a=rtcp:9 IN IP4 0.0.0.0
    a=ice-ufrag:xoX+
    a=ice-pwd:KTYSyS/M3a+9MltQ9vjeqfGQ
    a=ice-options:trickle
    a=mid:1
    a=extmap:14 urn:ietf:params:rtp-hdrext:toffset
    a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
    a=extmap:13 urn:3gpp:video-orientation
    a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
    a=extmap:5 http://www.webrtc.org/experiments/rtp-hdrext/playout-delay
    a=extmap:6 http://www.webrtc.org/experiments/rtp-hdrext/video-content-type
    a=extmap:7 http://www.webrtc.org/experiments/rtp-hdrext/video-timing
    a=extmap:8 http://www.webrtc.org/experiments/rtp-hdrext/color-space
    a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
    a=extmap:10 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id
    a=extmap:11 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id
    a=sendrecv
    a=msid:stream_id video_label
    a=rtcp-mux
    a=rtcp-rsize
    a=rtpmap:96 VP8/90000
    a=rtcp-fb:96 goog-remb
    a=rtcp-fb:96 transport-cc
    a=rtcp-fb:96 ccm fir
    a=rtcp-fb:96 nack
    a=rtcp-fb:96 nack pli
    a=rtpmap:97 rtx/90000
    a=fmtp:97 apt=96
    a=rtpmap:98 VP9/90000
    a=rtcp-fb:98 goog-remb
    a=rtcp-fb:98 transport-cc
    a=rtcp-fb:98 ccm fir
    a=rtcp-fb:98 nack
    a=rtcp-fb:98 nack pli
    a=fmtp:98 profile-id=0
    a=rtpmap:99 rtx/90000
    a=fmtp:99 apt=98
    a=rtpmap:100 VP9/90000
    a=rtcp-fb:100 goog-remb
    a=rtcp-fb:100 transport-cc
    a=rtcp-fb:100 ccm fir
    a=rtcp-fb:100 nack
    a=rtcp-fb:100 nack pli
    a=fmtp:100 profile-id=2
    a=rtpmap:101 rtx/90000
    a=fmtp:101 apt=100
    a=rtpmap:35 AV1/90000
    a=rtcp-fb:35 goog-remb
    a=rtcp-fb:35 transport-cc
    a=rtcp-fb:35 ccm fir
    a=rtcp-fb:35 nack
    a=rtcp-fb:35 nack pli
    a=rtpmap:36 rtx/90000
    a=fmtp:36 apt=35
    a=rtpmap:124 red/90000
    a=rtpmap:123 rtx/90000
    a=fmtp:123 apt=124
    a=rtpmap:127 ulpfec/90000
    a=ssrc-group:FID 951759562 3406123244
    a=ssrc:951759562 cname:sKdWEXdSPhisX/aG
    a=ssrc:951759562 msid:stream_id video_label
    a=ssrc:951759562 mslabel:stream_id
    a=ssrc:951759562 label:video_label
    a=ssrc:3406123244 cname:sKdWEXdSPhisX/aG
    a=ssrc:3406123244 msid:stream_id video_label
    a=ssrc:3406123244 mslabel:stream_id
    a=ssrc:3406123244 label:video_label


* Offer SDP

.. code-block::

    v=0
    o=- 5891415405757292783 2 IN IP4 127.0.0.1
    s=-
    t=0 0
    a=group:BUNDLE 0 1
    a=extmap-allow-mixed
    a=msid-semantic: WMS stream_id
    m=audio 9 RTP/AVPF 111 63 103 104 9 102 0 8 106 105 13 110 112 113 126
    c=IN IP4 0.0.0.0
    a=rtcp:9 IN IP4 0.0.0.0
    a=ice-ufrag:V8Bg
    a=ice-pwd:/pGLA/exQ5bdHylEsC6KOZmm
    a=ice-options:trickle
    a=mid:0
    a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level
    a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
    a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
    a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
    a=sendrecv
    a=msid:stream_id audio_label
    a=rtcp-mux
    a=rtpmap:111 opus/48000/2
    a=rtcp-fb:111 transport-cc
    a=fmtp:111 minptime=10;useinbandfec=1
    a=rtpmap:63 red/48000/2
    a=fmtp:63 111/111
    a=rtpmap:103 ISAC/16000
    a=rtpmap:104 ISAC/32000
    a=rtpmap:9 G722/8000
    a=rtpmap:102 ILBC/8000
    a=rtpmap:0 PCMU/8000
    a=rtpmap:8 PCMA/8000
    a=rtpmap:106 CN/32000
    a=rtpmap:105 CN/16000
    a=rtpmap:13 CN/8000
    a=rtpmap:110 telephone-event/48000
    a=rtpmap:112 telephone-event/32000
    a=rtpmap:113 telephone-event/16000
    a=rtpmap:126 telephone-event/8000
    a=ssrc:661437280 cname:7HW9LbofrT0Z073x
    m=video 9 RTP/AVPF 96 97 98 99 100 101 35 36 124 123 127
    c=IN IP4 0.0.0.0
    a=rtcp:9 IN IP4 0.0.0.0
    a=ice-ufrag:V8Bg
    a=ice-pwd:/pGLA/exQ5bdHylEsC6KOZmm
    a=ice-options:trickle
    a=mid:1
    a=extmap:14 urn:ietf:params:rtp-hdrext:toffset
    a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
    a=extmap:13 urn:3gpp:video-orientation
    a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
    a=extmap:5 http://www.webrtc.org/experiments/rtp-hdrext/playout-delay
    a=extmap:6 http://www.webrtc.org/experiments/rtp-hdrext/video-content-type
    a=extmap:7 http://www.webrtc.org/experiments/rtp-hdrext/video-timing
    a=extmap:8 http://www.webrtc.org/experiments/rtp-hdrext/color-space
    a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
    a=extmap:10 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id
    a=extmap:11 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id
    a=sendrecv
    a=msid:stream_id video_label
    a=rtcp-mux
    a=rtcp-rsize
    a=rtpmap:96 VP8/90000
    a=rtcp-fb:96 goog-remb
    a=rtcp-fb:96 transport-cc
    a=rtcp-fb:96 ccm fir
    a=rtcp-fb:96 nack
    a=rtcp-fb:96 nack pli
    a=rtpmap:97 rtx/90000
    a=fmtp:97 apt=96
    a=rtpmap:98 VP9/90000
    a=rtcp-fb:98 goog-remb
    a=rtcp-fb:98 transport-cc
    a=rtcp-fb:98 ccm fir
    a=rtcp-fb:98 nack
    a=rtcp-fb:98 nack pli
    a=fmtp:98 profile-id=0
    a=rtpmap:99 rtx/90000
    a=fmtp:99 apt=98
    a=rtpmap:100 VP9/90000
    a=rtcp-fb:100 goog-remb
    a=rtcp-fb:100 transport-cc
    a=rtcp-fb:100 ccm fir
    a=rtcp-fb:100 nack
    a=rtcp-fb:100 nack pli
    a=fmtp:100 profile-id=2
    a=rtpmap:101 rtx/90000
    a=fmtp:101 apt=100
    a=rtpmap:35 AV1/90000
    a=rtcp-fb:35 goog-remb
    a=rtcp-fb:35 transport-cc
    a=rtcp-fb:35 ccm fir
    a=rtcp-fb:35 nack
    a=rtcp-fb:35 nack pli
    a=rtpmap:36 rtx/90000
    a=fmtp:36 apt=35
    a=rtpmap:124 red/90000
    a=rtpmap:123 rtx/90000
    a=fmtp:123 apt=124
    a=rtpmap:127 ulpfec/90000
    a=ssrc-group:FID 1704191852 3785084139
    a=ssrc:1704191852 cname:7HW9LbofrT0Z073x
    a=ssrc:3785084139 cname:7HW9LbofrT0Z073x





参考资料
=========================
* `RFC6015`_: RTP Payload Format for 1-D Interleaved Parity Forward Error Correction (FEC)
* `RFC8627`_: RTP Payload Format for Flexible Forward Error Correction (FEC)
* https://www.callstats.io/blog/2016/11/09/how-to-recover-lost-media-packets-in-webrtc-with-fec

.. _RFC6015: https://tools.ietf.org/html/rfc6015
.. _RFC8627: https://tools.ietf.org/html/rfc8627

