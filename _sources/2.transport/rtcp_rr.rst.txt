##############################
RTCP Receiver Report
##############################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** RTCP RR
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
==========================

RTCP Receiver Report (RR) 是 RTCP (RTP Control Protocol) 中最重要的报文类型之一，用于接收方向发送方报告媒体流的接收质量。RR 报文包含了丢包率、抖动、往返时延等关键指标，这些信息对于 WebRTC 的自适应码率控制、前向纠错 (FEC)、丢包重传 (NACK) 和抖动缓冲区调整至关重要。

在 WebRTC 中，RTCP RR 的主要作用包括：

* **丢包率监控**: 帮助发送方决定是否启用 FEC 或 NACK
* **抖动监控**: 帮助接收方调整 jitter buffer 大小
* **RTT 估算**: 结合 SR (Sender Report) 计算往返时延，用于拥塞控制
* **质量评估**: 提供端到端的媒体传输质量指标

RTCP RR 的 Payload Type (PT) 为 201，与 Sender Report (PT=200) 的结构类似，但不包含发送方信息块。


RR 报文格式
==========================

RTCP Receiver Report 的完整报文格式如 RFC 3550 所定义：

.. code-block::

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P|    RC   |   PT=RR=201   |            length L           |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                     SSRC of packet sender                     |
   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
   |                 SSRC_1 (SSRC of first source)                 |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   | fraction lost |       cumulative number of packets lost       |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |           extended highest sequence number received           |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                      inter-arrival jitter                     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                         last SR (LSR)                         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                   delay since last SR (DLSR)                  |
   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
   |                 SSRC_2 (SSRC of second source)                |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   :                               ...                             :
   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
   |                  profile-specific extensions                  |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

头部字段
--------------------------

* **V (Version, 2 bits)**: RTP 版本号，固定为 2
* **P (Padding, 1 bit)**: 填充标志，如果设置为 1，则报文末尾包含填充字节
* **RC (Reception Report Count, 5 bits)**: 报告块的数量，最多 31 个。如果需要报告更多源，可以发送多个 RR 报文
* **PT (Payload Type, 8 bits)**: 报文类型，RR 固定为 201
* **Length (16 bits)**: 报文长度，以 32 位字为单位减 1（不包括头部的第一个 32 位字）
* **SSRC of packet sender (32 bits)**: 发送此 RR 报文的参与者的 SSRC 标识符


报告块字段详解
==========================

每个报告块 (Report Block) 包含一个 RTP 源的接收质量信息，共 24 字节（6 个 32 位字）。

SSRC of source (32 bits)
--------------------------

被报告的 RTP 源的 SSRC 标识符。一个 RR 报文可以包含多个报告块，分别报告不同 RTP 源的接收质量。

Fraction Lost (8 bits)
--------------------------

自上次 SR 或 RR 报文发送以来的丢包率，以 256 为分母的分数表示。

计算方法：

.. code-block::

    fraction_lost = (lost_interval * 256) / expected_interval

    其中:
    expected_interval = extended_max_seq - last_extended_max_seq
    received_interval = received - last_received
    lost_interval = expected_interval - received_interval

    例如:
    如果在一个间隔内期望收到 100 个包，实际收到 95 个:
    lost_interval = 100 - 95 = 5
    fraction_lost = (5 * 256) / 100 = 12 (约 4.7% 丢包率)

    fraction_lost = 0   表示没有丢包
    fraction_lost = 256  表示 100% 丢包（实际用 8 位表示，最大 255）

.. note::

    Fraction lost 是一个区间值，反映的是最近一个报告间隔内的丢包情况，而非累计丢包率。这使得发送方可以快速响应网络状况的变化。

Cumulative Number of Packets Lost (24 bits)
----------------------------------------------

自接收开始以来累计丢失的 RTP 数据包总数。这是一个 24 位有符号整数，范围为 -8388608 到 8388607。

.. code-block::

    cumulative_lost = expected_packets - received_packets

    其中:
    expected_packets = extended_max_seq - initial_seq + 1
    received_packets = 实际收到的数据包数量

    注意:
    - 负值表示收到了重复的数据包
    - 如果丢包数超过 24 位范围，则饱和到最大值 0x7FFFFF

Extended Highest Sequence Number Received (32 bits)
------------------------------------------------------

接收到的最高 RTP 序列号的扩展值。低 16 位是最高序列号，高 16 位是序列号回绕 (wrap-around) 的次数。

.. code-block::

    extended_max_seq = (cycles << 16) | max_seq

    其中:
    cycles = 序列号回绕次数 (16 bits)
    max_seq = 收到的最高序列号 (16 bits)

    例如:
    如果序列号已经回绕了 2 次，当前最高序列号为 1000:
    extended_max_seq = (2 << 16) | 1000 = 132072

    这个字段使得接收方可以跟踪超过 65535 个数据包的序列。

Interarrival Jitter (32 bits)
--------------------------

到达间隔抖动 (interarrival jitter) 的估计值，以 RTP 时间戳单位表示。这是 RTP 数据包到达时间间隔与发送时间间隔之差的统计方差的估计。

RFC 3550 定义的计算公式：

.. code-block::

    对于每个收到的 RTP 数据包 i:

    D(i, j) = (Rj - Ri) - (Sj - Si)

    其中:
    Ri = 数据包 i 的接收时间 (以 RTP 时间戳单位)
    Rj = 数据包 j 的接收时间 (以 RTP 时间戳单位)
    Si = 数据包 i 的 RTP 时间戳
    Sj = 数据包 j 的 RTP 时间戳

    抖动的递推计算:
    J(i) = J(i-1) + (|D(i-1, i)| - J(i-1)) / 16

    这是一个指数加权移动平均 (EWMA)，增益为 1/16。

.. note::

    抖动值反映了网络传输延迟的变化程度。较大的抖动意味着网络不稳定，接收方需要更大的 jitter buffer 来平滑播放。对于音频（采样率 48000 Hz），1 ms 的抖动对应 48 个 RTP 时间戳单位。

Last SR Timestamp - LSR (32 bits)
-----------------------------------------

最近收到的 RTCP Sender Report (SR) 中 NTP 时间戳的中间 32 位。如果尚未收到 SR，则此字段为 0。

.. code-block::

    NTP 时间戳 (64 bits):
    +------------------+------------------+
    | 秒部分 (32 bits)  | 小数部分 (32 bits) |
    +------------------+------------------+

    LSR = NTP 时间戳的中间 32 位
        = (秒部分的低 16 位) << 16 | (小数部分的高 16 位)

    例如:
    NTP timestamp = 0x83AA7E80_80000000
    LSR = 0x7E808000

Delay Since Last SR - DLSR (32 bits)
-----------------------------------------

从收到最近的 SR 到发送此 RR 之间的延迟，以 1/65536 秒为单位。如果尚未收到 SR，则此字段为 0。

.. code-block::

    DLSR 单位: 1/65536 秒

    例如:
    如果延迟为 100 ms:
    DLSR = 0.1 * 65536 = 6554 (0x199A)

    如果延迟为 1.5 秒:
    DLSR = 1.5 * 65536 = 98304 (0x18000)


RTT 计算
==========================

RTT (Round-Trip Time) 可以通过 SR 和 RR 报文中的时间戳信息计算得出。这是 WebRTC 中估算网络延迟的重要方法。

计算公式
--------------------------

.. code-block::

    RTT = A - LSR - DLSR

    其中:
    A    = 当前时间 (NTP 时间戳的中间 32 位格式)
    LSR  = RR 报文中的 Last SR Timestamp
    DLSR = RR 报文中的 Delay Since Last SR

计算过程示意图：

.. code-block::

    发送方 (Sender)                          接收方 (Receiver)
        |                                        |
        |--- SR (NTP timestamp T1) ------------->|
        |                                        |
        |                                        | (处理延迟 = DLSR)
        |                                        |
        |<-- RR (LSR=T1, DLSR=delay) ------------|
        |                                        |
        | 收到 RR 的时间 = A                      |
        |                                        |
        | RTT = A - LSR - DLSR                   |
        |     = A - T1 - delay                   |
        |                                        |

    具体数值示例:
    T1 (SR 发送时间):     10:00:00.000  → LSR = 0x00000000
    SR 到达接收方时间:     10:00:00.050  (传播延迟 50ms)
    RR 发送时间:          10:00:00.150  → DLSR = 0.1s = 6554
    RR 到达发送方时间:     10:00:00.200  → A

    RTT = A - LSR - DLSR
        = 0.200s - 0.000s - 0.100s
        = 0.100s (100ms)

    单向延迟 ≈ RTT / 2 = 50ms

.. note::

    RTT 计算假设 SR 和 RR 的传播延迟大致相等（对称路径）。在实际网络中，上行和下行延迟可能不同，但 RTT 仍然是一个有用的指标。


WebRTC 中 RR 的应用
==========================

丢包率用于 FEC/NACK 决策
-----------------------------------------

WebRTC 根据 RR 报告的丢包率动态调整错误恢复策略：

.. code-block::

    丢包率 (fraction_lost) 的使用:

    if fraction_lost == 0:
        # 网络状况良好，无需额外保护
        disable_fec()
        disable_nack()  # 或保持最小 NACK

    elif fraction_lost < threshold_low (如 2%):
        # 轻微丢包，使用 NACK 重传
        enable_nack()
        disable_fec()

    elif fraction_lost < threshold_high (如 10%):
        # 中等丢包，同时使用 NACK 和 FEC
        enable_nack()
        enable_fec(redundancy=low)

    elif fraction_lost < threshold_critical (如 25%):
        # 严重丢包，增加 FEC 冗余
        enable_nack()
        enable_fec(redundancy=high)
        reduce_bitrate()

    else:
        # 极端丢包，大幅降低码率
        enable_fec(redundancy=max)
        reduce_bitrate_significantly()

抖动用于 Jitter Buffer 调整
-----------------------------------------

RR 中的 interarrival jitter 值帮助接收方动态调整 jitter buffer 的大小：

.. code-block::

    Jitter Buffer 自适应调整:

    target_delay = k * jitter + min_delay

    其中:
    k = 安全系数 (通常为 2-4)
    jitter = RR 报告的抖动值 (转换为毫秒)
    min_delay = 最小缓冲延迟 (如 20ms)

    例如:
    jitter = 480 (RTP 时间戳单位, 48kHz 采样率)
    jitter_ms = 480 / 48 = 10ms
    target_delay = 3 * 10 + 20 = 50ms

    如果抖动增大:
    jitter = 960 → jitter_ms = 20ms
    target_delay = 3 * 20 + 20 = 80ms
    (增大 jitter buffer 以减少播放中断)

RTT 用于拥塞控制
-----------------------------------------

WebRTC 的拥塞控制算法（如 GCC - Google Congestion Control）使用 RTT 作为重要输入：

.. code-block::

    RTT 在拥塞控制中的作用:

    1. 基于延迟的拥塞检测:
       if RTT > RTT_threshold:
           # 网络可能拥塞，降低发送码率
           reduce_bitrate()

    2. NACK 重传定时:
       nack_timeout = RTT + RTT_variance
       # RTT 越大，等待重传的时间越长

    3. 码率估算:
       # 结合丢包率和 RTT 估算可用带宽
       available_bandwidth = f(loss_rate, RTT)

    4. Probe 间隔:
       # RTT 影响带宽探测的频率
       probe_interval = max(min_interval, 2 * RTT)


RTCP Sender Report (SR) 格式
==========================

为了更好地理解 RR，有必要了解与之配合使用的 Sender Report (SR) 格式。SR 的 Payload Type 为 200。

.. code-block::

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P|    RC   |   PT=SR=200   |            length             |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                     SSRC of sender                            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |              NTP timestamp, most significant word             |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |             NTP timestamp, least significant word             |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                         RTP timestamp                         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                     sender's packet count                     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                      sender's octet count                     |
   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
   |                 SSRC_1 (SSRC of first source)                 |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   :                    ... (report blocks)                        :
   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

SR 比 RR 多了一个发送方信息块 (Sender Info)，包含：

* **NTP Timestamp (64 bits)**: 发送此 SR 时的 NTP 时间戳，用于 RTT 计算
* **RTP Timestamp (32 bits)**: 与 NTP 时间戳对应的 RTP 时间戳，用于 NTP 和 RTP 时间的同步
* **Sender's Packet Count (32 bits)**: 自会话开始以来发送的 RTP 数据包总数
* **Sender's Octet Count (32 bits)**: 自会话开始以来发送的 RTP 负载字节总数

SR 中也可以包含报告块（与 RR 中的格式相同），用于报告该发送方作为接收方时的接收质量。


RTCP 复合报文
==========================

根据 RFC 3550 的规定，RTCP 报文通常以复合报文 (compound packet) 的形式发送。一个复合报文包含多个 RTCP 报文，封装在一个 UDP 数据包中。

复合报文的规则：

1. 第一个报文必须是 SR 或 RR
2. 必须包含 SDES (Source Description) 报文，至少包含 CNAME 项
3. 可以包含其他 RTCP 报文（如 BYE、APP）

.. code-block::

    RTCP 复合报文结构:

    +------------------+
    | SR 或 RR          |  ← 必须是第一个
    +------------------+
    | SDES (CNAME)     |  ← 必须包含
    +------------------+
    | BYE (可选)        |  ← 参与者离开时发送
    +------------------+
    | APP (可选)        |  ← 应用特定数据
    +------------------+
    | XR (可选)         |  ← 扩展报告 (RFC 3611)
    +------------------+

常见的 RTCP 报文类型：

.. list-table::
   :header-rows: 1
   :widths: 10 10 40 40

   * - PT
     - 缩写
     - 名称
     - 用途
   * - 200
     - SR
     - Sender Report
     - 发送方统计和接收质量报告
   * - 201
     - RR
     - Receiver Report
     - 接收质量报告
   * - 202
     - SDES
     - Source Description
     - 源描述（CNAME 等）
   * - 203
     - BYE
     - Goodbye
     - 参与者离开通知
   * - 204
     - APP
     - Application-Defined
     - 应用自定义数据
   * - 205
     - RTPFB
     - Transport Layer Feedback
     - NACK、TMMBR 等
   * - 206
     - PSFB
     - Payload-Specific Feedback
     - PLI、FIR、REMB 等
   * - 207
     - XR
     - Extended Report
     - 扩展报告 (RFC 3611)


RTCP 定时规则
==========================

RTCP 报文的发送频率受到严格的带宽限制，以避免 RTCP 流量占用过多带宽。

带宽分配
--------------------------

RFC 3550 规定：

* RTCP 流量不应超过会话总带宽的 **5%**
* 其中 **25%** 分配给发送方（SR），**75%** 分配给接收方（RR）
* 最小发送间隔为 **5 秒**（可通过 reduced minimum 降低到约 360ms / 参与者数量）

.. code-block::

    RTCP 带宽计算示例:

    假设会话带宽 = 2 Mbps
    RTCP 带宽 = 2 Mbps * 5% = 100 kbps

    发送方 RTCP 带宽 = 100 kbps * 25% = 25 kbps
    接收方 RTCP 带宽 = 100 kbps * 75% = 75 kbps

    假设 RTCP 复合报文大小 ≈ 100 bytes = 800 bits
    接收方发送间隔 ≈ 800 / 75000 ≈ 0.01s (约 10ms)

    但受最小间隔限制，实际间隔 = max(计算值, 5s / 参与者数)

发送间隔的随机化
--------------------------

为了避免所有参与者同时发送 RTCP 报文导致网络突发，实际发送时间会在计算间隔的 [0.5, 1.5] 倍范围内随机化。


Reduced-Size RTCP (RFC 5506)
==========================

传统的 RTCP 复合报文规则要求每个 UDP 数据包必须以 SR/RR 开头并包含 SDES，这增加了不必要的开销。RFC 5506 定义了 Reduced-Size RTCP，允许发送不包含 SR/RR 和 SDES 的单独 RTCP 报文。

在 WebRTC 中，Reduced-Size RTCP 被广泛使用：

.. code-block::

    传统 RTCP 复合报文:
    +------+------+------+
    | SR/RR| SDES | NACK |  ← 即使只需要发送 NACK，也必须包含 SR/RR 和 SDES
    +------+------+------+

    Reduced-Size RTCP:
    +------+
    | NACK |  ← 可以单独发送 NACK，减少开销和延迟
    +------+

Reduced-Size RTCP 的优势：

* **减少延迟**: 反馈报文可以立即发送，无需等待下一个 RTCP 发送时机
* **减少开销**: 不需要附带 SR/RR 和 SDES
* **更灵活**: 适合需要快速反馈的场景（如 NACK、PLI）

在 SDP 中通过以下属性协商：

.. code-block::

    a=rtcp-rsize


代码示例
=========================

解析 RR 报文
--------------------------

.. code-block:: python

    import struct
    import time

    class RtcpReportBlock:
        """RTCP Report Block 解析器"""

        def __init__(self):
            self.ssrc = 0           # 32 bits: 被报告源的 SSRC
            self.fraction_lost = 0  # 8 bits: 区间丢包率
            self.packets_lost = 0   # 24 bits: 累计丢包数 (有符号)
            self.highest_seq = 0    # 32 bits: 扩展最高序列号
            self.jitter = 0         # 32 bits: 到达间隔抖动
            self.lsr = 0            # 32 bits: 最近 SR 时间戳
            self.dlsr = 0           # 32 bits: 自最近 SR 的延迟

        @staticmethod
        def parse(data: bytes) -> 'RtcpReportBlock':
            """从 24 字节数据解析报告块"""
            if len(data) < 24:
                raise ValueError("报告块数据不足 24 字节")

            block = RtcpReportBlock()
            block.ssrc = struct.unpack('!I', data[0:4])[0]

            # fraction_lost (8 bits) + cumulative_lost (24 bits)
            lost_word = struct.unpack('!I', data[4:8])[0]
            block.fraction_lost = (lost_word >> 24) & 0xFF
            block.packets_lost = lost_word & 0x00FFFFFF
            # 处理 24 位有符号数
            if block.packets_lost & 0x800000:
                block.packets_lost -= 0x1000000

            block.highest_seq = struct.unpack('!I', data[8:12])[0]
            block.jitter = struct.unpack('!I', data[12:16])[0]
            block.lsr = struct.unpack('!I', data[16:20])[0]
            block.dlsr = struct.unpack('!I', data[20:24])[0]

            return block

        def get_loss_percentage(self) -> float:
            """获取丢包百分比"""
            return (self.fraction_lost / 256.0) * 100.0

        def get_jitter_ms(self, clock_rate: int = 90000) -> float:
            """将抖动转换为毫秒"""
            return (self.jitter / clock_rate) * 1000.0

        def get_dlsr_seconds(self) -> float:
            """将 DLSR 转换为秒"""
            return self.dlsr / 65536.0

        def __str__(self):
            return (
                f"ReportBlock(ssrc=0x{self.ssrc:08X}, "
                f"loss={self.get_loss_percentage():.1f}%, "
                f"cum_lost={self.packets_lost}, "
                f"highest_seq={self.highest_seq}, "
                f"jitter={self.jitter}, "
                f"lsr=0x{self.lsr:08X}, "
                f"dlsr={self.get_dlsr_seconds():.3f}s)"
            )


    class RtcpReceiverReport:
        """RTCP Receiver Report 解析器"""

        PT_RR = 201

        def __init__(self):
            self.version = 2
            self.padding = False
            self.report_count = 0
            self.length = 0
            self.ssrc = 0
            self.report_blocks = []

        @staticmethod
        def parse(data: bytes) -> 'RtcpReceiverReport':
            """解析 RTCP RR 报文"""
            if len(data) < 8:
                raise ValueError("数据太短，不是有效的 RTCP RR")

            rr = RtcpReceiverReport()

            # 解析头部
            first_byte = data[0]
            rr.version = (first_byte >> 6) & 0x03
            rr.padding = bool((first_byte >> 5) & 0x01)
            rr.report_count = first_byte & 0x1F

            pt = data[1]
            if pt != RtcpReceiverReport.PT_RR:
                raise ValueError(f"不是 RR 报文，PT={pt}")

            rr.length = struct.unpack('!H', data[2:4])[0]
            rr.ssrc = struct.unpack('!I', data[4:8])[0]

            # 解析报告块
            offset = 8
            for i in range(rr.report_count):
                if offset + 24 > len(data):
                    break
                block = RtcpReportBlock.parse(data[offset:offset+24])
                rr.report_blocks.append(block)
                offset += 24

            return rr

        def __str__(self):
            blocks_str = '\n  '.join(str(b) for b in self.report_blocks)
            return (
                f"ReceiverReport(ssrc=0x{self.ssrc:08X}, "
                f"rc={self.report_count})\n  {blocks_str}"
            )


    def calculate_rtt(current_ntp_middle32: int,
                      lsr: int,
                      dlsr: int) -> float:
        """
        计算 RTT

        :param current_ntp_middle32: 当前 NTP 时间戳的中间 32 位
        :param lsr: RR 中的 Last SR Timestamp
        :param dlsr: RR 中的 Delay Since Last SR
        :return: RTT (秒)
        """
        if lsr == 0:
            return -1.0  # 尚未收到 SR

        rtt_fixed = (current_ntp_middle32 - lsr - dlsr) & 0xFFFFFFFF
        rtt_seconds = rtt_fixed / 65536.0
        return rtt_seconds


    # 使用示例
    if __name__ == '__main__':
        # 模拟解析一个 RR 报文
        # (实际使用时从网络接收)
        sample_data = bytearray(32)
        # 头部: V=2, P=0, RC=1, PT=201, Length=7
        sample_data[0] = 0x81  # V=2, P=0, RC=1
        sample_data[1] = 0xC9  # PT=201
        struct.pack_into('!H', sample_data, 2, 7)  # Length
        struct.pack_into('!I', sample_data, 4, 0x12345678)  # SSRC

        # 报告块
        struct.pack_into('!I', sample_data, 8, 0xAABBCCDD)  # SSRC_1
        struct.pack_into('!I', sample_data, 12, 0x0D000005)  # frac=13(~5%), lost=5
        struct.pack_into('!I', sample_data, 16, 0x00001000)  # highest_seq
        struct.pack_into('!I', sample_data, 20, 480)  # jitter
        struct.pack_into('!I', sample_data, 24, 0x7E808000)  # LSR
        struct.pack_into('!I', sample_data, 28, 6554)  # DLSR (~100ms)

        rr = RtcpReceiverReport.parse(bytes(sample_data))
        print(rr)

        for block in rr.report_blocks:
            print(f"  丢包率: {block.get_loss_percentage():.1f}%")
            print(f"  抖动: {block.get_jitter_ms(48000):.1f}ms (音频)")
            print(f"  DLSR: {block.get_dlsr_seconds():.3f}s")


参考资料
=========================

* `RFC 3550 - RTP: A Transport Protocol for Real-Time Applications <https://datatracker.ietf.org/doc/html/rfc3550>`_
* `RFC 3551 - RTP Profile for Audio and Video Conferences with Minimal Control <https://datatracker.ietf.org/doc/html/rfc3551>`_
* `RFC 5506 - Support for Reduced-Size Real-Time Transport Control Protocol (RTCP) <https://datatracker.ietf.org/doc/html/rfc5506>`_
* `RFC 3611 - RTP Control Protocol Extended Reports (RTCP XR) <https://datatracker.ietf.org/doc/html/rfc3611>`_
* `RFC 4585 - Extended RTP Profile for Real-time Transport Control Protocol (RTCP)-Based Feedback (RTP/AVPF) <https://datatracker.ietf.org/doc/html/rfc4585>`_
