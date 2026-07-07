.. _audio_codec_aac:

============================
AAC — 音乐场景的王者
============================

.. contents:: 目录
   :local:
   :depth: 2

概述
====

AAC（Advanced Audio Coding）是 ISO/IEC 制定的音频编码标准，最初作为 MPEG-2 的一部分发布（1997），后在 MPEG-4 中大幅扩展。AAC 是 MP3 的继任者，在相同码率下质量明显更好，已成为 Apple 生态、YouTube、数字广播等平台的默认音频编码。

对于实时通信，AAC 的低延迟变体 **AAC-LD** 和 **AAC-ELD** 是重要的选项，特别是在音乐和高保真音频传输场景。

.. list-table::
   :header-rows: 1
   :widths: 20 25 25 25

   * - 属性
     - AAC-LC
     - AAC-LD
     - AAC-ELD
   * - 标准
     - ISO 14496-3
     - ISO 14496-3
     - ISO 14496-3
   * - 采样率
     - 8-96 kHz
     - 8-48 kHz
     - 8-48 kHz
   * - 码率
     - 16-320 kbps
     - 16-128 kbps
     - 16-64 kbps
   * - 帧长
     - 1024 samples
     - 480/512 samples
     - 480/512 samples
   * - 算法延迟
     - ~46 ms @48kHz
     - ~20 ms @48kHz
     - ~15 ms @48kHz
   * - 声道
     - 最多 48 声道
     - 单/双声道
     - 单/双声道
   * - 适用场景
     - 流媒体、存储
     - 视频会议
     - 实时通信

AAC 编码原理
=============

AAC 属于**变换编码**，与 CELP 类语音编码器有本质区别：

.. mermaid::

   flowchart TD
     A[输入 PCM<br/>1024 samples] --> B[MDCT 变换]
     B --> C[频谱分析<br/>1024 频率系数]
     C --> D[心理声学模型]
     D --> E[量化与编码]
     E --> E1[非均匀量化<br/>Scalefactor Bands]
     E1 --> E2[Huffman 编码]
     E2 --> F[比特流格式化]
     F --> G[ADTS/LATM 封装]

核心技术
---------

1. **MDCT（改进离散余弦变换）**

   将时域信号变换到频域。使用 2048 点 MDCT（50% 重叠），产生 1024 个频率系数。

   - 长窗（1024 samples）：稳态信号，频率分辨率高
   - 短窗（128 samples × 8）：瞬态信号（如鼓点），时间分辨率高
   - 窗口切换由瞬态检测器控制

2. **心理声学模型**

   利用人耳的掩蔽效应来分配比特：

   - **频域掩蔽**：强信号附近的弱信号听不到
   - **时域掩蔽**：强瞬态前后的弱信号听不到
   - 计算每个频带的掩蔽阈值，低于阈值的量化噪声不可闻

3. **Scalefactor Bands**

   频谱被分为约 49 个 scalefactor band（类似临界带宽），每个 band 有独立的量化步长（scalefactor）。

4. **Huffman 编码**

   量化后的频谱系数用 Huffman 编码压缩，有 12 张码表可选。

AAC Profile 家族
==================

.. list-table::
   :header-rows: 1
   :widths: 15 20 30 35

   * - Profile
     - 全称
     - 特点
     - 应用
   * - AAC-LC
     - Low Complexity
     - 基础版，最广泛
     - iTunes, YouTube, DAB+
   * - HE-AAC v1
     - High Efficiency + SBR
     - 低码率高质量
     - 数字广播, 流媒体
   * - HE-AAC v2
     - HE-AAC + PS
     - 极低码率立体声
     - 移动流媒体
   * - AAC-LD
     - Low Delay
     - 低延迟变换编码
     - 视频会议
   * - AAC-ELD
     - Enhanced Low Delay
     - 最低延迟 + SBR
     - FaceTime, 实时通信
   * - xHE-AAC
     - Extended HE-AAC
     - USAC 标准，全能型
     - 5G 广播, 流媒体

SBR（Spectral Band Replication）
----------------------------------

SBR 是 HE-AAC 的核心技术：

- 编码器只编码低频部分（如 0-8 kHz）
- 用少量辅助数据（约 2 kbps）描述高频与低频的关系
- 解码器根据低频信号和辅助数据"复制"出高频部分
- 效果：在 32 kbps 实现接近 64 kbps AAC-LC 的质量

PS（Parametric Stereo）
-------------------------

PS 是 HE-AAC v2 的附加技术：

- 编码器将立体声混为单声道编码
- 用少量参数（IID/ICC/IPD）描述立体声空间信息
- 解码器从单声道 + 参数重建立体声
- 效果：在 24 kbps 实现可接受的立体声

AAC-ELD：实时通信利器
=======================

AAC-ELD 是 AAC 家族中延迟最低的变体，专为实时通信设计：

.. list-table::
   :header-rows: 1
   :widths: 30 35 35

   * - 特性
     - AAC-LD
     - AAC-ELD
   * - 变换
     - MDCT (512)
     - LD-MDCT (480/512)
   * - 窗函数
     - 正弦窗
     - 低延迟窗（非对称）
   * - SBR
     - 不支持
     - 支持（低延迟 SBR）
   * - 算法延迟
     - ~20 ms
     - ~15 ms（可达 ~32 ms with SBR）
   * - 典型码率
     - 32-64 kbps
     - 24-48 kbps

AAC-ELD 的低延迟窗设计是关键创新——传统 MDCT 需要 50% 重叠（即 1 帧前瞻），低延迟窗通过非对称设计将前瞻减少到接近零。

**Apple FaceTime** 使用 AAC-ELD 作为音频编码器（在 Opus 被广泛支持之前）。

AAC vs Opus
============

.. list-table::
   :header-rows: 1
   :widths: 25 35 35

   * - 特性
     - AAC-ELD
     - Opus
   * - 语音质量 @24kbps
     - 好
     - 好（SILK 模式）
   * - 音乐质量 @64kbps
     - 优秀
     - 优秀（CELT 模式）
   * - 最低延迟
     - ~15 ms
     - ~5 ms（2.5ms 帧）
   * - FEC
     - 无内置
     - 内置 in-band FEC
   * - 自适应码率
     - 有限
     - 连续可调 6-510 kbps
   * - 立体声
     - 支持
     - 支持
   * - 专利
     - **有**（需授权费）
     - **免费**
   * - WebRTC 支持
     - 不要求
     - 必须支持
   * - 浏览器支持
     - 仅解码（MSE）
     - 编解码均支持

在音乐质量上，AAC-ELD 和 Opus 的 CELT 模式各有千秋。但 Opus 的免专利、内置 FEC 和 WebRTC 原生支持使其成为互联网实时通信的首选。

AAC 在实时通信中的应用
========================

虽然 WebRTC 不要求支持 AAC，但它在以下场景仍然重要：

1. **Apple 生态**：FaceTime 历史上使用 AAC-ELD
2. **RTMP/HLS 推流**：直播推流几乎都用 AAC-LC
3. **SIP 视频会议**：部分系统支持 AAC-LD
4. **转码网关**：WebRTC (Opus) ↔ RTMP (AAC) 转码
5. **录制存储**：会议录制常转码为 AAC 存储

小结
====

AAC 是通用音频编码的标杆，特别是在音乐和高保真场景。它的心理声学模型和变换编码技术代表了音频压缩的主流方向。

对于实时通信开发者，理解 AAC-ELD 的低延迟设计有助于理解 Opus CELT 模式的设计思路——两者都是基于 MDCT 变换编码，但 Opus 在延迟和自适应性上做了更激进的优化。
