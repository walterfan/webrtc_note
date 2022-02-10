:orphan:

##############################
WebRTC Congestion Control
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Congestion Control
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

Overview
=============


Receiver side congestion controller
------------------------------------------
从 https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/congestion_controller/BUILD.gn 可以看出以下的代码结构

.. code-block::

    rtc_library("congestion_controller") {
      visibility = [ "*" ]
      configs += [ ":bwe_test_logging" ]
      sources = [
        "include/receive_side_congestion_controller.h",
        "receive_side_congestion_controller.cc",
        "remb_throttler.cc",
        "remb_throttler.h",
      ]

      deps = [
        "..:module_api",
        "../../api/transport:field_trial_based_config",
        "../../api/transport:network_control",
        "../../api/units:data_rate",
        "../../api/units:time_delta",
        "../../api/units:timestamp",
        "../../rtc_base/synchronization:mutex",
        "../pacing",
        "../remote_bitrate_estimator",
        "../rtp_rtcp:rtp_rtcp_format",
      ]


sender side congestion controller
------------------------------------------

从 https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/congestion_controller/goog_cc/BUILD.gn 可以看出以下的代码结构

google congestion controller:

* alr_detector
* delay_based_bwe
* estimators
* probe_controller
* pushback_controller
* send_side_bwe

Code
=============


.. code-block:: c++

   enum class BandwidthUsage {
      kBwNormal = 0,
      kBwUnderusing = 1,
      kBwOverusing = 2,
      kLast
   };



* refer to https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/congestion_controller/



main classes
=================================

* GoogleNetworkController
* DelayBasedBwe
* TransportFeedbackAdapter
  - process RTCP message TransportFeedback to 


.. code-block::

   class DelayBasedBwe {
      public:
      struct Result {
         Result();
         ~Result() = default;
         bool updated;
         bool probe;
         DataRate target_bitrate = DataRate::Zero();
         bool recovered_from_overuse;
         bool backoff_in_alr;
      };

      explicit DelayBasedBwe(const WebRtcKeyValueConfig* key_value_config,
                              RtcEventLog* event_log,
                              NetworkStatePredictor* network_state_predictor);

      DelayBasedBwe() = delete;
      DelayBasedBwe(const DelayBasedBwe&) = delete;
      DelayBasedBwe& operator=(const DelayBasedBwe&) = delete;

      virtual ~DelayBasedBwe();

      Result IncomingPacketFeedbackVector(
            const TransportPacketsFeedback& msg,
            absl::optional<DataRate> acked_bitrate,
            absl::optional<DataRate> probe_bitrate,
            absl::optional<NetworkStateEstimate> network_estimate,
            bool in_alr);

      //...


      }


Reference
==================
* https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/encode_usage_resource.h
* https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/video/adaptation/overuse_frame_detector.h

