##############################
WebRTC NACK code
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC REMB
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
======================================



snippets
======================================

.. code-block::

    int NackRequester::OnReceivedPacket(uint16_t seq_num,
                                    bool is_keyframe,
                                    bool is_recovered) {
        RTC_DCHECK_RUN_ON(worker_thread_);
        // TODO(philipel): When the packet includes information whether it is
        //                 retransmitted or not, use that value instead. For
        //                 now set it to true, which will cause the reordering
        //                 statistics to never be updated.
        bool is_retransmitted = true;

        if (!initialized_) {
            newest_seq_num_ = seq_num;
            if (is_keyframe)
            keyframe_list_.insert(seq_num);
            initialized_ = true;
            return 0;
        }

        // Since the `newest_seq_num_` is a packet we have actually received we know
        // that packet has never been Nacked.
        if (seq_num == newest_seq_num_)
            return 0;

        if (AheadOf(newest_seq_num_, seq_num)) {
            // An out of order packet has been received.
            auto nack_list_it = nack_list_.find(seq_num);
            int nacks_sent_for_packet = 0;
            if (nack_list_it != nack_list_.end()) {
            nacks_sent_for_packet = nack_list_it->second.retries;
            nack_list_.erase(nack_list_it);
            }
            if (!is_retransmitted)
            UpdateReorderingStatistics(seq_num);
            return nacks_sent_for_packet;
        }

        // Keep track of new keyframes.
        if (is_keyframe)
            keyframe_list_.insert(seq_num);

        // And remove old ones so we don't accumulate keyframes.
        auto it = keyframe_list_.lower_bound(seq_num - kMaxPacketAge);
        if (it != keyframe_list_.begin())
            keyframe_list_.erase(keyframe_list_.begin(), it);

        if (is_recovered) {
            recovered_list_.insert(seq_num);

            // Remove old ones so we don't accumulate recovered packets.
            auto it = recovered_list_.lower_bound(seq_num - kMaxPacketAge);
            if (it != recovered_list_.begin())
            recovered_list_.erase(recovered_list_.begin(), it);

            // Do not send nack for packets recovered by FEC or RTX.
            return 0;
        }

        AddPacketsToNack(newest_seq_num_ + 1, seq_num);
        newest_seq_num_ = seq_num;

        // Are there any nacks that are waiting for this seq_num.
        std::vector<uint16_t> nack_batch = GetNackBatch(kSeqNumOnly);
        if (!nack_batch.empty()) {
            // This batch of NACKs is triggered externally; the initiator can
            // batch them with other feedback messages.
            nack_sender_->SendNack(nack_batch, /*buffering_allowed=*/true);
        }

        return 0;
    }