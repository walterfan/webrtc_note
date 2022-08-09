##############################
WebRTC RTP Sender
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC RTP Sender
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
======================================

A RTCPeerConnection method getSenders() returns an array of RTCRtpSender objects, each of which represents the RTP sender responsible for transmitting one track's data.

A sender object provides methods and properties for examining and controlling the encoding and transmission of the track's data.


和 Javascript 中的 API 定义的 RTCRtpSender 类似，这里的 RTPSender 就是 C++ 层面的实现


Implementation
======================================

RtpState
------------------
RtpSender 会维护一个状态

.. code-block::

    struct RtpState {
        uint16_t sequence_number;
        uint32_t start_timestamp;
        uint32_t timestamp;
        int64_t capture_time_ms;
        int64_t last_timestamp_time_ms;
        bool ssrc_has_acked;
    };



Packet History
-------------------

RtpSender 维护了一个用来存储发送过的包的队列，称为 Packet History, 根据 sequence  number 来排序
老包放在队首，新包放在队尾

.. code-block:: c++

    RtpPacketHistory* const packet_history_;

由于存在 sequence number 回滚的情况，队尾的包的 sequence  number 有可能比之前的包小。

RtpPacketHistory 包含了一个队列，队列的元素是 `StoredPacket` , 形如 `std::deque<StoredPacket> packet_history_`


对 NACK 的处理
-------------------

收到  NACK 请求，根据 sequence number 从发送缓存中找到相应的包重发

.. code-block:: c++

    void RTPSender::OnReceivedNack(
        const std::vector<uint16_t>& nack_sequence_numbers,
        int64_t avg_rtt) {
    packet_history_->SetRtt(TimeDelta::Millis(5 + avg_rtt));
    for (uint16_t seq_no : nack_sequence_numbers) {
        const int32_t bytes_sent = ReSendPacket(seq_no);
        if (bytes_sent < 0) {
            // Failed to send one Sequence number. Give up the rest in this nack.
            RTC_LOG(LS_WARNING) << "Failed resending RTP packet " << seq_no
                                << ", Discard rest of packets.";
            break;
        }
    }
    }


重发 RTP 包
-------------------

.. code-block::

    int32_t RTPSender::ReSendPacket(uint16_t packet_id) {
        int32_t packet_size = 0;
        const bool rtx = (RtxStatus() & kRtxRetransmitted) > 0;

        std::unique_ptr<RtpPacketToSend> packet =
            packet_history_->GetPacketAndMarkAsPending(
                packet_id, [&](const RtpPacketToSend& stored_packet) {
                    // Check if we're overusing retransmission bitrate.
                    // TODO(sprang): Add histograms for nack success or failure
                    // reasons.
                    packet_size = stored_packet.size();
                    std::unique_ptr<RtpPacketToSend> retransmit_packet;
                    if (retransmission_rate_limiter_ &&
                        !retransmission_rate_limiter_->TryUseRate(packet_size)) {
                            return retransmit_packet;
                    }
                    // walter: 如果开启了 RTX, 就构建 RTX 包，否则就用原始的流，相同的 SSRC
                    if (rtx) {
                        retransmit_packet = BuildRtxPacket(stored_packet);
                    } else {
                        retransmit_packet =
                            std::make_unique<RtpPacketToSend>(stored_packet);
                    }

                    if (retransmit_packet) {
                        retransmit_packet->set_retransmitted_sequence_number(
                            stored_packet.SequenceNumber());
                    }
                    return retransmit_packet;
                });

        if (packet_size == 0) {
            // Packet not found or already queued for retransmission, ignore.
            RTC_DCHECK(!packet);
            return 0;
        }
        if (!packet) {
            // Packet was found, but lambda helper above chose not to create
            // `retransmit_packet` out of it.
            return -1;
        }

        packet->set_packet_type(RtpPacketMediaType::kRetransmission);
        packet->set_fec_protect_packet(false);
        std::vector<std::unique_ptr<RtpPacketToSend>> packets;
        packets.emplace_back(std::move(packet));
        paced_sender_->EnqueuePackets(std::move(packets));

        return packet_size;
    }


构建 RTX 包
---------------

.. code-block::

    std::unique_ptr<RtpPacketToSend> RTPSender::BuildRtxPacket(
        const RtpPacketToSend& packet) {
    std::unique_ptr<RtpPacketToSend> rtx_packet;

    // Walter: 先添加原始的 RTP 包头
    // Add original RTP header.
    {
        MutexLock lock(&send_mutex_);
        if (!sending_media_)
        return nullptr;

        RTC_DCHECK(rtx_ssrc_);
        // Walter: 将 payload type 修改为重传的 RTP 包的 payload type
        // Replace payload type.
        auto kv = rtx_payload_type_map_.find(packet.PayloadType());
        if (kv == rtx_payload_type_map_.end())
        return nullptr;

        rtx_packet = std::make_unique<RtpPacketToSend>(&rtp_header_extension_map_,
                                                    max_packet_size_);

        rtx_packet->SetPayloadType(kv->second);
        // Walter: 将 SSRC 修改为 RTX 重传包的 SSRC
        // Replace SSRC.
        rtx_packet->SetSsrc(*rtx_ssrc_);

        CopyHeaderAndExtensionsToRtxPacket(packet, rtx_packet.get());

        // Walter: RTX 包和原始包使用不同的 SSRC , 通过 MID 和  RRID 将其关联起来
        // Walter: 关联的规则就是相同的 MID, RTX 包头中的 RRID 扩展头中存放的是原始包的 RID

        // RTX packets are sent on an SSRC different from the main media, so the
        // decision to attach MID and/or RRID header extensions is completely
        // separate from that of the main media SSRC.
        //
        // Note that RTX packets must used the RepairedRtpStreamId (RRID) header
        // extension instead of the RtpStreamId (RID) header extension even though
        // the payload is identical.
        if (always_send_mid_and_rid_ || !rtx_ssrc_has_acked_) {
        // These are no-ops if the corresponding header extension is not
        // registered.
        if (!mid_.empty()) {
            rtx_packet->SetExtension<RtpMid>(mid_);
        }
        if (!rid_.empty()) {
            rtx_packet->SetExtension<RepairedRtpStreamId>(rid_);
        }
        }
    }
    RTC_DCHECK(rtx_packet);

    uint8_t* rtx_payload =
        rtx_packet->AllocatePayload(packet.payload_size() + kRtxHeaderSize);
    if (rtx_payload == nullptr)
        return nullptr;

    // Walter: 添加原始包的 sequence number
    // Add OSN (original sequence number).
    ByteWriter<uint16_t>::WriteBigEndian(rtx_payload, packet.SequenceNumber());

    // Walter: 复制原始包的 payload
    // Add original payload data.
    auto payload = packet.payload();
    memcpy(rtx_payload + kRtxHeaderSize, payload.data(), payload.size());
    // Walter: 复制原始包的 additional data
    // Add original additional data.
    rtx_packet->set_additional_data(packet.additional_data());

    // Walter: 复制原始包的 capture time
    // Copy capture time so e.g. TransmissionOffset is correctly set.
    rtx_packet->set_capture_time(packet.capture_time());

    return rtx_packet;
    }