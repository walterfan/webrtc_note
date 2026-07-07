################
WebRTC 视频
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Web 视频
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. toctree::
   :maxdepth: 1
   :caption: Contents:

   
   video_basic
   video_codec
   video_adaptation
   video_quality
   video_pipeline
   video_process
   video_lip_sync
   yuv
   video_codec_h264
   video_codec_av1


概述
===================

WebRTC 视频处理是整个实时通信系统中最复杂、最消耗资源的部分。从摄像头采集原始图像数据开始，经过预处理、编码、RTP 打包、网络传输、接收解包、解码、后处理，最终渲染到屏幕上，这一完整的 pipeline 涉及到图像处理、视频编解码、网络传输、拥塞控制等多个技术领域。

WebRTC 视频处理的核心目标是在有限的网络带宽和计算资源条件下，提供尽可能高质量、低延迟的视频通信体验。这需要在以下几个维度之间进行精细的权衡：

* **质量 (Quality)**: 分辨率、帧率、清晰度
* **延迟 (Latency)**: 端到端延迟，通常要求在 150ms 以内
* **带宽 (Bandwidth)**: 网络可用带宽是动态变化的
* **计算资源 (Compute)**: CPU/GPU 的编解码能力
* **功耗 (Power)**: 移动设备上的电池消耗

WebRTC 视频处理的完整 pipeline 如下：

.. code-block:: text

   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
   │  Camera  │──▶│  Pre-    │──▶│ Encoder  │──▶│   RTP    │──▶│ Network  │
   │ Capture  │   │ process  │   │(H264/VP8)│   │ Packetize│   │  Send    │
   └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
                                                                      │
                                                                      ▼
   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
   │  Screen  │◀──│  Post-   │◀──│ Decoder  │◀──│   RTP    │◀──│ Network  │
   │  Render  │   │ process  │   │          │   │Depacketize│  │ Receive  │
   └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘

在发送端，视频帧从摄像头采集后，首先经过预处理（如降噪、裁剪、缩放），然后由编码器压缩为比特流，再由 RTP 模块将编码后的 NAL 单元或 VP8 分区打包为 RTP 包，最后通过网络发送。

在接收端，RTP 包经过 jitter buffer 重排序和去抖动后，解包还原为编码比特流，由解码器解码为原始图像帧，经过后处理（如去块效应、超分辨率）后渲染到屏幕上。

整个过程中，拥塞控制模块 (Congestion Control) 持续监测网络状况，动态调整编码参数（分辨率、帧率、比特率），以适应网络带宽的变化。这就是 WebRTC 视频自适应 (Video Adaptation) 的核心机制。


视频基础知识
===================

像素与分辨率
-------------------

**像素 (Pixel)** 是数字图像的最小单元，每个像素包含颜色信息。一幅数字图像由二维像素阵列组成。

**PPI (Pixels Per Inch)** 表示每英寸的像素数量，用于衡量显示设备的像素密度。PPI 越高，图像越细腻。例如，Apple Retina 显示屏的 PPI 通常在 220 以上。

**分辨率 (Resolution)** 表示图像的宽度和高度的像素数量。常见的视频分辨率如下：

.. list-table:: 常见视频分辨率
   :header-rows: 1
   :widths: 20 20 15 15 30

   * - 名称
     - 分辨率
     - 宽高比
     - 像素总数
     - 典型应用场景
   * - QVGA
     - 320×240
     - 4:3
     - 76,800
     - 低带宽视频通话
   * - VGA
     - 640×480
     - 4:3
     - 307,200
     - 标清视频通话
   * - qHD
     - 960×540
     - 16:9
     - 518,400
     - 中等质量视频
   * - 720p (HD)
     - 1280×720
     - 16:9
     - 921,600
     - 高清视频通话、会议
   * - 1080p (Full HD)
     - 1920×1080
     - 16:9
     - 2,073,600
     - 高清直播、录制
   * - 1440p (2K)
     - 2560×1440
     - 16:9
     - 3,686,400
     - 高端视频会议
   * - 2160p (4K UHD)
     - 3840×2160
     - 16:9
     - 8,294,400
     - 超高清视频

**宽高比 (Aspect Ratio)** 是图像宽度与高度的比值。现代视频主要使用 16:9 宽高比，传统视频使用 4:3。在 WebRTC 中，宽高比会影响视频采集和渲染的布局。

在 WebRTC 视频通话中，分辨率的选择需要综合考虑：

* 网络带宽：720p@30fps 通常需要 1.5-2.5 Mbps 的带宽
* 设备性能：编解码器的处理能力
* 应用场景：一对一通话 vs 多人会议
* 显示区域：视频窗口的实际大小


色彩空间
-------------------

**色彩空间 (Color Space)** 定义了颜色的数学表示方式。在视频处理中，主要使用以下几种色彩空间：

**RGB 色彩空间**

RGB 是最直观的色彩空间，每个像素由红 (Red)、绿 (Green)、蓝 (Blue) 三个分量组成。每个分量通常用 8 位表示，取值范围为 0-255。一个 RGB 像素占用 24 位 (3 字节)。

RGB 色彩空间适合显示设备，但不适合视频压缩，因为三个分量之间存在较强的相关性，且人眼对亮度和色度的敏感度不同。

**YUV (YCbCr) 色彩空间**

YUV 色彩空间将颜色信息分为亮度 (Luminance, Y) 和色度 (Chrominance, U/V 或 Cb/Cr) 两部分：

* **Y (Luminance)**: 亮度分量，表示图像的明暗信息
* **U/Cb (Blue-difference Chrominance)**: 蓝色色度分量
* **V/Cr (Red-difference Chrominance)**: 红色色度分量

视频处理中使用 YUV 色彩空间的主要原因：

1. **人眼特性**: 人眼对亮度变化比色度变化更敏感，因此可以对色度分量进行更大比例的压缩而不明显影响视觉质量
2. **压缩效率**: 色度子采样 (Chroma Subsampling) 可以显著减少数据量
3. **兼容性**: 黑白电视只需要 Y 分量即可显示

**色度子采样 (Chroma Subsampling)**

色度子采样是利用人眼对色度分辨率不敏感的特性，降低色度分量的采样率：

.. list-table:: 色度子采样格式
   :header-rows: 1
   :widths: 15 30 20 35

   * - 格式
     - 说明
     - 每像素位数
     - 应用场景
   * - YUV 4:4:4
     - 色度与亮度采样率相同，无压缩
     - 24 bits
     - 专业视频制作
   * - YUV 4:2:2
     - 水平方向色度采样率减半
     - 16 bits
     - 高质量视频、广播
   * - YUV 4:2:0
     - 水平和垂直方向色度采样率均减半
     - 12 bits
     - WebRTC、大多数视频编码
   * - YUV 4:1:1
     - 水平方向色度采样率为 1/4
     - 12 bits
     - DV 格式

WebRTC 中最常用的是 **I420** 格式（即 YUV 4:2:0 planar），其中 Y 平面的分辨率为完整分辨率，U 和 V 平面的分辨率各为 Y 平面的 1/4。例如，一帧 1280×720 的 I420 图像占用的字节数为：

.. code-block:: text

   Y: 1280 × 720 = 921,600 bytes
   U: 640 × 360  = 230,400 bytes
   V: 640 × 360  = 230,400 bytes
   Total: 1,382,400 bytes ≈ 1.32 MB

**HSV 色彩空间**

HSV (Hue, Saturation, Value) 色彩空间更接近人类对颜色的感知方式，常用于图像处理中的颜色检测和分割，但在视频编码中较少使用。

RGB 与 YUV 之间的转换公式（BT.601 标准）：

.. code-block:: text

   Y  =  0.299 × R + 0.587 × G + 0.114 × B
   Cb = -0.169 × R - 0.331 × G + 0.500 × B + 128
   Cr =  0.500 × R - 0.419 × G - 0.081 × B + 128


帧率
-------------------

**帧率 (Frame Rate)** 表示每秒显示的图像帧数，单位为 fps (frames per second)。帧率直接影响视频的流畅度和自然感。

.. list-table:: 常见帧率及其应用
   :header-rows: 1
   :widths: 15 25 60

   * - 帧率
     - 名称
     - 说明
   * - 15 fps
     - 低帧率
     - 最低可接受的视频通话帧率，适用于极低带宽场景，画面有明显卡顿感
   * - 24 fps
     - 电影帧率
     - 电影标准帧率，具有"电影感"，人眼可感知到轻微的运动模糊
   * - 25 fps
     - PAL 标准
     - 欧洲电视标准 (PAL/SECAM)
   * - 30 fps
     - NTSC 标准
     - 北美电视标准，WebRTC 视频通话的常用帧率，画面流畅
   * - 60 fps
     - 高帧率
     - 游戏直播、运动场景，画面非常流畅，但带宽和计算需求翻倍
   * - 120 fps
     - 超高帧率
     - 慢动作回放、高端游戏

在 WebRTC 中，帧率通常设置为 **30 fps**，在带宽不足时会自动降低到 15 fps 甚至更低。帧率与流畅度的关系：

* **< 10 fps**: 幻灯片效果，不适合视频通话
* **10-15 fps**: 基本可用，但有明显卡顿
* **15-24 fps**: 可接受，适合低带宽场景
* **24-30 fps**: 流畅，适合大多数视频通话
* **> 30 fps**: 非常流畅，适合运动场景和屏幕共享

帧率对带宽的影响是线性的：在相同分辨率和编码质量下，60 fps 所需的带宽大约是 30 fps 的 1.5-2 倍（不是严格的 2 倍，因为相邻帧之间的相似度更高，编码器可以利用时间冗余进行更高效的压缩）。


比特率
-------------------

**比特率 (Bitrate)** 表示每秒传输的数据量，单位为 bps (bits per second)。比特率是衡量视频质量和带宽需求的关键指标。

**CBR (Constant Bitrate) 恒定比特率**

编码器输出的比特率保持恒定。优点是带宽占用可预测，适合网络带宽固定的场景；缺点是在复杂场景中质量可能不足，在简单场景中浪费带宽。

**VBR (Variable Bitrate) 可变比特率**

编码器根据画面复杂度动态调整比特率。复杂场景（如快速运动）分配更多比特，简单场景（如静止画面）分配更少比特。VBR 在相同平均比特率下通常能提供更好的视觉质量。

WebRTC 中通常使用 **VBR** 模式，并结合拥塞控制算法动态调整目标比特率。

.. list-table:: 不同分辨率的推荐比特率
   :header-rows: 1
   :widths: 20 25 25 30

   * - 分辨率
     - 最低比特率
     - 推荐比特率
     - 高质量比特率
   * - 320×240 (QVGA)
     - 150 kbps
     - 300 kbps
     - 500 kbps
   * - 640×480 (VGA)
     - 300 kbps
     - 600 kbps
     - 1 Mbps
   * - 1280×720 (720p)
     - 800 kbps
     - 1.5 Mbps
     - 2.5 Mbps
   * - 1920×1080 (1080p)
     - 1.5 Mbps
     - 3 Mbps
     - 5 Mbps

比特率与质量的关系并非线性。在低比特率区间，增加比特率能显著提升质量；但当比特率达到一定水平后，继续增加比特率带来的质量提升会越来越小，这就是所谓的 **收益递减 (Diminishing Returns)** 效应。


GOP (Group of Pictures)
---------------------------

**GOP (Group of Pictures)** 是视频编码中的基本结构单元，定义了一组连续帧的编码依赖关系。

**帧类型**

* **I 帧 (Intra-coded Frame, 关键帧)**: 独立编码，不依赖其他帧，可以独立解码。I 帧的压缩率最低，数据量最大，但它是随机访问的入口点。
* **P 帧 (Predicted Frame, 前向预测帧)**: 参考前面的 I 帧或 P 帧进行编码，只编码与参考帧的差异。P 帧的压缩率高于 I 帧。
* **B 帧 (Bi-directional Predicted Frame, 双向预测帧)**: 同时参考前后的帧进行编码，压缩率最高，但增加了编码延迟（需要等待后续帧）。

**GOP 结构**

一个典型的 GOP 结构如下：

.. code-block:: text

   I  B  B  P  B  B  P  B  B  P  B  B  I  B  B  P ...
   |<-------------- GOP (12 frames) ------------->|

**关键帧间隔 (Keyframe Interval)**

关键帧间隔是两个 I 帧之间的帧数。在 WebRTC 中：

* 较短的关键帧间隔（如 1-2 秒）有利于快速恢复丢包错误，降低加入延迟
* 较长的关键帧间隔（如 5-10 秒）有利于提高压缩效率
* WebRTC 通常不使用 B 帧，因为 B 帧会增加编码延迟
* 当检测到丢包时，接收端可以通过 PLI (Picture Loss Indication) 或 FIR (Full Intra Request) 请求发送端发送新的关键帧

在 WebRTC 中，典型的 GOP 结构是 **IPPP...** 模式（不使用 B 帧），关键帧间隔通常为 2-3 秒，但在网络丢包时会根据需要插入额外的关键帧。


视频编解码器
===================

视频编解码器 (Video Codec) 是视频处理的核心组件，负责将原始视频数据压缩为比特流（编码），以及将比特流还原为视频帧（解码）。WebRTC 支持多种视频编解码器。

H.264/AVC
-------------------

**H.264/AVC (Advanced Video Coding)** 是目前应用最广泛的视频编码标准，由 ITU-T 和 ISO/IEC 联合制定（ITU-T H.264 / ISO/IEC 14496-10）。

**Profile (配置)**

H.264 定义了多个 Profile，每个 Profile 支持不同的编码工具集：

* **Baseline Profile**: 支持 I 帧和 P 帧，不支持 B 帧和 CABAC 熵编码。编码复杂度最低，适合实时通信和移动设备。WebRTC 中最常用的 Profile。
* **Main Profile**: 在 Baseline 基础上增加了 B 帧和 CABAC 支持，压缩效率更高，但编码延迟也更大。
* **High Profile**: 支持 8×8 变换、自适应量化矩阵等高级工具，压缩效率最高，适合高质量视频存储和广播。

**Level**

Level 定义了编解码器的处理能力上限，包括最大分辨率、最大帧率、最大比特率等。例如：

* Level 3.1: 最大支持 1280×720@30fps
* Level 4.0: 最大支持 2048×1024@30fps
* Level 5.1: 最大支持 4096×2160@30fps

**在 WebRTC 中的地位**

根据 `RFC7742`_ 的规定，H.264 Constrained Baseline Profile Level 1.2 是 WebRTC 实现的 **必选 (MUST)** 编解码器之一。H.264 的 RTP 打包格式定义在 RFC 6184 中，支持 Single NAL Unit Mode、Non-Interleaved Mode 和 Interleaved Mode。

VP8
-------------------

**VP8** 是 Google 开发并开源的视频编码格式，是 WebRTC 的默认视频编解码器之一。

主要特点：

* **开源免费**: 采用 BSD 许可证，无专利费用
* **低延迟**: 设计上针对实时通信优化，不支持 B 帧
* **错误恢复**: 支持 temporal scalability 和 golden frame / altref frame 参考结构
* **硬件支持**: 主流移动芯片和浏览器均支持 VP8 硬件加解码

VP8 的压缩效率与 H.264 Baseline Profile 相当，但低于 H.264 High Profile。VP8 的 RTP 打包格式定义在 RFC 7741 中。

根据 `RFC7742`_ 的规定，VP8 也是 WebRTC 实现的 **必选 (MUST)** 编解码器。

VP9
-------------------

**VP9** 是 VP8 的继任者，同样由 Google 开发并开源。

主要特点：

* **压缩效率**: 相比 VP8 提升约 30-50%，与 H.265/HEVC 相当
* **SVC 支持**: 原生支持 Scalable Video Coding，包括时间可伸缩性 (Temporal Scalability) 和空间可伸缩性 (Spatial Scalability)
* **超级块 (Superblock)**: 支持 64×64 的超级块，提高了大面积平坦区域的编码效率
* **开源免费**: 无专利费用
* **广泛支持**: YouTube 大量使用 VP9 编码

VP9 在 WebRTC 中的应用越来越广泛，特别是在 SFU (Selective Forwarding Unit) 架构中，VP9 SVC 可以让服务器根据每个接收端的带宽条件选择性转发不同层级的视频流，而无需转码。

AV1
-------------------

**AV1 (AOMedia Video 1)** 是由开放媒体联盟 (Alliance for Open Media, AOMedia) 开发的下一代开源视频编码格式。AOMedia 的成员包括 Google、Apple、Microsoft、Amazon、Netflix、Meta 等科技巨头。

主要特点：

* **压缩效率**: 相比 VP9/HEVC 提升约 30%，相比 H.264 提升约 50%
* **开源免费**: 无专利费用，这是 AV1 相对于 H.265/HEVC 的最大优势
* **编码复杂度**: 编码速度较慢，是 AV1 目前的主要瓶颈，但随着硬件编码器的普及正在改善
* **工具丰富**: 支持 film grain synthesis、超分辨率、环路恢复滤波器等先进工具
* **SVC 支持**: 支持可伸缩视频编码

AV1 在 WebRTC 中的应用正在逐步推进，Chrome 和 Firefox 已经支持 AV1 的 WebRTC 编解码。

编解码器对比
-------------------

.. list-table:: WebRTC 视频编解码器对比
   :header-rows: 1
   :widths: 15 15 15 15 15 25

   * - 特性
     - H.264/AVC
     - VP8
     - VP9
     - AV1
     - H.265/HEVC
   * - 发布年份
     - 2003
     - 2010
     - 2013
     - 2018
     - 2013
   * - 压缩效率
     - 基准
     - ≈ H.264 BP
     - +30-50%
     - +50-60%
     - +30-50%
   * - 编码复杂度
     - 低
     - 低
     - 中
     - 高
     - 中-高
   * - 解码复杂度
     - 低
     - 低
     - 中
     - 中
     - 中
   * - 延迟
     - 低
     - 低
     - 低-中
     - 中
     - 低-中
   * - 许可证
     - 需付费
     - 免费 (BSD)
     - 免费 (BSD)
     - 免费
     - 需付费
   * - WebRTC 必选
     - 是
     - 是
     - 否
     - 否
     - 否
   * - 硬件支持
     - 广泛
     - 广泛
     - 较广泛
     - 逐步增加
     - 广泛
   * - SVC 支持
     - 有限
     - 有限
     - 原生支持
     - 原生支持
     - 支持


WebRTC 视频 Pipeline
=========================

WebRTC 视频处理的完整 pipeline 包含以下阶段：

1. 采集 (Capture)
-------------------

从摄像头或屏幕捕获原始视频帧。WebRTC 使用平台原生 API 访问摄像头设备：

* Windows: Media Foundation / DirectShow
* macOS/iOS: AVFoundation
* Linux: V4L2 (Video4Linux2)
* Android: Camera2 API

2. 预处理 (Pre-processing)
-----------------------------

对原始视频帧进行处理，包括：

* **降噪 (Denoising)**: 去除摄像头噪声，提高编码效率
* **缩放 (Scaling)**: 根据目标分辨率进行缩放
* **裁剪 (Cropping)**: 调整宽高比
* **旋转 (Rotation)**: 处理移动设备的方向变化
* **美颜/背景替换**: 应用 AI 处理效果

3. 编码 (Encoding)
-------------------

将原始视频帧压缩为比特流。编码器根据拥塞控制模块提供的目标比特率、分辨率和帧率进行编码。

4. RTP 打包 (Packetization)
------------------------------

将编码后的比特流分割为适合网络传输的 RTP 包。每个 RTP 包通常不超过 MTU 大小（约 1200 字节），以避免 IP 层分片。

5. 网络发送 (Network Send)
-----------------------------

通过 DTLS-SRTP 加密后发送 RTP 包，同时发送 RTCP 报告用于质量反馈。

6. 网络接收 (Network Receive)
-------------------------------

接收 RTP 包，处理乱序、丢包和重复包。

7. Jitter Buffer
-------------------

对接收到的 RTP 包进行缓冲和重排序，消除网络抖动的影响。Jitter buffer 的大小需要在延迟和流畅度之间权衡。

8. RTP 解包 (Depacketization)
--------------------------------

将 RTP 包还原为编码比特流，组装完整的视频帧。

9. 解码 (Decoding)
-------------------

将编码比特流解码为原始视频帧。

10. 渲染 (Rendering)
----------------------

将解码后的视频帧显示到屏幕上。WebRTC 在浏览器中通过 ``<video>`` 元素进行渲染。


视频采集
===================

在 Web 浏览器中，视频采集通过 ``getUserMedia`` API 实现。

getUserMedia API
-------------------

``getUserMedia`` 是 WebRTC 的核心 API 之一，用于获取用户的摄像头和麦克风权限并采集媒体流。

.. code-block:: javascript

   // 基本用法
   const stream = await navigator.mediaDevices.getUserMedia({
     video: true,
     audio: true
   });

   // 指定视频约束
   const stream = await navigator.mediaDevices.getUserMedia({
     video: {
       width: { ideal: 1280, max: 1920 },
       height: { ideal: 720, max: 1080 },
       frameRate: { ideal: 30, max: 60 },
       facingMode: 'user',  // 前置摄像头
       deviceId: { exact: cameraId }  // 指定摄像头
     },
     audio: true
   });

**约束 (Constraints)**

视频约束支持以下属性：

* ``width`` / ``height``: 分辨率
* ``frameRate``: 帧率
* ``facingMode``: 摄像头朝向 (``user`` 前置, ``environment`` 后置)
* ``deviceId``: 指定设备 ID
* ``aspectRatio``: 宽高比

每个约束属性可以使用以下修饰符：

* ``exact``: 精确匹配，不满足则失败
* ``ideal``: 理想值，浏览器尽量满足
* ``min`` / ``max``: 最小/最大值范围

**分辨率/帧率协商**

浏览器会根据约束条件和摄像头能力进行协商，选择最接近理想值的配置。如果摄像头不支持请求的分辨率，浏览器可能会选择最接近的可用分辨率，或者通过缩放来满足约束。

.. code-block:: javascript

   // 枚举可用设备
   const devices = await navigator.mediaDevices.enumerateDevices();
   const cameras = devices.filter(d => d.kind === 'videoinput');

   // 获取摄像头能力
   const track = stream.getVideoTracks()[0];
   const capabilities = track.getCapabilities();
   console.log('支持的分辨率范围:', capabilities.width, capabilities.height);
   console.log('支持的帧率范围:', capabilities.frameRate);

   // 动态调整约束
   await track.applyConstraints({
     width: { ideal: 640 },
     height: { ideal: 480 },
     frameRate: { ideal: 15 }
   });


视频文件格式
===================

理解视频文件格式需要区分 **容器格式 (Container Format)** 和 **编码格式 (Codec Format)**：

* **容器格式**: 定义了如何将视频流、音频流、字幕等多种数据封装在一个文件中。容器格式负责同步、索引和元数据管理。
* **编码格式**: 定义了如何压缩和解压缩视频/音频数据。一个容器可以包含不同编码格式的流。

例如，一个 MP4 文件（容器格式）可以包含 H.264 编码的视频流和 AAC 编码的音频流。

.. list-table:: 常见视频容器格式
   :header-rows: 1
   :widths: 15 15 35 35

   * - 格式
     - 扩展名
     - 支持的视频编码
     - 说明
   * - AVI
     - ``.avi``
     - 几乎所有编码
     - Microsoft 开发，较老的格式，不支持流媒体
   * - MP4
     - ``.mp4``
     - H.264, H.265, AV1
     - ISO 标准 (MPEG-4 Part 14)，最通用的格式
   * - MKV
     - ``.mkv``
     - 几乎所有编码
     - Matroska 开源格式，功能丰富
   * - WebM
     - ``.webm``
     - VP8, VP9, AV1
     - Google 开发，基于 Matroska，Web 友好
   * - MOV
     - ``.mov``
     - H.264, H.265, ProRes
     - Apple QuickTime 格式
   * - FLV
     - ``.flv``
     - H.264, VP6
     - Adobe Flash Video，曾广泛用于网络视频
   * - TS
     - ``.ts``
     - H.264, H.265
     - MPEG Transport Stream，用于广播和流媒体
   * - WMV
     - ``.wmv``
     - WMV9, VC-1
     - Microsoft Windows Media Video
   * - RMVB
     - ``.rm``, ``.rmvb``
     - RealVideo
     - RealNetworks 开发，已较少使用

在 WebRTC 中，视频数据以 RTP 包的形式传输，不使用容器格式。但在录制 WebRTC 会话时，通常使用 WebM 容器格式（通过 MediaRecorder API）。


WebRTC 视频相关 API
=========================

RTCRtpSender
-------------------

``RTCRtpSender`` 负责将本地视频轨道编码并发送到远端。

.. code-block:: javascript

   const sender = peerConnection.addTrack(videoTrack, stream);

   // 获取发送参数
   const params = sender.getParameters();
   console.log('编码器:', params.codecs);
   console.log('编码配置:', params.encodings);

   // 动态调整编码参数
   params.encodings[0].maxBitrate = 1000000;  // 1 Mbps
   params.encodings[0].maxFramerate = 30;
   params.encodings[0].scaleResolutionDownBy = 2;  // 分辨率缩小一半
   await sender.setParameters(params);

RTCRtpReceiver
-------------------

``RTCRtpReceiver`` 负责接收远端视频数据并解码。

.. code-block:: javascript

   peerConnection.ontrack = (event) => {
     const receiver = event.receiver;
     const track = event.track;

     if (track.kind === 'video') {
       videoElement.srcObject = new MediaStream([track]);

       // 获取接收参数
       const params = receiver.getParameters();
       console.log('解码器:', params.codecs);
     }
   };

getStats() 视频指标
-----------------------

通过 ``getStats()`` API 可以获取详细的视频传输统计信息：

.. code-block:: javascript

   const stats = await peerConnection.getStats();
   stats.forEach(report => {
     if (report.type === 'outbound-rtp' && report.kind === 'video') {
       console.log('发送帧率:', report.framesPerSecond);
       console.log('发送分辨率:', report.frameWidth, '×', report.frameHeight);
       console.log('发送比特率:', report.bytesSent);
       console.log('编码器:', report.encoderImplementation);
       console.log('关键帧数:', report.keyFramesEncoded);
       console.log('QP 值:', report.qpSum / report.framesEncoded);
     }

     if (report.type === 'inbound-rtp' && report.kind === 'video') {
       console.log('接收帧率:', report.framesPerSecond);
       console.log('接收分辨率:', report.frameWidth, '×', report.frameHeight);
       console.log('丢包数:', report.packetsLost);
       console.log('抖动:', report.jitter);
       console.log('解码帧数:', report.framesDecoded);
       console.log('丢弃帧数:', report.framesDropped);
       console.log('冻结次数:', report.freezeCount);
       console.log('NACK 数:', report.nackCount);
       console.log('PLI 数:', report.pliCount);
       console.log('FIR 数:', report.firCount);
     }
   });

这些统计指标对于监控视频质量、诊断问题和优化性能至关重要。


参考文献
===================

* `RFC7742`_ "WebRTC Video Processing and Codec Requirements" - 定义了 WebRTC 视频处理和编解码器的要求
* `RFC 6184 <https://tools.ietf.org/html/rfc6184>`_ "RTP Payload Format for H.264 Video" - H.264 的 RTP 打包格式
* `RFC 7741 <https://tools.ietf.org/html/rfc7741>`_ "RTP Payload Format for VP8 Video" - VP8 的 RTP 打包格式
* `RFC 7798 <https://tools.ietf.org/html/rfc7798>`_ "RTP Payload Format for High Efficiency Video Coding (HEVC)" - HEVC 的 RTP 打包格式
* `RFC 8834 <https://tools.ietf.org/html/rfc8834>`_ "Media Transport and Use of RTP in WebRTC" - WebRTC 中 RTP 的使用
* `ITU-T H.264 <https://www.itu.int/rec/T-REC-H.264>`_ "Advanced video coding for generic audiovisual services"
* `AV1 Bitstream & Decoding Process Specification <https://aomediacodec.github.io/av1-spec/>`_
* `WebRTC API - MDN <https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API>`_
