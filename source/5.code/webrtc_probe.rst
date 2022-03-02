##############################
WebRTC Probe
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Probe
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

Overview
=============

1）network available at startup
2）enable_periodic_alr_probing_
3）large drop in estimated bandwidth
4) probing results indicate channel has greater capacity.


Flow
==============

handle TransportPacketsFeedback
---------------------------------------
* GoogCcNetworkController::OnTransportPacketsFeedback

.. code-block:: c++

    NetworkControlUpdate GoogCcNetworkController::OnTransportPacketsFeedback(
    TransportPacketsFeedback report) {
    //...

    if (feedback.sent_packet.pacing_info.probe_cluster_id !=
        PacedPacketInfo::kNotAProbe) {
      probe_bitrate_estimator_->HandleProbeAndEstimateBitrate(feedback);
    }

    //... 
    // 取出上次估计的比特率，并将上次估计的比特率重置为0
    absl::optional<DataRate> probe_bitrate =
        probe_bitrate_estimator_->FetchAndResetLastEstimatedBitrate();
    // 如果探测的比特率小于估计的比特率， 重置探测的比特率
    if (ignore_probes_lower_than_network_estimate_ && probe_bitrate &&
        estimate_ && *probe_bitrate < delay_based_bwe_->last_estimate() &&
        *probe_bitrate < estimate_->link_capacity_lower) {
        probe_bitrate.reset();
    }
    if (limit_probes_lower_than_throughput_estimate_ && probe_bitrate &&
        acknowledged_bitrate) {
        // Limit the backoff to something slightly below the acknowledged
        // bitrate. ("Slightly below" because we want to drain the queues
        // if we are actually overusing.)
        // The acknowledged bitrate shouldn't normally be higher than the delay
        // based estimate, but it could happen e.g. due to packet bursts or
        // encoder overshoot. We use std::min to ensure that a probe result
        // below the current BWE never causes an increase.
        DataRate limit =
            std::min(delay_based_bwe_->last_estimate(),
                    *acknowledged_bitrate * kProbeDropThroughputFraction);
        probe_bitrate = std::max(*probe_bitrate, limit);
    }

    NetworkControlUpdate update;
    bool recovered_from_overuse = false;
    bool backoff_in_alr = false;

    DelayBasedBwe::Result result;
    result = delay_based_bwe_->IncomingPacketFeedbackVector(
        report, acknowledged_bitrate, probe_bitrate, estimate_,
        alr_start_time.has_value());

    if (result.updated) {
        if (result.probe) {
        bandwidth_estimation_->SetSendBitrate(result.target_bitrate,
                                                report.feedback_time);
        }
        // Since SetSendBitrate now resets the delay-based estimate, we have to
        // call UpdateDelayBasedEstimate after SetSendBitrate.
        bandwidth_estimation_->UpdateDelayBasedEstimate(report.feedback_time,
                                                        result.target_bitrate);
        // Update the estimate in the ProbeController, in case we want to probe.
        MaybeTriggerOnNetworkChanged(&update, report.feedback_time);
    }
    recovered_from_overuse = result.recovered_from_overuse;
    backoff_in_alr = result.backoff_in_alr;

    if (recovered_from_overuse) {
        probe_controller_->SetAlrStartTimeMs(alr_start_time);
        auto probes = probe_controller_->RequestProbe(report.feedback_time.ms());
        update.probe_cluster_configs.insert(update.probe_cluster_configs.end(),
                                            probes.begin(), probes.end());
    } else if (backoff_in_alr) {
        // If we just backed off during ALR, request a new probe.
        auto probes = probe_controller_->RequestProbe(report.feedback_time.ms());
        update.probe_cluster_configs.insert(update.probe_cluster_configs.end(),
                                            probes.begin(), probes.end());
    }

    // No valid RTT could be because send-side BWE isn't used, in which case
    // we don't try to limit the outstanding packets.
    if (rate_control_settings_.UseCongestionWindow() &&
        max_feedback_rtt.IsFinite()) {
        UpdateCongestionWindowSize();
    }
    if (congestion_window_pushback_controller_ && current_data_window_) {
        congestion_window_pushback_controller_->SetDataWindow(
            *current_data_window_);
    } else {
        update.congestion_window = current_data_window_;
    }

    return update;
    }

structures
================

.. code-block:: c++

    struct SentPacket {
        Timestamp send_time = Timestamp::PlusInfinity();
        // Size of packet with overhead up to IP layer.
        DataSize size = DataSize::Zero();
        // Size of preceeding packets that are not part of feedback.
        DataSize prior_unacked_data = DataSize::Zero();
        // Probe cluster id and parameters including bitrate, number of packets and
        // number of bytes.
        PacedPacketInfo pacing_info;
        // True if the packet is an audio packet, false for video, padding, RTX etc.
        bool audio = false;
        // Transport independent sequence number, any tracked packet should have a
        // sequence number that is unique over the whole call and increasing by 1 for
        // each packet.
        int64_t sequence_number;
        // Tracked data in flight when the packet was sent, excluding unacked data.
        DataSize data_in_flight = DataSize::Zero();
    };

    struct PacedPacketInfo {
        PacedPacketInfo();
        PacedPacketInfo(int probe_cluster_id,
                        int probe_cluster_min_probes,
                        int probe_cluster_min_bytes);

        bool operator==(const PacedPacketInfo& rhs) const;

        // TODO(srte): Move probing info to a separate, optional struct.
        static constexpr int kNotAProbe = -1;
        int send_bitrate_bps = -1;
        int probe_cluster_id = kNotAProbe;
        int probe_cluster_min_probes = -1;
        int probe_cluster_min_bytes = -1;
        int probe_cluster_bytes_sent = 0;
    };


    struct PacketResult {
        class ReceiveTimeOrder {
        public:
            bool operator()(const PacketResult& lhs, const PacketResult& rhs);
        };

        PacketResult();
        PacketResult(const PacketResult&);
        ~PacketResult();

        inline bool IsReceived() const { return !receive_time.IsPlusInfinity(); }

        SentPacket sent_packet;
        Timestamp receive_time = Timestamp::PlusInfinity();
    };

    struct AggregatedCluster {
        int num_probes = 0;
        Timestamp first_send = Timestamp::PlusInfinity();
        Timestamp last_send = Timestamp::MinusInfinity();
        Timestamp first_receive = Timestamp::PlusInfinity();
        Timestamp last_receive = Timestamp::MinusInfinity();
        DataSize size_last_send = DataSize::Zero();
        DataSize size_first_receive = DataSize::Zero();
        DataSize size_total = DataSize::Zero();
   };


HandleProbeAndEstimateBitrate
---------------------------------------

* HandleProbeAndEstimateBitrate

.. code-block:: C++

    absl::optional<DataRate> ProbeBitrateEstimator::HandleProbeAndEstimateBitrate
    (const PacketResult& packet_feedback) {
        //...

        DataSize send_size = cluster->size_total - cluster->size_last_send;
        DataRate send_rate = send_size / send_interval;

        DataSize receive_size = cluster->size_total - cluster->size_first_receive;
        DataRate receive_rate = receive_size / receive_interval;

        DataRate res = std::min(send_rate, receive_rate);
        //...
        estimated_data_rate_ = res;
        return estimated_data_rate_;
    }