###################
Audio Opus Codec
###################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============
**Abstract** Opus Codec
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ =============



.. contents::
   :local:

概述
=============

Opus 是 IETF 标准化的开源音频编解码器（RFC 6716），是 WebRTC 的**强制实现**（mandatory-to-implement）音频编解码器。
它由 Skype 的 **SILK** 语音编码器和 Xiph.Org 的 **CELT** 音乐编码器融合而成，兼顾语音和音乐的优秀表现。

**为什么 Opus 是 WebRTC 的首选？**

- 唯一被 WebRTC 规范要求所有实现必须支持的音频编解码器
- 6 kb/s ~ 510 kb/s 的超宽比特率范围，覆盖电话到高保真音乐
- 5 ms 的算法延迟，满足实时交互需求
- 内置 FEC 和带宽自适应，天然适合不稳定网络
- 从窄带（8 kHz）到全频带（48 kHz）无缝切换，无需重新协商

核心特性一览：

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 特性
     - 说明
   * - 比特率
     - 6 kb/s ~ 510 kb/s，支持 CBR 和 VBR
   * - 采样率
     - 8 kHz（窄带）~ 48 kHz（全频带）
   * - 帧大小
     - 2.5 ms / 5 ms / 10 ms / 20 ms / 40 ms / 60 ms
   * - 声道
     - 单声道、立体声，最多 255 通道（多流）
   * - 算法延迟
     - 最低 5 ms（CELT-only），典型 26.5 ms（SILK 20ms 帧）
   * - 丢包恢复
     - 内置 In-band FEC + PLC + DRED（Opus 1.5+）
   * - 自适应
     - 比特率、带宽、帧大小、模式均可逐帧动态调整


互联网音频编码需求
=====================

`Requirements for an Internet Audio Codec <https://tools.ietf.org/html/rfc6366>`_

音频带宽定义
----------------------------------

.. list-table::
   :header-rows: 1
   :widths: 30 20 20

   * - 名称
     - 音频带宽
     - 有效采样率
   * - NB（窄带 narrowband）
     - 4 kHz
     - 8 kHz
   * - MB（中带 medium-band）
     - 6 kHz
     - 12 kHz
   * - WB（宽带 wideband）
     - 8 kHz
     - 16 kHz
   * - SWB（超宽带 super-wideband）
     - 12 kHz
     - 24 kHz
   * - FB（全频带 fullband）
     - 20 kHz
     - 48 kHz

应用场景
----------------------------------

- 点对点通话（VoIP）
- 多方会议（Conferencing）
- 远程呈现（Telepresence）
- 游戏内语音（In-game voice chat）
- 远程音乐表演 / 在线音乐教学
- 延迟容忍型网络 / 一键通（Push-to-talk）


编解码器架构
==================================

Opus 的设计核心是将两种互补的编码技术融合到一个统一框架中：

.. code-block:: text

   ┌─────────────────────────────────────────────────────────────┐
   │                    Opus Encoder                             │
   │                                                             │
   │  PCM Input ──► ┌──────────────────────────────────────┐     │
   │                │           Mode Decision              │     │
   │                │  (根据信号类型/比特率/带宽自动选择)      │     │
   │                └───┬──────────┬──────────┬────────────┘     │
   │                    │          │          │                   │
   │              ┌─────▼────┐ ┌──▼───────┐ ┌▼──────────────┐   │
   │              │   SILK   │ │  Hybrid  │ │    CELT       │   │
   │              │  (LP层)  │ │(SILK+CELT)│ │  (MDCT层)     │   │
   │              │          │ │          │ │               │   │
   │              │ 语音优化  │ │ 超宽带/   │ │ 音乐/低延迟   │   │
   │              │ NB~WB    │ │ 全频带    │ │ NB~FB        │   │
   │              │ ≥10ms帧  │ │ 10/20ms帧│ │ ≥2.5ms帧     │   │
   │              └─────┬────┘ └──┬───────┘ └┬──────────────┘   │
   │                    │         │          │                   │
   │                    └─────────┴──────────┘                   │
   │                              │                              │
   │                    ┌─────────▼──────────┐                   │
   │                    │   Range Encoder    │                   │
   │                    │  (熵编码器)         │                   │
   │                    └─────────┬──────────┘                   │
   │                              │                              │
   │                    Opus Packet (TOC + Payload)               │
   └──────────────────────────────┴──────────────────────────────┘


三种操作模式
----------------------------------

.. list-table::
   :header-rows: 1
   :widths: 20 15 15 50

   * - 模式
     - 带宽
     - 帧大小
     - 适用场景
   * - **SILK-only**
     - NB / MB / WB
     - 10~60 ms
     - 低比特率语音通话，电话级质量。利用线性预测（LP）对语音频谱建模
   * - **Hybrid**
     - SWB / FB
     - 10 / 20 ms
     - 中高比特率超宽带/全频带语音。低频用 SILK，高频用 CELT 补充
   * - **CELT-only**
     - NB ~ FB
     - 2.5~20 ms
     - 音乐、低延迟语音。使用 MDCT 变换编码，最低仅 5 ms 延迟

模式选择是自动的——编码器根据信号类型（语音/音乐）、目标比特率、带宽等参数，逐帧决定使用哪种模式。
也可以通过 ``OPUS_SET_SIGNAL`` 和 ``OPUS_SET_APPLICATION`` 手动引导。


SILK 层详解
==================================

SILK 是 Opus 中负责语音编码的层，源自 Skype 的同名编解码器，基于 **CELP**（Code-Excited Linear Prediction）框架。

编码原理
----------------------------------

CELP 的核心思想是：语音信号 = 声道滤波器（声道模型）× 激励信号（残差）

.. code-block:: text

   PCM 输入
     │
     ▼
   ┌────────────────────┐
   │  线性预测分析 (LP)   │  ← 提取声道特征（LPC 系数 → 转为 LSF/LSP）
   │  10~16 阶           │
   └────────┬───────────┘
            │
            ▼
   ┌────────────────────┐
   │  LP 残差计算        │  ← 原始信号 - LP 预测信号 = 残差
   └────────┬───────────┘
            │
            ▼
   ┌────────────────────┐
   │  长时预测 (LTP)     │  ← 利用基音周期（pitch）对残差建模
   │  又称 Pitch Filter  │     消除浊音的周期性冗余
   └────────┬───────────┘
            │
            ▼
   ┌────────────────────┐
   │  激励量化           │  ← 对最终残差进行标量/向量量化
   │  (Excitation)       │
   └────────┬───────────┘
            │
            ▼
   Range Encoder 输出

关键参数：

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 参数
     - 说明
   * - LP 阶数
     - NB: 10 阶, MB: 12 阶, WB: 16 阶
   * - 子帧
     - 每帧分为 4 个子帧（20ms 帧时每子帧 5ms）
   * - 基音周期
     - 搜索范围 2~18 ms，对浊音（voiced speech）编码至关重要
   * - LSF 量化
     - LP 系数转为 Line Spectral Frequencies，使用多级 VQ 量化
   * - 噪声整形
     - 通过感知加权滤波器将量化噪声推入不敏感频段


CELT 层详解
==================================

CELT（Constrained Energy Lapped Transform）是 Opus 中负责通用音频/音乐编码的层，基于 MDCT 变换编码。

编码原理
----------------------------------

.. code-block:: text

   PCM 输入
     │
     ▼
   ┌─────────────────────┐
   │  预加重 (Pre-emphasis)│  ← 减少频谱泄漏
   └────────┬────────────┘
            │
            ▼
   ┌─────────────────────┐
   │  MDCT 变换           │  ← 时域 → 频域，窗口重叠 2.5ms
   │  (Modified DCT)      │
   └────────┬────────────┘
            │
            ▼
   ┌─────────────────────┐
   │  频带划分            │  ← MDCT 系数按 Bark 尺度分组
   │  (Bark-scale bands)  │     每个频带独立处理
   └────────┬────────────┘
            │
            ├── 能量编码 ──► 粗量化（6dB 精度）+ 细量化（可变精度）
            │                用前帧预测 + 熵编码
            │
            └── 形状编码 ──► PVQ（Pyramid Vector Quantization）
                             归一化到单位球面，用 K 个有符号脉冲编码

关键设计：

- **Bark 尺度频带**：MDCT 系数分组近似临界带宽，低频细分、高频粗分，符合人耳感知
- **能量-形状分离**：每个频带先编码能量（响度），再编码归一化后的频谱形状
- **PVQ 量化**：将每个频带的归一化频谱向量投影到 N 维单位球面，用 K 个脉冲的组合表示
- **隐式比特分配**：编码器和解码器使用相同算法分配比特，无需额外信令
- **带间折叠（Band Folding）**：当某个频带比特不足时，复制其他频带的形状作为替代，避免频谱空洞


Hybrid 模式
==================================

当需要超宽带（SWB）或全频带（FB）的语音质量时，Opus 同时启用 SILK 和 CELT：

.. code-block:: text

                    ┌──────────────────────────────────┐
                    │          频率 (Hz)                │
   0          8000          16000         24000        │
   │◄─── SILK (LP) ────►│                              │
   │                     │◄────── CELT (MDCT) ────────►│
                    └──────────────────────────────────┘

- **SILK** 负责 0 ~ 8 kHz 的低频语音部分（线性预测对语音基频和共振峰效率最高）
- **CELT** 负责 8 kHz 以上的高频部分（变换编码对高频和瞬态信号更高效）
- 带间平滑过渡通过交叉衰减（crossfade）实现
- Hybrid 模式仅在 SWB/FB + 10/20 ms 帧时可用


内部分帧与 TOC
===================================

Opus 包（packet）的结构定义了如何将编码数据封装在 RTP 载荷中。

TOC 字节
-----------------------------------

每个 Opus 包的第一个字节是 TOC（Table Of Contents），编码了该包的配置信息：

::

    0 1 2 3 4 5 6 7
   +-+-+-+-+-+-+-+-+
   | config  |s| c |
   +-+-+-+-+-+-+-+-+

- **config** (bit 0-4)：5 位，表示操作模式 + 音频带宽 + 帧大小（共 32 种配置）
- **s** (bit 5)：0 = 单声道，1 = 立体声
- **c** (bit 6-7)：帧数编码

::

   +---------+-----------+-----------+-------------------+
   | Config  | Mode      | Bandwidth | Frame Sizes       |
   +---------+-----------+-----------+-------------------+
   | 0...3   | SILK-only | NB        | 10, 20, 40, 60 ms |
   | 4...7   | SILK-only | MB        | 10, 20, 40, 60 ms |
   | 8...11  | SILK-only | WB        | 10, 20, 40, 60 ms |
   | 12...13 | Hybrid    | SWB       | 10, 20 ms         |
   | 14...15 | Hybrid    | FB        | 10, 20 ms         |
   | 16...19 | CELT-only | NB        | 2.5, 5, 10, 20 ms |
   | 20...23 | CELT-only | WB        | 2.5, 5, 10, 20 ms |
   | 24...27 | CELT-only | SWB       | 2.5, 5, 10, 20 ms |
   | 28...31 | CELT-only | FB        | 2.5, 5, 10, 20 ms |
   +---------+-----------+-----------+-------------------+

帧数编码 ``c`` 的含义：

- ``0``：1 帧
- ``1``：2 帧，压缩大小相同
- ``2``：2 帧，压缩大小不同
- ``3``：任意数量的帧（CBR 或 VBR，由后续字节指定）

RTP 时间戳递增
-----------------------------------

.. list-table::
   :header-rows: 1
   :widths: 20 20 10 10 10 10 10 10

   * - 类型
     - 采样率
     - 2.5ms
     - 5ms
     - 10ms
     - 20ms
     - 40ms
     - 60ms
   * - 时间戳增量
     - 全部
     - 120
     - 240
     - 480
     - 960
     - 1920
     - 2880
   * - voice 模式
     - NB~FB
     - x
     - x
     - o
     - o
     - o
     - o
   * - audio 模式
     - NB~FB
     - o
     - o
     - o
     - o
     - x
     - x

``o`` 表示推荐，``x`` 表示可用但非最优。WebRTC 中最常用的是 20ms 帧（960 个采样 @48kHz）。

.. tip::

   解析 TOC 字节的快速方法：

   .. code-block:: c

      uint8_t toc = opus_packet[0];
      int config = toc >> 3;           // 高 5 位
      int stereo = (toc >> 2) & 0x01;  // 第 6 位
      int frame_code = toc & 0x03;     // 低 2 位


控制参数详解
===================================

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - 参数
     - CTL 宏
     - 说明
   * - 比特率
     - ``OPUS_SET_BITRATE``
     - 目标比特率（bps）。语音通话建议 24~32 kbps，高质量音乐 64~128 kbps
   * - 复杂度
     - ``OPUS_SET_COMPLEXITY``
     - 0~10。越高 CPU 越高、质量越好。实时场景建议 5~8
   * - 信号类型
     - ``OPUS_SET_SIGNAL``
     - ``OPUS_AUTO`` / ``OPUS_SIGNAL_VOICE`` / ``OPUS_SIGNAL_MUSIC``
   * - 应用类型
     - ``OPUS_SET_APPLICATION``
     - ``OPUS_APPLICATION_VOIP`` / ``OPUS_APPLICATION_AUDIO`` / ``OPUS_APPLICATION_RESTRICTED_LOWDELAY``
   * - 带宽
     - ``OPUS_SET_BANDWIDTH``
     - ``OPUS_AUTO`` / ``OPUS_BANDWIDTH_NARROWBAND`` ~ ``OPUS_BANDWIDTH_FULLBAND``
   * - VBR
     - ``OPUS_SET_VBR``
     - 1=VBR（默认），0=CBR
   * - VBR 约束
     - ``OPUS_SET_VBR_CONSTRAINT``
     - 1=受约束的 VBR（不超过目标太多）
   * - 丢包率
     - ``OPUS_SET_PACKET_LOSS_PERC``
     - 期望丢包率（0~100），影响 FEC 冗余量
   * - FEC
     - ``OPUS_SET_INBAND_FEC``
     - 1=启用 In-band FEC
   * - DTX
     - ``OPUS_SET_DTX``
     - 1=启用不连续传输（静音时降低比特率）


FEC（前向纠错）
-----------------------------------

Opus 的 In-band FEC 仅在 SILK 层工作（因此 ptime ≥ 10ms）：

**原理**：编码器将感知上重要的帧（如语音起始、瞬态）以较低比特率重新编码，
附加到**下一个**包中。解码端收到当前包后，如果发现前一个包丢失，可以从当前包中提取低比特率冗余来恢复。

.. code-block:: text

   时间 ──────────────────────────────►

   Packet N:   [帧N 正常编码]
   Packet N+1: [帧N+1 正常编码] + [帧N 低比特率 FEC 冗余]
   Packet N+2: [帧N+2 正常编码] + [帧N+1 低比特率 FEC 冗余]

   如果 Packet N 丢失：
   收到 Packet N+1 后 → 用其中的 FEC 数据恢复帧 N（质量略低但远好于 PLC）

**启用条件**：

1. ptime ≥ 10ms（否则 Opus 工作在纯 CELT 模式，无 FEC）
2. 比特率不能太低（需要额外空间存放 LBRR 包），语音建议 ≥ 24 kbps
3. 必须通过 ``OPUS_SET_INBAND_FEC(1)`` 启用
4. 必须通过 ``OPUS_SET_PACKET_LOSS_PERC`` 告知编码器期望丢包率

**编码端配置**：

.. code-block:: c

   opus_encoder_ctl(encoder, OPUS_SET_INBAND_FEC(1));
   opus_encoder_ctl(encoder, OPUS_SET_PACKET_LOSS_PERC(20));  // 预期 20% 丢包

**解码端使用**：

.. code-block:: c

   // 检测到 packet N 丢失，但已收到 packet N+1
   // 第一步：用 N+1 的 FEC 数据恢复帧 N
   opus_decoder_ctl(decoder, OPUS_GET_LAST_PACKET_DURATION(&frame_size));
   opus_decode(decoder,
       packet_n1_data, packet_n1_len,
       pcm_output, frame_size,
       1);     // decode_fec = 1，从当前包提取前一帧的 FEC
   play_audio(pcm_output, frame_size);

   // 第二步：正常解码帧 N+1
   opus_decode(decoder,
       packet_n1_data, packet_n1_len,
       pcm_output, frame_size,
       0);     // decode_fec = 0，正常解码
   play_audio(pcm_output, frame_size);


DTX（不连续传输）
-----------------------------------

当检测到静音或背景噪声时，DTX 将发送频率降低到每 400ms 一帧，大幅节省带宽：

.. code-block:: c

   opus_encoder_ctl(encoder, OPUS_SET_DTX(1));

.. note::

   DTX 在多方会议中特别有用——大多数时间只有一两个人在说话，其他人的音频流都处于静默状态。


DRED：深度冗余（Opus 1.5+）
===================================

**Deep REDundancy (DRED)** 是 Opus 1.5（2024 年 3 月发布）引入的革命性丢包恢复技术，在 Opus 1.6（2025 年 12 月）中进一步改进。

传统 FEC vs DRED
-----------------------------------

.. list-table::
   :header-rows: 1
   :widths: 20 40 40

   * - 特性
     - 传统 In-band FEC (LBRR)
     - DRED
   * - 冗余范围
     - 仅前 1 帧
     - 最多数秒的历史音频
   * - 额外带宽
     - 较高（低比特率重编码）
     - 每一帧的冗余副本成本极低（约为该帧正常比特率的 1/50），但由于同时携带约 1 秒（约 50 帧）历史，总开销约 12~32 kbps
   * - 技术基础
     - 传统信号处理
     - 深度学习（神经网络声码器）
   * - 恢复质量
     - 可接受
     - 接近原始
   * - 突发丢包
     - 只能恢复单帧
     - 可恢复数百毫秒甚至数秒

**工作原理**：

DRED 将过去的音频编码为 20 维声学特征向量，以极低比特率嵌入当前包中。
当接收端检测到丢包，可以用最近收到的包中的声学特征，通过神经网络声码器合成丢失的音频。

.. code-block:: text

   Packet N:   [帧N] + [DRED: 帧N-1到帧N-50的声学特征, ~32kbps 总开销]
   
   如果 Packet N-1 ~ N-10 全部丢失（突发丢包）：
   收到 Packet N → 用 DRED 声学特征合成 N-1 ~ N-10 的全部音频

启用 DRED（需要 libopus ≥ 1.5）：

.. code-block:: c

   opus_encoder_ctl(encoder, OPUS_SET_DRED_DURATION(400));  // 最多 400ms 冗余
   opus_decoder_ctl(decoder, OPUS_SET_DRED(1));


Deep PLC（深度丢包隐藏）
-----------------------------------

Opus 1.5 同时引入了基于深度学习的 PLC（Packet Loss Concealment）。
即使没有 FEC/DRED 冗余数据，解码器也能利用神经网络从之前的音频上下文中推断丢失的帧，
效果远好于传统的基于插值的 PLC。


SDP 协商参数
===================================

在 WebRTC 的 SDP Offer/Answer 中，Opus 的参数通过 ``a=fmtp`` 行传递：

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - 参数
     - 默认值
     - 说明
   * - ``maxaveragebitrate``
     - (无限制)
     - 最大平均比特率（bps）。接收方的解码能力上限
   * - ``maxplaybackrate``
     - 48000
     - 最大回放采样率（Hz）。暗示发送方无需编码超过此频率的内容
   * - ``minptime``
     - 10
     - 最小包时间（ms）。影响 FEC 可用性
   * - ``stereo``
     - 0
     - 1=接收方希望收到立体声
   * - ``cbr``
     - 0
     - 1=使用恒定比特率
   * - ``useinbandfec``
     - 0
     - 1=接收方支持 FEC 解码
   * - ``usedtx``
     - 0
     - 1=发送方可以使用 DTX
   * - ``sprop-maxcapturerate``
     - 48000
     - 发送方最大采集采样率
   * - ``sprop-stereo``
     - 0
     - 1=发送方会发立体声

SDP 示例
-----------------------------------

典型的 WebRTC 语音通话 SDP：

.. code-block:: text

   m=audio 9 UDP/TLS/RTP/SAVPF 111
   a=rtpmap:111 opus/48000/2
   a=ptime:20
   a=maxptime:60
   a=fmtp:111 minptime=10; useinbandfec=1; usedtx=1

高质量音乐共享 SDP：

.. code-block:: text

   m=audio 9 UDP/TLS/RTP/SAVPF 111
   a=rtpmap:111 opus/48000/2
   a=ptime:20
   a=fmtp:111 stereo=1; sprop-stereo=1; maxaveragebitrate=128000; maxplaybackrate=48000

.. note::

   ``opus/48000/2`` 中的 ``48000`` 是 RTP 时钟速率（固定为 48kHz），``2`` 是 RTP 通道数（固定为 2）。
   这不代表实际采样率或声道数——实际由 ``fmtp`` 参数和编码器配置决定。


实际例子
===================================

例 1：C 语言完整编解码
-----------------------------------

使用 libopus 进行 PCM → Opus → PCM 的完整编解码流程：

.. code-block:: c

   #include <opus/opus.h>
   #include <stdio.h>
   #include <stdlib.h>
   #include <string.h>

   #define SAMPLE_RATE     48000
   #define CHANNELS        1
   #define FRAME_SIZE_MS   20
   #define FRAME_SIZE      (SAMPLE_RATE * FRAME_SIZE_MS / 1000)  // 960 samples
   #define MAX_PACKET_SIZE 4000

   int main(int argc, char *argv[]) {
       int err;

       // --- 创建编码器 ---
       OpusEncoder *encoder = opus_encoder_create(
           SAMPLE_RATE, CHANNELS, OPUS_APPLICATION_VOIP, &err);
       if (err != OPUS_OK) {
           fprintf(stderr, "创建编码器失败: %s\n", opus_strerror(err));
           return 1;
       }

       // 配置编码参数
       opus_encoder_ctl(encoder, OPUS_SET_BITRATE(24000));
       opus_encoder_ctl(encoder, OPUS_SET_COMPLEXITY(8));
       opus_encoder_ctl(encoder, OPUS_SET_SIGNAL(OPUS_SIGNAL_VOICE));
       opus_encoder_ctl(encoder, OPUS_SET_INBAND_FEC(1));
       opus_encoder_ctl(encoder, OPUS_SET_PACKET_LOSS_PERC(10));

       // --- 创建解码器 ---
       OpusDecoder *decoder = opus_decoder_create(
           SAMPLE_RATE, CHANNELS, &err);
       if (err != OPUS_OK) {
           fprintf(stderr, "创建解码器失败: %s\n", opus_strerror(err));
           return 1;
       }

       // --- 编码一帧 ---
       opus_int16 pcm_input[FRAME_SIZE * CHANNELS];
       unsigned char opus_packet[MAX_PACKET_SIZE];

       // 生成测试信号：1kHz 正弦波
       for (int i = 0; i < FRAME_SIZE; i++) {
           pcm_input[i] = (opus_int16)(32767.0 * sin(2.0 * 3.14159265 * 1000.0 * i / SAMPLE_RATE));
       }

       int packet_len = opus_encode(encoder, pcm_input, FRAME_SIZE,
                                     opus_packet, MAX_PACKET_SIZE);
       if (packet_len < 0) {
           fprintf(stderr, "编码失败: %s\n", opus_strerror(packet_len));
           return 1;
       }
       printf("编码: %d samples → %d bytes (%.1f kbps)\n",
              FRAME_SIZE, packet_len, packet_len * 8.0 * 1000 / FRAME_SIZE_MS / 1000);

       // 解析 TOC 字节
       uint8_t toc = opus_packet[0];
       printf("TOC: config=%d, stereo=%d, frame_code=%d\n",
              toc >> 3, (toc >> 2) & 1, toc & 3);

       // --- 解码一帧 ---
       opus_int16 pcm_output[FRAME_SIZE * CHANNELS];
       int decoded_samples = opus_decode(decoder, opus_packet, packet_len,
                                          pcm_output, FRAME_SIZE, 0);
       if (decoded_samples < 0) {
           fprintf(stderr, "解码失败: %s\n", opus_strerror(decoded_samples));
           return 1;
       }
       printf("解码: %d bytes → %d samples\n", packet_len, decoded_samples);

       // --- 模拟丢包 + FEC 恢复 ---
       // 假设前一帧丢失，用当前包的 FEC 恢复
       opus_int16 pcm_fec[FRAME_SIZE * CHANNELS];
       int fec_samples = opus_decode(decoder, opus_packet, packet_len,
                                      pcm_fec, FRAME_SIZE, 1);  // decode_fec=1
       printf("FEC 恢复: %d samples\n", fec_samples);

       opus_encoder_destroy(encoder);
       opus_decoder_destroy(decoder);
       return 0;
   }

编译与运行：

.. code-block:: bash

   # Ubuntu/Debian
   sudo apt install libopus-dev

   # macOS
   brew install opus

   # 编译
   gcc -o opus_demo opus_demo.c -lopus -lm

   # 运行
   ./opus_demo


例 2：Python 编解码（PyOgg）
-----------------------------------

.. code-block:: python

   import pyogg
   import struct
   import math

   # --- 编码器配置 ---
   encoder = pyogg.OpusBufferedEncoder()
   encoder.set_application("voip")
   encoder.set_sampling_frequency(48000)
   encoder.set_channels(1)
   encoder.set_frame_size(20)  # 20ms

   # --- 解码器 ---
   decoder = pyogg.OpusDecoder()
   decoder.set_channels(1)
   decoder.set_sampling_frequency(48000)

   # 生成 20ms 的 1kHz 正弦波测试信号 (48000 * 0.02 = 960 samples)
   samples = 960
   pcm_data = b""
   for i in range(samples):
       sample = int(32767 * math.sin(2 * math.pi * 1000 * i / 48000))
       pcm_data += struct.pack("<h", sample)

   # 编码
   encoded_packets = encoder.buffered_encode(
       memoryview(bytearray(pcm_data)),
       flush=True
   )

   for packet, _, _ in encoded_packets:
       print(f"编码: {samples} samples → {len(packet)} bytes")

       # 解码
       decoded_pcm = decoder.decode(memoryview(bytearray(packet)))
       print(f"解码: {len(packet)} bytes → {len(decoded_pcm)//2} samples")

安装依赖：

.. code-block:: bash

   pip install PyOgg


例 3：WebRTC 中配置 Opus（JavaScript）
--------------------------------------------

在浏览器中通过 WebRTC API 配置 Opus 参数：

.. code-block:: javascript

   const pc = new RTCPeerConnection();

   // 获取音频轨道
   const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
   const audioTrack = stream.getAudioTracks()[0];

   // 添加轨道并获取 transceiver
   const transceiver = pc.addTransceiver(audioTrack, { direction: 'sendrecv' });

   // 设置 Opus 为首选编解码器
   const codecs = RTCRtpReceiver.getCapabilities('audio').codecs;
   const opusCodecs = codecs.filter(c => c.mimeType === 'audio/opus');
   const otherCodecs = codecs.filter(c => c.mimeType !== 'audio/opus');
   transceiver.setCodecPreferences([...opusCodecs, ...otherCodecs]);

   // 创建 Offer
   const offer = await pc.createOffer();

   // 在 SDP 中设置 Opus 参数（useinbandfec, stereo 等）
   // 注意：现代浏览器推荐用 setCodecPreferences 而非 SDP munging
   let sdp = offer.sdp;

   // 查看 Opus 相关的 SDP 行
   const opusLines = sdp.split('\n').filter(l =>
       l.includes('opus') || l.includes('111')
   );
   console.log('Opus SDP lines:', opusLines);

   await pc.setLocalDescription(offer);

通过 SDP munging 启用 FEC（不推荐但有时需要）：

.. code-block:: javascript

   function enableOpusFec(sdp) {
       return sdp.replace(
           /(a=fmtp:111 .*)/,
           '$1;useinbandfec=1'
       );
   }

   function setOpusBitrate(sdp, maxBitrate) {
       return sdp.replace(
           /(a=fmtp:111 .*)/,
           `$1;maxaveragebitrate=${maxBitrate}`
       );
   }

通过 ``RTCRtpSender.setParameters()`` 动态调整比特率：

.. code-block:: javascript

   const sender = pc.getSenders().find(s => s.track?.kind === 'audio');
   const params = sender.getParameters();
   if (params.encodings.length > 0) {
       params.encodings[0].maxBitrate = 32000;  // 32 kbps
   }
   await sender.setParameters(params);


例 4：FFmpeg 处理 Opus
-----------------------------------

.. code-block:: bash

   # WAV 转 Opus（VoIP 模式，24kbps）
   ffmpeg -i input.wav -c:a libopus -b:a 24k -application voip output.opus

   # Opus 转 WAV
   ffmpeg -i input.opus -c:a pcm_s16le output.wav

   # 从视频中提取音频为 Opus
   ffmpeg -i video.mp4 -vn -c:a libopus -b:a 64k audio.opus

   # 高质量音乐编码（立体声，128kbps）
   ffmpeg -i music.wav -c:a libopus -b:a 128k -application audio music.opus

   # 指定帧大小和复杂度
   ffmpeg -i input.wav -c:a libopus -b:a 32k \
       -frame_duration 20 -compression_level 8 output.opus

   # 推送 Opus RTP 流
   ffmpeg -re -i input.wav -c:a libopus -b:a 48k \
       -f rtp rtp://127.0.0.1:5004

   # 接收 Opus RTP 流（需要 SDP 文件描述流格式）
   ffmpeg -protocol_whitelist file,udp,rtp -i stream.sdp -c:a pcm_s16le output.wav


例 5：opus-tools 命令行
-----------------------------------

.. code-block:: bash

   # 安装
   # Ubuntu: sudo apt install opus-tools
   # macOS:  brew install opus-tools

   # 编码
   opusenc --bitrate 64 input.wav output.opus

   # 高质量编码
   opusenc --bitrate 128 --comp 10 input.wav hq_output.opus

   # 低延迟编码
   opusenc --bitrate 32 --framesize 10 input.wav lowdelay.opus

   # 解码
   opusdec output.opus decoded.wav

   # 查看 Opus 文件信息
   opusinfo output.opus

   # Opus 文件的详细信息示例输出：
   # Processing file "output.opus"...
   # Channels: 2
   # Rate: 48000
   # Pre-skip: 356
   # Playback gain: 0 dB
   # Encoder: libopus 1.5.2


例 6：Go + Pion WebRTC 中的 Opus 处理
--------------------------------------------

在 Go 后端接收 WebRTC 音频并解码 Opus：

.. code-block:: go

   package main

   import (
       "fmt"
       "github.com/pion/webrtc/v4"
       "gopkg.in/hraban/opus.v2"
   )

   func handleAudioTrack(track *webrtc.TrackRemote) {
       // 创建 Opus 解码器
       dec, err := opus.NewDecoder(48000, 1)
       if err != nil {
           panic(err)
       }

       pcmBuf := make([]int16, 960) // 20ms @ 48kHz
       buf := make([]byte, 1500)

       for {
           n, _, readErr := track.Read(buf)
           if readErr != nil {
               return
           }

           // 解码 Opus → PCM
           samplesDecoded, decErr := dec.Decode(buf[:n], pcmBuf)
           if decErr != nil {
               fmt.Printf("解码错误: %v\n", decErr)
               continue
           }

           fmt.Printf("解码: %d bytes → %d samples\n", n, samplesDecoded)
           // 将 pcmBuf[:samplesDecoded] 写入文件或送入语音识别引擎...
       }
   }

Go 的 Opus 绑定安装：

.. code-block:: bash

   # 需要系统安装 libopus
   sudo apt install libopus-dev   # Ubuntu
   brew install opus               # macOS

   # Go 依赖
   go get gopkg.in/hraban/opus.v2


常见问题与调优
===================================

比特率选择指南
-----------------------------------

.. list-table::
   :header-rows: 1
   :widths: 25 20 55

   * - 场景
     - 建议比特率
     - 说明
   * - 电话级语音
     - 8~16 kbps
     - 窄带，SILK-only，省带宽
   * - VoIP 通话
     - 20~32 kbps
     - 宽带/超宽带，清晰语音
   * - 高质量语音
     - 32~64 kbps
     - 全频带，接近面对面
   * - 音乐共享
     - 64~128 kbps
     - 立体声，CELT-only 或 Hybrid
   * - 高保真音乐
     - 128~256 kbps
     - 立体声全频带，透明质量

常见问题
-----------------------------------

**Q: 为什么 Opus 的 RTP 时钟速率固定是 48000？**

A: 这是 RFC 7587 的规定。不管实际采样率是 8kHz 还是 48kHz，RTP 时间戳一律按 48kHz 计算。
这简化了时间戳处理——不需要因为采样率变化而调整时间戳。

**Q: 为什么 SDP 中 opus 的通道数固定是 2？**

A: ``a=rtpmap:111 opus/48000/2`` 中的 ``2`` 不表示立体声，而是 Opus RTP 的固定参数。
实际声道数由 ``fmtp`` 中的 ``stereo`` 参数和编码器配置决定。

**Q: FEC 启用后为什么看不到效果？**

A: 常见原因：

1. 帧大小 < 10ms（此时 Opus 使用纯 CELT 模式，不支持 FEC）
2. 比特率太低（没有空间放 FEC 冗余数据）
3. 没有设置 ``OPUS_SET_PACKET_LOSS_PERC``（编码器不知道需要添加 FEC）
4. 解码端没有用 ``decode_fec=1`` 调用 ``opus_decode``

**Q: 如何判断当前帧使用的是什么模式？**

A: 解析 TOC 字节的 config 字段：

.. code-block:: c

   int bandwidth;
   opus_packet_get_bandwidth(opus_packet);  // 返回 OPUS_BANDWIDTH_*

   int nb_frames;
   nb_frames = opus_packet_get_nb_frames(opus_packet, packet_len);

   int nb_samples;
   nb_samples = opus_packet_get_nb_samples(opus_packet, packet_len, 48000);


术语表
==================================

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - 术语
     - 说明
   * - CELP
     - Code-Excited Linear Prediction，码本激励线性预测
   * - MDCT
     - Modified Discrete Cosine Transform，修正离散余弦变换
   * - LP
     - Linear Prediction，线性预测
   * - LPC
     - Linear Predictive Coding，线性预测编码
   * - LSF/LSP
     - Line Spectral Frequencies/Pairs，线谱频率/对
   * - LTP
     - Long-Term Prediction，长时预测（基音预测）
   * - PVQ
     - Pyramid Vector Quantization，金字塔向量量化
   * - PLC
     - Packet Loss Concealment，丢包隐藏
   * - DRED
     - Deep REDundancy，深度冗余
   * - LBRR
     - Low Bitrate Redundancy，低比特率冗余（传统 FEC）
   * - DTX
     - Discontinuous Transmission，不连续传输
   * - CBR
     - Constant Bit Rate，恒定比特率
   * - VBR
     - Variable Bit Rate，可变比特率
   * - TOC
     - Table Of Contents，内容表（Opus 包首字节）


参考资料
===================================

标准文档

- `RFC 6716 - Definition of the Opus Audio Codec <https://tools.ietf.org/html/rfc6716>`_
- `RFC 7587 - RTP Payload Format for the Opus Speech and Audio Codec <https://tools.ietf.org/html/rfc7587>`_
- `RFC 7845 - Ogg Encapsulation for the Opus Audio Codec <https://tools.ietf.org/html/rfc7845>`_
- `RFC 8251 - Updates to the Opus Audio Codec <https://tools.ietf.org/html/rfc8251>`_
- `RFC 8486 - Ambisonics in an Ogg Opus Container <https://tools.ietf.org/html/rfc8486>`_
- `RFC 6366 - Requirements for an Internet Audio Codec <https://tools.ietf.org/html/rfc6366>`_

官方资源

- `Opus 官网 <https://opus-codec.org/>`_
- `Opus API 文档 <https://opus-codec.org/docs/>`_
- `Opus 源码 <https://gitlab.xiph.org/xiph/opus>`_
- `Opus FAQ <https://wiki.xiph.org/OpusFAQ>`_

版本发布

- `libopus 1.5 发布说明（含 DRED / Deep PLC） <https://opus-codec.org/release/stable/2024/03/04/libopus-1_5.html>`_
- `libopus 1.6 发布说明 <https://opus-codec.org/release/stable/2025/12/15/libopus-1_6.html>`_
- `DRED 标准化草案 <https://datatracker.ietf.org/doc/draft-valin-opus-dred/>`_
