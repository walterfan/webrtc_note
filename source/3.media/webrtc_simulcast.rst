################################################
WebRTC Simulcast
################################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Simulcast
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
===========================
我们的电脑有强大的多媒体能力，有多个媒体源 - 麦克风，摄像头，电脑屏幕，可以发送多路的音频，视频以及共享屏幕内容。
也可能接多个摄像头，几个外接显示器。每个摄像头或屏幕可以分别分送不同的分辨率和帧率。


Simulcast 可翻译为联播，同播或并播，一个摄像头可以发送不同分辨率（spatial quality）或帧率(temporal quality)的视频流，这些流可以在一个 RTP 会话中传送， 不同的分辨率使用不同的 SSRC, 不同的帧率可以使用相同的 SSRC（SST） 或者不同的 SSRC（MST）。这些流可以共同使用一个相同的 CSRC 或者一个扩展的 ID

.. code-block::

   (async () => {

      const pc = new RTCPeerConnection();

      const localStream = await navigator.mediaDevices.getUserMedia({audio: true, video: true});

      const localAudioTrack = localStream.getAudioTracks()[0];
      const localVideoTrack = localStream.getVideoTracks()[0];


      const encodings = [
         {rid: 'high', maxBitrate: 1500000, active: true, priority: "high"},
         {rid: 'middle', maxBitrate: 500000, active: true, scaleResolutionDownBy: 2.0},
         {rid: 'low', maxBitrate: 100000, active: true, scaleResolutionDownBy: 4.0}
      ];


      pc.addTransceiver(localAudioTrack, {direction: 'sendrecv', streams: [localStream]});
      pc.addTransceiver(localVideoTrack, {direction: 'sendonly', sendEncodings: encodings, streams: [localStream]});

      const offer = await pc.createOffer();
      console.log(offer.sdp);
   })();


参见:

* `RTCRtpTransceiver <https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpTransceiver>`_, we can get mid(Media Stream ID)
* `RTCRtpEncodingParameters <https://developer.mozilla.org/en-US/docs/Web/API/RTCRtpEncodingParameters>`_, we can set rid(RTP stream ID)
* `RTCPeerConnection.addTransceiver <https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/addTransceiver>`_



SDP grouping Framework
===============================================

SDP 中包含多个 m-line 代表多路媒体流，每个媒体流用 mid 来标识，但是媒体流之间的关系如何描述呢？

RFC5888 中提出了分组的方法，将这些媒体流分为一个个的组

例如

.. code-block::

   v=0
   o=Laura 289083124 289083124 IN IP4 one.example.com
   c=IN IP4 192.0.2.1
   t=0 0
   a=group:LS 1 2
   m=audio 30000 RTP/AVP 0
   a=mid:1
   m=video 30002 RTP/AVP 31
   a=mid:2

LS 即 Lip Synchronization 唇同步的意思


Source-Specific Media Attributes in SDP
================================================

在 RFC5576 Source-Specific Media Attributes in SDP 中定义了两个媒体属性


1. ssrc-group

.. code-block::

   a=ssrc:<ssrc-id> <attribute>
   a=ssrc:<ssrc-id> <attribute>:<value>

1. ssrc  Media Attribute
----------------------------------

.. code-block::

   # The "cname" Source Attribute
   a=ssrc:<ssrc-id> cname:<cname>

   # The "previous-ssrc" Source Attribute
   a=ssrc:<ssrc-id> previous-ssrc:<ssrc-id> ...

   # The "fmtp" Source Attribute
   a=ssrc:<ssrc> fmtp:<format> <format specific parameters>


2. ssrc-group Media Attribute
----------------------------------

.. code-block::

   a=ssrc-group:<semantics> <ssrc-id> ...


SDP 媒体属性“ssrc-group”表示一个 RTP 会话的几个来源之间的关系。 它类似于上面提到的 "SDP grouping Framework" 的会话级属性，它表达了 SDP 多媒体会话中媒体流之间的关系（即，几个逻辑相关的 RTP 会话之间的关系）。

由于源已经由它们的 SSRC ID 标识，因此不需要类似于“mid”属性的属性； 源组由它们的 SSRC ID 直接标识


<semantics> 参数取自“组”属性 [RFC3388] 的规范。 为“ssrc-group”属性定义的初始语义值是 FID（流标识）[RFC3388] 和 FEC（前向纠错）[RFC4756]。 在每种情况下，分组源之间的关系与使用 SDP“组”属性分组的媒体流中的相应源之间的关系相同。

Example
-------------------------------------

例1. 演示了一个视频流，其中一个参会者（由单个 CNAME 标识）具有多个摄像头。 来源可以由 RTCP Source Description (SDES) 进一步区分

.. code-block::

   m=video 49170 RTP/AVP 96
   a=rtpmap:96 H264/90000
   a=ssrc:12345 cname:another-user@example.com
   a=ssrc:67890 cname:another-user@example.com



例2. 演示了用于 RTP 重传 [RFC4588] 的源之间的关系， 当 SSRC 多路复用用于 RTP 重传时，这可以防止将原始源与重传源相关联的复杂性，如 [RFC4588] 的第 5.3 节所述

.. code-block::

   m=video 49174 RTP/AVPF 96 98
   a=rtpmap:96 H.264/90000
   a=rtpmap:98 rtx/90000
   a=fmtp:98 apt=96;rtx-time=3000
   a=ssrc-group:FID 11111 22222
   a=ssrc:11111 cname:user3@example.com
   a=ssrc:22222 cname:user3@example.com
   a=ssrc-group:FID 33333 44444
   a=ssrc:33333 cname:user3@example.com
   a=ssrc:44444 cname:user3@example.com



Negotiating Media Multiplexing Using SDP
================================================


RFC 8843 Negotiating Media Multiplexing Using SDP 中提出了一个新的 SDP 分组框架 [RFC5888] 扩展，“BUNDLE”。

BUNDLE 扩展可以与 SDP 提供/应答机制一起使用来协商一组“m=”部分，这些部分将成为 BUNDLE group 的一部分。

在 BUNDLE group 中，每个“m=”部分使用 BUNDLE 传输来发送和接收捆绑媒体。每个端点使用一个地址：端口组合来发送和接收捆绑的媒体。

BUNDLE 扩展使用具有“BUNDLE”语义值 [RFC5888] 的 SDP 'group' 属性来指示。为每个捆绑的“m=”部分分配一个标识标签，每个标识标签 mid 都列在 SDP 'group:BUNDLE' 属性标识标签列表中。

标识标签列表中列出的标识标签的每个“m=”部分都与给定的 BUNDLE 组相关联。 SDP 主体可以包含多个 BUNDLE 组。

任何给定的捆绑“m=”部分在任何给定时间都不得与多个捆绑组相关联。注意：在 SDP 'group:BUNDLE' 属性标识标签列表中列出的“m=”部分的顺序不必与“m=”部分在 SDP 中出现的顺序相同。

实现 SDP bundle negotiation extension 的 WebRTC 端点将使用 SDP SDP Grouping Framework 中的 "mid" 属性来识别媒体流。
这样的端点必须实现 RFC8843 中描述的 RTP MID 头扩展。

此 RTP 扩展头 使用 RFC828 中描述的通用包头扩展框架，因此需要在使用之前进行协商。


Example
------------------------------------------------

* SDP Offer

.. code-block::

  v=0
  o=alice 2890844526 2890844526 IN IP6 2001:db8::3
  s=
  c=IN IP6 2001:db8::3
  t=0 0
  a=group:BUNDLE foo bar

  m=audio 10000 RTP/AVP 0 8 97
  b=AS:200
  a=mid:foo
  a=rtcp-mux
  a=rtpmap:0 PCMU/8000
  a=rtpmap:8 PCMA/8000
  a=rtpmap:97 iLBC/8000
  a=extmap:1 urn:ietf:params:rtp-hdrext:sdes:mid

  m=video 10002 RTP/AVP 31 32
  b=AS:1000
  a=mid:bar
  a=rtcp-mux
  a=rtpmap:31 H261/90000
  a=rtpmap:32 MPV/90000
  a=extmap:1 urn:ietf:params:rtp-hdrext:sdes:mid


* SDP Answer


.. code-block::

  v=0
  o=bob 2808844564 2808844564 IN IP6 2001:db8::1
  s=
  c=IN IP6 2001:db8::1
  t=0 0
  a=group:BUNDLE foo bar

  m=audio 20000 RTP/AVP 0
  b=AS:200
  a=mid:foo
  a=rtcp-mux
  a=rtpmap:0 PCMU/8000
  a=extmap:1 urn:ietf:params:rtp-hdrext:sdes:mid

  m=video 0 RTP/AVP 32
  b=AS:1000
  a=mid:bar
  a=bundle-only
  a=rtpmap:32 MPV/90000
  a=extmap:1 urn:ietf:params:rtp-hdrext:sdes:mid


Using Simulcast in SDP and RTP Sessions
===============================================================================

RTP 会话中会包含多路的媒体流 media stream，每一路流由 ssrc 这个 RTP 头域来标识。不过，SSRC 和媒体流的关联并不是恒定的.
在一个会话中，，这些 stream 可以用一些标识符来区分，包括 CNAMES, MSID（RFC8830）。

不幸的是，它们在同一时刻可能出现在多路流中，都不合适用来标识一个独立的媒体流

* RFC8852 RTP Stream Identifier Source Description (SDES) 定义了 RTCP SDES 消息扩展和 RID 属性
* RFC7941 RTP Header Extension for the RTP Control Protocol (RTCP) Source Description Items 中定义了相应的 RTP 头扩展
* RFC8853 Using Simulcast in Session Description Protocol (SDP) and RTP Sessions 中定义了 “a=simulcast” 属性


SDP Example
-------------------


因为 `a=simulcast:send 1;2,3 recv 4` , 所以我们知道提议者能够发送两路 media stream (rid=1 和 rid=2或3),
接收一路 media stream (rid=4 )

1) 一个 H.264 编码流，分辨率高达 720p
2) 另一个流编码为 H.264 或 VP8，最大分辨率为 320x180 像素
3) 提议者者可以接收一个最大 720p 分辨率的 H.264 流


* SDP Offer

.. code-block::

   m=video 49300 RTP/AVP 97 98 99
   a=rtpmap:97 H264/90000
   a=rtpmap:98 H264/90000
   a=rtpmap:99 VP8/90000
   a=fmtp:97 profile-level-id=42c01f;max-fs=3600;max-mbps=108000
   a=fmtp:98 profile-level-id=42c00b;max-fs=240;max-mbps=3600
   a=fmtp:99 max-fs=240; max-fr=30
   a=rid:1 send pt=97;max-width=1280;max-height=720
   a=rid:2 send pt=98;max-width=320;max-height=180
   a=rid:3 send pt=99;max-width=320;max-height=180
   a=rid:4 recv pt=97
   a=simulcast:send 1;2,3 recv 4
   a=extmap:1 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id


* SDP Answer

.. code-block::

   m=video 49674 RTP/AVP 97 98
   a=rtpmap:97 H264/90000
   a=rtpmap:98 H264/90000
   a=fmtp:97 profile-level-id=42c01f;max-fs=3600;max-mbps=108000
   a=fmtp:98 profile-level-id=42c00b;max-fs=240;max-mbps=3600
   a=rid:1 recv pt=97;max-width=1280;max-height=720
   a=rid:2 recv pt=98;max-width=320;max-height=180
   a=rid:4 send pt=97
   a=simulcast:recv 1;2 send 4
   a=extmap:1 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id


更多示例参见 https://datatracker.ietf.org/doc/html/rfc8853

* RTCP "RtpStreamId" SDES Extension

.. code-block::

        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |RtpStreamId=12 |     length    | RtpStreamId                 ...
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

   The RtpStreamId payload is ASCII encoded and is not null terminated.

*  RTCP "RepairedRtpStreamId" SDES Extension

.. code-block::

        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |Repaired...=13 |     length    | RepairRtpStreamId           ...
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


Using SSRC with WebRTC Simulcast
=========================================
it is "draft-alvestrand-mmusic-simulcast-ssrc-01" now , which define "Semantics: Simulcast group"
(refer to https://datatracker.ietf.org/doc/html/draft-alvestrand-mmusic-simulcast-ssrc-01)

It describes a convention for sending "a=ssrc" attributes in SDP together with "a=simulcast" attributes.
This allows SFUs that need SSRC information to have this info easily accessible.

.. code-block::

   m=video
   a=simulcast:send hi,mid,low
   a=rid:hi send
   a=rid:mid send
   a=rid:low send
   a=ssrc-group:SIM 123 456 789
   a=ssrc:123 cname:foo
   a=ssrc:456 cname:foo
   a=ssrc:789 cname:foo



WebRTC library 中对 simulcast 的描述
========================================


.. code-block::

   // Describes a Simulcast Layer.
   // Each simulcast layer has a rid as the identifier and a paused flag.
   // See also: https://tools.ietf.org/html/draft-ietf-mmusic-rid-15 for
   // an explanation about rids.
   struct SimulcastLayer final {
      SimulcastLayer(absl::string_view rid, bool is_paused);

      SimulcastLayer(const SimulcastLayer& other) = default;
      SimulcastLayer& operator=(const SimulcastLayer& other) = default;
      bool operator==(const SimulcastLayer& other) const;

      std::string rid;
      bool is_paused;
   };

   // Describes a list of Simulcast layers.
   // Simulcast layers are specified in order of preference.
   // Each layer can have a list of alternatives (in order of preference).
   // https://tools.ietf.org/html/draft-ietf-mmusic-sdp-simulcast-13#section-5.1
   // Example Usage:
   //   To populate a list that specifies the following:
   //     1. Layer 1 or Layer 2
   //     2. Layer 3
   //     3. Layer 4 or Layer 5
   //   Use the following code:
   //     SimulcastLayerList list;
   //     list.AddLayerWithAlternatives(
   //            {SimulcastLayer("1", false), SimulcastLayer("2", false});
   //     list.AddLayer("3");
   //     list.AddLayerWithAlternatives(
   //            {SimulcastLayer("4", false), SimulcastLayer("5", false});
   class SimulcastLayerList final {
      public:
      // Type definitions required by a container.
      typedef size_t size_type;
      typedef std::vector<SimulcastLayer> value_type;
      typedef std::vector<std::vector<SimulcastLayer>>::const_iterator
            const_iterator;

      // Use to add a layer when there will be no alternatives.
      void AddLayer(const SimulcastLayer& layer);

      // Use to add a list of alternatives.
      // The alternatives should be specified in order of preference.
      void AddLayerWithAlternatives(const std::vector<SimulcastLayer>& layers);

      // Read-only access to the contents.
      // Note: This object does not allow removal of layers.
      const_iterator begin() const { return list_.begin(); }

      const_iterator end() const { return list_.end(); }

      const std::vector<SimulcastLayer>& operator[](size_t index) const;

      size_t size() const { return list_.size(); }
      bool empty() const { return list_.empty(); }

      // Provides access to all the layers in the simulcast without their
      // association into groups of alternatives.
      std::vector<SimulcastLayer> GetAllLayers() const;

      private:
      // TODO(amithi, bugs.webrtc.org/10075):
      // Validate that rids do not repeat in the list.
      std::vector<std::vector<SimulcastLayer>> list_;
   };

   // Describes the simulcast options of a video media section.
   // This will list the send and receive layers (along with their alternatives).
   // Each simulcast layer has an identifier (rid) and can optionally be paused.
   // The order of the layers (as well as alternates) indicates user preference
   // from first to last (most preferred to least preferred).
   // https://tools.ietf.org/html/draft-ietf-mmusic-sdp-simulcast-13#section-5.1
   class SimulcastDescription final {
   public:
      const SimulcastLayerList& send_layers() const { return send_layers_; }
      SimulcastLayerList& send_layers() { return send_layers_; }

      const SimulcastLayerList& receive_layers() const { return receive_layers_; }
      SimulcastLayerList& receive_layers() { return receive_layers_; }

      bool empty() const;

      private:
      // TODO(amithi, bugs.webrtc.org/10075):
      // Validate that rids do not repeat in send and receive layers.
      SimulcastLayerList send_layers_;
      SimulcastLayerList receive_layers_;
   };


参考资料
====================
* `RFC5576`_\ : Source-Specific Media Attributes in SDP
* `RFC8843`_\ : Negotiating Media Multiplexing Using the Session Description Protocol(SDP)
* `RFC8852`_\ : RTP Stream Identifier Source Description (SDES)
* `RFC7941`_\ : RTP Header Extension for the RTP Control Protocol (RTCP) Source Description Items
* `RFC8853`_\ : Using Simulcast in Session Description Protocol (SDP) and RTP Sessions
