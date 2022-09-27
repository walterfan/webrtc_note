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

main classes
=========================


* RtxReceiveStream

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