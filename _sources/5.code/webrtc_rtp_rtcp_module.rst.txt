##############################
WebRTC RTP RTCP module
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC RTP RTCP module
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
======================================

rtp_rtcp 是 libwebrtc 的一个核心模块

.. code-block::

    constexpr TimeDelta RTCP_SEND_BEFORE_KEY_FRAME = TimeDelta::Millis(100);
    constexpr int RTCP_MAX_REPORT_BLOCKS = 31;  // RFC 3550 page 37


RTCP Mode
--------------------------------------

.. code-block::

    // RTCP mode to use. Compound mode is described by RFC 4585 and reduced-size
    // RTCP mode is described by RFC 5506.
    enum class RtcpMode { kOff, kCompound, kReducedSize };


RTX Mode

.. code-block::

    enum RtxMode {
    kRtxOff = 0x0,
    kRtxRetransmitted = 0x1,     // Only send retransmissions over RTX.
    kRtxRedundantPayloads = 0x2  // Preventively send redundant payloads
                                // instead of padding.
    };


WebRTC 中计算的汇报间隔
======================================


.. code-block::

    void RTCPSender::PrepareReport(const FeedbackState& feedback_state) {
        bool generate_report;
        if (IsFlagPresent(kRtcpSr) || IsFlagPresent(kRtcpRr)) {
            // Report type already explicitly set, don't automatically populate.
            generate_report = true;
            RTC_DCHECK(ConsumeFlag(kRtcpReport) == false);
        } else {
            generate_report =
                (ConsumeFlag(kRtcpReport) && method_ == RtcpMode::kReducedSize) ||
                method_ == RtcpMode::kCompound;
            if (generate_report)
            SetFlag(sending_ ? kRtcpSr : kRtcpRr, true);
        }

        if (IsFlagPresent(kRtcpSr) || (IsFlagPresent(kRtcpRr) && !cname_.empty()))
            SetFlag(kRtcpSdes, true);

        if (generate_report) {
            if ((!sending_ && xr_send_receiver_reference_time_enabled_) ||
                !feedback_state.last_xr_rtis.empty() ||
                send_video_bitrate_allocation_) {
                SetFlag(kRtcpAnyExtendedReports, true);
            }

            // generate next time to send an RTCP report
            TimeDelta min_interval = report_interval_;

            if (!audio_ && sending_) {
                // Calculate bandwidth for video; 360 / send bandwidth in kbit/s.
                int send_bitrate_kbit = feedback_state.send_bitrate / 1000;
                if (send_bitrate_kbit != 0) {
                    min_interval = std::min(TimeDelta::Millis(360000 / send_bitrate_kbit),
                                            report_interval_);
                }
            }

            // The interval between RTCP packets is varied randomly over the
            // range [1/2,3/2] times the calculated interval.
            int min_interval_int = rtc::dchecked_cast<int>(min_interval.ms());
            TimeDelta time_to_next = TimeDelta::Millis(
                random_.Rand(min_interval_int * 1 / 2, min_interval_int * 3 / 2));

            RTC_DCHECK(!time_to_next.IsZero());
            SetNextRtcpSendEvaluationDuration(time_to_next);

            // RtcpSender expected to be used for sending either just sender reports
            // or just receiver reports.
            RTC_DCHECK(!(IsFlagPresent(kRtcpSr) && IsFlagPresent(kRtcpRr)));
        }
    }


WebRTC中支持的 RTP 扩展头
======================================
.. code-block::

    // This enum must not have any gaps, i.e., all integers between
    // kRtpExtensionNone and kRtpExtensionNumberOfExtensions must be valid enum
    // entries.
    enum RTPExtensionType : int {
        kRtpExtensionNone,
        kRtpExtensionTransmissionTimeOffset,
        kRtpExtensionAudioLevel,
        kRtpExtensionCsrcAudioLevel,
        kRtpExtensionInbandComfortNoise,
        kRtpExtensionAbsoluteSendTime,
        kRtpExtensionAbsoluteCaptureTime,
        kRtpExtensionVideoRotation,
        kRtpExtensionTransportSequenceNumber,
        kRtpExtensionTransportSequenceNumber02,
        kRtpExtensionPlayoutDelay,
        kRtpExtensionVideoContentType,
        kRtpExtensionVideoLayersAllocation,
        kRtpExtensionVideoTiming,
        kRtpExtensionRtpStreamId,
        kRtpExtensionRepairedRtpStreamId,
        kRtpExtensionMid,
        kRtpExtensionGenericFrameDescriptor00,
        kRtpExtensionGenericFrameDescriptor = kRtpExtensionGenericFrameDescriptor00,
        kRtpExtensionGenericFrameDescriptor02,
        kRtpExtensionColorSpace,
        kRtpExtensionVideoFrameTrackingId,
        kRtpExtensionNumberOfExtensions  // Must be the last entity in the enum.
    };


RTP 包中的媒体内容类型
---------------------------------------

.. code-block::

    // NOTE! `kNumMediaTypes` must be kept in sync with RtpPacketMediaType!
    static constexpr size_t kNumMediaTypes = 5;
    enum class RtpPacketMediaType : size_t {
        kAudio,                         // Audio media packets.
        kVideo,                         // Video media packets.
        kRetransmission,                // Retransmisions, sent as response to NACK.
        kForwardErrorCorrection,        // FEC packets.
        kPadding = kNumMediaTypes - 1,  // RTX or plain padding sent to maintain BWE.
        // Again, don't forget to udate `kNumMediaTypes` if you add another value!
    };

RTCP 包
======================================

RTCP 包类型
---------------------------------------

.. code-block::

    enum RTCPPacketType : uint32_t {
        kRtcpReport = 0x0001,
        kRtcpSr = 0x0002,
        kRtcpRr = 0x0004,
        kRtcpSdes = 0x0008,
        kRtcpBye = 0x0010,
        kRtcpPli = 0x0020,
        kRtcpNack = 0x0040,
        kRtcpFir = 0x0080,
        kRtcpTmmbr = 0x0100,
        kRtcpTmmbn = 0x0200,
        kRtcpSrReq = 0x0400,
        kRtcpLossNotification = 0x2000,
        kRtcpRemb = 0x10000,
        kRtcpTransmissionTimeOffset = 0x20000,
        kRtcpXrReceiverReferenceTime = 0x40000,
        kRtcpXrDlrrReportBlock = 0x80000,
        kRtcpTransportFeedback = 0x100000,
        kRtcpXrTargetBitrate = 0x200000
    };


SenderReportStats
-------------------------------------------------


.. code-block::

    // Stats for RTCP sender reports (SR) for a specific SSRC.
    // Refer to https://tools.ietf.org/html/rfc3550#section-6.4.1.
    struct SenderReportStats {
        // Arrival NTP timestamp for the last received RTCP SR.
        NtpTime last_arrival_timestamp;
        // Received (a.k.a., remote) NTP timestamp for the last received RTCP SR.
        NtpTime last_remote_timestamp;
        // Total number of RTP data packets transmitted by the sender since starting
        // transmission up until the time this SR packet was generated. The count
        // should be reset if the sender changes its SSRC identifier.
        uint32_t packets_sent;
        // Total number of payload octets (i.e., not including header or padding)
        // transmitted in RTP data packets by the sender since starting transmission
        // up until the time this SR packet was generated. The count should be reset
        // if the sender changes its SSRC identifier.
        uint64_t bytes_sent;
        // Total number of RTCP SR blocks received.
        // https://www.w3.org/TR/webrtc-stats/#dom-rtcremoteoutboundrtpstreamstats-reportssent.
        uint64_t reports_count;
    };


RTCP sender
----------------------------------------------------


* configuration

.. code-block::

    struct Configuration {
        // TODO(bugs.webrtc.org/11581): Remove this temporary conversion utility
        // once rtc_rtcp_impl.cc/h are gone.
        static Configuration FromRtpRtcpConfiguration(
            const RtpRtcpInterface::Configuration& config);

        // True for a audio version of the RTP/RTCP module object false will create
        // a video version.
        bool audio = false;
        // SSRCs for media and retransmission, respectively.
        // FlexFec SSRC is fetched from `flexfec_sender`.
        uint32_t local_media_ssrc = 0;
        // The clock to use to read time. If nullptr then system clock will be used.
        Clock* clock = nullptr;
        // Transport object that will be called when packets are ready to be sent
        // out on the network.
        Transport* outgoing_transport = nullptr;
        // Estimate RTT as non-sender as described in
        // https://tools.ietf.org/html/rfc3611#section-4.4 and #section-4.5
        bool non_sender_rtt_measurement = false;
        // Optional callback which, if specified, is used by RTCPSender to schedule
        // the next time to evaluate if RTCP should be sent by means of
        // TimeToSendRTCPReport/SendRTCP.
        // The RTCPSender client still needs to call TimeToSendRTCPReport/SendRTCP
        // to actually get RTCP sent.
        //
        // Note: It's recommended to use the callback to ensure program design that
        // doesn't use polling.
        // TODO(bugs.webrtc.org/11581): Make mandatory once downstream consumers
        // have migrated to the callback solution.
        std::function<void(TimeDelta)> schedule_next_rtcp_send_evaluation_function;

        RtcEventLog* event_log = nullptr;
        absl::optional<TimeDelta> rtcp_report_interval;
        ReceiveStatisticsProvider* receive_statistics = nullptr;
        RtcpPacketTypeCounterObserver* rtcp_packet_type_counter_observer = nullptr;
    };