##############################
WebRTC Bandwidth Probe
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Bandwidth Probe
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============

在会话刚建立时需要确定远端的一个初始带宽，congestion_controller 通过 

* ProbeController 控制何时进行启动探测
* ProbeBitrateEstimator 基于探测包进行带宽估算

带宽探测的基本思路是以 cluster 为单位按照一定的速度来发送RTP包，然后在收到RTP包的反馈消息时计算发送速度和接收端的接收速度，取这两个速度的最小值为远端带宽速度。

一次探测为一个cluster, 在同一个cluster内RTP包的cluster_id都相同。ProbeController类用来控制探测行为，例如设定开始探测比特率、分配cluster_id等。

用于探测带宽的RTP包其实就是音视频的RTP包，如果没有发送过音视频RTP包那么探测行为不会发生。音视频编码出生的RTP数量有限，在探测带宽时为满足以一定的速度发送数据的要求，很可能会对已经发送过的RTP包进行填充发送。

和所有的RTP、RTCP包的发送一样，探测包的发送也是通过pacing模块来进行的，所有发送的RTP包都会被保存到congestion_controller模块

在收到feedback消息时，如果此RTP包是用来探测带宽的，那么就会调用到ProbeBitrateEstimator::HandleProbeAndEstimateBitrate函数进行处理。

会话刚建立时会探测两次，以及编码器配置改变时会探测两次，一个cluster为一次探测，

会话刚建立时进行两次探测的bps分别为900000、1800000，一般连续的两次探测，第二次的bps为第一次的两倍。

触发探测的条件
----------------------------------------
1）network available at startup
2）enable periodic alr probing
3）large drop in estimated bandwidth
4) probing results indicate channel has greater capacity.


Flow
==============

handle TransportPacketsFeedback
---------------------------------------
* GoogCcNetworkController::OnTransportPacketsFeedback




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