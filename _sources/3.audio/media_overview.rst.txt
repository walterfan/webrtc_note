######################
WebRTC 媒体概论
######################

.. contents::
    :local:


Overview
========================
* Audio Encode/decode(Opus, g.711), mixing, ASA, ASN, 3A(AGC, AEC, ANS), BNR, ASR, TTS. etc.
* Video Encode/decode(H264, AV1), compose/annotation, watermarking, virtual background, video stream pub-sub
* Sharing : slide audio, high frame
* Adaptive Jitter buffer
* Smooth sending(Pacer)
* Recording
* Device manage: audio device(mic, speaker), video device(camera, monitor)
* Web Assembly, WebCodecs, Insertable stream support

RTP Extension
---------------------
* abs-send-time
* abs-capture-time
* mid
* rid
* rrid
* transport-wide-cc-01
* transport-wide-cc-02
* color-space
* playout-delay
* video-content-type
* video-timing
* inband-cn
* video-layers-allocation00
* RTCP Extensions
* NACK, PLI, FIR
* REMB
* Transport CC
* FEC: ULP/FLEX FEC
* RTX

refer to RTPExtensionType, RTCPPacketType, KeyFrameReqMethod and RtxMode

.. code-block::

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

    enum class KeyFrameReqMethod : uint8_t {
        kNone,     // Don't request keyframes.
        kPliRtcp,  // Request keyframes through Picture Loss Indication.
        kFirRtcp   // Request keyframes through Full Intra-frame Request.
    };

    enum RtxMode {
        kRtxOff = 0x0,
        kRtxRetransmitted = 0x1,     // Only send retransmissions over RTX.
        kRtxRedundantPayloads = 0x2  // Preventively send redundant payloads
                                    // instead of padding.
    };

* refer to https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/rtp_rtcp/include/rtp_rtcp_defines.h




Protocols
==================
* [RFC3264] Rosenberg, J. and H. Schulzrinne, "An Offer/Answer Model with Session Description Protocol (SDP)", RFC 3264, DOI 10.17487/RFC3264, June 2002, <https://www.rfc-editor.org/info/rfc3264>.
* [RFC3550] Schulzrinne, H., Casner, S., Frederick, R., and V. Jacobson, "RTP: A Transport Protocol for Real-Time Applications", STD 64, RFC 3550, DOI 10.17487/RFC3550, July 2003, <https://www.rfc-editor.org/info/rfc3550>.
* [RFC3711] Baugher, M., McGrew, D., Naslund, M., Carrara, E., and K. Norrman, "The Secure Real-time Transport Protocol (SRTP)", RFC 3711, DOI 10.17487/RFC3711, March 2004, <https://www.rfc-editor.org/info/rfc3711>.
* [RFC7742] Roach, A.B., "WebRTC Video Processing and Codec Requirements", RFC 7742, DOI 10.17487/RFC7742, March 2016, <https://www.rfc-editor.org/info/rfc7742>.
* [RFC7874] Valin, JM. and C. Bran, "WebRTC Audio Codec and Processing Requirements", RFC 7874, DOI 10.17487/RFC7874, May 2016, <https://www.rfc-editor.org/info/rfc7874>.
* [RFC8174] Leiba, B., "Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words", BCP 14, RFC 8174, DOI 10.17487/RFC8174, May 2017, <https://www.rfc-editor.org/info/rfc8174>.
* [RFC8445] Keranen, A., Holmberg, C., and J. Rosenberg, "Interactive Connectivity Establishment (ICE): A Protocol for Network Address Translator (NAT) Traversal", RFC 8445, DOI 10.17487/RFC8445, July 2018, <https://www.rfc-editor.org/info/rfc8445>.
* [RFC8826] Rescorla, E., "Security Considerations for WebRTC", RFC 8826, DOI 10.17487/RFC8826, January 2021, <https://www.rfc-editor.org/info/rfc8826>.
* [RFC8827] Rescorla, E., "WebRTC Security Architecture", RFC 8827, DOI 10.17487/RFC8827, January 2021, <https://www.rfc-editor.org/info/rfc8827>.
* [RFC8829] Uberti, J., Jennings, C., and E. Rescorla, Ed., "JavaScript Session Establishment Protocol (JSEP)", RFC 8829, DOI 10.17487/RFC8829, January 2021, <https://www.rfc-editor.org/info/rfc8829>.
* [RFC8831] Jesup, R., Loreto, S., and M. Tüxen, "WebRTC Data Channels", RFC 8831, DOI 10.17487/RFC8831, January 2021, <https://www.rfc-editor.org/info/rfc8831>.
* [RFC8832] Jesup, R., Loreto, S., and M. Tüxen, "WebRTC Data Channel Establishment Protocol", RFC 8832, DOI 10.17487/RFC8832, January 2021, <https://www.rfc-editor.org/info/rfc8832>.
* [RFC8834] Perkins, C., Westerlund, M., and J. Ott, "Media Transport and Use of RTP in WebRTC", RFC 8834, DOI 10.17487/RFC8834, January 2021, <https://www.rfc-editor.org/info/rfc8834>.
* [RFC8835] Alvestrand, H., "Transports for WebRTC", RFC 8835, DOI 10.17487/RFC8835, January 2021, <https://www.rfc-editor.org/info/rfc8835>.
* [W3C.WD-mediacapture-streams] Jennings, C., Aboba, B., Bruaroey, J-I., and H. Boström, "Media Capture and Streams", W3C Candidate Recommendation, <https://www.w3.org/TR/mediacapture-streams/>.
* [W3C.WD-webrtc] Jennings, C., Boström, H., and J-I. Bruaroey, "WebRTC 1.0: Real-time Communication Between Browsers", W3C Proposed Recommendation, <https://www.w3.org/TR/webrtc/>. 12.2. Informative References
* [HTML5] WHATWG, "HTML - Living Standard", January 2021, <https://html.spec.whatwg.org/>.
* [RFC3261] Rosenberg, J., Schulzrinne, H., Camarillo, G., Johnston, A., Peterson, J., Sparks, R., Handley, M., and E. Schooler, "SIP: Session Initiation Protocol", RFC 3261, DOI 10.17487/RFC3261, June 2002, <https://www.rfc-editor.org/info/rfc3261>.
* [RFC3361] Schulzrinne, H., "Dynamic Host Configuration Protocol (DHCP-for-IPv4) Option for Session Initiation Protocol (SIP) Servers", RFC 3361, DOI 10.17487/RFC3361, August 2002, <https://www.rfc-editor.org/info/rfc3361>.
* [RFC3935] Alvestrand, H., "A Mission Statement for the IETF", BCP 95, RFC 3935, DOI 10.17487/RFC3935, October 2004, <https://www.rfc-editor.org/info/rfc3935>.
* [RFC5245] Rosenberg, J., "Interactive Connectivity Establishment (ICE): A Protocol for Network Address Translator (NAT) Traversal for Offer/Answer Protocols", RFC 5245, DOI 10.17487/RFC5245, April 2010, <https://www.rfc-editor.org/info/rfc5245>.
* [RFC5761] Perkins, C. and M. Westerlund, "Multiplexing RTP Data and Control Packets on a Single Port", RFC 5761, DOI 10.17487/RFC5761, April 2010, <https://www.rfc-editor.org/info/rfc5761>.
* [RFC6120] Saint-Andre, P., "Extensible Messaging and Presence Protocol (XMPP): Core", RFC 6120, DOI 10.17487/RFC6120, March 2011, <https://www.rfc-editor.org/info/rfc6120>.
* [RFC6501] Novo, O., Camarillo, G., Morgan, D., and J. Urpalainen, "Conference Information Data Model for Centralized Conferencing (XCON)", RFC 6501, DOI 10.17487/RFC6501, March 2012, <https://www.rfc-editor.org/info/rfc6501>.
* [RFC7478] Holmberg, C., Hakansson, S., and G. Eriksson, "Web Real- Time Communication Use Cases and Requirements", RFC 7478, DOI 10.17487/RFC7478, March 2015, <https://www.rfc-editor.org/info/rfc7478>.
* [RFC8155] Patil, P., Reddy, T., and D. Wing, "Traversal Using Relays around NAT (TURN) Server Auto Discovery", RFC 8155, DOI 10.17487/RFC8155, April 2017, <https://www.rfc-editor.org/info/rfc8155>. [RFC8837] Jones, P., Dhesikan, S., Jennings, C., and D. Druta, "Differentiated Services Code Point (DSCP) Packet Markings for WebRTC QoS", RFC 8837, DOI 10.17487/RFC8837, January 2021, <https://www.rfc-editor.org/info/rfc8837>.
* [RFC8838] Ivov, E., Uberti, J., and P. Saint-Andre, "Trickle ICE: Incremental Provisioning of Candidates for the Interactive Connectivity Establishment (ICE) Protocol", RFC 8838, DOI 10.17487/RFC8838, January 2021, <https://www.rfc-editor.org/info/rfc8838>.
* [RFC8843] Holmberg, C., Alvestrand, H., and C. Jennings, "Negotiating Media Multiplexing Using the Session Description Protocol (SDP)", RFC 8843, DOI 10.17487/RFC8843, January 2021, <https://www.rfc-editor.org/info/rfc8843>.
* [WebRTC-Gateways] Alvestrand, H. and U. Rauschenbach, "WebRTC Gateways", Work in Progress, Internet-Draft, draft-ietf-rtcweb- gateways-02, 21 January 2016, <https://tools.ietf.org/html/draft-ietf-rtcweb-gateways- 02>.