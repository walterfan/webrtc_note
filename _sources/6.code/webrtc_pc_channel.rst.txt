#################################
WebRTC PeerConnection Channel
#################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ================================
**Abstract** WebRTC PeerConnection Channel
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ================================



.. contents::
   :local:

概述
=============

在 WebRTC 内部，``PeerConnection`` 并不直接管理媒体的发送和接收，
而是通过 **Channel** 层来协调信令线程、工作线程和网络线程之间的媒体操作。

.. code-block:: text

   PeerConnection
       │
       ├── RtpTransceiver (mid=0, audio)
       │       └── VoiceChannel ──► AudioSendStream / AudioReceiveStream
       │
       ├── RtpTransceiver (mid=1, video)
       │       └── VideoChannel ──► VideoSendStream / VideoReceiveStream
       │
       └── SctpTransport
               └── DataChannel


BaseChannel
--------------------------

``BaseChannel`` 是 ``VoiceChannel`` 和 ``VideoChannel`` 的基类，
封装了音视频通道的公共逻辑：

- 线程安全的启用/禁用
- 跨线程方法调度（信令→工作→网络）
- 连接和媒体状态监控
- SrtpTransport 管理

.. code-block:: c++

   class BaseChannel : public ChannelInterface {
   public:
       // 设置本地/远端 SDP 描述
       bool SetLocalContent(const MediaContentDescription* content,
                            SdpType type, std::string* error);
       bool SetRemoteContent(const MediaContentDescription* content,
                             SdpType type, std::string* error);

       // 启用/禁用通道
       void Enable(bool enable);

       // 获取通道关联的 RTP transport
       webrtc::RtpTransportInternal* rtp_transport() const;
   };

方法命名约定：

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - 后缀
     - 含义
   * - ``_n``
     - 必须在 Network Thread 上调用
   * - ``_w``
     - 必须在 Worker Thread 上调用
   * - ``_s``
     - 必须在 Signaling Thread 上调用

Network 和 Worker 线程在某些配置下可以是同一个线程。


VideoChannel
----------------------------

``VideoChannel`` 继承自 ``BaseChannel``，管理视频流的生命周期：

- 创建和销毁 ``VideoSendStream`` / ``VideoReceiveStream``
- 处理视频相关的 SDP 协商（编解码器、分辨率、帧率）
- 管理 Simulcast 和 SVC 配置
- 处理关键帧请求（PLI/FIR）


VoiceChannel
----------------------------

``VoiceChannel`` 继承自 ``BaseChannel``，管理音频流的生命周期：

- 创建和销毁 ``AudioSendStream`` / ``AudioReceiveStream``
- 处理音频相关的 SDP 协商（编解码器、采样率、声道数）
- 管理音频电平监控
- 处理 DTMF


SSRC 生成器
--------------------------

每条 RTP 流需要一个唯一的 SSRC 标识。WebRTC 使用 ``UniqueRandomIdGenerator``
生成随机的非零 32 位 SSRC：

.. code-block:: c++

   uint32_t UniqueRandomIdGenerator::GenerateId() {
       webrtc::MutexLock lock(&mutex_);
       RTC_CHECK_LT(known_ids_.size(),
                    std::numeric_limits<uint32_t>::max() - 1);
       while (true) {
           auto pair = known_ids_.insert(CreateRandomNonZeroId());
           if (pair.second) {
               return *pair.first;
           }
       }
   }

- SSRC 永远不为 0（0 有特殊含义）
- 使用 ``std::set`` 保证会话内不重复
- 碰撞概率极低（32 位空间），但仍需处理 SSRC 冲突


Channel 与 Transport 的关系
==============================

.. code-block:: text

   VoiceChannel / VideoChannel
       │
       ▼
   RtpTransport (or SrtpTransport / DtlsSrtpTransport)
       │
       ▼
   IceTransport (DTLS)
       │
       ▼
   P2PTransportChannel (ICE)
       │
       ▼
   UDP Socket

Channel 层不直接操作 Socket，而是通过 Transport 抽象层。
这种分层使得可以灵活替换传输方式（直连、TURN 中继、BUNDLE 复用等）。


参考资料
=============

- `BaseChannel 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/pc/channel.h>`_
- `PeerConnection 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/pc/peer_connection.h>`_
