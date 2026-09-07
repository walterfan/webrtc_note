########################
QUIC 协议
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** QUIC protocol
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=======================================

QUIC (Quick UDP Internet Connections) 是一种基于 UDP 的多路复用安全传输协议，由 Google 最初设计，后经 IETF 标准化为 RFC 9000。QUIC 提供了与 TCP+TLS 等效的功能，但具有更低的连接建立延迟、更好的多路复用支持和内置的连接迁移能力。

QUIC 的核心设计目标：

* **低延迟连接建立**: 1-RTT 握手（首次连接），0-RTT 恢复（后续连接）
* **多路复用无队头阻塞**: 多个流独立传输，单个流的丢包不影响其他流
* **内置加密**: 所有 QUIC 数据包都经过加密，使用 TLS 1.3
* **连接迁移**: 基于 Connection ID 而非 IP:Port 四元组标识连接
* **改进的丢包检测和拥塞控制**: 更精确的 RTT 测量和灵活的拥塞控制

QUIC 在 WebRTC 生态系统中的地位日益重要，WebTransport 和 Media over QUIC (MoQ) 等新技术正在探索使用 QUIC 作为实时媒体传输的替代方案。


背景
----------------------------------------

HTTP/2 通过多路复用和头部压缩显著提升了 Web 性能，但它仍然受限于 TCP 的固有问题。虽然 HTTP/2 允许在单个 TCP 连接上多路复用多个流，但当某个流发生丢包时，TCP 的可靠传输机制会阻塞整个连接上的所有流——这就是 TCP 层面的队头阻塞 (Head-of-Line Blocking)。

Daniel Stenberg 在其关于 HTTP/3 的著作中指出，在 2% 丢包率的情况下，使用 HTTP/1 的六个并行连接反而比 HTTP/2 的单连接多路复用性能更好。

QUIC 通过在 UDP 之上实现传输层功能来解决这个问题：

* 多路复用的流之间相互独立，单个流的丢包不影响其他流
* 连接建立与 TLS 握手合并，减少了 RTT
* 在用户空间实现，可以快速迭代和部署

Google Cloud Platform 在 2018 年为其负载均衡器引入 QUIC 支持后，全球平均页面加载时间改善了 8%，在高延迟地区改善高达 13%。


QUIC 与 TCP 对比
=======================================

.. list-table:: QUIC vs TCP 详细对比
   :header-rows: 1
   :widths: 25 37 38

   * - 特性
     - TCP
     - QUIC
   * - 传输层
     - 内核实现
     - 用户空间实现（基于 UDP）
   * - 连接建立
     - TCP 3-way handshake + TLS 握手 (2-3 RTT)
     - 1-RTT（含 TLS 1.3），0-RTT 恢复
   * - 加密
     - 可选（TLS 层）
     - 强制（内置 TLS 1.3）
   * - 多路复用
     - 无原生支持（HTTP/2 在应用层实现）
     - 原生流多路复用，无队头阻塞
   * - 队头阻塞
     - 存在（丢包阻塞所有流）
     - 仅影响丢包的流
   * - 连接迁移
     - 不支持（IP 变化需重建连接）
     - 支持（基于 Connection ID）
   * - 拥塞控制
     - 内核实现，更新缓慢
     - 用户空间实现，可插拔
   * - NAT 重绑定
     - 连接中断
     - 通过 Connection ID 保持连接
   * - 协议僵化
     - 严重（中间设备依赖 TCP 头部）
     - 头部加密，防止中间设备干预


QUIC 核心特性
=======================================

流多路复用 (Stream Multiplexing)
-----------------------------------------

QUIC 的流 (stream) 是协议的基本服务抽象。每个流是一个有序的字节序列，流之间相互独立。

.. code-block::

    QUIC 连接
    ├── Stream 0 (双向): 控制流
    ├── Stream 1 (客户端发起，双向): HTTP 请求/响应 1
    ├── Stream 3 (客户端发起，双向): HTTP 请求/响应 2
    ├── Stream 5 (客户端发起，双向): HTTP 请求/响应 3
    ├── Stream 2 (服务器发起，双向): 服务器推送
    └── Stream 7 (客户端发起，单向): 单向数据

流的类型由 Stream ID 的低 2 位决定：

.. code-block::

    +------+------------------------------------------+
    | 低2位 | 流类型                                    |
    +------+------------------------------------------+
    | 0x00 | 客户端发起的双向流 (Client-Initiated,     |
    |      | Bidirectional)                            |
    +------+------------------------------------------+
    | 0x01 | 服务器发起的双向流 (Server-Initiated,     |
    |      | Bidirectional)                            |
    +------+------------------------------------------+
    | 0x02 | 客户端发起的单向流 (Client-Initiated,     |
    |      | Unidirectional)                           |
    +------+------------------------------------------+
    | 0x03 | 服务器发起的单向流 (Server-Initiated,     |
    |      | Unidirectional)                           |
    +------+------------------------------------------+

关键优势：当 Stream 3 发生丢包时，只有 Stream 3 的数据传输被阻塞，Stream 1 和 Stream 5 可以继续正常接收和处理数据。

连接迁移 (Connection Migration)
-----------------------------------------

QUIC 使用 Connection ID 而非传统的四元组 (源IP, 源端口, 目标IP, 目标端口) 来标识连接。这使得当客户端的网络地址发生变化时（如从 Wi-Fi 切换到蜂窝网络），连接可以无缝迁移。

.. code-block::

    场景: 用户从 Wi-Fi 切换到 4G

    TCP 行为:
    Wi-Fi: 192.168.1.100:5000 → 服务器  [连接 A]
    切换到 4G...
    4G:    10.0.0.50:6000    → 服务器  [需要新建连接 B]
    (之前的连接 A 中断，需要重新握手)

    QUIC 行为:
    Wi-Fi: 192.168.1.100:5000 → 服务器  [Connection ID: 0xABCD]
    切换到 4G...
    4G:    10.0.0.50:6000    → 服务器  [Connection ID: 0xABCD]
    (同一个连接，通过路径验证后继续传输)

连接迁移过程中，QUIC 会进行路径验证 (Path Validation)，确保新路径的可达性和安全性。

握手与加密
-----------------------------------------

QUIC 将传输层握手和 TLS 1.3 握手合并，实现了高效的连接建立：

**1-RTT 握手（首次连接）**

.. code-block::

    Client                                               Server

    Initial[0]: CRYPTO[CH]       -------->
                                                 Initial[0]: CRYPTO[SH]
                                            Handshake[0]: CRYPTO[EE, CERT, CV, FIN]
                                 <--------
    Handshake[0]: CRYPTO[FIN]    -------->

    1-RTT[0]: STREAM[0, ...]     -------->
                                 <--------   1-RTT[1]: STREAM[1, ...]

    CH = ClientHello, SH = ServerHello
    EE = EncryptedExtensions, CERT = Certificate
    CV = CertificateVerify, FIN = Finished

**0-RTT 恢复（后续连接）**

.. code-block::

    Client                                               Server

    Initial[0]: CRYPTO[CH]
    0-RTT[0]: STREAM[0, ...]     -------->
                                                 Initial[0]: CRYPTO[SH]
                                            Handshake[0]: CRYPTO[EE, FIN]
                                 <--------
    Handshake[0]: CRYPTO[FIN]    -------->

    1-RTT[1]: STREAM[1, ...]     -------->
                                 <--------   1-RTT[0]: STREAM[0, ...]

0-RTT 数据在第一个数据包中就可以发送，但需要注意重放攻击的风险。

QUIC 使用多层加密保护：

* **Initial packets**: 使用从 Connection ID 派生的密钥（公开的，仅防止意外修改）
* **Handshake packets**: 使用握手密钥
* **1-RTT packets**: 使用应用数据密钥
* **Header protection**: 数据包头部的部分字段也被加密

丢包检测与拥塞控制
-----------------------------------------

QUIC 改进了 TCP 的丢包检测和拥塞控制机制 (RFC 9002)：

**改进的 RTT 测量**

* QUIC 的 packet number 严格递增，不会像 TCP 的序列号那样在重传时复用
* 消除了 TCP 的重传歧义问题 (retransmission ambiguity)
* 支持更精确的 RTT 估算

**丢包检测**

QUIC 使用两种丢包检测机制：

1. **基于 ACK 的检测**: 如果一个数据包的 packet number 比已确认的最大 packet number 小 3 个以上，则认为丢失
2. **基于时间的检测**: 如果一个数据包发送后超过一定时间（通常为 9/8 * max(smoothed_rtt, latest_rtt)）仍未被确认，则认为丢失

**可插拔的拥塞控制**

QUIC 的拥塞控制在用户空间实现，可以灵活替换：

* **New Reno**: RFC 9002 中描述的默认算法
* **Cubic**: 类似 TCP Cubic
* **BBR (Bottleneck Bandwidth and RTT)**: Google 开发的基于模型的拥塞控制
* **Copa**: 基于延迟的拥塞控制

流量控制 (Flow Control)
-----------------------------------------

QUIC 实现了两级流量控制：

**流级别 (Stream-level) 流量控制**

每个流有独立的接收窗口，防止单个流消耗过多缓冲区：

.. code-block::

    MAX_STREAM_DATA frame:
    +------+------------+------------------+
    | Type | Stream ID  | Maximum Data     |
    +------+------------+------------------+

**连接级别 (Connection-level) 流量控制**

限制所有流的总数据量，防止连接整体消耗过多资源：

.. code-block::

    MAX_DATA frame:
    +------+------------------+
    | Type | Maximum Data     |
    +------+------------------+

此外，QUIC 还通过 ``MAX_STREAMS`` 帧限制并发流的数量。


WebTransport over QUIC
=======================================

WebTransport 是一个新的 Web API，允许 Web 应用通过 QUIC 或 HTTP/3 与服务器进行低延迟的双向通信。它被设计为 WebSocket 和 WebRTC DataChannel 的补充或替代方案。

WebTransport API
-----------------------------------------

.. code-block:: javascript

    // 建立 WebTransport 连接
    const transport = new WebTransport('https://example.com:4433/wt');
    await transport.ready;

    // 发送不可靠的数据报 (Datagram)
    const writer = transport.datagrams.writable.getWriter();
    await writer.write(new Uint8Array([1, 2, 3, 4]));

    // 接收数据报
    const reader = transport.datagrams.readable.getReader();
    const { value, done } = await reader.read();

    // 创建双向流 (可靠传输)
    const stream = await transport.createBidirectionalStream();
    const streamWriter = stream.writable.getWriter();
    await streamWriter.write(new TextEncoder().encode('Hello'));

    // 创建单向流
    const uniStream = await transport.createUnidirectionalStream();
    const uniWriter = uniStream.getWriter();
    await uniWriter.write(new Uint8Array([5, 6, 7, 8]));

    // 接收服务器发起的流
    const incomingStreams = transport.incomingBidirectionalStreams;
    const streamReader = incomingStreams.getReader();
    const { value: inStream } = await streamReader.read();

数据报与流
-----------------------------------------

WebTransport 提供两种数据传输模式：

.. list-table::
   :header-rows: 1
   :widths: 20 40 40

   * - 特性
     - Datagrams (数据报)
     - Streams (流)
   * - 可靠性
     - 不可靠，可能丢失
     - 可靠，保证有序交付
   * - 有序性
     - 不保证顺序
     - 保证顺序
   * - 延迟
     - 最低（无重传）
     - 较高（需要重传）
   * - 适用场景
     - 实时音视频、游戏状态
     - 文件传输、信令消息
   * - 流量控制
     - 无
     - 有

WebTransport 与 WebRTC DataChannel 对比
-----------------------------------------

.. list-table::
   :header-rows: 1
   :widths: 25 37 38

   * - 特性
     - WebRTC DataChannel
     - WebTransport
   * - 底层协议
     - SCTP over DTLS over UDP
     - QUIC (HTTP/3)
   * - 连接模型
     - P2P（需要 ICE/STUN/TURN）
     - 客户端-服务器
   * - 信令
     - 需要 SDP offer/answer
     - 直接连接 URL
   * - 不可靠传输
     - 支持（配置 maxRetransmits=0）
     - 原生支持（Datagrams）
   * - 服务器要求
     - 需要信令服务器
     - 标准 HTTP/3 服务器
   * - NAT 穿越
     - 内置（ICE）
     - 不需要（客户端-服务器模型）


QUIC 用于媒体传输
=======================================

Media over QUIC (MoQ)
-----------------------------------------

IETF 的 Media over QUIC (MoQ) 工作组正在开发基于 QUIC 的媒体传输协议，目标是为直播、视频会议等场景提供新的传输方案。

MoQ 的核心概念：

* **发布-订阅模型 (Pub/Sub)**: 发布者发布媒体轨道，订阅者订阅感兴趣的轨道
* **轨道 (Track)**: 媒体数据的逻辑单元，如一个视频流或音频流
* **组 (Group)**: 轨道中的数据分组，通常对应一个 GOP (Group of Pictures)
* **对象 (Object)**: 组中的最小数据单元，通常对应一个媒体帧

.. code-block::

    MoQ 架构:

    发布者 ──→ MoQ Relay ──→ 订阅者 A
                    │
                    └──→ 订阅者 B
                    │
                    └──→ 订阅者 C

QUIC vs RTP/UDP
-----------------------------------------

将 QUIC 用于实时媒体传输面临一些挑战：

.. list-table::
   :header-rows: 1
   :widths: 25 37 38

   * - 方面
     - RTP/UDP
     - QUIC
   * - 延迟
     - 极低（无握手开销）
     - 1-RTT 握手（首次）
   * - 可靠性
     - 不可靠（适合实时媒体）
     - 可靠流 + 不可靠数据报
   * - 拥塞控制
     - 应用层实现（如 GCC）
     - 内置（可能与媒体需求冲突）
   * - 加密
     - SRTP（仅加密负载）
     - 全部加密（包括头部）
   * - 生态系统
     - 成熟，广泛部署
     - 新兴，快速发展
   * - 中间设备
     - 可被中间设备检查/优化
     - 加密头部，中间设备无法干预

媒体传输的挑战
-----------------------------------------

使用 QUIC 进行实时媒体传输需要解决以下问题：

1. **延迟与可靠性的权衡**: 实时媒体通常宁可丢帧也不愿等待重传。QUIC 的可靠流不适合这种场景，需要使用 DATAGRAM 扩展
2. **拥塞控制适配**: 传统的 QUIC 拥塞控制（如 Cubic、BBR）针对吞吐量优化，可能不适合实时媒体的低延迟需求
3. **优先级调度**: 视频的 I 帧比 P 帧更重要，音频通常比视频更重要，需要灵活的优先级机制
4. **部分可靠性**: 某些媒体帧可以丢弃（如过期的视频帧），但 QUIC 流是完全可靠的


HTTP/3 与 QUIC
=======================================

HTTP/3 是 HTTP 协议的第三个主要版本，使用 QUIC 作为传输层。HTTP/3 的主要改进：

* **消除队头阻塞**: 每个 HTTP 请求/响应使用独立的 QUIC 流
* **更快的连接建立**: 利用 QUIC 的 1-RTT/0-RTT 握手
* **连接迁移**: 网络切换时无需重建 HTTP 连接
* **改进的头部压缩**: QPACK 替代 HPACK，适应 QUIC 的乱序特性

.. code-block::

    HTTP 协议栈演进:

    HTTP/1.1          HTTP/2           HTTP/3
    +----------+    +----------+    +----------+
    | HTTP/1.1 |    | HTTP/2   |    | HTTP/3   |
    +----------+    +----------+    +----------+
    | TLS      |    | TLS      |    | QUIC     |
    +----------+    +----------+    | (含TLS1.3)|
    | TCP      |    | TCP      |    +----------+
    +----------+    +----------+    | UDP      |
    | IP       |    | IP       |    +----------+
    +----------+    +----------+    | IP       |
                                    +----------+


QUIC 实现
=======================================

主要的开源 QUIC 实现：

.. list-table::
   :header-rows: 1
   :widths: 20 20 30 30

   * - 实现
     - 组织
     - 语言
     - 特点
   * - quiche
     - Cloudflare
     - Rust
     - 高性能，用于 Cloudflare CDN
   * - msquic
     - Microsoft
     - C
     - Windows 原生支持，跨平台
   * - ngtcp2
     - 开源社区
     - C
     - 轻量级，与 nghttp3 配合
   * - quinn
     - 开源社区
     - Rust
     - 纯 Rust 实现，async/await
   * - quic-go
     - 开源社区
     - Go
     - Go 语言实现
   * - aioquic
     - 开源社区
     - Python
     - Python asyncio 实现
   * - Chromium QUIC
     - Google
     - C++
     - Chrome 浏览器内置

.. code-block:: bash

    # 使用 quiche 运行 QUIC 服务器示例
    cargo run --example server -- --cert cert.pem --key key.pem --listen 0.0.0.0:4433

    # 使用 curl 测试 HTTP/3
    curl --http3 https://example.com/


QUIC 在 WebRTC 生态中的现状
=======================================

QUIC 在 WebRTC 生态系统中的应用正在快速发展：

* **WebTransport**: 已在主流浏览器中实现，可作为 DataChannel 的替代方案
* **Media over QUIC (MoQ)**: IETF 工作组活跃开发中，目标是标准化基于 QUIC 的媒体传输
* **QUIC for RTC**: 一些厂商正在探索使用 QUIC 替代 RTP/SRTP 进行实时通信
* **信令传输**: QUIC/HTTP3 可用于 WebRTC 信令通道，提供更低延迟的信令传输

未来展望：

1. QUIC 可能不会完全替代 RTP/SRTP，但会在特定场景中提供更好的选择
2. WebTransport 将成为 WebRTC DataChannel 的有力补充
3. MoQ 可能成为直播和大规模媒体分发的新标准
4. QUIC 的连接迁移特性对移动端实时通信特别有价值


协议文档结构
=======================================

RFC 9000 的文档结构如下：

Streams 是 QUIC 提供的基本服务抽象：

* Section 2 描述了与流相关的核心概念
* Section 3 提供了流状态的参考模型
* Section 4 概述了流量控制的操作

Connections 是 QUIC 端点通信的上下文：

* Section 5 描述了与连接相关的核心概念
* Section 6 描述了版本协商
* Section 7 详细说明了建立连接的过程
* Section 8 描述了地址验证和关键的拒绝服务缓解措施
* Section 9 描述了端点如何将连接迁移到新的网络路径
* Section 10 列出了终止打开连接的选项
* Section 11 提供了流和连接错误处理的指导

Packets 和 Frames 是 QUIC 通信的基本单元：

* Section 12 描述了与数据包和帧相关的概念
* Section 13 定义了数据传输、重传和确认的模型
* Section 14 指定了管理承载 QUIC 数据包的数据报大小的规则

编码细节：

* Section 15 (版本)
* Section 16 (整数编码)
* Section 17 (数据包头部)
* Section 18 (传输参数)
* Section 19 (帧)
* Section 20 (错误)


参考资料
=======================================

* `RFC 9000 - QUIC: A UDP-Based Multiplexed and Secure Transport <https://www.rfc-editor.org/rfc/rfc9000.html>`_
* `RFC 9001 - Using TLS to Secure QUIC <https://www.rfc-editor.org/rfc/rfc9001.html>`_
* `RFC 9002 - QUIC Loss Detection and Congestion Control <https://www.rfc-editor.org/rfc/rfc9002.html>`_
* `RFC 9114 - HTTP/3 <https://www.rfc-editor.org/rfc/rfc9114.html>`_
* `RFC 9221 - An Unreliable Datagram Extension to QUIC <https://www.rfc-editor.org/rfc/rfc9221.html>`_
* `WebTransport Specification <https://w3c.github.io/webtransport/>`_
* `Media over QUIC (MoQ) Working Group <https://datatracker.ietf.org/wg/moq/about/>`_
* `HTTP/3 explained by Daniel Stenberg <https://http3-explained.haxx.se/>`_
