####################
WebRTC Demux
####################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Demux
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============
RFC 8843 - Negotiating Media Multiplexing Using the Session Description Protocol(SDP) 中说明了如何通过 SDP 来协商媒体流的多路复用与分解

WebRTC 为多路分解一个 Transport 中的多路流，需要下面这些标识进行分解, 分解的详细规则稍后详述

* mid
* rsid
* ssrcs
* payload types


If rsid is not empty string, will match packets with this as their RTP stream ID or repaired RTP stream ID.

Note that if both MID and RSID are specified, this will only match packets that have both specified
(either through RTP header extensions, SSRC latching or RTCP).

.. code-block:: cpp

    class RtpDemuxerCriteria
    {
        //...
        const std::string mid_;
        const std::string rsid_;
        flat_set<uint32_t> ssrcs_;
        flat_set<uint8_t> payload_types_;
    }



RtpDemuxer
================

当一个 RTP 收到时，RtpDemuxer 会依照如下原则进行处理

1. If the packet contains the MID header extension, and no sink has been
    added with that MID as a criteria, the packet is not routed.

2. If the packet has the MID header extension, but no RSID or RRID extension,
   and the MID is bound to a sink, then bind its SSRC to the same sink and
   forward the packet to that sink. Note that rebinding to the same sink is
   not an error. (Later packets with that SSRC would therefore be forwarded
   to the same sink, whether they have the MID header extension or not.)

3. If the packet has the MID header extension and either the RSID or RRID
   extension, and the MID, RSID (or RRID) pair is bound to a sink, then bind
   its SSRC to the same sink and forward the packet to that sink. Later
   packets with that SSRC will be forwarded to the same sink.

4. If the packet has the RSID or RRID header extension, but no MID extension,
   and the RSID or RRID is bound to an RSID sink, then bind its SSRC to the
   same sink and forward the packet to that sink. Later packets with that
   SSRC will be forwarded to the same sink.

5. If the packet's SSRC is bound to an SSRC through a previous call to
    AddSink, then forward the packet to that sink. Note that the RtpDemuxer
    will not verify the payload type even if included in the sink's criteria.
    The sink is expected to do the check in its handler.

6. If the packet's payload type is bound to exactly one payload type sink
   through an earlier call to AddSink, then forward the packet to that sink.

7. Otherwise, the packet is not routed.

In summary, the routing algorithm will always try to first match MID and RSID
(including through SSRC binding), match SSRC directly as needed, and use
payload types only if all else fails.


main methods
--------------------
根据 RtpDemuxerCriteria, SSRC 或者 rsid 来添加 RTP 包对应的回调 RtpPacketSinkInterface

分解到的 sink 在下面的这些 map 中之一


Map each sink by its component attributes to facilitate quick lookups.

Payload Type mapping is a multimap because if two sinks register for the same payload type, both AddSinks succeed but we must know not to demux on
that attribute since it is ambiguous.

Note:

Mappings are only modified by AddSink/RemoveSink (except for SSRC mapping which receives all MID, payload type,
or RSID to SSRC bindings discovered when demuxing packets).

.. code-block:: cpp

    flat_map<std::string, RtpPacketSinkInterface*> sink_by_mid_;
    flat_map<uint32_t, RtpPacketSinkInterface*> sink_by_ssrc_;
    std::multimap<uint8_t, RtpPacketSinkInterface*> sinks_by_pt_;
    flat_map<std::pair<std::string, std::string>, RtpPacketSinkInterface*> sink_by_mid_and_rsid_;
    flat_map<std::string, RtpPacketSinkInterface*> sink_by_rsid_;


* AddSink

.. code-block:: cpp

    // Registers a sink that will be notified when RTP packets match its given
    // criteria according to the algorithm described in the class description.
    // Returns true if the sink was successfully added.
    // Returns false in the following situations:
    // - Only MID is specified and the MID is already registered.
    // - Only RSID is specified and the RSID is already registered.
    // - Both MID and RSID is specified and the (MID, RSID) pair is already
    //   registered.
    // - Any of the criteria SSRCs are already registered.
    // If false is returned, no changes are made to the demuxer state.
    bool AddSink(const RtpDemuxerCriteria& criteria, RtpPacketSinkInterface* sink);

    // Registers a sink. Multiple SSRCs may be mapped to the same sink, but
    // each SSRC may only be mapped to one sink. The return value reports
    // whether the association has been recorded or rejected. Rejection may occur
    // if the SSRC has already been associated with a sink. The previously added
    // sink is *not* forgotten.
    bool AddSink(uint32_t ssrc, RtpPacketSinkInterface* sink);

    // Registers a sink's association to an RSID. Only one sink may be associated
    // with a given RSID. Null pointer is not allowed.
    void AddSink(absl::string_view rsid, RtpPacketSinkInterface* sink);


这段代码解释了如何根据 RTP 头及扩展来映射到相应的流中

.. code-block:: cpp

    if (!criteria.mid().empty()) {
        if (criteria.rsid().empty()) {
            sink_by_mid_.emplace(criteria.mid(), sink);
        } else {
        sink_by_mid_and_rsid_.emplace(
            std::make_pair(criteria.mid(), criteria.rsid()), sink);
        }
    } else {
        if (!criteria.rsid().empty()) {
            sink_by_rsid_.emplace(criteria.rsid(), sink);
        }
    }

Snippets
====================================



.. code-block:: cpp

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