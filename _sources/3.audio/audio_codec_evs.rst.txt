.. _audio_codec_evs:

================================
EVS — VoLTE 的核心编码
================================

.. contents:: 目录
   :local:
   :depth: 2

概述
====

EVS（Enhanced Voice Services）是 3GPP 于 2014 年发布的新一代语音编码标准（3GPP TS 26.441），专为 4G LTE 和 5G NR 网络设计。它是 AMR-WB 的继任者，在语音质量、音乐处理、延迟和抗丢包能力上都有显著提升。

EVS 的设计目标是成为"一个编码器统治所有场景"——从窄带电话到超宽带高保真音频，从纯语音到音乐混合内容。

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 属性
     - 值
   * - 标准
     - 3GPP TS 26.441-452
   * - 采样率
     - 8 / 16 / 32 / 48 kHz
   * - 码率
     - 5.9 - 128 kbps（13 种 + AMR-WB IO 模式）
   * - 帧长
     - 20 ms
   * - 算法延迟
     - 32 ms（默认）/ 22 ms（低延迟模式）
   * - 频率范围
     - NB: 300-3400 Hz, WB: 50-7000 Hz, SWB: 50-14000 Hz, FB: 20-20000 Hz
   * - 声道
     - 单声道（Rel-12），立体声（Rel-15+）
   * - 专利
     - 有（专利池授权）

带宽与码率
===========

EVS 支持四种带宽模式：

.. list-table::
   :header-rows: 1
   :widths: 15 15 20 20 30

   * - 带宽
     - 采样率
     - 频率范围
     - 可用码率
     - 说明
   * - NB
     - 8 kHz
     - 300-3400 Hz
     - 5.9-24.4 kbps
     - 兼容窄带网络
   * - WB
     - 16 kHz
     - 50-7000 Hz
     - 5.9-128 kbps
     - VoLTE 主力
   * - SWB
     - 32 kHz
     - 50-14000 Hz
     - 9.6-128 kbps
     - 高清语音
   * - FB
     - 48 kHz
     - 20-20000 Hz
     - 16.4-128 kbps
     - 全带宽音频

EVS 的码率模式：

.. code-block:: text

   5.9*  7.2*  8.0*  9.6  13.2  16.4  24.4  32  48  64  96  128 kbps
   |_____|_____|_____|_____|_____|_____|_____|___|___|___|___|
   VBR 可选      固定码率模式

   * 5.9/7.2/8.0 kbps 支持 VBR（可变码率）模式

编码架构
========

EVS 的核心创新是**混合编码架构**——根据信号类型自动切换编码模式：

.. mermaid::

   flowchart TD
     A[输入 20ms 帧] --> B[信号分类器]
     B -->|语音/浊音| C[ACELP 模式<br/>线性预测 + 代数码本]
     B -->|音乐/噪声/瞬态| D[MDCT 模式<br/>变换编码]
     B -->|过渡帧| E[TCX 模式<br/>变换激励]
     C --> F[比特流]
     D --> F
     E --> F

三种编码模式
-------------

1. **ACELP 模式**

   - 用于语音信号（浊音、清音）
   - 与 AMR-WB 类似的 CELP 编码
   - 16 阶 LP 分析，ISF 量化
   - 自适应码本 + 代数码本

2. **MDCT 模式**（HQ 模式）

   - 用于音乐、噪声等非语音信号
   - 基于 MDCT 变换编码
   - 类似 AAC 的频域量化
   - 心理声学模型指导比特分配

3. **TCX 模式**（Transform Coded Excitation）

   - ACELP 和 MDCT 的混合
   - 用 MDCT 变换编码 LP 残差（激励信号）
   - 支持多种帧长：TCX-20, TCX-40, TCX-80
   - 适合语音到音乐的过渡段

信号分类器
-----------

EVS 的信号分类器是其"大脑"，决定每帧使用哪种编码模式：

.. code-block:: text

   特征提取：
   ├── 频谱倾斜（spectral tilt）
   ├── 过零率（zero crossing rate）
   ├── 基音相关性（pitch correlation）
   ├── 频谱平坦度（spectral flatness）
   ├── 能量变化率
   └── 谐波结构强度

   分类结果：
   ├── VOICED（浊音）      → ACELP
   ├── UNVOICED（清音）    → ACELP
   ├── GENERIC（通用语音） → ACELP 或 TCX
   ├── TRANSITION（过渡）  → TCX
   ├── AUDIO（音乐/噪声） → MDCT
   └── INACTIVE（静音）    → CNG

EVS vs AMR-WB
===============

.. list-table::
   :header-rows: 1
   :widths: 25 35 35

   * - 特性
     - AMR-WB
     - EVS
   * - 最高带宽
     - 宽带 (7 kHz)
     - 全带宽 (20 kHz)
   * - 音乐处理
     - 差（纯 ACELP）
     - 优秀（MDCT 模式）
   * - 最低码率
     - 6.6 kbps
     - 5.9 kbps（质量更好）
   * - 丢包隐藏
     - 基础 PLC
     - 高级 PLC（频域插值）
   * - 信道感知
     - 码率切换
     - 码率切换 + JBM 优化
   * - 延迟
     - 25 ms
     - 32 ms（可降至 22 ms）
   * - 互操作
     - —
     - AMR-WB IO 模式兼容

在相同码率下，EVS 的 MOS 评分通常比 AMR-WB 高 0.3-0.5 分。特别是在音乐保持（Music on Hold）和混合内容场景，EVS 的优势更加明显。

JBM（Jitter Buffer Management）
=================================

EVS 标准包含了一个配套的 **JBM** 规范（3GPP TS 26.114 Annex A），这在语音编码标准中是首次：

- 自适应抖动缓冲，根据网络状况动态调整缓冲深度
- 时间拉伸/压缩（Time Stretching）：无损地调整语音播放速度
- 与编码器的丢包隐藏（PLC）协同工作
- 目标：在延迟和质量之间取得最佳平衡

EVS vs Opus
=============

.. list-table::
   :header-rows: 1
   :widths: 25 35 35

   * - 特性
     - EVS
     - Opus
   * - 语音 @13.2 kbps
     - MOS ~4.2 (SWB)
     - MOS ~4.0 (WB)
   * - 音乐 @32 kbps
     - 优秀
     - 优秀
   * - 最低延迟
     - 22 ms
     - 5 ms
   * - FEC
     - 依赖信道编码
     - 内置 in-band FEC
   * - 自适应码率
     - 13 档离散
     - 连续可调
   * - 专利
     - **有**（专利池）
     - **免费**
   * - WebRTC
     - 不支持
     - 必须支持
   * - VoLTE/5G
     - **标准编码**
     - 不支持
   * - 信号分类
     - 内置（5 类）
     - 内置（SILK/CELT/Hybrid）

EVS 在运营商网络中的地位类似于 Opus 在互联网中的地位——各自是自己领域的最佳选择。

部署现状
========

截至 2026 年，EVS 的部署情况：

- **VoLTE**：全球主要运营商已部署或正在部署 EVS
- **VoNR（5G）**：EVS 是 5G 语音的默认编码
- **终端支持**：iPhone 12+、Samsung Galaxy S20+、Pixel 5+ 等
- **互操作**：EVS 的 AMR-WB IO 模式确保与旧设备兼容

小结
====

EVS 代表了语音编码技术的最高水平——它用混合编码架构解决了"一个编码器适应所有内容"的难题。信号分类器自动选择 ACELP/TCX/MDCT 模式，使得语音和音乐都能获得最佳质量。

对于 WebRTC 开发者，EVS 的直接关系不大（浏览器不支持），但理解它的设计思想——特别是混合编码和信号分类——有助于理解 Opus 的 SILK/CELT/Hybrid 模式切换机制，两者的设计哲学异曲同工。
