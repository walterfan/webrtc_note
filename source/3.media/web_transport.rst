########################
Web Transport
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Web Transport
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


Overview
=========================

WebTransport 是一种基于 HTTP/3 (QUIC) 的新型网络传输 API，为 Web 应用提供低延迟的双向通信能力。
它可以发送和接收可靠的有序数据流，也可以发送不可靠的无序数据报 (datagram)，
这使得它非常适合实时音视频和游戏等低延迟场景。


核心特性
=========================

WebTransport 提供了以下关键能力：

* **双向流 (Bidirectional Streams)**: 客户端和服务器都可以创建双向字节流
* **单向流 (Unidirectional Streams)**: 支持单方向的数据流传输
* **数据报 (Datagrams)**: 不可靠、无序的消息传递，类似 UDP
* **多路复用**: 在单个连接上支持多条并发流，无队头阻塞
* **基于 QUIC**: 继承 QUIC 的 0-RTT 连接建立、连接迁移等优势

.. code-block:: javascript

   // 创建 WebTransport 连接
   const transport = new WebTransport("https://example.com:4433/wt");
   await transport.ready;

   // 发送 Datagram (不可靠，低延迟)
   const writer = transport.datagrams.writable.getWriter();
   await writer.write(new Uint8Array([0x01, 0x02, 0x03]));

   // 创建双向流 (可靠)
   const stream = await transport.createBidirectionalStream();
   const streamWriter = stream.writable.getWriter();
   await streamWriter.write(new TextEncoder().encode("hello"));

   // 接收数据报
   const reader = transport.datagrams.readable.getReader();
   const { value, done } = await reader.read();


与 WebSocket 对比
=========================

.. list-table::
   :header-rows: 1
   :widths: 25 35 35

   * - 特性
     - WebSocket
     - WebTransport
   * - 底层协议
     - TCP
     - QUIC (UDP)
   * - 队头阻塞
     - 有 (TCP 层)
     - 无 (流级别独立)
   * - 可靠性
     - 仅可靠传输
     - 可靠流 + 不可靠数据报
   * - 多路复用
     - 单流
     - 多流并发
   * - 连接建立
     - TCP + TLS 握手
     - QUIC 0-RTT / 1-RTT
   * - 延迟
     - 较高
     - 更低
   * - 安全性
     - wss:// (TLS)
     - 强制 TLS 1.3
   * - 浏览器支持
     - 广泛
     - Chrome 97+, Edge 97+


在 WebRTC 中的应用
=========================

WebTransport 可以在多个方面补充或替代 WebRTC 的部分功能：

信令传输
-----------

传统 WebRTC 需要额外的信令服务器 (通常基于 WebSocket)。WebTransport 可以作为更高效的信令通道，
利用 QUIC 的低延迟特性加速 SDP Offer/Answer 交换和 ICE Candidate 传递。

媒体数据传输
--------------

对于某些场景，WebTransport 的 Datagram API 可以替代 WebRTC 的 DataChannel：

* **不可靠模式**: 使用 Datagram 发送实时音视频数据，丢包不重传
* **可靠模式**: 使用 Stream 传输文件、字幕等需要可靠传输的数据
* **混合模式**: 同一连接上同时使用可靠流和不可靠数据报

.. code-block:: javascript

   // 使用 WebTransport 传输媒体数据的示例
   async function sendMediaFrame(transport, frame) {
     // 对于实时媒体，使用不可靠的 datagram
     const writer = transport.datagrams.writable.getWriter();
     const header = new Uint8Array(4);
     new DataView(header.buffer).setUint32(0, frame.timestamp);
     const packet = new Uint8Array(header.length + frame.data.length);
     packet.set(header);
     packet.set(frame.data, header.length);
     await writer.write(packet);
     writer.releaseLock();
   }

与 WebCodecs 结合
--------------------

WebTransport + WebCodecs 的组合被视为下一代 Web 实时通信方案：

1. **WebCodecs** 负责音视频的编解码
2. **WebTransport** 负责编码后数据的网络传输
3. 应用层可以完全控制拥塞控制、FEC、Jitter Buffer 等策略

这种方案相比 WebRTC 更加灵活，开发者可以根据具体场景定制传输策略，
但也意味着需要自行实现 WebRTC 内置的许多功能。


服务端实现
=========================

常见的 WebTransport 服务端实现：

* **aioquic** (Python): 基于 asyncio 的 QUIC 实现
* **quiche** (Rust): Cloudflare 开源的 QUIC 库
* **msquic** (C): Microsoft 开源的跨平台 QUIC 实现
* **Go**: ``quic-go`` 库支持 WebTransport

.. code-block:: python

   # aioquic 服务端示例 (简化)
   from aioquic.quic.configuration import QuicConfiguration
   from aioquic.h3.connection import H3Connection

   config = QuicConfiguration(is_client=False)
   config.load_cert_chain("cert.pem", "key.pem")
   # 启动 HTTP/3 服务器并处理 WebTransport 会话


参考资料
=========================
* W3C WebTransport Spec: https://www.w3.org/TR/webtransport/
* IETF RFC 9297: HTTP Datagrams and the Capsule Protocol
* Chrome WebTransport: https://web.dev/webtransport/
