######################
video quality
######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Video Quality
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=========

视频质量 (Video Quality) 是衡量视频编码、传输和显示效果的核心指标。
在 WebRTC 实时通信场景中，视频质量受到编码参数、网络条件、终端能力等多种因素的影响。

视频质量评估方法主要分为两大类：

* **主观评估 (Subjective Assessment)**: 由人类观察者对视频质量进行评分，结果通常以 MOS (Mean Opinion Score) 表示
* **客观评估 (Objective Assessment)**: 使用数学模型和算法自动计算视频质量分数，包括全参考 (Full Reference)、半参考 (Reduced Reference) 和无参考 (No Reference) 三种方式

在实际工程中，客观评估方法因其可自动化、可重复的特点而被广泛使用，
但最终的质量标准仍然以人类的主观感受为准。


指标
=========

PSNR (Peak Signal-to-Noise Ratio)
--------------------------------------

PSNR 是最经典、最广泛使用的视频质量客观评估指标。它基于像素级的均方误差 (MSE) 来衡量重建图像与原始图像之间的差异。

**计算公式:**

.. code-block:: text

    MSE = (1 / (M × N)) × Σ Σ [I(i,j) - K(i,j)]²

    PSNR = 10 × log₁₀(MAX² / MSE)  [单位: dB]

其中：

* ``I(i,j)`` 是原始图像在位置 (i,j) 的像素值
* ``K(i,j)`` 是重建图像在位置 (i,j) 的像素值
* ``M × N`` 是图像的尺寸（宽 × 高）
* ``MAX`` 是像素的最大值（8-bit 图像为 255）

**PSNR 值的解读:**

.. list-table:: PSNR 值与主观质量的对应关系
   :header-rows: 1
   :widths: 20 30 50

   * - PSNR (dB)
     - 主观质量
     - 说明
   * - > 40
     - 优秀
     - 几乎无法察觉失真
   * - 35 ~ 40
     - 良好
     - 轻微失真，可接受
   * - 30 ~ 35
     - 一般
     - 可以察觉失真
   * - 25 ~ 30
     - 较差
     - 明显失真
   * - < 25
     - 差
     - 严重失真

**PSNR 的局限性:**

* PSNR 基于像素级误差，不考虑人类视觉系统 (HVS) 的特性
* 相同的 PSNR 值可能对应不同的主观质量（例如，模糊和块效应的 PSNR 可能相同，但主观感受差异很大）
* 对于某些类型的失真（如颜色偏移、结构性失真），PSNR 的评估结果与主观感受不一致
* 不适合跨内容比较（不同视频内容的 PSNR 值不具有可比性）


SSIM (Structural Similarity Index Measure)
----------------------------------------------

SSIM 由 Wang 等人于 2004 年提出，基于人类视觉系统对结构信息敏感的特点，从亮度、对比度和结构三个维度评估图像质量。

**计算公式:**

.. code-block:: text

    SSIM(x, y) = [l(x,y)]^α × [c(x,y)]^β × [s(x,y)]^γ

    其中:
    l(x,y) = (2μₓμᵧ + C₁) / (μₓ² + μᵧ² + C₁)        -- 亮度比较
    c(x,y) = (2σₓσᵧ + C₂) / (σₓ² + σᵧ² + C₂)        -- 对比度比较
    s(x,y) = (σₓᵧ + C₃) / (σₓσᵧ + C₃)                -- 结构比较

    简化形式 (α=β=γ=1, C₃=C₂/2):
    SSIM(x,y) = (2μₓμᵧ + C₁)(2σₓᵧ + C₂) / ((μₓ² + μᵧ² + C₁)(σₓ² + σᵧ² + C₂))

其中：

* ``μₓ``, ``μᵧ`` 分别是 x 和 y 的均值
* ``σₓ``, ``σᵧ`` 分别是 x 和 y 的标准差
* ``σₓᵧ`` 是 x 和 y 的协方差
* ``C₁``, ``C₂`` 是稳定常数，防止分母为零

**SSIM 的特点:**

* 取值范围: [0, 1]，1 表示完全相同
* 通常在滑动窗口（如 11x11 高斯窗口）上计算，然后取平均值得到 MSSIM
* 比 PSNR 更符合人类视觉感知
* 对模糊、块效应、噪声等失真类型有较好的区分能力

**MS-SSIM (Multi-Scale SSIM):**

MS-SSIM 是 SSIM 的多尺度扩展版本，在多个分辨率尺度上计算 SSIM，然后加权组合。
它比单尺度 SSIM 更能反映人类视觉系统的多尺度特性，评估精度更高。


VMAF (Video Multi-Method Assessment Fusion)
-------------------------------------------------

VMAF 是 Netflix 开发的基于机器学习的视频质量评估指标，被认为是目前最准确的客观质量评估方法之一。

**核心原理:**

VMAF 融合了多种基础质量指标，使用支持向量机 (SVM) 回归模型将它们组合为一个综合分数：

* **VIF (Visual Information Fidelity)**: 基于自然场景统计和信息论的质量指标
* **DLM (Detail Loss Metric)**: 衡量细节丢失的程度
* **Motion**: 视频运动特征，用于调整质量评估的权重

.. code-block:: text

    VMAF 计算流程:
    原始视频 ──┐
               ├── VIF 计算 ──┐
    失真视频 ──┤              ├── SVM 回归 ── VMAF 分数 [0-100]
               ├── DLM 计算 ──┤
               └── Motion ────┘

**VMAF 分数解读:**

.. list-table:: VMAF 分数与主观质量
   :header-rows: 1
   :widths: 20 30 50

   * - VMAF 分数
     - 主观质量
     - 说明
   * - > 90
     - 优秀
     - 接近无损质量
   * - 80 ~ 90
     - 良好
     - 高质量，适合大多数场景
   * - 70 ~ 80
     - 一般
     - 可接受质量
   * - 60 ~ 70
     - 较差
     - 质量下降明显
   * - < 60
     - 差
     - 质量不可接受

**VMAF 的优势:**

* 与主观评分 (MOS) 的相关性最高（Pearson 相关系数 > 0.95）
* 考虑了内容特征（运动、纹理等）
* Netflix 在大规模 A/B 测试中验证了其有效性
* 支持 4K、HDR 等高质量内容的评估


MOS (Mean Opinion Score)
------------------------------

MOS 是主观视频质量评估的标准方法，定义在 ITU-T P.800 和 ITU-T P.910 等标准中。

**评分标准:**

.. list-table:: MOS 五级评分
   :header-rows: 1
   :widths: 15 20 65

   * - MOS 值
     - 质量等级
     - 描述
   * - 5
     - Excellent
     - 无法察觉的失真
   * - 4
     - Good
     - 可察觉但不恼人的失真
   * - 3
     - Fair
     - 轻微恼人的失真
   * - 2
     - Poor
     - 恼人的失真
   * - 1
     - Bad
     - 非常恼人的失真

**MOS 测试方法:**

* **ACR (Absolute Category Rating)**: 观察者独立评价每个视频序列
* **DCR (Degradation Category Rating)**: 观察者先看原始视频，再看失真视频，评价失真程度
* **PC (Pair Comparison)**: 观察者比较两个视频，选择质量更好的一个

MOS 测试需要大量的观察者（通常 15-30 人）和严格的测试环境控制，成本较高，
因此在工程实践中通常使用客观指标来近似估计 MOS。


VQM (Video Quality Metric)
-------------------------------

VQM 是 NTIA (美国国家电信和信息管理局) 开发的视频质量评估指标，
被 ITU-T J.144 标准采纳。它从多个维度评估视频质量，包括模糊、块效应、颜色失真等。

VQM 的评估维度包括：

* **空间失真**: 模糊、块效应、振铃效应等
* **时间失真**: 运动不连续、帧率下降等
* **颜色失真**: 色彩偏移、饱和度变化等

VQM 的输出范围为 [0, 1]，0 表示无失真，1 表示最大失真。


视频质量指标对比
---------------------

.. list-table:: 视频质量指标综合对比
   :header-rows: 1
   :widths: 12 12 12 14 14 12 12 12

   * - 指标
     - 类型
     - 范围
     - 与 MOS 相关性
     - 计算复杂度
     - 需要参考
     - 感知一致性
     - 标准化
   * - PSNR
     - 客观/FR
     - 0~∞ dB
     - 中等
     - 低
     - 是
     - 低
     - 广泛使用
   * - SSIM
     - 客观/FR
     - [0, 1]
     - 较高
     - 中
     - 是
     - 较高
     - IEEE
   * - MS-SSIM
     - 客观/FR
     - [0, 1]
     - 高
     - 中高
     - 是
     - 高
     - IEEE
   * - VMAF
     - 客观/FR
     - [0, 100]
     - 最高
     - 高
     - 是
     - 最高
     - Netflix
   * - VQM
     - 客观/FR
     - [0, 1]
     - 高
     - 高
     - 是
     - 高
     - ITU-T J.144
   * - MOS
     - 主观
     - [1, 5]
     - 基准
     - 人工
     - 否
     - 基准
     - ITU-T P.800

.. note::

   FR = Full Reference (全参考)。在实际工程中，VMAF 被认为是与人类主观感受最一致的客观指标，
   但其计算开销较大。对于实时监控场景，PSNR 和 SSIM 因计算简单而更常用。
   在无法获取参考视频的场景（如实时通信的接收端），可以使用无参考指标如 BRISQUE 或 NIQE。


视频质量影响因素
======================

编解码器与编码参数
-----------------------

**编解码器选择:**

不同的编解码器在相同码率下的质量表现差异显著：

.. code-block:: text

    质量排序 (相同码率):
    AV1 > H.265/HEVC > VP9 > H.264/AVC > VP8

**关键编码参数:**

* **码率 (Bitrate)**: 最直接影响质量的参数。码率越高，可用于编码的比特越多，质量越好
* **量化参数 (QP)**: 控制量化步长，QP 越大，量化越粗糙，质量越低
* **编码 Profile**: 更高的 Profile 支持更多编码工具，通常能获得更好的质量
* **编码速度 (Preset/Speed)**: 更慢的编码速度允许编码器进行更充分的率失真优化，质量更好
* **GOP 结构**: I 帧间隔、B 帧数量等影响压缩效率和随机访问能力
* **参考帧数**: 更多的参考帧提供更好的帧间预测，但增加内存和计算开销

.. code-block:: text

    编码参数对质量的影响程度:
    码率 >>> 编解码器选择 > 编码速度 > QP 范围 > GOP 结构 > 参考帧数


分辨率与帧率
-----------------

分辨率和帧率是影响视频质量感知的重要因素：

* **分辨率**: 更高的分辨率提供更多的细节，但在码率受限时，过高的分辨率反而会降低质量（因为每个像素分配到的比特更少）
* **帧率**: 更高的帧率提供更流畅的运动，但同样会增加码率需求
* **分辨率-码率匹配**: 在给定码率下，存在一个最优分辨率。Netflix 的 per-title encoding 就是基于这个原理

.. list-table:: 推荐的分辨率-码率匹配 (H.264)
   :header-rows: 1
   :widths: 25 25 25 25

   * - 分辨率
     - 最低码率
     - 推荐码率
     - 帧率
   * - 320x240
     - 200 Kbps
     - 400 Kbps
     - 15-30 fps
   * - 640x480
     - 500 Kbps
     - 1 Mbps
     - 30 fps
   * - 1280x720
     - 1 Mbps
     - 2.5 Mbps
     - 30 fps
   * - 1920x1080
     - 2 Mbps
     - 5 Mbps
     - 30 fps
   * - 3840x2160
     - 8 Mbps
     - 15 Mbps
     - 30 fps


网络条件
-----------

在 WebRTC 实时通信中，网络条件对视频质量有决定性影响：

* **丢包 (Packet Loss)**: 丢包会导致解码错误、花屏、卡顿。即使 1-2% 的丢包率也会显著影响视频质量
* **延迟 (Delay)**: 高延迟影响交互体验，但对视频质量本身影响较小
* **抖动 (Jitter)**: 抖动导致接收端缓冲区波动，可能引起卡顿
* **带宽波动**: 带宽突然下降时，如果码率控制不及时，会导致严重的质量下降

.. code-block:: text

    网络条件对视频质量的影响:
    ┌──────────────┬──────────────────────────────────┐
    │ 丢包率        │ 影响                              │
    ├──────────────┼──────────────────────────────────┤
    │ 0%           │ 无影响                            │
    │ 0.1% ~ 1%   │ 偶尔出现轻微马赛克                  │
    │ 1% ~ 3%     │ 明显的马赛克和花屏                   │
    │ 3% ~ 5%     │ 频繁花屏，需要 PLI/FIR 请求关键帧    │
    │ > 5%         │ 视频基本不可用                      │
    └──────────────┴──────────────────────────────────┘


编码器复杂度与质量权衡
---------------------------

在实时通信场景中，编码器必须在质量和延迟之间做出权衡：

* **更高的编码复杂度** → 更好的率失真优化 → 更高的质量，但编码延迟增加
* **更低的编码复杂度** → 更快的编码速度 → 更低的延迟，但质量下降

WebRTC 中的编码器通常使用最快的编码速度设置：

.. code-block:: text

    编码器速度设置:
    H.264:  ultrafast / superfast (x264)
    VP8:    speed 12-16 (libvpx)
    VP9:    speed 6-9 (libvpx)
    AV1:    speed 8-10 (libaom)

**终端能力:**

终端设备的硬件能力也会影响视频质量：

* **CPU/GPU 性能**: 决定了可以使用的编码复杂度和分辨率上限
* **硬件编码器**: 硬件编码器（如 Intel QSV, NVIDIA NVENC, Apple VideoToolbox）通常比软件编码器更快，但在相同码率下质量可能略低
* **摄像头质量**: 摄像头的传感器质量、镜头质量、自动曝光/白平衡等直接影响采集到的原始视频质量
* **显示器分辨率**: 在高分辨率显示器上，低分辨率视频的质量缺陷更容易被察觉


码率控制
==========

在在线视频应用中，卡顿和花屏是最常见的两个问题，多数原因是由于网络的不稳定。
除了应用一些丢包补偿和恢复技术（例如 FEC, RTX, NACK, PLI 等）以及调整接收缓冲区 (Adjust Jitter Buffer)，
我们还可以对视频编码进行一些码率控制，这对视频质量或许有些影响，但利大于弊。

码率控制模式
-----------------

**CBR (Constant Bitrate) - 恒定码率:**

* 输出码率保持恒定（或在很小的范围内波动）
* 优点: 带宽使用可预测，适合网络传输
* 缺点: 简单场景浪费码率，复杂场景质量不足
* 适用场景: 实时通信 (WebRTC)、直播

**VBR (Variable Bitrate) - 可变码率:**

* 根据内容复杂度动态调整码率
* 优点: 质量更均匀，压缩效率更高
* 缺点: 码率波动大，可能导致网络拥塞
* 适用场景: 视频点播 (VOD)、离线编码

**CRF (Constant Rate Factor) - 恒定质量:**

* 保持恒定的视觉质量，码率随内容复杂度变化
* 优点: 质量最均匀
* 缺点: 码率不可预测，不适合实时传输
* 适用场景: 离线编码、存档

.. code-block:: text

    码率控制模式对比:
    ┌──────┬──────────┬──────────┬──────────────┐
    │ 模式  │ 码率稳定性 │ 质量稳定性 │ 适用场景      │
    ├──────┼──────────┼──────────┼──────────────┤
    │ CBR  │ 高        │ 低        │ 实时通信/直播  │
    │ VBR  │ 中        │ 中        │ VOD          │
    │ CRF  │ 低        │ 高        │ 离线编码      │
    └──────┴──────────┴──────────┴──────────────┘


经典码率控制算法
---------------------

经典的码率控制算法有：

* **MPEG-2 使用的 TM5**: 基于虚拟缓冲区模型，使用线性 R-Q 模型
* **H.263 使用的 TMN8**: 改进的码率控制，引入了帧级和宏块级的码率分配
* **MPEG-4 使用的 VM8**: 基于二次 R-Q 模型
* **H.264 使用的 JVT-G012**: 由 Li 等人提出的二次 R-D 模型，被广泛采用

H.264 码率控制的核心是 R-Q 模型：

.. code-block:: text

    R = c₁ × Q⁻¹ + c₂ × Q⁻²

    其中:
    R = 编码码率
    Q = 量化步长
    c₁, c₂ = 模型参数 (通过编码历史数据拟合)


WebRTC 中的码率控制
--------------------------

**VP8/VP9 码率控制 (libvpx):**

WebRTC 中的 VP8/VP9 编码器使用 libvpx 库，其码率控制主要通过以下类实现：

* ``LibvpxVp8Encoder``: VP8 编码器封装
* ``LibvpxVp9Encoder``: VP9 编码器封装

关键码率控制参数：

.. code-block:: cpp

    // WebRTC 中 libvpx 码率控制配置
    vpx_codec_enc_cfg_t cfg;

    // 目标码率
    cfg.rc_target_bitrate = target_bitrate_kbps;

    // 码率控制模式: CBR
    cfg.rc_end_usage = VPX_CBR;

    // 缓冲区设置
    cfg.rc_buf_initial_sz = 500;   // 初始缓冲区大小 (ms)
    cfg.rc_buf_optimal_sz = 600;   // 最优缓冲区大小 (ms)
    cfg.rc_buf_sz = 1000;          // 最大缓冲区大小 (ms)

    // 码率波动范围
    cfg.rc_undershoot_pct = 100;   // 允许低于目标码率的百分比
    cfg.rc_overshoot_pct = 15;     // 允许高于目标码率的百分比

    // QP 范围
    cfg.rc_min_quantizer = 2;      // 最小 QP
    cfg.rc_max_quantizer = 56;     // 最大 QP (VP8/VP9 QP 范围: 0-63)

**目标码率、最大码率和最小码率:**

在 WebRTC 中，码率控制涉及三个关键码率值：

* **Target Bitrate (目标码率)**: 编码器尝试达到的码率，由带宽估计模块 (BWE) 动态调整
* **Max Bitrate (最大码率)**: 编码器输出码率的上限，防止突发大帧导致网络拥塞
* **Min Bitrate (最小码率)**: 编码器输出码率的下限，保证最低可接受的视频质量

.. code-block:: text

    WebRTC 码率控制层次:
    ┌─────────────────────────────────────────────┐
    │ 带宽估计 (BWE: GCC/REMB/Transport-CC)        │
    │     ↓ 估计可用带宽                            │
    │ 码率分配 (BitrateAllocator)                   │
    │     ↓ 分配给各个媒体流                         │
    │ 编码器码率控制 (Encoder Rate Control)           │
    │     ↓ 控制每帧的编码质量                       │
    │ 输出码流                                      │
    └─────────────────────────────────────────────┘


缓冲区模型 (HRD/VBV)
--------------------------

HRD (Hypothetical Reference Decoder) 和 VBV (Video Buffering Verifier) 是视频编码标准中定义的缓冲区模型，
用于约束编码器的输出码率，确保解码器能够正常工作。

.. code-block:: text

    VBV 缓冲区模型:
                    ┌──────────────┐
    编码码流 ──────→│  VBV Buffer  │──────→ 解码器
    (可变码率)       │  (固定大小)   │      (恒定速率取出)
                    └──────────────┘

    约束条件:
    1. 缓冲区不能溢出 (overflow): 编码器不能产生过多数据
    2. 缓冲区不能下溢 (underflow): 编码器必须产生足够的数据

在 WebRTC 中，VBV 缓冲区的大小通常设置得较小（几百毫秒），以保证低延迟：

* 较大的缓冲区: 允许更大的码率波动，质量更好，但延迟更高
* 较小的缓冲区: 码率更平稳，延迟更低，但质量波动更大


WebRTC 视频质量优化
========================

QualityScaler
-----------------

WebRTC 中的 ``QualityScaler`` 类负责根据编码质量自动调整视频分辨率：

* **工作原理**: 监控编码器输出的 QP 值，当 QP 持续偏高时（表示质量不足），降低输入分辨率；当 QP 持续偏低时（表示有余量），提高分辨率
* **QP 阈值**: 不同编解码器有不同的 QP 阈值

.. code-block:: cpp

    // QualityScaler 的关键逻辑 (简化)
    class QualityScaler {
    public:
      void ReportQP(int qp) {
        // 更新 QP 统计
        average_qp_.AddSample(qp);

        if (average_qp_ > high_qp_threshold_) {
          // QP 过高，请求降低分辨率
          AdaptDown();
        } else if (average_qp_ < low_qp_threshold_) {
          // QP 过低，请求提高分辨率
          AdaptUp();
        }
      }
    };

    // 不同编解码器的 QP 阈值
    // VP8:  low=24, high=37  (QP 范围 0-127)
    // VP9:  low=29, high=95  (QP 范围 0-255)
    // H264: low=24, high=37  (QP 范围 0-51)

**QP 与质量的关系:**

QP (Quantization Parameter) 直接控制量化精度，是影响视频质量的最底层参数：

.. code-block:: text

    QP 值与质量的关系 (以 H.264 为例, QP 范围 0-51):
    ┌──────────┬──────────────────────────────────────┐
    │ QP 范围   │ 质量描述                              │
    ├──────────┼──────────────────────────────────────┤
    │ 0 ~ 15   │ 接近无损，码率非常高                    │
    │ 15 ~ 25  │ 高质量，适合高码率场景                   │
    │ 25 ~ 35  │ 中等质量，WebRTC 常见工作范围            │
    │ 35 ~ 45  │ 低质量，明显的块效应和模糊               │
    │ 45 ~ 51  │ 极低质量，严重失真                      │
    └──────────┴──────────────────────────────────────┘

    QP 每增加 6，量化步长翻倍，码率大约减半。

**qualityLimitationReason 统计:**

WebRTC 的 ``RTCOutboundRtpStreamStats`` 提供了 ``qualityLimitationReason`` 字段，
用于指示当前视频质量受限的原因：

.. code-block:: javascript

    // 获取 qualityLimitationReason
    const stats = await sender.getStats();
    stats.forEach(report => {
      if (report.type === 'outbound-rtp' && report.kind === 'video') {
        console.log('Quality limitation reason:', report.qualityLimitationReason);
        // 可能的值: "none", "cpu", "bandwidth", "other"

        console.log('Quality limitation durations:', report.qualityLimitationDurations);
        // 各原因累计持续时间 (ms)

        console.log('Quality limitation resolution changes:',
                     report.qualityLimitationResolutionChanges);
        // 因质量限制导致的分辨率变化次数
      }
    });


带宽自适应 (Bandwidth Adaptation)
--------------------------------------

当网络带宽不足时，WebRTC 会自动降低视频质量以适应网络条件。自适应策略包括：

**1. 分辨率降低 (Resolution Reduction):**

* 通过 ``VideoAdapter`` 类实现
* 按比例缩小视频分辨率（如 1/2, 1/4, 3/4 等）
* 分辨率降低对质量的影响最大，但码率节省也最显著

**2. 帧率降低 (Framerate Reduction):**

* 通过丢弃部分帧来降低帧率
* 帧率从 30fps 降到 15fps 可以节省约 40-50% 的码率
* 对运动流畅性有影响，但对静态画面质量影响较小

**3. 自适应策略优先级:**

.. code-block:: text

    WebRTC 默认的自适应策略:
    1. 首先降低帧率 (maintain-resolution 模式)
    2. 然后降低分辨率
    3. 或者同时降低帧率和分辨率 (balanced 模式)

    可通过 degradationPreference 配置:
    - "maintain-framerate": 优先保持帧率，降低分辨率
    - "maintain-resolution": 优先保持分辨率，降低帧率
    - "balanced": 平衡降低帧率和分辨率

.. code-block:: javascript

    // JavaScript 中设置 degradationPreference
    const sender = pc.addTrack(videoTrack, stream);
    const params = sender.getParameters();
    params.degradationPreference = 'balanced';
    await sender.setParameters(params);


时域层丢弃 (Temporal Layer Dropping)
-----------------------------------------

在使用 SVC (Scalable Video Coding) 时，WebRTC 可以通过丢弃高时域层来降低码率：

.. code-block:: text

    时域层结构 (3 层):
    T0: [I]─────────────────[P]─────────────────[P]
    T1:          [P]                   [P]
    T2:    [P]         [P]       [P]         [P]

    帧率:
    T0 only:     7.5 fps  (基础层)
    T0 + T1:    15 fps
    T0 + T1 + T2: 30 fps  (完整帧率)

SFU 可以根据接收端的带宽条件，选择性地转发不同的时域层。


内容自适应编码 (Content-Adaptive Encoding)
-----------------------------------------------

根据视频内容的特征动态调整编码参数：

* **运动检测**: 高运动场景分配更多码率，低运动场景降低码率
* **场景切换检测**: 检测到场景切换时插入关键帧
* **ROI (Region of Interest) 编码**: 对感兴趣区域（如人脸）分配更多码率
* **屏幕内容检测**: 检测到屏幕共享内容时，切换到屏幕内容编码模式（更高的 QP 容忍度，更注重清晰度）

.. code-block:: cpp

    // WebRTC 中的内容类型检测
    enum class VideoContentType : uint8_t {
      UNSPECIFIED = 0,
      SCREENSHARE = 1,  // 屏幕共享内容
    };


视频质量测试工具
======================

FFmpeg
---------

FFmpeg 是最常用的视频处理工具，支持 PSNR 和 SSIM 的计算：

**计算 PSNR:**

.. code-block:: bash

    # 计算两个视频之间的 PSNR
    ffmpeg -i distorted.mp4 -i reference.mp4 \
           -lavfi psnr=stats_file=psnr.log \
           -f null -

    # 输出示例:
    # [Parsed_psnr_0 @ 0x...] PSNR y:38.52 u:43.17 v:44.21 average:39.68 min:32.15 max:48.92

**计算 SSIM:**

.. code-block:: bash

    # 计算两个视频之间的 SSIM
    ffmpeg -i distorted.mp4 -i reference.mp4 \
           -lavfi ssim=stats_file=ssim.log \
           -f null -

    # 输出示例:
    # [Parsed_ssim_0 @ 0x...] SSIM Y:0.952 U:0.978 V:0.981 All:0.960 (13.98)

**同时计算 PSNR 和 SSIM:**

.. code-block:: bash

    ffmpeg -i distorted.mp4 -i reference.mp4 \
           -lavfi "[0:v][1:v]psnr=stats_file=psnr.log;[0:v][1:v]ssim=stats_file=ssim.log" \
           -f null -


VMAF 工具
-----------

Netflix 开源了 VMAF 计算工具：

.. code-block:: bash

    # 安装 VMAF
    pip install vmaf

    # 使用 FFmpeg + libvmaf 计算 VMAF
    ffmpeg -i distorted.mp4 -i reference.mp4 \
           -lavfi libvmaf=model_path=/path/to/vmaf_v0.6.1.json:log_path=vmaf.json:log_fmt=json \
           -f null -

    # 使用 vmaf 命令行工具
    vmaf -r reference.y4m -d distorted.y4m \
         -w 1920 -h 1080 -p 420 -b 8 \
         --model version=vmaf_v0.6.1 \
         -o vmaf_output.json

**VMAF 输出示例:**

.. code-block:: json

    {
      "VMAF score": 82.45,
      "VMAF bagging score": 81.92,
      "PSNR": 38.52,
      "SSIM": 0.952,
      "MS-SSIM": 0.968
    }


WebRTC Internals
--------------------

Chrome 浏览器内置了 WebRTC 调试工具：

* 在 Chrome 地址栏输入 ``chrome://webrtc-internals``
* 可以查看实时的视频编码统计信息：

  - 编码码率 (Encode bitrate)
  - 编码帧率 (Frames encoded per second)
  - QP 值 (Quantization Parameter)
  - 分辨率变化 (Resolution changes)
  - 质量限制原因 (qualityLimitationReason: bandwidth / cpu / other)

.. code-block:: text

    chrome://webrtc-internals 关键视频质量指标:
    ┌─────────────────────────────────────────────┐
    │ [outbound-rtp]                               │
    │   frameWidth: 1280                           │
    │   frameHeight: 720                           │
    │   framesPerSecond: 30                        │
    │   framesEncoded: 1800                        │
    │   qualityLimitationReason: "none"            │
    │   qualityLimitationDurations:                │
    │     bandwidth: 0, cpu: 0, none: 60000, other:0│
    │   encoderImplementation: "libvpx"            │
    │   totalEncodeTime: 45.2                      │
    └─────────────────────────────────────────────┘


测试序列与测试模式
-----------------------

视频质量测试需要标准化的测试序列和测试模式：

**标准测试序列:**

.. list-table:: 常用视频测试序列
   :header-rows: 1
   :widths: 20 15 15 50

   * - 序列名称
     - 分辨率
     - 特点
     - 适用测试场景
   * - Foreman
     - CIF/QCIF
     - 人脸、中等运动
     - 视频会议场景
   * - Akiyo
     - CIF
     - 低运动、简单背景
     - 低码率编码测试
   * - Football
     - SIF
     - 高运动、复杂纹理
     - 运动场景编码测试
   * - City
     - 720p/1080p
     - 城市景观、丰富细节
     - 高分辨率编码测试
   * - Crowd Run
     - 1080p
     - 极高运动、复杂场景
     - 编码器压力测试
   * - Netflix Chimera
     - 4K
     - 多场景混合
     - VMAF 校准测试

**测试模式 (Test Patterns):**

.. code-block:: bash

    # 使用 FFmpeg 生成测试模式
    # 彩条测试图
    ffmpeg -f lavfi -i testsrc=duration=10:size=1920x1080:rate=30 \
           -c:v libx264 -pix_fmt yuv420p test_pattern.mp4

    # 纯色渐变
    ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=10,format=yuv420p" \
           -c:v libx264 output.mp4

    # SMPTE 彩条
    ffmpeg -f lavfi -i smptebars=duration=10:size=1920x1080:rate=30 \
           -c:v libx264 -pix_fmt yuv420p smpte_bars.mp4


其他工具
-----------

* **Elecard StreamEye**: 可视化分析视频码流结构（帧类型、QP 分布、运动矢量等）
* **YUView**: 开源的 YUV 视频查看和分析工具
* **VQProbe**: 视频质量探测工具
* **Testbed**: WebRTC 测试框架，支持自动化的视频质量测试
* **BRISQUE**: 无参考图像质量评估算法，适用于无法获取原始视频的场景
* **WebRTC Test Framework**: Google 提供的 WebRTC 端到端测试框架，支持视频质量自动化测试

**自动化视频质量测试流程:**

.. code-block:: text

    自动化视频质量测试流程:
    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ 输入参考  │───→│ WebRTC   │───→│ 录制输出  │───→│ 质量评估  │
    │ 视频序列  │    │ 编码传输  │    │ 视频序列  │    │ PSNR/SSIM │
    └──────────┘    └──────────┘    └──────────┘    │ /VMAF    │
                                                     └──────────┘
    关键步骤:
    1. 准备标准测试序列 (YUV/Y4M 格式)
    2. 通过 WebRTC 管道进行编码和传输
    3. 在接收端录制解码后的视频
    4. 对齐参考视频和输出视频 (时间同步)
    5. 使用 FFmpeg/VMAF 工具计算质量指标
    6. 生成质量报告和 R-D 曲线


Reference
================
* ITU-T P.910: Subjective video quality assessment methods for multimedia applications
* ITU-T J.144: Objective perceptual video quality measurement techniques for digital cable television
* PSNR: https://en.wikipedia.org/wiki/Peak_signal-to-noise_ratio
* SSIM: https://en.wikipedia.org/wiki/Structural_similarity
* VMAF: https://github.com/Netflix/vmaf
* Netflix Tech Blog - VMAF: https://netflixtechblog.com/toward-a-practical-perceptual-video-quality-metric-653f208b9652
* WebRTC QualityScaler: https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/modules/video_coding/utility/quality_scaler.h
* FFmpeg Filters Documentation: https://ffmpeg.org/ffmpeg-filters.html
* x264 Rate Control: https://www.cnblogs.com/wainiwann/p/7477794.html
