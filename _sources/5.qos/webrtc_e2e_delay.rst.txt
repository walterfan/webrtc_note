################################
WebRTC E2E Delay
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** WebRTC E2E Delay
**Category** Learning note
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ =============================



.. contents::
   :local:


概述
===========================

在网上会议中，张三和李四在会议中进行视频聊天。张三的声音从麦克风中传入，视频从摄像头中传入，
李四要过一段时间才能听到声音，看到图像，这个时间差是视频会议中的关键指标。我们称为端到端延迟（End-to-End Delay）。

.. code-block::

   端到端延迟 = 接收端的播放时间 - 发送端的捕获时间

麻烦的事情在于，时间在发送端和接收端的时间基准是不一致的，这就要参考 RTCP SR 中给出了发送端的 NTP 时间，
通过这个时间，将接收端的 NTP 时间基准转换为发送端的：

.. code-block::

   端到端延迟 = (接收端的播放时间 - delta - RTT/2) - 发送端的捕获时间

.. code-block:: javascript

   e2e_delay = receiver_playout_time - sender_capture_time
   receiver_capture_time = sender_capture_time + ntp_delta
   e2e_delay = receiver_playout_time - receiver_capture_time
   ntp_delta = received_time - ntp_time_in_sr - rtt/2

端到端延迟是实时通信系统中最重要的质量指标之一。过高的延迟会严重影响用户的交互体验，
导致对话不自然、协作困难。因此，理解延迟的组成、测量方法和优化策略对于构建高质量的 WebRTC 应用至关重要。


延迟组成分析
===========================

端到端延迟并非单一的延迟，而是由多个环节的延迟累加而成。下面的 ASCII 图展示了完整的延迟管道：

.. code-block::

   发送端                          网络                          接收端
   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
   │  捕获延迟  │→│  编码延迟  │→│ 打包/排队  │→│  网络传输  │→│ Jitter   │→│  解码延迟  │→ 渲染
   │ Capture  │  │ Encoding │  │ Pacing   │  │ Network  │  │ Buffer   │  │ Decoding │
   └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘
       T1            T2            T3            T4             T5            T6         T7

   E2E Delay = T7 - T1 = T_capture + T_encode + T_packetize + T_network
                        + T_jitter_buffer + T_decode + T_render

各环节延迟详解如下：


捕获延迟（Capture Delay）
----------------------------

捕获延迟是指从物理世界的声音/图像到达传感器，到数字化数据可供编码器使用之间的时间。

**音频捕获延迟**:

- 麦克风硬件延迟：通常 1-5 ms
- 音频驱动缓冲区：取决于采样率和缓冲区大小，通常 10-20 ms
- 音频处理（AEC, AGC, NS）：5-20 ms
- 典型总延迟：20-40 ms

**视频捕获延迟**:

- 摄像头传感器曝光时间：取决于帧率，30fps 时约 33 ms
- 摄像头 ISP（Image Signal Processor）处理：5-15 ms
- USB/CSI 传输延迟：1-5 ms
- 典型总延迟：20-50 ms


编码延迟（Encoding Delay）
----------------------------

编码延迟是指编码器将原始音视频帧压缩为编码比特流所需的时间。

**音频编码延迟**:

- Opus 编码器：帧长度通常为 20 ms（可配置为 2.5-60 ms）
- 前瞻（lookahead）：Opus 约 5 ms
- 典型总延迟：20-25 ms

**视频编码延迟**:

- 软件编码（VP8/VP9/H.264）：5-30 ms，取决于分辨率和 CPU 性能
- 硬件编码（Hardware Encoder）：1-5 ms，显著低于软件编码
- 多帧参考和 B 帧：WebRTC 通常不使用 B 帧以降低延迟
- 码率控制的缓冲：CBR 模式下较低
- 典型总延迟：5-30 ms


打包与排队延迟（Packetization & Queuing Delay）
--------------------------------------------------

打包延迟是将编码后的比特流分割为 RTP 包的时间，通常很短（< 1 ms）。

排队延迟是指 RTP 包在发送端 Pacer（发送节奏控制器）缓冲区中等待发送的时间：

- Pacer 的作用是平滑发送速率，避免突发流量
- 排队延迟取决于当前发送队列的深度和目标发送速率
- 典型延迟：5-50 ms
- 在带宽受限时，排队延迟可能显著增加


网络传输延迟（Network Transmission Delay）
----------------------------------------------

网络传输延迟包含多个子组件：

- **传播延迟（Propagation Delay）**: 信号在物理介质中传播的时间，取决于距离。光纤中约 5 μs/km，跨大洋约 30-70 ms。
- **序列化延迟（Serialization Delay）**: 将数据包放到链路上的时间，取决于包大小和链路带宽。1500 字节在 1 Mbps 链路上约 12 ms，在 100 Mbps 链路上约 0.12 ms。
- **路由器排队延迟（Router Queuing Delay）**: 数据包在路由器缓冲区中等待转发的时间。这是网络延迟中最不可预测的部分，在网络拥塞时可能达到数百毫秒。
- **NAT/防火墙处理延迟**: 通常 < 1 ms。
- **TURN 中继延迟**: 如果使用 TURN 服务器中继，会增加额外的传播延迟和处理延迟。

典型的网络单向延迟：

- 同城：5-20 ms
- 同国：20-50 ms
- 跨洲：50-150 ms
- 使用 TURN 中继：额外增加 10-50 ms


Jitter Buffer 延迟
----------------------------

Jitter Buffer（抖动缓冲区）用于吸收网络抖动，确保数据包能够按顺序、均匀地提供给解码器。

- **音频 Jitter Buffer**: WebRTC 中使用 NetEq，自适应调整缓冲区大小，典型延迟 20-200 ms
- **视频 Jitter Buffer**: 需要等待完整帧的所有包到达，典型延迟 20-100 ms
- Jitter Buffer 的大小与网络抖动成正比：抖动越大，缓冲区越大，延迟越高
- 自适应 Jitter Buffer 会在延迟和流畅性之间做权衡


解码延迟（Decoding Delay）
----------------------------

解码延迟是将编码比特流还原为原始音视频帧的时间。

- **音频解码**: 通常 < 5 ms
- **视频软件解码**: 5-20 ms，取决于分辨率和 CPU 性能
- **视频硬件解码**: 1-5 ms，利用 GPU/专用硬件加速
- 关键帧（I-frame）的解码时间通常比预测帧（P-frame）更长


渲染延迟（Rendering Delay）
----------------------------

渲染延迟是将解码后的帧显示到屏幕或播放到扬声器的时间。

- **音频渲染**: 音频设备缓冲区延迟，通常 10-30 ms
- **视频渲染**: 取决于显示刷新率和 VSync，通常 0-16.7 ms（60 Hz 显示器）
- **GPU 渲染管线**: 如果涉及 GPU 合成，可能增加 1-2 帧的延迟


延迟预算总结
----------------------------

.. list-table:: 典型端到端延迟预算（单向）
   :header-rows: 1
   :widths: 30 20 20 20

   * - 延迟组件
     - 最佳情况
     - 典型情况
     - 最差情况
   * - 捕获延迟
     - 10 ms
     - 30 ms
     - 50 ms
   * - 编码延迟
     - 5 ms
     - 20 ms
     - 40 ms
   * - 打包/排队延迟
     - 5 ms
     - 20 ms
     - 80 ms
   * - 网络传输延迟
     - 5 ms
     - 50 ms
     - 200 ms
   * - Jitter Buffer 延迟
     - 20 ms
     - 50 ms
     - 200 ms
   * - 解码延迟
     - 2 ms
     - 15 ms
     - 30 ms
   * - 渲染延迟
     - 5 ms
     - 15 ms
     - 30 ms
   * - **总计**
     - **52 ms**
     - **200 ms**
     - **630 ms**


延迟目标与标准
===========================

ITU-T G.114 建议
----------------------------

ITU-T G.114 是关于单向传输时间的国际标准建议，定义了不同延迟等级对通信质量的影响：

.. list-table:: ITU-T G.114 延迟等级
   :header-rows: 1
   :widths: 25 25 50

   * - 单向延迟
     - 质量等级
     - 说明
   * - 0 - 150 ms
     - 优秀（Good）
     - 大多数用户满意，适合交互式对话
   * - 150 - 300 ms
     - 可接受（Acceptable）
     - 用户可以感知到延迟，但仍可进行正常对话
   * - 300 - 400 ms
     - 勉强可用（Poor）
     - 延迟明显，对话变得困难，需要适应
   * - > 400 ms
     - 不可接受（Unacceptable）
     - 严重影响交互，对话几乎无法正常进行

音频与视频的延迟容忍度差异
----------------------------------------------

音频和视频对延迟的敏感度不同：

- **音频延迟**: 人耳对音频延迟非常敏感。超过 150 ms 的单向延迟就会导致对话中出现明显的 "踩话" 现象，双方会不自觉地同时说话。
- **视频延迟**: 人眼对视频延迟的容忍度相对较高。视频延迟在 200-300 ms 内通常不会严重影响用户体验，但超过 500 ms 会导致唇音不同步等问题。
- **音视频同步**: 音频和视频之间的相对延迟（lip sync）比绝对延迟更容易被感知。ITU-R BT.1359 建议音视频同步误差应在 -125 ms 到 +45 ms 之间（音频领先视频不超过 125 ms，视频领先音频不超过 45 ms）。


延迟测量方法
===========================

RTCP SR/RR 测量 RTT
----------------------------

RTCP Sender Report (SR) 和 Receiver Report (RR) 可以用来测量往返时间（RTT）：

.. code-block::

   1. 发送端在 SR 中包含 NTP 时间戳 T1
   2. 接收端收到 SR，记录接收时间
   3. 接收端在 RR 中包含:
      - LSR (Last SR): 最近收到的 SR 中的 NTP 时间戳中间 32 位
      - DLSR (Delay since Last SR): 从收到 SR 到发送 RR 的时间间隔
   4. 发送端收到 RR，记录接收时间 T4
   5. RTT = T4 - LSR - DLSR

RTT 可以用来估计单向延迟（假设路径对称）：

.. code-block::

   单向延迟 ≈ RTT / 2

但需要注意，实际网络中上行和下行路径可能不对称，因此 RTT/2 只是一个近似值。


NTP 时间戳同步
----------------------------

RTCP SR 中包含 NTP 时间戳和对应的 RTP 时间戳，可以用来建立发送端和接收端之间的时钟映射：

.. code-block::

   发送端 NTP 时间 = SR.NTP_timestamp
   对应的 RTP 时间 = SR.RTP_timestamp

   接收端可以通过以下方式估计发送端的 NTP 时间:
   sender_ntp_time = SR.NTP_timestamp + (current_rtp_ts - SR.RTP_timestamp) / clock_rate

   时钟偏移 ntp_delta = receiver_ntp_time - sender_ntp_time - RTT/2


Absolute Capture Time 头扩展
----------------------------------------------

Absolute Capture Time 扩展用于在 RTP 包中携带原始捕获时间的 NTP 时间戳。
该扩展的目的是在有 RTCP 终结中间系统（如 mixer）参与时，仍然能够实现音视频同步。

Name: "Absolute Capture Time"; "RTP Header Extension for Absolute Capture Time"

**缩短版数据布局** (1-byte header + 8 bytes data):

.. code-block::

   0                   1                   2                   3
   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ID   | len=7 |     absolute capture timestamp (bit 0-23)     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |             absolute capture timestamp (bit 24-55)            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ... (56-63)  |
   +-+-+-+-+-+-+-+-+

**扩展版数据布局** (1-byte header + 16 bytes data):

.. code-block::

   0                   1                   2                   3
   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ID   | len=15|     absolute capture timestamp (bit 0-23)     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |             absolute capture timestamp (bit 24-55)            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ... (56-63)  |   estimated capture clock offset (bit 0-23)   |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |           estimated capture clock offset (bit 24-55)          |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  ... (56-63)  |
   +-+-+-+-+-+-+-+-+


**Absolute Capture Timestamp（绝对捕获时间戳）**:

绝对捕获时间戳是数据包中第一个音频或视频帧被原始捕获时的 NTP 时间戳。
该时间戳必须基于与捕获系统上用于生成 RTCP Sender Report 的 NTP 时间戳相同的时钟。

并非总是能在媒体帧被捕获的确切时刻进行 NTP 时钟读取。捕获系统可以推迟读取到更方便的时间。
捕获系统应从读取值中减去已知的延迟（例如来自硬件缓冲区的延迟），使最终时间戳尽可能接近实际捕获时间。

该字段编码为 64 位无符号定点数，高 32 位为秒数，低 32 位为小数部分（UQ32.32 格式）。

**Estimated Capture Clock Offset（估计的捕获时钟偏移）**:

估计的捕获时钟偏移是发送方对其自身 NTP 时钟与捕获系统 NTP 时钟之间偏移的估计。

.. code-block::

   Capture NTP Clock = Sender NTP Clock + Capture Clock Offset


chrome://webrtc-internals 延迟指标
----------------------------------------------

Chrome 浏览器提供了 ``chrome://webrtc-internals`` 工具，可以查看丰富的延迟相关指标：

- **jitterBufferDelay**: Jitter Buffer 引入的总延迟
- **jitterBufferTargetDelay**: Jitter Buffer 的目标延迟
- **jitterBufferMinimumDelay**: Jitter Buffer 的最小延迟
- **totalRoundTripTime / roundTripTimeMeasurements**: RTT 测量值
- **estimatedPlayoutTimestamp**: 估计的播放时间戳
- **framesDecoded / framesDropped**: 解码帧数和丢帧数，间接反映延迟压力


Media Stats
============================

estimatedPlayoutTimestamp
----------------------------
type: DOMHighResTimeStamp

这是接收端 track 的估计播放时间。

播放时间是最后一个可播放的音频采样或视频帧的 NTP 时间戳（来自将 RTP 时间戳映射到 NTP 时间戳的 RTCP SR 包），
并根据自准备好播放以来经过的时间进行外推。

这是发送端 NTP 时钟时间中 track 的 "当前时间"，即使当前没有音频播放也可以存在。

这对于估计来自同一源的两个 track 的音视频不同步程度非常有用：

.. code-block:: javascript

   audioVideoSyncDiff = audioTrackStats.estimatedPlayoutTimestamp
                      - videoTrackStats.estimatedPlayoutTimestamp


延迟优化策略
===========================

降低捕获延迟
----------------------------

- 使用低延迟的音频驱动配置，减小音频缓冲区大小
- 选择支持低延迟模式的摄像头
- 优化音频处理管线（AEC, AGC, NS），使用更高效的算法
- 在 WebRTC 中，可以通过 ``MediaTrackConstraints`` 设置 ``latency`` 约束


降低编码延迟
----------------------------

- **使用硬件编码器**: 硬件编码器（如 Intel QSV, NVIDIA NVENC, Apple VideoToolbox）的延迟远低于软件编码器
- **低延迟编码预设**: 使用编码器的低延迟模式，如 H.264 的 ``zerolatency`` tune
- **避免 B 帧**: B 帧需要参考未来帧，会引入额外延迟。WebRTC 默认不使用 B 帧
- **减小 GOP 大小**: 较小的 GOP 可以减少编码器的缓冲需求
- **使用较短的音频帧长度**: Opus 支持 2.5-60 ms 的帧长度，较短的帧长度可以降低延迟


降低 Jitter Buffer 延迟
----------------------------

- **自适应 Jitter Buffer 调优**: WebRTC 的 Jitter Buffer 会根据网络抖动自适应调整大小。可以通过配置参数限制最大缓冲区大小
- **最小延迟设置**: 通过 ``RTCRtpReceiver.jitterBufferTarget`` 设置目标延迟
- **加速播放（Accelerated playout）**: 当缓冲区积累过多时，通过加速播放来追赶，减少延迟
- **NetEq 优化**: 对于音频，WebRTC 的 NetEq 模块提供了多种策略来平衡延迟和质量


降低网络延迟
----------------------------

- **TURN 服务器就近部署**: 将 TURN 服务器部署在靠近用户的位置，减少中继路径长度
- **优先使用 P2P 连接**: ICE 协商时优先选择直连路径，避免不必要的中继
- **使用 CDN/边缘节点**: 对于大规模场景，使用分布式边缘节点减少传输距离
- **选择低延迟网络路径**: 某些 CDN 提供商提供优化的实时通信网络路径
- **启用 DSCP 标记**: 通过 DiffServ Code Point 标记实时流量，获得网络优先级


降低排队延迟
----------------------------

- **合理的 Pacing 配置**: Pacer 的发送速率应与估计的可用带宽匹配
- **有效的拥塞控制**: 避免发送超过网络容量的数据，减少路由器缓冲区排队
- **小队列策略**: 限制发送端队列的最大深度，宁可丢弃旧数据也不积累延迟


降低渲染延迟
----------------------------

- **硬件加速渲染**: 使用 GPU 进行视频渲染和合成
- **减少渲染管线深度**: 避免不必要的后处理步骤
- **低延迟音频输出**: 使用低延迟的音频 API（如 WASAPI Exclusive Mode, ALSA）


音视频同步
===========================

唇音同步问题（Lip Sync Problem）
----------------------------------------------

在实时通信中，音频和视频通常通过不同的 RTP 流传输，它们可能经历不同的处理延迟和网络延迟，
导致到达接收端时出现不同步。这就是所谓的唇音同步（Lip Sync）问题。

常见的不同步原因：

- 音频和视频的编码延迟不同
- 音频和视频的 Jitter Buffer 大小不同
- 音频和视频经过不同的网络路径（虽然在 WebRTC 中通常使用同一路径）
- 音频和视频的解码延迟不同


RTCP SR 实现流间同步
----------------------------------------------

RTCP Sender Report 中包含 NTP 时间戳和 RTP 时间戳的映射关系，
接收端可以利用这个映射关系来同步不同的 RTP 流：

.. code-block::

   音频流: NTP_audio = f(RTP_timestamp_audio)  (从音频 SR 获取映射)
   视频流: NTP_video = f(RTP_timestamp_video)  (从视频 SR 获取映射)

   同步: 将音频和视频的 RTP 时间戳都映射到 NTP 时间域
         然后根据 NTP 时间对齐播放

WebRTC 中的 ``StreamSynchronization`` 类负责实现这个同步逻辑：

.. code-block:: c++

    class StreamSynchronization {
    public:
      struct Measurements {
        // RTCP SR 中的 NTP 时间和 RTP 时间映射
        RtpToNtpEstimator rtp_to_ntp;
        // 最新的接收时间
        int64_t latest_receive_time_ms = 0;
        // 最新的时间戳
        uint32_t latest_timestamp = 0;
      };

      StreamSynchronization(uint32_t video_stream_id,
                            uint32_t audio_stream_id);

      // 计算音视频的相对延迟调整
      bool ComputeRelativeDelay(
          const Measurements& audio_measurement,
          const Measurements& video_measurement,
          int* relative_delay_ms);

      // 计算需要的延迟补偿
      bool ComputeDelays(int relative_delay_ms,
                         int current_audio_delay_ms,
                         int* extra_audio_delay_ms,
                         int* total_video_delay_ms);
    };

同步策略是：计算音频和视频之间的相对延迟差，然后通过调整较快流的播放延迟来对齐两个流。
通常是延迟较快的流，而不是加速较慢的流，因为加速可能导致质量下降。


Glass-to-Glass 延迟测量
===========================

Glass-to-Glass 延迟是指从发送端摄像头镜头捕获图像到接收端屏幕显示该图像之间的总延迟。
这是最真实的端到端延迟测量，包含了所有环节的延迟。

测量方法
----------------------------

**方法一：高速摄像机法**

1. 在发送端屏幕上显示一个高精度计时器（精确到毫秒）
2. 用发送端的摄像头拍摄该计时器
3. 在接收端屏幕上显示接收到的视频
4. 用一台高速摄像机（如 240fps）同时拍摄发送端的计时器和接收端的屏幕
5. 分析高速摄像机的帧，计算两个计时器显示值的差异

**方法二：光电传感器法**

1. 在发送端生成交替的黑白帧
2. 在接收端用光电传感器检测屏幕亮度变化
3. 比较发送端生成时间和接收端检测时间的差异

**方法三：软件时间戳法**

利用 WebRTC Stats API 中的时间戳信息进行估算：

.. code-block:: javascript

   // 获取接收端统计信息
   const stats = await peerConnection.getStats();
   stats.forEach(report => {
     if (report.type === 'inbound-rtp') {
       console.log('jitterBufferDelay:', report.jitterBufferDelay);
       console.log('jitterBufferEmittedCount:', report.jitterBufferEmittedCount);
       // 平均 jitter buffer 延迟
       const avgJBDelay = report.jitterBufferDelay
                        / report.jitterBufferEmittedCount * 1000;
       console.log('Average JB delay (ms):', avgJBDelay);
     }
     if (report.type === 'candidate-pair' && report.nominated) {
       console.log('currentRoundTripTime:', report.currentRoundTripTime);
     }
   });


常用工具
----------------------------

- **WebRTC Test Page**: Google 提供的 WebRTC 测试页面，可以显示基本的延迟指标
- **chrome://webrtc-internals**: Chrome 内置的 WebRTC 调试工具，提供详细的统计信息
- **testRTC**: 商业化的 WebRTC 测试平台，支持自动化的延迟测量
- **Srflx/Callstats**: 提供实时的 WebRTC 质量监控，包括延迟指标


总结
===========================

端到端延迟是 WebRTC 实时通信质量的核心指标。优化延迟需要从整个媒体管道的每个环节入手，
包括捕获、编码、传输、缓冲、解码和渲染。没有单一的 "银弹" 可以解决所有延迟问题，
需要根据具体场景进行综合优化。

关键原则：

1. **测量先行**: 在优化之前，先准确测量各环节的延迟，找到瓶颈
2. **端到端思维**: 不要只关注某一个环节，要从全局角度优化
3. **权衡取舍**: 延迟与质量、流畅性之间存在权衡，需要根据应用场景做出合理选择
4. **持续监控**: 网络条件是动态变化的，需要持续监控延迟指标并自适应调整


参考资料
===========================

* `ITU-T G.114 - One-way transmission time <https://www.itu.int/rec/T-REC-G.114/en>`_
* `ITU-R BT.1359 - Relative timing of sound and vision for broadcasting <https://www.itu.int/rec/R-REC-BT.1359/en>`_
* `RFC 3550 - RTP: A Transport Protocol for Real-Time Applications <https://tools.ietf.org/html/rfc3550>`_
* `RFC 3611 - RTP Control Protocol Extended Reports (RTCP XR) <https://tools.ietf.org/html/rfc3611>`_
* `Absolute Capture Time RTP Header Extension <https://webrtc.org/experiments/rtp-hdrext/abs-capture-time/>`_
* `W3C WebRTC Stats <https://www.w3.org/TR/webrtc-stats/>`_
* https://github.com/w3ctag/design-reviews/issues/493
* https://github.com/w3c/webrtc-extensions/blob/main/explainer.md
* https://github.com/w3c/webrtc-stats/pull/538/files
* https://janus.conf.meetecho.com/docs/rtp_8h.html#a55faec3441b03350eec0f9b39e8b79bf
