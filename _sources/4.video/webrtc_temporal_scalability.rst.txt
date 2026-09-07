################################
Temporal scalability
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** Temporal scalability
**Category** Learning note
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ =============================



.. contents::
   :local:


概述
===========================

时间可伸缩性 (Temporal Scalability) 是视频编码中的一种重要技术，
它允许将视频帧序列编码为多个时间层 (temporal layers)，
使得中间节点（如 SFU）可以选择性地丢弃高层帧，
而接收端仍然能够正确解码剩余的帧序列，只是帧率会相应降低。

在 WebRTC 实时通信中，时间可伸缩性具有重要的实际意义：

1. **带宽适配**: SFU 可以根据接收端的可用带宽，选择性地转发不同数量的时间层，
   实现平滑的帧率降级
2. **拥塞控制辅助**: 当网络拥塞时，可以快速丢弃高层帧来降低码率，
   而不需要等待编码器重新配置
3. **异构网络支持**: 在多方会议中，不同接收端可能有不同的带宽条件，
   SFU 可以为每个接收端转发不同数量的时间层
4. **错误恢复**: 当丢包发生时，如果丢失的是高层帧，
   低层帧仍然可以正确解码，减少了视频卡顿

**核心原理：**

时间可伸缩性的核心在于帧间参考关系的精心设计。
低层帧（如 T0）只参考同层或更低层的帧，不参考高层帧；
而高层帧（如 T1、T2）可以参考低层帧。
这样，丢弃高层帧不会影响低层帧的解码。

.. note::

   时间可伸缩性是 SVC (Scalable Video Coding) 的一个维度，
   但它不需要完整的 SVC 编解码器支持。
   VP8、H.264 AVC 等非 SVC 编解码器也可以通过特定的参考帧管理实现时间可伸缩性。


帧依赖模式
===========================

2 个时间层 (T0, T1)
-----------------------------

最简单的时间可伸缩性配置是 2 个时间层。
假设目标帧率为 30fps，则：

- **T0 层 (基础层)**: 15fps，包含关键帧和基础参考帧
- **T1 层 (增强层)**: 额外的 15fps，与 T0 层合并后达到 30fps

帧依赖关系如下：

.. code-block:: text

   时间 →
   
   T1:       1       3       5       7       9
             ↑       ↑       ↑       ↑       ↑
   T0:   K───0───────2───────4───────6───────8───────
   
   帧号: K   0   1   2   3   4   5   6   7   8   9
   层:   T0  T0  T1  T0  T1  T0  T1  T0  T1  T0  T1

依赖规则：

- **T0 帧**: 只参考前一个 T0 帧（或关键帧）
- **T1 帧**: 参考前一个 T0 帧（单向预测）或前后两个 T0 帧

当 SFU 丢弃所有 T1 帧时，接收端只解码 T0 帧，帧率从 30fps 降为 15fps。
由于 T0 帧之间没有对 T1 帧的依赖，解码完全不受影响。

**码率分配：**

- T0 层通常占总码率的约 60-70%
- T1 层占约 30-40%
- 丢弃 T1 层后，码率降低约 30-40%，帧率降低 50%


3 个时间层 (T0, T1, T2)
-----------------------------

3 个时间层提供更精细的帧率控制。假设目标帧率为 30fps：

- **T0 层**: 7.5fps
- **T0 + T1 层**: 15fps
- **T0 + T1 + T2 层**: 30fps

帧依赖关系：

.. code-block:: text

   时间 →
   
   T2:           2       6       10      14
                 ↑       ↑       ↑       ↑
   T1:       1───────3───────7───────11──────
             ↑       ↑       ↑       ↑
   T0:   K───0───────4───────8───────12──────
   
   帧号: K   0   1   2   3   4   5   6   7   8   ...
   层:   T0  T0  T1  T2  T1  T0  T1  T2  T1  T0  ...
   
   模式周期 (GOP = 4 帧):
   T0 → T2 → T1 → T2 → T0 → T2 → T1 → T2 → T0 → ...

更详细的依赖关系图：

.. code-block:: text

   T2:     ·   2   ·   6   ·   10  ·   14  ·
               |       |       |       |
               ↓       ↓       ↓       ↓
   T1:     · 1 · · 3 5 · · 7 9 · · 11 13 · ·
             |     |   |     |   |      |
             ↓     ↓   ↓     ↓   ↓      ↓
   T0:   K─→0─────→4─────→8─────→12────→16──→
   
   箭头方向表示 "被参考" 关系:
   - T0 帧只参考前一个 T0 帧
   - T1 帧参考相邻的 T0 帧
   - T2 帧参考相邻的 T1 帧

**降级策略：**

1. 丢弃 T2 层: 30fps → 15fps，码率降低约 20-25%
2. 丢弃 T2 + T1 层: 30fps → 7.5fps，码率降低约 50-60%

**码率分配（典型值）：**

- T0 层: ~50% 的总码率
- T1 层: ~30% 的总码率
- T2 层: ~20% 的总码率


4 个时间层 (T0, T1, T2, T3)
-----------------------------

4 个时间层提供最精细的帧率控制，但在实际应用中较少使用。
假设目标帧率为 30fps（或 60fps 场景下更常见）：

- **T0 层**: 3.75fps (或 7.5fps)
- **T0 + T1 层**: 7.5fps (或 15fps)
- **T0 + T1 + T2 层**: 15fps (或 30fps)
- **T0 + T1 + T2 + T3 层**: 30fps (或 60fps)

GOP 周期为 8 帧，帧的层分配模式为：

.. code-block:: text

   帧序号:  0    1    2    3    4    5    6    7    8    ...
   层:      T0   T3   T2   T3   T1   T3   T2   T3   T0   ...

4 个时间层的依赖关系更加复杂，但遵循相同的原则：
低层帧不依赖高层帧，高层帧可以依赖低层帧。


VP8 时间可伸缩性
===========================

VP8 是最早在 WebRTC 中支持时间可伸缩性的编解码器。
虽然 VP8 不支持完整的 SVC（没有空间可伸缩性），
但它通过灵活的参考帧管理实现了时间可伸缩性。

VP8 Payload Descriptor 中的相关字段
-----------------------------------------

VP8 RTP payload descriptor 中包含以下与时间可伸缩性相关的字段：

.. code-block:: text

   VP8 Payload Descriptor (扩展格式):
   
    0 1 2 3 4 5 6 7
   +-+-+-+-+-+-+-+-+
   |X|R|N|S|R| PID |  第一个字节
   +-+-+-+-+-+-+-+-+
   |I|L|T|K| RSV   |  X=1 时的扩展字节
   +-+-+-+-+-+-+-+-+
   |M| PictureID   |  I=1 时
   +-+-+-+-+-+-+-+-+
   |   PictureID   |  M=1 时 (16-bit PictureID)
   +-+-+-+-+-+-+-+-+
   |   TL0PICIDX   |  L=1 时
   +-+-+-+-+-+-+-+-+
   |TID|Y| KEYIDX  |  T=1 或 K=1 时
   +-+-+-+-+-+-+-+-+

关键字段说明：

- **TID (Temporal Layer Index, 2 bits)**: 当前帧所属的时间层索引
  - ``00``: T0 (基础层)
  - ``01``: T1
  - ``10``: T2
  - ``11``: T3

- **TL0PICIDX (8 bits)**: T0 层的图片索引计数器。
  每当编码一个 T0 帧时，该值递增。
  SFU 可以通过比较 TL0PICIDX 来判断帧的时间顺序和依赖关系。

- **Y (Layer Sync, 1 bit)**: 层同步标志。
  当 Y=1 时，表示当前帧只依赖 T0 层的帧，
  可以作为高层帧的解码起始点（即 SFU 可以从此帧开始转发高层帧）。

- **KEYIDX (Key Frame Index, 5 bits)**: 关键帧索引。

**SFU 如何使用这些字段：**

1. SFU 解析每个 RTP 包的 VP8 payload descriptor
2. 根据 TID 字段判断帧所属的时间层
3. 根据接收端的带宽条件，决定转发哪些层的帧
4. 使用 TL0PICIDX 确保帧的连续性
5. 使用 Y (Layer Sync) 标志确定安全的层切换点

VP8 参考帧管理
-----------------------------

VP8 有 3 个参考帧缓冲区：

- **Last Frame**: 最近的参考帧
- **Golden Frame**: 长期参考帧
- **AltRef Frame**: 备用参考帧

在时间可伸缩性模式下，这些参考帧缓冲区被精心管理：

**2 层模式的参考帧管理：**

.. code-block:: text

   T0 帧: 参考 Last Frame (前一个 T0 帧)
          更新 Last Frame 和 Golden Frame
   
   T1 帧: 参考 Golden Frame (最近的 T0 帧)
          不更新任何参考帧缓冲区（或只更新 AltRef）

这样确保了 T0 帧之间的参考链不经过 T1 帧。

**3 层模式的参考帧管理：**

.. code-block:: text

   T0 帧: 参考 Last Frame (前一个 T0 帧)
          更新 Last Frame 和 Golden Frame
   
   T1 帧: 参考 Golden Frame (最近的 T0 帧)
          更新 AltRef Frame
   
   T2 帧: 参考 AltRef Frame (最近的 T1 帧) 或 Golden Frame (最近的 T0 帧)
          不更新任何参考帧缓冲区

libvpx 配置
-----------------------------

在 libvpx 中配置 VP8 时间可伸缩性：

.. code-block:: c

   // 配置 2 个时间层
   vpx_codec_enc_cfg_t cfg;
   vpx_codec_enc_config_default(vpx_codec_vp8_cx(), &cfg, 0);
   
   cfg.g_threads = 4;
   cfg.rc_target_bitrate = 1000;  // 1000 kbps
   
   // 时间可伸缩性配置
   cfg.ts_number_layers = 2;
   cfg.ts_periodicity = 2;
   cfg.ts_layer_id[0] = 0;  // 第 1 帧: T0
   cfg.ts_layer_id[1] = 1;  // 第 2 帧: T1
   
   // 各层目标码率 (累积值)
   cfg.ts_target_bitrate[0] = 600;   // T0: 600 kbps
   cfg.ts_target_bitrate[1] = 1000;  // T0+T1: 1000 kbps
   
   // 各层帧率比例
   cfg.ts_rate_decimator[0] = 2;  // T0: 每 2 帧编码 1 帧
   cfg.ts_rate_decimator[1] = 1;  // T1: 每帧都编码

.. code-block:: c

   // 配置 3 个时间层
   cfg.ts_number_layers = 3;
   cfg.ts_periodicity = 4;
   cfg.ts_layer_id[0] = 0;  // T0
   cfg.ts_layer_id[1] = 2;  // T2
   cfg.ts_layer_id[2] = 1;  // T1
   cfg.ts_layer_id[3] = 2;  // T2
   
   cfg.ts_target_bitrate[0] = 500;   // T0: 500 kbps
   cfg.ts_target_bitrate[1] = 750;   // T0+T1: 750 kbps
   cfg.ts_target_bitrate[2] = 1000;  // T0+T1+T2: 1000 kbps
   
   cfg.ts_rate_decimator[0] = 4;  // T0: 每 4 帧编码 1 帧
   cfg.ts_rate_decimator[1] = 2;  // T1: 每 2 帧编码 1 帧
   cfg.ts_rate_decimator[2] = 1;  // T2: 每帧都编码


VP9 时间可伸缩性
===========================

VP9 对时间可伸缩性的支持更加完善，提供了两种模式：

Flexible Mode
-----------------------------

在 flexible mode 下，每帧可以灵活地指定参考帧，
参考关系通过 VP9 payload descriptor 中的 ``P_DIFF`` 字段显式指定。

优点：

- 参考帧选择更灵活
- 可以实现更复杂的依赖模式
- 适合动态调整层结构

缺点：

- 每帧都需要携带参考帧信息，overhead 较大
- SFU 需要解析每帧的参考关系

Non-Flexible Mode
-----------------------------

在 non-flexible mode 下，参考帧模式通过 Scalability Structure (SS) 预先定义，
SS 在关键帧处发送，描述了整个 GOP 的帧依赖模式。

VP9 payload descriptor 中的 SS 字段：

.. code-block:: text

   Scalability Structure (SS):
   
   +-+-+-+-+-+-+-+-+
   |N_S|Y|G|  RSV  |
   +-+-+-+-+-+-+-+-+
   (如果 Y=1) 每个空间层的分辨率
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |        WIDTH[i]               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |        HEIGHT[i]              |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   (如果 G=1) PG 描述
   +-+-+-+-+-+-+-+-+
   |  N_G          |  GOP 中的图片数量
   +-+-+-+-+-+-+-+-+
   对每个图片:
   +-+-+-+-+-+-+-+-+
   |TID|U|R| RSV   |
   +-+-+-+-+-+-+-+-+
   (如果 R>0) 参考帧索引
   +-+-+-+-+-+-+-+-+
   |  P_DIFF[j]    |
   +-+-+-+-+-+-+-+-+

- **N_S**: 空间层数量减 1
- **Y**: 是否包含分辨率信息
- **G**: 是否包含 PG (Picture Group) 描述
- **N_G**: GOP 中的图片数量
- **TID**: 时间层 ID
- **U**: 是否可以作为上层切换点 (switching up point)
- **R**: 参考帧数量
- **P_DIFF**: 参考帧的帧号差值

优点：

- overhead 较小，只在关键帧处发送 SS
- SFU 可以预先了解整个 GOP 的依赖结构

缺点：

- 灵活性较低，GOP 内的依赖模式固定


SFU 中的时间层转发
===========================

选择性转发策略
-----------------------------

SFU 根据接收端的可用带宽，选择性地转发不同数量的时间层：

.. code-block:: text

   发送端 (30fps, 3 temporal layers)
   ┌──────────────────────────────────────────────┐
   │ T0  T2  T1  T2  T0  T2  T1  T2  T0  T2 ... │
   │ 7.5fps        15fps           30fps          │
   └──────────────────────────────────────────────┘
                        │
                        ↓
                   ┌─────────┐
                   │   SFU   │
                   └─────────┘
                   ╱    │    ╲
                  ╱     │     ╲
                 ↓      ↓      ↓
   接收端 A     接收端 B     接收端 C
   (高带宽)     (中带宽)     (低带宽)
   T0+T1+T2    T0+T1        T0
   30fps       15fps        7.5fps

层丢弃策略
-----------------------------

当需要降低码率时，应该按照从高到低的顺序丢弃时间层：

1. **首先丢弃最高层 (T2)**: 帧率从 30fps 降为 15fps
   - 码率降低约 20-25%
   - 用户感知：轻微的流畅度下降，通常可以接受

2. **然后丢弃次高层 (T1)**: 帧率从 15fps 降为 7.5fps
   - 码率再降低约 25-30%
   - 用户感知：明显的卡顿感，但画面仍然可用

3. **最后保留基础层 (T0)**: 仅 7.5fps
   - 仅保留约 50% 的码率
   - 用户感知：严重卡顿，但至少有画面

**帧率降级对照表：**

.. list-table:: 时间层丢弃与帧率变化
   :header-rows: 1
   :widths: 25 20 20 20 15

   * - 转发的层
     - 原始 30fps
     - 原始 24fps
     - 原始 60fps
     - 码率占比
   * - T0 + T1 + T2
     - 30 fps
     - 24 fps
     - 60 fps
     - 100%
   * - T0 + T1
     - 15 fps
     - 12 fps
     - 30 fps
     - ~75-80%
   * - T0 only
     - 7.5 fps
     - 6 fps
     - 15 fps
     - ~50%

**平滑降级的优势：**

与直接降低编码帧率相比，时间层丢弃有以下优势：

1. **即时生效**: SFU 可以立即开始丢弃高层帧，无需等待编码器重新配置
2. **无需信令**: 不需要通知发送端修改编码参数
3. **可逆性**: 当带宽恢复时，SFU 可以立即恢复转发高层帧
4. **独立控制**: 每个接收端可以独立地接收不同数量的时间层


WebRTC API 配置
===========================

scalabilityMode 参数
-----------------------------

在 WebRTC 中，通过 ``RTCRtpEncodingParameters`` 的 ``scalabilityMode`` 属性配置时间可伸缩性：

.. code-block:: javascript

   // 2 个时间层
   const transceiver = pc.addTransceiver(videoTrack, {
     direction: 'sendonly',
     sendEncodings: [{
       scalabilityMode: 'L1T2',  // 1 个空间层, 2 个时间层
       maxBitrate: 1000000,
       maxFramerate: 30
     }]
   });

.. code-block:: javascript

   // 3 个时间层
   const transceiver = pc.addTransceiver(videoTrack, {
     direction: 'sendonly',
     sendEncodings: [{
       scalabilityMode: 'L1T3',  // 1 个空间层, 3 个时间层
       maxBitrate: 1500000,
       maxFramerate: 30
     }]
   });

.. code-block:: javascript

   // Simulcast 中每路流使用时间可伸缩性
   const transceiver = pc.addTransceiver(videoTrack, {
     direction: 'sendonly',
     sendEncodings: [
       {rid: 'low',  scaleResolutionDownBy: 4.0, scalabilityMode: 'L1T3'},
       {rid: 'mid',  scaleResolutionDownBy: 2.0, scalabilityMode: 'L1T3'},
       {rid: 'high', scalabilityMode: 'L1T3'}
     ]
   });

**动态修改时间层数量：**

.. code-block:: javascript

   const sender = transceiver.sender;
   const params = sender.getParameters();
   
   // 从 3 个时间层切换到 2 个时间层
   params.encodings[0].scalabilityMode = 'L1T2';
   await sender.setParameters(params);


WebRTC 编码器封装中的实现
===========================

在 Chrome/libwebrtc 的实现中，时间可伸缩性通过编码器封装层 (encoder wrapper) 来管理：

**VP8 编码器封装 (VP8EncoderImpl)：**

1. 根据 ``scalabilityMode`` 配置 libvpx 的时间层参数
2. 在每帧编码前，设置当前帧的时间层 ID
3. 编码后，在 RTP payload descriptor 中填入 TID 和 TL0PICIDX
4. 管理参考帧缓冲区的更新策略

**VP9 编码器封装 (VP9EncoderImpl)：**

1. 根据 ``scalabilityMode`` 配置 libvpx 的 SVC 参数
2. 使用 ``vpx_svc_extra_cfg_t`` 结构配置层间依赖关系
3. 在关键帧处生成 Scalability Structure (SS)
4. 通过 Dependency Descriptor RTP header extension 传递帧依赖信息

**关键代码路径 (libwebrtc)：**

.. code-block:: text

   VideoStreamEncoder::EncodeVideoFrame()
     → VP8EncoderImpl::Encode()
       → vpx_codec_encode() (libvpx)
       → 设置 CodecSpecificInfoVP8::temporalIdx
     → RtpVideoSender::OnEncodedImage()
       → RtpSenderVideo::SendVideo()
         → 填充 VP8 payload descriptor (TID, TL0PICIDX)
         → 填充 Dependency Descriptor header extension


与拥塞控制的交互
===========================

时间可伸缩性与 WebRTC 的拥塞控制 (Congestion Control) 紧密配合：

**发送端拥塞控制触发层变化：**

.. code-block:: text

   GCC 检测到带宽下降
     → BitrateAllocator 降低目标码率
     → VideoStreamEncoder 调整编码参数
       → 可能减少时间层数量 (如 L1T3 → L1T2)
       → 或降低各层的码率分配

**SFU 端的带宽适配：**

.. code-block:: text

   SFU 检测到接收端带宽下降 (通过 REMB 或 transport-cc)
     → 决定减少转发的时间层数量
     → 立即停止转发高层帧
     → 接收端帧率降低，但不会出现花屏

**两种机制的配合：**

1. **快速响应**: SFU 端的时间层丢弃可以在毫秒级别生效
2. **精细调整**: 发送端的编码器调整可以在秒级别优化码率分配
3. **协同工作**: SFU 先丢弃高层帧快速降低码率，
   然后发送端根据反馈调整编码参数，最终达到最优的码率-质量平衡

**典型的适配流程：**

.. code-block:: text

   t=0s:  网络带宽突然下降
   t=0.1s: SFU 检测到接收端 NACK 增加或 transport-cc 反馈延迟增大
   t=0.2s: SFU 开始丢弃 T2 层帧 (30fps → 15fps)
   t=0.5s: 发送端收到 REMB 或 transport-cc 反馈，GCC 降低目标码率
   t=1.0s: 编码器调整码率分配，降低各层码率
   t=2.0s: 如果带宽继续不足，SFU 进一步丢弃 T1 层 (15fps → 7.5fps)
   t=5.0s: 网络带宽恢复
   t=5.1s: SFU 恢复转发 T1 层 (7.5fps → 15fps)
   t=5.5s: GCC 逐步提高目标码率
   t=6.0s: SFU 恢复转发 T2 层 (15fps → 30fps)


参考
==========================
* [1] "Advanced Video Coding for Generic Audiovisual Services," ITU-T, Tech. Rep. Recommendation H.264 & ISO/IEC 14496-10 AVC, v3, 2005.
* [2] J. Ostermann, J. Bormans, P. List, D. Marpe, N. Narroschke, F. Pereira, T. Stockhammer, and T. Wedi, "Video Coding with H.264/AVC: Tools, Performance and Complexity," IEEE Circuits and Systems Magazine, vol.4, no.1, pp. 7-28, April 2004.
* [3] H. Schwarz, D. Marpe, and T. Wiegand, "Overview of the Scalable Video Coding Extension of the H.264/AVC Standard," IEEE Transactions on Circuits and Systems for Video Technology, vol.17, no.9, pp. 1103-1120, September 2007.
* [4] "Advanced Video Coding for Generic Audiovisual Services, Annex G," ITU-T, Tech. Rep. Recommendation H.264 & ISO/IEC 14496-10 AVC/Amd.3 Scalable Video Coding, November 2007.
* [5] https://www.w3.org/TR/webrtc-svc/ — WebRTC Scalable Video Coding
* [6] https://datatracker.ietf.org/doc/html/rfc7741 — RTP Payload Format for VP8 Video
* [7] https://datatracker.ietf.org/doc/html/draft-ietf-payload-vp9 — RTP Payload Format for VP9 Video
* [8] https://webrtc.googlesource.com/src/ — WebRTC/libwebrtc 源码
