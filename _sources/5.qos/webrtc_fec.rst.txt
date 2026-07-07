########################
WebRTC FEC
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC FEC
**Authors**  Walter Fan
**Status**   v2
**Updated**  |date|
============ ==========================



.. contents::
   :local:


简介
=========================

FEC 即 Forward Error Correction（前向纠错），是一种在发送端添加冗余数据，使接收端能够在不需要重传的情况下恢复丢失数据包的技术。

在实时音视频通信中，FEC 和 NACK/RTX 是应对丢包的两大主要手段：

- **NACK/RTX**：接收端检测到丢包后请求重传，延迟 = RTT
- **FEC**：发送端预先发送冗余包，接收端自行恢复，延迟 ≈ 0

两者的选择取决于网络条件：

.. list-table:: FEC vs NACK/RTX 对比
   :header-rows: 1
   :widths: 20 40 40

   * - 特性
     - FEC
     - NACK/RTX
   * - 恢复延迟
     - 接近零（无需等待重传）
     - 至少一个 RTT
   * - 带宽开销
     - 始终存在（即使无丢包）
     - 仅在丢包时产生
   * - 适用 RTT
     - 高 RTT 场景优势明显
     - 低 RTT 场景更高效
   * - 突发丢包
     - 恢复能力有限
     - 可多次重传
   * - 适用场景
     - 高延迟、低丢包率
     - 低延迟、可变丢包率

NACK 作为应付丢包的常用手段默认会启用，但是如果延迟较大，NACK 请求重传的包可能来不及到达，这时 FEC 就显得尤为重要。WebRTC 中通常同时启用 FEC 和 NACK，形成互补的丢包恢复策略。


FEC 的数学原理
=========================

XOR 恢复原理
--------------------------

FEC 最基本的原理是异或（XOR）运算。XOR 运算有一个关键性质：

.. code-block:: text

   A ⊕ B ⊕ A = B
   即：如果知道 A 和 A⊕B，就能恢复 B

利用这个性质，可以对一组数据包计算 XOR 校验包：

.. code-block:: text

   假设有 4 个数据包：P1, P2, P3, P4
   FEC 包 = P1 ⊕ P2 ⊕ P3 ⊕ P4

   如果 P3 丢失，接收端可以恢复：
   P3 = P1 ⊕ P2 ⊕ P4 ⊕ FEC
      = P1 ⊕ P2 ⊕ P4 ⊕ (P1 ⊕ P2 ⊕ P3 ⊕ P4)
      = P3  ✓

具体示例
--------------------------

.. code-block:: text

   P1 = [0x48, 0x65, 0x6C, 0x6C]  ("Hell")
   P2 = [0x6F, 0x20, 0x57, 0x6F]  ("o Wo")
   P3 = [0x72, 0x6C, 0x64, 0x21]  ("rld!")

   FEC = P1 ⊕ P2 ⊕ P3
       = [0x48⊕0x6F⊕0x72, 0x65⊕0x20⊕0x6C, 0x6C⊕0x57⊕0x64, 0x6C⊕0x6F⊕0x21]
       = [0x55, 0x09, 0x7B, 0x22]

   若 P2 丢失：
   P2 = P1 ⊕ P3 ⊕ FEC
      = [0x48⊕0x72⊕0x55, 0x65⊕0x6C⊕0x09, 0x6C⊕0x64⊕0x7B, 0x6C⊕0x21⊕0x22]
      = [0x6F, 0x20, 0x57, 0x6F]  ✓ 恢复成功

保护比率
--------------------------

N 个数据包生成 1 个 FEC 包的方案称为 (N, 1) FEC：

- **(1, 1)**：100% 冗余，每个包都有备份，可恢复任意单包丢失
- **(2, 1)**：50% 冗余，每 2 个包生成 1 个 FEC 包
- **(4, 1)**：25% 冗余，每 4 个包生成 1 个 FEC 包
- **(10, 1)**：10% 冗余

保护比率越高，恢复能力越强，但带宽开销也越大。


Parity FEC
=========================

Parity FEC 是最简单的 FEC 方案，基于 XOR 运算：

.. code-block:: text

   FEC Header:
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      SN Base                  |      Length Recovery          |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |E|PT Recovery  |                 Mask                          |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                      TS Recovery                              |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

其中：

- **SN Base**：被保护的第一个 RTP 包的序列号
- **Length Recovery**：被保护包长度的 XOR
- **PT Recovery**：被保护包 Payload Type 的 XOR
- **Mask**：位掩码，指示哪些包被此 FEC 包保护
- **TS Recovery**：被保护包时间戳的 XOR


ULP FEC 详解
=========================

ULP FEC（Uneven Level Protection FEC）定义在 RFC 5109 中，是 WebRTC 中视频 FEC 的主要方案。

ULP FEC 包格式
--------------------------

.. code-block:: text

   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    RTP Header                                 |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      FEC Header (10 bytes)                                   |
   |      - SN Base (16 bits)                                     |
   |      - Length Recovery (16 bits)                              |
   |      - E, PT Recovery (8 bits)                                |
   |      - Mask (24 bits)                                         |
   |      - TS Recovery (32 bits)                                  |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      ULP Level Header (Level 0)                               |
   |      - Length (16 bits)                                       |
   |      - Mask (16/48 bits)                                      |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      Level 0 FEC Payload                                      |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      ULP Level Header (Level 1) [可选]                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      Level 1 FEC Payload [可选]                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

保护级别
--------------------------

ULP FEC 支持多级保护（Uneven Level Protection）：

- **Level 0**：保护 payload 的前 N 个字节（最重要的部分）
- **Level 1**：保护 payload 的后续字节（次要部分）

这种不均匀保护的设计理念是：视频帧的头部（如 slice header、运动向量）比尾部（如高频 DCT 系数）更重要，丢失头部会导致整帧不可解码，而丢失尾部只会降低质量。

Mask 表
--------------------------

Mask 是一个位掩码，指示哪些媒体包被当前 FEC 包保护。例如：

.. code-block:: text

   SN Base = 100
   Mask = 0b101010...

   表示保护 SN=100, SN=102, SN=104 的包

WebRTC 使用预定义的 Mask 表来决定 FEC 包的保护模式，这些表在 ``fec_private_tables_bursty.h`` 和 ``fec_private_tables_random.h`` 中定义，分别针对突发丢包和随机丢包场景优化。

WebRTC 中的 ULP FEC 实现
--------------------------

WebRTC 中 ULP FEC 的核心类：

- ``ForwardErrorCorrection``：FEC 编解码的核心类
- ``UlpfecGenerator``：在发送端生成 FEC 包
- ``UlpfecReceiver``：在接收端接收和恢复 FEC 包

.. code-block:: text

   发送端流程：
   1. UlpfecGenerator 收集一组媒体包
   2. 根据丢包率选择保护比率（FEC rate）
   3. 根据 Mask 表计算 FEC 包
   4. FEC 包使用 RED (RFC 2198) 封装后发送

   接收端流程：
   1. UlpfecReceiver 解析 RED 包，分离媒体包和 FEC 包
   2. 检测丢包（通过序列号间隙）
   3. 尝试使用 FEC 包恢复丢失的媒体包
   4. 恢复成功则将包交给解码器


FlexFEC 详解
=========================

FlexFEC 定义在 RFC 8627 中，是 ULP FEC 的演进版本，提供更灵活的保护方案。

与 ULP FEC 的区别
--------------------------

.. list-table:: FlexFEC vs ULP FEC
   :header-rows: 1
   :widths: 25 37 38

   * - 特性
     - ULP FEC
     - FlexFEC
   * - RFC
     - RFC 5109
     - RFC 8627
   * - 封装方式
     - 需要 RED 封装
     - 独立 SSRC，无需 RED
   * - 保护维度
     - 1D（行）
     - 1D 行、1D 列、2D
   * - 突发丢包恢复
     - 较弱
     - 较强（2D 模式）
   * - 灵活性
     - Mask 表固定
     - 可自定义保护模式
   * - 带宽效率
     - 一般
     - 更高

保护模式
--------------------------

FlexFEC 支持三种保护模式：

**1D 行保护（Row FEC）**

.. code-block:: text

   P1  P2  P3  P4  → FEC_R1
   P5  P6  P7  P8  → FEC_R2

   每行独立保护，可恢复每行中的 1 个丢包

**1D 列保护（Column FEC）**

.. code-block:: text

   P1  P2  P3  P4
   P5  P6  P7  P8
   ↓   ↓   ↓   ↓
   FC1 FC2 FC3 FC4

   每列独立保护，可恢复每列中的 1 个丢包
   对突发丢包（连续丢失多个包）特别有效

**2D 保护（Row + Column FEC）**

.. code-block:: text

   P1  P2  P3  P4  → FEC_R1
   P5  P6  P7  P8  → FEC_R2
   ↓   ↓   ↓   ↓
   FC1 FC2 FC3 FC4

   同时使用行和列保护
   可恢复更复杂的丢包模式（如同时丢失 P2 和 P5）
   但带宽开销更大

FlexFEC 包格式
--------------------------

FlexFEC 使用独立的 SSRC 发送，不需要 RED 封装：

.. code-block:: text

   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    RTP Header (独立 SSRC)                     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |R|F|P|X|  CC   |M|     PT      |       Sequence Number        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                      Timestamp                                |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                      SSRC (FEC stream)                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      FlexFEC Header                                           |
   |      - Repair window, SN Base, Mask, etc.                     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      FEC Payload                                              |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


音频 FEC
=========================

Opus In-band FEC
--------------------------

Opus 编解码器内置了 FEC 功能（In-band FEC），通过在当前帧中嵌入前一帧的低码率编码来实现：

.. code-block:: text

   正常 Opus 帧:
   [Frame N 高质量编码]

   启用 In-band FEC 的 Opus 帧:
   [Frame N 高质量编码 | Frame N-1 低质量编码]

   如果 Frame N-1 的包丢失：
   → 从 Frame N 的包中提取 Frame N-1 的低质量编码进行解码

SDP 协商中通过 ``useinbandfec=1`` 启用：

.. code-block:: text

   a=rtpmap:111 opus/48000/2
   a=fmtp:111 minptime=10;useinbandfec=1

Opus In-band FEC 的特点：

- 带宽开销较小（约 10-20%）
- 恢复质量低于原始质量（使用低码率编码）
- 只能恢复前一帧（延迟 1 帧）
- 不需要额外的 RTP 流

RED 冗余编码
--------------------------

RED（Redundant Audio Data）定义在 RFC 2198 中，通过在一个 RTP 包中携带多个时间点的音频数据来实现冗余：

.. code-block:: text

   RED 包结构:
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |F|   Block PT  |  Timestamp Offset   |   Block Length          |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |0|   Block PT  |  (primary encoding, no offset/length)        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      Redundant encoding data (older frame)                    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      Primary encoding data (current frame)                    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

WebRTC 中 RED + Opus 的组合使用：

.. code-block:: text

   a=rtpmap:63 red/48000/2
   a=fmtp:63 111/111
   a=rtpmap:111 opus/48000/2

这表示 RED 封装中携带两份 Opus 编码（当前帧 + 前一帧），如果当前包丢失，可以从下一个包中恢复。


FEC 与带宽的权衡
=========================

FEC 的带宽开销与保护能力之间存在权衡：

.. code-block:: text

   带宽开销 = FEC 包数 / 媒体包数 × 100%

   保护比率    带宽开销    可恢复丢包率（理论最大值）
   ─────────  ─────────  ──────────────────────
   (1, 1)     100%       50%（任意单包）
   (2, 1)      50%       33%（每组 1 包）
   (4, 1)      25%       20%（每组 1 包）
   (10, 1)     10%        9%（每组 1 包）

实际中，WebRTC 会根据当前丢包率动态调整 FEC 比率：

.. code-block:: text

   丢包率        推荐 FEC 比率    带宽开销
   ─────────    ──────────────  ─────────
   < 2%         不启用 FEC       0%
   2% - 5%      (10, 1)         ~10%
   5% - 10%     (4, 1)          ~25%
   10% - 20%    (2, 1)          ~50%
   > 20%        (1, 1)          ~100%

需要注意的是，FEC 的带宽开销会占用可用带宽，可能导致拥塞控制降低媒体码率。因此需要在 FEC 保护和媒体质量之间找到平衡点。


FEC/NACK Rate
=========================

WebRTC 中 FEC 和 NACK 的协同策略：

- **低 RTT（< 100ms）**：优先使用 NACK，FEC 作为补充
- **中 RTT（100-300ms）**：NACK + FEC 并用
- **高 RTT（> 300ms）**：主要依赖 FEC，NACK 效果有限

.. code-block:: text

   FEC 保护率的动态调整：

   if (rtt < 100ms):
       fec_rate = max(0, loss_rate - 5%)  # NACK 能处理大部分丢包
   elif (rtt < 300ms):
       fec_rate = loss_rate * 0.8         # FEC 和 NACK 各承担一部分
   else:
       fec_rate = loss_rate * 1.2         # 主要依赖 FEC，适当过保护


WebRTC 中的 FEC 配置
=========================

SDP 协商
--------------------------

视频 FEC（ULP FEC + RED）：

.. code-block:: text

   a=rtpmap:96 VP8/90000
   a=rtpmap:97 rtx/90000
   a=fmtp:97 apt=96
   a=rtpmap:98 ulpfec/90000
   a=rtpmap:99 red/90000
   a=fmtp:99 96/98

音频 FEC（RED + Opus）：

.. code-block:: text

   a=rtpmap:111 opus/48000/2
   a=fmtp:111 minptime=10;useinbandfec=1
   a=rtpmap:63 red/48000/2
   a=fmtp:63 111/111

FlexFEC：

.. code-block:: text

   a=rtpmap:118 flexfec-03/90000
   a=fmtp:118 repair-window=200000
   a=ssrc-group:FEC-FR 12345 67890

API 配置
--------------------------

在 WebRTC Native API 中配置 FEC：

.. code-block:: cpp

   // 启用 ULP FEC
   webrtc::RtpParameters params = sender->GetParameters();
   for (auto& encoding : params.encodings) {
       encoding.fec = webrtc::FecMechanism::RED_AND_ULPFEC;
   }
   sender->SetParameters(params);

   // 启用 FlexFEC
   webrtc::RtpParameters params = sender->GetParameters();
   for (auto& encoding : params.encodings) {
       encoding.fec = webrtc::FecMechanism::FLEXFEC;
   }
   sender->SetParameters(params);

在 JavaScript API 中，FEC 通过 SDP munging 或 codec preferences 配置：

.. code-block:: javascript

   // 设置 codec preferences 启用 RED
   const transceiver = pc.addTransceiver('audio');
   const codecs = RTCRtpReceiver.getCapabilities('audio').codecs;
   const redCodec = codecs.find(c => c.mimeType === 'audio/red');
   const opusCodec = codecs.find(c => c.mimeType === 'audio/opus');
   transceiver.setCodecPreferences([redCodec, opusCodec]);


参考资料
=========================

- RFC 2198: RTP Payload for Redundant Audio Data
- RFC 5109: RTP Payload Format for Generic Forward Error Correction
- RFC 8627: RTP Payload Format for Flexible Forward Error Correction (FlexFEC)
- RFC 4588: RTP Retransmission Payload Format
- WebRTC 源码: ``modules/rtp_rtcp/source/fec/``
- WebRTC UlpfecGenerator: ``modules/rtp_rtcp/source/ulpfec_generator.cc``
- WebRTC FlexfecSender: ``modules/rtp_rtcp/source/flexfec_sender.cc``
- `Pro-MPEG COP3 FEC <https://www.smpte.org/standards>`_
- `Parity FEC in WebRTC <https://webrtc.googlesource.com/src/+/refs/heads/main/modules/rtp_rtcp/source/fec/>`_
