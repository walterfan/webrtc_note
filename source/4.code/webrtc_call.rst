####################
WebRTC Call
####################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Call
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============

``Call`` 是 WebRTC 原生代码中的核心类之一，位于 ``call/call.h``，
它代表一个完整的通话会话，负责管理所有的音视频发送流和接收流，
并协调带宽估计、拥塞控制等传输层功能。

Objects
--------------
* PeerConnection
* Call
* Transceiver
* Channel

  - WebRtcVideoChannel
  - WebRtcVoiceMediaChannel


Call 类的职责
=================

``Call`` 类是 ``PeerConnection`` 和底层媒体引擎之间的桥梁，主要职责包括：

1. **媒体流管理**: 创建和销毁 AudioSendStream、AudioReceiveStream、VideoSendStream、VideoReceiveStream
2. **带宽估计**: 持有全局的 ``SendSideCongestionController``，统一管理所有流的带宽分配
3. **Pacer 管理**: 通过 ``PacedSender`` 控制所有媒体包的发送节奏
4. **RTCP 处理**: 汇总处理所有流的 RTCP 反馈
5. **比特率分配**: 通过 ``BitrateAllocator`` 在多条流之间分配可用带宽

.. code-block:: cpp

   // Call 接口定义 (简化)
   class Call {
    public:
     virtual AudioSendStream* CreateAudioSendStream(
         const AudioSendStream::Config& config) = 0;
     virtual void DestroyAudioSendStream(AudioSendStream* send_stream) = 0;

     virtual AudioReceiveStreamInterface* CreateAudioReceiveStream(
         const AudioReceiveStreamInterface::Config& config) = 0;

     virtual VideoSendStream* CreateVideoSendStream(
         VideoSendStream::Config config,
         VideoEncoderConfig encoder_config) = 0;
     virtual void DestroyVideoSendStream(VideoSendStream* send_stream) = 0;

     virtual VideoReceiveStreamInterface* CreateVideoReceiveStream(
         VideoReceiveStreamInterface::Config config) = 0;

     virtual Stats GetStats() const = 0;
   };


与 PeerConnection 的关系
============================

``PeerConnection`` 是面向应用层的 API 接口，而 ``Call`` 是内部的媒体会话管理器。
它们之间的层次关系如下：

::

  Application
      |
  PeerConnection          (API 层: SDP 协商, ICE 连接)
      |
  RtpTransceiver          (媒体协商单元: sender + receiver)
      |
  WebRtcVideoChannel /    (媒体通道: 编解码器协商)
  WebRtcVoiceMediaChannel
      |
  Call                     (会话管理: 流管理, 带宽估计)
      |
  AudioSendStream /        (具体的媒体流)
  VideoSendStream /
  AudioReceiveStream /
  VideoReceiveStream

当 ``PeerConnection::SetLocalDescription`` 或 ``SetRemoteDescription`` 被调用时，
``SdpOfferAnswerHandler`` 会解析 SDP，通过 ``RtpTransceiver`` 和 ``MediaChannel``
最终调用 ``Call`` 的接口来创建或更新媒体流。


AudioSendStream 管理
========================

``AudioSendStream`` 负责音频发送流的完整生命周期：

* 从 ``AudioDeviceModule`` 获取采集的 PCM 数据
* 经过 ``AudioProcessing`` 模块进行预处理
* 使用配置的编解码器 (如 Opus) 进行编码
* 将编码后的数据通过 RTP 发送

.. code-block:: cpp

   // AudioSendStream 的创建流程
   AudioSendStream::Config audio_config(send_transport);
   audio_config.rtp.ssrc = local_ssrc;
   audio_config.rtp.extensions = rtp_extensions;
   audio_config.encoder_factory = encoder_factory;
   audio_config.send_codec_spec = AudioSendStream::Config::SendCodecSpec(
       payload_type, SdpAudioFormat("opus", 48000, 2));

   AudioSendStream* audio_send_stream =
       call->CreateAudioSendStream(audio_config);
   audio_send_stream->Start();


VideoSendStream 管理
========================

``VideoSendStream`` 管理视频发送流，涉及更复杂的处理：

* **视频源**: 从 ``VideoTrackSource`` 获取视频帧
* **预处理**: 缩放、裁剪、帧率适配
* **编码**: 支持 VP8、VP9、H.264、AV1 等编解码器
* **Simulcast/SVC**: 支持多层编码以适应不同接收端的带宽
* **RTP 打包**: 将编码后的 NAL 单元打包为 RTP 包
* **Pacer**: 通过 PacedSender 平滑发送

.. code-block:: cpp

   // VideoSendStream 的创建
   VideoSendStream::Config video_config(send_transport);
   video_config.rtp.ssrc = video_ssrc;
   video_config.rtp.rtx.ssrc = rtx_ssrc;
   video_config.encoder_settings.encoder_factory = encoder_factory;

   VideoEncoderConfig encoder_config;
   encoder_config.codec_type = kVideoCodecVP8;
   encoder_config.max_bitrate_bps = 2000000;
   encoder_config.number_of_streams = 3;  // simulcast

   VideoSendStream* video_send_stream =
       call->CreateVideoSendStream(std::move(video_config),
                                   std::move(encoder_config));


带宽估计与比特率分配
========================

``Call`` 内部持有全局的拥塞控制器，负责：

1. **接收端估计**: 通过 RTCP REMB 或 Transport-CC 反馈估计可用带宽
2. **发送端估计**: 基于丢包率和延迟梯度进行 GCC (Google Congestion Control) 估计
3. **比特率分配**: ``BitrateAllocator`` 根据各流的优先级和最小/最大码率约束分配带宽

::

  Transport-CC feedback
         |
  SendSideBwe (带宽估计)
         |
  BitrateAllocator (比特率分配)
       /    \
  VideoStream  AudioStream
  (动态码率)   (固定码率优先)

音频流通常具有更高的优先级，因为人耳对音频中断更敏感。
视频流则根据可用带宽动态调整分辨率和帧率。


参考资料
=============
* 源码路径: ``call/call.h``, ``call/call.cc``
* ``call/audio_send_stream.h``, ``call/video_send_stream.h``
* ``call/bitrate_allocator.h``
