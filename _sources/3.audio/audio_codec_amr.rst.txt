.. _audio_codec_amr:

================================
AMR/AMR-WB — 移动通信编码
================================

.. contents:: 目录
   :local:
   :depth: 2

概述
====

AMR（Adaptive Multi-Rate）是 3GPP 为 GSM 和 UMTS 移动通信网络设计的语音编码标准。它的核心特性是**多码率自适应**——根据无线信道质量动态切换码率，在语音质量和信道保护之间取得最佳平衡。

AMR 家族包含两个标准：

- **AMR-NB**（窄带）：3GPP TS 26.071，8 种码率，4.75-12.2 kbps
- **AMR-WB**（宽带）：3GPP TS 26.171，即 ITU-T G.722.2，9 种码率，6.6-23.85 kbps

.. list-table::
   :header-rows: 1
   :widths: 20 40 40

   * - 属性
     - AMR-NB
     - AMR-WB
   * - 标准
     - 3GPP TS 26.071
     - 3GPP TS 26.171 / G.722.2
   * - 采样率
     - 8 kHz
     - 16 kHz
   * - 码率
     - 4.75-12.2 kbps（8 档）
     - 6.6-23.85 kbps（9 档）
   * - 帧长
     - 20 ms
     - 20 ms
   * - 前瞻
     - 5 ms
     - 5 ms
   * - 算法延迟
     - 25 ms
     - 25 ms
   * - 频率范围
     - 300-3400 Hz
     - 50-7000 Hz
   * - 编码算法
     - ACELP
     - ACELP
   * - 专利
     - 有（VoiceAge 等）
     - 有

AMR-NB 码率模式
=================

.. list-table::
   :header-rows: 1
   :widths: 15 15 15 55

   * - 模式
     - 码率
     - 帧大小
     - 说明
   * - AMR_4.75
     - 4.75 kbps
     - 95 bits
     - 最低码率，信道条件极差时使用
   * - AMR_5.15
     - 5.15 kbps
     - 103 bits
     -
   * - AMR_5.90
     - 5.90 kbps
     - 118 bits
     -
   * - AMR_6.70
     - 6.70 kbps
     - 134 bits
     -
   * - AMR_7.40
     - 7.40 kbps
     - 148 bits
     -
   * - AMR_7.95
     - 7.95 kbps
     - 159 bits
     -
   * - AMR_10.2
     - 10.2 kbps
     - 204 bits
     -
   * - AMR_12.2
     - 12.2 kbps
     - 244 bits
     - 最高码率，信道条件好时使用，与 GSM-EFR 兼容

自适应码率切换
===============

AMR 的码率切换是其最重要的特性：

.. mermaid::

   sequenceDiagram
     participant UE as 手机
     participant BTS as 基站
     participant BSC as 基站控制器

     Note over UE,BSC: 信道质量好 → 高码率
     BSC->>BTS: Codec Mode Command: 12.2 kbps
     BTS->>UE: 下行 12.2 kbps
     UE->>BTS: 上行 12.2 kbps

     Note over UE,BSC: 信道质量变差
     UE->>BTS: Codec Mode Request: 降码率
     BSC->>BTS: Codec Mode Command: 7.4 kbps
     BTS->>UE: 下行 7.4 kbps
     UE->>BTS: 上行 7.4 kbps

     Note over UE,BSC: 信道质量恢复
     UE->>BTS: Codec Mode Request: 升码率
     BSC->>BTS: Codec Mode Command: 12.2 kbps

切换逻辑：

1. **信道质量好** → 使用高码率（12.2 kbps），语音质量最佳
2. **信道质量差** → 降低码率（如 4.75 kbps），释放比特给信道编码（FEC），提高传输可靠性
3. 切换可以**逐帧进行**（每 20ms），响应速度快

这种设计的精妙之处在于：总的传输码率（语音 + 信道编码）保持不变，只是在语音质量和传输可靠性之间动态分配。

AMR-WB 编码原理
=================

AMR-WB 采用 **ACELP**（Algebraic CELP）编码，与 G.729 同属 CELP 家族，但有以下改进：

1. **宽带采样**：16 kHz，频率范围扩展到 50-7000 Hz
2. **ISP 量化**：使用 ISP（Immittance Spectral Pairs）代替 LSP，量化效率更高
3. **高频带扩展**：对 6400-7000 Hz 使用带宽扩展技术
4. **更精细的基音搜索**：1/4 分数精度（G.729 为 1/3）

AMR-WB 23.85 kbps 模式的帧结构：

.. list-table::
   :header-rows: 1
   :widths: 40 20 40

   * - 参数
     - 比特数
     - 说明
   * - ISP
     - 46
     - 频谱包络（分裂 VQ）
   * - 自适应码本延迟
     - 9 + 6 + 6 + 6
     - 4 个子帧
   * - 自适应码本增益
     - 4 × 6
     - 联合量化
   * - 代数码本
     - 4 × 52
     - 24 个脉冲/子帧
   * - 代数码本增益
     - 4 × 7
     -
   * - VAD 标志
     - 1
     -
   * - **合计**
     - **477**
     - 23.85 kbps

AMR-WB+
========

**AMR-WB+**（3GPP TS 26.290）是 AMR-WB 的超宽带扩展：

- 采样率：内部 25.6 kHz，输出可达 48 kHz
- 码率：6-36 kbps（单声道），7-48 kbps（立体声）
- 增加了 **TCX**（Transform Coded Excitation）模式，适合音乐信号
- 支持立体声
- 主要用于 3G 多媒体广播（MBMS）和流媒体

RTP 打包
========

AMR 的 RTP 打包定义在 RFC 4867 中，有两种模式：

**带宽高效模式**（bandwidth-efficient）：

.. code-block:: text

   a=rtpmap:96 AMR/8000
   a=fmtp:96 octet-align=0

**字节对齐模式**（octet-aligned）：

.. code-block:: text

   a=rtpmap:97 AMR-WB/16000
   a=fmtp:97 octet-align=1; mode-change-capability=2

字节对齐模式更常用，因为解析更简单：

.. code-block:: text

   ┌─────────────────────────────────────┐
   │ CMR (4 bits) │ padding (4 bits)     │  ← Codec Mode Request
   ├─────────────────────────────────────┤
   │ F │ FT (4 bits) │ Q │ padding      │  ← Table of Contents
   ├─────────────────────────────────────┤
   │ Speech data (padded to octet)       │  ← 语音数据
   └─────────────────────────────────────┘

- **CMR**：请求对端切换到的码率模式
- **FT**：当前帧的码率模式
- **Q**：帧质量指示（1=好，0=可能有错）
- **F**：后续是否还有帧（支持多帧打包）

与 Opus 的对比
===============

.. list-table::
   :header-rows: 1
   :widths: 25 25 25 25

   * - 特性
     - AMR-NB
     - AMR-WB
     - Opus
   * - 采样率
     - 8 kHz
     - 16 kHz
     - 8-48 kHz
   * - 码率范围
     - 4.75-12.2
     - 6.6-23.85
     - 6-510 kbps
   * - 自适应码率
     - 8 档离散
     - 9 档离散
     - 连续可调
   * - 音乐支持
     - 差
     - 一般
     - 优秀（CELT 模式）
   * - FEC
     - 依赖信道编码
     - 依赖信道编码
     - 内置 in-band FEC
   * - 立体声
     - 不支持
     - 不支持
     - 支持
   * - 专利
     - 有
     - 有
     - 免费
   * - WebRTC 支持
     - 不要求
     - 不要求
     - 必须支持

在 WebRTC/VoIP 中的位置
=========================

AMR/AMR-WB 在 WebRTC 浏览器中不被支持，但在以下场景仍然核心：

1. **VoLTE/VoNR**：4G/5G 语音通话的标准编码（AMR-WB 为主）
2. **运营商互联**：PSTN/移动网络互通
3. **FreeSWITCH 转码**：WebRTC (Opus) ↔ AMR-WB 转码网关
4. **录音系统**：通话录音常以 AMR 格式存储

小结
====

AMR 家族是移动通信语音编码的基石。它的多码率自适应机制——在语音质量和信道保护之间动态平衡——是一个优雅的工程设计。

虽然在互联网通信领域 Opus 已经全面胜出，但在移动通信网络中，AMR-WB（以及它的继任者 EVS）仍然是不可替代的标准。理解 AMR 的设计思想，对理解整个语音通信生态很有帮助。
