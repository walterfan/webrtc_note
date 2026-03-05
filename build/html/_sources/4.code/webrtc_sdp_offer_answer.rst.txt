##############################
WebRTC SDP Offer Answer
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC SDP Offer Answer
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
======================================

SDP Offer/Answer 模型是 WebRTC 建立连接的核心协商机制，遵循 RFC 3264。
在 WebRTC 原生代码中，``SdpOfferAnswerHandler`` 类是处理 SDP 协商的核心，
它管理 ``CreateOffer``、``CreateAnswer``、``SetLocalDescription``、``SetRemoteDescription``
等关键操作的完整流程。


SdpOfferAnswerHandler 类
======================================

``SdpOfferAnswerHandler`` 位于 ``pc/sdp_offer_answer.h``，是从 ``PeerConnection`` 中
拆分出来的专门处理 SDP 协商逻辑的类。它的主要职责：

* 管理 SDP 状态机 (stable → have-local-offer → have-remote-offer → stable)
* 创建和解析 SDP Offer/Answer
* 管理 ``RtpTransceiver`` 的生命周期
* 协调 ICE 和 DTLS 传输的建立

.. code-block:: cpp

   // SDP 状态机
   enum SignalingState {
     kStable,              // 初始状态 / 协商完成
     kHaveLocalOffer,      // 已设置本地 Offer
     kHaveRemoteOffer,     // 已收到远端 Offer
     kHaveLocalPrAnswer,   // 已设置本地临时 Answer
     kHaveRemotePrAnswer,  // 已收到远端临时 Answer
     kClosed               // 连接已关闭
   };


CreateOffer 流程
======================================

当应用调用 ``PeerConnection::CreateOffer()`` 时，内部流程如下：

1. **收集 Transceiver 信息**: 遍历所有 ``RtpTransceiver``，获取每个媒体的方向、编解码器等
2. **生成 MediaDescription**: 为每个 m= 行创建对应的媒体描述
3. **添加 ICE 候选参数**: 包含 ICE ufrag、password、DTLS fingerprint
4. **添加编解码器列表**: 根据本地支持的编解码器生成 codec 列表
5. **生成 SDP 字符串**: 将结构化的 SessionDescription 序列化为 SDP 文本

.. code-block:: text

   // CreateOffer 的简化调用链
   PeerConnection::CreateOffer(observer, options)
     → SdpOfferAnswerHandler::CreateOffer(observer, options)
       → MediaSessionDescriptionFactory::CreateOffer(options, current_desc)
         → 为每个 Transceiver 创建 ContentInfo
         → 添加 RTP header extensions
         → 添加 codec 列表和参数
       → observer->OnSuccess(offer_sdp)

生成的 SDP Offer 示例片段：

.. code-block:: text

   v=0
   o=- 4567890 2 IN IP4 127.0.0.1
   s=-
   t=0 0
   a=group:BUNDLE 0 1
   m=audio 9 UDP/TLS/RTP/SAVPF 111 103 104
   a=mid:0
   a=sendrecv
   a=rtpmap:111 opus/48000/2
   a=fmtp:111 minptime=10;useinbandfec=1
   m=video 9 UDP/TLS/RTP/SAVPF 96 97 98
   a=mid:1
   a=sendrecv
   a=rtpmap:96 VP8/90000
   a=rtcp-fb:96 nack
   a=rtcp-fb:96 nack pli
   a=rtcp-fb:96 transport-cc


CreateAnswer 流程
======================================

收到远端 Offer 后，调用 ``CreateAnswer()`` 生成 Answer：

1. **匹配编解码器**: 将远端 Offer 中的编解码器与本地支持的编解码器取交集
2. **确定媒体方向**: 根据远端方向和本地 Transceiver 方向确定最终方向
3. **选择传输参数**: 确定 ICE 角色 (controlling/controlled)、DTLS 角色
4. **生成 Answer SDP**: 每个 m= 行与 Offer 中的对应行匹配

.. code-block:: text

   // CreateAnswer 的关键逻辑
   SdpOfferAnswerHandler::CreateAnswer(observer, options)
     → MediaSessionDescriptionFactory::CreateAnswer(
           remote_offer, options, current_desc)
       → 对每个 Offer 中的 m= 行:
           → NegotiateCodecs(offer_codecs, local_codecs)
           → 确定方向: offer=sendrecv, local=sendrecv → sendrecv
           → 生成对应的 Answer ContentInfo


Transceiver 管理
======================================

``RtpTransceiver`` 是 Unified Plan SDP 的核心概念，每个 Transceiver 对应 SDP 中的一个 m= 行。

.. code-block:: cpp

   class RtpTransceiver {
     RtpSenderInterface* sender();      // 发送端
     RtpReceiverInterface* receiver();  // 接收端
     absl::optional<std::string> mid();  // Media ID
     RtpTransceiverDirection direction(); // sendrecv/sendonly/recvonly/inactive
     absl::optional<RtpTransceiverDirection> current_direction();
   };

Transceiver 的生命周期：

* **AddTrack()**: 创建新的 Transceiver 或复用已停止的 Transceiver
* **RemoveTrack()**: 将 Transceiver 方向改为 recvonly 或 inactive
* **协商过程中**: 根据远端 SDP 可能创建新的 Transceiver
* **Stop()**: 停止 Transceiver，对应的 m= 行标记为 rejected (port=0)


SetLocalDescription / SetRemoteDescription
=============================================

这两个方法是 SDP 协商的执行阶段：

**SetLocalDescription**:

1. 验证 SDP 类型与当前状态机是否匹配
2. 更新本地 SDP 描述
3. 触发 ICE candidate 收集 (如果是 Offer)
4. 更新 Transceiver 的 current_direction

**SetRemoteDescription**:

1. 解析远端 SDP，验证合法性
2. 创建或更新远端 Transceiver
3. 触发 ``ontrack`` 事件 (如果有新的接收流)
4. 应用远端的 ICE 候选和 DTLS 参数
5. 更新媒体通道的编解码器配置

.. code-block:: cpp

   // 典型的协商流程
   // Caller 端:
   pc->CreateOffer(observer, options);
   // observer->OnSuccess(offer):
   pc->SetLocalDescription(observer, offer);
   // 通过信令发送 offer 给 Callee

   // Callee 端:
   pc->SetRemoteDescription(observer, offer);
   pc->CreateAnswer(observer, options);
   // observer->OnSuccess(answer):
   pc->SetLocalDescription(observer, answer);
   // 通过信令发送 answer 给 Caller

   // Caller 端:
   pc->SetRemoteDescription(observer, answer);
   // 协商完成，媒体开始流动


参考资料
======================================
* 源码路径: ``pc/sdp_offer_answer.h``, ``pc/sdp_offer_answer.cc``
* ``pc/media_session.h`` - MediaSessionDescriptionFactory
* ``pc/rtp_transceiver.h`` - RtpTransceiver
* RFC 3264: An Offer/Answer Model with SDP
* RFC 8829: JavaScript Session Establishment Protocol (JSEP)
