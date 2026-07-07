##################
5. QoS 与网络对抗
##################

本章涵盖 WebRTC 的 QoS 策略，包括拥塞控制算法（GCC/REMB/TWCC）、前向纠错（FEC）、重传（NACK/RTX）、抖动缓冲（Jitter Buffer）、丢包隐藏（PLC）、端到端延迟等。

.. toctree::
   :maxdepth: 1
   :caption: 目录

   webrtc_qos

   webrtc_cc
   webrtc_gcc
   webrtc_remb
   webrtc_twcc
   webrtc_bw_probe
   webrtc_cc_evaluation

   webrtc_fec
   webrtc_rtx
   webrtc_red
   webrtc_feedback

   jitter_overview
   audio_jitter_buffer
   video_jitter_buffer
   neteq_deep_dive
   plc

   webrtc_e2e_delay
   webrtc_metrics
   network_resilience

   web_transport
