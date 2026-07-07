########################
WebRTC Feedback
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Feedback
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:


简介
=========================

在 WebRTC 实时通信中，RTCP (Real-time Transport Control Protocol) 反馈机制是保障音视频质量的核心手段。
发送端需要根据接收端的反馈信息来调整编码策略、码率和重传行为，从而在不断变化的网络条件下维持尽可能好的用户体验。

RTCP 反馈消息定义在 RFC 4585 (Extended RTP Profile for RTCP-Based Feedback, RTP/AVPF) 中，
它扩展了原始的 RTP/AVP profile，允许接收端在不等待常规 RTCP 报告间隔的情况下，及时地向发送端反馈信息。

这些反馈消息按照功能分为三大类：

   - **Transport layer FB messages (RTPFB, PT=205)** — 传输层的反馈消息，关注 RTP 包的传输状态
   - **Payload-specific FB messages (PSFB, PT=206)** — 特定荷载的反馈消息，关注媒体编码层面的问题
   - **Application layer FB messages (APPFB, PT=207)** — 应用层的反馈消息，用于应用自定义的反馈


RTCP FB 通用包格式
=========================

所有 RTCP 反馈消息共享以下通用包格式：

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P|   FMT   |       PT      |          length               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of packet sender                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of media source                         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   :            Feedback Control Information (FCI)                 :
   :                                                               :

           Figure 3: Common Packet Format for Feedback Messages

各字段含义如下：

- **V (Version)**: 固定为 2
- **P (Padding)**: 填充标志位
- **FMT (Feedback Message Type)**: 反馈消息子类型，不同的 FMT 值代表不同的反馈消息
- **PT (Payload Type)**: 荷载类型，区分传输层、荷载特定和应用层反馈
- **length**: 以 32-bit 字为单位的包长度（不含首个 32-bit 字）
- **SSRC of packet sender**: 发送此 RTCP 反馈包的参与者的 SSRC
- **SSRC of media source**: 被反馈的媒体源的 SSRC
- **FCI**: 反馈控制信息，具体内容取决于 FMT 和 PT 的组合

PT 荷载类型有如下分类：

.. code-block::

            Name   | Value | Brief Description
         ----------+-------+------------------------------------
            RTPFB  |  205  | Transport layer FB message
            PSFB   |  206  | Payload-specific FB message
            APPFB  |  207  | Application-specific FB message


传输层反馈消息 (Transport Layer FB)
=============================================

传输层反馈消息 (PT=205, RTPFB) 关注的是 RTP 包在网络传输过程中的状态，
主要用于丢包通知和码率控制。

Generic NACK (FMT=1)
-----------------------------

Generic NACK (Negative Acknowledgement) 是最基本的丢包反馈机制。
当接收端检测到 RTP 包丢失时，会发送 NACK 消息通知发送端进行重传。

NACK 的 FCI 格式如下：

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |            PID                |             BLP               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

- **PID (Packet ID, 16 bits)**: 丢失的 RTP 包的序列号。这是触发 NACK 的第一个丢失包。
- **BLP (Bitmask of Lost Packets, 16 bits)**: 位掩码，表示 PID 之后连续 16 个包的丢失情况。
  BLP 的第 i 位 (i=0..15) 为 1 表示序列号为 PID+i+1 的包也丢失了。

因此，一个 NACK FCI 条目最多可以报告 17 个连续丢失的包（PID 本身加上 BLP 中的 16 个）。
一个 NACK 消息可以包含多个 FCI 条目，以报告不连续的丢包区间。

**工作流程：**

1. 接收端维护一个 RTP 序列号的接收记录
2. 当检测到序列号间隙（gap）时，等待一小段时间（通常为一个 RTT 的一部分）以应对乱序到达
3. 如果等待超时后包仍未到达，发送 NACK 消息
4. 发送端收到 NACK 后，从重传缓冲区（retransmission buffer）中取出对应的包进行重传
5. 重传的包通常通过 RTX (Retransmission) 流发送，使用不同的 SSRC 和 PT

**注意事项：**

- NACK 重传会引入额外的延迟（至少一个 RTT）
- 在高丢包率场景下，大量 NACK 和重传可能加剧拥塞
- WebRTC 中通常对 NACK 重传次数有限制（如最多重传 10 次）
- 对于实时性要求极高的场景（如超低延迟直播），NACK 重传可能不适用


TMMBR/TMMBN (FMT=3/FMT=4)
-----------------------------

TMMBR (Temporary Maximum Media Stream Bit Rate Request) 和 TMMBN (Temporary Maximum Media Stream Bit Rate Notification)
定义在 RFC 5104 中，用于接收端请求发送端临时限制媒体流的最大码率。

**TMMBR (FMT=3)** 的工作流程：

1. 接收端根据自身的处理能力或下行带宽限制，计算出期望的最大码率
2. 发送 TMMBR 消息给发送端，携带期望的最大码率值和 overhead 信息
3. 发送端收到后，调整编码码率不超过请求的值

**TMMBN (FMT=4)** 是发送端对 TMMBR 的确认响应：

1. 发送端收到一个或多个 TMMBR 后，选择最小的码率限制
2. 发送 TMMBN 消息通知所有接收端当前生效的码率限制

TMMBR FCI 格式：

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                              SSRC                             |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   | MxTBR Exp |  MxTBR Mantissa                 |Measured Overhead|
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

- **MxTBR Exp (6 bits)** 和 **MxTBR Mantissa (17 bits)**: 共同表示最大码率，
  计算公式为 ``MxTBR = MxTBR Mantissa * 2^MxTBR Exp`` (单位: bps)
- **Measured Overhead (9 bits)**: 每个包的平均 overhead（IP/UDP/RTP 头部等）


Transport-wide CC Feedback (FMT=15)
-----------------------------------------

Transport-wide Congestion Control (transport-cc) 是 Google 提出的一种传输层反馈机制，
定义在 draft-holmer-rmcat-transport-wide-cc-extensions 中。
它是 WebRTC 中 GCC (Google Congestion Control) 算法的核心组成部分。

与传统的基于 RTCP RR 的丢包率和 jitter 统计不同，transport-cc 提供了每个 RTP 包的精确到达时间信息，
使得发送端可以进行更精细的带宽估计。

**核心思想：**

1. 发送端为每个 RTP 包分配一个 transport-wide sequence number（通过 RTP header extension 携带）
2. 接收端记录每个包的到达时间
3. 接收端定期（通常每 100ms）发送 transport-cc feedback 包，汇报一批包的接收状态和到达时间

**RTP Header Extension 格式：**

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |       0xBE    |    0xDE       |           length=1            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ID   | L=1   |transport-wide sequence number  |   padding   |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

transport-wide sequence number 是一个 16-bit 的值，在所有媒体流（音频和视频）之间共享递增。

**Feedback 包格式 (PT=205, FMT=15)：**

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P|  FMT=15 |   PT=205      |          length               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of packet sender                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of media source                         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      base sequence number     |      packet status count      |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                 reference time                | fb pkt. count |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |          packet chunk         |         packet chunk          |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   .                                                               .
   .                                                               .
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |         recv delta            |        recv delta             |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   .                                                               .
   .                                                               .
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

关键字段说明：

- **base sequence number**: 本次反馈覆盖的起始 transport-wide sequence number
- **packet status count**: 本次反馈覆盖的包数量
- **reference time**: 参考时间戳，以 64ms 为单位
- **fb pkt. count**: 反馈包计数器，用于检测反馈包丢失
- **packet chunk**: 使用 run-length 或 status vector 编码的包接收状态
- **recv delta**: 相邻包到达时间的差值，以 250μs 为单位

**Packet Status 编码：**

每个包的状态用 1-bit 或 2-bit 表示：

- ``00``: 未收到 (not received)
- ``01``: 收到，小 delta (received, small delta, 1 byte recv delta)
- ``10``: 收到，大 delta (received, large or negative delta, 2 bytes recv delta)
- ``11``: 保留

**发送端如何使用 transport-cc feedback：**

发送端收到 feedback 后，可以重建每个包的发送时间和到达时间序列，
然后使用 delay-based 算法（如 GCC 中的 Trendline Filter）来估计可用带宽：

1. 计算相邻包的 inter-departure time（发送间隔）和 inter-arrival time（到达间隔）
2. 计算 delay gradient: ``delta = inter_arrival - inter_departure``
3. 使用 Trendline Filter 对 delay gradient 序列进行线性回归
4. 如果趋势线斜率为正，说明网络拥塞加剧，需要降低码率
5. 如果趋势线斜率为零或负，说明网络状况良好，可以尝试提高码率


荷载特定反馈消息 (Payload-Specific FB)
=============================================

荷载特定反馈消息 (PT=206, PSFB) 关注的是媒体编码层面的问题，
主要用于通知发送端视频解码出现了问题，需要采取相应的编码措施。

PLI — Picture Loss Indication (FMT=1)
-----------------------------------------

PLI (Picture Loss Indication) 定义在 RFC 4585 中，用于通知发送端接收端的解码器丢失了一个或多个完整的视频帧，
导致解码器无法正确解码后续帧。

PLI 消息没有额外的 FCI 字段，它只是一个简单的信号：

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P|  FMT=1  |   PT=206      |          length=2             |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of packet sender                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of media source                         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

**触发条件：**

- 接收端检测到一个或多个视频帧的 RTP 包丢失，且无法通过 NACK 重传恢复
- 解码器因为参考帧缺失而无法继续正确解码
- 长时间未收到关键帧，解码器状态不确定

**发送端响应：**

收到 PLI 后，编码器通常会生成一个关键帧（I-frame / IDR frame），
使接收端的解码器可以从该关键帧重新开始解码，无需依赖之前的参考帧。

**注意事项：**

- 关键帧通常比 P 帧大 5-10 倍，频繁的 PLI 会导致码率波动
- WebRTC 中通常会对 PLI 请求进行节流（throttling），避免过于频繁地生成关键帧
- Chrome/libwebrtc 中默认的 PLI 最小间隔约为 300ms


SLI — Slice Loss Indication (FMT=2)
-----------------------------------------

SLI (Slice Loss Indication) 定义在 RFC 4585 中，提供比 PLI 更精细的丢失信息。
它可以指出具体丢失的是哪些 macroblock（宏块）区域，而不是笼统地报告整帧丢失。

SLI FCI 格式：

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |         First          |        Number           | PictureID |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

- **First (13 bits)**: 丢失区域中第一个宏块的地址（按光栅扫描顺序）
- **Number (13 bits)**: 连续丢失的宏块数量
- **PictureID (6 bits)**: 丢失宏块所属图片的时间参考（低 6 位）

**使用场景：**

SLI 在实际 WebRTC 实现中使用较少，因为：

1. 现代视频编码器（如 VP8/VP9/AV1）不使用传统的 macroblock 概念
2. PLI 和 FIR 已经能满足大多数场景的需求
3. 编码器通常不支持仅刷新部分区域的精细控制


RPSI — Reference Picture Selection Indication (FMT=3)
---------------------------------------------------------

RPSI (Reference Picture Selection Indication) 定义在 RFC 4585 中，
用于接收端通知发送端某个特定的参考帧已经被正确解码，
发送端可以使用该帧作为后续编码的参考帧。

RPSI FCI 格式：

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      PB       |0| Payload Type|    Native RPSI bit string     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |   defined per codec          ...                | Padding (0) |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

- **PB (8 bits)**: 填充位数
- **Payload Type (7 bits)**: 对应的 RTP payload type
- **Native RPSI bit string**: 编解码器特定的参考帧标识信息

**工作原理：**

1. 接收端成功解码某个帧后，发送 RPSI 告知发送端该帧可用作参考
2. 发送端在编码后续帧时，选择该帧作为参考帧，而不是使用可能已丢失的最近帧
3. 这样可以避免错误传播（error propagation），无需发送完整的关键帧

**优势：**

- 比 PLI/FIR 更高效，因为不需要生成完整的关键帧
- 可以在保持较低码率的同时恢复解码状态

**局限：**

- 需要编码器支持灵活的参考帧选择
- 在 WebRTC 中实际使用较少，VP8/VP9 更倾向于使用 PLI + 关键帧的方式


FIR — Full Intra Request (FMT=4)
-----------------------------------------

FIR (Full Intra Request) 定义在 RFC 5104 中，用于请求发送端生成一个完整的关键帧。
与 PLI 不同，FIR 不仅仅是因为丢包，还可能是因为新的接收端加入（如 SFU 场景中新用户加入会议）。

FIR FCI 格式：

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                              SSRC                             |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   | Seq nr.       |    Reserved                                   |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

- **SSRC (32 bits)**: 请求关键帧的媒体源 SSRC
- **Seq nr. (8 bits)**: 命令序列号，每次新的 FIR 请求递增，用于去重

**FIR vs PLI 的区别：**

.. list-table:: FIR 与 PLI 的对比
   :header-rows: 1
   :widths: 30 35 35

   * - 特性
     - PLI
     - FIR
   * - 定义
     - RFC 4585
     - RFC 5104
   * - 触发原因
     - 帧丢失导致解码失败
     - 需要关键帧（不一定因为丢包）
   * - 典型场景
     - 丢包恢复
     - 新用户加入、录制开始
   * - FCI
     - 无
     - 包含 SSRC 和序列号
   * - 语义
     - "我丢了帧，请帮忙"
     - "请立即发送关键帧"


REMB — Receiver Estimated Maximum Bitrate
=============================================

REMB (Receiver Estimated Maximum Bitrate) 是 Google 提出的一种 RTCP 反馈消息，
用于接收端将其估计的最大可用带宽通知给发送端。REMB 使用 PSFB (PT=206) 的 Application layer FB (FMT=15)。

.. note::

   REMB 已经逐渐被 transport-cc 取代。在较新的 WebRTC 实现中，
   带宽估计主要在发送端完成（sender-side BWE），使用 transport-cc feedback。
   但 REMB 在一些旧的实现和 SFU 中仍然被使用。

REMB 包格式：

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P| FMT=15  |   PT=206      |             length            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of packet sender                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                  SSRC of media source (unused)                |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  Unique identifier 'R' 'E' 'M' 'B'                           |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  Num SSRC     | BR Exp    |  BR Mantissa                      |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |   SSRC feedback                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ...                                                          |

- **Unique identifier**: 固定为 ASCII 字符 "REMB"
- **Num SSRC (8 bits)**: 后续 SSRC 列表的数量
- **BR Exp (6 bits)** 和 **BR Mantissa (18 bits)**: 估计的最大码率，
  计算公式为 ``bitrate = BR Mantissa * 2^BR Exp`` (单位: bps)
- **SSRC feedback**: 该估计适用的媒体流 SSRC 列表

**工作流程：**

1. 接收端使用 REMB 算法（基于丢包率和延迟变化）估计可用带宽
2. 将估计值通过 REMB 消息发送给发送端
3. 发送端将 REMB 值作为码率上限的参考之一
4. 在 SFU 场景中，SFU 可以汇总多个接收端的 REMB，取最小值转发给发送端


RTCP XR — Extended Reports
=============================================

RTCP XR (Extended Reports) 定义在 RFC 3611 中，提供了比标准 RTCP SR/RR 更丰富的统计信息。
XR 使用 PT=207，包含一个或多个 report block，每个 block 有不同的 block type。

XR 通用格式：

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P|reserved |   PT=207      |             length            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                     SSRC of packet sender                     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   :                         report blocks                         :
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

常用的 XR Block Types：

.. list-table:: RTCP XR Block Types
   :header-rows: 1
   :widths: 10 30 60

   * - BT
     - 名称
     - 描述
   * - 1
     - Loss RLE Report Block
     - 使用 Run-Length Encoding 报告详细的丢包模式
   * - 2
     - Duplicate RLE Report Block
     - 报告重复包的模式
   * - 3
     - Packet Receipt Times Report Block
     - 报告每个包的接收时间
   * - 4
     - Receiver Reference Time Report Block
     - 接收端参考时间，类似 SR 中的 NTP 时间戳
   * - 5
     - DLRR Report Block
     - Delay since Last Receiver Report，用于 RTT 计算
   * - 6
     - Statistics Summary Report Block
     - 汇总统计：丢包率、重复率、jitter 等
   * - 7
     - VoIP Metrics Report Block
     - VoIP 质量指标：R-factor、MOS、burst/gap 统计等

**VoIP Metrics Report Block (BT=7)** 是最常用的 XR block 之一，包含以下关键指标：

- **Loss Rate**: 丢包率
- **Discard Rate**: 因为到达太晚而被丢弃的包的比率
- **Burst Density / Gap Density**: 突发丢包和间隙丢包的密度
- **Burst Duration / Gap Duration**: 突发和间隙的持续时间
- **Round Trip Delay**: 往返延迟
- **End System Delay**: 端系统延迟
- **R-factor**: ITU-T G.107 E-model 中的 R 值，综合反映通话质量
- **MOS-LQ / MOS-CQ**: Mean Opinion Score，主观质量评分

在 WebRTC 中，RTCP XR 主要用于 VoIP 质量监控和诊断，
Chrome 的 ``getStats()`` API 返回的部分统计数据就来源于 XR 报告。


反馈时机与频率控制
=============================================

RTCP 带宽分配
-----------------------------

根据 RFC 3550 的规定，RTCP 流量不应超过会话总带宽的 5%。
在这 5% 中，25% 分配给发送端报告（SR），75% 分配给接收端报告（RR 和反馈消息）。

然而，在 WebRTC 的实时交互场景中，这个限制可能导致反馈不够及时。
RFC 4585 (RTP/AVPF) 引入了 "Early RTCP" 机制，允许在以下条件下提前发送反馈：

1. **Immediate feedback**: 对于时间敏感的反馈（如 NACK、PLI），可以立即发送
2. **Early feedback**: 在常规 RTCP 间隔之前发送，但需要遵守最小间隔限制
3. **Regular feedback**: 按照常规 RTCP 间隔发送

Reduced-Size RTCP (RFC 5506)
-----------------------------

传统的 RTCP 复合包（compound packet）要求每个 RTCP 包至少包含一个 SR 或 RR。
这在需要快速发送反馈时会增加不必要的开销。

RFC 5506 定义了 Reduced-Size RTCP，允许发送不包含 SR/RR 的单独反馈消息。
这对于 NACK、PLI 等需要快速响应的反馈特别有用。

在 WebRTC 的 SDP 协商中，通过以下属性启用 reduced-size RTCP：

.. code-block::

   a=rtcp-rsize

WebRTC 中几乎所有实现都支持并默认启用 reduced-size RTCP。


SDP 中的反馈能力协商
=============================================

在 WebRTC 的 SDP offer/answer 交换中，通过 ``a=rtcp-fb`` 属性来协商支持的反馈类型。
格式为：

.. code-block::

   a=rtcp-fb:<payload type> <feedback type> [<feedback parameters>]

典型的 WebRTC SDP 中的反馈协商示例：

.. code-block::

   m=video 9 UDP/TLS/RTP/SAVPF 96 97 98
   a=rtpmap:96 VP8/90000
   a=rtcp-fb:96 goog-remb
   a=rtcp-fb:96 transport-cc
   a=rtcp-fb:96 ccm fir
   a=rtcp-fb:96 nack
   a=rtcp-fb:96 nack pli
   a=rtpmap:97 VP9/90000
   a=rtcp-fb:97 goog-remb
   a=rtcp-fb:97 transport-cc
   a=rtcp-fb:97 ccm fir
   a=rtcp-fb:97 nack
   a=rtcp-fb:97 nack pli
   a=rtpmap:98 H264/90000
   a=rtcp-fb:98 goog-remb
   a=rtcp-fb:98 transport-cc
   a=rtcp-fb:98 ccm fir
   a=rtcp-fb:98 nack
   a=rtcp-fb:98 nack pli

各 ``a=rtcp-fb`` 行的含义：

- ``nack``: 支持 Generic NACK (丢包重传)
- ``nack pli``: 支持 PLI (Picture Loss Indication)
- ``ccm fir``: 支持 FIR (Full Intra Request)，ccm 表示 Codec Control Messages (RFC 5104)
- ``goog-remb``: 支持 Google REMB (接收端带宽估计)
- ``transport-cc``: 支持 Transport-wide Congestion Control


WebRTC 实现中的反馈处理
=============================================

在 Chrome/libwebrtc 的实现中，各种反馈消息的处理流程如下：

NACK 处理流程
-----------------------------

1. ``RtpVideoStreamReceiver`` 检测到 RTP 序列号间隙
2. 通过 ``NackModule`` 管理 NACK 请求的生成和去重
3. ``NackModule`` 维护一个 NACK 列表，等待一定时间后（基于 RTT）发送 NACK
4. NACK 消息通过 ``RTCPSender`` 发送
5. 发送端的 ``RTPSender`` 收到 NACK 后，从 ``RtpPacketHistory`` 中查找并重传对应的包
6. 重传包通过 RTX (Retransmission) 通道发送，使用独立的 SSRC

PLI/FIR 处理流程
-----------------------------

1. 接收端检测到需要关键帧（解码失败、新用户加入等）
2. 通过 ``RTCPSender`` 发送 PLI 或 FIR 消息
3. 发送端的 ``VideoStreamEncoder`` 收到关键帧请求
4. 编码器在下一帧编码时生成 IDR/关键帧
5. 关键帧通过正常的 RTP 通道发送

Transport-CC 处理流程
-----------------------------

1. 发送端通过 ``TransportSequenceNumberAllocator`` 为每个 RTP 包分配 transport-wide sequence number
2. 接收端的 ``RemoteEstimatorProxy`` 收集包的到达时间
3. 定期（约 100ms）生成 transport-cc feedback 包并发送
4. 发送端的 ``SendSideBandwidthEstimation`` 接收 feedback
5. ``GoogCcNetworkController`` 使用 feedback 数据运行 delay-based 和 loss-based 估计
6. 估计结果用于调整 ``BitrateAllocator`` 的目标码率
7. ``VideoStreamEncoder`` 根据新的目标码率调整编码参数


反馈对质量的影响
=============================================

RTCP 反馈机制是 WebRTC 自适应码率控制（Adaptive Bitrate Control）的基础。
各种反馈消息共同驱动以下质量适配决策：

.. list-table:: 反馈消息与质量适配
   :header-rows: 1
   :widths: 25 35 40

   * - 反馈类型
     - 触发的适配行为
     - 对用户体验的影响
   * - NACK
     - 丢包重传
     - 减少视频花屏和卡顿，但增加延迟
   * - PLI/FIR
     - 生成关键帧
     - 快速恢复视频画面，但瞬间码率飙升
   * - Transport-CC
     - 调整编码码率
     - 平滑的码率适配，避免拥塞
   * - REMB
     - 限制发送码率上限
     - 防止接收端过载
   * - RTCP XR
     - 质量监控和诊断
     - 帮助定位和解决质量问题

**典型的质量适配循环：**

.. code-block:: text

   网络拥塞 → 丢包增加 → NACK 重传 + transport-cc 检测到延迟增加
       → GCC 降低目标码率 → 编码器降低码率/分辨率/帧率
       → 网络拥塞缓解 → transport-cc 检测到延迟减少
       → GCC 逐步提高目标码率 → 编码器提高码率/分辨率/帧率

这个反馈循环使得 WebRTC 能够在不断变化的网络条件下，
自动调整视频质量以维持最佳的用户体验。


反馈消息汇总表
=============================================

.. list-table:: WebRTC RTCP 反馈消息汇总
   :header-rows: 1
   :widths: 15 8 8 20 49

   * - 消息类型
     - PT
     - FMT
     - RFC
     - 用途
   * - Generic NACK
     - 205
     - 1
     - RFC 4585
     - 请求重传丢失的 RTP 包
   * - TMMBR
     - 205
     - 3
     - RFC 5104
     - 请求临时限制最大码率
   * - TMMBN
     - 205
     - 4
     - RFC 5104
     - 确认当前生效的码率限制
   * - Transport-CC
     - 205
     - 15
     - draft-holmer
     - 传输层拥塞控制反馈
   * - PLI
     - 206
     - 1
     - RFC 4585
     - 通知图片丢失，请求关键帧
   * - SLI
     - 206
     - 2
     - RFC 4585
     - 通知 slice 丢失
   * - RPSI
     - 206
     - 3
     - RFC 4585
     - 参考帧选择指示
   * - FIR
     - 206
     - 4
     - RFC 5104
     - 请求完整关键帧
   * - REMB
     - 206
     - 15
     - draft-alvestrand
     - 接收端估计的最大码率


参考
=========================
* `RFC4585`_: Extended RTP Profile for Real-time Transport Control Protocol (RTCP)-Based Feedback (RTP/AVPF)
* `RFC5104`_: Codec Control Messages in the RTP Audio-Visual Profile with Feedback (AVPF)
* `RFC5506`_: Support for Reduced-Size Real-Time Transport Control Protocol (RTCP): Opportunities and Consequences
* `RFC3611`_: RTP Control Protocol Extended Reports (RTCP XR)
* draft-holmer-rmcat-transport-wide-cc-extensions: RTP Extensions for Transport-wide Congestion Control
* draft-alvestrand-rmcat-remb: RTCP message for Receiver Estimated Maximum Bitrate
* `RFC3550`_: RTP: A Transport Protocol for Real-Time Applications
