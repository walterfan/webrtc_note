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

* RtpDemuxerCriteria

.. code-block:: cpp

    class RtpDemuxerCriteria {
        const std::string mid_;
        const std::string rsid_;
        flat_set<uint32_t> ssrcs_;
        flat_set<uint8_t> payload_types_;
    }

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