########################
WebRTC RTX
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC RTX
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


简介
=========================

在 WebRTC 中常用的 QoS 策略有

1. 反馈：例如 PLI , NACK
2. 冗余， 例如 FEC, RTX, Interleaving 交织编码
3. 调整：例如码率，分辨率及帧率的调整
4. 缓存:  例如 Receive Adaptive Jitter Buffer, Send Buffer

这些措施的采用需要基于拥塞控制(congestion control) 及带宽估计(bandwidth estimation)技术, 不同的网络条件下需要采用不同的措施。

`RFC2354`_ 对这些方法有所讨论， FEC 用作丢包恢复需要占用更多的带宽，即使 5% 的丢包需要几乎一倍的带宽，在带宽有限的情况下可能会使情况更糟。

RTX 不会占用太多的带宽，接收方发送 NACK 指明哪些包丢失了，发送方通过单独的 RTP 流（不同的 SSRC）来重传丢失的包，但是 RTX 至少需要一个 RTT 来修复丢失的包。

音频流对于延迟很敏感，而且占用带宽不多，所以用 FEC 更好。
视频流对于延迟没那么敏感，而且占用带宽很多，所以用 RTX 更好。

所以 RTP 重传是一种有效的丢包恢复技术，适用于具有宽松延迟限制的实时应用程序。

`RFC4588`_ describes an RTP payload format for performing retransmissions.  Retransmitted RTP packets are sent in a separate stream from the original RTP stream.

RTX 即 RTransmission, 用于丢包重传， 它使用不同的会话(session) 或者不同的 ssrc 来传送冗余的 RTP 包

Webrtc 默认是开启 RTX (重传)，它一般采用不同的 SSRC 进行传输, RTX 包的 Payload 在  RFC4588 中有详细描述，一般 NACK 和 Bandwidth Probe 也可能走 RTX 通道。



术语
===================================

* Original packet: 源包

  an RTP packet that carries user data sent for the first time by an RTP sender.

* Original stream: 源媒体流

  the RTP stream of original packets.

* Retransmission packet: 重传包

  an RTP packet that is to be used by the receiver instead of a lost original packet.
  Such a retransmission packet is said to be associated with the original RTP packet.

* Retransmission request:

  a means by which an RTP receiver is able to request that the RTP sender should send a retransmission packet
  for a given original packet.  Usually, an RTCP NACK packet as specified in is used as retransmission request
  for lost packets.

* Retransmission stream:

  the stream of retransmission packets associated with an original stream.

* Session-multiplexing:

  scheme by which the original stream and the associated retransmission stream are sent into two different RTP sessions.

* SSRC: synchronization source.

* SSRC-multiplexing:

  scheme by which the original stream and the retransmission stream are sent in the same RTP session with different SSRC values.


Requirements and Design Rationale for a Retransmission Scheme
======================================================================

The use of retransmissions in RTP as a repair method for streaming media is appropriate in those scenarios with relaxed delay bounds and where full reliability is not a requirement.

The RTP retransmission scheme defined in this document is designed to
   fulfill the following set of requirements:

   1. It must not break general RTP and RTCP mechanisms.
   2. It must be suitable for unicast and small multicast groups.
   3. It must work with mixers and translators.
   4. It must work with all known payload types.
   5. It must not prevent the use of multiple payload types in a
      session.
   6. In order to support the largest variety of payload formats, the
      RTP receiver must be able to derive how many and which RTP packets
      were lost as a result of a gap in received RTP sequence numbers.

      This requirement is referred to as sequence number preservation.
      Without such a requirement, it would be impossible to use
      retransmission with payload formats, such as conversational text
      [9] or most audio/video streaming applications, that use the RTP
      sequence number to detect lost packets.

Retransmission Payload Format
===================================
.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                         RTP Header                            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |            OSN                |                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               |
   |                  Original RTP Packet Payload                  |
   |                                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+



重传请求
-------------------------
* NACK 可用来请求发送方重传


拥塞控制
-------------------------
拥塞导致丢包，丢包会重传，重传导致拥塞更严重，这样会生成恶性循环，所以需要考虑一个可接受的发送速率。

对于原始数据流和重传数据流的 packet rate 及 bitrate

* 总的传输速率必须控制在允许的带宽之内
* 在媒体质量要求很高的情况下，严重的拥塞需要降低原始流的发送速率之后再发送 RTX 包
* 某些环境下，比如无线网络，丢包并不是由拥塞导致的，发送 RTX 包是很用的


RTX Payload format MIME Type
-----------------------------------------
* rtx: Retransmission
* rtx-time
* apt: associated payload type 将重传的 payload type 和 RTX 的 payload type 关联起来


相关代码
=========================


* RtpConfig -> UlpfecConfig


.. code-block:: c++

  // Settings for ULPFEC forward error correction.
  // Set the payload types to '-1' to disable.
  struct UlpfecConfig {
    UlpfecConfig()
        : ulpfec_payload_type(-1),
          red_payload_type(-1),
          red_rtx_payload_type(-1) {}
    std::string ToString() const;
    bool operator==(const UlpfecConfig& other) const;

    // Payload type used for ULPFEC packets.
    int ulpfec_payload_type;

    // Payload type used for RED packets.
    int red_payload_type;

    // RTX payload type for RED payload.
    int red_rtx_payload_type;
  };


* RtpConfig -> RTX

.. code-block:: c++

  // Settings for RTP retransmission payload format, see RFC 4588 for
  // details.
  struct Rtx {
    Rtx();
    Rtx(const Rtx&);
    ~Rtx();
    std::string ToString() const;
    // SSRCs to use for the RTX streams.
    std::vector<uint32_t> ssrcs;

    // Payload type to use for the RTX stream.
    int payload_type = -1;
  } rtx;




* RtpRtcpInterface

.. code-block:: c++

  class RtpRtcpInterface : public RtcpFeedbackSenderInterface {
  public:
    //...

      struct Configuration {

        // Called when the receiver sends a loss notification.
        RtcpLossNotificationObserver* rtcp_loss_notification_observer = nullptr;

        // Called when we receive a changed estimate from the receiver of out
        // stream.
        RtcpBandwidthObserver* bandwidth_callback = nullptr;


        // If true, the RTP sender will always annotate outgoing packets with
        // MID and RID header extensions, if provided and negotiated.
        // If false, the RTP sender will stop sending MID and RID header extensions,
        // when it knows that the receiver is ready to demux based on SSRC. This is
        // done by RTCP RR acking.
        bool always_send_mid_and_rid = false;


        // If true, the RTP packet history will select RTX packets based on
        // heuristics such as send time, retransmission count etc, in order to
        // make padding potentially more useful.
        // If false, the last packet will always be picked. This may reduce CPU
        // overhead.
        bool enable_rtx_padding_prioritization = true;
      };


        // Turns on/off sending RTX (RFC 4588). The modes can be set as a combination
        // of values of the enumerator RtxMode.
        virtual void SetRtxSendStatus(int modes) = 0;

        // Returns status of sending RTX (RFC 4588). The returned value can be
        // a combination of values of the enumerator RtxMode.
        virtual int RtxSendStatus() const = 0;

        // Returns the SSRC used for RTX if set, otherwise a nullopt.
        virtual absl::optional<uint32_t> RtxSsrc() const = 0;

        // Sets the payload type to use when sending RTX packets. Note that this
        // doesn't enable RTX, only the payload type is set.
        virtual void SetRtxSendPayloadType(int payload_type,
                                          int associated_payload_type) = 0;


        // (REMB) Receiver Estimated Max Bitrate.
        // Schedules sending REMB on next and following sender/receiver reports.
        void SetRemb(int64_t bitrate_bps, std::vector<uint32_t> ssrcs) override = 0;
        // Stops sending REMB on next and following sender/receiver reports.
        void UnsetRemb() override = 0;

        // (NACK)

        // Sends NACK for the packets specified.
        // Note: This assumes the caller keeps track of timing and doesn't rely on
        // the RTP module to do this.
        virtual void SendNack(const std::vector<uint16_t>& sequence_numbers) = 0;

  }


Build RTX packet
-------------------------

.. code-block::


  std::unique_ptr<RtpPacketToSend> RTPSender::BuildRtxPacket(
      const RtpPacketToSend& packet) {
    std::unique_ptr<RtpPacketToSend> rtx_packet;

    // Add original RTP header.
    {
      MutexLock lock(&send_mutex_);
      if (!sending_media_)
        return nullptr;

      RTC_DCHECK(rtx_ssrc_);

      // Replace payload type.
      auto kv = rtx_payload_type_map_.find(packet.PayloadType());
      if (kv == rtx_payload_type_map_.end())
        return nullptr;

      rtx_packet = std::make_unique<RtpPacketToSend>(&rtp_header_extension_map_,
                                                    max_packet_size_);

      rtx_packet->SetPayloadType(kv->second);

      // Replace SSRC.
      rtx_packet->SetSsrc(*rtx_ssrc_);

      CopyHeaderAndExtensionsToRtxPacket(packet, rtx_packet.get());

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

    // Add OSN (original sequence number).
    ByteWriter<uint16_t>::WriteBigEndian(rtx_payload, packet.SequenceNumber());

    // Add original payload data.
    auto payload = packet.payload();
    memcpy(rtx_payload + kRtxHeaderSize, payload.data(), payload.size());

    // Add original additional data.
    rtx_packet->set_additional_data(packet.additional_data());

    // Copy capture time so e.g. TransmissionOffset is correctly set.
    rtx_packet->set_capture_time(packet.capture_time());

    return rtx_packet;
  }

参考资料
=========================
* RFC4588: `RTP Retransmission Payload Format`_
* RFC4585: `Extended RTP Profile for RTCP-Based Feedback`_
* `Implement RTX for WebRTC`_
* RFC2198: RED -  Redundant Audio Data


.. _Implement RTX for WebRTC: https://bugzilla.mozilla.org/show_bug.cgi?id=1164187
.. _RTP Retransmission Payload Format: https://tools.ietf.org/html/rfc4588
.. _Extended RTP Profile for RTCP-Based Feedback: https://datatracker.ietf.org/doc/html/rfc4585
