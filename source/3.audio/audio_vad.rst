##########################
Voice Activity Detector
##########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Voice Activity Detector
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
===================

Voice activity detection (VAD), also known as speech activity detection or speech detection, is the detection of the presence or absence of human speech, used in speech processing.

The main uses of VAD are in speech coding and speech recognition. It can facilitate speech processing, and can also be used to deactivate some processes during non-speech section of an audio session: it can avoid unnecessary coding/transmission of silence packets in Voice over Internet Protocol (VoIP) applications, saving on computation and on network bandwidth.

VAD is an important enabling technology for a variety of speech-based applications.

Therefore, various VAD algorithms have been developed that provide varying features and compromises between latency, sensitivity, accuracy and computational cost.

Some VAD algorithms also provide further analysis, for example whether the speech is voiced, unvoiced or sustained. Voice activity detection is usually independent of language.

在 WebRTC 中，VAD 扮演着至关重要的角色。它不仅用于语音编码中的 DTX (Discontinuous Transmission) 功能，
还与 AGC (Automatic Gain Control)、NS (Noise Suppression) 等音频处理模块紧密协作。
准确的 VAD 检测可以：

* **节省带宽**: 在静音期间不发送语音数据包，仅发送舒适噪声参数
* **降低功耗**: 减少编码和传输的计算量，对移动设备尤为重要
* **提升音频处理质量**: AGC 仅在语音活动期间调整增益，避免放大噪声
* **支持活跃说话人检测**: 在多方会议中识别当前说话人
* **改善噪声抑制**: 帮助区分语音和噪声，提高噪声抑制的准确性


VAD 算法分类
===================

VAD 算法经历了从简单到复杂、从传统方法到深度学习的演进过程。

基于能量的 VAD (Energy-based VAD)
--------------------------------------

最简单的 VAD 方法是基于信号能量的检测。其基本假设是语音信号的能量高于背景噪声。

**短时能量 (Short-time Energy)**

对每一帧音频信号计算其能量：

.. math::

   E_n = \sum_{m=0}^{N-1} x^2(n \cdot H + m)

其中 :math:`x` 是音频信号，:math:`N` 是帧长，:math:`H` 是帧移。
当 :math:`E_n` 超过预设阈值时，判定为语音帧。

**过零率 (Zero-Crossing Rate, ZCR)**

过零率衡量信号在时域上穿越零点的频率：

.. math::

   ZCR_n = \frac{1}{2N} \sum_{m=1}^{N-1} |sign(x(n \cdot H + m)) - sign(x(n \cdot H + m - 1))|

清音 (unvoiced speech) 通常具有较高的过零率，而浊音 (voiced speech) 具有较低的过零率。
结合能量和过零率可以提高 VAD 的准确性。

**优缺点**:

* 优点：计算简单，延迟低
* 缺点：在低 SNR 环境下性能急剧下降，阈值难以自适应调整


基于频谱的 VAD (Spectral-based VAD)
--------------------------------------

频谱方法利用语音和噪声在频域上的不同特征进行检测。

**频谱平坦度 (Spectral Flatness Measure, SFM)**

频谱平坦度衡量信号频谱的平坦程度。白噪声的频谱接近平坦（SFM 接近 1），
而语音信号由于谐波结构，频谱具有明显的峰谷（SFM 较低）：

.. math::

   SFM = \frac{\left(\prod_{k=0}^{K-1} |X(k)|^2\right)^{1/K}}{\frac{1}{K}\sum_{k=0}^{K-1} |X(k)|^2}

**频谱熵 (Spectral Entropy)**

频谱熵衡量频谱的不确定性。噪声的频谱熵较高（能量均匀分布），
语音的频谱熵较低（能量集中在特定频率）：

.. math::

   H = -\sum_{k=0}^{K-1} p(k) \log_2 p(k)

其中 :math:`p(k) = \frac{|X(k)|^2}{\sum_{j} |X(j)|^2}` 是归一化的功率谱密度。

**优缺点**:

* 优点：比能量方法更鲁棒，能区分语音和某些类型的噪声
* 缺点：对非平稳噪声（如音乐、键盘敲击）效果不佳


基于统计模型的 VAD (Statistical Model VAD)
----------------------------------------------

统计模型方法将 VAD 问题建模为假设检验问题。

**高斯混合模型 (Gaussian Mixture Model, GMM)**

GMM-based VAD 是 WebRTC 传统 VAD 的核心方法。它为语音和噪声分别建立 GMM 模型，
然后通过似然比检验 (Likelihood Ratio Test, LRT) 进行判决：

.. math::

   \Lambda = \frac{p(x | H_1)}{p(x | H_0)} \gtrless \eta

其中 :math:`H_1` 表示语音假设，:math:`H_0` 表示噪声假设，:math:`\eta` 是判决阈值。

GMM 模型：

.. math::

   p(x | H_i) = \sum_{m=1}^{M} w_m \cdot \mathcal{N}(x; \mu_m, \sigma_m^2)

WebRTC 的 GMM VAD 使用 2 个高斯分量来建模每个子带的语音和噪声分布。

**优缺点**:

* 优点：有坚实的统计理论基础，性能较好
* 缺点：需要估计噪声模型参数，对非平稳噪声适应较慢


基于深度学习的 VAD (Deep Learning VAD)
----------------------------------------------

近年来，深度学习方法在 VAD 领域取得了显著进展。

**RNN-based VAD**

循环神经网络 (RNN) 特别适合处理时序信号。Opus 编解码器在高复杂度模式下使用基于 GRU
(Gated Recurrent Unit) 的 RNN VAD：

.. code-block:: text

   输入特征 → GRU Layer 1 → GRU Layer 2 → Dense Layer → Sigmoid → VAD 概率

RNN VAD 的优势在于能够捕捉语音信号的时序依赖关系，对短暂的静音和噪声突发有更好的鲁棒性。

**CNN-based VAD**

卷积神经网络 (CNN) 可以从频谱图中提取局部特征：

* 输入：Mel 频谱图或 MFCC 特征
* 网络结构：多层卷积 + 池化 + 全连接层
* 输出：每帧的语音概率

**Silero VAD**

Silero VAD 是一个流行的开源深度学习 VAD 模型，基于 PyTorch 实现：

* 模型小巧（约 1MB），适合实时应用
* 支持 8kHz 和 16kHz 采样率
* 在多种噪声环境下表现优异

**优缺点**:

* 优点：在低 SNR 环境下性能远超传统方法，泛化能力强
* 缺点：计算量较大，可能需要 GPU 加速；模型训练需要大量标注数据


WebRTC VAD 实现
===================

WebRTC 包含两套 VAD 实现：传统的 GMM-based VAD 和较新的 RNN-based VAD。

传统 GMM VAD (common_audio/vad/)
--------------------------------------

WebRTC 的传统 VAD 位于 ``common_audio/vad/`` 目录下，是一个基于 GMM 的轻量级实现。

**核心 API**

.. code-block:: c

   // 创建 VAD 实例
   VadInst* WebRtcVad_Create(void);

   // 初始化 VAD
   int WebRtcVad_Init(VadInst* handle);

   // 设置 aggressiveness 模式 (0-3)
   int WebRtcVad_set_mode(VadInst* handle, int mode);

   // 处理一帧音频，返回 1 (语音) 或 0 (非语音)
   int WebRtcVad_Process(VadInst* handle,
                         int fs,           // 采样率: 8000/16000/32000/48000
                         const int16_t* audio_frame,
                         size_t frame_length);  // 帧长: 对应 10/20/30ms

   // 释放 VAD 实例
   void WebRtcVad_Free(VadInst* handle);


**Aggressiveness 模式**

WebRTC VAD 提供 4 种激进程度模式，控制 VAD 对语音检测的灵敏度：

.. csv-table:: VAD Aggressiveness 模式
   :header: "模式", "说明", "适用场景"
   :widths: 10, 50, 40

   "0", "最不激进，最容易判定为语音 (低漏检率)", "高质量语音通话，不能丢失任何语音"
   "1", "较不激进", "一般语音通话"
   "2", "较激进，更倾向于判定为非语音", "带宽受限场景"
   "3", "最激进，最容易判定为非语音 (高漏检率)", "极度带宽受限，可容忍少量语音丢失"

模式越激进，静音检测越灵敏（更多帧被判定为非语音），但也更容易将低音量语音误判为噪声。

**支持的帧大小**

WebRTC VAD 支持以下帧大小：

* **10ms**: 最小帧大小，延迟最低，但检测准确性稍差
* **20ms**: 推荐的帧大小，平衡延迟和准确性
* **30ms**: 最大帧大小，检测准确性最好，但延迟较高

对于不同采样率，对应的样本数为：

.. csv-table:: 帧大小与样本数
   :header: "采样率", "10ms", "20ms", "30ms"
   :widths: 20, 20, 20, 20

   "8000 Hz", "80", "160", "240"
   "16000 Hz", "160", "320", "480"
   "32000 Hz", "320", "640", "960"
   "48000 Hz", "480", "960", "1440"


**内部实现：特征提取**

WebRTC GMM VAD 的内部处理流程如下：

1. **下采样**: 如果输入采样率高于 8kHz，先下采样到 8kHz
2. **子带分解**: 将信号分解为 6 个频率子带 (sub-bands)

   * 80-250 Hz
   * 250-500 Hz
   * 500-1000 Hz
   * 1000-2000 Hz
   * 2000-3000 Hz
   * 3000-4000 Hz

3. **特征计算**: 对每个子带计算对数能量特征
4. **GMM 分类**: 使用预训练的 GMM 模型对每个子带进行语音/噪声分类
5. **综合判决**: 综合 6 个子带的分类结果，做出最终的 VAD 判决

.. code-block:: c

   // 内部特征提取 (简化)
   // vad_core.c
   static void WebRtcVad_CalcFeatures(VadInstT* self,
                                       const int16_t* data,
                                       int data_length,
                                       int16_t* features) {
     // 1. 滤波器组将信号分解为 6 个子带
     // 2. 计算每个子带的能量
     // 3. 取对数得到特征向量
   }

**内部实现：GMM 分类**

.. code-block:: c

   // vad_gmm.c
   // 计算高斯分布的对数似然
   int32_t WebRtcVad_GaussianProbability(int16_t input,
                                          int16_t mean,
                                          int16_t std,
                                          int16_t* delta);

每个子带使用 2 个高斯分量的混合模型。语音模型和噪声模型的参数（均值、方差、权重）
是预训练好的，存储在 ``vad_filterbank.c`` 中。噪声模型的参数会在运行时自适应更新。


RNN VAD (modules/audio_processing/agc2/rnn_vad/)
------------------------------------------------------

WebRTC 较新版本中引入了基于 RNN 的 VAD，主要用于 AGC2 (Automatic Gain Controller 2) 模块。

.. code-block:: cpp

   // RNN VAD 的核心类
   class RnnVad {
    public:
     // 处理一帧音频 (10ms, 48kHz)
     // 返回语音概率 [0.0, 1.0]
     float ComputeVadProbability(
         rtc::ArrayView<const float, kFrameSize10ms48kHz> frame,
         bool is_silence);
   };

RNN VAD 的特点：

* 使用 GRU (Gated Recurrent Unit) 网络结构
* 输入特征：band energies 和 pitch features
* 输出：语音概率（0.0 到 1.0 的连续值，而非二值判决）
* 在低 SNR 环境下比 GMM VAD 更准确
* 计算量略大于 GMM VAD，但仍适合实时处理


VAD 在 AudioProcessing 模块中的集成
--------------------------------------

在 WebRTC 的 ``AudioProcessing`` 模块中，VAD 与其他音频处理组件紧密集成：

.. code-block:: cpp

   // AudioProcessing 配置中的 VAD 相关设置
   AudioProcessing::Config config;

   // VAD 主要通过以下模块间接使用：

   // 1. AGC2 中使用 RNN VAD
   config.gain_controller2.enabled = true;
   config.gain_controller2.adaptive_digital.enabled = true;
   // AGC2 内部使用 RNN VAD 来判断是否应该调整增益

   // 2. 传统 AGC 中使用 GMM VAD
   config.gain_controller1.enabled = true;
   config.gain_controller1.mode =
       AudioProcessing::Config::GainController1::kAdaptiveAnalog;

   // 3. 噪声抑制中隐式使用 VAD
   config.noise_suppression.enabled = true;
   config.noise_suppression.level =
       AudioProcessing::Config::NoiseSuppression::kHigh;


VAD 在编解码器中的应用
=========================

VAD in Opus
--------------------------

VAD in Opus determines whether a frame is sent out as empty (DTX) or not.

If speech is classified as silence (false negative), the frame will be empty and speech will be lost.
False negative rate (FNR) needs to be as close to zero as possible when DTX is enabled.
The different VAD in Opus codec under different complexity: VAD ON will trigger DTX ON (400ms),
and VAD's decision will decide whether we should play CNG on playback.

The RNN-VAD is used when complexity setting >= 7 (float), which means when complexity < 7, we use traditional VAD.

**Opus VAD 的两种模式**:

1. **SILK VAD (低复杂度)**: 基于 SNR 的传统方法

   * 估计 4 个频率子带的信噪比
   * 通过平滑逆能量来估计背景噪声水平
   * 将各子带的 SNR 加权组合得到最终的语音活动度量

2. **RNN VAD (高复杂度, complexity >= 7)**: 基于 GRU 的深度学习方法

   * 同时进行 speech/music 和 speech/silence 分类
   * 更准确，但计算量更大

.. code-block:: cpp

   // Opus 编码器中启用 DTX
   opus_encoder_ctl(encoder, OPUS_SET_DTX(1));

   // 设置复杂度（影响 VAD 算法选择）
   opus_encoder_ctl(encoder, OPUS_SET_COMPLEXITY(10));
   // complexity >= 7: 使用 RNN VAD
   // complexity < 7:  使用 SILK VAD


VAD in G.711
--------------------------

G.711 编解码器本身不包含 VAD。需要注意区分 ITU-T 为 G.711 定义的两个附录：

* **G.711 Appendix I**: 丢包隐藏（PLC，Packet Loss Concealment），**不是 VAD**
* **G.711 Appendix II**: 才是 VAD/CNG/DTX 方案，包含语音活动检测、舒适噪声生成和不连续传输


VAD 的应用场景
===================

DTX (Discontinuous Transmission)
--------------------------------------

DTX 是 VAD 最重要的应用之一。在检测到静音时，编码器停止发送语音数据包，
仅周期性地发送舒适噪声 (Comfort Noise, CN) 参数：

.. code-block:: text

   语音活动:  ████████░░░░░░░░████████████░░░░░░████
   RTP 发送:  ████████·CN·····████████████·CN···████
                      ↑                    ↑
                   静音期间仅发送 CN 参数

DTX 的优势：

* 节省约 30-50% 的带宽（因为人在对话中约有 50-60% 的时间是沉默的）
* 降低网络拥塞
* 减少移动设备的功耗

DTX 的风险：

* 如果 VAD 误判语音为静音（false negative），会导致语音丢失
* 静音到语音的切换可能产生短暂的不自然感


CNG (Comfort Noise Generation)
--------------------------------------

CNG 与 DTX 配合使用。在静音期间，接收端需要播放舒适噪声而非完全静音，
因为完全静音会让用户误以为通话断开。

There is a Real-time Transport Protocol (RTP) Payload for Comfort Noise (CN).
(refer to RFC 3389)

The payload format provides a minimum interoperability specification for communication of comfort noise parameters. The comfort noise analysis and synthesis as well as the Voice Activity Detection (VAD) and DTX.

Two popular types of VAD/CNG schemes are included in G.711.

The noise power levels in both VAD/CNG methods are expressed in −dBov to interoperate with each other.

The unit "dBov" is the dB level relative to the overload of the system. It is not a Volts reference for dBV.

For example, in the case of μ-law-based coding, the maximum sine wave signal power without distortion is 3.17 dBm with amplitude ±8159. Square wave power is 3 dB more than sine wave power. The maximum possible power of signal from a square wave with an amplitude of ±8159 is 0 dBov as reference, which corresponds to a 6.17-dBm power level in the μ-law system. Hence, 0 dBov = 6.17 dBm is used in μ-law system.

.. code-block:: cpp

   // WebRTC 中的 CNG 编码器
   // modules/audio_coding/codecs/cng/
   class ComfortNoiseEncoder {
    public:
     // 编码舒适噪声参数
     size_t Encode(rtc::ArrayView<const int16_t> speech,
                   bool force_sid,  // 是否强制发送 SID 帧
                   rtc::Buffer* output);
   };

   class ComfortNoiseDecoder {
    public:
     // 生成舒适噪声
     void Generate(rtc::ArrayView<int16_t> output);
   };


AGC 集成
--------------------------

VAD 与 AGC (Automatic Gain Control) 紧密协作：

* AGC 仅在检测到语音活动时调整增益
* 在静音期间，AGC 保持当前增益不变，避免放大背景噪声
* RNN VAD 提供的语音概率值可以用于平滑增益调整

.. code-block:: cpp

   // AGC2 中使用 VAD 概率
   void AdaptiveDigitalGainController::Process(
       const AudioFrameView<float>& frame,
       float speech_probability) {
     if (speech_probability > kVadConfidenceThreshold) {
       // 语音帧：根据目标电平调整增益
       UpdateGain(frame);
     } else {
       // 非语音帧：保持增益不变
       HoldGain();
     }
   }


Audio Level Indication (RFC 6464)
--------------------------------------

RFC 6464 定义了在 RTP 头扩展中携带音频电平信息的机制。VAD 的结果也可以通过此扩展传递：

.. code-block:: text

    0                   1
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ID   | len=0 |V|   level     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

   V: VAD flag (1 = voice activity, 0 = no voice activity)
   level: audio level in -dBov (0-127)

在多方会议中，SFU 可以利用此信息进行：

* **活跃说话人检测**: 选择音频电平最高且 VAD 为 1 的参与者
* **音频混合优化**: 只混合活跃说话人的音频流
* **视频布局切换**: 将活跃说话人的视频放大显示


噪声抑制集成
--------------------------

VAD 帮助噪声抑制模块区分语音和噪声：

* 在非语音帧中更新噪声估计模型
* 在语音帧中应用噪声抑制但保护语音成分
* VAD 的准确性直接影响噪声抑制的质量


VAD 定义与模型
========================

* SILK VAD (SNR based)

SILK VAD is based on SNR, which estimates the noise level to determine speech activity.
The Voice Activity Detector (VAD) generates a measure of speech activity by combining the signal-to-noise ratios (SNRs) from 4 separate frequency bands. In each band the background noise level is estimated by smoothing the inverse energy over time frames.
Multiplying this smoothed inverse energy with the subband energy gives the SNR.

* Opus VAD (RNN based)

Opus VAD uses recursive neural network based on GRU units to perform both speech/music and speech/silence classification.


VAD 算法流程
========================

1. There may first be a noise reduction stage, e.g. via spectral subtraction.
2. Then some features or quantities are calculated from a section of the input signal.
3. A classification rule is applied to classify the section as speech or non-speech – often this classification rule finds when a value exceeds a certain threshold.

There may be some feedback in this sequence, in which the VAD decision is used to improve the noise estimate in the noise reduction stage, or to adaptively vary the threshold(s). These feedback operations improve the VAD performance in non-stationary noise (i.e. when the noise varies a lot).

A representative set of recently published VAD methods formulates the decision rule on a frame by frame basis using instantaneous measures of the divergence distance between speech and noise. The different measures which are used in VAD methods include spectral slope, correlation coefficients, log likelihood ratio, cepstral, weighted cepstral, and modified distance measures.

Independently from the choice of VAD algorithm, a compromise must be made between having voice detected as noise, or noise detected as voice (between false positive and false negative). A VAD operating in a mobile phone must be able to detect speech in the presence of a range of very diverse types of acoustic background noise. In these difficult detection conditions it is often preferable that a VAD should fail-safe, indicating speech detected when the decision is in doubt, to lower the chance of losing speech segments. The biggest difficulty in the detection of speech in this environment is the very low signal-to-noise ratios (SNRs) that are encountered. It may be impossible to distinguish between speech and noise using simple level detection techniques when parts of the speech utterance are buried below the noise.


GMM VAD
-------------------

WebRTC 的 GMM VAD 实现位于 ``common_audio/vad/`` 目录下，主要文件包括：

* ``vad_core.c``: VAD 核心逻辑
* ``vad_filterbank.c``: 滤波器组和特征提取
* ``vad_gmm.c``: 高斯混合模型计算
* ``vad_sp.c``: 信号处理辅助函数

源码链接: https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/common_audio/vad/vad_gmm.h


性能指标
========================

评估 VAD 性能的关键指标：

.. csv-table:: VAD 性能指标
   :header: "指标", "定义", "影响"
   :widths: 25, 40, 35

   "False Positive Rate (FPR)", "噪声被误判为语音的比例", "FPR 高导致带宽浪费"
   "False Negative Rate (FNR)", "语音被误判为噪声的比例", "FNR 高导致语音丢失（严重）"
   "Accuracy", "正确判定的帧占总帧数的比例", "综合性能指标"
   "Latency", "从语音开始到检测到语音的延迟", "影响通话体验"
   "Hangover Time", "语音结束后继续判定为语音的时间", "防止语音尾部被截断"

**Hangover 机制**

Hangover 是 VAD 中的一个重要机制。当 VAD 检测到语音结束后，不会立即切换到非语音状态，
而是保持语音状态一段时间（通常 100-300ms）。这样做的目的是：

* 防止语音尾部（如辅音、尾音）被截断
* 避免在短暂停顿时频繁切换状态
* 提高 DTX 的主观质量

.. code-block:: text

   实际语音:    ████████████░░████████░░░░░░░░░░░░
   VAD 输出:    ████████████████████████████░░░░░░
                                        ↑
                                   Hangover 延长


JavaScript API 配置
========================

在 WebRTC 的 JavaScript API 中，VAD 相关的配置主要通过 ``MediaConstraints`` 进行：

.. code-block:: javascript

   // 启用/禁用自动增益控制（内部使用 VAD）
   const constraints = {
     audio: {
       autoGainControl: true,    // AGC 内部使用 VAD
       noiseSuppression: true,   // NS 内部使用 VAD
       echoCancellation: true,
     }
   };

   const stream = await navigator.mediaDevices.getUserMedia(constraints);

   // 通过 AudioContext 获取音频电平（可用于自定义 VAD）
   const audioContext = new AudioContext();
   const source = audioContext.createMediaStreamSource(stream);
   const analyser = audioContext.createAnalyser();
   analyser.fftSize = 2048;
   source.connect(analyser);

   // 简单的能量检测 VAD
   function detectVoiceActivity() {
     const dataArray = new Float32Array(analyser.frequencyBinCount);
     analyser.getFloatTimeDomainData(dataArray);

     let sumSquares = 0;
     for (let i = 0; i < dataArray.length; i++) {
       sumSquares += dataArray[i] * dataArray[i];
     }
     const rms = Math.sqrt(sumSquares / dataArray.length);
     const dB = 20 * Math.log10(rms);

     return dB > -40;  // 阈值可调
   }


常见问题
========================

1. **音乐被误判为噪声**: 传统 VAD 算法针对语音设计，音乐信号的特征与语音不同，
   容易被误判为噪声。解决方案：

   * 使用 Opus 的 RNN VAD（支持 speech/music 分类）
   * 降低 VAD aggressiveness 模式
   * 在音乐场景下禁用 DTX

2. **低音量语音被漏检**: 当说话人声音很小或距离麦克风较远时，语音能量可能低于 VAD 阈值。
   解决方案：

   * 使用较低的 aggressiveness 模式（0 或 1）
   * 启用 AGC 预处理，先放大信号再进行 VAD
   * 使用 RNN VAD 替代 GMM VAD

3. **键盘敲击等脉冲噪声触发 VAD**: 短促的脉冲噪声可能被误判为语音。解决方案：

   * 使用较高的 aggressiveness 模式（2 或 3）
   * 增加 hangover 时间的最小语音持续时间要求
   * 在 VAD 前添加瞬态噪声抑制

4. **多人同时说话时 VAD 不准确**: 当多个说话人的声音混合时，VAD 通常会持续判定为语音活动。
   这在多方会议中是正常行为，但可能影响 DTX 的效果。


Reference
===================
* https://en.wikipedia.org/wiki/Voice_activity_detection
* https://github.com/wiseman/py-webrtcvad
* https://github.com/snakers4/silero-vad
* https://colab.research.google.com/github/snakers4/silero-vad/blob/master/silero-vad.ipynb
* https://chromium.googlesource.com/external/webrtc/+/518c683f3e413523a458a94b533274bd7f29992d/webrtc/modules/audio_processing/vad/voice_activity_detector.h
* https://www.mathworks.com/matlabcentral/fileexchange/78895-google-webrtc-voice-activity-detection-vad-module
* https://github.com/cpuimage/WebRTC_VAD
* `RFC 3389`_ "Real-time Transport Protocol (RTP) Payload for Comfort Noise (CN)"
* `RFC 6464`_ "A Real-time Transport Protocol (RTP) Header Extension for Client-to-Mixer Audio Level Indication"
* https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/common_audio/vad/
* https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/audio_processing/agc2/rnn_vad/
