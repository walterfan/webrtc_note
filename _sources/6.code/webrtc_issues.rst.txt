####################
WebRTC issues
####################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC 常见问题与排查
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

FAQ
=============

首帧延迟过大
------------------------------------------------

路径: sender → SFU → receiver（无 TURN 中继时）

常见原因：

1. **GOP 太大**：如果编码器 GOP 设为 10 秒，接收方必须等到下一个关键帧才能开始解码。
   WebRTC 场景建议 GOP 设为 1~2 秒（即 ``keyint = framerate * 2``）。

2. **关键帧请求延迟**：接收方通过 PLI/FIR 请求关键帧，但 RTCP 反馈的传输本身有延迟。

3. **ICE 连接建立慢**：候选收集或 STUN/TURN 协商耗时。可通过 ``iceServers`` 配置
   和 ``iceCandidatePoolSize`` 提前收集来优化。

4. **DTLS 握手**：首次建立 SRTP 密钥需要 DTLS 握手，增加 1~2 个 RTT。

.. code-block:: javascript

   // 提前收集 ICE 候选，减少首帧延迟
   const pc = new RTCPeerConnection({
       iceServers: [{ urls: 'stun:stun.l.google.com:19302' }],
       iceCandidatePoolSize: 2
   });


音视频不同步
------------------------------------------------

可能原因：

1. **发送端时间戳错误**：音频和视频使用不同的 NTP 时钟基准，SR 包中的 NTP/RTP 映射不正确。

2. **接收端 Jitter Buffer 策略不一致**：音频和视频的 jitter buffer 深度差异过大。

3. **SFU 转发延迟不一致**：音频和视频通过不同路径或不同优先级转发。

排查方法：

.. code-block:: javascript

   // 通过 getStats 检查音视频的 jitterBufferDelay
   const stats = await pc.getStats();
   stats.forEach(report => {
       if (report.type === 'inbound-rtp') {
           console.log(`${report.kind}: jitterBufferDelay=${report.jitterBufferDelay}, ` +
                        `jitterBufferEmittedCount=${report.jitterBufferEmittedCount}`);
       }
   });


丢包导致画面花屏/卡顿
------------------------------------------------

WebRTC 视频帧之间存在参考关系（P 帧依赖前一帧），单个包丢失可能导致后续多帧无法正确解码。

恢复机制优先级：

1. **NACK 重传**：延迟最低（1 RTT），适合丢包率 < 5% 的场景
2. **FEC 前向纠错**：不增加延迟但消耗带宽，适合丢包率 5~15%
3. **PLI/FIR 关键帧请求**：最后手段，会导致码率突增和画面跳帧

.. code-block:: javascript

   // 监控丢包情况
   const stats = await pc.getStats();
   stats.forEach(report => {
       if (report.type === 'inbound-rtp' && report.kind === 'video') {
           console.log(`packetsLost: ${report.packetsLost}, ` +
                        `packetsReceived: ${report.packetsReceived}, ` +
                        `nackCount: ${report.nackCount}, ` +
                        `pliCount: ${report.pliCount}, ` +
                        `firCount: ${report.firCount}`);
       }
   });


CPU 占用过高导致编码降级
------------------------------------------------

当设备 CPU 负载过高时，WebRTC 编码器会自动降低分辨率或帧率（通过 OveruseFrameDetector）。

表现：

- 视频分辨率突然下降（如 720p → 360p）
- 帧率降低（如 30fps → 15fps）
- 编码延迟增加

排查：

.. code-block:: javascript

   // 监控编码参数变化
   const stats = await pc.getStats();
   stats.forEach(report => {
       if (report.type === 'outbound-rtp' && report.kind === 'video') {
           console.log(`frameWidth: ${report.frameWidth}, ` +
                        `frameHeight: ${report.frameHeight}, ` +
                        `framesPerSecond: ${report.framesPerSecond}, ` +
                        `qualityLimitationReason: ${report.qualityLimitationReason}`);
       }
   });

``qualityLimitationReason`` 的值：

- ``none``：无限制
- ``cpu``：CPU 瓶颈
- ``bandwidth``：带宽不足
- ``other``：其他原因


带宽估计不准导致码率震荡
------------------------------------------------

GCC（Google Congestion Control）算法可能在某些网络条件下出现码率反复升降的问题。

常见场景：

- WiFi 环境下的竞争流量
- 带有大缓冲的网络设备（bufferbloat）
- 跨运营商网络

排查：

.. code-block:: javascript

   // 监控带宽估计和实际码率
   const stats = await pc.getStats();
   stats.forEach(report => {
       if (report.type === 'candidate-pair' && report.nominated) {
           console.log(`availableOutgoingBitrate: ${report.availableOutgoingBitrate}`);
       }
       if (report.type === 'outbound-rtp' && report.kind === 'video') {
           const actualBitrate = report.bytesSent * 8;  // 需要计算差值
           console.log(`targetBitrate: ${report.targetBitrate}`);
       }
   });

也可以通过 ``chrome://webrtc-internals`` 查看 BWE 图表来分析。


回声/啸叫
------------------------------------------------

原因：扬声器输出的音频被麦克风重新采集。

解决方法：

1. 确保 ``echoCancellation`` 约束启用
2. 使用耳机而非外放
3. 检查 AEC（Acoustic Echo Cancellation）是否正常工作

.. code-block:: javascript

   const stream = await navigator.mediaDevices.getUserMedia({
       audio: {
           echoCancellation: true,
           noiseSuppression: true,
           autoGainControl: true
       }
   });


常用调试工具
=============

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - 工具
     - 说明
   * - ``chrome://webrtc-internals``
     - Chrome 内置 WebRTC 调试面板，可查看 SDP、ICE 状态、RTP 统计、BWE 图表等
   * - ``getStats()`` API
     - 程序化获取 WebRTC 统计信息
   * - Wireshark
     - 抓包分析 STUN/DTLS/RTP/RTCP
   * - ``tcpdump``
     - 命令行抓包
   * - Othe third-party tools
     - webrtc-test, testRTC 等在线测试平台
