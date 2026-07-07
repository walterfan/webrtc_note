##############################
WebRTC Packet Buffer
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Packet Buffer
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=============

从网络上收到的 RTP 包可能会丢失、乱序或延迟到达。
为了在不稳定的网络条件下保证音视频播放的流畅性，接收端需要缓冲区（Jitter Buffer）来：

- 重新排序乱序的 RTP 包
- 等待延迟到达的包（在一定时间窗口内）
- 组装完整的视频帧（从多个 RTP 包中）
- 为丢包恢复（NACK/FEC）提供时间

.. code-block:: text

   网络      →    Packet Buffer    →    解码器
   (乱序/丢包)    (排序/组帧/等待)      (完整帧)

   RTP 包流:  [3] [1] [5] [2] [4]
                      ↓
   排序后:    [1] [2] [3] [4] [5]
                      ↓
   组帧:      [Frame 1: pkt 1,2,3] [Frame 2: pkt 4,5]


视频 Packet Buffer
===========================

视频帧通常由多个 RTP 包组成（一个 1080p 关键帧可能拆分为几十个 RTP 包）。
视频 Packet Buffer 需要将这些包重新组装为完整的帧。

关键类
--------------------------

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - 类
     - 说明
   * - ``PacketBuffer``
     - 通用视频包缓冲区，负责收集 RTP 包并按序号排列，检测帧边界后组装为完整帧
   * - ``H264PacketBuffer``
     - H.264 专用扩展，处理 H.264 特有的分片（FU-A）和聚合（STAP-A）NAL 单元
   * - ``RtpFrameReferenceFinder``
     - 建立帧间参考关系（I/P/B 帧依赖），确定帧的解码顺序

PacketBuffer 工作流程
--------------------------

.. code-block:: text

   RTP 包到达
       │
       ▼
   ┌─────────────────────────┐
   │  按序号插入环形缓冲区    │
   │  (大小通常 2048 个槽位)  │
   └────────┬────────────────┘
            │
            ▼
   ┌─────────────────────────┐
   │  检测帧边界              │
   │  (RTP Marker bit = 1    │
   │   表示帧的最后一个包)    │
   └────────┬────────────────┘
            │
            ▼
   ┌─────────────────────────┐
   │  向前搜索帧的第一个包    │
   │  (检查序号连续性)        │
   └────────┬────────────────┘
            │
       ┌────┴────┐
       │完整?    │不完整
       ▼         ▼
   组装帧输出   等待/请求 NACK

核心代码逻辑：

.. code-block:: c++

   // 简化的 PacketBuffer 插入逻辑
   InsertResult PacketBuffer::InsertPacket(std::unique_ptr<Packet> packet) {
       uint16_t seq_num = packet->seq_num;
       size_t index = seq_num % buffer_size_;

       buffer_[index] = std::move(packet);

       // 如果 Marker bit 为 1，尝试向前找到帧的起始包
       if (buffer_[index]->marker_bit) {
           return FindFrames(seq_num);
       }
       return InsertResult();
   }


音频 Jitter Buffer
===========================

音频的 Jitter Buffer 通常独立于视频，因为音频帧较小（一个 Opus 帧通常只有一个 RTP 包）
且对延迟更敏感。

WebRTC 中音频 Jitter Buffer 的核心实现是 **NetEQ**，它不仅负责缓冲，
还集成了丢包隐藏（PLC）、加速播放、减速播放等功能。

详细内容参见 :doc:`../5.qos/audio_jitter_buffer` 和 :doc:`../5.qos/neteq_deep_dive`。


关键参数
===========================

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 参数
     - 说明
   * - Buffer 大小
     - 环形缓冲区槽位数，默认 2048。过小会导致帧不完整，过大会增加内存占用
   * - 最大等待时间
     - 等待缺失包的最长时间。超时后放弃等待，触发 NACK 或 PLC
   * - 解码顺序
     - 视频帧需要按解码顺序（DTS）输出，而非按到达顺序（PTS 可能不同）


参考资料
===========================

- `PacketBuffer 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/video_coding/packet_buffer.h>`_
- `H264PacketBuffer 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/video_coding/h264_packet_buffer.h>`_
- `RtpFrameReferenceFinder 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/video_coding/rtp_frame_reference_finder.h>`_
