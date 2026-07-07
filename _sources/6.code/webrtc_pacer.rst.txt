##############################
WebRTC Pacer
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Pacer 发送节奏控制
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=============

Pacer（发送节奏控制器）是 WebRTC 拥塞控制中的关键组件。
它的核心作用是**将突发的编码输出平滑为均匀的发送速率**，避免网络瞬时拥塞。

没有 Pacer 的话，编码器输出一个关键帧（可能 50KB+）会一次性将所有 RTP 包发送出去，
造成网络突发拥塞和丢包。Pacer 则将这些包排入队列，按照目标比特率匀速发送。

.. code-block:: text

   编码器输出（突发）                    Pacer 输出（平滑）

   ┃█████████████┃                    ┃██ ██ ██ ██ ██ ██ ██┃
   ┃             ┃                    ┃                     ┃
   ┃    ████     ┃                    ┃██ ██ ██ ██          ┃
   ┃  ██    ██   ┃       ──►         ┃██ ██ ██ ██          ┃
   ┃██        ██ ┃                    ┃██ ██ ██ ██          ┃
   ━━━━━━━━━━━━━━━ 时间               ━━━━━━━━━━━━━━━━━━━━━━ 时间


在 WebRTC 中的位置
========================

.. code-block:: text

   编码器 → RTP 打包 → Pacer 队列 → SRTP 加密 → ICE/UDP 发送
                            ↑
                     GCC 带宽估计 → 设定发送速率


核心类
=============

PacingController
-----------------------

``PacingController`` 实现了 Leaky Bucket（漏桶）算法，是 Pacer 的核心逻辑：

- 维护一个按优先级排序的包队列
- 按照设定的发送速率（pacing rate）释放包
- 处理不同类型包的优先级调度

关键方法：

.. code-block:: c++

   class PacingController {
   public:
       // 将包加入发送队列
       void EnqueuePacket(std::unique_ptr<RtpPacketToSend> packet);

       // 处理定时器触发，发送到期的包
       void ProcessPackets();

       // 设置发送速率（由 GCC 算法决定）
       void SetPacingRates(DataRate pacing_rate, DataRate padding_rate);

       // 设置是否允许探测式发送
       void SetProbingEnabled(bool enabled);

       // 暂停/恢复发送
       void Pause();
       void Resume();
   };

RtpPacketPacer
---------------------------

``TaskQueuePacedSender`` (旧版中为 ``RtpPacketPacer``) 是 Pacer 的外层封装，
负责定时器调度和实际的包发送：

主要调用链：

.. code-block:: text

   TaskQueuePacedSender::EnqueuePackets()
     → PacingController::EnqueuePacket()

   TaskQueuePacedSender::MaybeProcessPackets()  (定时器触发)
     → PacingController::ProcessPackets()
       → PacketRouter::SendPacket()
         → ModuleRtpRtcpImpl::TrySendPacket()


包类型与优先级
==============

Pacer 按照包类型分配不同的发送优先级：

.. code-block:: c++

   static constexpr size_t kNumMediaTypes = 5;
   enum class RtpPacketMediaType : size_t {
       kAudio,                         // 音频包 (最高优先级)
       kVideo,                         // 视频包
       kRetransmission,                // 重传包 (响应 NACK)
       kForwardErrorCorrection,        // FEC 包
       kPadding = kNumMediaTypes - 1,  // 填充包 (最低优先级)
   };

发送优先级从高到低：

.. list-table::
   :header-rows: 1
   :widths: 10 25 65

   * - 优先级
     - 类型
     - 说明
   * - 1
     - Audio
     - 音频包始终最高优先级，确保语音流畅
   * - 2
     - Retransmission
     - NACK 重传包需要快速发送以降低恢复延迟
   * - 3
     - Video
     - 正常视频包
   * - 4
     - FEC
     - 前向纠错冗余包
   * - 5
     - Padding
     - 填充包，用于维持带宽估计探测


发送速率控制
==============

Pacer 的发送速率由 GCC（Google Congestion Control）算法决定：

.. code-block:: text

   GCC 估计可用带宽
       │
       ▼
   设定 pacing_rate = estimated_bitrate × multiplier (通常 2.5x)
       │
       ▼
   Pacer 按照 pacing_rate 匀速发送队列中的包
       │
       ▼
   如果队列为空且带宽有富余 → 发送 padding 包以探测更高带宽

关键参数：

- **Pacing rate**：通常是目标比特率的 2.5 倍（允许突发恢复，同时不过度占用带宽）
- **Padding rate**：当没有媒体数据时的填充发送速率，用于保持带宽估计准确
- **Max queue time**：队列中包的最大等待时间（默认 2 秒），超过则丢弃

.. code-block:: c++

   // 典型配置
   pacer->SetPacingRates(
       DataRate::KilobitsPerSec(2500),   // pacing rate: 2.5 Mbps
       DataRate::KilobitsPerSec(200));    // padding rate: 200 kbps


Probe 探测
==============

Pacer 还负责带宽探测（Probing）。在连接初期或带宽变化时，
GCC 会要求 Pacer 以特定速率发送探测包来估算可用带宽：

.. code-block:: text

   连接建立
     │
     ▼
   Probe Cluster 1: 以 900 kbps 发送 5 个包
     │
     ▼
   Probe Cluster 2: 以 1800 kbps 发送 5 个包
     │
     ▼
   根据接收端反馈（TWCC）计算实际可用带宽
     │
     ▼
   进入正常 GCC 速率控制

探测包优先使用排队中的媒体包，只在媒体包不足时才补充 padding。


与 GCC 的协作
==============

.. code-block:: text

   ┌─────────────┐     ┌──────────────┐     ┌─────────────┐
   │  Encoder    │     │    Pacer     │     │   Network   │
   │             │     │              │     │             │
   │ 输出 RTP 包 ──────► 排队 + 调度  ──────► 发送        │
   │             │     │     ↑        │     │             │
   └─────────────┘     │  设定速率    │     └──────┬──────┘
                       │     ↑        │            │
                       └─────┼────────┘            │
                             │                     │
                       ┌─────┴────────┐     ┌──────▼──────┐
                       │     GCC      │     │  Receiver   │
                       │              │◄────│  TWCC/REMB  │
                       │ 估计可用带宽  │     │  反馈       │
                       └──────────────┘     └─────────────┘


参考资料
========================

- WebRTC 源码: ``modules/pacing/`` 目录
- `PacingController <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/pacing/pacing_controller.h>`_
- `TaskQueuePacedSender <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/pacing/task_queue_paced_sender.h>`_
- `GCC Draft <https://datatracker.ietf.org/doc/html/draft-ietf-rmcat-gcc>`_
