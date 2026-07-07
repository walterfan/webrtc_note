##############################
WebRTC NACK 实现
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC NACK 丢包重传机制
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
======================================

NACK（Negative Acknowledgement）是 WebRTC 中最基本的丢包恢复机制。
当接收端检测到 RTP 包丢失时，通过 RTCP NACK 消息通知发送端重传丢失的包。

.. code-block:: text

   发送端                                    接收端
     │                                         │
     │── RTP seq=100 ─────────────────────────►│
     │── RTP seq=101 ────── ✗ 丢失              │
     │── RTP seq=102 ─────────────────────────►│
     │                                         │ 检测到 seq=101 缺失
     │◄── RTCP NACK (seq=101) ────────────────│
     │                                         │
     │── RTP seq=101 (重传) ─────────────────►│
     │                                         │ 恢复完整

相比 FEC（前向纠错），NACK 的优势是不浪费带宽（只在丢包时重传），
劣势是增加至少一个 RTT 的延迟。


RTCP NACK 包格式
======================================

NACK 使用 RTCP 反馈消息（RFC 4585），格式如下：

.. code-block:: text

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P|  FMT=1  |   PT=205     |          length               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of packet sender                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of media source                         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |          PID (丢失包序号)      |        BLP (位掩码)           |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

- **PID**：丢失包的序号
- **BLP**：位掩码，指示 PID 之后的 16 个包中哪些也丢失了（1 个 NACK FCI 可报告最多 17 个丢包）


核心类
======================================

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - 类
     - 说明
   * - ``NackRequester``
     - 接收端 NACK 请求生成器，维护 nack_list，检测丢包并决定何时发送 NACK
   * - ``NackModule2``
     - NackRequester 的别名/演化版本
   * - ``RtpPacketHistory``
     - 发送端包历史缓冲区，保存已发送的 RTP 包以备重传
   * - ``RTCPSender``
     - 发送 RTCP NACK 消息
   * - ``RTCPReceiver``
     - 解析收到的 RTCP NACK 消息


NackRequester 工作流程
======================================

.. code-block:: text

   RTP 包到达
       │
       ▼
   OnReceivedPacket(seq_num)
       │
       ├── seq_num == newest? → 忽略（重复包）
       │
       ├── seq_num < newest? → 乱序到达
       │   └── 从 nack_list_ 中移除（已恢复）
       │       └── 返回该包被 NACK 的次数
       │
       └── seq_num > newest? → 新包
           ├── 将 (newest+1, seq_num) 之间的缺失包加入 nack_list_
           ├── 更新 newest_seq_num_
           └── 触发 GetNackBatch() 发送 NACK

关键源码：

.. code-block:: c++

   int NackRequester::OnReceivedPacket(uint16_t seq_num,
                                       bool is_keyframe,
                                       bool is_recovered) {
       RTC_DCHECK_RUN_ON(worker_thread_);
       bool is_retransmitted = true;

       if (!initialized_) {
           newest_seq_num_ = seq_num;
           if (is_keyframe)
               keyframe_list_.insert(seq_num);
           initialized_ = true;
           return 0;
       }

       if (seq_num == newest_seq_num_)
           return 0;

       if (AheadOf(newest_seq_num_, seq_num)) {
           // 乱序包到达 — 从 nack_list 中移除
           auto nack_list_it = nack_list_.find(seq_num);
           int nacks_sent_for_packet = 0;
           if (nack_list_it != nack_list_.end()) {
               nacks_sent_for_packet = nack_list_it->second.retries;
               nack_list_.erase(nack_list_it);
           }
           if (!is_retransmitted)
               UpdateReorderingStatistics(seq_num);
           return nacks_sent_for_packet;
       }

       if (is_keyframe)
           keyframe_list_.insert(seq_num);

       // 清理过旧的关键帧记录
       auto it = keyframe_list_.lower_bound(seq_num - kMaxPacketAge);
       if (it != keyframe_list_.begin())
           keyframe_list_.erase(keyframe_list_.begin(), it);

       // FEC/RTX 恢复的包不需要 NACK
       if (is_recovered) {
           recovered_list_.insert(seq_num);
           auto it = recovered_list_.lower_bound(seq_num - kMaxPacketAge);
           if (it != recovered_list_.begin())
               recovered_list_.erase(recovered_list_.begin(), it);
           return 0;
       }

       // 将缺失的序号加入 nack_list
       AddPacketsToNack(newest_seq_num_ + 1, seq_num);
       newest_seq_num_ = seq_num;

       // 立即发送一批 NACK
       std::vector<uint16_t> nack_batch = GetNackBatch(kSeqNumOnly);
       if (!nack_batch.empty()) {
           nack_sender_->SendNack(nack_batch, /*buffering_allowed=*/true);
       }

       return 0;
   }


NACK 重试与限制
======================================

NackRequester 对每个丢失包的 NACK 请求有限制，避免无效重传浪费带宽：

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - 参数
     - 说明
   * - ``kMaxNackRetries``
     - 单个包最大 NACK 重试次数（默认 10 次）
   * - ``kMaxPacketAge``
     - 包的最大年龄（序号差），超过后不再 NACK
   * - ``kMaxNackPackets``
     - nack_list 最大长度，超过后清空并请求关键帧
   * - NACK 间隔
     - 基于 RTT 计算，避免在 RTT 内重复 NACK 同一个包

当 nack_list 过大时（连续大量丢包），说明网络状况极差，此时 NACK 重传已无意义，
WebRTC 会转为请求关键帧（PLI/FIR），重新同步视频流。


发送端：RtpPacketHistory
======================================

发送端需要缓存已发送的 RTP 包，以便收到 NACK 后能重传：

.. code-block:: c++

   class RtpPacketHistory {
   public:
       // 存储已发送的包
       void PutRtpPacket(std::unique_ptr<RtpPacketToSend> packet,
                         Timestamp send_time);

       // 根据序号取出包用于重传
       std::unique_ptr<RtpPacketToSend> GetPacketAndMarkAsPending(
           uint16_t sequence_number);

       // 设置历史缓冲区大小（包数量）
       void SetStorePacketsStatus(StorageMode mode,
                                  uint16_t number_to_store);
   };

重传的包通常通过 RTX（Retransmission）通道发送，使用独立的 SSRC 和 PT，
避免与原始流混淆。详见 :doc:`webrtc_rtx_code`。


NACK 与其他丢包恢复的协同
======================================

.. code-block:: text

   丢包检测
       │
       ├── FEC 能恢复？ ──► 直接恢复，不发 NACK
       │
       ├── RTX 重传 ──► 通过 NACK 触发，独立 SSRC 发送
       │
       └── 都无法恢复 ──► 请求关键帧 (PLI/FIR)

WebRTC 的策略是优先使用 FEC 恢复（零延迟），FEC 无法恢复时使用 NACK 请求重传，
大面积丢包时退化为请求关键帧。


在 JavaScript 中观察 NACK
======================================

.. code-block:: javascript

   const stats = await pc.getStats();
   stats.forEach(report => {
       if (report.type === 'inbound-rtp') {
           console.log('nackCount:', report.nackCount);
           console.log('packetsLost:', report.packetsLost);
           console.log('packetsReceived:', report.packetsReceived);
       }
       if (report.type === 'outbound-rtp') {
           console.log('nackCount:', report.nackCount);
           console.log('retransmittedPacketsSent:', report.retransmittedPacketsSent);
           console.log('retransmittedBytesSent:', report.retransmittedBytesSent);
       }
   });


参考资料
======================================

- `NackRequester 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/video_coding/nack_requester.h>`_
- `RtpPacketHistory 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/rtp_rtcp/source/rtp_packet_history.h>`_
- RFC 4585: Extended RTP Profile for RTCP-Based Feedback (RTP/AVPF)
