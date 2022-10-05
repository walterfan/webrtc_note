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
===============================


RTX Config
===============================
RtpConfig 类有两个 SSRC 列表

* ssrcs
* rtx.ssrcs

 If we use RTX there MUST be an association ssrcs[i] <-> rtx.ssrcs[i].
 参见 `rtp_config.h`_


.. _rtp_config.h: https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/call/rtp_config.h?q=rtp_config.h&ss=chromium%2Fchromium%2Fsrc

RTX 包的接收与处理
===============================

VideoReceiveStream2 的构建函数中创建 RtxReceiveStream


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


    //判断是不是 RTX 流就根据 config_.rtp.rtx_ssrc
    uint32_t rtx_ssrc() const { return config_.rtp.rtx_ssrc; }


那么  rtx_ssrc  是从哪里知道的呢，一个方法是通过 FID SSRC Group


如果发现所收到的 RTP packet 的 SSRC 是属于 RTX stream 的，就会创建 RTXReceiveStream

还有一种就是通过 RID (RtpStreamID) 和 RRID (RepairedRtpStreamID)

.. code-block:: cpp


    void RtxReceiveStream::OnRtpPacket(const RtpPacketReceived& rtx_packet) {
        RTC_DCHECK_RUN_ON(&packet_checker_);
        if (rtp_receive_statistics_) {
            rtp_receive_statistics_->OnRtpPacket(rtx_packet);
        }
        rtc::ArrayView<const uint8_t> payload = rtx_packet.payload();

        if (payload.size() < kRtxHeaderSize) {
            return;
        }

        auto it = associated_payload_types_.find(rtx_packet.PayloadType());
        if (it == associated_payload_types_.end()) {
            RTC_DLOG(LS_VERBOSE) << "Unknown payload type "
                                << static_cast<int>(rtx_packet.PayloadType())
                                << " on rtx ssrc " << rtx_packet.Ssrc();
            return;
        }
        RtpPacketReceived media_packet;
        media_packet.CopyHeaderFrom(rtx_packet);

        media_packet.SetSsrc(media_ssrc_);
        media_packet.SetSequenceNumber((payload[0] << 8) + payload[1]);
        media_packet.SetPayloadType(it->second);
        media_packet.set_recovered(true);
        media_packet.set_arrival_time(rtx_packet.arrival_time());

        // Skip the RTX header.
        rtc::ArrayView<const uint8_t> rtx_payload = payload.subview(kRtxHeaderSize);

        uint8_t* media_payload = media_packet.AllocatePayload(rtx_payload.size());
        RTC_DCHECK(media_payload != nullptr);

        memcpy(media_payload, rtx_payload.data(), rtx_payload.size());

        media_sink_->OnRtpPacket(media_packet);
    }




Relative Classes
============================================


.. code-block::


    class VideoReceiveStream2:
        pass

    class RtxReceiveStream:
        pass




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
* 参见 `webrtc demux <webrtc_demux.html>`_

可以通过 MID, RSID 以及 SSRC 来进行分解


.. code-block:: cpp

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

Call
--------------------------------------------

Call 是代表一个会话的实体,



* 创建 Send 和 Receive stream

.. code-block::

    webrtc::VideoReceiveStreamInterface* Call::CreateVideoReceiveStream


* 收到的包要进行识别


.. code-block:: cpp


    bool Call::IdentifyReceivedPacket(RtpPacketReceived& packet,
                                  bool* use_send_side_bwe /*= nullptr*/) {
        RTC_DCHECK_RUN_ON(&receive_11993_checker_);
        auto it = receive_rtp_config_.find(packet.Ssrc());
        if (it == receive_rtp_config_.end()) {
            RTC_DLOG(LS_WARNING) << "receive_rtp_config_ lookup failed for ssrc "
                                << packet.Ssrc();
            return false;
        }

        packet.IdentifyExtensions(it->second->GetRtpExtensionMap());

        if (use_send_side_bwe) {
            *use_send_side_bwe = UseSendSideBwe(it->second);
        }

        return true;
    }



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


在 SDP 中没指定的 SSRC 会在 OnUnsignalledSsrc 方法中处理并创建相应的 ReceiveStream


.. code-block::

    UnsignalledSsrcHandler::Action DefaultUnsignalledSsrcHandler::OnUnsignalledSsrc(..)

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


    void WebRtcVideoChannel::OnPacketReceived(rtc::CopyOnWriteBuffer packet,
                                          int64_t packet_time_us) {
        RTC_DCHECK_RUN_ON(&network_thread_checker_);
        // TODO(bugs.webrtc.org/11993): This code is very similar to what
        // WebRtcVoiceMediaChannel::OnPacketReceived does. For maintainability and
        // consistency it would be good to move the interaction with call_->Receiver()
        // to a common implementation and provide a callback on the worker thread
        // for the exception case (DELIVERY_UNKNOWN_SSRC) and how retry is attempted.
        worker_thread_->PostTask(
            SafeTask(task_safety_.flag(), [this, packet, packet_time_us] {
                RTC_DCHECK_RUN_ON(&thread_checker_);
                const webrtc::PacketReceiver::DeliveryStatus delivery_result =
                    call_->Receiver()->DeliverPacket(webrtc::MediaType::VIDEO, packet,
                                                    packet_time_us);
                switch (delivery_result) {
                case webrtc::PacketReceiver::DELIVERY_OK:
                    return;
                case webrtc::PacketReceiver::DELIVERY_PACKET_ERROR:
                    return;
                case webrtc::PacketReceiver::DELIVERY_UNKNOWN_SSRC:
                    break;
                }
        //...
    }


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

.. code-block::

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


Relative log
======================


.. code-block::


    [813310:25:1003/011612.144105:INFO:webrtc_video_engine.cc(1234)] SetRecvParameters: {codecs: [VideoCodec[102:H264], VideoCodec[123:rtx], VideoCodec[127:H264], VideoCodec[122:rtx], VideoCodec[125:H264], VideoCodec[107:rtx], VideoCodec[108:H264], VideoCodec[109:rtx], VideoCodec[124:H264], VideoCodec[121:rtx], VideoCodec[39:H264], VideoCodec[40:rtx]], extensions: [{uri: http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01, id: 4}, {uri: http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time, id: 2}, {uri: http://www.webrtc.org/experiments/rtp-hdrext/color-space, id: 8}, {uri: http://www.webrtc.org/experiments/rtp-hdrext/playout-delay, id: 5}, {uri: http://www.webrtc.org/experiments/rtp-hdrext/video-content-type, id: 6}, {uri: http://www.webrtc.org/experiments/rtp-hdrext/video-timing, id: 7}, {uri: urn:3gpp:video-orientation, id: 3}, {uri: urn:ietf:params:rtp-hdrext:sdes:mid, id: 9}, {uri: urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id, id: 11}, {uri: urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id, id: 10}, {uri: urn:ietf:params:rtp-hdrext:toffset, id: 1}]}

    video_receive_stream2.cc(234)] VideoReceiveStream2: {decoders: [{payload_type: 102, payload_name: H264, codec_params: {level-asymmetry-allowed: 1, packetization-mode: 1, profile-level-id: 42001f}}, {payload_type: 127, payload_name: H264, codec_params: {level-asymmetry-allowed: 1, packetization-mode: 0, profile-level-id: 42001f}}, {payload_type: 125, payload_name: H264, codec_params: {level-asymmetry-allowed: 1, packetization-mode: 1, profile-level-id: 42e01f}}, {payload_type: 108, payload_name: H264, codec_params: {level-asymmetry-allowed: 1, packetization-mode: 0, profile-level-id: 42e01f}}, {payload_type: 124, payload_name: H264, codec_params: {level-asymmetry-allowed: 1, packetization-mode: 1, profile-level-id: 4d001f}}, {payload_type: 39, payload_name: H264, codec_params: {level-asymmetry-allowed: 1, packetization-mode: 0, profile-level-id: 4d001f}}, {payload_type: 41, payload_name: H264, codec_params: {level-asymmetry-allowed: 1, packetization-mode: 1, profile-level-id: f4001f}}, {payload_type: 43, payload_name: H264, codec_params: {level-asymmetry-allowed: 1, packetization-mode: 0, profile-level-id: f4001f}}], rtp: {remote_ssrc: 1850072183, local_ssrc: 1, rtcp_mode: RtcpMode::kCompound, rtcp_xr: {receiver_reference_time_report: off}, transport_cc: off, lntf: {enabled: false}, nack: {rtp_history_ms: 1000}, ulpfec_payload_type: -1, red_type: -1, rtx_ssrc: 0, rtx_payload_types: {40 (pt) -> 39 (apt), 42 (pt) -> 41 (apt), 44 (pt) -> 43 (apt), 107 (pt) -> 125 (apt), 109 (pt) -> 108 (apt), 121 (pt) -> 124 (apt), 122 (pt) -> 127 (apt), 123 (pt) -> 102 (apt), }, raw_payload_types: {}, extensions: [{uri: http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01, id: 4}, {uri: http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time, id: 2}, {uri: http://www.webrtc.org/experiments/rtp-hdrext/color-space, id: 8}, {uri: http://www.webrtc.org/experiments/rtp-hdrext/playout-delay, id: 5}, {uri: http://www.webrtc.org/experiments/rtp-hdrext/video-content-type, id: 6}, {uri: http://www.webrtc.org/experiments/rtp-hdrext/video-timing, id: 7}, {uri: urn:3gpp:video-orientation, id: 3}, {uri: urn:ietf:params:rtp-hdrext:sdes:mid, id: 9}, {uri: urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id, id: 11}, {uri: urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id, id: 10}, {uri: urn:ietf:params:rtp-hdrext:toffset, id: 1}]}, renderer: (renderer), render_delay_ms: 10}