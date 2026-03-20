########################
WebRTC RTX
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC RTX
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:


简介
=========================

在 WebRTC 中常用的 QoS 策略有

1. 反馈：例如 PLI , NACK
2. 冗余， 例如 FEC, RTX, Interleaving 交织编码
3. 调整：例如码率，分辨率及帧率的调整
4. 缓存:  例如 Receive Adaptive Jitter Buffer, Send Buffer

这些措施的采用需要基于拥塞控制(congestion control) 及带宽估计(bandwidth estimation)技术, 不同的网络条件下需要采用不同的措施。

`RFC2354`_ 对这些方法有所讨论， FEC 用作丢包恢复需要占用更多的带宽，即使 5% 的丢包需要几乎一倍的带宽，在带宽有限的情况下可能会使情况更糟。

RTX 不会占用太多的带宽，接收方发送 NACK 指明哪些包丢失了，发送方通过单独的 RTP 流（不同的 SSRC）来重传丢失的包，但是 RTX 至少需要一个 RTT 来修复丢失的包。

音频流对于延迟很敏感，而且占用带宽不多，所以用 FEC 更好。
视频流对于延迟没那么敏感，而且占用带宽很多，所以用 RTX 更好。

所以 RTP 重传是一种有效的丢包恢复技术，适用于具有宽松延迟限制的实时应用程序。

`RFC4588`_ describes an RTP payload format for performing retransmissions.  Retransmitted RTP packets are sent in a separate stream from the original RTP stream.

RTX 即 RTransmission, 用于丢包重传， 它使用不同的会话(session) 或者不同的 ssrc 来传送冗余的 RTP 包

Webrtc 默认是开启 RTX (重传)，它一般采用不同的 SSRC 进行传输, RTX 包的 Payload 在  RFC4588 中有详细描述，一般 NACK 和 Bandwidth Probe 也可能走 RTX 通道。


丢包恢复策略对比
-------------------------

在 WebRTC 中，丢包恢复主要有三种策略：NACK + RTX、FEC 和 NACK-only。它们各有优劣，适用于不同的场景。

.. list-table:: 丢包恢复策略对比
   :header-rows: 1
   :widths: 15 20 20 20 25

   * - 策略
     - 原理
     - 优点
     - 缺点
     - 适用场景
   * - NACK + RTX
     - 接收方检测丢包后发送 NACK，发送方通过独立 RTX 流重传
     - 带宽开销小，只重传丢失的包；恢复精确
     - 至少需要一个 RTT 的延迟；不适合高延迟网络
     - 视频流，RTT < 200ms 的场景
   * - FEC (ULPFEC/FlexFEC)
     - 发送方提前发送冗余纠错包，接收方利用冗余数据恢复丢失包
     - 无需等待 RTT，恢复速度快
     - 带宽开销大（通常需要额外 50%-100% 带宽）；丢包超过冗余度则无法恢复
     - 音频流；高延迟网络；低丢包率场景
   * - NACK-only (无 RTX)
     - 接收方发送 NACK，发送方在原始 SSRC 上重传
     - 实现简单，无需额外 SSRC
     - 序列号不连续，可能干扰 RTCP 统计；无法区分原始包和重传包
     - 简单场景，不推荐在 WebRTC 中使用

**选择策略的一般原则：**

* **RTT < 100ms 且丢包率 < 10%** ：优先使用 NACK + RTX，带宽效率最高
* **RTT > 200ms 或丢包率 > 15%** ：优先使用 FEC，避免重传延迟过大
* **中等条件** ：RTX 和 FEC 可以同时使用，互为补充
* **音频流** ：通常使用 Opus 内置 FEC 或 RED 冗余编码
* **视频流** ：通常使用 NACK + RTX 作为主要恢复手段


术语
===================================

* Original packet: 源包

  an RTP packet that carries user data sent for the first time by an RTP sender.

* Original stream: 源媒体流

  the RTP stream of original packets.

* Retransmission packet: 重传包

  an RTP packet that is to be used by the receiver instead of a lost original packet.
  Such a retransmission packet is said to be associated with the original RTP packet.

* Retransmission request:

  a means by which an RTP receiver is able to request that the RTP sender should send a retransmission packet
  for a given original packet.  Usually, an RTCP NACK packet as specified in is used as retransmission request
  for lost packets.

* Retransmission stream:

  the stream of retransmission packets associated with an original stream.

* Session-multiplexing:

  scheme by which the original stream and the associated retransmission stream are sent into two different RTP sessions.

* SSRC: synchronization source.

* SSRC-multiplexing:

  scheme by which the original stream and the retransmission stream are sent in the same RTP session with different SSRC values.

* OSN (Original Sequence Number):

  RTX 包 payload 的前两个字节，记录了被重传的原始 RTP 包的序列号，接收方据此将重传包还原为原始包。

* RTX SSRC:

  RTX 流使用的 SSRC，与原始媒体流的 SSRC 不同，用于区分原始包和重传包。

* APT (Associated Payload Type):

  在 SDP 中用于将 RTX 的 payload type 与原始媒体的 payload type 关联起来。


Requirements and Design Rationale for a Retransmission Scheme
======================================================================

The use of retransmissions in RTP as a repair method for streaming media is appropriate in those scenarios with relaxed delay bounds and where full reliability is not a requirement.

The RTP retransmission scheme defined in this document is designed to
   fulfill the following set of requirements:

   1. It must not break general RTP and RTCP mechanisms.
   2. It must be suitable for unicast and small multicast groups.
   3. It must work with mixers and translators.
   4. It must work with all known payload types.
   5. It must not prevent the use of multiple payload types in a
      session.
   6. In order to support the largest variety of payload formats, the
      RTP receiver must be able to derive how many and which RTP packets
      were lost as a result of a gap in received RTP sequence numbers.

      This requirement is referred to as sequence number preservation.
      Without such a requirement, it would be impossible to use
      retransmission with payload formats, such as conversational text
      [9] or most audio/video streaming applications, that use the RTP
      sequence number to detect lost packets.

Retransmission Payload Format
===================================
.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                         RTP Header                            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |            OSN                |                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               |
   |                  Original RTP Packet Payload                  |
   |                                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

RTX 包的 RTP Header 与普通 RTP 包结构相同，但有以下关键区别：

* **SSRC** ：使用 RTX 专用的 SSRC，与原始媒体流的 SSRC 不同
* **Sequence Number** ：RTX 流有自己独立的序列号空间，从随机值开始递增
* **Payload Type** ：使用 RTX 专用的 payload type（在 SDP 中通过 apt 参数与原始 PT 关联）
* **Timestamp** ：与原始包的 timestamp 相同，便于接收方正确排序
* **Payload** ：前 2 字节为 OSN（Original Sequence Number），后面跟原始包的 payload 数据

SDP 协商示例
-------------------------

在 SDP 中，RTX 通过 ``a=rtpmap`` 和 ``a=fmtp`` 进行协商：

.. code-block:: sdp

   m=video 9 UDP/TLS/RTP/SAVPF 96 97
   a=rtpmap:96 VP8/90000
   a=rtpmap:97 rtx/90000
   a=fmtp:97 apt=96
   a=ssrc-group:FID 12345678 87654321
   a=ssrc:12345678 cname:user@example.com
   a=ssrc:87654321 cname:user@example.com

其中：

* PT 96 是 VP8 视频的 payload type
* PT 97 是对应的 RTX payload type
* ``apt=96`` 表示 PT 97 关联到 PT 96
* ``FID`` (Flow Identification) SSRC group 将原始 SSRC (12345678) 和 RTX SSRC (87654321) 关联起来


NACK 机制详解
=========================

NACK（Negative Acknowledgement）是 RTCP 反馈消息的一种，定义在 `RFC4585`_ 中。接收方通过 NACK 告知发送方哪些 RTP 包丢失了，请求发送方重传。

NACK 包格式
-------------------------

NACK 使用 RTCP Generic NACK 格式，其 Feedback Message Type (FMT) 为 1，Payload Type 为 205 (RTPFB)。

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P|  FMT=1  |   PT=205     |          length               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of packet sender                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of media source                         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |            PID                |             BLP               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

各字段含义：

* **FMT=1** ：表示 Generic NACK
* **PT=205** ：RTCP Transport Layer Feedback (RTPFB)
* **SSRC of packet sender** ：发送此 NACK 的接收方的 SSRC
* **SSRC of media source** ：丢包所属的媒体流的 SSRC
* **PID (Packet ID)** ：丢失的第一个 RTP 包的序列号（16 bit）
* **BLP (Bitmask of Lost Packets)** ：PID 之后的 16 个包的丢失位图，bit 0 表示 PID+1，bit 1 表示 PID+2，以此类推

一个 NACK FCI (Feedback Control Information) 条目可以报告最多 17 个连续范围内的丢包（1 个 PID + 16 个 BLP 位）。一个 NACK 包可以包含多个 FCI 条目。

**示例** ：假设序列号 100、102、105 的包丢失了

* PID = 100
* BLP = 0b0000000000010010 （bit 1 对应 102，bit 4 对应 105）

接收方 NACK 生成
-------------------------

在 WebRTC 中，接收方的 NACK 生成由 ``NackRequester`` （早期版本中叫 ``NackModule`` 或 ``NackModule2``）负责。其核心逻辑如下：

1. **丢包检测** ：当接收方收到一个 RTP 包时，检查其序列号是否连续。如果发现序列号间隙（gap），则将缺失的序列号加入 NACK 列表。

2. **等待乱序** ：不会立即发送 NACK，而是等待一小段时间（通常基于 reorder timer），因为网络乱序可能导致包晚到而非真正丢失。

3. **RTT 感知** ：NACK 的重发间隔基于 RTT。如果第一次 NACK 没有收到重传包，会在一个 RTT 后重新发送 NACK。

4. **最大重试次数** ：为避免无限重传，NACK 有最大重试次数限制（WebRTC 中默认为 10 次）。

5. **关键帧请求降级** ：如果某个包的 NACK 重试次数耗尽仍未恢复，且该包属于参考帧，接收方可能会发送 PLI/FIR 请求关键帧。

.. code-block:: c++

   // NackRequester 的核心数据结构（简化）
   struct NackInfo {
     uint16_t seq_num;        // 丢失包的序列号
     uint16_t send_at_seq_num; // 在收到此序列号时发送 NACK
     Timestamp created_at;     // 首次检测到丢包的时间
     Timestamp sent_at;        // 上次发送 NACK 的时间
     int retries;              // 已重试次数
   };

   // 丢包检测的核心逻辑
   void NackRequester::OnReceivedPacket(uint16_t seq_num,
                                        bool is_keyframe,
                                        bool is_recovered) {
     // 如果是恢复的包（来自 FEC 或 RTX），从 NACK 列表中移除
     if (is_recovered) {
       nack_list_.erase(seq_num);
       return;
     }

     // 检测序列号间隙，将缺失的序列号加入 NACK 列表
     if (seq_num != newest_seq_num_ + 1) {
       for (uint16_t i = newest_seq_num_ + 1;
            AheadOf(seq_num, i); ++i) {
         nack_list_[i] = NackInfo(i, seq_num + kWaitNumberOfPackets,
                                  clock_->Now());
       }
     }
     newest_seq_num_ = seq_num;
   }

发送方 NACK 处理
-------------------------

发送方收到 NACK 后的处理流程：

1. **解析 NACK** ：从 RTCP NACK 包中提取丢失的序列号列表（PID + BLP 展开）。

2. **查找历史包** ：在 ``RtpPacketHistory`` 中查找对应序列号的原始包。如果包已经被清除（超出历史缓存），则忽略该 NACK。

3. **构建 RTX 包** ：将原始包封装为 RTX 格式（添加 OSN，替换 SSRC 和 PT）。

4. **发送 RTX 包** ：通过 pacer 发送 RTX 包，遵循拥塞控制的速率限制。

.. code-block:: c++

   // 发送方处理 NACK 的简化流程
   void RtpSenderEgress::OnReceivedNack(
       const std::vector<uint16_t>& nack_sequence_numbers,
       int64_t avg_rtt) {
     for (uint16_t seq_num : nack_sequence_numbers) {
       const int32_t bytes_sent = ReSendPacket(seq_num);
       if (bytes_sent < 0) {
         // 包不在历史缓存中，无法重传
         LOG(LS_WARNING) << "Failed to resend packet " << seq_num;
       }
     }
   }

NACK 速率限制与去重
-------------------------

为了避免 NACK 风暴（大量丢包时产生大量 NACK），WebRTC 实现了以下保护机制：

* **NACK 列表大小限制** ：NACK 列表有最大容量（默认 500 个条目）。当列表满时，最旧的条目会被丢弃，并可能触发关键帧请求。

* **发送速率限制** ：NACK 的发送频率受限于 RTCP 带宽预算。在 RTCP 复合包中，NACK 与其他反馈消息共享带宽。

* **去重** ：对于同一个序列号，在一个 RTT 内不会重复发送 NACK。``NackRequester`` 通过 ``sent_at`` 时间戳和 RTT 估计来控制重发间隔。

* **批量发送** ：多个丢失的序列号会被合并到一个 NACK 包中发送，利用 BLP 位图高效编码连续丢包。

RTT 感知的 NACK 时序
-------------------------

NACK 的发送时机与 RTT 密切相关：

.. code-block:: text

   时间线示例 (RTT = 50ms):

   T=0ms     接收方检测到 seq=100 丢失
   T=10ms    等待乱序窗口（约 2-3 个包的时间）
   T=10ms    发送第一次 NACK(seq=100)
   T=35ms    发送方收到 NACK，查找 seq=100，构建 RTX 包
   T=36ms    发送方发送 RTX 包
   T=60ms    接收方收到 RTX 包，恢复 seq=100
   ---
   如果 RTX 包也丢失了：
   T=60ms    接收方未收到重传，等待一个 RTT
   T=110ms   发送第二次 NACK(seq=100)
   ...

在 WebRTC 中，NACK 的重发间隔计算公式大致为：

.. code-block:: text

   nack_resend_interval = max(rtt_ms, kMinNackResendIntervalMs)

其中 ``kMinNackResendIntervalMs`` 通常为 20ms，确保即使 RTT 很小也不会过于频繁地发送 NACK。


RTX 工作流程
=========================

RTX 的完整工作流程涉及接收方和发送方的协作。以下是详细的步骤说明和时序图。

流程概述
-------------------------

.. code-block:: text

   Sender                                              Receiver
     |                                                     |
     |--- RTP Packet (seq=100, SSRC=A) ------------------->|
     |--- RTP Packet (seq=101, SSRC=A) ------X (丢失)      |
     |--- RTP Packet (seq=102, SSRC=A) ------------------->|
     |                                                     |
     |                          检测到 seq=101 丢失         |
     |                          等待乱序窗口                |
     |                                                     |
     |<--- RTCP NACK (PID=101) ----------------------------|
     |                                                     |
     | 查找 RtpPacketHistory                               |
     | 找到 seq=101 的原始包                                |
     | 构建 RTX 包:                                        |
     |   SSRC = B (RTX SSRC)                               |
     |   SeqNum = RTX 流的下一个序列号                      |
     |   PT = RTX payload type                             |
     |   Payload = [OSN=101] + 原始 payload                |
     |                                                     |
     |--- RTX Packet (SSRC=B, OSN=101) ------------------->|
     |                                                     |
     |                          识别 RTX SSRC              |
     |                          提取 OSN=101               |
     |                          还原为原始包 (seq=101)      |
     |                          插入 jitter buffer         |
     |                                                     |

详细步骤
-------------------------

**Step 1: 接收方检测丢包**

接收方维护一个期望的序列号。当收到 seq=102 但期望 seq=101 时，检测到间隙。``NackRequester`` 将 seq=101 加入 NACK 列表，但不会立即发送 NACK，而是等待几个包的时间以排除乱序。

**Step 2: 接收方发送 NACK**

等待乱序窗口后，如果 seq=101 仍未到达，接收方构建 RTCP Generic NACK 包并发送。NACK 包中包含 PID=101 和对应的 BLP。

**Step 3: 发送方接收 NACK**

发送方的 RTCP 处理模块解析 NACK，提取丢失的序列号列表。对于每个序列号，调用 ``ReSendPacket()`` 尝试重传。

**Step 4: 发送方查找历史包**

``RtpPacketHistory`` 中存储了最近发送的 RTP 包。发送方根据序列号查找原始包。如果包仍在历史缓存中，则进入下一步；否则忽略。

**Step 5: 发送方构建 RTX 包**

调用 ``RTPSender::BuildRtxPacket()`` 构建 RTX 包：

* 分配新的 RTX 序列号（RTX 流有独立的序列号空间）
* 设置 RTX SSRC
* 设置 RTX payload type
* 在 payload 前插入 2 字节的 OSN（原始序列号）
* 复制原始包的 payload 数据

**Step 6: 接收方接收 RTX 包**

接收方根据 SSRC 识别这是一个 RTX 包（RTX SSRC 在 SDP 协商时已知）。提取 payload 前 2 字节作为 OSN，剩余部分作为原始 payload。用 OSN 和原始 SSRC 重建原始 RTP 包，插入 jitter buffer。

RTX 包的还原
-------------------------

接收方还原 RTX 包的过程如下：

.. code-block:: c++

   // 接收方还原 RTX 包的简化逻辑
   bool RtpDemuxer::ParseRtxPacket(const RtpPacketReceived& rtx_packet,
                                    RtpPacketReceived* original_packet) {
     // RTX payload 至少需要 2 字节（OSN）
     if (rtx_packet.payload_size() < 2) {
       return false;
     }

     // 提取 OSN
     auto payload = rtx_packet.payload();
     uint16_t original_seq_num =
         ByteReader<uint16_t>::ReadBigEndian(payload.data());

     // 重建原始包
     original_packet->SetSsrc(original_ssrc);  // 使用原始 SSRC
     original_packet->SetSequenceNumber(original_seq_num);
     original_packet->SetPayloadType(original_payload_type);
     original_packet->SetTimestamp(rtx_packet.Timestamp());

     // 复制原始 payload（跳过前 2 字节 OSN）
     original_packet->SetPayload(payload.subview(2));

     return true;
   }


RTX 用于带宽探测
=========================

除了丢包重传，RTX 在 WebRTC 中还有一个重要用途：**带宽探测（Bandwidth Probing）**。

带宽探测的需求
-------------------------

WebRTC 的拥塞控制算法（如 GCC/SendSideBWE）需要不断探测可用带宽。当估计的带宽低于实际可用带宽时，需要发送额外的数据来探测更高的带宽。

传统的做法是发送纯 padding 包（全零填充），但这些包对接收方没有任何价值。WebRTC 巧妙地利用 RTX 通道发送历史包作为 padding，这样即使这些包到达接收方，也可以被正确处理（虽然通常会被丢弃，因为 jitter buffer 中已有对应的原始包）。

RTX Padding 的工作方式
-------------------------

1. **Pacer 请求 padding** ：当 pacer 的发送速率低于目标码率时，需要额外的 padding 来填充带宽。

2. **选择历史包** ：``RtpPacketHistory`` 根据优先级策略选择一个历史包作为 padding 候选。

3. **构建 RTX 包** ：将选中的历史包封装为 RTX 格式发送。

4. **带宽估计** ：接收方收到这些包后，会在 Transport-CC 反馈中报告，发送方据此更新带宽估计。

.. code-block:: c++

   // Pacer 请求 padding 时的调用链（简化）
   std::vector<std::unique_ptr<RtpPacketToSend>>
   RTPSender::GeneratePadding(size_t target_size_bytes,
                               bool media_has_been_sent) {
     std::vector<std::unique_ptr<RtpPacketToSend>> packets;

     // 优先使用 RTX 历史包作为 padding
     if (rtx_ssrc_ && media_has_been_sent) {
       while (target_size_bytes > 0) {
         auto packet = packet_history_->GetPayloadPaddingPacket();
         if (!packet) break;

         auto rtx_packet = BuildRtxPacket(*packet);
         if (rtx_packet) {
           rtx_packet->set_packet_type(
               RtpPacketMediaType::kPadding);
           target_size_bytes -= std::min(
               target_size_bytes, rtx_packet->size());
           packets.push_back(std::move(rtx_packet));
         }
       }
     }

     // 如果 RTX 历史包不够，使用纯 padding
     while (target_size_bytes > 0) {
       auto padding_packet = CreatePaddingPacket(target_size_bytes);
       target_size_bytes -= std::min(
           target_size_bytes, padding_packet->size());
       packets.push_back(std::move(padding_packet));
     }

     return packets;
   }

RTX Padding 的优势
-------------------------

* **更真实的探测** ：RTX padding 包的大小与真实媒体包相似，比纯 padding 更能反映真实的网络状况。
* **潜在的冗余恢复** ：如果原始包恰好丢失，RTX padding 包可以作为冗余恢复手段。
* **更好的中间设备兼容性** ：某些网络中间设备可能会丢弃纯 padding 包，但 RTX 包看起来像正常的 RTP 流量。


RTP Packet History
=========================

``RtpPacketHistory`` 是 WebRTC 中管理已发送 RTP 包历史记录的核心类。它为 NACK 重传和 RTX padding 提供数据源。

存储策略
-------------------------

``RtpPacketHistory`` 维护一个有序的包历史缓存，支持两种存储模式：

* **StorageMode::kDisabled** ：不存储任何包（RTX 未启用时）
* **StorageMode::kStoreAndCull** ：存储包并定期清理过期条目

每个存储的包记录包含以下信息：

.. code-block:: c++

   struct StoredPacket {
     // 完整的 RTP 包数据
     std::unique_ptr<RtpPacketToSend> packet;
     // 首次发送时间
     Timestamp send_time;
     // 包被请求重传的次数
     int times_retransmitted = 0;
     // 是否正在等待 pacer 发送（避免重复入队）
     bool pending_transmission = false;
   };

存储容量与清理
-------------------------

``RtpPacketHistory`` 的容量管理策略：

* **最大包数量** ：默认存储最近 600 个包。这个数量足以覆盖大多数 NACK 场景（考虑到 RTT 和丢包率）。

* **时间窗口** ：包的最大保留时间通常与 NACK 的最大等待时间一致。超过此时间的包会被清理。

* **清理触发** ：每次插入新包时检查是否需要清理旧包。清理策略是移除最旧的包，直到满足容量限制。

.. code-block:: c++

   void RtpPacketHistory::PutRtpPacket(
       std::unique_ptr<RtpPacketToSend> packet,
       Timestamp send_time) {
     RTC_DCHECK(googcc_mode_);

     // 存储包
     uint16_t seq_num = packet->SequenceNumber();
     packet_history_[seq_num] = StoredPacket{
         std::move(packet), send_time, 0, false};

     // 清理过期包
     while (packet_history_.size() > kMaxCapacity) {
       RemoveOldestPacket();
     }
   }

Padding 优先级策略
-------------------------

当 RTX 被用于带宽探测时，``RtpPacketHistory`` 需要选择合适的历史包作为 padding。WebRTC 实现了一个优先级策略（当 ``enable_rtx_padding_prioritization`` 为 true 时）：

1. **优先选择最近发送的包** ：最近发送的包更可能仍在网络路径的缓存中，重复发送的影响较小。

2. **避免频繁重传的包** ：已经被重传多次的包优先级较低，因为它们可能指示持续的网络问题。

3. **优先选择较大的包** ：较大的包能更有效地填充 padding 预算，减少包的数量。

4. **避免正在传输中的包** ：标记为 ``pending_transmission`` 的包不会被重复选择。

.. code-block:: c++

   std::unique_ptr<RtpPacketToSend>
   RtpPacketHistory::GetPayloadPaddingPacket() {
     if (padding_priority_.empty()) return nullptr;

     // 从优先级队列中取出最佳候选
     auto best_it = padding_priority_.begin();
     StoredPacket& best_packet = packet_history_[*best_it];

     if (best_packet.pending_transmission) return nullptr;

     best_packet.pending_transmission = true;
     return std::make_unique<RtpPacketToSend>(*best_packet.packet);
   }


RTX 与 FEC 的协同
=========================

在 WebRTC 中，RTX 和 FEC 并非互斥的，它们可以同时工作，互为补充。WebRTC 的媒体引擎会根据网络条件动态调整两者的使用策略。

决策因素
-------------------------

WebRTC 在选择丢包恢复策略时，主要考虑以下因素：

.. list-table:: RTX 与 FEC 的决策因素
   :header-rows: 1
   :widths: 20 40 40

   * - 因素
     - 倾向 RTX
     - 倾向 FEC
   * - RTT
     - RTT < 100ms
     - RTT > 200ms
   * - 丢包率
     - 丢包率 < 10%（重传成功率高）
     - 丢包率 > 15%（重传包也可能丢失）
   * - 可用带宽
     - 带宽有限（RTX 按需重传）
     - 带宽充足（FEC 需要额外冗余）
   * - 媒体类型
     - 视频流（包较大，FEC 开销高）
     - 音频流（包较小，FEC 开销可接受）
   * - 延迟要求
     - 延迟容忍度 > 1 RTT
     - 延迟容忍度极低

协同工作模式
-------------------------

在实际的 WebRTC 会话中，RTX 和 FEC 通常按以下方式协同工作：

1. **FEC 作为第一道防线** ：FEC 冗余包与原始包一起发送，可以立即恢复少量丢包，无需等待 RTT。

2. **RTX 作为第二道防线** ：当 FEC 无法恢复丢包时（丢包数超过冗余度），接收方发送 NACK，触发 RTX 重传。

3. **动态调整 FEC 冗余度** ：根据丢包率动态调整 FEC 的冗余比例。丢包率高时增加冗余，丢包率低时减少冗余以节省带宽。

4. **RTX 恢复的包可以辅助 FEC 解码** ：在某些情况下，RTX 恢复的包可以与 FEC 冗余包配合，恢复更多的丢失包。

.. code-block:: text

   网络条件变化时的策略切换示例：

   丢包率 2%, RTT 30ms:
     → FEC 冗余度: 5%
     → RTX: 启用（作为 FEC 失败时的后备）
     → 预期恢复率: ~99%

   丢包率 8%, RTT 80ms:
     → FEC 冗余度: 15%
     → RTX: 启用（主要恢复手段）
     → 预期恢复率: ~97%

   丢包率 20%, RTT 250ms:
     → FEC 冗余度: 30%
     → RTX: 降低优先级（重传包也容易丢失）
     → 可能触发降码率/降分辨率
     → 预期恢复率: ~85%

WebRTC 中的实现
-------------------------

在 WebRTC 的 ``RtpVideoSender`` 中，FEC 和 RTX 的配置是独立的：

.. code-block:: c++

   // RtpVideoSender 中 FEC 和 RTX 的配置
   void RtpVideoSender::ConfigureProtection() {
     // FEC 配置
     if (fec_enabled_) {
       // 根据丢包率设置 FEC 冗余度
       int fec_rate = protection_method_->FecRate(
           loss_rate_, rtt_ms_, bitrate_bps_);
       for (auto& rtp_stream : rtp_streams_) {
         rtp_stream.fec_generator->SetFecRate(fec_rate);
       }
     }

     // RTX 配置（独立于 FEC）
     if (rtx_enabled_) {
       for (auto& rtp_stream : rtp_streams_) {
         rtp_stream.rtp_rtcp->SetRtxSendStatus(kRtxRetransmitted);
       }
     }
   }

``VCMProtectionMethod`` 类负责根据网络条件选择最优的保护策略：

.. code-block:: c++

   // 保护策略选择的简化逻辑
   bool VCMNackFecMethod::EffectivePacketLoss(
       const VCMProtectionParameters* parameters) {
     // 计算 NACK + FEC 组合的有效丢包率
     // 考虑 RTT、丢包率、FEC 冗余度等因素
     float fec_residual_loss = ComputeFecResidualLoss(
         parameters->lossPr, parameters->fecRateDelta);
     float nack_residual_loss = ComputeNackResidualLoss(
         fec_residual_loss, parameters->rtt,
         parameters->maxNackRetries);
     return nack_residual_loss;
   }


性能分析
=========================

RTX 的使用会对系统性能产生多方面的影响。理解这些影响有助于在实际部署中做出合理的权衡。

带宽开销
-------------------------

RTX 的带宽开销取决于丢包率和重传成功率：

.. code-block:: text

   RTX 带宽开销 = 丢包率 × 原始码率 × (1 + 重传失败率)

   示例计算：
   原始视频码率: 2 Mbps
   丢包率: 5%
   重传失败率: 5%（重传包也可能丢失）

   RTX 带宽开销 = 5% × 2 Mbps × 1.05 = 105 kbps (约 5.25%)

相比之下，FEC 在相同丢包率下的带宽开销：

.. code-block:: text

   FEC 带宽开销 ≈ 丢包率 × 2 × 原始码率（经验值）

   FEC 带宽开销 = 5% × 2 × 2 Mbps = 200 kbps (约 10%)

可以看出，RTX 的带宽效率通常优于 FEC，因为它只重传实际丢失的包。

此外，RTX 用于 padding 时的带宽开销需要单独考虑。Padding 的带宽由拥塞控制算法决定，不属于 RTX 的额外开销。

延迟影响
-------------------------

RTX 引入的额外延迟主要由以下部分组成：

.. list-table:: RTX 延迟分解
   :header-rows: 1
   :widths: 30 30 40

   * - 延迟组成
     - 典型值
     - 说明
   * - 丢包检测延迟
     - 5-20ms
     - 等待乱序窗口，确认包确实丢失
   * - NACK 传输延迟
     - RTT/2
     - NACK 从接收方到发送方的传输时间
   * - 发送方处理延迟
     - 1-5ms
     - 查找历史包、构建 RTX 包
   * - Pacer 排队延迟
     - 0-50ms
     - RTX 包在 pacer 队列中等待发送
   * - RTX 传输延迟
     - RTT/2
     - RTX 包从发送方到接收方的传输时间
   * - **总计**
     - **约 1-1.5 RTT**
     - **典型场景下的端到端恢复延迟**

对于 RTT=50ms 的典型场景，RTX 恢复延迟约为 60-80ms。这对于视频流来说通常是可接受的（jitter buffer 通常有 100-200ms 的缓冲），但对于低延迟音频流可能过大。

恢复成功率
-------------------------

RTX 的恢复成功率受多个因素影响：

* **丢包模式** ：随机丢包时 RTX 恢复率高；突发丢包时，大量 NACK 可能导致拥塞加剧。

* **RTT** ：RTT 越大，NACK 到达发送方的时间越长，历史包可能已被清除。

* **历史缓存大小** ：缓存越大，能恢复的包越多，但内存开销也越大。

* **重传次数限制** ：默认最多重试 10 次，超过后放弃恢复。

典型场景下的恢复率估算：

.. code-block:: text

   场景 1: RTT=30ms, 丢包率=3%, 随机丢包
     → 首次 NACK 恢复率: ~97%
     → 二次 NACK 恢复率: ~99.9%
     → 总恢复率: ~99.9%

   场景 2: RTT=100ms, 丢包率=8%, 随机丢包
     → 首次 NACK 恢复率: ~92%
     → 二次 NACK 恢复率: ~99.4%
     → 总恢复率: ~99.4%

   场景 3: RTT=200ms, 丢包率=15%, 突发丢包
     → 首次 NACK 恢复率: ~85%
     → 二次 NACK 恢复率: ~97.8%
     → 总恢复率: ~95% (受 jitter buffer 超时影响)

常见问题与调优
-------------------------

**问题 1: NACK 风暴**

当网络突发丢包时，大量 NACK 可能导致网络拥塞加剧。解决方案：

* 限制 NACK 列表大小
* 在严重丢包时切换到关键帧请求（PLI/FIR）
* 配合拥塞控制降低发送码率

**问题 2: RTX 包与原始包竞争带宽**

RTX 包的发送会占用带宽，可能影响原始媒体流的发送。解决方案：

* 通过 pacer 统一调度原始包和 RTX 包
* RTX 包的优先级低于原始媒体包
* 总发送速率受拥塞控制限制

**问题 3: 历史缓存内存占用**

存储大量历史包会占用较多内存。解决方案：

* 合理设置缓存大小（根据 RTT 和丢包率）
* 及时清理过期包
* 对于高码率视频，可以只存储关键帧的包


重传请求
-------------------------
* NACK 可用来请求发送方重传


拥塞控制
-------------------------
拥塞导致丢包，丢包会重传，重传导致拥塞更严重，这样会生成恶性循环，所以需要考虑一个可接受的发送速率。

对于原始数据流和重传数据流的 packet rate 及 bitrate

* 总的传输速率必须控制在允许的带宽之内
* 在媒体质量要求很高的情况下，严重的拥塞需要降低原始流的发送速率之后再发送 RTX 包
* 某些环境下，比如无线网络，丢包并不是由拥塞导致的，发送 RTX 包是很用的


RTX Payload format MIME Type
-----------------------------------------
* rtx: Retransmission
* rtx-time
* apt: associated payload type 将重传的 payload type 和 RTX 的 payload type 关联起来


相关代码
=========================


* RtpConfig -> UlpfecConfig


.. code-block:: c++

  // Settings for ULPFEC forward error correction.
  // Set the payload types to '-1' to disable.
  struct UlpfecConfig {
    UlpfecConfig()
        : ulpfec_payload_type(-1),
          red_payload_type(-1),
          red_rtx_payload_type(-1) {}
    std::string ToString() const;
    bool operator==(const UlpfecConfig& other) const;

    // Payload type used for ULPFEC packets.
    int ulpfec_payload_type;

    // Payload type used for RED packets.
    int red_payload_type;

    // RTX payload type for RED payload.
    int red_rtx_payload_type;
  };


* RtpConfig -> RTX

.. code-block:: c++

  // Settings for RTP retransmission payload format, see RFC 4588 for
  // details.
  struct Rtx {
    Rtx();
    Rtx(const Rtx&);
    ~Rtx();
    std::string ToString() const;
    // SSRCs to use for the RTX streams.
    std::vector<uint32_t> ssrcs;

    // Payload type to use for the RTX stream.
    int payload_type = -1;
  } rtx;




* RtpRtcpInterface

.. code-block:: c++

  class RtpRtcpInterface : public RtcpFeedbackSenderInterface {
  public:
    //...

      struct Configuration {

        // Called when the receiver sends a loss notification.
        RtcpLossNotificationObserver* rtcp_loss_notification_observer = nullptr;

        // Called when we receive a changed estimate from the receiver of out
        // stream.
        RtcpBandwidthObserver* bandwidth_callback = nullptr;


        // If true, the RTP sender will always annotate outgoing packets with
        // MID and RID header extensions, if provided and negotiated.
        // If false, the RTP sender will stop sending MID and RID header extensions,
        // when it knows that the receiver is ready to demux based on SSRC. This is
        // done by RTCP RR acking.
        bool always_send_mid_and_rid = false;


        // If true, the RTP packet history will select RTX packets based on
        // heuristics such as send time, retransmission count etc, in order to
        // make padding potentially more useful.
        // If false, the last packet will always be picked. This may reduce CPU
        // overhead.
        bool enable_rtx_padding_prioritization = true;
      };


        // Turns on/off sending RTX (RFC 4588). The modes can be set as a combination
        // of values of the enumerator RtxMode.
        virtual void SetRtxSendStatus(int modes) = 0;

        // Returns status of sending RTX (RFC 4588). The returned value can be
        // a combination of values of the enumerator RtxMode.
        virtual int RtxSendStatus() const = 0;

        // Returns the SSRC used for RTX if set, otherwise a nullopt.
        virtual absl::optional<uint32_t> RtxSsrc() const = 0;

        // Sets the payload type to use when sending RTX packets. Note that this
        // doesn't enable RTX, only the payload type is set.
        virtual void SetRtxSendPayloadType(int payload_type,
                                          int associated_payload_type) = 0;


        // (REMB) Receiver Estimated Max Bitrate.
        // Schedules sending REMB on next and following sender/receiver reports.
        void SetRemb(int64_t bitrate_bps, std::vector<uint32_t> ssrcs) override = 0;
        // Stops sending REMB on next and following sender/receiver reports.
        void UnsetRemb() override = 0;

        // (NACK)

        // Sends NACK for the packets specified.
        // Note: This assumes the caller keeps track of timing and doesn't rely on
        // the RTP module to do this.
        virtual void SendNack(const std::vector<uint16_t>& sequence_numbers) = 0;

  }


Build RTX packet
-------------------------

.. code-block::


  std::unique_ptr<RtpPacketToSend> RTPSender::BuildRtxPacket(
      const RtpPacketToSend& packet) {
    std::unique_ptr<RtpPacketToSend> rtx_packet;

    // Add original RTP header.
    {
      MutexLock lock(&send_mutex_);
      if (!sending_media_)
        return nullptr;

      RTC_DCHECK(rtx_ssrc_);

      // Replace payload type.
      auto kv = rtx_payload_type_map_.find(packet.PayloadType());
      if (kv == rtx_payload_type_map_.end())
        return nullptr;

      rtx_packet = std::make_unique<RtpPacketToSend>(&rtp_header_extension_map_,
                                                    max_packet_size_);

      rtx_packet->SetPayloadType(kv->second);

      // Replace SSRC.
      rtx_packet->SetSsrc(*rtx_ssrc_);

      CopyHeaderAndExtensionsToRtxPacket(packet, rtx_packet.get());

      // RTX packets are sent on an SSRC different from the main media, so the
      // decision to attach MID and/or RRID header extensions is completely
      // separate from that of the main media SSRC.
      //
      // Note that RTX packets must used the RepairedRtpStreamId (RRID) header
      // extension instead of the RtpStreamId (RID) header extension even though
      // the payload is identical.
      if (always_send_mid_and_rid_ || !rtx_ssrc_has_acked_) {
        // These are no-ops if the corresponding header extension is not
        // registered.
        if (!mid_.empty()) {
          rtx_packet->SetExtension<RtpMid>(mid_);
        }
        if (!rid_.empty()) {
          rtx_packet->SetExtension<RepairedRtpStreamId>(rid_);
        }
      }
    }
    RTC_DCHECK(rtx_packet);

    uint8_t* rtx_payload =
        rtx_packet->AllocatePayload(packet.payload_size() + kRtxHeaderSize);
    if (rtx_payload == nullptr)
      return nullptr;

    // Add OSN (original sequence number).
    ByteWriter<uint16_t>::WriteBigEndian(rtx_payload, packet.SequenceNumber());

    // Add original payload data.
    auto payload = packet.payload();
    memcpy(rtx_payload + kRtxHeaderSize, payload.data(), payload.size());

    // Add original additional data.
    rtx_packet->set_additional_data(packet.additional_data());

    // Copy capture time so e.g. TransmissionOffset is correctly set.
    rtx_packet->set_capture_time(packet.capture_time());

    return rtx_packet;
  }


参考资料
=========================
* RFC4588: `RTP Retransmission Payload Format`_
* RFC4585: `Extended RTP Profile for RTCP-Based Feedback`_
* RFC2354: `Options for Repair of Streaming Media`_
* RFC2198: RED - Redundant Audio Data
* `Implement RTX for WebRTC`_
* `WebRTC Source - RtpPacketHistory`_
* `WebRTC Source - NackRequester`_
* `WebRTC Source - RTPSender`_
* `WebRTC Source - RtpVideoSender`_


.. _Implement RTX for WebRTC: https://bugzilla.mozilla.org/show_bug.cgi?id=1164187
.. _RTP Retransmission Payload Format: https://tools.ietf.org/html/rfc4588
.. _Extended RTP Profile for RTCP-Based Feedback: https://datatracker.ietf.org/doc/html/rfc4585
.. _Options for Repair of Streaming Media: https://datatracker.ietf.org/doc/html/rfc2354
.. _WebRTC Source - RtpPacketHistory: https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/rtp_rtcp/source/rtp_packet_history.h
.. _WebRTC Source - NackRequester: https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/video_coding/nack_requester.h
.. _WebRTC Source - RTPSender: https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/rtp_rtcp/source/rtp_sender.h
.. _WebRTC Source - RtpVideoSender: https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/call/rtp_video_sender.h
