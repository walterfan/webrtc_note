##############################
WebRTC Video Flow
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Video Flow
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============

WebRTC 的视频处理流程分为发送端和接收端两条主线。发送端从摄像头采集视频帧，
经过预处理、编码、RTP 打包后发送到网络；接收端从网络接收 RTP 包，
经过解包、解码、渲染后显示到屏幕上。


VideoSendStream 发送流程
============================

``VideoSendStream`` (位于 ``video/video_send_stream.h``) 管理完整的视频发送链路。

数据流如下：

::

  VideoSource (Camera/Screen)
       |
  VideoBroadcaster
       |
  VideoStreamEncoder
       |  ├── VideoAdapter (分辨率/帧率适配)
       |  ├── VideoEncoder (VP8/VP9/H264/AV1)
       |  └── EncoderRateSettings (码率控制)
       |
  EncodedImageCallback
       |
  RtpVideoSender
       |  ├── RtpPacketizer (NAL → RTP)
       |  ├── FecGenerator (ULP-FEC / FlexFEC)
       |  └── RtxSender (重传)
       |
  PacedSender (平滑发送)
       |
  Network (UDP Socket)

关键类说明
--------------

**VideoStreamEncoder**: 发送端最核心的类，负责：

* 接收原始视频帧 (``VideoFrame``)
* 根据带宽和 CPU 负载动态调整编码参数 (``QualityScaler``)
* 调用编解码器进行编码
* 支持 Simulcast 多流编码

.. code-block:: cpp

   // VideoStreamEncoder 的核心回调
   class VideoStreamEncoder : public VideoStreamEncoderInterface,
                              public EncodedImageCallback {
     // 接收原始视频帧
     void OnFrame(const VideoFrame& frame) override;

     // 编码完成回调
     EncodedImageCallback::Result OnEncodedImage(
         const EncodedImage& encoded_image,
         const CodecSpecificInfo* codec_specific) override;
   };

**RtpVideoSender**: 负责将编码后的视频帧打包为 RTP 包：

* 根据编解码器类型选择打包方式 (VP8/VP9/H264 各有不同的 RTP payload format)
* 添加 RTP header extensions (如 transport-cc, abs-send-time)
* 生成 FEC 冗余包用于前向纠错
* 管理 RTX 重传流


VideoReceiveStream 接收流程
================================

``VideoReceiveStream`` (位于 ``video/video_receive_stream2.h``) 管理视频接收链路。

数据流如下：

::

  Network (UDP Socket)
       |
  RtpVideoStreamReceiver2
       |  ├── RtpDepacketizer (RTP → NAL)
       |  ├── NackModule (丢包检测与重传请求)
       |  └── PacketBuffer (帧组装)
       |
  FrameBuffer (帧排序与等待)
       |  ├── 等待关键帧
       |  ├── 帧间依赖检查
       |  └── Jitter Buffer 延迟控制
       |
  VideoDecoder (VP8/VP9/H264/AV1)
       |
  VideoReceiveStream::OnDecodedFrame
       |
  IncomingVideoStream
       |
  VideoSink (Renderer / Display)

关键类说明
--------------

**RtpVideoStreamReceiver2**: 接收端的入口，负责：

* 解析 RTP 包，提取视频 payload
* 处理 NACK：检测丢包并发送重传请求
* 处理 FEC：利用冗余包恢复丢失的数据包
* 组装完整的视频帧

**FrameBuffer**: 帧级别的缓冲管理：

* 维护帧的依赖关系 (参考帧是否已到达)
* 控制解码时机，平衡延迟和流畅性
* 请求关键帧 (PLI/FIR) 当无法解码时

.. code-block:: cpp

   // 接收端的关键流程
   void RtpVideoStreamReceiver2::OnRtpPacket(const RtpPacketReceived& packet) {
     // 1. 解析 RTP header 和 payload
     // 2. 检查是否需要 NACK
     // 3. 将 packet 放入 PacketBuffer
     // 4. 尝试组装完整帧
     // 5. 完整帧送入 FrameBuffer
   }

   void VideoReceiveStream2::OnCompleteFrame(
       std::unique_ptr<EncodedFrame> frame) {
     // 将完整帧插入 FrameBuffer
     // FrameBuffer 在合适的时机取出帧进行解码
   }


码率自适应
=============

发送端根据网络状况动态调整视频质量：

* **QualityScaler**: 监控编码器输出的 QP 值，QP 过高时降低分辨率
* **OveruseFrameDetector**: 监控 CPU 使用率，过载时降低帧率或分辨率
* **BitrateAllocator**: 根据 GCC 估计的可用带宽分配码率

::

  GCC 估计带宽下降
       |
  BitrateAllocator 降低目标码率
       |
  VideoStreamEncoder 调整编码参数
       |  ├── 降低帧率 (FrameDropper)
       |  ├── 降低分辨率 (VideoAdapter)
       |  └── 降低编码质量 (QP 上升)


Simulcast 与 SVC
===================

WebRTC 支持两种多层编码方式：

* **Simulcast**: 同时编码多个独立的分辨率层 (如 720p + 360p + 180p)，每层独立编码
* **SVC (Scalable Video Coding)**: 编码为可分层的单一码流，VP9 和 AV1 原生支持

Simulcast 在 SFU 架构中广泛使用，SFU 根据每个接收端的带宽选择转发合适的层。


参考资料
=============
* 源码路径: ``video/video_send_stream.h``, ``video/video_receive_stream2.h``
* ``video/video_stream_encoder.h``
* ``modules/rtp_rtcp/source/rtp_video_sender.h``
* ``video/rtp_video_stream_receiver2.h``
