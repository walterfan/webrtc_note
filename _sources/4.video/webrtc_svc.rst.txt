################################
WebRTC SVC
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** WebRTC SVC
**Category** Learning note
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ =============================



.. contents::
   :local:


概述
===========================

SVC (Scalable Video Coding，可伸缩视频编码) 是一种视频编码技术，
它将视频编码为一个基础层（base layer）和一个或多个增强层（enhancement layers）。
接收端可以根据自身的网络带宽、处理能力和显示分辨率，选择性地解码不同数量的层，
从而获得不同质量级别的视频。

SVC 在 WebRTC 中的应用尤为重要，特别是在多方视频会议场景中。
SFU (Selective Forwarding Unit) 可以根据每个接收端的条件，
选择性地转发不同的层，而无需进行转码（transcoding），大大降低了服务器的计算开销。

SVC 提供三种维度的可伸缩性：

**空间可伸缩性 (Spatial Scalability)**

空间可伸缩性允许在不同分辨率之间进行伸缩。基础层编码低分辨率视频，
增强层在基础层的基础上提供更高分辨率的信息。

例如：基础层 320x180，增强层 1 为 640x360，增强层 2 为 1280x720。

**时间可伸缩性 (Temporal Scalability)**

时间可伸缩性允许在不同帧率之间进行伸缩。基础层包含关键帧和低帧率的参考帧，
增强层提供额外的帧以提高帧率。

例如：基础层 7.5fps，增强层 1 为 15fps，增强层 2 为 30fps。

**质量可伸缩性 (Quality/SNR Scalability)**

质量可伸缩性（也称为 SNR 可伸缩性）允许在相同分辨率和帧率下提供不同的画质。
基础层提供较低质量的视频，增强层提供额外的细节信息以提高画质。


Terminology
==========================

* **SST**: Single-Session Transmission — 单会话传输，所有 SVC 层在一个 RTP 会话中传输，参见 `RFC6190`_
* **MST**: Multi-Session Transmission — 多会话传输，不同 SVC 层在不同 RTP 会话中传输，参见 `RFC6190`_
* **Base Layer**: 基础层，可以独立解码的最低质量层
* **Enhancement Layer**: 增强层，依赖基础层，提供更高质量
* **Dependency Descriptor (DD)**: 依赖描述符，描述帧之间的依赖关系
* **SFU**: Selective Forwarding Unit，选择性转发单元
* **Simulcast**: 同时发送多个独立编码的视频流（不同分辨率/帧率）


SVC 与 Simulcast 对比
===========================

在 WebRTC 多方会议中，SVC 和 Simulcast 是两种主要的多层视频传输方案。
它们各有优劣：

.. list-table:: SVC 与 Simulcast 对比
   :header-rows: 1
   :widths: 20 40 40

   * - 特性
     - SVC
     - Simulcast
   * - 编码方式
     - 单个编码器输出分层码流
     - 多个独立编码器分别编码
   * - 带宽效率
     - 较高，层间共享信息，总带宽约为最高层的 1.2-1.5 倍
     - 较低，各流独立编码，总带宽约为最高流的 2-3 倍
   * - 编码复杂度
     - 较高，需要支持分层编码
     - 较低，使用标准编码器即可
   * - 解码复杂度
     - 较高，需要支持分层解码
     - 较低，标准解码器即可
   * - SFU 支持
     - 需要理解 SVC 层结构
     - 简单，直接转发不同的流
   * - 层切换延迟
     - 可能需要等待关键帧
     - 可以在关键帧处切换
   * - 灵活性
     - 层数和参数在编码时确定
     - 可以灵活配置各流参数
   * - 错误恢复
     - 基础层丢失影响所有层
     - 各流独立，互不影响
   * - 编解码器支持
     - VP9, AV1 支持较好; H.264 有限
     - VP8, VP9, H.264, AV1 均支持

**选择建议：**

- 带宽受限场景：优先选择 SVC，因为带宽效率更高
- SFU 部署简单性：优先选择 Simulcast，SFU 实现更简单
- 大规模会议：SVC + SFU 组合可以在保持低带宽的同时支持多种接收端
- 兼容性要求高：Simulcast 兼容性更好，几乎所有编解码器都支持


VP9 SVC in WebRTC
===========================

VP9 是 WebRTC 中 SVC 支持最成熟的编解码器。它原生支持空间和时间可伸缩性，
并且在 Chrome/libwebrtc 中有完整的实现。

Scalability Modes
-----------------------------

WebRTC 定义了一套标准化的 scalability mode 标识符，用于描述 SVC 的层结构。
命名规则为 ``L<spatial_layers>T<temporal_layers>`` 或 ``S<simulcast_streams>T<temporal_layers>``：

- **L** 前缀表示 SVC 空间层（层间有依赖关系）
- **S** 前缀表示 Simulcast 流（流间无依赖关系，但可以使用 K-SVC 的帧间预测）
- 第一个数字表示空间层/流的数量
- **T** 后面的数字表示时间层的数量

常用的 scalability modes：

.. list-table:: VP9 Scalability Modes
   :header-rows: 1
   :widths: 15 20 20 45

   * - Mode
     - 空间层
     - 时间层
     - 描述
   * - L1T1
     - 1
     - 1
     - 无可伸缩性，单层编码
   * - L1T2
     - 1
     - 2
     - 仅时间可伸缩性，2 个时间层
   * - L1T3
     - 1
     - 3
     - 仅时间可伸缩性，3 个时间层
   * - L2T1
     - 2
     - 1
     - 2 个空间层，无时间可伸缩性
   * - L2T2
     - 2
     - 2
     - 2 个空间层 × 2 个时间层 = 4 个可选层
   * - L2T3
     - 2
     - 3
     - 2 个空间层 × 3 个时间层 = 6 个可选层
   * - L3T1
     - 3
     - 1
     - 3 个空间层，无时间可伸缩性
   * - L3T2
     - 3
     - 2
     - 3 个空间层 × 2 个时间层 = 6 个可选层
   * - L3T3
     - 3
     - 3
     - 3 个空间层 × 3 个时间层 = 9 个可选层
   * - S2T1
     - 2 (Simulcast)
     - 1
     - 2 路 Simulcast，无时间可伸缩性
   * - S2T3
     - 2 (Simulcast)
     - 3
     - 2 路 Simulcast，各路 3 个时间层
   * - S3T3
     - 3 (Simulcast)
     - 3
     - 3 路 Simulcast，各路 3 个时间层

**L2T3 层结构示例：**

.. code-block:: text

   空间层 1 (高分辨率):  S1T0  S1T1  S1T2  S1T0  S1T1  S1T2  ...
                           ↑     ↑     ↑     ↑     ↑     ↑
   空间层 0 (低分辨率):  S0T0  S0T1  S0T2  S0T0  S0T1  S0T2  ...

   时间层:               T0    T1    T2    T0    T1    T2
   帧率:                 7.5   15    30    7.5   15    30

SFU 可以根据接收端的带宽选择转发不同的层组合：

- 带宽充足：转发 S1T2（高分辨率 + 高帧率）
- 带宽中等：转发 S0T2（低分辨率 + 高帧率）或 S1T0（高分辨率 + 低帧率）
- 带宽不足：转发 S0T0（低分辨率 + 低帧率）


Dependency Descriptor (DD)
-----------------------------

Dependency Descriptor (DD) 是一种 RTP header extension，
用于描述 SVC 帧之间的依赖关系。它使得 SFU 无需解析视频码流本身，
就能理解帧的层结构和依赖关系，从而做出正确的转发决策。

DD 的设计目标：

1. **编解码器无关 (Codec-agnostic)**: 适用于 VP9、AV1 等任何支持 SVC 的编解码器
2. **SFU 友好**: SFU 只需解析 RTP header extension，无需解析 payload
3. **高效编码**: 使用紧凑的二进制格式，最小化 header overhead

DD 包含以下关键信息：

- **Frame number**: 帧编号
- **Frame dependencies**: 当前帧依赖的其他帧
- **Decode target indications**: 当前帧对各个 decode target 的贡献
- **Chain information**: 用于确定层切换点

**DD 在 RTP Header Extension 中的位置：**

DD 通过 SDP 协商，使用如下 URI 标识：

.. code-block::

   a=extmap:11 https://aomediacodec.github.io/av1-rtp-spec/#dependency-descriptor-rtp-header-extension

**Frame Dependency Structure：**

DD 定义了一个 Frame Dependency Structure，描述了帧的重复模式（template）。
每个 template 包含：

- 空间层 ID 和时间层 ID
- 依赖的帧偏移列表（DTI - Decode Target Indication）
- Chain diff 信息

在关键帧处，DD 会携带完整的 structure 描述；
在非关键帧处，DD 只需携带 template index 和 frame number，大大减少了 overhead。


AV1 SVC 支持
===========================

AV1 是新一代开源视频编解码器，由 Alliance for Open Media (AOMedia) 开发。
AV1 原生支持 SVC，并且在 WebRTC 中的支持正在快速完善。

AV1 SVC 的特点：

- **更好的压缩效率**: 相比 VP9，AV1 在相同质量下可以节省 20-30% 的带宽
- **原生 SVC 支持**: AV1 规范中内置了 SVC 支持
- **Dependency Descriptor**: AV1 使用与 VP9 相同的 DD RTP header extension
- **灵活的参考帧管理**: AV1 支持最多 7 个参考帧，为 SVC 提供了更灵活的帧间预测

AV1 SVC 支持的 scalability modes 与 VP9 类似，包括 L1T2、L1T3、L2T1、L2T2、L2T3、L3T3 等。

**AV1 SVC 在 WebRTC 中的配置：**

.. code-block:: javascript

   const sender = pc.addTransceiver(videoTrack, {
     direction: 'sendonly',
     sendEncodings: [{
       scalabilityMode: 'L2T3',
       codec: {mimeType: 'video/AV1'}
     }]
   });


H.264 SVC 支持
===========================

H.264 SVC (也称为 H.264/SVC 或 Annex G) 定义在 H.264 标准的附录 G 中。
然而，H.264 SVC 在 WebRTC 中的支持非常有限：

- **硬件支持不足**: 大多数硬件编解码器不支持 H.264 SVC
- **专利问题**: H.264 SVC 涉及额外的专利许可
- **复杂度高**: H.264 SVC 的实现复杂度远高于 VP9/AV1 SVC
- **WebRTC 实现**: Chrome/libwebrtc 中 H.264 主要支持时间可伸缩性（temporal scalability），
  不支持完整的空间可伸缩性

在实际应用中，如果需要使用 H.264 进行多层传输，通常采用 Simulcast 方案而非 SVC。


SFU 中的 SVC 转发
===========================

SFU (Selective Forwarding Unit) 是 WebRTC 多方会议中最常用的服务器架构。
SVC 与 SFU 的结合可以实现高效的带宽适配：

选择性层转发
-----------------------------

SFU 根据每个接收端的条件，选择性地转发 SVC 码流中的不同层：

.. code-block:: text

   发送端                    SFU                     接收端 A (高带宽)
   ┌──────┐                ┌──────┐                 ┌──────┐
   │      │  L2T3 全部层   │      │  S1T2 (全部)    │      │
   │ VP9  │ ─────────────→ │      │ ───────────────→ │ 720p │
   │ SVC  │                │      │                  │ 30fps│
   │      │                │      │                  └──────┘
   │      │                │      │
   │      │                │      │                  接收端 B (中等带宽)
   │      │                │      │  S0T2 (低分辨率) ┌──────┐
   │      │                │      │ ───────────────→ │ 360p │
   │      │                │      │                  │ 30fps│
   └──────┘                │      │                  └──────┘
                           │      │
                           │      │                  接收端 C (低带宽)
                           │      │  S0T0 (最低层)   ┌──────┐
                           │      │ ───────────────→ │ 360p │
                           └──────┘                  │ 7.5fps│
                                                     └──────┘

**带宽节省分析：**

假设发送端编码 L2T3 VP9 SVC，最高层为 720p@30fps，目标码率 1.5 Mbps：

- SVC 总发送带宽: ~1.8 Mbps（基础层 + 增强层，约为最高层的 1.2 倍）
- Simulcast 总发送带宽: ~3.5 Mbps（720p + 360p + 180p 三路独立编码）
- 带宽节省: 约 48%

层切换策略
-----------------------------

SFU 在进行层切换时需要注意以下问题：

1. **向上切换 (Switch Up)**: 从低层切换到高层时，需要等待高层的关键帧或可解码点
2. **向下切换 (Switch Down)**: 从高层切换到低层通常可以立即进行
3. **切换延迟**: 层切换可能引入短暂的延迟，特别是向上切换时
4. **Chain 机制**: DD 中的 chain 信息帮助 SFU 确定安全的切换点

**使用 DD 进行层切换的流程：**

1. SFU 监控接收端的带宽变化
2. 决定切换到目标层
3. 检查 DD 中的 decode target indication，找到目标层的可解码帧
4. 从该帧开始转发目标层的数据
5. 停止转发旧层的数据


WebRTC 中的 SVC 配置
===========================

RTCRtpEncodingParameters
-----------------------------

WebRTC API 通过 ``RTCRtpEncodingParameters`` 的 ``scalabilityMode`` 属性来配置 SVC：

.. code-block:: javascript

   // 单流 SVC 配置
   const transceiver = pc.addTransceiver(videoTrack, {
     direction: 'sendonly',
     sendEncodings: [{
       scalabilityMode: 'L3T3',
       maxBitrate: 2500000,
       maxFramerate: 30
     }]
   });

.. code-block:: javascript

   // Simulcast + SVC 组合配置
   // 每路 Simulcast 流内部使用时间可伸缩性
   const transceiver = pc.addTransceiver(videoTrack, {
     direction: 'sendonly',
     sendEncodings: [
       {rid: 'q', scaleResolutionDownBy: 4.0, scalabilityMode: 'L1T3'},
       {rid: 'h', scaleResolutionDownBy: 2.0, scalabilityMode: 'L1T3'},
       {rid: 'f', scalabilityMode: 'L1T3'}
     ]
   });

**动态修改 scalabilityMode：**

.. code-block:: javascript

   const sender = transceiver.sender;
   const params = sender.getParameters();
   params.encodings[0].scalabilityMode = 'L2T3';
   await sender.setParameters(params);

SDP 协商
-----------------------------

SVC 的 scalability mode 信息会反映在 SDP 中。以下是一个典型的 SDP 片段：

.. code-block::

   m=video 9 UDP/TLS/RTP/SAVPF 96 97
   a=rtpmap:96 VP9/90000
   a=fmtp:96 profile-id=0
   a=rtpmap:97 AV1/90000
   a=extmap:11 https://aomediacodec.github.io/av1-rtp-spec/#dependency-descriptor-rtp-header-extension

完整的 JavaScript 示例
-----------------------------

以下是一个完整的 WebRTC SVC 配置示例：

.. code-block:: javascript

   const signaling = new SignalingChannel(); // handles JSON.stringify/parse
   const constraints = {audio: true, video: true};
   const configuration = {'iceServers': [{'urls': 'stun:stun.example.org'}]};
   let pc;

   // call start() to initiate
   async function start() {
     pc = new RTCPeerConnection(configuration);

     // let the "negotiationneeded" event trigger offer generation
     pc.onnegotiationneeded = async () => {
       try {
         await pc.setLocalDescription();
         // send the offer to the other peer
         signaling.send({description: pc.localDescription});
       } catch (err) {
         console.error(err);
       }
     };

     try {
       // get a local stream, show it in a self-view and add it to be sent
       const stream = await navigator.mediaDevices.getUserMedia(constraints);
       selfView.srcObject = stream;
       pc.addTransceiver(stream.getAudioTracks()[0], {direction: 'sendonly'});
       pc.addTransceiver(stream.getVideoTracks()[0], {
         direction: 'sendonly',
         sendEncodings: [
           {rid: 'q', scaleResolutionDownBy: 4.0, scalabilityMode: 'L1T3'},
           {rid: 'h', scaleResolutionDownBy: 2.0, scalabilityMode: 'L1T3'},
           {rid: 'f', scalabilityMode: 'L1T3'},
         ]
       });
     } catch (err) {
       console.error(err);
     }
   }

   signaling.onmessage = async ({data: {description, candidate}}) => {
     try {
       if (description) {
         await pc.setRemoteDescription(description);
         // if we got an offer, we need to reply with an answer
         if (description.type == 'offer') {
           await pc.setLocalDescription();
           signaling.send({description: pc.localDescription});
         }
       } else if (candidate) {
         await pc.addIceCandidate(candidate);
       }
     } catch (err) {
       console.error(err);
     }
   };


性能对比：SVC vs Simulcast
===========================

以下是在不同带宽条件下，SVC 和 Simulcast 的性能对比：

.. list-table:: 不同带宽下的表现对比
   :header-rows: 1
   :widths: 20 40 40

   * - 可用带宽
     - SVC (L3T3)
     - Simulcast (3 路)
   * - 2.5 Mbps+
     - 720p@30fps，最高质量
     - 720p@30fps，最高质量
   * - 1.0-2.5 Mbps
     - 720p@15fps 或 360p@30fps
     - 360p@30fps（切换到中等流）
   * - 0.5-1.0 Mbps
     - 360p@15fps
     - 360p@15fps（中等流降帧率）
   * - 0.2-0.5 Mbps
     - 180p@15fps 或 360p@7.5fps
     - 180p@30fps（切换到低流）
   * - <0.2 Mbps
     - 180p@7.5fps
     - 180p@7.5fps（低流降帧率）

**关键观察：**

1. 在高带宽下，两者表现相当
2. 在中等带宽下，SVC 提供更平滑的降级体验
3. SVC 的带宽利用率更高，因为层间共享编码信息
4. Simulcast 的层切换更简单，延迟更低


挑战与限制
===========================

解码器复杂度
-----------------------------

SVC 解码比单层解码更复杂：

- 空间可伸缩性需要上采样（upsampling）和层间预测
- 解码器需要同时维护多个参考帧缓冲区
- 在低端设备上可能导致解码延迟增加

错误恢复
-----------------------------

SVC 的层间依赖关系使得错误恢复更加复杂：

- 基础层的丢包会影响所有增强层的解码
- 需要更复杂的错误隐藏（error concealment）策略
- 关键帧的大小更大（包含所有层的关键帧数据）

层切换延迟
-----------------------------

在 SFU 场景中，层切换可能引入延迟：

- 向上切换需要等待可解码点（通常是关键帧或特定的帧模式）
- K-SVC (Key-frame SVC) 模式可以减少切换延迟，但牺牲了一些压缩效率
- DD 中的 chain 机制帮助 SFU 找到最优的切换点

编解码器支持
-----------------------------

不同编解码器对 SVC 的支持程度不同：

.. list-table:: 编解码器 SVC 支持情况
   :header-rows: 1
   :widths: 15 20 20 20 25

   * - 编解码器
     - 时间可伸缩性
     - 空间可伸缩性
     - 质量可伸缩性
     - WebRTC 支持状态
   * - VP8
     - ✓
     - ✗
     - ✗
     - 仅时间层
   * - VP9
     - ✓
     - ✓
     - ✗
     - 完整支持
   * - AV1
     - ✓
     - ✓
     - ✗
     - 逐步完善中
   * - H.264
     - ✓ (有限)
     - ✗ (WebRTC 中)
     - ✗
     - 仅时间层
   * - H.265
     - ✓
     - ✓
     - ✓
     - WebRTC 中尚未广泛支持


参考
===========================
* https://www.w3.org/TR/webrtc-svc/
* `RFC6190`_: RTP Payload Format for Scalable Video Coding
* https://aomediacodec.github.io/av1-rtp-spec/ — AV1 RTP Payload Format
* https://webrtc.googlesource.com/src/ — WebRTC 源码
* https://www.w3.org/TR/webrtc/#dom-rtcrtpencodingparameters-scalabilitymode — ScalabilityMode API
* draft-ietf-avtext-framemarking — Frame Marking RTP Header Extension
* Dependency Descriptor RTP Header Extension: https://aomediacodec.github.io/av1-rtp-spec/#dependency-descriptor-rtp-header-extension
