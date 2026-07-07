########################
WHIP 协议
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WHIP protocol
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=======================

在流媒体领域，RTMP, HLS 以及 DASH 是比较流行的技术，不过现在 WebRTC 后来居上，提供了另外一个选项。
虽然对于 CDN 的支持还有待提高，可是它的低延迟却秒杀传统的流媒体协议。

然而，WebRTC 的信令（Signaling）部分并没有被标准化。每个 WebRTC 应用都需要自行实现信令服务器，
这导致了不同平台之间的互操作性问题。为了解决这个问题，IETF 的 WISH（WebRTC-HTTP Ingestion Signaling Protocol）
工作组提出了 **WHIP (WebRTC-HTTP Ingestion Protocol)** 协议。

WHIP 是什么
-----------------------

WHIP 全称为 **WebRTC-HTTP Ingestion Protocol**，即 WebRTC-HTTP 推流协议。
它是一个基于 HTTP 的简单信令协议，用于在 WebRTC 端点和媒体服务器之间建立单向的推流（ingestion）会话。

WHIP 的核心思想非常简单：

* 使用 **HTTP POST** 发送 SDP Offer，服务器返回 SDP Answer
* 使用 **HTTP PATCH** 发送 Trickle ICE candidates
* 使用 **HTTP DELETE** 终止会话
* 使用 **HTTP OPTIONS** 发现 endpoint 能力

这种设计使得 WHIP 成为一个极其轻量级的信令协议，不需要 WebSocket 或其他长连接机制。

WHIP 解决了什么问题
-----------------------

在 WHIP 出现之前，WebRTC 推流面临以下问题：

1. **信令碎片化**: 每个 WebRTC 平台都有自己的信令实现，互不兼容
2. **复杂度高**: 需要实现 WebSocket 服务器、自定义信令协议等
3. **缺乏标准化**: 没有统一的推流接口，OBS 等工具无法直接支持 WebRTC 推流
4. **与现有基础设施不兼容**: CDN、负载均衡器等 HTTP 基础设施无法直接使用

WHIP 通过将信令简化为标准的 HTTP 请求/响应，解决了上述所有问题。

WHIP vs RTMP 对比
-----------------------

.. list-table:: WHIP 与 RTMP 对比
   :header-rows: 1
   :widths: 25 35 35

   * - 特性
     - RTMP
     - WHIP (WebRTC)
   * - 端到端延迟
     - 3-10 秒
     - < 500 毫秒
   * - 浏览器原生支持
     - 否（需要 Flash，已废弃）
     - 是（WebRTC API）
   * - 传输协议
     - TCP
     - UDP (SRTP/DTLS)
   * - 加密
     - RTMPS (TLS)
     - DTLS/SRTP（强制）
   * - 信令复杂度
     - 中等（TCP 握手 + RTMP 握手）
     - 低（单次 HTTP POST）
   * - 编解码器支持
     - H.264, AAC
     - H.264, VP8, VP9, AV1, Opus
   * - 自适应码率
     - 有限
     - 原生支持（Simulcast, SVC）
   * - NAT 穿越
     - 不支持
     - ICE/STUN/TURN
   * - CDN 集成
     - 成熟
     - 发展中
   * - 工具支持
     - OBS, FFmpeg 等
     - OBS 30+, GStreamer, 浏览器

虽然 RTMP 在 CDN 集成方面更加成熟，但 WHIP 在延迟、安全性和浏览器支持方面具有明显优势。
随着越来越多的媒体服务器和 CDN 支持 WHIP，它正在逐步取代 RTMP 成为新一代的推流标准。


WHIP 协议详解
=======================

WHIP 协议基于 HTTP/HTTPS，定义了一组简单的 RESTful 操作来管理 WebRTC 会话的生命周期。

HTTP POST: 创建会话
-----------------------

客户端通过向 WHIP endpoint 发送 HTTP POST 请求来创建一个新的 WebRTC 会话。
请求体（body）包含客户端生成的 SDP Offer，服务器返回 SDP Answer。

**请求格式:**

* Method: ``POST``
* Content-Type: ``application/sdp``
* Authorization: ``Bearer <token>`` （可选，用于认证）
* Body: SDP Offer

**响应格式:**

* Status: ``201 Created``
* Content-Type: ``application/sdp``
* Location: 新创建的 resource URL（用于后续 PATCH/DELETE 操作）
* Body: SDP Answer

**完整的 HTTP 请求示例:**

.. code-block:: http

   POST /whip/endpoint HTTP/1.1
   Host: whip.example.com
   Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   Content-Type: application/sdp
   Content-Length: 1234

   v=0
   o=- 5228595038118931041 2 IN IP4 127.0.0.1
   s=-
   t=0 0
   a=group:BUNDLE 0 1
   a=extmap-allow-mixed
   a=msid-semantic: WMS stream0
   m=audio 9 UDP/TLS/RTP/SAVPF 111
   c=IN IP4 0.0.0.0
   a=rtcp:9 IN IP4 0.0.0.0
   a=ice-ufrag:EsAw
   a=ice-pwd:bP+XJMM09aR8AiX1jdukzR6Y
   a=ice-options:trickle
   a=fingerprint:sha-256 D1:3C:22:AB:F5:...
   a=setup:actpass
   a=mid:0
   a=sendonly
   a=rtcp-mux
   a=rtpmap:111 opus/48000/2
   a=fmtp:111 minptime=10;useinbandfec=1
   m=video 9 UDP/TLS/RTP/SAVPF 96
   c=IN IP4 0.0.0.0
   a=rtcp:9 IN IP4 0.0.0.0
   a=ice-ufrag:EsAw
   a=ice-pwd:bP+XJMM09aR8AiX1jdukzR6Y
   a=ice-options:trickle
   a=fingerprint:sha-256 D1:3C:22:AB:F5:...
   a=setup:actpass
   a=mid:1
   a=sendonly
   a=rtcp-mux
   a=rtpmap:96 VP8/90000
   a=rtcp-fb:96 nack
   a=rtcp-fb:96 nack pli
   a=rtcp-fb:96 ccm fir

**完整的 HTTP 响应示例:**

.. code-block:: http

   HTTP/1.1 201 Created
   Content-Type: application/sdp
   Location: https://whip.example.com/whip/resource/abc123
   ETag: "v1"
   Content-Length: 1024

   v=0
   o=- 1657793490019 1 IN IP4 127.0.0.1
   s=-
   t=0 0
   a=group:BUNDLE 0 1
   a=msid-semantic: WMS *
   m=audio 9 UDP/TLS/RTP/SAVPF 111
   c=IN IP4 0.0.0.0
   a=rtcp:9 IN IP4 0.0.0.0
   a=ice-ufrag:Srvr
   a=ice-pwd:serverpassword123456789012
   a=ice-options:ice2
   a=fingerprint:sha-256 A2:B3:C4:D5:E6:...
   a=setup:passive
   a=mid:0
   a=recvonly
   a=rtcp-mux
   a=rtpmap:111 opus/48000/2
   a=candidate:1 1 UDP 2130706431 198.51.100.1 3478 typ host
   m=video 9 UDP/TLS/RTP/SAVPF 96
   c=IN IP4 0.0.0.0
   a=rtcp:9 IN IP4 0.0.0.0
   a=ice-ufrag:Srvr
   a=ice-pwd:serverpassword123456789012
   a=ice-options:ice2
   a=fingerprint:sha-256 A2:B3:C4:D5:E6:...
   a=setup:passive
   a=mid:1
   a=recvonly
   a=rtcp-mux
   a=rtpmap:96 VP8/90000
   a=candidate:1 1 UDP 2130706431 198.51.100.1 3478 typ host

注意事项：

* 服务器返回的 ``Location`` header 是后续操作（PATCH, DELETE）的目标 URL
* 服务器的 SDP Answer 中 ``a=setup:passive`` 表示服务器作为 DTLS 被动方
* 服务器的 SDP Answer 中 ``a=recvonly`` 表示服务器只接收媒体流
* ``ETag`` header 用于后续 PATCH 请求的条件更新


HTTP PATCH: Trickle ICE
-----------------------

当客户端发现新的 ICE candidate 时，可以通过 HTTP PATCH 请求将其发送给服务器。
这实现了 Trickle ICE 机制，允许在 ICE 收集过程中逐步发送 candidate，而不必等待所有 candidate 收集完毕。

**请求格式:**

* Method: ``PATCH``
* URL: POST 响应中 ``Location`` header 指定的 resource URL
* Content-Type: ``application/trickle-ice-sdpfrag``
* If-Match: ``<ETag>`` （用于条件更新）
* Body: ICE candidate(s) in SDP fragment format

**请求示例:**

.. code-block:: http

   PATCH /whip/resource/abc123 HTTP/1.1
   Host: whip.example.com
   Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   Content-Type: application/trickle-ice-sdpfrag
   If-Match: "v1"

   a=ice-ufrag:EsAw
   a=ice-pwd:bP+XJMM09aR8AiX1jdukzR6Y
   a=candidate:1 1 UDP 2130706431 192.0.2.1 50000 typ host
   a=candidate:2 1 UDP 1694498815 198.51.100.1 3478 typ srflx raddr 192.0.2.1 rport 50000

**响应示例:**

.. code-block:: http

   HTTP/1.1 204 No Content
   ETag: "v2"

当 ICE 收集完成时，客户端发送 end-of-candidates 指示：

.. code-block:: http

   PATCH /whip/resource/abc123 HTTP/1.1
   Host: whip.example.com
   Content-Type: application/trickle-ice-sdpfrag
   If-Match: "v2"

   a=ice-ufrag:EsAw
   a=ice-pwd:bP+XJMM09aR8AiX1jdukzR6Y
   a=end-of-candidates

如果服务器也有新的 ICE candidate 需要发送给客户端，可以在 PATCH 响应体中返回：

.. code-block:: http

   HTTP/1.1 200 OK
   Content-Type: application/trickle-ice-sdpfrag
   ETag: "v3"

   a=ice-ufrag:Srvr
   a=ice-pwd:serverpassword123456789012
   a=candidate:3 1 UDP 2130706431 203.0.113.1 5000 typ host


HTTP DELETE: 终止会话
-----------------------

客户端通过向 resource URL 发送 HTTP DELETE 请求来终止 WebRTC 会话并释放服务器端资源。

**请求示例:**

.. code-block:: http

   DELETE /whip/resource/abc123 HTTP/1.1
   Host: whip.example.com
   Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

**响应示例:**

.. code-block:: http

   HTTP/1.1 200 OK

服务器在收到 DELETE 请求后，应该：

1. 关闭 WebRTC PeerConnection
2. 释放所有相关的媒体资源
3. 删除 resource URL 对应的会话状态


HTTP OPTIONS: 发现 endpoint 能力
-----------------------------------

客户端可以通过 HTTP OPTIONS 请求来发现 WHIP endpoint 支持的能力和扩展。

**请求示例:**

.. code-block:: http

   OPTIONS /whip/endpoint HTTP/1.1
   Host: whip.example.com

**响应示例:**

.. code-block:: http

   HTTP/1.1 200 OK
   Accept-Patch: application/trickle-ice-sdpfrag
   Link: <stun:stun.example.com:3478>; rel="ice-server"
   Link: <turn:turn.example.com:3478?transport=udp>; rel="ice-server"; username="user"; credential="pass"; credential-type="password"

``Link`` header 可以携带 ICE server 的配置信息，客户端可以使用这些信息来配置 RTCPeerConnection。
这样客户端就不需要单独获取 STUN/TURN 服务器的配置。


认证机制
-----------------------

WHIP 使用标准的 HTTP 认证机制，推荐使用 Bearer Token（通常是 JWT）：

.. code-block:: text

   Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

认证失败时，服务器返回：

.. code-block:: http

   HTTP/1.1 401 Unauthorized
   WWW-Authenticate: Bearer realm="whip"

也可以使用其他 HTTP 认证方案，如 Basic Auth 或自定义的 Token 方案，
但 Bearer Token 是最推荐的方式，因为它与 OAuth 2.0 生态系统兼容。


WHEP 协议
=======================

**WHEP (WebRTC-HTTP Egress Protocol)** 是 WHIP 的对称协议，用于从媒体服务器拉流（egress）。
如果说 WHIP 是 "推流协议"，那么 WHEP 就是 "拉流协议"。

WHEP 的设计理念
-----------------------

WHEP 与 WHIP 采用了对称的设计：

* 同样使用 HTTP POST 创建会话（SDP Offer/Answer 交换）
* 同样使用 HTTP PATCH 进行 Trickle ICE
* 同样使用 HTTP DELETE 终止会话
* 同样使用 HTTP OPTIONS 发现能力

WHIP 与 WHEP 的区别
-----------------------

.. list-table:: WHIP 与 WHEP 对比
   :header-rows: 1
   :widths: 25 35 35

   * - 特性
     - WHIP（推流）
     - WHEP（拉流）
   * - 媒体方向
     - 客户端 → 服务器 (sendonly)
     - 服务器 → 客户端 (recvonly)
   * - SDP 中的方向属性
     - Offer: sendonly, Answer: recvonly
     - Offer: recvonly, Answer: sendonly
   * - 典型使用场景
     - 主播推流、摄像头采集
     - 观众拉流、直播观看
   * - 客户端角色
     - 媒体发送者（Publisher）
     - 媒体接收者（Subscriber）
   * - 标准化状态
     - RFC 9725
     - draft-murillo-whep

**WHEP 请求示例:**

.. code-block:: http

   POST /whep/endpoint/stream123 HTTP/1.1
   Host: whep.example.com
   Content-Type: application/sdp
   Authorization: Bearer <token>

   v=0
   o=- 1234567890 2 IN IP4 127.0.0.1
   s=-
   t=0 0
   a=group:BUNDLE 0 1
   m=audio 9 UDP/TLS/RTP/SAVPF 111
   c=IN IP4 0.0.0.0
   a=mid:0
   a=recvonly
   a=rtpmap:111 opus/48000/2
   m=video 9 UDP/TLS/RTP/SAVPF 96
   c=IN IP4 0.0.0.0
   a=mid:1
   a=recvonly
   a=rtpmap:96 VP8/90000


工作流程
=======================

完整的 WHIP 信令交换时序
----------------------------

以下是一个完整的 WHIP 推流会话的时序图：

.. code-block::

   Publisher                    WHIP Endpoint              Media Server
   (Browser/OBS)                (HTTP Server)              (SFU/MCU)
       |                             |                          |
       |  1. OPTIONS /whip/endpoint  |                          |
       |---------------------------->|                          |
       |  200 OK                     |                          |
       |  Link: <stun:...>           |                          |
       |  Link: <turn:...>           |                          |
       |<----------------------------|                          |
       |                             |                          |
       |  [Create RTCPeerConnection] |                          |
       |  [getUserMedia()]           |                          |
       |  [createOffer()]            |                          |
       |                             |                          |
       |  2. POST /whip/endpoint     |                          |
       |  Content-Type: application/sdp                         |
       |  Authorization: Bearer xxx  |                          |
       |  Body: SDP Offer            |                          |
       |---------------------------->|  Create session           |
       |                             |------------------------->|
       |                             |  SDP Answer              |
       |                             |<-------------------------|
       |  201 Created                |                          |
       |  Location: /whip/resource/id|                          |
       |  Body: SDP Answer           |                          |
       |<----------------------------|                          |
       |                             |                          |
       |  [setRemoteDescription()]   |                          |
       |                             |                          |
       |  3. PATCH /whip/resource/id |                          |
       |  Content-Type:              |                          |
       |   application/trickle-ice-sdpfrag                      |
       |  Body: ICE candidates       |                          |
       |---------------------------->|  Forward candidates       |
       |                             |------------------------->|
       |  204 No Content             |                          |
       |<----------------------------|                          |
       |                             |                          |
       |  [ICE Connectivity Check]   |                          |
       |   location===================|=========================>|
       |                             |                          |
       |  [DTLS Handshake]           |                          |
       |  <==========================>=========================>|
       |                             |                          |
       |  [SRTP Media Flow]          |                          |
       |  ========================== |=========================>|
       |  (Audio + Video)            |                          |
       |                             |                          |
       |  ... streaming ...          |                          |
       |                             |                          |
       |  4. DELETE /whip/resource/id|                          |
       |---------------------------->|  Terminate session        |
       |                             |------------------------->|
       |  200 OK                     |                          |
       |<----------------------------|                          |
       |                             |                          |

简化流程说明
-----------------------

1. **能力发现（可选）**: 客户端通过 OPTIONS 请求获取 ICE server 配置
2. **会话创建**: 客户端发送 SDP Offer，服务器返回 SDP Answer 和 resource URL
3. **ICE 候选交换**: 客户端通过 PATCH 请求发送 ICE candidates
4. **媒体传输**: ICE 连通性检查和 DTLS 握手完成后，开始 SRTP 媒体传输
5. **会话终止**: 客户端发送 DELETE 请求终止会话


SDP 协商细节
=======================

WHIP 中的 SDP 协商遵循 WebRTC 的标准 SDP Offer/Answer 模型（`RFC3264`_），但有一些特定的约定。

Codec 选择
-----------------------

WHIP 客户端在 SDP Offer 中列出支持的编解码器，服务器在 SDP Answer 中选择要使用的编解码器。

常见的编解码器组合：

* **音频**: Opus (推荐), G.711 (兼容)
* **视频**: H.264 (广泛支持), VP8, VP9, AV1 (新一代)

.. code-block::

   # 客户端 Offer 中的视频编解码器列表
   m=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99
   a=rtpmap:96 VP8/90000
   a=rtpmap:97 H264/90000
   a=fmtp:97 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f
   a=rtpmap:98 VP9/90000
   a=rtpmap:99 AV1/90000

   # 服务器 Answer 中选择 H.264
   m=video 9 UDP/TLS/RTP/SAVPF 97
   a=rtpmap:97 H264/90000
   a=fmtp:97 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f

ICE-lite
-----------------------

许多 WHIP 媒体服务器使用 **ICE-lite** 模式，即服务器只提供 host candidate，
不主动进行连通性检查。这简化了服务器端的实现。

在 SDP Answer 中通过以下属性声明：

.. code-block::

   a=ice-lite

使用 ICE-lite 时，服务器不需要实现完整的 ICE 状态机，只需要响应客户端的连通性检查即可。

BUNDLE
-----------------------

WHIP 推荐使用 BUNDLE（`RFC8843`_）将所有媒体流复用到同一个传输通道上，
这样只需要一个 ICE/DTLS 连接即可传输音频和视频。

.. code-block::

   a=group:BUNDLE 0 1
   ...
   m=audio 9 UDP/TLS/RTP/SAVPF 111
   a=mid:0
   ...
   m=video 9 UDP/TLS/RTP/SAVPF 96
   a=mid:1

DTLS setup:passive
-----------------------

在 WHIP 场景中，服务器通常作为 DTLS 的被动方（passive），客户端作为主动方（active）。

* 客户端 Offer: ``a=setup:actpass`` （表示可以作为主动方或被动方）
* 服务器 Answer: ``a=setup:passive`` （表示服务器作为被动方）

这意味着 DTLS 握手由客户端发起，服务器等待客户端的 ClientHello 消息。

Simulcast 支持
-----------------------

WHIP 也支持 Simulcast，允许客户端同时发送多个不同分辨率/码率的视频流：

.. code-block::

   m=video 9 UDP/TLS/RTP/SAVPF 96
   a=mid:1
   a=sendonly
   a=rtpmap:96 VP8/90000
   a=simulcast:send h;m;l
   a=rid:h send
   a=rid:m send
   a=rid:l send


服务端支持
=======================

目前已有多个主流媒体服务器支持 WHIP 协议：

Janus Gateway
-----------------------

Janus 是最早支持 WHIP 的开源媒体服务器之一。通过其 Streaming 插件提供 WHIP 支持。

配置示例：

.. code-block:: json

   {
     "janus": "create",
     "plugin": "janus.plugin.streaming",
     "request": "create",
     "type": "rtp",
     "id": 1,
     "description": "WHIP Stream",
     "audio": true,
     "video": true,
     "audioport": 5002,
     "videoport": 5004
   }

WHIP endpoint URL 格式: ``https://janus.example.com/whip/<mountpoint_id>``

更多信息参见:

* https://www.meetecho.com/blog/whip-janus/
* https://www.meetecho.com/blog/whip-janus-part-ii/

Mediasoup
-----------------------

Mediasoup 通过社区贡献的 WHIP handler 支持 WHIP 协议。
需要在 Node.js 应用中集成 WHIP HTTP endpoint。

.. code-block:: javascript

   const express = require('express');
   const mediasoup = require('mediasoup');

   app.post('/whip/endpoint', async (req, res) => {
     const sdpOffer = req.body;
     // 创建 WebRtcTransport
     const transport = await router.createWebRtcTransport({...});
     // 处理 SDP Offer, 生成 Answer
     const sdpAnswer = await processOffer(transport, sdpOffer);
     res.status(201)
        .header('Location', `/whip/resource/${transport.id}`)
        .header('Content-Type', 'application/sdp')
        .send(sdpAnswer);
   });

SRS (Simple Realtime Server)
-----------------------------

SRS 从 v5 版本开始原生支持 WHIP 协议，可以直接接收 WebRTC 推流。

.. code-block:: bash

   # 启动 SRS 服务器
   docker run --rm -it -p 1935:1935 -p 1985:1985 \
     -p 8080:8080 -p 8000:8000/udp \
     ossrs/srs:5 ./objs/srs -c conf/docker.conf

WHIP 推流 URL: ``https://srs.example.com/rtc/v1/whip/?app=live&stream=livestream``

SRS 还支持 WHIP 到 RTMP、HLS、DASH 等格式的自动转换。

Cloudflare Stream
-----------------------

Cloudflare Stream 提供了商业化的 WHIP 支持，可以直接使用 WHIP 协议推流到 Cloudflare 的全球 CDN 网络。

.. code-block:: bash

   # 获取 WHIP endpoint
   curl -X POST "https://api.cloudflare.com/client/v4/accounts/{account_id}/stream/live_inputs" \
     -H "Authorization: Bearer {api_token}" \
     -H "Content-Type: application/json" \
     -d '{"meta":{"name":"WHIP Stream"},"recording":{"mode":"automatic"}}'

OvenMediaEngine (OME)
-----------------------

OvenMediaEngine 是一个开源的流媒体服务器，原生支持 WHIP 推流和 WHEP 拉流。

配置示例（Server.xml）：

.. code-block:: xml

   <Server>
     <Bind>
       <Publishers>
         <WebRTC>
           <Signalling>
             <Port>3333</Port>
           </Signalling>
           <IceCandidates>
             <IceCandidate>*:10000-10005/udp</IceCandidate>
           </IceCandidates>
         </WebRTC>
       </Publishers>
     </Bind>
   </Server>

WHIP endpoint: ``https://ome.example.com/app/stream?direction=whip``


客户端实现
=======================

OBS WHIP Output 配置
-----------------------

OBS Studio 从 30.0 版本开始原生支持 WHIP 输出。配置步骤：

1. 打开 OBS Studio → 设置 → 直播
2. 服务选择 "WHIP"
3. 填写 WHIP endpoint URL，例如: ``https://whip.example.com/whip/endpoint``
4. 填写 Bearer Token（如果需要认证）
5. 点击 "开始直播"

.. code-block::

   OBS WHIP 配置:
   ┌─────────────────────────────────────────┐
   │  服务:     WHIP                          │
   │  服务器:   https://whip.example.com/whip │
   │  Bearer Token: eyJhbGciOi...             │
   │                                          │
   │  视频编码器: H.264 (硬件加速)             │
   │  音频编码器: Opus                         │
   │  码率:      2500 Kbps                    │
   └─────────────────────────────────────────┘

OBS 的 WHIP 输出支持以下特性：

* H.264 和 AV1 视频编码
* Opus 音频编码
* Bearer Token 认证
* 自动重连

GStreamer whipsink
-----------------------

GStreamer 提供了 ``whipsink`` 元素，可以通过 WHIP 协议推流。

.. code-block:: bash

   # 使用摄像头和麦克风推流
   gst-launch-1.0 \
     v4l2src ! videoconvert ! vp8enc deadline=1 ! rtpvp8pay ! \
     queue ! application/x-rtp,media=video,encoding-name=VP8,payload=96 ! whipsink.sink_0 \
     audiotestsrc ! audioconvert ! opusenc ! rtpopuspay ! \
     queue ! application/x-rtp,media=audio,encoding-name=OPUS,payload=111 ! whipsink.sink_1 \
     whipsink name=whipsink \
       whip-endpoint="https://whip.example.com/whip/endpoint" \
       auth-token="eyJhbGciOi..."

   # 推送测试视频和音频
   gst-launch-1.0 \
     videotestsrc is-live=true ! videoconvert ! x264enc tune=zerolatency ! \
     rtph264pay ! queue ! whipsink.sink_0 \
     audiotestsrc is-live=true ! audioconvert ! opusenc ! \
     rtpopuspay ! queue ! whipsink.sink_1 \
     whipsink name=whipsink \
       whip-endpoint="https://whip.example.com/whip/endpoint"

   # 推送文件
   gst-launch-1.0 \
     filesrc location=video.mp4 ! decodebin name=demux \
     demux. ! queue ! videoconvert ! vp8enc ! rtpvp8pay ! whipsink.sink_0 \
     demux. ! queue ! audioconvert ! opusenc ! rtpopuspay ! whipsink.sink_1 \
     whipsink name=whipsink \
       whip-endpoint="https://whip.example.com/whip/endpoint"

JavaScript 浏览器端推流
-----------------------

以下是一个完整的 JavaScript WHIP 客户端实现示例：

.. code-block:: javascript

   class WHIPClient {
     constructor(endpoint, token) {
       this.endpoint = endpoint;
       this.token = token;
       this.pc = null;
       this.resourceUrl = null;
     }

     async publish(stream) {
       // 1. 创建 RTCPeerConnection
       this.pc = new RTCPeerConnection({
         iceServers: [
           { urls: 'stun:stun.l.google.com:19302' }
         ],
         bundlePolicy: 'max-bundle'
       });

       // 2. 添加媒体轨道
       stream.getTracks().forEach(track => {
         this.pc.addTrack(track, stream);
       });

       // 3. 收集 ICE candidates
       const candidates = [];
       const gatheringComplete = new Promise(resolve => {
         this.pc.onicecandidate = (event) => {
           if (event.candidate) {
             candidates.push(event.candidate);
           } else {
             resolve(); // ICE gathering complete
           }
         };
       });

       // 4. 创建 SDP Offer
       const offer = await this.pc.createOffer();
       await this.pc.setLocalDescription(offer);

       // 等待 ICE 收集完成（简单模式，非 Trickle ICE）
       await gatheringComplete;

       // 5. 发送 HTTP POST 请求
       const headers = {
         'Content-Type': 'application/sdp'
       };
       if (this.token) {
         headers['Authorization'] = `Bearer ${this.token}`;
       }

       const response = await fetch(this.endpoint, {
         method: 'POST',
         headers: headers,
         body: this.pc.localDescription.sdp
       });

       if (response.status !== 201) {
         throw new Error(`WHIP request failed: ${response.status}`);
       }

       // 6. 获取 resource URL 和 SDP Answer
       this.resourceUrl = response.headers.get('Location');
       const sdpAnswer = await response.text();

       // 7. 设置远端描述
       await this.pc.setRemoteDescription({
         type: 'answer',
         sdp: sdpAnswer
       });

       console.log('WHIP session established!');
       console.log('Resource URL:', this.resourceUrl);
     }

     async stop() {
       // 发送 DELETE 请求终止会话
       if (this.resourceUrl) {
         const headers = {};
         if (this.token) {
           headers['Authorization'] = `Bearer ${this.token}`;
         }
         await fetch(this.resourceUrl, {
           method: 'DELETE',
           headers: headers
         });
       }

       // 关闭 PeerConnection
       if (this.pc) {
         this.pc.close();
         this.pc = null;
       }

       console.log('WHIP session terminated.');
     }
   }

   // 使用示例
   async function startStreaming() {
     try {
       // 获取摄像头和麦克风
       const stream = await navigator.mediaDevices.getUserMedia({
         video: { width: 1280, height: 720 },
         audio: true
       });

       // 创建 WHIP 客户端并开始推流
       const client = new WHIPClient(
         'https://whip.example.com/whip/endpoint',
         'your-bearer-token-here'
       );
       await client.publish(stream);

       // 显示本地预览
       document.getElementById('preview').srcObject = stream;

       // 停止推流
       document.getElementById('stopBtn').onclick = () => {
         client.stop();
         stream.getTracks().forEach(t => t.stop());
       };
     } catch (error) {
       console.error('Failed to start streaming:', error);
     }
   }

支持 Trickle ICE 的增强版本
---------------------------------

.. code-block:: javascript

   class WHIPClientWithTrickleICE {
     constructor(endpoint, token) {
       this.endpoint = endpoint;
       this.token = token;
       this.pc = null;
       this.resourceUrl = null;
       this.etag = null;
       this.pendingCandidates = [];
       this.canTrickle = false;
     }

     async publish(stream) {
       this.pc = new RTCPeerConnection({
         iceServers: [
           { urls: 'stun:stun.l.google.com:19302' }
         ],
         bundlePolicy: 'max-bundle'
       });

       stream.getTracks().forEach(track => {
         this.pc.addTrack(track, stream);
       });

       // 处理 Trickle ICE candidates
       this.pc.onicecandidate = async (event) => {
         if (!this.canTrickle) {
           if (event.candidate) {
             this.pendingCandidates.push(event.candidate);
           }
           return;
         }
         await this.sendCandidate(event.candidate);
       };

       // 创建并发送 Offer
       const offer = await this.pc.createOffer();
       await this.pc.setLocalDescription(offer);

       const headers = { 'Content-Type': 'application/sdp' };
       if (this.token) {
         headers['Authorization'] = `Bearer ${this.token}`;
       }

       const response = await fetch(this.endpoint, {
         method: 'POST',
         headers: headers,
         body: offer.sdp
       });

       if (response.status !== 201) {
         throw new Error(`WHIP error: ${response.status}`);
       }

       this.resourceUrl = response.headers.get('Location');
       this.etag = response.headers.get('ETag');
       const sdpAnswer = await response.text();

       await this.pc.setRemoteDescription({
         type: 'answer', sdp: sdpAnswer
       });

       // 发送之前缓存的 candidates
       this.canTrickle = true;
       for (const candidate of this.pendingCandidates) {
         await this.sendCandidate(candidate);
       }
       this.pendingCandidates = [];
     }

     async sendCandidate(candidate) {
       if (!this.resourceUrl) return;

       const ufrag = this.pc.localDescription.sdp
         .match(/a=ice-ufrag:(.+)/)?.[1]?.trim();
       const pwd = this.pc.localDescription.sdp
         .match(/a=ice-pwd:(.+)/)?.[1]?.trim();

       let body = `a=ice-ufrag:${ufrag}\r\na=ice-pwd:${pwd}\r\n`;
       if (candidate) {
         body += `a=${candidate.candidate}\r\n`;
       } else {
         body += `a=end-of-candidates\r\n`;
       }

       const headers = {
         'Content-Type': 'application/trickle-ice-sdpfrag'
       };
       if (this.etag) {
         headers['If-Match'] = this.etag;
       }
       if (this.token) {
         headers['Authorization'] = `Bearer ${this.token}`;
       }

       const response = await fetch(this.resourceUrl, {
         method: 'PATCH',
         headers: headers,
         body: body
       });

       if (response.headers.get('ETag')) {
         this.etag = response.headers.get('ETag');
       }
     }

     async stop() {
       if (this.resourceUrl) {
         await fetch(this.resourceUrl, { method: 'DELETE' });
       }
       if (this.pc) {
         this.pc.close();
       }
     }
   }


直播场景应用
=======================

低延迟直播
-----------------------

WHIP + WHEP 的组合为低延迟直播提供了端到端的解决方案：

.. code-block::

   推流端                    媒体服务器                   拉流端
   (OBS/Browser)            (SFU)                      (Browser)
       |                       |                           |
       |--- WHIP (推流) ------>|                           |
       |   WebRTC (SRTP)       |                           |
       |=======================>                           |
       |                       |--- WHEP (拉流) --------->|
       |                       |   WebRTC (SRTP)           |
       |                       |==========================>|
       |                       |                           |
   延迟: < 200ms            处理: < 50ms              延迟: < 200ms
                                                    总延迟: < 500ms

与传统直播方案的延迟对比：

* **RTMP + HLS**: 10-30 秒
* **RTMP + Low-Latency HLS**: 3-5 秒
* **RTMP + DASH**: 5-15 秒
* **WHIP + WHEP (WebRTC)**: < 500 毫秒

CDN 集成
-----------------------

WHIP 的 HTTP 特性使其天然适合与 CDN 集成：

1. **HTTP 负载均衡**: WHIP 的 POST 请求可以通过标准的 HTTP 负载均衡器分发
2. **TLS 终止**: CDN 边缘节点可以处理 HTTPS/TLS
3. **认证代理**: CDN 可以在边缘验证 Bearer Token
4. **地理路由**: 基于客户端位置将 WHIP 请求路由到最近的媒体服务器

.. code-block::

   推流端 --WHIP--> CDN Edge --> Origin Media Server
                       |
                       +--> Edge SFU 1 --WHEP--> 观众 A
                       |
                       +--> Edge SFU 2 --WHEP--> 观众 B
                       |
                       +--> Edge SFU 3 --WHEP--> 观众 C

RTMP → WebRTC 转换
-----------------------

在过渡期间，许多场景需要同时支持 RTMP 和 WebRTC。
媒体服务器可以同时接收 RTMP 和 WHIP 推流，并转换为多种输出格式：

.. code-block::

   RTMP 推流 ──┐
               ├──> 媒体服务器 ──┬──> WHEP (WebRTC 低延迟拉流)
   WHIP 推流 ──┘                ├──> HLS  (兼容性拉流)
                                ├──> DASH (自适应码率)
                                └──> RTMP (转推到其他平台)

SRS 等媒体服务器已经支持这种多协议转换能力。例如：

.. code-block:: bash

   # SRS 同时支持 RTMP 和 WHIP 推流
   # RTMP 推流
   ffmpeg -re -i input.mp4 -c copy -f flv rtmp://srs.example.com/live/stream

   # WHIP 推流 (使用 GStreamer)
   gst-launch-1.0 ... whipsink whip-endpoint="https://srs.example.com/rtc/v1/whip/?app=live&stream=stream"

   # 两种推流方式的内容都可以通过以下方式拉流:
   # WebRTC (WHEP): https://srs.example.com/rtc/v1/whep/?app=live&stream=stream
   # HLS:           https://srs.example.com/live/stream.m3u8
   # HTTP-FLV:      https://srs.example.com/live/stream.flv


错误处理与最佳实践
=======================

常见错误码
-----------------------

.. list-table:: WHIP 常见 HTTP 错误码
   :header-rows: 1
   :widths: 15 25 55

   * - 状态码
     - 含义
     - 说明
   * - 400
     - Bad Request
     - SDP Offer 格式错误或不支持的编解码器
   * - 401
     - Unauthorized
     - Bearer Token 缺失或无效
   * - 403
     - Forbidden
     - Token 有效但权限不足
   * - 404
     - Not Found
     - WHIP endpoint 或 resource URL 不存在
   * - 405
     - Method Not Allowed
     - 不支持的 HTTP 方法
   * - 409
     - Conflict
     - 资源已存在（重复推流）
   * - 422
     - Unprocessable Entity
     - SDP 协商失败
   * - 500
     - Internal Server Error
     - 服务器内部错误

最佳实践
-----------------------

1. **使用 HTTPS**: WHIP 应始终通过 HTTPS 传输，保护 SDP 和 Token 的安全
2. **实现重连逻辑**: 网络中断时自动重新发送 POST 请求建立新会话
3. **使用 Trickle ICE**: 减少首帧延迟，不必等待所有 ICE candidate 收集完毕
4. **设置合理的超时**: HTTP 请求超时建议 10-30 秒
5. **处理 Location header**: 确保正确解析相对和绝对 URL
6. **Token 刷新**: 长时间推流时注意 Bearer Token 的过期和刷新


参考文献
=============

* `RFC 9725`_: WebRTC-HTTP Ingestion Protocol (WHIP)
* `draft-murillo-whep`_: WebRTC-HTTP Egress Protocol (WHEP)
* `State of #webrtc in Media Streaming and Broadcast`_

.. _State of #webrtc in Media Streaming and Broadcast: http://webrtcbydralex.com/index.php/2020/04/14/state-of-webrtc-in-media-streaming-and-broadcast/
.. _RFC 9725: https://datatracker.ietf.org/doc/rfc9725/
.. _draft-murillo-whep: https://datatracker.ietf.org/doc/draft-murillo-whep/

* https://www.meetecho.com/blog/whip-janus/
* https://www.meetecho.com/blog/whip-janus-part-ii/
* https://github.com/nicobao/whip-whep-demo
* https://webrtcforthecurious.com/
* https://bloggeek.me/whip-whep-webrtc-live-streaming/
