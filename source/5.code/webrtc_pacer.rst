##############################
WebRTC Pacer
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Pacer
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============
将要发的包追加到一个队列中，由 Pacer 这个模块按照设定的速率将媒体包发送出去


主要方法：

* PacketRouter::SendPacket(...)
* ModuleRtpRtcpImpl::TrySendPacket(...)
* std::vector<std::unique_ptr<RtpPacketToSend>> RTPSender::GeneratePadding(...)


Types
==============

* RtpPacketMediaType 表示 RTP 包的类型，共有 5 种

1. 音频包
2. 视频包
3. 重传包
4. 纠错包
5. 填充包

.. code-block:: c++

    static constexpr size_t kNumMediaTypes = 5;
    enum class RtpPacketMediaType : size_t {
        kAudio,                         // Audio media packets.
        kVideo,                         // Video media packets.
        kRetransmission,                // Retransmisions, sent as response to NACK.
        kForwardErrorCorrection,        // FEC packets.
        kPadding = kNumMediaTypes - 1,  // RTX or plain padding sent to maintain BWE.
        // Again, don't forget to udate `kNumMediaTypes` if you add another value!
    };
