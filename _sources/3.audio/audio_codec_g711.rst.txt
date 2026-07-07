.. _audio_codec_g711:

======================
G.711 — PSTN 的基石
======================

.. contents:: 目录
   :local:
   :depth: 2

概述
====

G.711 是 ITU-T 于 1972 年发布的语音编码标准，是全球公共交换电话网络（PSTN）的基础编码。它采用脉冲编码调制（PCM），将模拟语音以 8kHz 采样、8bit 量化，产生 **64 kbps** 的恒定码率。

尽管已有 50 多年历史，G.711 至今仍是 VoIP 和 WebRTC 中最重要的兼容性编码——几乎所有语音设备都支持它。

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 属性
     - 值
   * - 标准
     - ITU-T G.711 (1972)
   * - 采样率
     - 8 kHz
   * - 量化位数
     - 8 bit（非线性压扩后）
   * - 码率
     - 64 kbps
   * - 帧长
     - 无固定帧长（逐样本编码）
   * - 算法延迟
     - 0.125 ms（1 个采样点）
   * - 频率范围
     - 300 - 3400 Hz
   * - MOS
     - ~4.1
   * - 专利
     - 无（已过期）

压扩法则
========

人耳对声音的感知是对数的——小信号的变化比大信号更敏感。G.711 利用这一特性，采用**非线性量化**（压扩，Companding）：对小信号用更多量化级，对大信号用更少量化级。

这样，8bit 非线性量化的效果接近 13-14bit 线性量化。

μ-law（PCMU）
--------------

北美和日本使用，RTP payload type = **0**。

压缩公式：

.. math::

   F(x) = \text{sgn}(x) \cdot \frac{\ln(1 + \mu |x|)}{\ln(1 + \mu)}, \quad -1 \leq x \leq 1

其中 μ = 255。

编码步骤：

1. 输入 14bit 线性 PCM 样本（有符号）
2. 加偏移 33（bias），避免对数函数在零点附近的问题
3. 取符号位（1bit）
4. 确定段号（3bit）：找到最高有效位的位置
5. 取段内量化值（4bit）
6. 组合为 8bit，按位取反

.. code-block:: c

   /* μ-law 编码（简化版） */
   static const int16_t BIAS = 0x84;   /* 132, 即 33 << 2 */
   static const int16_t CLIP = 32635;

   uint8_t linear_to_ulaw(int16_t sample) {
       int sign = (sample >> 8) & 0x80;
       if (sign) sample = -sample;
       if (sample > CLIP) sample = CLIP;
       sample += BIAS;

       int exponent = 7;
       int mask = 0x4000;
       while (!(sample & mask) && exponent > 0) {
           exponent--;
           mask >>= 1;
       }
       int mantissa = (sample >> (exponent + 3)) & 0x0F;
       uint8_t ulawbyte = ~(sign | (exponent << 4) | mantissa);
       return ulawbyte;
   }

A-law（PCMA）
--------------

欧洲和中国使用，RTP payload type = **8**。

压缩公式：

.. math::

   F(x) = \begin{cases}
   \frac{A \cdot |x|}{1 + \ln A} \cdot \text{sgn}(x), & |x| \leq \frac{1}{A} \\
   \frac{1 + \ln(A \cdot |x|)}{1 + \ln A} \cdot \text{sgn}(x), & \frac{1}{A} < |x| \leq 1
   \end{cases}

其中 A = 87.6。

μ-law vs A-law 对比
---------------------

.. list-table::
   :header-rows: 1
   :widths: 25 35 35

   * - 特性
     - μ-law (PCMU)
     - A-law (PCMA)
   * - 地区
     - 北美、日本
     - 欧洲、中国、其他
   * - RTP PT
     - 0
     - 8
   * - 动态范围
     - 略好（小信号）
     - 略好（大信号）
   * - 空闲信道噪声
     - 较高
     - 较低
   * - 国际互通
     - A-law 优先（ITU 建议）
     - A-law 优先

RTP 打包
========

G.711 的 RTP 打包非常简单——每个 RTP 包直接承载 PCM 样本字节：

.. code-block:: text

   RTP Header (12 bytes)
   ┌──────────────────────────────────────┐
   │ V=2 │ P │ X │ CC │ M │ PT=0/8      │
   │ Sequence Number                      │
   │ Timestamp (8000 Hz clock)            │
   │ SSRC                                 │
   └──────────────────────────────────────┘
   Payload (N bytes = N samples)
   ┌──────────────────────────────────────┐
   │ sample[0] │ sample[1] │ ... │ sample[N-1] │
   └──────────────────────────────────────┘

- 20ms 帧 = 160 samples = 160 bytes payload
- 加上 RTP(12) + UDP(8) + IP(20) = 200 bytes/packet
- 包率 = 50 pps（每秒 50 个包）

G.711 附录
==========

G.711 Appendix I — PLC
------------------------

G.711 原始标准没有丢包隐藏（PLC）。ITU-T 在 1999 年发布了 **Appendix I**，定义了一种简单的 PLC 算法：

1. 正常接收时，保存最近的 48.75ms 语音作为历史缓冲
2. 丢包时，用基音周期检测找到历史缓冲中的重复模式
3. 用该模式外推生成替代帧
4. 逐渐衰减（每丢一帧衰减 10%），避免长时间丢包产生伪音

G.711 Appendix II — DTX
-------------------------

**Appendix II**（2000 年）增加了不连续传输（DTX）支持：

- 静音检测（VAD）
- 舒适噪声生成（CNG）
- 静音期间不发送语音包，节省带宽约 50-60%

在 WebRTC 中的使用
===================

WebRTC 规范要求**应该支持** G.711（PCMA 和 PCMU）。它的主要用途：

1. **PSTN 网关互通**：与传统电话系统对接时，避免转码
2. **低延迟场景**：算法延迟几乎为零
3. **兜底编码**：当 Opus 协商失败时的后备方案

SDP 示例：

.. code-block:: text

   a=rtpmap:0 PCMU/8000
   a=rtpmap:8 PCMA/8000
   a=ptime:20

局限性
-------

- **码率高**：64 kbps，是 Opus 的 2-4 倍
- **窄带**：只覆盖 300-3400 Hz，语音听起来"电话味"
- **无内置 FEC**：依赖网络层或 RED 冗余
- **无自适应码率**：无法根据网络状况调整

小结
====

G.711 是语音编码的"Hello World"——简单、可靠、无处不在。理解它的压扩原理和 RTP 打包方式，是学习更复杂编码器的基础。

在现代 WebRTC 应用中，Opus 几乎总是更好的选择，但 G.711 作为兼容性保障和 PSTN 互通桥梁，仍然不可或缺。
