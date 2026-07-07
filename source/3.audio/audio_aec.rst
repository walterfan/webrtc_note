##############################
Acoustic Echo Canceller
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Acoustic Echo Canceller
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
===================
回声抵消 (AEC) 指的是在二线传输的两个方向上同时间、同频谱地占用线路, 在线路上两个方向传输的信号完全混在一起, 本端发信号的回声即成为本端收信号的干扰信号, 利用自适应滤波器可抵消回声以达到较好的接收信号质量. 也就是消除回声. 

回声消除的原理就是利用接收到的音频与本地采集的音频做对比, 添加反相的人造回声, 将远端的声音消除. 

WebRTC library 提供了 Echo Cancellation 的功能

MediaTrackSettings.echoCancellation
----------------------------------------------

The MediaTrackSettings dictionary's echoCancellation property is a Boolean value whose value indicates whether or not echo cancellation is enabled on an audio track.


何为回声？
-----------------------------------------------

In audio signal processing and acoustics, an echo is a reflection of sound that arrives at the listener with a delay after the direct sound. The delay is directly proportional to the distance of the reflecting surface from the source and the listener. Typical examples are the echo produced by the bottom of a well, by a building, or by the walls of an enclosed room and an empty room. A true echo is a single reflection of the sound source.[citation needed]

回声产生的原因
--------------------

从通讯回音产生的原因看, 可以分为声学回音 (Acoustic Echo) 和线路回音 (Line Echo) , 相应的回声消除技术就叫声学回声消除 (Acoustic Echo Cancelation, AEC) 和线路回声消除 (Line Echo Canceltion, LEC) .


一方面, IP电话系统与PSTN互联时, 涉及到混合线圈的2/4线转换电路, 因而会产生线路回声 (Line Echo) . 另一方面, IP电话的语音数据在传输过程中还存在"声学回声(Acoustic Echo) ".

线路回声
~~~~~~~~~~~~~~~~~
线路回声通常产生于有线通话中, 为了降低电话中心局与电话用户之间电话线的价格, 用户间线的连接采用两线制；而电话中心局之间连接采用四线制 (上面两条线路用于发送给用户端信号, 下面两条线路用于接收用户端信号) . 问题就出来了, 造成电路回声的根本原因是转换混合器的二线-四线阻抗不能完全匹配 (使用的不同型号的电线或者负载线圈没有被使用的原因) , 导致混合器 接收线路 上的语音信号流失到了 发送线路 , 产生了回声信号, 使得另一端的用户在接收信号的同时听到了自己的声音

声学回声
~~~~~~~~~~~~~~~~~

声学回声是指扬声器播放出来的声音被麦克风拾取后发回远端, 使远端谈话者能听到自己的声音.


声学回声又分为直接回声和间接回声.

* 直接回声是指扬声器播放出来的声音未经任何反射直接进入麦克风. 这种回声延迟最短, 它与远端说话者的语音能量, 扬声器与话筒之间的距离、角度、扬声器的播放音量以及话筒的拾取灵敏度等因素相关；

* 间接回声是指扬声器播放的声音经不同的路径一次或多次反射后进入麦克风所产生的回声集合.

当回声返回时间超过 10 ms时, 人耳就可听到明显的回声了, 会干扰正常通话. 对于时延相对较大的IP网络环境, 时延很容易就达到50 ms, 因此必须清除回声.


在网络会议中, 近端通话者的声音被自己的麦克风拾取后通过网络传到远端，远端扬声器播放出来的声音被麦克风拾取后通过网络又重新发回近端。
加上网络和数据处理等各种延迟的影响，使得近端通话者能够从扬声器中听到自己的刚才所说的话，就产生了回声。


回声路径模型
--------------------

声学回声可以用线性系统来建模。假设远端信号为 :math:`x(n)`，回声路径的脉冲响应为 :math:`h(n)`，
则麦克风采集到的回声信号 :math:`d(n)` 可以表示为：

.. math::

   d(n) = \sum_{k=0}^{L-1} h(k) \cdot x(n-k) = \mathbf{h}^T \mathbf{x}(n)

其中 :math:`L` 是回声路径的长度（以采样点为单位），:math:`\mathbf{h} = [h(0), h(1), \ldots, h(L-1)]^T` 是回声路径的脉冲响应向量，
:math:`\mathbf{x}(n) = [x(n), x(n-1), \ldots, x(n-L+1)]^T` 是远端信号向量。

麦克风实际采集到的信号 :math:`y(n)` 包含近端语音 :math:`s(n)`、回声 :math:`d(n)` 和背景噪声 :math:`v(n)`：

.. math::

   y(n) = s(n) + d(n) + v(n) = s(n) + \mathbf{h}^T \mathbf{x}(n) + v(n)

AEC 的目标是估计回声路径 :math:`\hat{\mathbf{h}}`，然后从麦克风信号中减去估计的回声：

.. math::

   e(n) = y(n) - \hat{\mathbf{h}}^T \mathbf{x}(n)

当 :math:`\hat{\mathbf{h}} \approx \mathbf{h}` 时，误差信号 :math:`e(n) \approx s(n) + v(n)`，即回声被消除。

典型的房间回声路径长度为 100~500ms，在 16kHz 采样率下对应 1600~8000 个抽头的 FIR 滤波器。


回声消除的方法
-----------------------

回声消除是非常复杂的技术, 但我们可以简单的描述两种处理方法：

1. 回声路径消除

2) 房间A的音频会议系统接收到房间B中的声音

3) 声音被采样, 这一采样被称为回声消除参考

4) 随后声音被送到房间A的音箱和声学回声消除器中

5) 房间B的声音和房间A的声音一起被房间A的话筒拾取

6) 声音被送到声学回声消除器中, 与原始的采样进行比较, 移除房间B的声音

2. 自适应滤波器

自适应滤波器是以输入和输出信号的统计特性的估计为依据, 采取特定算法自动地调整滤波器系数, 使其达到最佳滤波特性的一种算法或装置. 
自适应滤波器 可以是连续域的或是离散域的. 离散域自适应滤波器由一组抽头延迟线、可变加权系数和自动调整系数的机构组成. 


自适应滤波算法详解
-----------------------

LMS (Least Mean Squares) 算法
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

LMS 算法是最基本的自适应滤波算法，由 Widrow 和 Hoff 于 1960 年提出。
其核心思想是沿误差信号梯度的反方向更新滤波器系数：

.. math::

   \mathbf{w}(n+1) = \mathbf{w}(n) + \mu \cdot e(n) \cdot \mathbf{x}(n)

其中 :math:`\mu` 是步长因子（step size），:math:`e(n) = y(n) - \mathbf{w}^T(n)\mathbf{x}(n)` 是误差信号。

LMS 算法简单但存在两个问题：

* 收敛速度取决于输入信号的功率，语音信号功率变化大导致收敛不稳定
* 步长选择困难：太大会发散，太小收敛慢

NLMS (Normalized Least Mean Squares) 算法
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

NLMS 通过对输入信号功率进行归一化来解决 LMS 的收敛问题：

.. math::

   \mathbf{w}(n+1) = \mathbf{w}(n) + \frac{\mu}{\|\mathbf{x}(n)\|^2 + \delta} \cdot e(n) \cdot \mathbf{x}(n)

其中 :math:`\|\mathbf{x}(n)\|^2 = \sum_{k=0}^{L-1} x^2(n-k)` 是输入信号的能量，
:math:`\delta` 是一个小的正则化常数（防止除零）。

NLMS 的关键特性：

* **收敛条件**: :math:`0 < \mu < 2`，通常取 :math:`\mu = 0.5 \sim 1.0`
* **稳态失调** (Steady-state Misadjustment): :math:`M \approx \frac{\mu \cdot L}{2 - \mu}`
* **收敛速度**: 与滤波器长度 :math:`L` 和步长 :math:`\mu` 相关
* 归一化使得收敛速度不再依赖于输入信号的功率

频域自适应滤波 (FDAF / PBFDAF)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

对于长滤波器（如回声消除中的数千个抽头），时域 NLMS 的计算复杂度为 :math:`O(L)` 每个采样点，
总复杂度为 :math:`O(L^2)` 每帧。频域自适应滤波（Frequency-Domain Adaptive Filter, FDAF）
利用 FFT 将卷积转换为频域乘法，大幅降低计算复杂度。

**分区块频域自适应滤波 (Partitioned Block Frequency-Domain Adaptive Filter, PBFDAF)**

PBFDAF 是 WebRTC AEC3 采用的核心算法。其基本思想是：

1. 将长滤波器分成多个短块（partition），每块长度为 :math:`B` （通常等于 FFT 大小的一半）
2. 每个块在频域中独立进行自适应更新
3. 利用 overlap-save 方法实现线性卷积

假设滤波器长度为 :math:`L`，分成 :math:`P = L/B` 个块，则：

.. math::

   \hat{D}(k) = \sum_{p=0}^{P-1} W_p(k) \cdot X_p(k)

其中 :math:`W_p(k)` 是第 :math:`p` 个分区的频域滤波器系数，:math:`X_p(k)` 是对应的远端信号频谱。

频域 NLMS 更新公式：

.. math::

   W_p(k, m+1) = W_p(k, m) + \frac{\mu}{S_{xx}(k, m) + \delta} \cdot E(k, m) \cdot X_p^*(k, m)

其中 :math:`S_{xx}(k, m)` 是输入信号的功率谱估计，:math:`X_p^*(k, m)` 是远端信号频谱的共轭。

PBFDAF 的优势：

* 计算复杂度从 :math:`O(L^2)` 降低到 :math:`O(L \log L)` 每帧
* 每个分区可以独立控制步长，提高收敛性能
* 天然支持频域处理，便于与非线性处理结合

滤波器收敛与发散
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

自适应滤波器的收敛性是 AEC 性能的关键：

**收敛** (Convergence)：滤波器系数逐渐逼近真实的回声路径，回声残留逐渐减小。
影响收敛速度的因素包括：

* **步长** :math:`\mu`：步长越大收敛越快，但稳态失调也越大
* **输入信号特性**：白噪声收敛最快，语音信号（高度相关）收敛较慢
* **滤波器长度** :math:`L`：滤波器越长，收敛越慢
* **信噪比**：噪声越大，收敛越困难

**发散** (Divergence)：滤波器系数偏离真实回声路径，回声残留增大甚至产生啸叫。
导致发散的常见原因：

* 双讲（Double-talk）期间未冻结滤波器更新
* 步长过大
* 回声路径突变（如有人移动、门窗开关）
* 延迟估计错误导致远端参考信号未对齐


延迟估计 (Delay Estimation)
===================================

延迟估计是 AEC 的第一步，也是最关键的一步。如果远端参考信号与麦克风信号之间的延迟估计不准确，
自适应滤波器将无法正确收敛。

系统延迟 vs 算法延迟
-----------------------

**系统延迟** (System Delay)：从远端信号被送到扬声器播放，到该信号被麦克风采集并传回 AEC 模块的总延迟。
系统延迟包括：

* 播放缓冲区延迟（Playout buffer delay）
* DAC 延迟（Digital-to-Analog Converter delay）
* 声学传播延迟（Acoustic propagation delay）
* ADC 延迟（Analog-to-Digital Converter delay）
* 采集缓冲区延迟（Capture buffer delay）

典型的系统延迟范围为 20~200ms，在某些设备上可能更长。

**算法延迟** (Algorithmic Delay)：AEC 算法本身引入的处理延迟，通常为 1~2 个帧长（10~20ms）。

基于互相关的延迟估计
-----------------------

最常用的延迟估计方法是基于互相关（Cross-Correlation）的方法：

.. math::

   R_{xy}(\tau) = \sum_{n=0}^{N-1} x(n) \cdot y(n + \tau)

延迟估计值为互相关函数的峰值位置：

.. math::

   \hat{\tau} = \arg\max_{\tau} R_{xy}(\tau)

为了提高鲁棒性，通常使用 **广义互相关** (Generalized Cross-Correlation, GCC)：

.. math::

   R_{xy}^{GCC}(\tau) = \text{IFFT}\left\{\frac{X(k) \cdot Y^*(k)}{|X(k) \cdot Y^*(k)|^\gamma}\right\}

其中 :math:`\gamma` 是加权指数，:math:`\gamma = 1` 对应 GCC-PHAT（Phase Transform），
对混响和噪声具有较好的鲁棒性。

WebRTC AEC3 中的延迟估计使用了多种策略：

* 基于 API 报告的系统延迟作为初始估计
* 使用互相关进行精细延迟搜索
* 支持延迟的动态跟踪和调整
* 使用 Render Buffer 来缓存远端信号，容纳延迟变化


双讲检测 (Double-Talk Detection)
===================================

双讲（Double-Talk）是指近端和远端同时说话的情况。在双讲期间，麦克风信号中同时包含近端语音和回声，
如果此时继续更新自适应滤波器，近端语音会被当作误差信号，导致滤波器系数偏离正确值（发散）。

因此，双讲检测是 AEC 中至关重要的模块。

为什么双讲检测如此关键
-----------------------

* **滤波器保护**：在双讲期间冻结（或减慢）滤波器更新，防止发散
* **语音质量**：避免近端语音被错误地当作回声而被消除（语音削波）
* **用户体验**：双讲是实际通话中的常见场景，处理不好会严重影响通话质量

Geigel 算法
-----------------------

Geigel 算法是最简单的双讲检测方法，基于近端信号和远端信号的幅度比较：

如果满足以下条件，则判定为双讲：

.. math::

   |y(n)| > T \cdot \max_{0 \leq k \leq L-1} |x(n-k)|

其中 :math:`T` 是阈值（通常取 0.5~0.7），:math:`L` 是回声路径长度。

Geigel 算法的优点是计算简单，缺点是：

* 对阈值敏感
* 无法处理回声路径增益大于 1 的情况
* 在低 ERLE（Echo Return Loss Enhancement）条件下性能差

归一化互相关 (Normalized Cross-Correlation)
----------------------------------------------

更鲁棒的双讲检测方法基于远端信号和误差信号的归一化互相关：

.. math::

   \rho(n) = \frac{|\mathbf{x}^T(n) \cdot \mathbf{e}(n)|}{\|\mathbf{x}(n)\| \cdot \|\mathbf{e}(n)\|}

其中 :math:`\mathbf{e}(n)` 是误差信号向量。

* 当只有回声（单讲远端）时，:math:`\rho` 接近 0（因为误差信号主要是噪声）
* 当存在双讲时，:math:`\rho` 增大（因为误差信号中包含近端语音，与远端信号不相关）

判定规则：当 :math:`\rho > \theta` 时判定为双讲，:math:`\theta` 是预设阈值。

基于相干性的双讲检测
-----------------------

WebRTC AEC3 使用了更先进的基于信号相干性（Coherence）的双讲检测方法：

.. math::

   C_{xy}(k) = \frac{|S_{xy}(k)|^2}{S_{xx}(k) \cdot S_{yy}(k)}

其中 :math:`S_{xy}(k)` 是互功率谱密度，:math:`S_{xx}(k)` 和 :math:`S_{yy}(k)` 是自功率谱密度。

* 高相干性表示远端信号和近端信号高度相关 → 回声为主
* 低相干性表示两者不相关 → 可能存在双讲或近端语音


WebRTC AEC 实现
===================================

WebRTC 中的回声消除经历了多个版本的演进：

AEC (Legacy)
-----------------------

早期的 AEC 实现（``EchoCancellationImpl``）基于时域 NLMS 自适应滤波器，
位于 ``modules/audio_processing/aec/`` 目录下。其主要特点：

* 使用时域 NLMS 算法
* 支持固定的滤波器长度（128ms 或 256ms）
* 包含简单的非线性处理（NLP）
* 已被标记为 deprecated，不推荐在新项目中使用

AECM (AEC Mobile)
-----------------------

AECM（``EchoControlMobileImpl``）是为移动设备优化的轻量级回声消除实现，
位于 ``modules/audio_processing/aecm/`` 目录下。其特点：

* 计算复杂度低，适合移动设备
* 使用定点运算
* 回声抑制能力弱于 AEC/AEC3
* 适用于手持设备（扬声器和麦克风距离近，回声路径短）

AEC3 (现代实现)
-----------------------

AEC3（``EchoCanceller3``）是 WebRTC 当前默认的回声消除实现，
位于 ``modules/audio_processing/aec3/`` 目录下。AEC3 是一个完整重写的现代化回声消除器，
性能远超 Legacy AEC。

**整体架构**

AEC3 的处理流程分为以下几个主要阶段：

::

  远端信号 (Render) ──→ Render Buffer ──→ 延迟估计
                                            ↓
  近端信号 (Capture) ──→ 分帧/FFT ──→ 线性滤波 ──→ 残余回声抑制 ──→ 舒适噪声 ──→ 输出
                                         ↑
                                    自适应滤波器更新

**Block Processing 架构**

AEC3 以 64 采样点为一个 block 进行处理（在 48kHz 采样率下约 1.33ms），
使用 PBFDAF（Partitioned Block Frequency-Domain Adaptive Filter）算法：

.. code-block:: cpp

   // AEC3 核心处理类
   class EchoCanceller3 {
   public:
     EchoCanceller3(const EchoCanceller3Config& config,
                    int sample_rate_hz,
                    size_t num_render_channels,
                    size_t num_capture_channels);

     // 缓存远端参考信号
     void AnalyzeRender(const AudioBuffer& render);
     // 处理近端信号，消除回声
     void AnalyzeCapture(const AudioBuffer& capture);
     void ProcessCapture(AudioBuffer* capture, bool level_change);
   };

**Render Buffer 与对齐 (Alignment)**

Render Buffer 是 AEC3 中用于缓存远端信号的环形缓冲区：

* 缓存足够长的远端信号历史（通常 250~500ms）
* 支持延迟的动态搜索和调整
* 使用 ``RenderDelayBuffer`` 类实现

延迟对齐的过程：

1. 初始延迟估计：基于系统报告的播放延迟
2. 精细搜索：使用互相关在 Render Buffer 中搜索最佳对齐位置
3. 动态跟踪：持续监测延迟变化并调整

**回声路径估计 (Echo Path Estimation)**

AEC3 使用 PBFDAF 进行回声路径估计，核心组件包括：

* ``AdaptiveFirFilter``: 自适应 FIR 滤波器，在频域中操作；AEC3 用它同时实例化两路滤波器
* **Refined Filter（精细滤波器）**: 收敛慢但稳态性能好，用于生成回声估计
* **Coarse Filter（粗略滤波器）**: 自适应更快，用于快速跟踪回声路径变化
* ``FilterAnalyzer``: 分析滤波器状态，检测收敛/发散

.. note::

   早期 AEC3 曾使用 “main filter / shadow filter”（主/影子滤波器）的命名，
   约 2020 年中被重命名为 “refined filter / coarse filter”（精细/粗略滤波器）。
   本文以当前主干代码的命名为准。

精细滤波器和粗略滤波器的双滤波器结构是 AEC3 的一个重要设计：

* 精细滤波器（refined）适应较慢，收敛慢但稳态性能好
* 粗略滤波器（coarse）适应较快，收敛快但稳态失调大
* 当粗略滤波器性能优于精细滤波器时，将其系数复制到精细滤波器

**残余回声抑制 (Residual Echo Suppression)**

线性自适应滤波器无法完全消除回声，原因包括：

* 回声路径中的非线性成分（如扬声器失真）
* 滤波器长度不足以覆盖完整的回声路径
* 滤波器尚未完全收敛

因此需要非线性的残余回声抑制（Residual Echo Suppressor, RES）：

.. code-block:: cpp

   // 残余回声抑制器
   class ResidualEchoEstimator {
     // 估计残余回声的功率谱
     void Estimate(const AecState& aec_state,
                   const AudioBuffer& render,
                   rtc::ArrayView<float> R2);
   };

   class SuppressionGain {
     // 计算抑制增益
     std::array<float, kFftLengthBy2Plus1> GetGain(
         rtc::ArrayView<const float> nearend_power,
         rtc::ArrayView<const float> residual_echo_power,
         rtc::ArrayView<const float> comfort_noise_power);
   };

残余回声抑制的基本原理是估计残余回声的功率谱，然后计算频域抑制增益：

.. math::

   G(k) = \frac{S_{ss}(k)}{S_{ss}(k) + S_{rr}(k)}

其中 :math:`S_{ss}(k)` 是近端语音的功率谱估计，:math:`S_{rr}(k)` 是残余回声的功率谱估计。

**舒适噪声注入 (Comfort Noise Injection)**

回声抑制后，在回声被消除的频段会出现不自然的静默（"死寂"感），
舒适噪声生成器（Comfort Noise Generator, CNG）会注入低电平的背景噪声来填充这些静默段：

* 估计背景噪声的频谱特性
* 生成与背景噪声统计特性匹配的人工噪声
* 在回声被抑制的频段注入舒适噪声
* 使通话听起来更自然

**关键配置参数**

.. code-block:: cpp

   // 注意：该配置结构体当前位于 api/audio/echo_canceller3_config.h
   struct EchoCanceller3Config {
     struct Filter {
       struct RefinedConfiguration {
         size_t length_blocks;    // 精细滤波器长度（以 block 为单位）
         float leakage_converged;
         float leakage_diverged;
         float error_floor;
         float error_ceil;
         float noise_gate;
       };
       struct CoarseConfiguration {
         size_t length_blocks;    // 粗略滤波器长度
         float rate;              // 粗略滤波器自适应速率（非“步长”字段）
         float noise_gate;
       };
       // 稳态阶段配置
       RefinedConfiguration refined;   // length_blocks 默认 13，约 170ms @ 48kHz
       CoarseConfiguration  coarse;    // length_blocks 默认 13
       // 初始（快速自适应）阶段配置
       RefinedConfiguration refined_initial;
       CoarseConfiguration  coarse_initial;
     } filter;

     struct Delay {
       // 默认延迟（以 block 为单位）
       size_t default_delay = 5;
       // 延迟搜索范围
       size_t num_filters = 5;
       // API 报告的延迟偏移
       size_t api_call_jitter_blocks = 26;
     } delay;

     struct Suppressor {
       // 近端信号的最小增益
       float nearend_average_blocks = 4.0f;
     } suppressor;

     // 是否启用回声泄漏检测
     bool echo_audibility_enabled = true;
   };


WebRTC AEC 配置
-----------------------

在 WebRTC 中配置 AEC：

.. code-block:: cpp

   // C++ API
   AudioProcessing::Config config;
   config.echo_canceller.enabled = true;
   config.echo_canceller.mobile_mode = false;  // 使用 AEC3
   // mobile_mode = true 时使用 AECM

   auto apm = AudioProcessingBuilder().SetConfig(config).Create();

在 JavaScript 中：

.. code-block:: javascript

   const constraints = {
     audio: {
       echoCancellation: true,
       // Chrome 特有的扩展约束
       googEchoCancellation: true,
       googEchoCancellation2: true  // 启用 AEC3
     }
   };

   navigator.mediaDevices.getUserMedia(constraints);


AEC 处理流水线
===================================

完整的 AEC 处理流水线描述了从音频采集到输出的每一个处理步骤。理解这个流水线对于调试和优化 AEC 至关重要。

完整处理流程
-----------------------

::

  ┌─────────────────────────────────────────────────────────────────────────┐
  │                        AEC 完整处理流水线                                │
  ├─────────────────────────────────────────────────────────────────────────┤
  │                                                                         │
  │  远端信号 x(n)                                                          │
  │      │                                                                  │
  │      ▼                                                                  │
  │  ┌──────────┐    ┌──────────────┐    ┌──────────────┐                  │
  │  │ 分帧/加窗 │───→│ Render Buffer │───→│  延迟估计     │                  │
  │  └──────────┘    │  (环形缓冲)   │    │ (互相关搜索)  │                  │
  │                  └──────────────┘    └──────┬───────┘                  │
  │                                             │                          │
  │  近端信号 y(n)                              │ 对齐后的远端信号            │
  │      │                                      │                          │
  │      ▼                                      ▼                          │
  │  ┌──────────┐    ┌──────────────────────────────────┐                  │
  │  │ 分帧/FFT │───→│        线性自适应滤波              │                  │
  │  └──────────┘    │  (PBFDAF: 主滤波器 + 影子滤波器)   │                  │
  │                  └──────────────┬───────────────────┘                  │
  │                                 │                                      │
  │                                 ▼                                      │
  │                  ┌──────────────────────────────────┐                  │
  │                  │        双讲检测 (DTD)              │                  │
  │                  │  (控制滤波器更新 / 冻结系数)        │                  │
  │                  └──────────────┬───────────────────┘                  │
  │                                 │                                      │
  │                                 ▼                                      │
  │                  ┌──────────────────────────────────┐                  │
  │                  │     非线性处理 (NLP)               │                  │
  │                  │  (残余回声功率估计 + 抑制增益计算)   │                  │
  │                  └──────────────┬───────────────────┘                  │
  │                                 │                                      │
  │                                 ▼                                      │
  │                  ┌──────────────────────────────────┐                  │
  │                  │     残余回声抑制 (RES)             │                  │
  │                  │  (频域维纳滤波 / 谱减法)           │                  │
  │                  └──────────────┬───────────────────┘                  │
  │                                 │                                      │
  │                                 ▼                                      │
  │                  ┌──────────────────────────────────┐                  │
  │                  │     舒适噪声注入 (CNG)             │                  │
  │                  │  (填充被抑制频段的静默)             │                  │
  │                  └──────────────┬───────────────────┘                  │
  │                                 │                                      │
  │                                 ▼                                      │
  │                  ┌──────────────────────────────────┐                  │
  │                  │     IFFT / 重叠相加 / 输出         │                  │
  │                  └──────────────────────────────────┘                  │
  │                                 │                                      │
  │                                 ▼                                      │
  │                          输出信号 e(n)                                  │
  │                    (近端语音 + 残余噪声)                                │
  │                                                                         │
  └─────────────────────────────────────────────────────────────────────────┘

各阶段详解
-----------------------

**第一阶段：信号采集与缓冲**

远端信号 :math:`x(n)` 通过 ``AnalyzeRender()`` 接口进入 AEC3，被存储到 Render Buffer 中。
近端信号 :math:`y(n)` 通过 ``AnalyzeCapture()`` 和 ``ProcessCapture()`` 接口进入处理流程。

两路信号都被分成 64 采样点的 block，并进行 FFT 变换到频域。

**第二阶段：延迟对齐**

延迟估计器在 Render Buffer 中搜索与当前近端 block 最匹配的远端 block 位置。
对齐精度直接影响后续线性滤波的性能。AEC3 支持延迟的动态跟踪，
当检测到延迟变化时会自动调整对齐位置。

**第三阶段：线性自适应滤波**

使用 PBFDAF 算法，将对齐后的远端信号通过自适应滤波器生成回声估计 :math:`\hat{d}(n)`，
然后从近端信号中减去：

.. math::

   e_{linear}(n) = y(n) - \hat{d}(n)

这一步可以消除大部分线性回声，典型的线性回声消除量为 20~30 dB。

**第四阶段：双讲检测与滤波器控制**

基于信号相干性和能量比判断当前是否处于双讲状态。
如果检测到双讲，则冻结或减慢自适应滤波器的系数更新，保护滤波器不发散。

**第五阶段：非线性处理与残余回声抑制**

对线性滤波后的残余回声进行估计，计算频域抑制增益 :math:`G(k)`，
对每个频点施加不同的抑制量。这一步可以额外提供 10~30 dB 的回声抑制。

**第六阶段：舒适噪声注入**

在回声被大幅抑制的频段注入与背景噪声统计特性匹配的舒适噪声，
避免出现不自然的"死寂"感。

**第七阶段：输出**

将处理后的频域信号通过 IFFT 变换回时域，使用重叠相加（overlap-add）方法
合成连续的输出信号。

AEC3 处理时序
-----------------------

在 WebRTC 的音频处理管线中，AEC3 的调用时序如下：

.. code-block:: text

   时间轴 →
   ─────────────────────────────────────────────────────────
   远端:  AnalyzeRender(block_0)  AnalyzeRender(block_1)  ...
   近端:       AnalyzeCapture(block_0)  ProcessCapture(block_0)  ...
   ─────────────────────────────────────────────────────────

注意事项：

* ``AnalyzeRender()`` 和 ``ProcessCapture()`` 可能在不同的线程中调用
* AEC3 内部使用锁（mutex）保护共享数据
* 远端信号必须在近端信号之前或同时到达，否则会导致延迟估计问题

多通道 AEC
-----------------------

在立体声或多通道场景下，AEC 面临额外的挑战：

* 每个通道需要独立的自适应滤波器
* 通道间的相关性可能导致滤波器不唯一性问题（non-uniqueness problem）
* WebRTC AEC3 支持多通道处理，通过 ``num_render_channels`` 和 ``num_capture_channels`` 配置


Glossary
========================
* near end 近端
* far end 远端
* ERLE (Echo Return Loss Enhancement) 回声回损增强
* ERL (Echo Return Loss) 回声回损
* DTD (Double-Talk Detection) 双讲检测
* NLP (Non-Linear Processing) 非线性处理
* CNG (Comfort Noise Generator) 舒适噪声生成器


Methods
========================

AECM
------------------------

Input processing
~~~~~~~~~~~~~~~~~~~~~~~~
* Hanning window
* FFT

Echo Delay Estimation
~~~~~~~~~~~~~~~~~~~~~~~~~
* VAD
* Align Far Near End

Adaptive Filter
~~~~~~~~~~~~~~~~~~~~~~~~~
NLMS - Normalized Least-Mean-Squares


Non-linear processing
~~~~~~~~~~~~~~~~~~~~~~~~~~
Wiener Filter

Comfort Noise
~~~~~~~~~~~~~~~~~~~~~~~~~~
CNG generate

Output result
~~~~~~~~~~~~~~~~~~~~~~~~~~
IFFT


常见问题与调试
========================

回声未完全消除
-----------------------

**现象**：远端说话者仍能听到自己的回声。

**可能原因与解决方案**：

* **延迟估计不准确**：检查系统延迟报告是否正确，尝试增大延迟搜索范围
* **滤波器长度不足**：增大 ``main_length_blocks``，确保覆盖完整的回声路径
* **非线性回声**：扬声器在大音量下产生非线性失真，降低播放音量或增强 NLP
* **回声路径变化**：有人移动或环境变化导致回声路径改变，滤波器需要重新收敛

啸叫 / 反馈 (Howling / Feedback)
----------------------------------------------

**现象**：通话中出现持续的高频尖叫声，音量越来越大。

**原因**：回声消除失败，形成正反馈环路：

::

  扬声器播放 → 麦克风采集 → 网络传输 → 远端扬声器播放 → 远端麦克风采集 → ... (循环放大)

**解决方案**：

* 确保 AEC 正确启用且工作正常
* 降低扬声器音量或增大扬声器与麦克风的距离
* 启用增益限制（AGC limiter）防止信号无限放大
* 在检测到啸叫时临时静音

双讲时语音削波 (Speech Clipping during Double-Talk)
------------------------------------------------------

**现象**：双方同时说话时，近端语音被部分或完全消除。

**原因**：双讲检测失败，AEC 将近端语音误判为回声并消除。

**解决方案**：

* 调整双讲检测的灵敏度
* 使用更保守的滤波器更新策略
* AEC3 的双滤波器结构在一定程度上缓解了此问题

回声路径突变
-----------------------

**现象**：通话中突然出现回声，然后逐渐消失。

**原因**：有人移动、开关门窗等导致回声路径突然改变，滤波器需要重新收敛。

**解决方案**：

* AEC3 的影子滤波器可以快速跟踪回声路径变化
* 增大影子滤波器的步长以加快重新收敛

CPU 占用过高
-----------------------

**现象**：启用 AEC 后 CPU 占用显著增加，导致音频处理不及时、卡顿或丢帧。

**可能原因与解决方案**：

* **滤波器长度过长**：减小 ``main_length_blocks`` 和 ``shadow_length_blocks``，
  在回声路径较短的场景下（如手持设备）不需要很长的滤波器
* **采样率过高**：48kHz 的计算量是 16kHz 的 3 倍，在低端设备上考虑降低采样率
* **多通道处理**：立体声比单声道计算量翻倍，评估是否真正需要多通道 AEC
* **移动设备**：考虑使用 AECM（``mobile_mode = true``），计算复杂度显著低于 AEC3
* **硬件加速**：部分平台支持硬件 AEC（如 Android 的 ``JAVA_AECM``），可以卸载 CPU 负担
* **Profile 分析**：使用 WebRTC 内置的 ``AudioProcessingStats`` 监控处理时间

.. code-block:: cpp

   // 获取 AEC 处理统计信息
   AudioProcessingStats stats = apm->GetStatistics();
   // stats.echo_return_loss
   // stats.echo_return_loss_enhancement
   // stats.delay_ms


性能指标
========================

评估 AEC 性能的关键指标：

* **ERLE** (Echo Return Loss Enhancement)：回声抑制量，单位 dB

  .. math::

     \text{ERLE} = 10 \log_{10} \frac{E[y^2(n)]}{E[e^2(n)]}

  典型值：AEC3 可达 40~60 dB ERLE

* **ERL** (Echo Return Loss)：回声回损，衡量声学耦合程度

  .. math::

     \text{ERL} = 10 \log_{10} \frac{E[x^2(n)]}{E[d^2(n)]}

* **PESQ/POLQA**：语音质量评估，衡量近端语音的失真程度

* **收敛时间**：滤波器从初始状态收敛到稳态所需的时间，AEC3 通常在 1~3 秒内收敛


* specfic double-talk Detector

* auditory masking

* power coherence

* subband processing


参考资料
=====================

书籍与论文
-----------------------

* Haykin, S. (2014). "Adaptive Filter Theory." 5th Edition, Prentice Hall.
  — 自适应滤波器领域的经典教材，涵盖 LMS、RLS、卡尔曼滤波等算法的完整理论推导
* Haykin, S. (2001). "Adaptive Filter Theory." 4th Edition, Prentice Hall.
  — 第四版同样经典，包含详细的收敛性分析和性能分析
* Benesty, J., et al. (2001). "Advances in Network and Acoustic Echo Cancellation." Springer.
  — 网络和声学回声消除的进阶内容
* Benesty, J., Huang, Y. (2003). "Adaptive Signal Processing: Applications to Real-World Problems." Springer.
* Enzner, G., et al. (2014). "Acoustic Echo Control." in "Academic Press Library in Signal Processing."
* Sondhi, M.M. (1967). "An adaptive echo canceller." Bell System Technical Journal, 46(3), 497-511.
  — 自适应回声消除的开创性论文
* Widrow, B., Hoff, M.E. (1960). "Adaptive switching circuits." IRE WESCON Convention Record, Part 4, 96-104.
  — LMS 算法的原始论文
* Shynk, J.J. (1992). "Frequency-domain and multirate adaptive filtering." IEEE Signal Processing Magazine, 9(1), 14-37.
  — 频域自适应滤波的综述
* Ferrara, E.R. (1980). "Fast implementation of LMS adaptive filters." IEEE Trans. ASSP, 28(4), 474-475.
  — 块 LMS 和频域 LMS 的快速实现

标准
-----------------------

* ITU-T G.168: Digital network echo cancellers — 数字网络回声消除器的国际标准
* ITU-T G.167: Acoustic echo controllers — 声学回声控制器标准
* ITU-T P.340: Transmission characteristics and speech quality parameters of hands-free terminals
* 3GPP TS 26.077: Minimum performance requirements for noise suppresser and echo controller

WebRTC 源码
-----------------------

* WebRTC AEC3 源码: https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/aec3/
* WebRTC AEC3 核心类 ``echo_canceller3.h``: https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/aec3/echo_canceller3.h
* WebRTC AEC3 配置 ``echo_canceller3_config.h``: https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/aec3/echo_canceller3_config.h
* WebRTC AECM 源码: https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/aecm/
* WebRTC APM 配置: https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/include/audio_processing.h
* WebRTC Legacy AEC 源码 (deprecated): https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/aec/

在线资源
-----------------------

* 详解 WebRTC 高音质低延时的背后 — AEC（回声消除）: https://segmentfault.com/a/1190000040072259
* WebRTC 官方文档: https://webrtc.org/
* WebRTC Audio Processing Module 设计文档: https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/
* Chromium WebRTC AEC3 设计文档: https://docs.google.com/document/d/1JwEFaDpCFSBwMDf0EQb-aVMEBtrFEkYdCKBal05xYJA
