################################
WebRTC Metrics
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** WebRTC Metrics
**Category** Learning note
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ =============================



.. contents::
   :local:



Overview
======================
WebRTC 提供了 `webrtc_stats`_, 包含了诸多层面的指标, 浏览器提供了 `getStats()` API， Native SDK 需要调用类似的接口。

我们如果要计算在一段区间内的 metrics , 还需要做些计算。因为大多数的指标都是线性增长的，所以要把上一次取得的数据缓存下来，将这一次取得的指标减去上一次的指标

例如:

.. code-block::

    packetsSent = currentPacketsSent - previousPacketsSent

    frameRateReceived = (currentFramesReceived - previousFramesReceived)/(currentTimeMs - previousTimeMs)/1000



.. _webrtc_stats: ../1.basic/webrtc_stats.html


getStats() API 详解
-----------------------

``RTCPeerConnection.getStats()`` 是 WebRTC 中获取实时统计数据的核心 API。它返回一个 Promise，resolve 后得到一个 ``RTCStatsReport`` 对象。

基本用法如下:

.. code-block:: javascript

    const pc = new RTCPeerConnection();

    // 获取所有统计数据
    const stats = await pc.getStats();

    // 遍历所有统计报告
    stats.forEach(report => {
        console.log(`Type: ${report.type}, ID: ${report.id}`);
        console.log(`Timestamp: ${report.timestamp}`);
        console.log(JSON.stringify(report, null, 2));
    });

    // 获取特定 sender 或 receiver 的统计数据
    const senders = pc.getSenders();
    for (const sender of senders) {
        const senderStats = await sender.getStats();
        senderStats.forEach(report => {
            if (report.type === 'outbound-rtp') {
                console.log('Outbound RTP stats:', report);
            }
        });
    }


RTCStatsReport 结构
-----------------------

``RTCStatsReport`` 是一个 Map-like 对象，其中每个条目都是一个 ``RTCStats`` 字典。每个统计报告都包含以下基础字段:

.. list-table:: RTCStats 基础字段
   :header-rows: 1
   :widths: 20 20 60

   * - 字段
     - 类型
     - 说明
   * - ``id``
     - string
     - 统计对象的唯一标识符
   * - ``type``
     - string
     - 统计类型，如 ``inbound-rtp``, ``outbound-rtp``, ``candidate-pair`` 等
   * - ``timestamp``
     - DOMHighResTimeStamp
     - 统计数据采集的时间戳（毫秒）

常见的统计类型包括:

- ``inbound-rtp``: 入站 RTP 流统计
- ``outbound-rtp``: 出站 RTP 流统计
- ``remote-inbound-rtp``: 远端入站 RTP 流统计（来自 RTCP Receiver Report）
- ``remote-outbound-rtp``: 远端出站 RTP 流统计（来自 RTCP Sender Report）
- ``candidate-pair``: ICE 候选对统计
- ``local-candidate``: 本地 ICE 候选统计
- ``remote-candidate``: 远端 ICE 候选统计
- ``media-source``: 媒体源统计
- ``codec``: 编解码器信息
- ``transport``: 传输层统计
- ``data-channel``: 数据通道统计

这些统计类型之间通过 ID 引用相互关联，形成一个完整的统计数据图。例如，``inbound-rtp`` 报告中的 ``codecId`` 字段指向对应的 ``codec`` 报告。


RTCStatsReport 关键指标
============================

RTCInboundRtpStreamStats
-----------------------------

``RTCInboundRtpStreamStats`` 描述了接收端 RTP 流的统计信息，是评估接收质量的核心指标集。

.. list-table:: RTCInboundRtpStreamStats 关键字段
   :header-rows: 1
   :widths: 30 15 55

   * - 字段
     - 类型
     - 说明
   * - ``packetsReceived``
     - unsigned long
     - 已接收的 RTP 包总数
   * - ``bytesReceived``
     - unsigned long long
     - 已接收的 RTP 负载字节总数（不含头部和填充）
   * - ``packetsLost``
     - long
     - 累计丢包数，由 RTCP RR 中的 cumulative number of packets lost 得出
   * - ``jitter``
     - double
     - 当前到达间隔抖动（秒），按 RFC 3550 算法计算
   * - ``framesDecoded``
     - unsigned long
     - 已成功解码的视频帧总数（仅视频）
   * - ``framesDropped``
     - unsigned long
     - 被丢弃的视频帧总数（仅视频），通常因为解码过慢或渲染不及时
   * - ``totalDecodeTime``
     - double
     - 所有帧解码耗时总和（秒），可用于计算平均解码时间
   * - ``keyFramesDecoded``
     - unsigned long
     - 已解码的关键帧总数（仅视频）
   * - ``framesReceived``
     - unsigned long
     - 已接收的完整视频帧总数（仅视频）
   * - ``framesPerSecond``
     - double
     - 当前解码帧率（仅视频）
   * - ``totalInterFrameDelay``
     - double
     - 连续解码帧之间的延迟总和（秒）
   * - ``totalSquaredInterFrameDelay``
     - double
     - 连续解码帧之间延迟的平方和，用于计算抖动
   * - ``nackCount``
     - unsigned long
     - 发送的 NACK 请求总数
   * - ``firCount``
     - unsigned long
     - 发送的 FIR（Full Intra Request）请求总数
   * - ``pliCount``
     - unsigned long
     - 发送的 PLI（Picture Loss Indication）请求总数
   * - ``headerBytesReceived``
     - unsigned long long
     - 已接收的 RTP 头部字节总数
   * - ``lastPacketReceivedTimestamp``
     - DOMHighResTimeStamp
     - 最后一个 RTP 包到达的时间戳
   * - ``jitterBufferDelay``
     - double
     - 抖动缓冲区引入的总延迟（秒）
   * - ``jitterBufferEmittedCount``
     - unsigned long long
     - 从抖动缓冲区输出的样本/帧总数

使用示例:

.. code-block:: javascript

    stats.forEach(report => {
        if (report.type === 'inbound-rtp' && report.kind === 'video') {
            console.log(`Packets received: ${report.packetsReceived}`);
            console.log(`Packets lost: ${report.packetsLost}`);
            console.log(`Jitter: ${report.jitter} seconds`);
            console.log(`Frames decoded: ${report.framesDecoded}`);
            console.log(`Frames dropped: ${report.framesDropped}`);
            console.log(`Key frames decoded: ${report.keyFramesDecoded}`);

            // 计算平均解码时间
            if (report.framesDecoded > 0) {
                const avgDecodeTime = report.totalDecodeTime / report.framesDecoded;
                console.log(`Avg decode time: ${avgDecodeTime * 1000} ms`);
            }

            // 计算平均抖动缓冲延迟
            if (report.jitterBufferEmittedCount > 0) {
                const avgJitterBufferDelay =
                    report.jitterBufferDelay / report.jitterBufferEmittedCount;
                console.log(`Avg jitter buffer delay: ${avgJitterBufferDelay * 1000} ms`);
            }
        }
    });


RTCOutboundRtpStreamStats
-----------------------------

``RTCOutboundRtpStreamStats`` 描述了发送端 RTP 流的统计信息，用于评估发送质量和编码性能。

.. list-table:: RTCOutboundRtpStreamStats 关键字段
   :header-rows: 1
   :widths: 30 15 55

   * - 字段
     - 类型
     - 说明
   * - ``packetsSent``
     - unsigned long
     - 已发送的 RTP 包总数
   * - ``bytesSent``
     - unsigned long long
     - 已发送的 RTP 负载字节总数
   * - ``framesEncoded``
     - unsigned long
     - 已编码的视频帧总数（仅视频）
   * - ``keyFramesSent``
     - unsigned long
     - 已发送的关键帧总数（仅视频）
   * - ``qualityLimitationReason``
     - string
     - 当前质量受限原因: ``none``, ``cpu``, ``bandwidth``, ``other``
   * - ``qualityLimitationDurations``
     - object
     - 各质量受限原因的累计持续时间（秒），键为原因字符串
   * - ``qualityLimitationResolutionChanges``
     - unsigned long
     - 因质量受限而改变分辨率的次数
   * - ``retransmittedPacketsSent``
     - unsigned long
     - 重传的 RTP 包总数
   * - ``retransmittedBytesSent``
     - unsigned long long
     - 重传的字节总数
   * - ``headerBytesSent``
     - unsigned long long
     - 已发送的 RTP 头部字节总数
   * - ``nackCount``
     - unsigned long
     - 收到的 NACK 请求总数
   * - ``firCount``
     - unsigned long
     - 收到的 FIR 请求总数
   * - ``pliCount``
     - unsigned long
     - 收到的 PLI 请求总数
   * - ``totalEncodeTime``
     - double
     - 所有帧编码耗时总和（秒）
   * - ``totalPacketSendDelay``
     - double
     - 所有包从捕获到发送的延迟总和（秒）
   * - ``frameWidth``
     - unsigned long
     - 最后编码帧的宽度
   * - ``frameHeight``
     - unsigned long
     - 最后编码帧的高度
   * - ``framesPerSecond``
     - double
     - 当前编码帧率
   * - ``targetBitrate``
     - double
     - 编码器当前目标码率（bps）

``qualityLimitationReason`` 是一个非常有用的指标，它直接告诉我们当前编码质量受限的原因:

.. code-block:: javascript

    stats.forEach(report => {
        if (report.type === 'outbound-rtp' && report.kind === 'video') {
            console.log(`Quality limitation reason: ${report.qualityLimitationReason}`);
            console.log(`Quality limitation durations:`,
                report.qualityLimitationDurations);
            console.log(`Resolution changes: ${report.qualityLimitationResolutionChanges}`);
            console.log(`Target bitrate: ${report.targetBitrate} bps`);
            console.log(`Retransmitted packets: ${report.retransmittedPacketsSent}`);

            // 计算平均编码时间
            if (report.framesEncoded > 0) {
                const avgEncodeTime = report.totalEncodeTime / report.framesEncoded;
                console.log(`Avg encode time: ${avgEncodeTime * 1000} ms`);
            }
        }
    });


RTCRemoteInboundRtpStreamStats
-----------------------------------

``RTCRemoteInboundRtpStreamStats`` 包含远端接收方通过 RTCP Receiver Report 反馈回来的统计信息，是评估端到端传输质量的关键数据源。

.. list-table:: RTCRemoteInboundRtpStreamStats 关键字段
   :header-rows: 1
   :widths: 30 15 55

   * - 字段
     - 类型
     - 说明
   * - ``roundTripTime``
     - double
     - 最近一次测量的往返时间（秒），基于 RTCP SR/RR 计算
   * - ``totalRoundTripTime``
     - double
     - 所有 RTT 测量值的总和（秒）
   * - ``roundTripTimeMeasurements``
     - unsigned long
     - RTT 测量的次数，用于计算平均 RTT
   * - ``fractionLost``
     - double
     - 自上次 RR 以来的丢包率（0.0 ~ 1.0）
   * - ``packetsLost``
     - long
     - 远端报告的累计丢包数
   * - ``jitter``
     - double
     - 远端报告的到达间隔抖动（秒）
   * - ``localId``
     - string
     - 关联的本地 outbound-rtp 统计报告 ID

.. code-block:: javascript

    stats.forEach(report => {
        if (report.type === 'remote-inbound-rtp') {
            console.log(`RTT: ${report.roundTripTime * 1000} ms`);
            console.log(`Fraction lost: ${(report.fractionLost * 100).toFixed(2)}%`);

            // 计算平均 RTT
            if (report.roundTripTimeMeasurements > 0) {
                const avgRtt = report.totalRoundTripTime
                    / report.roundTripTimeMeasurements;
                console.log(`Average RTT: ${avgRtt * 1000} ms`);
            }
        }
    });


RTCIceCandidatePairStats
-----------------------------

``RTCIceCandidatePairStats`` 描述了 ICE 候选对的传输层统计信息，反映了网络连接的整体状况。

.. list-table:: RTCIceCandidatePairStats 关键字段
   :header-rows: 1
   :widths: 30 15 55

   * - 字段
     - 类型
     - 说明
   * - ``currentRoundTripTime``
     - double
     - 当前 ICE 连接的往返时间（秒），基于 STUN 连通性检查
   * - ``availableOutgoingBitrate``
     - double
     - 估算的可用出站带宽（bps），由拥塞控制算法提供
   * - ``availableIncomingBitrate``
     - double
     - 估算的可用入站带宽（bps）
   * - ``bytesReceived``
     - unsigned long long
     - 该候选对上接收的总字节数
   * - ``bytesSent``
     - unsigned long long
     - 该候选对上发送的总字节数
   * - ``totalRoundTripTime``
     - double
     - 所有 STUN RTT 测量值的总和（秒）
   * - ``responsesReceived``
     - unsigned long long
     - 收到的 STUN 连通性检查响应总数
   * - ``requestsSent``
     - unsigned long long
     - 发送的 STUN 连通性检查请求总数
   * - ``state``
     - string
     - 候选对状态: ``frozen``, ``waiting``, ``in-progress``, ``succeeded``, ``failed``
   * - ``nominated``
     - boolean
     - 该候选对是否被提名使用
   * - ``consentRequestsSent``
     - unsigned long long
     - 发送的 consent 请求总数（用于连接保活）

.. code-block:: javascript

    stats.forEach(report => {
        if (report.type === 'candidate-pair' && report.nominated) {
            console.log(`Current RTT: ${report.currentRoundTripTime * 1000} ms`);
            console.log(`Available outgoing bitrate: ${
                (report.availableOutgoingBitrate / 1000000).toFixed(2)} Mbps`);
            console.log(`Bytes sent: ${report.bytesSent}`);
            console.log(`Bytes received: ${report.bytesReceived}`);
            console.log(`State: ${report.state}`);
        }
    });


RTCMediaSourceStats
-----------------------------

``RTCMediaSourceStats`` 描述了媒体源（摄像头、麦克风或屏幕共享）的属性信息。

.. list-table:: RTCMediaSourceStats 关键字段（视频）
   :header-rows: 1
   :widths: 25 15 60

   * - 字段
     - 类型
     - 说明
   * - ``width``
     - unsigned long
     - 视频源的宽度（像素）
   * - ``height``
     - unsigned long
     - 视频源的高度（像素）
   * - ``framesPerSecond``
     - double
     - 视频源的当前帧率
   * - ``frames``
     - unsigned long
     - 视频源产生的总帧数

.. list-table:: RTCMediaSourceStats 关键字段（音频）
   :header-rows: 1
   :widths: 25 15 60

   * - 字段
     - 类型
     - 说明
   * - ``audioLevel``
     - double
     - 音频电平（0.0 ~ 1.0），0 表示静音
   * - ``totalAudioEnergy``
     - double
     - 音频能量总和，用于计算平均音量
   * - ``totalSamplesDuration``
     - double
     - 音频采样的总持续时间（秒）
   * - ``echoReturnLoss``
     - double
     - 回声回损（dB），值越大回声消除效果越好
   * - ``echoReturnLossEnhancement``
     - double
     - 回声回损增强（dB）


常用计算公式
======================

由于 ``getStats()`` 返回的大多数指标是累计值，我们需要通过两次采样的差值来计算区间内的实时指标。以下是常用的计算公式和对应的 JavaScript 实现。

丢包率计算
-----------------------------

丢包率是衡量网络质量最直接的指标之一:

.. code-block:: javascript

    // 计算区间丢包率
    function calculatePacketLossRate(currentStats, previousStats) {
        const packetsLostDelta =
            currentStats.packetsLost - previousStats.packetsLost;
        const packetsReceivedDelta =
            currentStats.packetsReceived - previousStats.packetsReceived;

        const totalPacketsDelta = packetsReceivedDelta + packetsLostDelta;
        if (totalPacketsDelta <= 0) return 0;

        const lossRate = packetsLostDelta / totalPacketsDelta;
        return Math.max(0, Math.min(1, lossRate)); // 限制在 0~1 之间
    }

    // 使用示例
    const lossRate = calculatePacketLossRate(currentInbound, previousInbound);
    console.log(`Packet loss rate: ${(lossRate * 100).toFixed(2)}%`);

.. note::

   ``packetsLost`` 可能为负值（当出现重复包时），因此需要做边界检查。


码率计算
-----------------------------

码率（Bitrate）反映了媒体流的数据传输速率:

.. code-block:: javascript

    // 计算区间码率 (bps)
    function calculateBitrate(currentStats, previousStats) {
        const bytesDelta = currentStats.bytesReceived !== undefined
            ? currentStats.bytesReceived - previousStats.bytesReceived
            : currentStats.bytesSent - previousStats.bytesSent;

        const timeDelta =
            (currentStats.timestamp - previousStats.timestamp) / 1000; // 转为秒

        if (timeDelta <= 0) return 0;

        return (bytesDelta * 8) / timeDelta; // 转为 bits per second
    }

    // 使用示例
    const bitrate = calculateBitrate(currentInbound, previousInbound);
    console.log(`Bitrate: ${(bitrate / 1000).toFixed(0)} kbps`);


帧率计算
-----------------------------

帧率反映了视频的流畅程度:

.. code-block:: javascript

    // 计算区间帧率
    function calculateFrameRate(currentStats, previousStats) {
        const framesDecodedDelta =
            currentStats.framesDecoded - previousStats.framesDecoded;
        const timeDelta =
            (currentStats.timestamp - previousStats.timestamp) / 1000;

        if (timeDelta <= 0) return 0;

        return framesDecodedDelta / timeDelta;
    }

    // 发送端帧率
    function calculateSendFrameRate(currentStats, previousStats) {
        const framesEncodedDelta =
            currentStats.framesEncoded - previousStats.framesEncoded;
        const timeDelta =
            (currentStats.timestamp - previousStats.timestamp) / 1000;

        if (timeDelta <= 0) return 0;

        return framesEncodedDelta / timeDelta;
    }


抖动与 RTT
-----------------------------

抖动（Jitter）和往返时间（RTT）可以直接从统计报告中读取，也可以计算平均值:

.. code-block:: javascript

    // 从 inbound-rtp 获取抖动
    function getJitter(inboundStats) {
        return inboundStats.jitter; // 单位: 秒
    }

    // 从 remote-inbound-rtp 获取 RTT
    function getRoundTripTime(remoteInboundStats) {
        return remoteInboundStats.roundTripTime; // 单位: 秒
    }

    // 计算平均 RTT
    function getAverageRTT(remoteInboundStats) {
        if (remoteInboundStats.roundTripTimeMeasurements > 0) {
            return remoteInboundStats.totalRoundTripTime
                / remoteInboundStats.roundTripTimeMeasurements;
        }
        return 0;
    }

    // 从 candidate-pair 获取 ICE 层 RTT
    function getIceRTT(candidatePairStats) {
        return candidatePairStats.currentRoundTripTime; // 单位: 秒
    }


综合采集示例
-----------------------------

以下是一个完整的统计数据采集和计算示例:

.. code-block:: javascript

    class WebRTCMetricsCollector {
        constructor(peerConnection, intervalMs = 1000) {
            this.pc = peerConnection;
            this.intervalMs = intervalMs;
            this.previousStats = new Map();
            this.timer = null;
        }

        start() {
            this.timer = setInterval(() => this.collect(), this.intervalMs);
        }

        stop() {
            if (this.timer) {
                clearInterval(this.timer);
                this.timer = null;
            }
        }

        async collect() {
            const stats = await this.pc.getStats();
            const metrics = {};

            stats.forEach(report => {
                const prev = this.previousStats.get(report.id);

                if (report.type === 'inbound-rtp' && prev) {
                    const timeDelta =
                        (report.timestamp - prev.timestamp) / 1000;
                    if (timeDelta > 0) {
                        const key = `${report.kind}_inbound`;
                        metrics[key] = {
                            bitrate: ((report.bytesReceived - prev.bytesReceived)
                                * 8) / timeDelta,
                            packetLossRate: this._calcLossRate(report, prev),
                            jitter: report.jitter * 1000, // ms
                        };
                        if (report.kind === 'video') {
                            metrics[key].frameRate =
                                (report.framesDecoded - prev.framesDecoded)
                                / timeDelta;
                            metrics[key].framesDropped =
                                report.framesDropped - prev.framesDropped;
                        }
                    }
                }

                if (report.type === 'outbound-rtp' && prev) {
                    const timeDelta =
                        (report.timestamp - prev.timestamp) / 1000;
                    if (timeDelta > 0) {
                        const key = `${report.kind}_outbound`;
                        metrics[key] = {
                            bitrate: ((report.bytesSent - prev.bytesSent)
                                * 8) / timeDelta,
                            qualityLimitationReason:
                                report.qualityLimitationReason,
                            retransmittedPackets:
                                report.retransmittedPacketsSent
                                - (prev.retransmittedPacketsSent || 0),
                        };
                        if (report.kind === 'video') {
                            metrics[key].frameRate =
                                (report.framesEncoded - prev.framesEncoded)
                                / timeDelta;
                        }
                    }
                }

                if (report.type === 'remote-inbound-rtp') {
                    metrics[`rtt_${report.kind}`] = {
                        roundTripTime: report.roundTripTime * 1000, // ms
                        fractionLost: report.fractionLost,
                    };
                }

                if (report.type === 'candidate-pair' && report.nominated) {
                    metrics.transport = {
                        currentRtt: report.currentRoundTripTime * 1000,
                        availableBitrate: report.availableOutgoingBitrate,
                    };
                }

                this.previousStats.set(report.id, report);
            });

            this.onMetrics(metrics);
        }

        _calcLossRate(current, previous) {
            const lostDelta = current.packetsLost - previous.packetsLost;
            const recvDelta =
                current.packetsReceived - previous.packetsReceived;
            const total = recvDelta + lostDelta;
            if (total <= 0) return 0;
            return Math.max(0, lostDelta / total);
        }

        onMetrics(metrics) {
            // 子类或回调覆盖此方法
            console.log('Metrics:', JSON.stringify(metrics, null, 2));
        }
    }

    // 使用
    const collector = new WebRTCMetricsCollector(peerConnection, 2000);
    collector.onMetrics = (metrics) => {
        // 发送到监控后端或更新 UI
        sendToMonitoringBackend(metrics);
    };
    collector.start();


RTCP XR 扩展指标
============================

Considerations for Selecting RTCP Extended Report (XR) Metrics for the WebRTC Statistics API
-----------------------------------------------------------------------------------------------

RTCP XR（Extended Reports）定义在 RFC 3611 中，提供了比标准 RTCP SR/RR 更丰富的质量度量指标。WebRTC 统计 API 中的部分指标来源于 RTCP XR。

RTCP XR 指标可分为三大类:

* network impact metrics（网络影响指标）
* application impact metrics（应用影响指标）
* recovery metrics（恢复指标）

相关 RFC:

* **RFC 3611** - RTP Control Protocol Extended Reports (RTCP XR)
* **RFC 6958** - burst/gap loss metric reporting
* **RFC 7003** - burst/gap discard metric reporting
* **RFC 6776** - Measurement Identity and Information Reporting Using a SDES Item and an RTCP Extended Report (XR) Block


Burst/Gap Loss 指标
-----------------------------

RFC 6958 定义了突发/间隙丢包指标，用于更精确地描述丢包模式:

- **Burst Duration**: 突发丢包持续时间
- **Burst Density**: 突发期间的丢包密度（丢包包数 / 总包数）
- **Gap Duration**: 间隙（正常传输）持续时间
- **Gap Density**: 间隙期间的丢包密度（通常很低）

突发丢包比均匀丢包对音视频质量的影响更大，因为:

1. 突发丢包可能导致连续多帧损坏，FEC 难以恢复
2. 突发丢包期间 NACK 重传可能来不及
3. 视频可能需要请求关键帧，导致明显卡顿


VoIP 质量指标
-----------------------------

RFC 3611 Section 4.7 定义了 VoIP Metrics Report Block，包含以下关键指标:

**R-Factor（传输评定因子）**

R-Factor 是 E-model（ITU-T G.107）的输出，综合考虑了延迟、丢包、编解码器等因素对语音质量的影响:

.. code-block:: text

    R = R0 - Is - Id - Ie_eff + A

    其中:
    R0 = 基础信噪比（通常为 93.2）
    Is = 同时发生的损伤因子（如量化噪声）
    Id = 延迟损伤因子
    Ie_eff = 设备损伤因子（与编解码器和丢包相关）
    A = 优势因子（用户对不同通信方式的容忍度补偿）

R-Factor 的取值范围和对应质量等级:

.. list-table:: R-Factor 质量等级
   :header-rows: 1
   :widths: 20 30 50

   * - R-Factor
     - 质量等级
     - 用户满意度
   * - 90 ~ 100
     - 优秀
     - 非常满意
   * - 80 ~ 90
     - 良好
     - 满意
   * - 70 ~ 80
     - 一般
     - 部分用户不满意
   * - 60 ~ 70
     - 较差
     - 多数用户不满意
   * - < 60
     - 很差
     - 几乎所有用户不满意

**MOS（平均意见分）估算**

MOS 可以从 R-Factor 转换得到:

.. code-block:: text

    若 R < 0:    MOS = 1.0
    若 R > 100:  MOS = 4.5
    否则:
    MOS = 1 + 0.035 * R + R * (R - 60) * (100 - R) * 7.0e-6

MOS 的取值范围为 1.0 ~ 4.5:

.. list-table:: MOS 质量等级
   :header-rows: 1
   :widths: 15 25 60

   * - MOS
     - 质量等级
     - 说明
   * - 4.3 ~ 5.0
     - 优秀
     - 高清语音质量
   * - 4.0 ~ 4.3
     - 良好
     - 传统电话质量
   * - 3.6 ~ 4.0
     - 一般
     - 可接受但有明显瑕疵
   * - 3.1 ~ 3.6
     - 较差
     - 勉强可用
   * - < 3.1
     - 很差
     - 不可接受


延迟指标
-----------------------------

RTCP XR 中与延迟相关的指标包括:

- **End System Delay**: 端系统延迟，包括编码、缓冲、解码等处理时间
- **One-Way Delay**: 单向延迟，通过 NTP 时间戳估算
- **Round Trip Delay**: 往返延迟，通过 RTCP SR/RR 时间戳计算

端到端延迟的组成:

.. code-block:: text

    E2E Delay = Capture Delay
              + Encode Delay
              + Packetization Delay
              + Network Delay (one-way)
              + Jitter Buffer Delay
              + Decode Delay
              + Render Delay


监控与告警
======================

质量阈值参考
-----------------------------

以下是 WebRTC 通话质量监控的常用阈值参考:

.. list-table:: 质量阈值参考表
   :header-rows: 1
   :widths: 25 20 20 20 15

   * - 指标
     - 正常
     - 警告
     - 严重
     - 单位
   * - 丢包率 (Packet Loss)
     - < 2%
     - 2% ~ 5%
     - > 5%
     - %
   * - 往返时间 (RTT)
     - < 150ms
     - 150 ~ 300ms
     - > 300ms
     - ms
   * - 抖动 (Jitter)
     - < 30ms
     - 30 ~ 75ms
     - > 75ms
     - ms
   * - 可用带宽
     - > 1 Mbps
     - 500k ~ 1M
     - < 500 kbps
     - bps
   * - 视频帧率
     - > 24 fps
     - 15 ~ 24 fps
     - < 15 fps
     - fps
   * - 视频分辨率
     - >= 720p
     - 360p ~ 720p
     - < 360p
     - px
   * - 音频电平
     - > 0.01
     - 0.001 ~ 0.01
     - < 0.001
     - level
   * - NACK 频率
     - < 10/s
     - 10 ~ 50/s
     - > 50/s
     - 次/秒
   * - PLI 频率
     - < 1/min
     - 1 ~ 5/min
     - > 5/min
     - 次/分
   * - 解码帧丢弃率
     - < 1%
     - 1% ~ 5%
     - > 5%
     - %
   * - qualityLimitationReason
     - none
     - bandwidth
     - cpu
     - —


质量问题特征识别
-----------------------------

不同的质量问题有不同的指标特征组合，可以帮助快速定位根因:

**网络拥塞**:

- 丢包率上升
- RTT 增大
- ``availableOutgoingBitrate`` 下降
- ``qualityLimitationReason`` 为 ``bandwidth``
- 分辨率和帧率可能自适应降低

**CPU 过载**:

- ``qualityLimitationReason`` 为 ``cpu``
- 编码帧率下降
- ``totalEncodeTime`` 增长过快（平均编码时间增大）
- 分辨率可能降低
- 丢包率和 RTT 正常

**网络抖动**:

- jitter 值增大
- 抖动缓冲区延迟增大
- 可能伴随少量丢包
- RTT 波动较大

**单向丢包（上行或下行）**:

- 本地 ``inbound-rtp.packetsLost`` 增大（下行丢包）
- ``remote-inbound-rtp.fractionLost`` 增大（上行丢包）
- 需要区分方向以定位问题

**音频问题**:

- ``audioLevel`` 持续为 0（麦克风静音或未采集）
- ``jitterBufferDelay`` 过大（音频延迟高）
- 丢包导致 PLC（Packet Loss Concealment）频繁触发


Dashboard 设计建议
-----------------------------

一个有效的 WebRTC 质量监控 Dashboard 应包含以下面板:

1. **实时概览面板**: 当前通话数、活跃用户数、整体质量评分
2. **网络质量面板**: RTT 分布图、丢包率趋势、抖动趋势
3. **媒体质量面板**: 码率趋势、帧率趋势、分辨率变化
4. **编码质量面板**: qualityLimitationReason 分布、编码时间趋势
5. **告警面板**: 实时告警列表、告警趋势、Top-N 问题用户
6. **用户体验面板**: MOS 估算分布、通话质量评分分布


工具与实践
======================

chrome://webrtc-internals
-----------------------------

Chrome 浏览器内置了强大的 WebRTC 调试工具，可通过地址栏输入 ``chrome://webrtc-internals`` 访问。

主要功能:

1. **实时统计图表**: 自动绘制所有 WebRTC 统计指标的时间序列图
2. **事件日志**: 记录 PeerConnection 的所有 API 调用和事件
3. **SDP 查看**: 显示 Offer/Answer SDP 的完整内容
4. **ICE 候选信息**: 展示所有 ICE 候选及其状态
5. **导出功能**: 可将所有数据导出为 JSON 文件供离线分析

使用步骤:

1. 打开 ``chrome://webrtc-internals``
2. 在另一个标签页中开始 WebRTC 通话
3. 回到 webrtc-internals 页面，可以看到新创建的 PeerConnection
4. 点击展开查看各项统计数据和图表
5. 通话结束后可点击 "Create Dump" 导出数据

.. note::

   Firefox 也提供了类似的工具: ``about:webrtc``。


getStats() 轮询模式
-----------------------------

在生产环境中，通常需要定期轮询 ``getStats()`` 来持续监控通话质量:

.. code-block:: javascript

    class StatsPoller {
        constructor(pc, onStats, intervalMs = 2000) {
            this.pc = pc;
            this.onStats = onStats;
            this.intervalMs = intervalMs;
            this.prevReports = new Map();
            this.running = false;
        }

        start() {
            this.running = true;
            this._poll();
        }

        stop() {
            this.running = false;
        }

        async _poll() {
            if (!this.running) return;

            try {
                const stats = await this.pc.getStats();
                const processed = this._processStats(stats);
                this.onStats(processed);
            } catch (e) {
                console.error('Stats polling error:', e);
            }

            setTimeout(() => this._poll(), this.intervalMs);
        }

        _processStats(stats) {
            const result = {
                timestamp: Date.now(),
                audio: { inbound: null, outbound: null },
                video: { inbound: null, outbound: null },
                transport: null,
            };

            stats.forEach(report => {
                const prev = this.prevReports.get(report.id);
                const timeDelta = prev
                    ? (report.timestamp - prev.timestamp) / 1000
                    : 0;

                if (report.type === 'inbound-rtp' && prev && timeDelta > 0) {
                    result[report.kind].inbound = {
                        bitrate: ((report.bytesReceived
                            - prev.bytesReceived) * 8) / timeDelta,
                        packetsLost: report.packetsLost - prev.packetsLost,
                        jitter: report.jitter * 1000,
                        ...(report.kind === 'video' && {
                            frameRate: (report.framesDecoded
                                - prev.framesDecoded) / timeDelta,
                            resolution: `${report.frameWidth}x${report.frameHeight}`,
                        }),
                    };
                }

                if (report.type === 'outbound-rtp' && prev && timeDelta > 0) {
                    result[report.kind].outbound = {
                        bitrate: ((report.bytesSent
                            - prev.bytesSent) * 8) / timeDelta,
                        ...(report.kind === 'video' && {
                            frameRate: (report.framesEncoded
                                - prev.framesEncoded) / timeDelta,
                            qualityLimitation: report.qualityLimitationReason,
                        }),
                    };
                }

                if (report.type === 'candidate-pair' && report.nominated) {
                    result.transport = {
                        rtt: report.currentRoundTripTime * 1000,
                        availableBitrate: report.availableOutgoingBitrate,
                    };
                }

                this.prevReports.set(report.id, report);
            });

            return result;
        }
    }


第三方监控工具
-----------------------------

除了自建监控系统，还可以使用以下第三方 WebRTC 监控服务:

- **callstats.io** (现为 Amazon Chime SDK 的一部分): 提供端到端的 WebRTC 质量监控和分析
- **testRTC**: 提供 WebRTC 应用的自动化测试和监控
- **Location Insights by Location Labs**: 网络质量分析
- **Srlocation**: 实时通信质量监控平台
- **WebRTC-Experiment**: 开源的 WebRTC 测试工具集

自建监控系统的基本架构:

.. code-block:: text

    ┌──────────┐    getStats()    ┌──────────────┐
    │  Browser │ ──────────────> │  Stats        │
    │  Client  │                 │  Collector    │
    └──────────┘                 └──────┬───────┘
                                        │ HTTP/WebSocket
                                        ▼
                                 ┌──────────────┐
                                 │  Monitoring   │
                                 │  Backend      │
                                 └──────┬───────┘
                                        │
                          ┌─────────────┼─────────────┐
                          ▼             ▼             ▼
                   ┌───────────┐ ┌───────────┐ ┌───────────┐
                   │ Time-     │ │ Alert     │ │ Dashboard │
                   │ Series DB │ │ Engine    │ │ (Grafana) │
                   └───────────┘ └───────────┘ └───────────┘


参考资料
======================

* `W3C WebRTC Statistics API <https://www.w3.org/TR/webrtc-stats/>`_
* `RFC 3550 - RTP: A Transport Protocol for Real-Time Applications <https://tools.ietf.org/html/rfc3550>`_
* `RFC 3611 - RTP Control Protocol Extended Reports (RTCP XR) <https://tools.ietf.org/html/rfc3611>`_
* `RFC 6958 - RTP Control Protocol (RTCP) Extended Report (XR) Block for Burst/Gap Loss Metric Reporting <https://tools.ietf.org/html/rfc6958>`_
* `RFC 7003 - RTP Control Protocol (RTCP) Extended Report (XR) Block for Burst/Gap Discard Metric Reporting <https://tools.ietf.org/html/rfc7003>`_
* `RFC 6776 - Measurement Identity and Information Reporting Using a SDES Item and an RTCP Extended Report (XR) Block <https://tools.ietf.org/html/rfc6776>`_
* `ITU-T G.107 - The E-model: a computational model for use in transmission planning <https://www.itu.int/rec/T-REC-G.107>`_
* `ITU-T P.800 - Methods for subjective determination of transmission quality (MOS) <https://www.itu.int/rec/T-REC-P.800>`_
* `chrome://webrtc-internals - Chrome WebRTC Debugging Tool <https://webrtc.github.io/webrtc-org/native-code/logging/>`_
