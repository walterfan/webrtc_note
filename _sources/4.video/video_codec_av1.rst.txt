###############
视频编码 AV1
###############

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Video Codec AV1
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=========

AOMedia Video 1 (AV1) 是一种开放的、免版税的视频编码格式，最初设计用于互联网上的视频传输。
它由开放媒体联盟 (Alliance for Open Media, AOMedia) 开发，作为 VP9 的继任者。

AV1 的设计目标是在保持合理编码复杂度的前提下，实现比 H.265/HEVC 和 VP9 更高的压缩效率。
由于其免版税的特性，AV1 在 WebRTC、流媒体和视频点播等领域获得了广泛的关注和采用。

AV1 的主要特点包括：

* **开放免版税**: 无需支付专利许可费用，降低了部署成本
* **高压缩效率**: 相比 VP9 提升约 30% 的压缩效率，相比 H.264 提升约 50%
* **丰富的编码工具**: 提供了大量先进的编码工具，包括超级块结构、多种预测模式、先进的变换和滤波技术
* **可扩展性**: 支持 SVC (Scalable Video Coding)，适合 WebRTC 等实时通信场景
* **广泛的行业支持**: 主要浏览器、硬件厂商和内容提供商均已支持


历史与发展
===============

VP9 到 AV1 的演进
---------------------

AV1 的发展历程可以追溯到多个视频编码项目的融合：

* **Google VP10**: Google 在 VP9 基础上开发的下一代编解码器
* **Cisco Thor**: Cisco 开发的开源视频编解码器
* **Mozilla Daala**: Mozilla 开发的实验性视频编解码器

2015 年，这三个项目的技术被整合到 AV1 项目中，由新成立的 AOMedia 联盟统一推进。

AOMedia 联盟
---------------------

Alliance for Open Media (AOMedia) 成立于 2015 年 9 月 1 日，创始成员包括七家行业巨头：

* **Amazon**: 全球最大的云服务和电商平台
* **Cisco**: 网络设备和视频会议领域的领导者
* **Google**: Chrome 浏览器、YouTube 和 WebRTC 的主要推动者
* **Intel**: 全球最大的半导体芯片制造商
* **Microsoft**: Windows、Edge 浏览器和 Teams 的开发者
* **Mozilla**: Firefox 浏览器的开发者
* **Netflix**: 全球最大的流媒体视频服务提供商

此后，Apple、Facebook (Meta)、NVIDIA、ARM、Samsung 等公司也相继加入。
截至目前，AOMedia 已拥有超过 40 家成员公司，涵盖了半导体、软件、内容和服务等多个领域。

AV1 的发展时间线：

* **2015 年 9 月**: AOMedia 成立
* **2016 年 4 月**: AV1 bitstream 格式初步确定
* **2018 年 3 月**: AV1 bitstream 规范冻结 (v1.0)
* **2018 年 6 月**: AV1 规范正式发布
* **2019 年**: libaom 编码器性能持续优化
* **2020 年**: 主要浏览器开始支持 AV1 解码
* **2021 年**: 硬件 AV1 解码器开始出现在消费级设备中
* **2022 年**: 硬件 AV1 编码器开始普及
* **2023-2024 年**: WebRTC 中 AV1 支持逐步成熟


AV1 技术特性
==================

超级块结构 (Superblock)
----------------------------

AV1 引入了灵活的超级块 (Superblock) 划分结构，这是其高效压缩的基础之一。

* **最大超级块尺寸**: 128x128 像素（VP9 为 64x64）
* **最小编码块尺寸**: 4x4 像素
* **递归四叉树划分**: 超级块可以递归地划分为更小的块

AV1 的块划分方式比 VP9 和 H.265 更加灵活：

.. code-block:: text

    128x128 Superblock
    ├── 不划分 (128x128)
    ├── 四叉树划分 (4 个 64x64)
    ├── 水平二叉树划分 (2 个 128x64)
    ├── 垂直二叉树划分 (2 个 64x128)
    ├── 水平三叉树划分 (128x32 + 128x64 + 128x32)
    └── 垂直三叉树划分 (32x128 + 64x128 + 32x128)

这种灵活的划分方式使得编码器能够更好地适应图像中不同区域的特征：

* 平坦区域使用较大的块，减少编码开销
* 纹理丰富或边缘区域使用较小的块，保留更多细节
* 非正方形划分（如水平/垂直二叉树和三叉树）能更好地匹配图像中的线性结构


预测模式 (Prediction Modes)
---------------------------------

**帧内预测 (Intra Prediction)**

AV1 大幅扩展了帧内预测模式的数量和种类：

* **方向性预测模式**: AV1 支持多达 56 种方向性预测角度（VP9 仅支持 10 种），角度范围从 45° 到 203°，步长约为 3°
* **非方向性模式**: 包括 DC 预测、Smooth 预测、Smooth-V 预测、Smooth-H 预测和 Paeth 预测
* **色度从亮度预测 (CfL, Chroma from Luma)**: 利用亮度分量的信息来预测色度分量，对于色度信号与亮度信号高度相关的区域非常有效
* **递归帧内预测**: 将块划分为更小的子块，逐步进行预测，提高预测精度

.. code-block:: text

    帧内预测模式总览:
    ┌─────────────────────────────────────────┐
    │ 方向性模式: 56 种角度 (45° ~ 203°)       │
    │ DC 模式: 使用邻近像素的平均值              │
    │ Smooth 模式: 双线性插值                   │
    │ Smooth-V: 垂直方向平滑                    │
    │ Smooth-H: 水平方向平滑                    │
    │ Paeth 模式: 选择最接近的邻近像素            │
    │ CfL: 色度从亮度预测                       │
    └─────────────────────────────────────────┘

**帧间预测 (Inter Prediction)**

AV1 的帧间预测引入了多项创新：

* **复合预测 (Compound Prediction)**: 使用两个参考帧的加权组合进行预测，支持多种加权方式：

  - 距离加权 (Distance-weighted): 根据参考帧的时间距离分配权重
  - 差异加权 (Difference-weighted): 根据预测值的差异自适应分配权重
  - 楔形复合 (Wedge compound): 使用楔形掩码将两个预测值组合
  - 段间复合 (Inter-intra compound): 将帧间预测和帧内预测组合

* **运动矢量预测**: 支持多达 7 个参考帧（VP9 为 3 个），提供更丰富的运动补偿选择
* **仿射运动模型 (Affine Motion)**: 除了传统的平移运动模型外，还支持旋转、缩放等仿射变换
* **Warped Motion**: 支持局部运动补偿，能更好地处理非刚体运动
* **OBMC (Overlapped Block Motion Compensation)**: 重叠块运动补偿，减少块效应


变换编码 (Transform)
--------------------------

AV1 提供了丰富的变换类型和灵活的变换尺寸：

**变换类型:**

* **DCT (Discrete Cosine Transform)**: 离散余弦变换，适用于平坦区域
* **ADST (Asymmetric Discrete Sine Transform)**: 非对称离散正弦变换，适用于边缘区域
* **Identity Transform**: 恒等变换（即不进行变换），适用于某些特殊纹理
* **Flipadst**: 翻转的 ADST

AV1 支持水平和垂直方向独立选择变换类型，形成二维组合变换。例如，水平方向使用 DCT，垂直方向使用 ADST。

**变换尺寸:**

* 支持从 4x4 到 64x64 的多种变换尺寸
* 支持非正方形变换: 4x8, 8x4, 8x16, 16x8, 16x32, 32x16, 4x16, 16x4, 8x32, 32x8, 16x64, 64x16 等
* 64x64 是 AV1 支持的最大变换尺寸（VP9 最大为 32x32，H.265 最大为 32x32）

.. code-block:: text

    变换尺寸与类型组合:
    ┌──────────┬──────────────────────────────────┐
    │ 尺寸      │ 可用变换类型                       │
    ├──────────┼──────────────────────────────────┤
    │ 4x4      │ DCT, ADST, Flipadst, Identity    │
    │ 8x8      │ DCT, ADST, Flipadst, Identity    │
    │ 16x16    │ DCT, ADST, Flipadst, Identity    │
    │ 32x32    │ DCT, Identity                    │
    │ 64x64    │ DCT                              │
    │ 非正方形  │ 根据尺寸支持不同组合                │
    └──────────┴──────────────────────────────────┘


环路滤波 (In-loop Filters)
-------------------------------

AV1 使用三级环路滤波器来提升重建图像的质量：

**1. 去块效应滤波器 (Deblocking Filter)**

与 H.264/H.265 类似，AV1 在块边界处应用去块效应滤波器，以减少由块划分和量化引起的块效应。
AV1 的去块滤波器支持更灵活的滤波强度控制。

**2. CDEF (Constrained Directional Enhancement Filter)**

CDEF 是 AV1 独有的滤波器，源自 Daala 项目的方向性滤波技术：

* **方向性检测**: 首先检测每个 8x8 块的主要方向（8 个方向之一）
* **方向性滤波**: 沿检测到的方向应用滤波，保留边缘的同时去除噪声
* **约束条件**: 滤波器的输出被约束在一定范围内，防止过度滤波
* **参数**: 每帧可以选择不同的 CDEF 强度参数（主强度和次强度）

.. code-block:: text

    CDEF 处理流程:
    输入重建帧 → 8x8 块方向检测 → 方向性滤波 → 约束裁剪 → 输出

CDEF 对于去除编码噪声（如蚊噪声）特别有效，同时能较好地保留图像的边缘和纹理。

**3. 环路恢复滤波器 (Loop Restoration Filter)**

环路恢复滤波器是 AV1 的最后一级环路滤波，提供两种滤波模式：

* **Wiener Filter**: 维纳滤波器，使用 7-tap 或 5-tap 的可分离对称滤波器，参数在帧级别传输
* **Self-guided Filter**: 自引导滤波器，基于自引导图像滤波算法，能自适应地平滑图像同时保留边缘

每个恢复单元 (Restoration Unit) 可以独立选择使用 Wiener、Self-guided 或不使用滤波。


胶片颗粒合成 (Film Grain Synthesis)
-----------------------------------------

AV1 内置了胶片颗粒合成工具，这是一个非常实用的特性：

* **原理**: 编码器在编码前分析并去除原始视频中的胶片颗粒/噪声，在 bitstream 中传输颗粒参数，解码器在解码后根据参数重新合成颗粒
* **优势**: 胶片颗粒是高频随机信号，直接编码会消耗大量码率。通过合成方式，可以在低码率下保持视觉上的颗粒感
* **参数**: 包括颗粒强度、自相关系数、色度与亮度的相关性等
* **应用场景**: 电影内容、老旧视频修复、艺术风格保持

.. code-block:: text

    胶片颗粒合成流程:
    编码端: 原始帧 → 颗粒分析 → 去颗粒 → 编码 + 颗粒参数
    解码端: 解码帧 → 颗粒合成 → 输出帧（带颗粒效果）


熵编码 (Entropy Coding)
-----------------------------

AV1 使用多符号算术编码 (Multi-symbol Arithmetic Coding)：

* **多符号编码**: 与 VP9 的布尔算术编码不同，AV1 使用多符号算术编码，每次可以编码一个多值符号，而不是逐位编码
* **CDF (Cumulative Distribution Function) 更新**: AV1 使用基于 CDF 的概率模型，并在编码过程中自适应更新
* **效率提升**: 多符号编码减少了编码操作的次数，提高了编码效率和吞吐量
* **帧级 CDF 更新**: 支持在帧级别更新概率模型，适应视频内容的变化


AV1 与其他编解码器对比
===========================

.. list-table:: AV1 vs H.264 vs H.265 vs VP9 对比
   :header-rows: 1
   :widths: 20 20 20 20 20

   * - 特性
     - H.264/AVC
     - H.265/HEVC
     - VP9
     - AV1
   * - 发布年份
     - 2003
     - 2013
     - 2013
     - 2018
   * - 标准组织
     - ITU-T/ISO
     - ITU-T/ISO
     - Google
     - AOMedia
   * - 最大块尺寸
     - 16x16
     - 64x64
     - 64x64
     - 128x128
   * - 帧内预测模式
     - 9 种
     - 35 种
     - 10 种
     - 56+ 种
   * - 最大变换尺寸
     - 8x8
     - 32x32
     - 32x32
     - 64x64
   * - 环路滤波
     - Deblocking
     - Deblocking + SAO
     - Deblocking
     - Deblocking + CDEF + LR
   * - 熵编码
     - CABAC/CAVLC
     - CABAC
     - Boolean AC
     - Multi-symbol AC
   * - 参考帧数
     - 最多 16
     - 最多 16
     - 最多 3
     - 最多 7
   * - 压缩效率 (vs H.264)
     - 基准
     - ~40% 提升
     - ~30% 提升
     - ~50% 提升
   * - 编码复杂度 (vs H.264)
     - 基准
     - ~5-10x
     - ~2-5x
     - ~20-50x
   * - 解码复杂度 (vs H.264)
     - 基准
     - ~1.5-2x
     - ~1.5x
     - ~2-3x
   * - 专利许可
     - 需要 (MPEG LA)
     - 需要 (MPEG LA + 其他)
     - 免费
     - 免费
   * - 硬件支持
     - 广泛
     - 广泛
     - 较广泛
     - 逐步普及


AV1 在 WebRTC 中的应用
===========================

SDP 协商
-----------

在 WebRTC 中，AV1 通过 SDP (Session Description Protocol) 进行编解码器协商。
AV1 的 RTP payload type 通常为动态分配，常见的 SDP 描述如下：

.. code-block:: text

    m=video 9 UDP/TLS/RTP/SAVPF 35 96 97
    a=rtpmap:35 AV1/90000
    a=rtcp-fb:35 ccm fir
    a=rtcp-fb:35 nack
    a=rtcp-fb:35 nack pli
    a=rtcp-fb:35 goog-remb
    a=rtcp-fb:35 transport-cc
    a=fmtp:35 profile=0;level-idx=5

SDP 中的关键参数说明：

* ``AV1/90000``: 编解码器名称和时钟频率（90kHz）
* ``profile=0``: AV1 编码 profile（0 = Main profile）
* ``level-idx``: AV1 level 索引
* ``rtcp-fb``: RTCP 反馈机制，包括 FIR、NACK、PLI、REMB、Transport-CC 等


libaom 编码器/解码器
-----------------------

libaom 是 AV1 的参考实现，由 AOMedia 维护：

* **编码器**: 提供完整的 AV1 编码功能，支持所有 AV1 编码工具
* **解码器**: 提供完整的 AV1 解码功能
* **特点**: 功能完整但编码速度较慢，主要用于参考和验证

在 WebRTC 中，libaom 被集成为 AV1 编码器的默认实现：

.. code-block:: cpp

    // WebRTC 中 libaom AV1 编码器的关键配置
    aom_codec_enc_cfg_t cfg;
    aom_codec_enc_config_default(aom_codec_av1_cx(), &cfg, 0);

    cfg.g_w = width;
    cfg.g_h = height;
    cfg.g_timebase.num = 1;
    cfg.g_timebase.den = 90000;
    cfg.rc_target_bitrate = target_bitrate_kbps;
    cfg.g_error_resilient = AOM_ERROR_RESILIENT_DEFAULT;
    cfg.g_lag_in_frames = 0;  // WebRTC 实时模式，无延迟
    cfg.rc_end_usage = AOM_CBR;  // 恒定码率模式

    // 实时编码速度设置
    aom_codec_control(&codec, AOME_SET_CPUUSED, 8);  // speed 8-10 for realtime
    aom_codec_control(&codec, AV1E_SET_TILE_COLUMNS, 2);
    aom_codec_control(&codec, AV1E_SET_TILE_ROWS, 0);
    aom_codec_control(&codec, AV1E_SET_ENABLE_OBMC, 0);  // 关闭 OBMC 以提速
    aom_codec_control(&codec, AV1E_SET_ENABLE_WARPED_MOTION, 0);


dav1d 解码器
-----------------

dav1d 是由 VideoLAN (VLC 的开发者) 和 FFmpeg 社区联合开发的高性能 AV1 解码器：

* **高性能**: 使用手写的 SIMD 汇编优化（支持 SSE、AVX2、NEON 等），解码速度远超 libaom
* **低内存占用**: 内存使用经过精心优化
* **多线程**: 支持帧级和 tile 级并行解码
* **跨平台**: 支持 x86、ARM、RISC-V 等多种架构

dav1d 在 WebRTC 中可以作为 AV1 解码器的替代实现，提供更好的解码性能：

.. code-block:: text

    解码性能对比 (1080p AV1 内容):
    ┌──────────┬──────────────┬──────────────┐
    │ 解码器    │ 解码速度(fps) │ 内存占用(MB) │
    ├──────────┼──────────────┼──────────────┤
    │ libaom   │ ~30-60       │ ~150         │
    │ dav1d    │ ~200-400     │ ~80          │
    └──────────┴──────────────┴──────────────┘
    (数据为近似值，实际性能取决于硬件和内容)


硬件加速状态
-----------------

AV1 的硬件加速支持正在快速普及：

**Intel:**

* 第 11 代 (Tiger Lake) 及以后: 硬件 AV1 解码
* 第 12 代 (Alder Lake) 及以后: 硬件 AV1 编码 + 解码 (通过 Intel Arc GPU)
* Intel Arc 独立显卡: 完整的 AV1 硬件编解码支持

**AMD:**

* Radeon RX 6000 系列 (RDNA 2): 硬件 AV1 解码
* Radeon RX 7000 系列 (RDNA 3): 硬件 AV1 编码 + 解码

**NVIDIA:**

* GeForce RTX 30 系列 (Ampere): 硬件 AV1 解码
* GeForce RTX 40 系列 (Ada Lovelace): 硬件 AV1 编码 + 解码 (NVENC AV1)

**Apple:**

* M3 芯片及以后: 硬件 AV1 解码
* Apple 目前尚未提供硬件 AV1 编码支持

**移动平台:**

* MediaTek Dimensity 1000 及以后: 硬件 AV1 解码
* Qualcomm Snapdragon 8 Gen 1 及以后: 硬件 AV1 解码
* Samsung Exynos 2200 及以后: 硬件 AV1 解码


SVC 支持 (Scalable Video Coding)
--------------------------------------

AV1 原生支持 SVC，这对 WebRTC 的多方通话场景非常重要：

* **时域可扩展性 (Temporal Scalability)**: 支持多个时域层，允许接收端根据带宽选择不同的帧率
* **空域可扩展性 (Spatial Scalability)**: 支持多个空域层，允许接收端选择不同的分辨率

.. code-block:: text

    AV1 SVC 结构示例 (L3T3 - 3 空域层 + 3 时域层):

    空域层 2 (1080p):  [S2T0]----[S2T1]----[S2T2]----[S2T0]
                          ↑         ↑         ↑         ↑
    空域层 1 (540p):   [S1T0]----[S1T1]----[S1T2]----[S1T0]
                          ↑         ↑         ↑         ↑
    空域层 0 (270p):   [S0T0]----[S0T1]----[S0T2]----[S0T0]

在 WebRTC 中，SVC 允许 SFU (Selective Forwarding Unit) 根据每个接收端的带宽条件，
选择性地转发不同层的数据，无需进行转码。

WebRTC 中 AV1 SVC 的配置示例：

.. code-block:: javascript

    const sender = pc.addTrack(videoTrack, stream);
    const params = sender.getParameters();
    params.encodings = [
      { rid: 'low', maxBitrate: 200000, scaleResolutionDownBy: 4 },
      { rid: 'mid', maxBitrate: 700000, scaleResolutionDownBy: 2 },
      { rid: 'high', maxBitrate: 2500000 }
    ];
    // 设置 scalabilityMode 为 AV1 SVC 模式
    params.encodings[0].scalabilityMode = 'L1T3';
    params.encodings[1].scalabilityMode = 'L1T3';
    params.encodings[2].scalabilityMode = 'L1T3';
    await sender.setParameters(params);


AV1 编码 Profile 和 Level
===============================

**Profiles:**

AV1 定义了三个 Profile：

.. list-table:: AV1 Profiles
   :header-rows: 1
   :widths: 15 25 30 30

   * - Profile
     - 名称
     - 色度采样
     - 位深
   * - 0
     - Main
     - 4:2:0
     - 8-bit, 10-bit
   * - 1
     - High
     - 4:2:0, 4:4:4
     - 8-bit, 10-bit
   * - 2
     - Professional
     - 4:2:0, 4:2:2, 4:4:4
     - 8-bit, 10-bit, 12-bit

WebRTC 中通常使用 Profile 0 (Main)，支持 4:2:0 色度采样和 8-bit/10-bit 位深。

**Levels:**

AV1 定义了多个 Level，用于约束编码参数的上限：

.. list-table:: AV1 常用 Levels
   :header-rows: 1
   :widths: 15 20 20 25 20

   * - Level
     - 最大分辨率
     - 最大帧率
     - 最大码率 (Main)
     - 典型应用
   * - 2.0
     - 426x240
     - 30
     - 1.5 Mbps
     - 低分辨率
   * - 3.0
     - 854x480
     - 30
     - 6 Mbps
     - SD 视频
   * - 4.0
     - 1920x1080
     - 30
     - 12 Mbps
     - HD 视频
   * - 4.1
     - 1920x1080
     - 60
     - 20 Mbps
     - HD 高帧率
   * - 5.0
     - 3840x2160
     - 30
     - 30 Mbps
     - 4K 视频
   * - 5.1
     - 3840x2160
     - 60
     - 40 Mbps
     - 4K 高帧率


性能基准
===============

编码速度与质量
-----------------

AV1 编码器的速度和质量取决于 ``cpu-used`` (speed) 参数的设置：

.. list-table:: libaom 编码速度与质量 (1080p 30fps)
   :header-rows: 1
   :widths: 15 20 20 25 20

   * - Speed
     - 编码速度
     - VMAF 增益 (vs VP9)
     - 适用场景
     - BD-Rate 节省
   * - 0
     - ~0.01 fps
     - +35-40%
     - 离线编码/研究
     - ~35%
   * - 3
     - ~0.5 fps
     - +30-35%
     - VOD 编码
     - ~30%
   * - 6
     - ~5-10 fps
     - +20-25%
     - 近实时
     - ~22%
   * - 8
     - ~30-60 fps
     - +15-20%
     - 实时通信
     - ~17%
   * - 10
     - ~60-120 fps
     - +10-15%
     - 低延迟实时
     - ~12%

.. note::

    WebRTC 场景通常使用 speed 8-10，以满足实时编码的延迟要求。
    虽然压缩效率不如低速设置，但仍然优于 VP9 的实时编码模式。

VMAF 评分对比
-----------------

在相同码率下，各编解码器的典型 VMAF 评分对比：

.. code-block:: text

    码率: 1 Mbps, 分辨率: 1080p, 内容: 混合

    AV1 (speed 6):  VMAF ≈ 82
    H.265 (medium):  VMAF ≈ 78
    VP9 (speed 4):   VMAF ≈ 75
    H.264 (medium):  VMAF ≈ 68

    码率: 500 Kbps, 分辨率: 720p, 内容: 混合

    AV1 (speed 6):  VMAF ≈ 76
    H.265 (medium):  VMAF ≈ 71
    VP9 (speed 4):   VMAF ≈ 68
    H.264 (medium):  VMAF ≈ 60


现状与浏览器支持
======================

* **Netflix** 和 **YouTube** 已经全面支持 AV1 流媒体播放
* 相比 H.264, VP9, H.265, AV1 在相同码率下 VMAF 和 MOS 值都是最高的，也就是质量最高

**浏览器支持状态:**

.. list-table:: 浏览器 AV1 支持状态
   :header-rows: 1
   :widths: 20 20 20 20 20

   * - 浏览器
     - AV1 解码
     - AV1 编码
     - WebRTC AV1
     - 备注
   * - Chrome
     - ✅ (v70+)
     - ✅ (v90+)
     - ✅ (v90+)
     - 最完整的支持
   * - Firefox
     - ✅ (v67+)
     - ✅ (v92+)
     - ✅ (v100+)
     - 持续改进中
   * - Safari
     - ✅ (v17+)
     - ❌
     - 部分支持
     - macOS 14+ / iOS 17+
   * - Edge
     - ✅ (v79+)
     - ✅ (v90+)
     - ✅ (v90+)
     - 基于 Chromium

**WebRTC 中的 AV1 支持检测:**

.. code-block:: javascript

    // 检查浏览器是否支持 AV1 编码
    const capabilities = RTCRtpSender.getCapabilities('video');
    const av1Codec = capabilities?.codecs.find(c => c.mimeType === 'video/AV1');
    if (av1Codec) {
      console.log('AV1 encoding supported:', av1Codec);
    }

    // 检查浏览器是否支持 AV1 解码
    const recvCapabilities = RTCRtpReceiver.getCapabilities('video');
    const av1Decode = recvCapabilities?.codecs.find(c => c.mimeType === 'video/AV1');
    if (av1Decode) {
      console.log('AV1 decoding supported:', av1Decode);
    }


构建 AV1 库
===============

AV1 库的源代码存储在 Alliance for Open Media 的 Git 仓库中：

.. code-block:: bash

    $ git clone https://aomedia.googlesource.com/aom
    # 默认情况下，上述命令将源代码存储在 aom 目录中:
    $ cd aom

    # 创建构建目录
    $ mkdir build && cd build

    # 使用 CMake 配置（启用实时编码优化）
    $ cmake .. -DCONFIG_REALTIME_ONLY=1 \
               -DCONFIG_AV1_ENCODER=1 \
               -DCONFIG_AV1_DECODER=1 \
               -DENABLE_EXAMPLES=1 \
               -DENABLE_TESTS=0 \
               -DCMAKE_BUILD_TYPE=Release

    # 编译
    $ make -j$(nproc)

    # 运行简单的编码测试
    $ ./aomenc --codec=av1 --width=1920 --height=1080 \
               --fps=30/1 --target-bitrate=2000 \
               --cpu-used=8 --rt --passes=1 \
               -o output.webm input.y4m

构建 dav1d 解码器：

.. code-block:: bash

    $ git clone https://code.videolan.org/videolan/dav1d.git
    $ cd dav1d

    # 使用 meson 构建系统
    $ mkdir build && cd build
    $ meson ..
    $ ninja

    # 运行解码测试
    $ ./tools/dav1d -i input.ivf -o output.y4m


Reference
================
* AV1 Bitstream & Decoding Process Specification: https://aomediacodec.github.io/av1-spec/
* Alliance for Open Media: https://aomedia.org/
* AV1 Wikipedia: https://en.wikipedia.org/wiki/AV1
* libaom 源代码: https://aomedia.googlesource.com/aom
* dav1d 解码器: https://code.videolan.org/videolan/dav1d
* WebRTC AV1 源代码: https://source.chromium.org/chromium/chromium/src/+/main:third_party/libaom/source/libaom/
* AV1 RTP Payload Format: https://aomediacodec.github.io/av1-rtp-spec/
* Netflix AV1 技术博客: https://netflixtechblog.com/
* AV1 实时编码优化: https://aomedia.googlesource.com/aom/+/refs/heads/main/doc/
