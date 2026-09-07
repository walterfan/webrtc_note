#################
Audio Analysis
#################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============
**Abstract** Audio Analysis
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ =============



.. contents::
   :local:

概述
=============

语音分析 (Audio Analysis) 是音视频开发中的核心环节之一, 它为语音编码、降噪、回声消除、语音识别等上层应用提供了基础支撑。
在 WebRTC 的音频处理管线 (Audio Processing Pipeline) 中, 语音分析贯穿始终 ——
从采集端的 VAD (Voice Activity Detection) 到发送端的编码器参数自适应, 再到接收端的质量评估, 都离不开对音频信号的深入分析。

对于语音文件或流的分析主要包括 **时域分析 (Time-Domain Analysis)** 和 **频域分析 (Frequency-Domain Analysis)** 两大类:

1. **时域分析**: 直接观察信号随时间变化的特征, 如振幅、能量、过零率等
2. **频域分析**: 通过傅里叶变换等手段, 观察信号在频率维度上的分布特征
3. **时频联合分析**: 如语谱图 (Spectrogram), 同时展示时间和频率两个维度的信息

音频信号的基本特征
-------------------

在进行音频分析之前, 我们需要了解数字音频信号的几个基本参数:

**采样率 (Sample Rate)**

采样率是指每秒钟对模拟信号进行采样的次数, 单位为 Hz。根据 Nyquist 采样定理, 采样率必须至少为信号最高频率的两倍, 才能无失真地还原原始信号。常见的采样率有:

- **8000 Hz**: 电话语音 (窄带, Narrowband), 频率范围 300-3400 Hz
- **16000 Hz**: 宽带语音 (Wideband), WebRTC 中常用, 频率范围 50-7000 Hz
- **32000 Hz**: 超宽带语音 (Super-Wideband), 频率范围 50-14000 Hz
- **44100 Hz**: CD 音质, 音乐录制标准
- **48000 Hz**: 专业音频和视频制作标准, WebRTC 中 Opus 编码器的默认采样率

**位深 (Bit Depth)**

位深决定了每个采样点的量化精度, 即用多少个比特来表示一个采样值。常见的位深有:

- **8 bit**: 256 个量化级别, 动态范围约 48 dB
- **16 bit**: 65536 个量化级别, 动态范围约 96 dB, 最常用
- **24 bit**: 约 1677 万个量化级别, 动态范围约 144 dB, 专业录音
- **32 bit float**: 浮点表示, 用于中间处理阶段

量化噪声 (Quantization Noise) 的信噪比可以用以下公式估算:

.. math::

   SNR_{dB} \approx 6.02 \times N + 1.76

其中 N 为位深。对于 16 bit 音频, 理论信噪比约为 98 dB。

**声道 (Channel)**

- **单声道 (Mono)**: 1 个声道, 语音通信中最常用
- **双声道 (Stereo)**: 2 个声道, 左右声道, 音乐和空间音频
- **多声道 (Multichannel)**: 5.1, 7.1 等环绕声格式

在 WebRTC 中, 语音通信通常使用 **单声道 16 bit 采样, 采样率为 16000 Hz 或 48000 Hz**。

**比特率 (Bitrate)**

未压缩音频的比特率计算公式:

.. math::

   Bitrate = SampleRate \times BitDepth \times Channels

例如, 16 kHz / 16 bit / Mono 的未压缩比特率为:

.. math::

   16000 \times 16 \times 1 = 256000 \text{ bps} = 256 \text{ kbps}


时域分析
=============

时域分析是最直观的音频分析方法, 直接在时间轴上观察信号的变化规律。

波形图 (Waveform)
-------------------

波形图是音频信号最基本的可视化形式:

- **横坐标**: 表示时间 (单位: 秒或毫秒)
- **纵坐标**: 表示振幅 (Amplitude), 对于 16 bit 音频, 范围为 [-32768, 32767]

通过波形图, 我们可以直观地观察到:

- 语音段和静音段的分布
- 信号的整体响度变化
- 是否存在削波 (Clipping) 等异常

振幅 (Amplitude)
~~~~~~~~~~~~~~~~~~

振幅是信号在某一时刻的瞬时值。对于离散信号 :math:`x[n]`, 常用的振幅度量包括:

**峰值振幅 (Peak Amplitude)**:

.. math::

   x_{peak} = \max_{n} |x[n]|

**均方根振幅 (RMS Amplitude)**:

.. math::

   x_{RMS} = \sqrt{\frac{1}{N} \sum_{n=0}^{N-1} x[n]^2}

RMS 值更能反映信号的"有效"强度, 与人耳感知的响度更为接近。

过零率 (Zero Crossing Rate)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

过零率 (ZCR) 是指信号在一帧内穿越零值的次数, 是区分清音 (Unvoiced) 和浊音 (Voiced) 的重要特征。

.. math::

   ZCR = \frac{1}{2(N-1)} \sum_{n=1}^{N-1} |sgn(x[n]) - sgn(x[n-1])|

其中 :math:`sgn(x)` 为符号函数:

.. math::

   sgn(x) = \begin{cases} 1, & x \geq 0 \\ -1, & x < 0 \end{cases}

过零率的特点:

- **浊音 (Voiced sound)**: 如元音 /a/, /i/, /u/, 具有明显的基频, 过零率较低 (通常 < 50 次/帧)
- **清音 (Unvoiced sound)**: 如辅音 /s/, /f/, /sh/, 类似白噪声, 过零率较高 (通常 > 100 次/帧)
- **静音 (Silence)**: 过零率不稳定, 取决于背景噪声

在 WebRTC 的 VAD 模块中, 过零率是判断语音活动的重要特征之一。

短时能量 (Short-Time Energy)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

短时能量是衡量一帧信号强度的基本指标:

.. math::

   E = \sum_{n=0}^{N-1} [x[n] \cdot w[n]]^2

其中 :math:`w[n]` 为窗函数, :math:`N` 为帧长。

为了避免数值过大, 通常使用对数能量 (Log Energy):

.. math::

   E_{log} = 10 \cdot \log_{10}\left(\sum_{n=0}^{N-1} x[n]^2 + \epsilon\right)

其中 :math:`\epsilon` 是一个很小的正数 (如 :math:`10^{-10}`), 用于避免对零取对数。

短时能量的应用:

- **语音/静音判断**: 语音段的能量远高于静音段
- **响度估计**: 能量与感知响度相关
- **自动增益控制 (AGC)**: WebRTC 中根据短时能量调整增益

端点检测 (Endpoint Detection)
-------------------------------

端点检测 (也称为 Voice Activity Detection, VAD) 是确定语音信号中语音段起止位置的技术。
在 WebRTC 中, VAD 对于节省带宽 (通过 DTX/CNG) 和提升用户体验至关重要。

**基于能量和过零率的双门限法**:

这是最经典的端点检测方法, 使用两个阈值:

1. **高能量阈值** :math:`E_H`: 用于检测语音段的核心部分
2. **低能量阈值** :math:`E_L`: 用于检测语音段的边界
3. **过零率阈值** :math:`ZCR_T`: 用于检测清音段

检测流程:

1. 首先用高能量阈值粗略确定语音段
2. 然后用低能量阈值向两端扩展, 找到更精确的边界
3. 最后用过零率阈值进一步向前扩展, 捕获可能遗漏的清音起始部分

.. code-block:: text

   静音 | 清音起始 | 浊音段 | 清音结尾 | 静音
        |<-- ZCR -->|<- E_H ->|          |
        |<------- E_L ------->|          |

**WebRTC 中的 VAD 实现**:

WebRTC 提供了三种 VAD 模式:

- **Mode 0**: 最宽松, 倾向于将更多帧判定为语音
- **Mode 1**: 较宽松
- **Mode 2**: 较严格
- **Mode 3**: 最严格, 倾向于将更多帧判定为静音

WebRTC 的 VAD 使用了基于高斯混合模型 (GMM) 的方法, 在多个子带上分别进行检测, 比简单的能量/过零率方法更加鲁棒。

自相关函数 (Autocorrelation)
-------------------------------

自相关函数用于检测信号的周期性, 是基音检测 (Pitch Detection) 的基础。

对于离散信号 :math:`x[n]`, 自相关函数定义为:

.. math::

   R(\tau) = \sum_{n=0}^{N-1-\tau} x[n] \cdot x[n+\tau]

其中 :math:`\tau` 为延迟 (lag)。

**基音检测 (Pitch Detection)**:

基音频率 (Fundamental Frequency, F0) 是语音信号最重要的韵律特征之一。人类语音的基音频率范围:

- **成年男性**: 约 85-180 Hz
- **成年女性**: 约 165-255 Hz
- **儿童**: 约 250-400 Hz

自相关法检测基音的步骤:

1. 对一帧信号计算自相关函数 :math:`R(\tau)`
2. 在合理的基音周期范围内 (对应 :math:`\tau` 的搜索范围) 寻找 :math:`R(\tau)` 的最大峰值
3. 峰值对应的 :math:`\tau_0` 即为基音周期, 基音频率 :math:`F_0 = F_s / \tau_0`

例如, 对于 16 kHz 采样率:

- 搜索范围下限: :math:`\tau_{min} = 16000 / 400 = 40` (对应 400 Hz)
- 搜索范围上限: :math:`\tau_{max} = 16000 / 80 = 200` (对应 80 Hz)

.. note::

   WebRTC 中的 Opus 编码器使用了更先进的基音检测算法, 结合了自相关和 CELT 层的基音搜索,
   以实现更准确和更低延迟的基音估计。


分帧
================

语音信号是一种非平稳 (Non-Stationary) 信号, 但在短时间内 (10~30 ms) 可以近似认为是平稳的 (Quasi-Stationary)。
这是因为语音的产生依赖于声道 (Vocal Tract) 的形状, 而声道形状的变化速度相对较慢。
这种 **短时平稳性 (Short-Time Stationarity)** 假设是语音信号处理的基石。

分帧 (Framing) 就是将连续的语音信号切分成一个个短时片段 (帧) 进行分析的过程。

帧长选择
-----------

帧长 (Frame Length) 的选择需要在时间分辨率和频率分辨率之间取得平衡:

- **帧长太短** (< 10 ms): 时间分辨率高, 但频率分辨率差, 无法捕获足够的基音周期
- **帧长太长** (> 40 ms): 频率分辨率高, 但时间分辨率差, 信号的平稳性假设不再成立
- **推荐范围**: 10~30 ms, 通常取 **20 ms** 或 **25 ms**

不同应用场景的帧长选择:

.. list-table:: 帧长选择参考
   :header-rows: 1
   :widths: 30 20 50

   * - 应用场景
     - 典型帧长
     - 说明
   * - WebRTC 语音编码 (Opus)
     - 20 ms
     - 兼顾延迟和编码效率
   * - 语音识别 (ASR)
     - 25 ms
     - 需要较好的频率分辨率
   * - 语音合成 (TTS)
     - 5-10 ms
     - 需要较高的时间分辨率
   * - 音乐分析
     - 40-100 ms
     - 音乐信号变化较慢
   * - WebRTC VAD
     - 10 ms
     - 需要快速响应

帧移与重叠
-----------

**帧移 (Frame Shift / Hop Length)** 是相邻两帧起始位置之间的距离。帧移通常小于帧长, 使得相邻帧之间存在重叠 (Overlap)。

**重叠率 (Overlap Ratio)** 的计算:

.. math::

   Overlap = \frac{FrameLength - FrameShift}{FrameLength} \times 100\%

常见的重叠率为 **50%** (帧移 = 帧长/2) 或 **60%** (帧移 = 帧长 × 0.4)。

重叠的意义:

- **平滑过渡**: 避免帧与帧之间的信息丢失
- **提高时间分辨率**: 更密集的分析点
- **窗函数补偿**: 窗函数会衰减帧边缘的信号, 重叠可以补偿这种衰减

采样点计算示例
----------------

以 **采样率 16000 Hz, 帧长 20 ms, 帧移 10 ms** 为例:

.. code-block:: text

   每帧采样点数 = 采样率 × 帧长
               = 16000 × 0.020
               = 320 个采样点

   帧移采样点数 = 采样率 × 帧移
               = 16000 × 0.010
               = 160 个采样点

   重叠采样点数 = 320 - 160 = 160 个采样点
   重叠率 = 160 / 320 = 50%

对于一段 1 秒的语音信号 (共 16000 个采样点):

.. code-block:: text

   总帧数 = (总采样点数 - 帧长采样点数) / 帧移采样点数 + 1
          = (16000 - 320) / 160 + 1
          = 98 + 1
          = 99 帧

下表列出了不同采样率和帧长组合下的每帧采样点数:

.. list-table:: 每帧采样点数
   :header-rows: 1
   :widths: 20 20 20 20 20

   * - 采样率
     - 10 ms
     - 20 ms
     - 25 ms
     - 30 ms
   * - 8000 Hz
     - 80
     - 160
     - 200
     - 240
   * - 16000 Hz
     - 160
     - 320
     - 400
     - 480
   * - 32000 Hz
     - 320
     - 640
     - 800
     - 960
   * - 48000 Hz
     - 480
     - 960
     - 1200
     - 1440

.. note::

   在 FFT 计算中, 通常需要将帧长补零 (Zero-Padding) 到 2 的幂次方。
   例如, 320 个采样点的帧通常补零到 512 点进行 FFT, 这样既能利用 FFT 的高效算法,
   又能提高频率分辨率。


加窗处理
=================

语音是连续的, 如果我们将帧起点之前以及之后的信号幅度都设为零, 在进行傅立叶变换时,
就会发生 Gibbs phenomenon (吉布斯现象), 在不连续点处产生高频分量,
导致傅立叶变换后的频谱出现局部峰值。此外, 由于周期信号在分帧过程中被截断,
会导致频谱在整个频带内发生拖尾现象, 这被称为 spectral leakage (频谱泄漏)。

加窗 (Windowing) 就是将一帧信号的每个值乘以不同的权重, 将较大的权重赋予靠近窗中心的信号,
将接近零的权重赋予靠近窗边缘的信号, 从而减轻分帧时造成的信号不连续性。

数学表示:

.. math::

   y[n] = x[n] \cdot w[n], \quad 0 \leq n \leq N-1

其中 :math:`x[n]` 为原始信号, :math:`w[n]` 为窗函数, :math:`y[n]` 为加窗后的信号。

常见窗函数
-----------

**1) 矩形窗 (Rectangular Window)**

.. math::

   w[n] = 1, \quad 0 \leq n \leq N-1

矩形窗等价于不加窗, 具有最窄的主瓣宽度, 但旁瓣衰减最差 (-13 dB)。
适用于信号本身已经是周期性的且恰好截取整数个周期的情况。

**2) 汉宁窗 (Hanning Window / von Hann Window)**

.. math::

   w[n] = 0.5 \left(1 - \cos\left(\frac{2\pi n}{N-1}\right)\right)

汉宁窗的两端恰好为零, 旁瓣衰减较好 (-31 dB), 是频谱分析中最常用的窗函数之一。
由于窗的两端为零, 特别适合与 50% 重叠的帧移配合使用, 因为相邻帧的汉宁窗之和恰好为常数 (完美重建条件)。

**3) 汉明窗 (Hamming Window)**

.. math::

   w[n] = 0.54 - 0.46 \cos\left(\frac{2\pi n}{N-1}\right)

汉明窗与汉宁窗类似, 但窗的两端不为零 (约 0.08), 这使得它的旁瓣衰减更好 (-43 dB)。
汉明窗是 **语音处理中最常用的窗函数**, 在 MFCC 提取、语音编码等场景中广泛使用。

**4) 布莱克曼窗 (Blackman Window)**

.. math::

   w[n] = 0.42 - 0.5 \cos\left(\frac{2\pi n}{N-1}\right) + 0.08 \cos\left(\frac{4\pi n}{N-1}\right)

布莱克曼窗使用了三项余弦和, 旁瓣衰减非常好 (-58 dB), 但主瓣宽度较大。
适用于需要高动态范围的频谱分析场景。

**5) 高斯窗 (Gaussian Window)**

.. math::

   w[n] = e^{-\frac{1}{2}\left(\frac{n - (N-1)/2}{\sigma \cdot (N-1)/2}\right)^2}

其中 :math:`\sigma` 控制窗的宽度, 通常取 0.4~0.5。高斯窗在时域和频域都具有高斯形状,
是时频分辨率折中最优的窗函数 (满足 Heisenberg 不确定性原理的下界)。

窗函数特性对比
----------------

.. list-table:: 窗函数特性对比
   :header-rows: 1
   :widths: 18 18 18 18 28

   * - 窗函数
     - 主瓣宽度 (bins)
     - 最高旁瓣 (dB)
     - 旁瓣衰减率
     - 典型应用
   * - 矩形窗
     - 2
     - -13
     - -6 dB/oct
     - 瞬态信号分析
   * - 汉宁窗
     - 4
     - -31
     - -18 dB/oct
     - 通用频谱分析
   * - 汉明窗
     - 4
     - -43
     - -6 dB/oct
     - 语音处理, MFCC
   * - 布莱克曼窗
     - 6
     - -58
     - -18 dB/oct
     - 高动态范围分析
   * - 高斯窗
     - 取决于 σ
     - 取决于 σ
     - 取决于 σ
     - 时频分析, Gabor 变换

主瓣宽度 vs 旁瓣衰减
-----------------------

窗函数的选择本质上是 **主瓣宽度 (Main Lobe Width)** 和 **旁瓣衰减 (Side Lobe Attenuation)** 之间的权衡:

- **主瓣宽度**: 决定了频率分辨率。主瓣越窄, 越能区分两个相近的频率分量
- **旁瓣衰减**: 决定了频谱泄漏的程度。旁瓣越低, 强信号对弱信号的干扰越小

.. code-block:: text

   频率分辨率优先 <-----> 旁瓣抑制优先

   矩形窗 → 汉宁窗 → 汉明窗 → 布莱克曼窗
   (窄主瓣)                    (低旁瓣)

在实际应用中:

- 如果需要精确测量频率, 选择主瓣较窄的窗 (如矩形窗)
- 如果需要检测弱信号 (如噪声中的语音), 选择旁瓣较低的窗 (如汉明窗或布莱克曼窗)
- 语音处理中, **汉明窗** 是最常见的选择, 因为它在两者之间取得了良好的平衡


频域分析
=============

频域分析通过将时域信号变换到频率域, 揭示信号的频率组成和能量分布。

DFT/FFT 基础
--------------

**离散傅里叶变换 (Discrete Fourier Transform, DFT)**

对于长度为 N 的离散信号 :math:`x[n]`, 其 DFT 定义为:

.. math::

   X[k] = \sum_{n=0}^{N-1} x[n] \cdot e^{-j\frac{2\pi kn}{N}}, \quad k = 0, 1, \ldots, N-1

其中 :math:`X[k]` 是复数, 包含了第 k 个频率分量的幅度和相位信息。

DFT 的直接计算复杂度为 :math:`O(N^2)`, 而 **快速傅里叶变换 (Fast Fourier Transform, FFT)** 利用了 DFT 的对称性和周期性, 将复杂度降低到 :math:`O(N \log N)`。

FFT 的关键参数:

- **FFT 点数 (N)**: 通常为 2 的幂次方 (256, 512, 1024 等)
- **频率分辨率**: :math:`\Delta f = F_s / N`, 例如 16000 Hz 采样率, 512 点 FFT 的频率分辨率为 31.25 Hz
- **频率范围**: 0 到 :math:`F_s / 2` (Nyquist 频率), 由 N/2 + 1 个频率点表示

频谱 (Spectrum)
-----------------

DFT 的结果 :math:`X[k]` 是复数, 可以分解为以下几种频谱表示:

**幅度谱 (Magnitude Spectrum)**:

.. math::

   |X[k]| = \sqrt{Re(X[k])^2 + Im(X[k])^2}

幅度谱反映了各频率分量的强度, 是最常用的频谱表示。

**相位谱 (Phase Spectrum)**:

.. math::

   \angle X[k] = \arctan\left(\frac{Im(X[k])}{Re(X[k])}\right)

相位谱反映了各频率分量的相位关系。在语音合成和音频编码中, 相位信息对音质有重要影响。

**功率谱 (Power Spectrum)**:

.. math::

   P[k] = |X[k]|^2 = Re(X[k])^2 + Im(X[k])^2

功率谱反映了各频率分量的能量分布。

**功率谱密度 (Power Spectral Density, PSD)**:

.. math::

   S[k] = \frac{1}{N} |X[k]|^2

功率谱密度是归一化的功率谱, 常用于噪声分析。

**对数功率谱 (Log Power Spectrum)**:

.. math::

   L[k] = 10 \cdot \log_{10}(P[k] + \epsilon)

对数功率谱以 dB 为单位, 更符合人耳对响度的感知 (Weber-Fechner 定律)。

语谱图 (Spectrogram)
-----------------------

语谱图 (Spectrogram) 是语音分析中最重要的可视化工具之一, 它同时展示了时间、频率和能量三个维度的信息:

- **横坐标**: 时间
- **纵坐标**: 频率
- **颜色/亮度**: 能量强度 (通常用对数刻度)

**生成方法 — 短时傅里叶变换 (Short-Time Fourier Transform, STFT)**:

STFT 是生成语谱图的标准方法, 其过程为:

1. 将信号分帧
2. 对每帧加窗
3. 对每帧进行 FFT
4. 取幅度或功率的对数
5. 将所有帧的频谱按时间顺序排列

数学定义:

.. math::

   STFT\{x[n]\}(m, k) = \sum_{n=0}^{N-1} x[n + mH] \cdot w[n] \cdot e^{-j\frac{2\pi kn}{N}}

其中 :math:`m` 为帧索引, :math:`H` 为帧移 (hop length), :math:`w[n]` 为窗函数。

语谱图的类型:

- **窄带语谱图 (Narrowband Spectrogram)**: 使用较长的窗 (40-60 ms), 频率分辨率高, 可以看到各次谐波 (Harmonics)
- **宽带语谱图 (Wideband Spectrogram)**: 使用较短的窗 (3-5 ms), 时间分辨率高, 可以看到声门脉冲 (Glottal Pulses)

在 WebRTC 的调试和分析中, 语谱图是诊断音频问题 (如回声、噪声、编码伪影) 的重要工具。

梅尔频率倒谱系数 (MFCC)
--------------------------

MFCC (Mel-Frequency Cepstral Coefficients) 是语音识别和说话人识别中最广泛使用的特征。
它模拟了人耳对频率的非线性感知特性。

**梅尔刻度 (Mel Scale)**

人耳对频率的感知是非线性的: 在低频段, 人耳对频率变化非常敏感; 在高频段, 敏感度降低。
梅尔刻度将物理频率映射到感知频率:

.. math::

   Mel(f) = 2595 \cdot \log_{10}\left(1 + \frac{f}{700}\right)

逆变换:

.. math::

   f = 700 \cdot \left(10^{Mel/2595} - 1\right)

例如:

- 1000 Hz → 1000 Mel (梅尔刻度以 1000 Hz = 1000 Mel 为参考点)
- 2000 Hz → 1500 Mel
- 4000 Hz → 2146 Mel
- 8000 Hz → 2840 Mel

**梅尔滤波器组 (Mel Filter Bank)**

梅尔滤波器组由一组三角形带通滤波器组成, 在梅尔刻度上均匀分布:

- 低频段: 滤波器较窄, 频率分辨率高
- 高频段: 滤波器较宽, 频率分辨率低

通常使用 **26 或 40 个** 三角滤波器。

**MFCC 提取流程**:

.. code-block:: text

   原始信号
     ↓ 预加重 (Pre-emphasis): y[n] = x[n] - α·x[n-1], α ≈ 0.97
     ↓ 分帧 (Framing): 25 ms 帧长, 10 ms 帧移
     ↓ 加窗 (Windowing): 汉明窗
     ↓ FFT: 通常 512 点
     ↓ 功率谱 (Power Spectrum)
     ↓ 梅尔滤波器组 (Mel Filter Bank): 26-40 个三角滤波器
     ↓ 取对数 (Log)
     ↓ DCT (离散余弦变换): 取前 12-13 个系数
     ↓
   MFCC 特征向量 (12-13 维)

**DCT (Discrete Cosine Transform)**:

DCT 的作用是对梅尔滤波器组的对数能量进行去相关 (Decorrelation), 压缩信息到少数几个系数中:

.. math::

   c[n] = \sum_{m=0}^{M-1} \log(S[m]) \cdot \cos\left(\frac{\pi n (2m+1)}{2M}\right)

其中 :math:`S[m]` 为第 m 个梅尔滤波器的输出能量, :math:`M` 为滤波器个数。

通常取前 **12-13 个** MFCC 系数, 加上帧能量, 再加上一阶差分 (Delta) 和二阶差分 (Delta-Delta), 构成 **39 维** 的特征向量。

**MFCC 在语音识别中的应用**:

- 传统 ASR 系统 (GMM-HMM) 的标准输入特征
- 深度学习时代, 虽然 Mel Spectrogram 和 Filter Bank 特征更为流行, 但 MFCC 仍然广泛使用
- 说话人识别 (Speaker Recognition) 中的基础特征


音频质量指标
=================

音频质量评估是 WebRTC 开发中的重要环节, 用于衡量语音通信的质量。

SNR (信噪比)
--------------

信噪比 (Signal-to-Noise Ratio) 是最基本的音频质量指标:

.. math::

   SNR_{dB} = 10 \cdot \log_{10}\left(\frac{P_{signal}}{P_{noise}}\right)

其中 :math:`P_{signal}` 和 :math:`P_{noise}` 分别为信号和噪声的功率。

分段信噪比 (Segmental SNR) 对每帧分别计算 SNR 后取平均, 更能反映语音质量的主观感受:

.. math::

   SNR_{seg} = \frac{1}{M} \sum_{m=0}^{M-1} 10 \cdot \log_{10}\left(\frac{\sum_{n} x^2[n]}{\sum_{n} (x[n] - \hat{x}[n])^2}\right)

PESQ
------

PESQ (Perceptual Evaluation of Speech Quality, ITU-T P.862) 是一种客观语音质量评估方法,
通过比较原始信号和退化信号来预测主观 MOS (Mean Opinion Score) 分数。

- **输入**: 原始 (参考) 信号和退化 (测试) 信号
- **输出**: MOS-LQO 分数, 范围 1.0-4.5
- **适用场景**: 窄带 (8 kHz) 和宽带 (16 kHz) 语音
- **标准**: ITU-T P.862, P.862.1, P.862.2

PESQ 的评估流程:

1. 时间对齐 (Time Alignment)
2. 感知滤波 (Perceptual Filtering)
3. 时频映射 (Time-Frequency Mapping)
4. 认知建模 (Cognitive Modeling)
5. 输出 MOS 分数

POLQA
------

POLQA (Perceptual Objective Listening Quality Analysis, ITU-T P.863) 是 PESQ 的下一代标准:

- 支持超宽带 (Super-Wideband, 48 kHz) 音频
- 更好地处理时间拉伸和压缩
- 对 VoIP 和移动网络的评估更准确
- MOS 分数范围: 1.0-5.0

ViSQOL
--------

ViSQOL (Virtual Speech Quality Objective Listener) 是 Google 开发的语音质量评估工具:

- 基于语谱图相似度的评估方法
- 支持语音模式 (Speech Mode) 和音频模式 (Audio Mode)
- 开源实现, 可集成到 CI/CD 流程中
- 特别适合评估 WebRTC 场景下的音频质量

WebRTC 中的音频质量监控
-------------------------

WebRTC 提供了 ``getStats()`` API 来实时监控音频质量:

.. code-block:: javascript

   const stats = await peerConnection.getStats();
   stats.forEach(report => {
     if (report.type === 'inbound-rtp' && report.kind === 'audio') {
       console.log('Packets received:', report.packetsReceived);
       console.log('Packets lost:', report.packetsLost);
       console.log('Jitter:', report.jitter);
       console.log('Audio level:', report.audioLevel);
       console.log('Total audio energy:', report.totalAudioEnergy);
       console.log('Concealment events:', report.concealmentEvents);
       console.log('Concealed samples:', report.concealedSamples);
     }
     if (report.type === 'outbound-rtp' && report.kind === 'audio') {
       console.log('Packets sent:', report.packetsSent);
       console.log('Bytes sent:', report.bytesSent);
       console.log('Target bitrate:', report.targetBitrate);
     }
   });

关键监控指标:

- **packetsLost / packetsReceived**: 丢包率, 影响语音质量的关键因素
- **jitter**: 抖动, 反映网络稳定性
- **audioLevel**: 音频电平 (0.0-1.0), 用于检测静音或过载
- **concealedSamples**: 丢包隐藏的采样数, 反映丢包补偿的频率
- **roundTripTime**: 往返时延, 影响通话的交互体验


Python 实践
=================

以下示例展示如何使用 Python 进行音频分析。主要使用 ``librosa``, ``scipy`` 和 ``matplotlib`` 库。

环境准备
---------

.. code-block:: bash

   pip install librosa scipy numpy matplotlib soundfile

读取音频文件
--------------

.. code-block:: python

   import librosa
   import numpy as np
   import matplotlib.pyplot as plt

   # 读取音频文件, sr=None 保持原始采样率
   y, sr = librosa.load('speech.wav', sr=None)

   print(f"采样率: {sr} Hz")
   print(f"时长: {len(y) / sr:.2f} 秒")
   print(f"采样点数: {len(y)}")
   print(f"数据类型: {y.dtype}")
   print(f"振幅范围: [{y.min():.4f}, {y.max():.4f}]")

   # 使用 scipy 读取 (保持整数格式)
   from scipy.io import wavfile
   sr_scipy, data = wavfile.read('speech.wav')
   print(f"scipy 数据类型: {data.dtype}")
   print(f"scipy 振幅范围: [{data.min()}, {data.max()}]")

绘制波形图和语谱图
---------------------

.. code-block:: python

   import librosa
   import librosa.display
   import numpy as np
   import matplotlib.pyplot as plt

   y, sr = librosa.load('speech.wav', sr=16000)

   fig, axes = plt.subplots(3, 1, figsize=(12, 10))

   # 1. 波形图
   librosa.display.waveshow(y, sr=sr, ax=axes[0])
   axes[0].set_title('Waveform (波形图)')
   axes[0].set_xlabel('Time (s)')
   axes[0].set_ylabel('Amplitude')

   # 2. 语谱图 (Spectrogram)
   D = librosa.stft(y, n_fft=512, hop_length=160, win_length=400)
   S_db = librosa.amplitude_to_db(np.abs(D), ref=np.max)
   img = librosa.display.specshow(S_db, sr=sr, hop_length=160,
                                   x_axis='time', y_axis='hz', ax=axes[1])
   axes[1].set_title('Spectrogram (语谱图)')
   fig.colorbar(img, ax=axes[1], format='%+2.0f dB')

   # 3. Mel 语谱图
   S_mel = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=80,
                                           n_fft=512, hop_length=160)
   S_mel_db = librosa.power_to_db(S_mel, ref=np.max)
   img2 = librosa.display.specshow(S_mel_db, sr=sr, hop_length=160,
                                    x_axis='time', y_axis='mel', ax=axes[2])
   axes[2].set_title('Mel Spectrogram (梅尔语谱图)')
   fig.colorbar(img2, ax=axes[2], format='%+2.0f dB')

   plt.tight_layout()
   plt.savefig('audio_analysis.png', dpi=150)
   plt.show()

计算 MFCC
-----------

.. code-block:: python

   import librosa
   import librosa.display
   import numpy as np
   import matplotlib.pyplot as plt

   y, sr = librosa.load('speech.wav', sr=16000)

   # 计算 MFCC (13 个系数)
   mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13,
                                  n_fft=512, hop_length=160,
                                  win_length=400, window='hamming')

   print(f"MFCC shape: {mfccs.shape}")
   # 输出: (13, num_frames)

   # 计算 Delta 和 Delta-Delta
   delta_mfccs = librosa.feature.delta(mfccs)
   delta2_mfccs = librosa.feature.delta(mfccs, order=2)

   # 拼接为 39 维特征
   features = np.vstack([mfccs, delta_mfccs, delta2_mfccs])
   print(f"完整特征 shape: {features.shape}")
   # 输出: (39, num_frames)

   # 可视化 MFCC
   fig, ax = plt.subplots(figsize=(12, 4))
   img = librosa.display.specshow(mfccs, sr=sr, hop_length=160,
                                   x_axis='time', ax=ax)
   ax.set_title('MFCC')
   ax.set_ylabel('MFCC Coefficients')
   fig.colorbar(img, ax=ax)
   plt.tight_layout()
   plt.savefig('mfcc.png', dpi=150)
   plt.show()

短时能量和过零率计算
-----------------------

.. code-block:: python

   import librosa
   import numpy as np
   import matplotlib.pyplot as plt

   y, sr = librosa.load('speech.wav', sr=16000)

   # 计算短时能量 (RMS)
   rms = librosa.feature.rms(y=y, frame_length=400, hop_length=160)[0]

   # 计算过零率
   zcr = librosa.feature.zero_crossing_rate(y, frame_length=400,
                                              hop_length=160)[0]

   # 可视化
   fig, axes = plt.subplots(3, 1, figsize=(12, 8), sharex=True)

   frames = np.arange(len(rms))
   times = librosa.frames_to_time(frames, sr=sr, hop_length=160)

   # 波形
   librosa.display.waveshow(y, sr=sr, ax=axes[0])
   axes[0].set_title('Waveform')

   # 短时能量
   axes[1].plot(times, rms, color='r')
   axes[1].set_title('Short-Time Energy (RMS)')
   axes[1].set_ylabel('Energy')

   # 过零率
   axes[2].plot(times, zcr, color='g')
   axes[2].set_title('Zero Crossing Rate')
   axes[2].set_ylabel('ZCR')
   axes[2].set_xlabel('Time (s)')

   plt.tight_layout()
   plt.savefig('energy_zcr.png', dpi=150)
   plt.show()

窗函数对比
-----------

.. code-block:: python

   import numpy as np
   import matplotlib.pyplot as plt
   from scipy.signal import windows

   N = 256

   # 生成各种窗函数
   win_rect = np.ones(N)
   win_hann = windows.hann(N)
   win_hamm = windows.hamming(N)
   win_black = windows.blackman(N)
   win_gauss = windows.gaussian(N, std=N/6)

   window_list = [
       ('Rectangular', win_rect),
       ('Hanning', win_hann),
       ('Hamming', win_hamm),
       ('Blackman', win_black),
       ('Gaussian', win_gauss),
   ]

   fig, axes = plt.subplots(len(window_list), 2, figsize=(14, 12))

   for i, (name, w) in enumerate(window_list):
       # 时域
       axes[i, 0].plot(w)
       axes[i, 0].set_title(f'{name} Window (Time Domain)')
       axes[i, 0].set_ylim(-0.1, 1.1)

       # 频域 (对数幅度谱)
       W = np.fft.fft(w, 4096)
       W_db = 20 * np.log10(np.abs(W[:2048]) / np.max(np.abs(W)) + 1e-10)
       freq = np.linspace(0, 0.5, 2048)
       axes[i, 1].plot(freq, W_db)
       axes[i, 1].set_title(f'{name} Window (Frequency Domain)')
       axes[i, 1].set_ylim(-120, 5)
       axes[i, 1].set_ylabel('Magnitude (dB)')

   plt.tight_layout()
   plt.savefig('window_comparison.png', dpi=150)
   plt.show()


WebRTC 中的应用
=================

WebRTC 的 Audio Processing Module (APM) 是一个功能强大的音频处理框架,
其中包含了多个与音频分析密切相关的子模块。

APM 中的分析模块
------------------

WebRTC APM 的主要分析和处理模块包括:

**1. 回声消除 (Acoustic Echo Cancellation, AEC)**

AEC 模块需要对近端信号和远端信号进行频域分析, 估计回声路径的传递函数:

- 使用 STFT 将信号变换到频域
- 通过自适应滤波器 (如 NLMS, Kalman Filter) 估计回声
- 在频域进行回声消除和残余回声抑制

**2. 噪声抑制 (Noise Suppression, NS)**

NS 模块基于频域分析进行噪声估计和抑制:

- 使用 STFT 分析信号的频谱特征
- 通过最小统计量 (Minimum Statistics) 或 MCRA 算法估计噪声功率谱
- 使用维纳滤波 (Wiener Filter) 或谱减法 (Spectral Subtraction) 进行降噪

**3. 自动增益控制 (Automatic Gain Control, AGC)**

AGC 模块分析信号的能量特征, 自动调整增益:

- 计算短时能量和峰值电平
- 根据目标电平调整增益
- 使用压缩器 (Compressor) 和限幅器 (Limiter) 防止削波

**4. 语音活动检测 (Voice Activity Detection, VAD)**

VAD 模块综合多种分析特征判断语音活动:

- 子带能量分析
- 频谱平坦度 (Spectral Flatness)
- 基于 GMM 的统计模型

**5. 音频电平估计 (Audio Level Estimation)**

用于 RTP 头扩展中的音频电平指示 (RFC 6464):

- 计算 RMS 电平
- 转换为 dBov (相对于数字满量程的分贝值)
- 通过 RTP 头扩展传递给接收端

APM 处理流程
--------------

.. code-block:: text

   采集端 (Capture/Near-end)              播放端 (Render/Far-end)
   ┌─────────────────────┐               ┌──────────────────┐
   │  麦克风采集          │               │  扬声器播放       │
   │       ↓              │               │       ↑           │
   │  高通滤波 (HPF)      │               │  远端信号参考     │
   │       ↓              │               │       │           │
   │  AEC (回声消除)  ←───┼───────────────┼───────┘           │
   │       ↓              │               └──────────────────┘
   │  NS (噪声抑制)       │
   │       ↓              │
   │  AGC (增益控制)      │
   │       ↓              │
   │  VAD (语音检测)      │
   │       ↓              │
   │  编码 & 发送         │
   └─────────────────────┘

C++ API 示例
--------------

以下是使用 WebRTC APM 的 C++ 代码片段:

.. code-block:: cpp

   #include "modules/audio_processing/include/audio_processing.h"

   // 创建 APM 实例
   webrtc::AudioProcessing::Config config;
   config.echo_canceller.enabled = true;
   config.echo_canceller.mobile_mode = false;
   config.noise_suppression.enabled = true;
   config.noise_suppression.level =
       webrtc::AudioProcessing::Config::NoiseSuppression::kHigh;
   config.gain_controller2.enabled = true;
   config.voice_detection.enabled = true;

   auto apm = webrtc::AudioProcessingBuilder().Create();
   apm->ApplyConfig(config);

   // 处理音频帧 (10 ms)
   webrtc::StreamConfig stream_config(16000, 1);  // 16 kHz, mono
   float* capture_data = ...;  // 采集到的音频数据
   float* render_data = ...;   // 远端参考信号

   // 先处理远端信号 (用于 AEC)
   apm->ProcessReverseStream(&render_data, stream_config, stream_config,
                              &render_data);

   // 处理近端信号
   apm->ProcessStream(&capture_data, stream_config, stream_config,
                       &capture_data);

   // 获取 VAD 结果
   auto stats = apm->GetStatistics();
   if (stats.voice_detected.has_value()) {
       bool voice_active = stats.voice_detected.value();
   }


小结
=============

本章介绍了音频分析的核心概念和方法, 从时域分析到频域分析, 从基础理论到 WebRTC 中的实际应用。
以下是关键要点的总结:

1. **时域分析** 提供了信号的直观特征: 振幅、短时能量、过零率和自相关函数
2. **分帧和加窗** 是语音信号处理的基础操作, 帧长通常选择 20-25 ms, 汉明窗是最常用的窗函数
3. **频域分析** 通过 FFT/STFT 揭示信号的频率特征, 语谱图是最重要的可视化工具
4. **MFCC** 是语音识别中最经典的特征, 模拟了人耳的非线性频率感知
5. **音频质量评估** 包括客观指标 (SNR, PESQ, POLQA, ViSQOL) 和 WebRTC 的实时监控
6. **WebRTC APM** 集成了回声消除、噪声抑制、增益控制等模块, 是音频分析技术的综合应用

掌握这些音频分析的基础知识, 对于理解和优化 WebRTC 的音频处理管线至关重要。


参考文献
=============

标准与规范
-----------

- ITU-T P.862: *Perceptual evaluation of speech quality (PESQ)*
- ITU-T P.863: *Perceptual objective listening quality analysis (POLQA)*
- ITU-T G.711: *Pulse code modulation (PCM) of voice frequencies*
- ITU-T G.722: *7 kHz audio-coding within 64 kbit/s*
- RFC 6716: *Definition of the Opus Audio Codec*
- RFC 6464: *A Real-time Transport Protocol (RTP) Header Extension for Client-to-Mixer Audio Level Indication*
- RFC 6465: *A Real-time Transport Protocol (RTP) Header Extension for Mixer-to-Client Audio Level Indication*
- RFC 3551: *RTP Profile for Audio and Video Conferences with Minimal Control*

书籍与论文
-----------

- Rabiner, L. R., & Schafer, R. W. (2010). *Theory and Applications of Digital Speech Processing*. Prentice Hall.
- Huang, X., Acero, A., & Hon, H. W. (2001). *Spoken Language Processing*. Prentice Hall.
- Oppenheim, A. V., & Schafer, R. W. (2009). *Discrete-Time Signal Processing* (3rd ed.). Prentice Hall.
- Davis, S. B., & Mermelstein, P. (1980). Comparison of parametric representations for monosyllabic word recognition in continuously spoken sentences. *IEEE Transactions on Acoustics, Speech, and Signal Processing*, 28(4), 357-366.

在线资源
-----------

- WebRTC 官方文档: https://webrtc.org/
- WebRTC APM 源码: https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/
- librosa 文档: https://librosa.org/doc/latest/
- ViSQOL 项目: https://github.com/google/visqol
