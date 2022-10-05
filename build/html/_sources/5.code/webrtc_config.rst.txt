#######################
WebRTC Configuration
#######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Configuration
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents:: Contents
   :local:


RTP Config
========================

.. code-block:: cpp

    struct RtpConfig {
    RtpConfig();
    RtpConfig(const RtpConfig&);
    ~RtpConfig();
    std::string ToString() const;

    std::vector<uint32_t> ssrcs;

    // The Rtp Stream Ids (aka RIDs) to send in the RID RTP header extension
    // if the extension is included in the list of extensions.
    // If rids are specified, they should correspond to the `ssrcs` vector.
    // This means that:
    // 1. rids.size() == 0 || rids.size() == ssrcs.size().
    // 2. If rids is not empty, then `rids[i]` should use `ssrcs[i]`.
    std::vector<std::string> rids;

    // The value to send in the MID RTP header extension if the extension is
    // included in the list of extensions.
    std::string mid;

    // See RtcpMode for description.
    RtcpMode rtcp_mode = RtcpMode::kCompound;

    // Max RTP packet size delivered to send transport from VideoEngine.
    size_t max_packet_size = kDefaultMaxPacketSize;

    // Corresponds to the SDP attribute extmap-allow-mixed.
    bool extmap_allow_mixed = false;

    // RTP header extensions to use for this send stream.
    std::vector<RtpExtension> extensions;

    // TODO(nisse): For now, these are fixed, but we'd like to support
    // changing codec without recreating the VideoSendStream. Then these
    // fields must be removed, and association between payload type and codec
    // must move above the per-stream level. Ownership could be with
    // RtpTransportControllerSend, with a reference from RtpVideoSender, where
    // the latter would be responsible for mapping the codec type of encoded
    // images to the right payload type.
    std::string payload_name;
    int payload_type = -1;
    // Payload should be packetized using raw packetizer (payload header will
    // not be added, additional meta data is expected to be present in generic
    // frame descriptor RTP header extension).
    bool raw_payload = false;

    // See LntfConfig for description.
    LntfConfig lntf;

    // See NackConfig for description.
    NackConfig nack;

    // See UlpfecConfig for description.
    UlpfecConfig ulpfec;

    struct Flexfec {
        Flexfec();
        Flexfec(const Flexfec&);
        ~Flexfec();
        // Payload type of FlexFEC. Set to -1 to disable sending FlexFEC.
        int payload_type = -1;

        // SSRC of FlexFEC stream.
        uint32_t ssrc = 0;

        // Vector containing a single element, corresponding to the SSRC of the
        // media stream being protected by this FlexFEC stream.
        // The vector MUST have size 1.
        //
        // TODO(brandtr): Update comment above when we support
        // multistream protection.
        std::vector<uint32_t> protected_media_ssrcs;
    } flexfec;

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

    // RTCP CNAME, see RFC 3550.
    std::string c_name;

    bool IsMediaSsrc(uint32_t ssrc) const;
    bool IsRtxSsrc(uint32_t ssrc) const;
    bool IsFlexfecSsrc(uint32_t ssrc) const;
    absl::optional<uint32_t> GetRtxSsrcAssociatedWithMediaSsrc(
        uint32_t media_ssrc) const;
    uint32_t GetMediaSsrcAssociatedWithRtxSsrc(uint32_t rtx_ssrc) const;
    uint32_t GetMediaSsrcAssociatedWithFlexfecSsrc(uint32_t flexfec_ssrc) const;
    absl::optional<std::string> GetRidForSsrc(uint32_t ssrc) const;
    };