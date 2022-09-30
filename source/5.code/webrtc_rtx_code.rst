##############################
WebRTC RTX Code
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC RTX Code
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============


Call flow
================

* VideoReceiveStream2::VideoReceiveStream2
*

.. code-block:: python

    class VideoReceiveStream2:
        pass

    class RtxReceiveStream:
        pass


Snippets
------------------

.. code-block:: cpp


    VideoReceiveStream2::VideoReceiveStream2(
    TaskQueueFactory* task_queue_factory,
    Call* call,
    int num_cpu_cores,
    PacketRouter* packet_router,
    VideoReceiveStreamInterface::Config config,
    CallStats* call_stats,
    Clock* clock,
    std::unique_ptr<VCMTiming> timing,
    NackPeriodicProcessor* nack_periodic_processor,
    DecodeSynchronizer* decode_sync)
        //...
        if (rtx_ssrc()) {
            rtx_receive_stream_ = std::make_unique<RtxReceiveStream>(
                &rtp_video_stream_receiver_, config_.rtp.rtx_associated_payload_types,
                remote_ssrc(), rtp_receive_statistics_.get());
        } else {
            rtp_receive_statistics_->EnableRetransmitDetection(remote_ssrc(), true);
        }
        //...
    }

    uint32_t rtx_ssrc() const { return config_.rtp.rtx_ssrc; }

main classes
=========================
RtpTransport
--------------------------------------------
* third_party/webrtc/pc/rtp_transport.h

.. code-block::

    void RtpTransport::DemuxPacket(rtc::CopyOnWriteBuffer packet,
                               int64_t packet_time_us) {
        webrtc::RtpPacketReceived parsed_packet(
            &header_extension_map_, packet_time_us == -1
                                        ? Timestamp::MinusInfinity()
                                        : Timestamp::Micros(packet_time_us));
        if (!parsed_packet.Parse(std::move(packet))) {
            RTC_LOG(LS_ERROR)
                << "Failed to parse the incoming RTP packet before demuxing. Drop it.";
            return;
        }

        if (!rtp_demuxer_.OnRtpPacket(parsed_packet)) {
            RTC_LOG(LS_WARNING) << "Failed to demux RTP packet: "
                                << RtpDemuxer::DescribePacket(parsed_packet);
        }
    }



RtpDemuxer
--------------------------------------------
* third_party/webrtc/call/rtp_demuxer.cc

.. code-block:: cpp


    // This class represents the RTP demuxing, for a single RTP session (i.e., one
    // SSRC space, see RFC 7656). It isn't thread aware, leaving responsibility of
    // multithreading issues to the user of this class.
    // The demuxing algorithm follows the sketch given in the BUNDLE draft:
    // https://tools.ietf.org/html/draft-ietf-mmusic-sdp-bundle-negotiation-38#section-10.2
    // with modifications to support RTP stream IDs also.
    //
    // When a packet is received, the RtpDemuxer will route according to the
    // following rules:
    // 1. If the packet contains the MID header extension, and no sink has been
    //    added with that MID as a criteria, the packet is not routed.
    // 2. If the packet has the MID header extension, but no RSID or RRID extension,
    //    and the MID is bound to a sink, then bind its SSRC to the same sink and
    //    forward the packet to that sink. Note that rebinding to the same sink is
    //    not an error. (Later packets with that SSRC would therefore be forwarded
    //    to the same sink, whether they have the MID header extension or not.)
    // 3. If the packet has the MID header extension and either the RSID or RRID
    //    extension, and the MID, RSID (or RRID) pair is bound to a sink, then bind
    //    its SSRC to the same sink and forward the packet to that sink. Later
    //    packets with that SSRC will be forwarded to the same sink.
    // 4. If the packet has the RSID or RRID header extension, but no MID extension,
    //    and the RSID or RRID is bound to an RSID sink, then bind its SSRC to the
    //    same sink and forward the packet to that sink. Later packets with that
    //    SSRC will be forwarded to the same sink.
    // 5. If the packet's SSRC is bound to an SSRC through a previous call to
    //    AddSink, then forward the packet to that sink. Note that the RtpDemuxer
    //    will not verify the payload type even if included in the sink's criteria.
    //    The sink is expected to do the check in its handler.
    // 6. If the packet's payload type is bound to exactly one payload type sink
    //    through an earlier call to AddSink, then forward the packet to that sink.
    // 7. Otherwise, the packet is not routed.
    //
    // In summary, the routing algorithm will always try to first match MID and RSID
    // (including through SSRC binding), match SSRC directly as needed, and use
    // payload types only if all else fails.
    class RtpDemuxer {

        // Map each sink by its component attributes to facilitate quick lookups.
        // Payload Type mapping is a multimap because if two sinks register for the
        // same payload type, both AddSinks succeed but we must know not to demux on
        // that attribute since it is ambiguous.
        // Note: Mappings are only modified by AddSink/RemoveSink (except for
        // SSRC mapping which receives all MID, payload type, or RSID to SSRC bindings
        // discovered when demuxing packets).
        flat_map<std::string, RtpPacketSinkInterface*> sink_by_mid_;
        flat_map<uint32_t, RtpPacketSinkInterface*> sink_by_ssrc_;
        std::multimap<uint8_t, RtpPacketSinkInterface*> sinks_by_pt_;
        flat_map<std::pair<std::string, std::string>, RtpPacketSinkInterface*>
            sink_by_mid_and_rsid_;
        flat_map<std::string, RtpPacketSinkInterface*> sink_by_rsid_;

        //...
    };

    RtpPacketSinkInterface* RtpDemuxer::ResolveSink(
    const RtpPacketReceived& packet) {
        // See the BUNDLE spec for high level reference to this algorithm:
        // https://tools.ietf.org/html/draft-ietf-mmusic-sdp-bundle-negotiation-38#section-10.2

        // RSID and RRID are routed to the same sinks. If an RSID is specified on a
        // repair packet, it should be ignored and the RRID should be used.
        std::string packet_mid, packet_rsid;
        bool has_mid = use_mid_ && packet.GetExtension<RtpMid>(&packet_mid);
        bool has_rsid = packet.GetExtension<RepairedRtpStreamId>(&packet_rsid);
        if (!has_rsid) {
            has_rsid = packet.GetExtension<RtpStreamId>(&packet_rsid);
        }
        uint32_t ssrc = packet.Ssrc();

        // The BUNDLE spec says to drop any packets with unknown MIDs, even if the
        // SSRC is known/latched.
        if (has_mid && known_mids_.find(packet_mid) == known_mids_.end()) {
            return nullptr;

        //... important-- resolve MID/RID
    }


    RtpPacketSinkInterface* RtpDemuxer::ResolveSinkByMidRsid(absl::string_view mid,
                                                            absl::string_view rsid,
                                                            uint32_t ssrc) {
        const auto it = sink_by_mid_and_rsid_.find(
            std::make_pair(std::string(mid), std::string(rsid)));
        if (it != sink_by_mid_and_rsid_.end()) {
            RtpPacketSinkInterface* sink = it->second;
            AddSsrcSinkBinding(ssrc, sink);
            return sink;
        }
        return nullptr;
    }


    // static
    std::string RtpDemuxer::DescribePacket(const RtpPacketReceived& packet) {
        rtc::StringBuilder sb;
        sb << "PT=" << packet.PayloadType() << " SSRC=" << packet.Ssrc();
        std::string mid;
        if (packet.GetExtension<RtpMid>(&mid)) {
            sb << " MID=" << mid;
        }
        std::string rsid;
        if (packet.GetExtension<RtpStreamId>(&rsid)) {
            sb << " RSID=" << rsid;
        }
        std::string rrsid;
        if (packet.GetExtension<RepairedRtpStreamId>(&rrsid)) {
            sb << " RRSID=" << rrsid;
        }
        return sb.Release();
    }

Call
--------------------------------------------

.. code-block:: cpp


    void Call::OnRecoveredPacket(const uint8_t* packet, size_t length) {
        // TODO(bugs.webrtc.org/11993): Expect to be called on the network thread.
        // This method is called synchronously via `OnRtpPacket()` (see DeliverRtp)
        // on the same thread.
        RTC_DCHECK_RUN_ON(worker_thread_);
        RtpPacketReceived parsed_packet;
        if (!parsed_packet.Parse(packet, length))
            return;

        parsed_packet.set_recovered(true);

        if (!IdentifyReceivedPacket(parsed_packet))
            return;

        // TODO(brandtr): Update here when we support protecting audio packets too.
        parsed_packet.set_payload_type_frequency(kVideoPayloadTypeFrequency);
        video_receiver_controller_.OnRtpPacket(parsed_packet);
    }

    webrtc::VideoReceiveStreamInterface* Call::CreateVideoReceiveStream(
    webrtc::VideoReceiveStreamInterface::Config configuration) {
        //...

        // TODO(bugs.webrtc.org/11993): Move the registration between `receive_stream`
        // and `video_receiver_controller_` out of VideoReceiveStream2 construction
        // and set it up asynchronously on the network thread (the registration and
        // `video_receiver_controller_` need to live on the network thread).
        VideoReceiveStream2* receive_stream = new VideoReceiveStream2(
            task_queue_factory_, this, num_cpu_cores_,
            transport_send_->packet_router(), std::move(configuration),
            call_stats_.get(), clock_, std::make_unique<VCMTiming>(clock_, trials()),
            &nack_periodic_processor_, decode_sync_.get());
        // TODO(bugs.webrtc.org/11993): Set this up asynchronously on the network
        // thread.
        receive_stream->RegisterWithTransport(&video_receiver_controller_);

        if (receive_stream->rtx_ssrc()) {
            // We record identical config for the rtx stream as for the main
            // stream. Since the transport_send_cc negotiation is per payload
            // type, we may get an incorrect value for the rtx stream, but
            // that is unlikely to matter in practice.
            RegisterReceiveStream(receive_stream->rtx_ssrc(), receive_stream);
        }
        //...
    }


WebRtcVideoChannel
-------------------------------------------
* webrtc_video_engine.cc


.. code-block:: cpp


    bool WebRtcVideoChannel::AddRecvStream(const StreamParams& sp,
                                       bool default_stream) {


        //...

        webrtc::VideoReceiveStreamInterface::Config config(this, decoder_factory_);
        webrtc::FlexfecReceiveStream::Config flexfec_config(this);
        ConfigureReceiverRtp(&config, &flexfec_config, sp);
        //...
        receive_streams_[sp.first_ssrc()] = new WebRtcVideoReceiveStream(
        this, call_, sp, std::move(config), default_stream, recv_codecs_,
        flexfec_config);

    return true;
    }

    void WebRtcVideoChannel::ConfigureReceiverRtp(
    webrtc::VideoReceiveStreamInterface::Config* config,
    webrtc::FlexfecReceiveStream::Config* flexfec_config,
    const StreamParams& sp) const {
        //...
        sp.GetFidSsrc(ssrc, &config->rtp.rtx_ssrc);

        config->rtp.extensions = recv_rtp_extensions_;
        //...
    }


VideoReceiveStream2
-------------------------------------------



VideoReceiveStreamInterface::Config
-------------------------------------------


.. code-block:: cpp

    // Receive-stream specific RTP settings.
    struct Rtp : public ReceiveStreamRtpConfig {
      Rtp();
      Rtp(const Rtp&);
      ~Rtp();
      std::string ToString() const;

      // See NackConfig for description.
      NackConfig nack;

      // See RtcpMode for description.
      RtcpMode rtcp_mode = RtcpMode::kCompound;

      // Extended RTCP settings.
      struct RtcpXr {
        // True if RTCP Receiver Reference Time Report Block extension
        // (RFC 3611) should be enabled.
        bool receiver_reference_time_report = false;
      } rtcp_xr;

      // How to request keyframes from a remote sender. Applies only if lntf is
      // disabled.
      KeyFrameReqMethod keyframe_method = KeyFrameReqMethod::kPliRtcp;

      // See LntfConfig for description.
      LntfConfig lntf;

      // Payload types for ULPFEC and RED, respectively.
      int ulpfec_payload_type = -1;
      int red_payload_type = -1;

      // SSRC for retransmissions.
      uint32_t rtx_ssrc = 0;

      // Set if the stream is protected using FlexFEC.
      bool protected_by_flexfec = false;

      // Optional callback sink to support additional packet handlsers such as
      // FlexFec.
      RtpPacketSinkInterface* packet_sink_ = nullptr;

      // Map from rtx payload type -> media payload type.
      // For RTX to be enabled, both an SSRC and this mapping are needed.
      std::map<int, int> rtx_associated_payload_types;

      // Payload types that should be depacketized using raw depacketizer
      // (payload header will not be parsed and must not be present, additional
      // meta data is expected to be present in generic frame descriptor
      // RTP header extension).
      std::set<int> raw_payload_types;
    } rtp;


RtxReceiveStream
-------------------------------------------

* ./third_party/webrtc/call/rtx_receive_stream.cc

.. code-block:: cpp

    diff --git a/call/rtx_receive_stream.cc b/call/rtx_receive_stream.cc
    index 6c5fa3f859..47df8c0bb9 100644
    --- a/call/rtx_receive_stream.cc
    +++ b/call/rtx_receive_stream.cc
    @@ -33,6 +33,7 @@ RtxReceiveStream::RtxReceiveStream(
        media_ssrc_(media_ssrc),
        rtp_receive_statistics_(rtp_receive_statistics) {
    packet_checker_.Detach();
    +  RTC_LOG(LS_INFO) << " walter: RtxReceiveStream created, media_ssrc=" << media_ssrc;
    if (associated_payload_types_.empty()) {
        RTC_LOG(LS_WARNING)
            << "RtxReceiveStream created with empty payload type mapping.";
    @@ -53,7 +54,7 @@ void RtxReceiveStream::OnRtpPacket(const RtpPacketReceived& rtx_packet) {
        rtp_receive_statistics_->OnRtpPacket(rtx_packet);
    }
    rtc::ArrayView<const uint8_t> payload = rtx_packet.payload();
    -
    +  RTC_LOG(LS_INFO) << " walter2: OnRtpPacket, ssrc=" << rtx_packet.Ssrc() << ", sn=" << rtx_packet.SequenceNumber();
    if (payload.size() < kRtxHeaderSize) {
        return;
    }
    @@ -67,13 +68,13 @@ void RtxReceiveStream::OnRtpPacket(const RtpPacketReceived& rtx_packet) {
    }
    RtpPacketReceived media_packet;
    media_packet.CopyHeaderFrom(rtx_packet);
    -
    +
    media_packet.SetSsrc(media_ssrc_);
    media_packet.SetSequenceNumber((payload[0] << 8) + payload[1]);
    media_packet.SetPayloadType(it->second);
    media_packet.set_recovered(true);
    media_packet.set_arrival_time(rtx_packet.arrival_time());
    -
    +  RTC_LOG(LS_INFO) << " walter2: OnRtpPacket, media packet ssrc=" << rtx_packet.Ssrc() << ", osn=" << media_packet.SequenceNumber();
    :