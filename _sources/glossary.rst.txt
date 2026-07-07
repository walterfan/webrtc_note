######################
术语表
######################

.. include:: links.ref
.. include:: tags.ref
.. include:: abbrs.ref

============ ==========================
**Abstract** 音视频实时通信术语速查
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================


本术语表汇总了全书涉及的核心术语，按英文字母排序，可用浏览器搜索（Ctrl+F）快速定位。

.. glossary::
   :sorted:

   AEC
      Acoustic Echo Cancellation，声学回声消除。消除扬声器播放的声音被麦克风重新采集后产生的回声。
      参见 :doc:`3.audio/audio_aec`。

   AGC
      Automatic Gain Control，自动增益控制。自动调整音频信号的增益，使输出音量保持稳定。
      参见 :doc:`3.audio/audio_agc`。

   AIMD
      Additive Increase Multiplicative Decrease，加性增乘性减。拥塞控制的经典策略，WebRTC GCC 中用于调整估计比特率。
      参见 :doc:`6.code/remote_bitrate_estimator`。

   ANS
      Automatic Noise Suppression，自动噪声抑制。降低背景噪音，提升语音清晰度。
      参见 :doc:`3.audio/audio_ans`。

   AV1
      AOMedia Video 1，开放媒体联盟的下一代视频编解码器，压缩效率优于 H.264 和 VP8。
      参见 :doc:`4.video/video_codec_av1`。

   BFCP
      Binary Floor Control Protocol，二进制发言控制协议。用于多方会议中的发言权管理。
      参见 :doc:`2.transport/bfcp`。

   BUNDLE
      一种 SDP 机制（RFC 8843），将多路媒体流复用到单个传输通道上，减少端口和 ICE 协商开销。
      参见 :doc:`2.transport/webrtc_bundle`。

   CELT
      Constrained Energy Lapped Transform，一种低延迟音频编码技术，是 Opus 编解码器的高频编码核心。
      参见 :doc:`3.audio/audio_codec_opus`。

   CNAME
      Canonical Name，规范名称。RTCP SDES 中的标识符，用于跨 SSRC 关联同一参与者的多条流，是音视频同步的基础。

   DataChannel
      WebRTC 的数据通道，基于 SCTP over DTLS，支持可靠/不可靠的任意数据传输。
      参见 :doc:`2.transport/webrtc_data_channel`。

   DTLS
      Datagram Transport Layer Security，基于 UDP 的传输层安全协议。WebRTC 用它协商 SRTP 密钥。
      参见 :doc:`2.transport/dtls`。

   DTX
      Discontinuous Transmission，不连续传输。静音时停止发送音频包以节省带宽。

   DRED
      Deep Redundancy，深度冗余。Opus 1.5+ 引入的基于深度学习的冗余编码，提升丢包下的音质。
      参见 :doc:`3.audio/audio_codec_opus`。

   FEC
      Forward Error Correction，前向纠错。发送端附加冗余数据，接收端无需重传即可恢复丢失的包。
      参见 :doc:`5.qos/webrtc_fec`。

   FIR
      Full Intra Request，完整帧内请求。接收端请求发送端发送完整关键帧。

   GCC
      Google Congestion Control，Google 拥塞控制算法。WebRTC 的默认拥塞控制，结合延迟和丢包估计。
      参见 :doc:`5.qos/webrtc_gcc`。

   H.264
      ITU-T 和 ISO/IEC 联合制定的视频编解码标准，WebRTC 支持的视频编解码器之一。
      参见 :doc:`4.video/video_codec_h264`。

   ICE
      Interactive Connectivity Establishment，交互式连接建立。综合 STUN/TURN 实现 NAT 穿透。
      参见 :doc:`2.transport/ice`。

   Jitter Buffer
      抖动缓冲区。接收端缓存收到的包，重新排序并平滑网络抖动带来的时间波动。
      参见 :doc:`5.qos/audio_jitter_buffer`。

   MCU
      Multipoint Control Unit，多点控制单元。服务端混合所有参与者的媒体流后统一分发。

   MID
      Media Identification，媒体标识。BUNDLE 模式下通过 RTP 扩展头标识所属的 SDP m= 行。

   NACK
      Negative Acknowledgement，否定确认。接收端通知发送端某包丢失，请求重传。
      参见 :doc:`6.code/webrtc_nack_code`。

   NetEQ
      WebRTC 的音频网络均衡器，集成了 Jitter Buffer、PLC、加减速播放等功能。

   Opus
      IETF 标准化的音频编解码器（RFC 6716），WebRTC 的强制实现编解码器，支持 6 kbps – 510 kbps。
      参见 :doc:`3.audio/audio_codec_opus`。

   Pacer
      发送节奏控制器。将编码器突发输出的包平滑分散到时间轴上发送，避免瞬时拥塞。
      参见 :doc:`6.code/webrtc_pacer`。

   PLC
      Packet Loss Concealment，丢包隐藏。当音频包丢失时，解码器合成替代音频以掩盖间断。

   PLI
      Picture Loss Indication，图片丢失指示。接收端通知发送端丢失了视频参考帧，请求关键帧。

   QP
      Quantization Parameter，量化参数。视频编码中控制压缩程度的参数，QP 越大画质越差。

   REMB
      Receiver Estimated Maximum Bitrate，接收端估计最大比特率。旧版 GCC 的带宽反馈机制。
      参见 :doc:`5.qos/webrtc_remb`。

   RTP
      Real-time Transport Protocol，实时传输协议（RFC 3550）。音视频数据的载体。
      参见 :doc:`2.transport/rtp`。

   RTCP
      RTP Control Protocol，RTP 控制协议。提供传输质量反馈、同步和参与者信息。
      参见 :doc:`2.transport/rtcp`。

   RTX
      Retransmission，重传流。使用独立 SSRC 发送 NACK 请求的重传包。
      参见 :doc:`5.qos/webrtc_rtx`。

   SCTP
      Stream Control Transmission Protocol，流控制传输协议。WebRTC DataChannel 的底层传输。
      参见 :doc:`2.transport/sctp`。

   SDP
      Session Description Protocol，会话描述协议。描述媒体会话的编解码器、地址、安全等参数。
      参见 :doc:`1.basic/webrtc_sdp`。

   SFU
      Selective Forwarding Unit，选择性转发单元。服务端按需转发（不混合）参与者的媒体流。
      参见 :doc:`7.practice/sfu`。

   SILK
      Skype 开发的语音编码技术，是 Opus 的低频编码核心，擅长窄带/宽带语音。
      参见 :doc:`3.audio/audio_codec_opus`。

   Simulcast
      同时发送同一视频源的多个质量层（不同分辨率/帧率），由 SFU 按接收端能力选择转发。
      参见 :doc:`4.video/webrtc_simulcast`。

   SRTP
      Secure Real-time Transport Protocol，安全 RTP（RFC 3711）。对 RTP 载荷加密并认证。
      参见 :doc:`2.transport/srtp`。

   SSRC
      Synchronization Source，同步源标识符。32 位随机数，唯一标识 RTP 会话中的一条流。

   STUN
      Session Traversal Utilities for NAT，NAT 会话穿透工具（RFC 8489）。用于发现公网地址。
      参见 :doc:`2.transport/stun`。

   SVC
      Scalable Video Coding，可伸缩视频编码。单流编码多个质量层，由 SFU 按需裁剪。
      参见 :doc:`4.video/webrtc_svc`。

   TURN
      Traversal Using Relays around NAT，使用中继穿越 NAT（RFC 5766）。当直连和 STUN 均失败时通过服务器中继。
      参见 :doc:`2.transport/turn`。

   TWCC
      Transport-Wide Congestion Control，传输层拥塞控制。接收端反馈每包到达时间，发送端估算带宽。
      参见 :doc:`5.qos/webrtc_twcc`。

   VAD
      Voice Activity Detection，语音活动检测。区分语音和静默段，常用于 DTX 和噪声抑制。
      参见 :doc:`3.audio/audio_vad`。

   VP8
      Google 开源的视频编解码器，WebRTC 早期默认视频编解码器。

   WebSocket
      全双工通信协议，常用于 WebRTC 的信令通道。
      参见 :doc:`2.transport/websocket`。

   YUV
      一种颜色空间，分离亮度（Y）和色度（U/V）。视频编码前的标准像素格式。
      参见 :doc:`4.video/yuv`。
