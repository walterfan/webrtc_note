.. _audio_codec_g729:

============================
G.729 — 低码率语音之王
============================

.. contents:: 目录
   :local:
   :depth: 2

概述
====

G.729 是 ITU-T 于 1996 年发布的低码率语音编码标准，采用 **CS-ACELP**（Conjugate-Structure Algebraic Code-Excited Linear Prediction）算法，在仅 **8 kbps** 的码率下实现了接近 G.711 的语音质量（MOS ≈ 3.9）。

G.729 曾是 VoIP 领域最流行的低码率编码器，广泛用于 IP 电话、语音网关和企业通信系统。

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 属性
     - 值
   * - 标准
     - ITU-T G.729 (1996)
   * - 采样率
     - 8 kHz
   * - 码率
     - 8 kbps（G.729a 同）
   * - 帧长
     - 10 ms（80 samples）
   * - 前瞻
     - 5 ms
   * - 算法延迟
     - 15 ms（帧长 + 前瞻）
   * - 频率范围
     - 300 - 3400 Hz
   * - MOS
     - ~3.9
   * - 复杂度
     - 20 MIPS（G.729），10 MIPS（G.729a）
   * - 专利
     - 2017 年核心专利过期

CS-ACELP 编码原理
==================

G.729 属于 **CELP**（Code-Excited Linear Prediction）家族。CELP 的核心思想：用一个激励信号通过线性预测滤波器来合成语音。

.. mermaid::

   flowchart TD
     A[输入 10ms 帧<br/>80 samples] --> B[LP 分析<br/>10 阶]
     B --> C[LP → LSP 转换<br/>并量化]
     C --> D[子帧处理<br/>2 × 5ms]
     D --> E[自适应码本搜索<br/>基音延迟 + 增益]
     E --> F[固定码本搜索<br/>代数码本 + 增益]
     F --> G[比特打包<br/>80 bits/帧]

每 10ms 帧编码为 80 bits，分配如下：

.. list-table::
   :header-rows: 1
   :widths: 40 20 40

   * - 参数
     - 比特数
     - 说明
   * - LSP（线性频谱对）
     - 18
     - 频谱包络，MA 预测 + 分裂 VQ
   * - 自适应码本延迟（子帧 1）
     - 8
     - 整数 + 1/3 分数精度
   * - 自适应码本延迟（子帧 2）
     - 5
     - 差分编码
   * - 自适应码本增益（×2）
     - 2 × 1
     - 3bit 联合量化（含固定码本增益）
   * - 固定码本索引（×2）
     - 2 × 13
     - 代数码本，4 个脉冲
   * - 码本增益（×2）
     - 2 × 4
     - 联合量化
   * - **合计**
     - **80**
     - 8 kbps

线性预测分析
-------------

G.729 使用 10 阶 LP 分析（对应 10 个 LSP 参数），通过 Levinson-Durbin 算法求解：

1. 计算自相关函数（带 Hamming 窗 + 带宽扩展）
2. Levinson-Durbin 递推求 LP 系数
3. LP 系数转换为 LSP（Line Spectral Pairs），便于量化和插值
4. LSP 用 MA 预测 + 分裂矢量量化（Split VQ）编码

自适应码本（基音预测）
-----------------------

自适应码本实现**长时预测**（基音周期预测）：

- 搜索范围：20-143 samples（对应基音频率 56-400 Hz）
- 子帧 1：开环搜索确定整数延迟，闭环搜索 1/3 分数精度
- 子帧 2：在子帧 1 延迟附近 ±5 范围搜索

代数码本（固定码本）
---------------------

G.729 的固定码本采用**代数结构**——这是"CS-ACELP"名称的由来：

- 40 个位置（5ms 子帧）分为 4 个轨道
- 每个轨道放置 1 个脉冲（±1）
- 4 个脉冲的位置和符号用 13 bit 编码
- 共轭结构：利用对称性减少搜索复杂度

G.729 变体
===========

.. list-table::
   :header-rows: 1
   :widths: 15 15 15 20 35

   * - 变体
     - 码率
     - 复杂度
     - 质量
     - 说明
   * - G.729
     - 8 kbps
     - 20 MIPS
     - MOS 3.9
     - 原始版本
   * - G.729a
     - 8 kbps
     - 10 MIPS
     - MOS 3.7
     - 简化版，降低复杂度
   * - G.729b
     - 8/0 kbps
     - 20 MIPS
     - 同 G.729
     - 增加 VAD/DTX/CNG
   * - G.729ab
     - 8/0 kbps
     - 10 MIPS
     - 同 G.729a
     - G.729a + VAD/DTX/CNG
   * - G.729.1
     - 8-32 kbps
     - 更高
     - 更好
     - 可伸缩宽带扩展

**G.729a** 是最常用的变体，它简化了码本搜索算法，复杂度减半，质量略有下降但在实际使用中差异不大。

G.729b 的 VAD/DTX
-------------------

G.729b 增加了静音检测和不连续传输：

- **VAD**：基于全带能量、低频能量、过零率和 LSF 距离的四维判决
- **SID 帧**：静音期间每 8 帧发送一个 15 bit 的 SID（Silence Insertion Descriptor）帧
- **CNG**：接收端根据 SID 帧生成舒适噪声
- 带宽节省：典型通话中约 50-60%

RTP 打包
========

.. code-block:: text

   a=rtpmap:18 G729/8000
   a=fmtp:18 annexb=yes

- RTP payload type = **18**
- 每帧 10 bytes（80 bits），通常 2 帧/包（20ms）= 20 bytes payload
- SID 帧 = 2 bytes
- ``annexb=yes`` 表示支持 VAD/DTX

G.729 vs Opus 低码率对比
==========================

.. list-table::
   :header-rows: 1
   :widths: 25 35 35

   * - 特性
     - G.729a
     - Opus @ 8 kbps
   * - 码率
     - 8 kbps
     - 8 kbps
   * - 采样率
     - 8 kHz
     - 8 kHz（NB 模式）
   * - MOS
     - 3.7
     - 3.5-3.8
   * - 帧长
     - 10 ms
     - 20 ms（默认）
   * - 算法延迟
     - 15 ms
     - 25 ms
   * - FEC
     - 无
     - 内置
   * - 自适应码率
     - 无
     - 6-510 kbps
   * - 专利
     - 2017 年过期
     - 免费

在 8 kbps 窄带场景下，G.729a 和 Opus 质量接近。但 Opus 的优势在于内置 FEC 和自适应码率——在有丢包的网络中，Opus 的实际表现通常更好。

在 WebRTC 中的位置
===================

WebRTC 规范没有要求支持 G.729，主流浏览器也不内置 G.729 解码器。但在以下场景仍然重要：

1. **SIP 中继**：许多运营商的 SIP trunk 仍以 G.729 为主
2. **语音网关**：PSTN/VoIP 网关需要 G.729 转码
3. **嵌入式设备**：低带宽 IoT 语音通信
4. **FreeSWITCH/Asterisk**：通过 mod_bcg729 等模块支持

小结
====

G.729 用 8 kbps 实现了接近 toll quality 的语音，是 CELP 编码家族的经典之作。理解它的 LP 分析、自适应码本和代数码本搜索，是理解现代语音编码器（包括 Opus 的 SILK 模式和 AMR）的基础。

虽然在 WebRTC 时代 Opus 已经取代了 G.729 的大部分应用场景，但在 VoIP 互通和低带宽场景中，G.729 仍然是重要的编码选项。
