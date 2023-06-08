############################################################
WebRTC Loss based Bandwidth Estimation
############################################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Probe Controller
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
======================================



classes
======================================
我们需要考虑的因素很多, 什么时候增加/减小带宽, 增加/减小多少, 调整的频率, 调整的幅度都需要仔细考量.

输入因素:

1. 发送的比特率 sendBitrate
2. 请求的比特率 requestBitrate
3. 丢包率: packetLossRatio = (sendBitrate - receiveBitrate)/sendBitrate
4. 延迟: RTT 及 QueueDelay 排队延迟
5. 当前状态 overuse, underuse or normal 以及持续了多少时间
6. 之前状态, 以及切换到当前状态的时间
7. 上次调整的行为
8. 上次调整的时间





配置类

.. code-block::


   struct LossBasedControlConfig {
      explicit LossBasedControlConfig(const FieldTrialsView* key_value_config);
      LossBasedControlConfig(const LossBasedControlConfig&);
      LossBasedControlConfig& operator=(const LossBasedControlConfig&) = default;
      ~LossBasedControlConfig();
      bool enabled;
      FieldTrialParameter<double> min_increase_factor;
      FieldTrialParameter<double> max_increase_factor;
      FieldTrialParameter<TimeDelta> increase_low_rtt;
      FieldTrialParameter<TimeDelta> increase_high_rtt;
      FieldTrialParameter<double> decrease_factor;
      FieldTrialParameter<TimeDelta> loss_window;
      FieldTrialParameter<TimeDelta> loss_max_window;
      FieldTrialParameter<TimeDelta> acknowledged_rate_max_window;
      FieldTrialParameter<DataRate> increase_offset;
      FieldTrialParameter<DataRate> loss_bandwidth_balance_increase;
      FieldTrialParameter<DataRate> loss_bandwidth_balance_decrease;
      FieldTrialParameter<DataRate> loss_bandwidth_balance_reset;
      FieldTrialParameter<double> loss_bandwidth_balance_exponent;
      FieldTrialParameter<bool> allow_resets;
      FieldTrialParameter<TimeDelta> decrease_interval;
      FieldTrialParameter<TimeDelta> loss_report_timeout;
   };

* 核心类


.. code-block::

   // Estimates an upper BWE limit based on loss.
   // It requires knowledge about lost packets and acknowledged bitrate.
   // Ie, this class require transport feedback.
   class LossBasedBandwidthEstimation {
      public:
         explicit LossBasedBandwidthEstimation(
               const FieldTrialsView* key_value_config);
         // Returns the new estimate.
         DataRate Update(Timestamp at_time,
                           DataRate min_bitrate,
                           DataRate wanted_bitrate,
                           TimeDelta last_round_trip_time);
         void UpdateAcknowledgedBitrate(DataRate acknowledged_bitrate,
                                          Timestamp at_time);
         void Initialize(DataRate bitrate);
         bool Enabled() const { return config_.enabled; }
         // Returns true if LossBasedBandwidthEstimation is enabled and have
         // received loss statistics. Ie, this class require transport feedback.
         bool InUse() const {
            return Enabled() && last_loss_packet_report_.IsFinite();
         }
         void UpdateLossStatistics(const std::vector<PacketResult>& packet_results,
                                    Timestamp at_time);
         DataRate GetEstimate() const { return loss_based_bitrate_; }

      private:
         friend class GoogCcStatePrinter;
         void Reset(DataRate bitrate);
         double loss_increase_threshold() const;
         double loss_decrease_threshold() const;
         double loss_reset_threshold() const;

         DataRate decreased_bitrate() const;

         const LossBasedControlConfig config_;
         double average_loss_;
         double average_loss_max_;
         DataRate loss_based_bitrate_;
         DataRate acknowledged_bitrate_max_;
         Timestamp acknowledged_bitrate_last_update_;
         Timestamp time_last_decrease_;
         bool has_decreased_since_last_loss_report_;
         Timestamp last_loss_packet_report_;
         double last_loss_ratio_;
   };



