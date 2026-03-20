################################
Automatic Noise Suppression
################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==============================
**Abstract** Automatic Noise Suppression
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==============================



.. contents::
   :local:

概述
===================

背景噪声抑制（ANS, Automatic Noise Suppression）指的是将声音中的背景噪声识别并进行消除的处理。
在实时通信场景中，背景噪声会严重影响语音的可懂度和通话体验。ANS 的目标是在尽可能保留语音信号的前提下，
最大程度地抑制背景噪声。

噪声抑制是 WebRTC 音频处理流水线（Audio Processing Module, APM）中的关键模块之一，
通常在回声消除（AEC）之后、自动增益控制（AGC）之前执行。其处理链路为：

::

  麦克风采集 → AEC → ANS → AGC → 编码 → 网络传输


噪声的分类
===================

要有效地抑制噪声，首先需要了解噪声的类型。根据噪声的时频特性，可以将其分为以下几类：

平稳噪声 (Stationary Noise)
----------------------------------------------

平稳噪声的频谱特性随时间变化缓慢，其统计特性（均值、方差）在较长时间内保持相对稳定。典型的平稳噪声包括：

* **风扇噪声** (Fan noise)：电脑风扇、空调出风口产生的持续低频噪声
* **空调噪声** (Air conditioning noise)：HVAC 系统产生的宽带背景噪声
* **电气噪声** (Electrical noise)：电源线干扰、接地回路产生的 50/60Hz 工频噪声
* **白噪声** (White noise)：麦克风电路本底噪声

平稳噪声的特点是频谱包络变化缓慢，因此可以通过估计噪声的长期频谱特性来进行有效抑制。

非平稳噪声 (Non-stationary Noise)
----------------------------------------------

非平稳噪声的频谱特性随时间快速变化，统计特性不稳定。典型的非平稳噪声包括：

* **键盘敲击声** (Keyboard typing)：短促的宽带冲击噪声
* **关门声** (Door slam)：低频为主的冲击噪声
* **背景人声** (Background speech/babble noise)：其他人的说话声，频谱与目标语音高度重叠
* **音乐声** (Background music)：频谱结构复杂，与语音有部分重叠
* **交通噪声** (Traffic noise)：汽车、火车等产生的时变噪声

非平稳噪声的抑制难度远大于平稳噪声，传统的频谱减法对其效果有限，通常需要基于深度学习的方法。

瞬态噪声 (Transient Noise)
----------------------------------------------

瞬态噪声是持续时间极短（通常 < 10ms）的突发噪声，其能量在短时间内急剧上升又迅速衰减。典型的瞬态噪声包括：

* **鼠标点击声** (Mouse click)
* **咳嗽声** (Cough)
* **纸张翻动声** (Paper rustling)
* **杯子碰撞声** (Cup clinking)

瞬态噪声需要专门的检测和抑制算法，WebRTC 中有独立的 Transient Suppressor 模块来处理此类噪声。


Background noise removal
===================================

保留人的说话声音，而将身边的噪声，例如风扇声，吃东西的声音消除，主要依据是人声的频率和噪声的频率和能量不同。

噪声抑制的基本思路是：

1. **噪声估计** (Noise Estimation)：在语音静默段或利用统计方法估计噪声的频谱特性
2. **信噪比估计** (SNR Estimation)：估计每个频率 bin 上的信噪比
3. **增益计算** (Gain Calculation)：根据信噪比计算每个频率 bin 的抑制增益
4. **增益应用** (Gain Application)：将增益应用于含噪语音的频谱，得到降噪后的语音

用数学公式表示，含噪语音信号可以建模为：

.. math::

   y(n) = s(n) + d(n)

其中 :math:`y(n)` 是含噪语音，:math:`s(n)` 是纯净语音，:math:`d(n)` 是噪声。
在频域中：

.. math::

   Y(k) = S(k) + D(k)

噪声抑制的目标是从 :math:`Y(k)` 中估计出 :math:`\hat{S}(k)`。


噪声抑制算法
===================================

谱减法 (Spectral Subtraction)
----------------------------------------------

谱减法是最经典的噪声抑制方法，其基本思想是从含噪语音的功率谱中减去噪声的功率谱估计：

.. math::

   |\hat{S}(k)|^2 = |Y(k)|^2 - |\hat{D}(k)|^2

其中 :math:`|\hat{D}(k)|^2` 是噪声功率谱的估计，通常在语音静默段（由 VAD 检测）进行更新。

为了避免过减（over-subtraction）导致的负值，引入过减因子 :math:`\alpha` 和谱下限 :math:`\beta`：

.. math::

   |\hat{S}(k)|^2 = \max\left(|Y(k)|^2 - \alpha \cdot |\hat{D}(k)|^2, \quad \beta \cdot |Y(k)|^2\right)

谱减法的优点是计算简单、实时性好；缺点是容易产生 **音乐噪声** (Musical Noise)，
即由于帧间频谱估计的随机波动导致的不自然的音调噪声。

维纳滤波 (Wiener Filter)
----------------------------------------------

维纳滤波是一种最优线性滤波方法，其目标是最小化估计信号与真实信号之间的均方误差（MSE）。
维纳滤波器的频域增益函数为：

.. math::

   H(k) = \frac{|S(k)|^2}{|S(k)|^2 + |D(k)|^2} = \frac{\text{SNR}(k)}{\text{SNR}(k) + 1}

其中 :math:`\text{SNR}(k)` 是第 :math:`k` 个频率 bin 的先验信噪比 (a priori SNR)。

在实际应用中，先验信噪比通常使用 **Decision-Directed** 方法估计：

.. math::

   \text{SNR}_{\text{priori}}(k, m) = \alpha_{\text{dd}} \cdot \frac{|\hat{S}(k, m-1)|^2}{|\hat{D}(k)|^2} + (1 - \alpha_{\text{dd}}) \cdot \max\left(\text{SNR}_{\text{post}}(k, m) - 1, 0\right)

其中 :math:`\alpha_{\text{dd}}` 是平滑因子（通常取 0.98），:math:`\text{SNR}_{\text{post}}` 是后验信噪比。

维纳滤波相比谱减法产生的音乐噪声更少，但计算复杂度稍高。

MMSE 估计器 (Minimum Mean Square Error Estimator)
------------------------------------------------------------

MMSE 估计器假设语音和噪声的 DFT 系数服从高斯分布，在此假设下推导出最优的频谱幅度估计。
常用的变体包括：

* **MMSE-STSA** (Short-Time Spectral Amplitude)：最小化频谱幅度的均方误差
* **MMSE-LSA** (Log-Spectral Amplitude)：最小化对数频谱幅度的均方误差，听感更自然

MMSE-LSA 的增益函数为：

.. math::

   G_{\text{LSA}}(k) = \frac{\xi(k)}{1 + \xi(k)} \cdot \exp\left(\frac{1}{2} \int_{v(k)}^{\infty} \frac{e^{-t}}{t} dt\right)

其中 :math:`\xi(k)` 是先验信噪比，:math:`v(k) = \frac{\xi(k)}{1+\xi(k)} \cdot \gamma(k)`，
:math:`\gamma(k)` 是后验信噪比。

基于深度学习的噪声抑制
----------------------------------------------

近年来，基于深度学习的噪声抑制方法取得了显著进展，在非平稳噪声和低信噪比条件下远超传统方法。

**RNNoise**

RNNoise 是由 Mozilla 的 Jean-Marc Valin 提出的基于 RNN 的噪声抑制方案，其特点包括：

* 使用 GRU (Gated Recurrent Unit) 网络
* 在 Bark 频率尺度上操作，将频谱划分为 22 个频带
* 模型极其轻量（约 85KB），适合实时处理
* 每帧处理仅需约 0.1ms（在现代 CPU 上）
* 同时输出 VAD 概率和每个频带的增益

RNNoise 的处理流程：

::

  输入帧 → 加窗 → FFT → 提取特征(42维) → GRU网络 → 频带增益(22个) → 插值到FFT bins → IFFT → 输出帧

**DTLN (Dual-signal Transformation LSTM Network)**

DTLN 是一种双阶段的噪声抑制网络：

* 第一阶段在 STFT 域操作，估计频谱幅度掩码
* 第二阶段在时域操作，进一步细化降噪结果
* 使用 LSTM 层捕获时序依赖关系
* 模型大小约 2MB，适合移动端部署

**PercepNet**

PercepNet 是 WebRTC 团队提出的感知驱动的噪声抑制方案：

* 结合了传统信号处理和深度学习
* 在感知频率尺度（Bark scale）上操作
* 使用 pitch filtering 增强周期性语音成分
* 使用 comb filtering 保留语音的谐波结构


Single Talk and Multiple talker
===================================

Single talker
------------------------------------------------------
在家或者办公室开会，你在说话，不想让身边人的声音传进去，主要方法是将近端的声音(能量较大)放大或保留，将远端的声音(能量较小)减小或消除


Multiple talker
------------------------------------------------------
在会议室开会，你在说话，也想让身边人的声音传进去，无论近端或远端的声音就保留，并做出一些必要的 AGC


WebRTC ANS 实现
===================================

WebRTC 中的噪声抑制经历了多个版本的演进，目前主要有两套实现：传统的基于信号处理的 NS 和基于神经网络的 NS2。

传统 NS 实现
----------------------------------------------

传统的噪声抑制实现位于 ``modules/audio_processing/ns/`` 目录下，核心类为 ``NoiseSuppression``。

**NS 等级 (Suppression Level)**

WebRTC NS 提供了 4 个抑制等级，对应不同的噪声抑制强度：

.. list-table:: NS 抑制等级
   :header-rows: 1
   :widths: 15 20 65

   * - 等级
     - 名称
     - 说明
   * - 0
     - Low (低)
     - 轻度抑制，语音失真最小，适合安静环境
   * - 1
     - Moderate (中等)
     - 中等抑制，平衡噪声抑制和语音质量
   * - 2
     - High (高)
     - 较强抑制，适合中等噪声环境，可能有轻微语音失真
   * - 3
     - Very High (非常高)
     - 最强抑制，适合高噪声环境，可能有明显语音失真

**处理流水线 (Processing Pipeline)**

NS 的处理流程如下：

::

  输入帧(10ms PCM)
    ↓
  分帧与加窗 (Windowing) — 使用 Hanning 窗
    ↓
  FFT — 将时域信号转换到频域
    ↓
  噪声估计 (Noise Estimation) — 基于 MCRA/IMCRA 算法
    ↓
  先验 SNR 估计 (A Priori SNR Estimation)
    ↓
  频谱增益计算 (Spectral Gain Calculation) — 维纳滤波
    ↓
  增益应用 (Gain Application)
    ↓
  IFFT — 将频域信号转换回时域
    ↓
  重叠相加 (Overlap-Add) — 合成输出帧
    ↓
  输出帧(10ms PCM)

**核心组件**

* ``NsCore``: 噪声抑制的核心处理逻辑

  - 维护噪声功率谱估计
  - 计算先验和后验信噪比
  - 应用维纳滤波增益

* ``NoiseEstimator``: 噪声估计器

  - 使用 Minimum Statistics 或 MCRA 算法
  - 在语音活动期间冻结噪声估计更新
  - 支持噪声功率谱的平滑更新

* ``SpeechProbabilityEstimator``: 语音存在概率估计

  - 基于先验和后验 SNR 估计语音存在概率
  - 用于控制噪声估计的更新速率

**关键参数**

.. code-block:: cpp

   // NS 核心参数
   struct NsConfig {
     // FFT 大小，通常为 256（对应 16kHz 采样率）
     static constexpr int kFftSize = 256;
     // 分析窗长度
     static constexpr int kAnalysisSize = 256;
     // 帧移（10ms @ 16kHz = 160 samples）
     static constexpr int kFrameSize = 160;
     // 噪声估计平滑因子
     float noise_smoothing_factor = 0.7f;
     // 过减因子
     float over_subtraction_factor = 1.0f;
     // 最小增益（谱下限），防止过度抑制
     float min_gain = 0.01f;  // -40 dB
   };


NS2: 基于神经网络的噪声抑制
----------------------------------------------

从 WebRTC M87 版本开始，引入了基于 RNN 的噪声抑制器 ``NoiseSuppressor``（通常称为 NS2），
位于 ``modules/audio_processing/ns/`` 目录下。

**NoiseSuppressor 类**

``NoiseSuppressor`` 是 NS2 的核心类，其主要特点：

* 使用 RNN（基于 GRU）进行噪声抑制
* 在 Bark 频率尺度上操作，减少计算量
* 同时输出降噪信号和语音存在概率
* 支持多通道处理

.. code-block:: cpp

   // NoiseSuppressor 的核心接口
   class NoiseSuppressor {
   public:
     NoiseSuppressor(const NsConfig& config,
                     size_t sample_rate_hz,
                     size_t num_channels);

     // 处理一帧音频数据
     void Analyze(const AudioBuffer& audio);
     void Process(AudioBuffer* audio);

   private:
     // RNN 模型权重
     std::unique_ptr<RnnModel> rnn_model_;
     // 每个通道的处理状态
     std::vector<ChannelState> channel_states_;
   };

**NS2 的优势**

相比传统 NS，NS2 具有以下优势：

* 对非平稳噪声（如键盘声、背景人声）的抑制效果显著提升
* 在低 SNR 条件下仍能保持较好的语音质量
* 音乐噪声（Musical Noise）问题大幅减少
* 语音失真更小


传统方法 vs 深度学习方法对比
===================================

.. list-table:: 传统 NS vs 深度学习 NS 对比
   :header-rows: 1
   :widths: 25 35 40

   * - 特性
     - 传统方法 (谱减法/维纳滤波)
     - 深度学习方法 (RNN/LSTM)
   * - 平稳噪声抑制
     - 效果好
     - 效果好
   * - 非平稳噪声抑制
     - 效果有限
     - 效果显著
   * - 语音失真
     - 高抑制等级下明显
     - 较小
   * - 音乐噪声
     - 容易产生
     - 很少产生
   * - 计算复杂度
     - 低
     - 中等（需要矩阵运算）
   * - 模型大小
     - 无需模型
     - 需要模型文件（几十KB~几MB）
   * - 适应性
     - 需要噪声估计收敛
     - 端到端学习，适应性强
   * - 可解释性
     - 强（基于明确的数学模型）
     - 弱（黑盒模型）


WebRTC 中的配置
===================================

在 WebRTC 中，可以通过 ``AudioProcessing::Config`` 来配置噪声抑制：

.. code-block:: cpp

   // C++ API 配置
   AudioProcessing::Config config;
   config.noise_suppression.enabled = true;
   config.noise_suppression.level =
       AudioProcessing::Config::NoiseSuppression::kHigh;

   auto apm = AudioProcessingBuilder().SetConfig(config).Create();

在 JavaScript 中，可以通过 ``MediaConstraints`` 来启用噪声抑制：

.. code-block:: javascript

   // JavaScript API 配置
   const constraints = {
     audio: {
       noiseSuppression: true,           // 启用噪声抑制
       autoGainControl: true,            // 通常与 AGC 配合使用
       echoCancellation: true            // 通常与 AEC 配合使用
     }
   };

   navigator.mediaDevices.getUserMedia(constraints)
     .then(stream => {
       // 使用降噪后的音频流
       const audioTrack = stream.getAudioTracks()[0];
       const settings = audioTrack.getSettings();
       console.log('Noise suppression:', settings.noiseSuppression);
     });

也可以通过 ``MediaTrackConstraints`` 进行更精细的控制：

.. code-block:: javascript

   // 使用 advanced constraints
   const constraints = {
     audio: {
       advanced: [{
         noiseSuppression: { exact: true },
         // 某些浏览器支持的扩展约束
         googNoiseSuppression: true,
         googHighpassFilter: true,
         googNoiseSuppression2: true  // 启用 NS2
       }]
     }
   };


性能指标
===================================

评估噪声抑制算法的性能通常使用以下指标：

**SNR 改善 (SNR Improvement / ΔSNR)**

.. math::

   \Delta\text{SNR} = \text{SNR}_{\text{output}} - \text{SNR}_{\text{input}}

表示噪声抑制后信噪比的提升量，单位为 dB。典型的 WebRTC NS 在不同等级下的 SNR 改善：

* Level 0 (Low): 6~10 dB
* Level 1 (Moderate): 10~15 dB
* Level 2 (High): 15~20 dB
* Level 3 (Very High): 20~25 dB

**语音失真 (Speech Distortion)**

* **PESQ** (Perceptual Evaluation of Speech Quality)：ITU-T P.862 标准，评分范围 1.0~4.5
* **POLQA** (Perceptual Objective Listening Quality Analysis)：ITU-T P.863 标准，PESQ 的升级版
* **STOI** (Short-Time Objective Intelligibility)：评估语音可懂度，范围 0~1

**噪声抑制量 (Noise Attenuation)**

在纯噪声段测量的噪声衰减量，单位为 dB。

**音乐噪声 (Musical Noise)**

音乐噪声是频谱减法类算法的典型伪影，表现为随机出现的短促音调。
可以通过主观听音测试（MOS 评分）或客观指标（如频谱方差）来评估。


噪声估计算法
===================================

噪声估计是噪声抑制的关键环节，常用的算法包括：

**Minimum Statistics**

由 Martin (2001) 提出，基于含噪语音功率谱的局部最小值来估计噪声功率谱。
其核心思想是：在一个较长的时间窗口内，功率谱的最小值近似等于噪声的功率谱。

**MCRA (Minima Controlled Recursive Averaging)**

由 Cohen 和 Berdugo (2002) 提出，结合了最小值跟踪和递归平均：

1. 使用时间递归平均来平滑功率谱
2. 使用局部最小值来检测语音存在
3. 根据语音存在概率来控制噪声估计的更新速率

**IMCRA (Improved MCRA)**

MCRA 的改进版本，使用两次平滑来提高噪声估计的鲁棒性。


瞬态噪声抑制
===================================

WebRTC 中有专门的 ``TransientSuppressor`` 模块来处理瞬态噪声：

* 使用短时能量检测来识别瞬态事件
* 对检测到的瞬态事件应用快速衰减
* 与 NS 模块独立工作，互不干扰

.. code-block:: cpp

   // TransientSuppressor 配置
   config.transient_suppression.enabled = true;


参考资料
===================================

论文
----------------------------------------------

* Boll, S. (1979). "Suppression of acoustic noise in speech using spectral subtraction." IEEE Transactions on Acoustics, Speech, and Signal Processing.
* Ephraim, Y., & Malah, D. (1984). "Speech enhancement using a minimum-mean square error short-time spectral amplitude estimator." IEEE Transactions on Acoustics, Speech, and Signal Processing.
* Martin, R. (2001). "Noise power spectral density estimation based on optimal smoothing and minimum statistics." IEEE Transactions on Speech and Audio Processing.
* Cohen, I., & Berdugo, B. (2002). "Noise estimation by minima controlled recursive averaging for robust speech enhancement." IEEE Signal Processing Letters.
* Valin, J.M. (2018). "A Hybrid DSP/Deep Learning Approach to Real-Time Full-Band Speech Enhancement." IEEE MMSP.

WebRTC 源码
----------------------------------------------

* WebRTC NS 模块: https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/ns/
* WebRTC APM 配置: https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/include/audio_processing.h
* WebRTC Transient Suppressor: https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/transient/
* RNNoise 项目: https://github.com/xiph/rnnoise

其他资源
----------------------------------------------

* RNNoise 演示: https://jmvalin.ca/demo/rnnoise/
* DTLN 项目: https://github.com/breizhn/DTLN
* DNS Challenge (Deep Noise Suppression): https://github.com/microsoft/DNS-Challenge
