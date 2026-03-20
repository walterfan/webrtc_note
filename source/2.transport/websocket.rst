########################
WebSocket
########################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebSocket Protocol
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
======================

WebSocket 是一种在单个 TCP 连接上进行全双工通信的协议。它由 IETF 在 RFC 6455 中标准化，
并由 W3C 提供了浏览器端的 JavaScript API。WebSocket 协议使得客户端和服务器之间的数据交换变得更加简单高效，
允许服务端主动向客户端推送数据，而不需要客户端反复轮询。

全双工通信
----------------------

传统的 HTTP 协议是一种请求-响应模型：客户端发送请求，服务器返回响应。这种模型在需要实时双向通信的场景中
存在明显的局限性。WebSocket 解决了这个问题，它提供了真正的全双工通信能力：

* **客户端到服务器 (Client → Server)**: 客户端可以随时向服务器发送消息
* **服务器到客户端 (Server → Client)**: 服务器可以随时主动向客户端推送消息
* **同时双向 (Simultaneous Bidirectional)**: 两个方向的通信可以同时进行，互不阻塞

这种全双工特性使得 WebSocket 非常适合以下场景：

* 实时聊天应用
* 在线游戏
* 股票行情推送
* **WebRTC 信令交换** —— 这是本书最关注的应用场景
* 协同编辑（如 Google Docs）
* IoT 设备通信

ws:// 和 wss://
----------------------

WebSocket 使用两种 URI scheme：

* ``ws://`` —— 未加密的 WebSocket 连接，默认端口 80
* ``wss://`` —— 通过 TLS 加密的 WebSocket 连接，默认端口 443

在生产环境中，强烈建议使用 ``wss://``，原因如下：

1. 数据传输加密，防止中间人攻击
2. 许多代理服务器和防火墙会拦截未加密的 WebSocket 连接
3. 浏览器的安全策略越来越严格，HTTPS 页面中不允许建立 ``ws://`` 连接

.. code-block:: text

   ws://example.com:8080/signaling
   wss://example.com/signaling


WebSocket 协议详解 (RFC 6455)
=======================================

HTTP Upgrade 握手过程
---------------------------------

WebSocket 连接的建立始于一个标准的 HTTP 请求，通过 HTTP Upgrade 机制将协议从 HTTP 切换到 WebSocket。
这个过程也被称为 "Opening Handshake"。

**客户端请求 (Client Handshake Request):**

.. code-block:: http

   GET /signaling HTTP/1.1
   Host: server.example.com
   Upgrade: websocket
   Connection: Upgrade
   Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
   Origin: http://example.com
   Sec-WebSocket-Protocol: webrtc-signaling
   Sec-WebSocket-Version: 13

关键的 HTTP Header 说明：

* ``Upgrade: websocket`` —— 表示要升级到 WebSocket 协议
* ``Connection: Upgrade`` —— 表示这是一个协议升级请求
* ``Sec-WebSocket-Key`` —— 一个 Base64 编码的 16 字节随机值，用于握手验证
* ``Sec-WebSocket-Version: 13`` —— WebSocket 协议版本号
* ``Sec-WebSocket-Protocol`` —— 可选，指定子协议

**服务器响应 (Server Handshake Response):**

.. code-block:: http

   HTTP/1.1 101 Switching Protocols
   Upgrade: websocket
   Connection: Upgrade
   Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
   Sec-WebSocket-Protocol: webrtc-signaling

``Sec-WebSocket-Accept`` 的计算方式：

.. code-block:: text

   Sec-WebSocket-Accept = Base64(SHA-1(Sec-WebSocket-Key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))

其中 ``258EAFA5-E914-47DA-95CA-C5AB0DC85B11`` 是一个固定的 GUID (Magic String)，
定义在 RFC 6455 中。这个机制确保服务器确实理解 WebSocket 协议，而不是误将普通 HTTP 请求当作 WebSocket 处理。

帧格式 (Frame Format)
---------------------------------

WebSocket 协议使用帧 (Frame) 作为数据传输的基本单位。每个帧的格式如下：

.. code-block:: text

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-------+-+-------------+-------------------------------+
   |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
   |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
   |N|V|V|V|       |S|             |   (if payload len==126/127)   |
   | |1|2|3|       |K|             |                               |
   +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
   |     Extended payload length continued, if payload len == 127  |
   + - - - - - - - - - - - - - - - +-------------------------------+
   |                               |Masking-key, if MASK set to 1  |
   +-------------------------------+-------------------------------+
   | Masking-key (continued)       |          Payload Data         |
   +-------------------------------- - - - - - - - - - - - - - - - +
   :                     Payload Data continued ...                :
   + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
   |                     Payload Data continued ...                |
   +---------------------------------------------------------------+

各字段说明：

* **FIN (1 bit)**: 表示这是消息的最后一个分片。如果消息只有一个帧，FIN 为 1。
* **RSV1, RSV2, RSV3 (各 1 bit)**: 保留位，通常为 0。扩展协议可能会使用这些位（如 permessage-deflate 使用 RSV1）。
* **Opcode (4 bits)**: 定义帧的类型

  - ``0x0`` —— Continuation Frame（续帧）
  - ``0x1`` —— Text Frame（文本帧，UTF-8 编码）
  - ``0x2`` —— Binary Frame（二进制帧）
  - ``0x8`` —— Connection Close（关闭连接）
  - ``0x9`` —— Ping
  - ``0xA`` —— Pong

* **MASK (1 bit)**: 表示 Payload 是否经过掩码处理。客户端发送的帧必须设置掩码，服务器发送的帧不设置掩码。
* **Payload Length (7 bits / 7+16 bits / 7+64 bits)**:

  - 0-125: 直接表示 payload 长度
  - 126: 后续 2 字节表示 payload 长度（16-bit unsigned integer）
  - 127: 后续 8 字节表示 payload 长度（64-bit unsigned integer）

* **Masking Key (0 or 4 bytes)**: 如果 MASK 位为 1，则包含 4 字节的掩码密钥
* **Payload Data**: 实际传输的数据

控制帧 (Control Frames)
---------------------------------

控制帧用于管理 WebSocket 连接的状态，其 payload 长度不能超过 125 字节，且不能被分片。

**Close Frame (0x8)**

用于发起关闭连接的握手。Payload 可以包含一个 2 字节的状态码和一个可选的关闭原因字符串。

常见的关闭状态码：

.. list-table:: WebSocket 关闭状态码
   :header-rows: 1
   :widths: 15 30 55

   * - 状态码
     - 名称
     - 说明
   * - 1000
     - Normal Closure
     - 正常关闭
   * - 1001
     - Going Away
     - 端点离开（如服务器关闭、页面导航）
   * - 1002
     - Protocol Error
     - 协议错误
   * - 1003
     - Unsupported Data
     - 收到不支持的数据类型
   * - 1006
     - Abnormal Closure
     - 异常关闭（连接未正常关闭）
   * - 1008
     - Policy Violation
     - 违反策略
   * - 1009
     - Message Too Big
     - 消息过大
   * - 1011
     - Internal Error
     - 服务器内部错误

**Ping Frame (0x9)**

用于检测连接是否仍然存活。收到 Ping 帧后，端点必须尽快回复一个 Pong 帧，
且 Pong 帧的 Payload 必须与 Ping 帧的 Payload 完全相同。

**Pong Frame (0xA)**

作为 Ping 帧的响应。也可以作为单向心跳 (unsolicited pong) 发送。

数据帧 (Data Frames)
---------------------------------

数据帧用于传输应用层数据：

* **Text Frame (0x1)**: 传输 UTF-8 编码的文本数据。在 WebRTC 信令场景中，通常使用 Text Frame 传输 JSON 格式的信令消息。
* **Binary Frame (0x2)**: 传输二进制数据。适用于传输 Protocol Buffers、MessagePack 等二进制序列化格式的数据。

消息分片 (Message Fragmentation)
-----------------------------------------

一个完整的消息可以被分成多个帧传输：

.. code-block:: text

   Frame 1: FIN=0, opcode=0x1 (Text), payload="Hello "
   Frame 2: FIN=0, opcode=0x0 (Continuation), payload="World"
   Frame 3: FIN=1, opcode=0x0 (Continuation), payload="!"

接收端需要将所有分片组装成完整的消息 "Hello World!"。分片机制允许发送端在不知道完整消息大小的情况下开始传输。


WebSocket 在 WebRTC 信令中的应用
=======================================

为什么选择 WebSocket
---------------------------------

WebRTC 本身不定义信令协议，开发者需要自行选择信令传输方案。WebSocket 是最常用的选择，原因如下：

1. **实时性**: WebSocket 提供低延迟的双向通信，信令消息可以即时送达
2. **浏览器原生支持**: 所有现代浏览器都内置了 WebSocket API，无需额外插件
3. **全双工**: 服务器可以主动推送信令消息（如远端的 ICE candidate），无需客户端轮询
4. **简单易用**: API 简洁，开发成本低
5. **广泛的服务端支持**: 几乎所有编程语言和框架都有成熟的 WebSocket 库
6. **防火墙友好**: 使用标准的 HTTP/HTTPS 端口，通常不会被防火墙拦截

信令消息格式 (JSON)
---------------------------------

在 WebRTC 信令中，通常使用 JSON 格式封装信令消息。以下是常见的信令消息类型：

**加入房间 (Join Room):**

.. code-block:: json

   {
     "type": "join",
     "roomId": "meeting-room-001",
     "userId": "user-alice",
     "displayName": "Alice"
   }

**SDP Offer:**

.. code-block:: json

   {
     "type": "offer",
     "from": "user-alice",
     "to": "user-bob",
     "roomId": "meeting-room-001",
     "sdp": {
       "type": "offer",
       "sdp": "v=0\r\no=- 4611731400430051336 2 IN IP4 127.0.0.1\r\n..."
     }
   }

**SDP Answer:**

.. code-block:: json

   {
     "type": "answer",
     "from": "user-bob",
     "to": "user-alice",
     "roomId": "meeting-room-001",
     "sdp": {
       "type": "answer",
       "sdp": "v=0\r\no=- 7614219264379location 2 IN IP4 127.0.0.1\r\n..."
     }
   }

**ICE Candidate:**

.. code-block:: json

   {
     "type": "candidate",
     "from": "user-alice",
     "to": "user-bob",
     "roomId": "meeting-room-001",
     "candidate": {
       "candidate": "candidate:842163049 1 udp 1677729535 192.168.1.100 52487 typ srflx raddr 10.0.0.1 rport 52487 generation 0",
       "sdpMLineIndex": 0,
       "sdpMid": "audio"
     }
   }

**离开房间 (Leave Room):**

.. code-block:: json

   {
     "type": "leave",
     "roomId": "meeting-room-001",
     "userId": "user-alice"
   }

Offer/Answer/ICE Candidate 交换流程
-------------------------------------------

WebRTC 通过 WebSocket 进行信令交换的典型流程如下：

.. code-block:: text

   Alice (Caller)              Signaling Server              Bob (Callee)
       |                            |                            |
       |--- join(room-001) -------->|                            |
       |                            |<--- join(room-001) --------|
       |                            |                            |
       |<-- user-joined(bob) -------|                            |
       |                            |--- user-joined(alice) ---->|
       |                            |                            |
       |  [createOffer()]           |                            |
       |  [setLocalDescription()]   |                            |
       |                            |                            |
       |--- offer(sdp) ----------->|--- offer(sdp) ------------>|
       |                            |                            |
       |                            |          [setRemoteDescription()]
       |                            |          [createAnswer()]
       |                            |          [setLocalDescription()]
       |                            |                            |
       |<-- answer(sdp) -----------|<-- answer(sdp) ------------|
       |                            |                            |
       |  [setRemoteDescription()]  |                            |
       |                            |                            |
       |--- candidate(ice) ------->|--- candidate(ice) -------->|
       |<-- candidate(ice) --------|<-- candidate(ice) ---------|
       |                            |                            |
       |  [ICE connectivity check]  |  [ICE connectivity check] |
       |                            |                            |
       |<========== P2P Media Stream (Audio/Video) ============>|


WebSocket vs 其他信令方案
=======================================

.. list-table:: 信令方案对比
   :header-rows: 1
   :widths: 18 18 18 18 28

   * - 特性
     - WebSocket
     - HTTP Long Polling
     - SSE
     - gRPC
   * - 通信方向
     - 全双工
     - 模拟双向
     - 服务器→客户端
     - 双向流
   * - 延迟
     - 低
     - 中等
     - 低（单向）
     - 低
   * - 浏览器支持
     - 原生支持
     - 原生支持
     - 原生支持
     - 需要 gRPC-Web
   * - 连接开销
     - 低（持久连接）
     - 高（频繁建连）
     - 低（持久连接）
     - 低（HTTP/2）
   * - 实现复杂度
     - 中等
     - 低
     - 低
     - 高
   * - 防火墙穿透
     - 好
     - 最好
     - 好
     - 一般
   * - 适用场景
     - WebRTC 信令首选
     - 兼容性要求高
     - 单向推送
     - 微服务间通信

**HTTP Long Polling**

客户端发送 HTTP 请求，服务器保持连接直到有新数据或超时。收到响应后客户端立即发起新请求。
这种方式实现简单，兼容性最好，但延迟较高且服务器资源消耗大。

**SSE (Server-Sent Events)**

基于 HTTP 的单向推送协议。服务器可以持续向客户端推送事件，但客户端向服务器发送数据仍需使用普通 HTTP 请求。
适合只需要服务器推送的场景，但不适合 WebRTC 信令这种需要频繁双向通信的场景。

**gRPC**

基于 HTTP/2 的 RPC 框架，支持双向流。性能优秀，但浏览器端需要 gRPC-Web 代理，增加了部署复杂度。
更适合服务端之间的信令传输。


服务端实现
=======================================

Node.js (ws 库) 完整示例
---------------------------------

使用 ``ws`` 库实现一个完整的 WebRTC 信令服务器：

.. code-block:: javascript

   const WebSocket = require('ws');
   const http = require('http');

   const server = http.createServer();
   const wss = new WebSocket.Server({ server });

   // 房间管理: roomId -> Map<userId, WebSocket>
   const rooms = new Map();

   // 心跳检测间隔 (30 秒)
   const HEARTBEAT_INTERVAL = 30000;

   wss.on('connection', function(ws, req) {
     console.log('New connection from:', req.socket.remoteAddress);

     ws.isAlive = true;
     ws.userId = null;
     ws.roomId = null;

     ws.on('pong', function() {
       ws.isAlive = true;
     });

     ws.on('message', function(data) {
       let message;
       try {
         message = JSON.parse(data);
       } catch (e) {
         ws.send(JSON.stringify({ type: 'error', message: 'Invalid JSON' }));
         return;
       }

       switch (message.type) {
         case 'join':
           handleJoin(ws, message);
           break;
         case 'offer':
         case 'answer':
         case 'candidate':
           handleSignaling(ws, message);
           break;
         case 'leave':
           handleLeave(ws);
           break;
         default:
           ws.send(JSON.stringify({ type: 'error', message: 'Unknown message type' }));
       }
     });

     ws.on('close', function() {
       handleLeave(ws);
     });

     ws.on('error', function(err) {
       console.error('WebSocket error:', err);
       handleLeave(ws);
     });
   });

   function handleJoin(ws, message) {
     const { roomId, userId } = message;
     ws.userId = userId;
     ws.roomId = roomId;

     if (!rooms.has(roomId)) {
       rooms.set(roomId, new Map());
     }

     const room = rooms.get(roomId);

     // 通知房间内已有用户
     const existingUsers = [];
     room.forEach((socket, id) => {
       existingUsers.push(id);
       socket.send(JSON.stringify({
         type: 'user-joined',
         userId: userId
       }));
     });

     // 将新用户加入房间
     room.set(userId, ws);

     // 告知新用户房间内已有哪些用户
     ws.send(JSON.stringify({
       type: 'room-info',
       roomId: roomId,
       users: existingUsers
     }));

     console.log(`User ${userId} joined room ${roomId} (${room.size} users)`);
   }

   function handleSignaling(ws, message) {
     const { to, roomId } = message;
     const room = rooms.get(roomId);

     if (!room) return;

     const targetWs = room.get(to);
     if (targetWs && targetWs.readyState === WebSocket.OPEN) {
       targetWs.send(JSON.stringify(message));
     }
   }

   function handleLeave(ws) {
     if (!ws.roomId || !ws.userId) return;

     const room = rooms.get(ws.roomId);
     if (!room) return;

     room.delete(ws.userId);

     // 通知房间内其他用户
     room.forEach((socket) => {
       socket.send(JSON.stringify({
         type: 'user-left',
         userId: ws.userId
       }));
     });

     // 如果房间为空，删除房间
     if (room.size === 0) {
       rooms.delete(ws.roomId);
     }

     console.log(`User ${ws.userId} left room ${ws.roomId}`);
     ws.userId = null;
     ws.roomId = null;
   }

   // 心跳检测
   const heartbeatTimer = setInterval(function() {
     wss.clients.forEach(function(ws) {
       if (ws.isAlive === false) {
         handleLeave(ws);
         return ws.terminate();
       }
       ws.isAlive = false;
       ws.ping();
     });
   }, HEARTBEAT_INTERVAL);

   wss.on('close', function() {
     clearInterval(heartbeatTimer);
   });

   const PORT = process.env.PORT || 8080;
   server.listen(PORT, function() {
     console.log(`Signaling server running on port ${PORT}`);
   });

Python (websockets/FastAPI) 示例
-----------------------------------------

使用 Python ``websockets`` 库实现信令服务器：

.. code-block:: python

   import asyncio
   import json
   import logging
   from collections import defaultdict
   import websockets

   logging.basicConfig(level=logging.INFO)
   logger = logging.getLogger("signaling")

   # 房间管理: room_id -> {user_id: websocket}
   rooms = defaultdict(dict)

   async def handle_connection(websocket, path):
       user_id = None
       room_id = None

       try:
           async for raw_message in websocket:
               try:
                   message = json.loads(raw_message)
               except json.JSONDecodeError:
                   await websocket.send(json.dumps({
                       "type": "error",
                       "message": "Invalid JSON"
                   }))
                   continue

               msg_type = message.get("type")

               if msg_type == "join":
                   room_id = message["roomId"]
                   user_id = message["userId"]

                   # 通知已有用户
                   existing_users = list(rooms[room_id].keys())
                   for uid, ws in rooms[room_id].items():
                       await ws.send(json.dumps({
                           "type": "user-joined",
                           "userId": user_id
                       }))

                   rooms[room_id][user_id] = websocket

                   await websocket.send(json.dumps({
                       "type": "room-info",
                       "roomId": room_id,
                       "users": existing_users
                   }))

                   logger.info(f"User {user_id} joined room {room_id}")

               elif msg_type in ("offer", "answer", "candidate"):
                   target_id = message.get("to")
                   target_ws = rooms.get(room_id, {}).get(target_id)
                   if target_ws:
                       await target_ws.send(json.dumps(message))

               elif msg_type == "leave":
                   break

       except websockets.exceptions.ConnectionClosed:
           logger.info(f"Connection closed: {user_id}")
       finally:
           if room_id and user_id:
               rooms[room_id].pop(user_id, None)
               for uid, ws in rooms[room_id].items():
                   await ws.send(json.dumps({
                       "type": "user-left",
                       "userId": user_id
                   }))
               if not rooms[room_id]:
                   del rooms[room_id]
               logger.info(f"User {user_id} left room {room_id}")

   async def main():
       async with websockets.serve(handle_connection, "0.0.0.0", 8080):
           logger.info("Signaling server started on port 8080")
           await asyncio.Future()  # run forever

   if __name__ == "__main__":
       asyncio.run(main())

使用 FastAPI 和 WebSocket 的示例：

.. code-block:: python

   from fastapi import FastAPI, WebSocket, WebSocketDisconnect
   from collections import defaultdict
   import json

   app = FastAPI()

   rooms = defaultdict(dict)

   @app.websocket("/signaling/{room_id}/{user_id}")
   async def websocket_endpoint(websocket: WebSocket, room_id: str, user_id: str):
       await websocket.accept()

       # 通知已有用户
       for uid, ws in rooms[room_id].items():
           await ws.send_json({"type": "user-joined", "userId": user_id})

       rooms[room_id][user_id] = websocket

       await websocket.send_json({
           "type": "room-info",
           "roomId": room_id,
           "users": list(rooms[room_id].keys())
       })

       try:
           while True:
               message = await websocket.receive_json()
               target_id = message.get("to")
               target_ws = rooms[room_id].get(target_id)
               if target_ws:
                   await target_ws.send_json(message)
       except WebSocketDisconnect:
           rooms[room_id].pop(user_id, None)
           for uid, ws in rooms[room_id].items():
               await ws.send_json({"type": "user-left", "userId": user_id})

Java Spring Boot WebSocket 示例
-----------------------------------------

首先添加 Maven 依赖：

.. code-block:: xml

   <dependency>
       <groupId>org.springframework.boot</groupId>
       <artifactId>spring-boot-starter-websocket</artifactId>
   </dependency>

WebSocket 配置类：

.. code-block:: java

   import org.springframework.context.annotation.Configuration;
   import org.springframework.web.socket.config.annotation.*;

   @Configuration
   @EnableWebSocket
   public class WebSocketConfig implements WebSocketConfigurer {

       @Override
       public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
           registry.addHandler(new SignalingHandler(), "/signaling")
                   .setAllowedOrigins("*");
       }
   }

信令处理器：

.. code-block:: java

   import com.fasterxml.jackson.databind.JsonNode;
   import com.fasterxml.jackson.databind.ObjectMapper;
   import org.springframework.web.socket.*;
   import org.springframework.web.socket.handler.TextWebSocketHandler;

   import java.io.IOException;
   import java.util.Map;
   import java.util.concurrent.ConcurrentHashMap;

   public class SignalingHandler extends TextWebSocketHandler {

       private static final ObjectMapper mapper = new ObjectMapper();

       // roomId -> (userId -> session)
       private final Map<String, Map<String, WebSocketSession>> rooms
           = new ConcurrentHashMap<>();

       @Override
       public void handleTextMessage(WebSocketSession session, TextMessage message)
               throws IOException {
           JsonNode json = mapper.readTree(message.getPayload());
           String type = json.get("type").asText();

           switch (type) {
               case "join":
                   handleJoin(session, json);
                   break;
               case "offer":
               case "answer":
               case "candidate":
                   handleSignaling(session, json, message);
                   break;
               case "leave":
                   handleLeave(session);
                   break;
           }
       }

       private void handleJoin(WebSocketSession session, JsonNode json)
               throws IOException {
           String roomId = json.get("roomId").asText();
           String userId = json.get("userId").asText();

           session.getAttributes().put("roomId", roomId);
           session.getAttributes().put("userId", userId);

           rooms.computeIfAbsent(roomId, k -> new ConcurrentHashMap<>());
           Map<String, WebSocketSession> room = rooms.get(roomId);

           // 通知已有用户
           for (Map.Entry<String, WebSocketSession> entry : room.entrySet()) {
               sendJson(entry.getValue(), Map.of(
                   "type", "user-joined", "userId", userId));
           }

           room.put(userId, session);
       }

       private void handleSignaling(WebSocketSession session, JsonNode json,
               TextMessage message) throws IOException {
           String roomId = (String) session.getAttributes().get("roomId");
           String targetId = json.get("to").asText();

           Map<String, WebSocketSession> room = rooms.get(roomId);
           if (room != null) {
               WebSocketSession target = room.get(targetId);
               if (target != null && target.isOpen()) {
                   target.sendMessage(message);
               }
           }
       }

       private void handleLeave(WebSocketSession session) throws IOException {
           String roomId = (String) session.getAttributes().get("roomId");
           String userId = (String) session.getAttributes().get("userId");
           if (roomId == null || userId == null) return;

           Map<String, WebSocketSession> room = rooms.get(roomId);
           if (room != null) {
               room.remove(userId);
               for (WebSocketSession ws : room.values()) {
                   sendJson(ws, Map.of("type", "user-left", "userId", userId));
               }
               if (room.isEmpty()) rooms.remove(roomId);
           }
       }

       @Override
       public void afterConnectionClosed(WebSocketSession session,
               CloseStatus status) throws IOException {
           handleLeave(session);
       }

       private void sendJson(WebSocketSession session, Object data)
               throws IOException {
           session.sendMessage(
               new TextMessage(mapper.writeValueAsString(data)));
       }
   }


客户端实现
=======================================

浏览器 WebSocket API
---------------------------------

浏览器提供了原生的 WebSocket API，使用非常简单：

.. code-block:: javascript

   // 创建 WebSocket 连接
   const ws = new WebSocket('wss://signaling.example.com/ws');

   // 连接建立
   ws.onopen = function(event) {
     console.log('WebSocket connected');
     ws.send(JSON.stringify({
       type: 'join',
       roomId: 'meeting-001',
       userId: 'alice'
     }));
   };

   // 接收消息
   ws.onmessage = function(event) {
     const message = JSON.parse(event.data);
     console.log('Received:', message);

     switch (message.type) {
       case 'offer':
         handleOffer(message);
         break;
       case 'answer':
         handleAnswer(message);
         break;
       case 'candidate':
         handleCandidate(message);
         break;
       case 'user-joined':
         handleUserJoined(message);
         break;
       case 'user-left':
         handleUserLeft(message);
         break;
     }
   };

   // 连接关闭
   ws.onclose = function(event) {
     console.log('WebSocket closed:', event.code, event.reason);
   };

   // 连接错误
   ws.onerror = function(error) {
     console.error('WebSocket error:', error);
   };

重连策略 (Reconnection Strategy)
-----------------------------------------

在生产环境中，WebSocket 连接可能因为网络波动、服务器重启等原因断开。
实现一个可靠的重连策略非常重要：

.. code-block:: javascript

   class ReconnectingWebSocket {
     constructor(url, options = {}) {
       this.url = url;
       this.maxRetries = options.maxRetries || 10;
       this.baseDelay = options.baseDelay || 1000;   // 1 秒
       this.maxDelay = options.maxDelay || 30000;     // 30 秒
       this.retryCount = 0;
       this.handlers = {};
       this.messageQueue = [];  // 断线期间的消息队列

       this.connect();
     }

     connect() {
       this.ws = new WebSocket(this.url);

       this.ws.onopen = () => {
         console.log('WebSocket connected');
         this.retryCount = 0;

         // 发送队列中积压的消息
         while (this.messageQueue.length > 0) {
           this.ws.send(this.messageQueue.shift());
         }

         if (this.handlers.open) this.handlers.open();
       };

       this.ws.onmessage = (event) => {
         if (this.handlers.message) this.handlers.message(event);
       };

       this.ws.onclose = (event) => {
         if (event.code === 1000) {
           // 正常关闭，不重连
           return;
         }
         this.scheduleReconnect();
       };

       this.ws.onerror = (error) => {
         console.error('WebSocket error:', error);
       };
     }

     scheduleReconnect() {
       if (this.retryCount >= this.maxRetries) {
         console.error('Max reconnection attempts reached');
         if (this.handlers.maxRetriesReached) {
           this.handlers.maxRetriesReached();
         }
         return;
       }

       // 指数退避 + 随机抖动 (Exponential Backoff with Jitter)
       const delay = Math.min(
         this.baseDelay * Math.pow(2, this.retryCount) + Math.random() * 1000,
         this.maxDelay
       );

       console.log(`Reconnecting in ${Math.round(delay)}ms (attempt ${this.retryCount + 1})`);
       this.retryCount++;

       setTimeout(() => this.connect(), delay);
     }

     send(data) {
       if (this.ws.readyState === WebSocket.OPEN) {
         this.ws.send(data);
       } else {
         // 连接未就绪，加入消息队列
         this.messageQueue.push(data);
       }
     }

     on(event, handler) {
       this.handlers[event] = handler;
     }

     close() {
       this.ws.close(1000, 'Normal closure');
     }
   }

   // 使用示例
   const ws = new ReconnectingWebSocket('wss://signaling.example.com/ws', {
     maxRetries: 15,
     baseDelay: 1000,
     maxDelay: 30000
   });

   ws.on('open', () => {
     ws.send(JSON.stringify({ type: 'join', roomId: 'room-1', userId: 'alice' }));
   });

   ws.on('message', (event) => {
     const msg = JSON.parse(event.data);
     console.log('Received:', msg);
   });

心跳机制 (Heartbeat)
---------------------------------

WebSocket 协议本身提供了 Ping/Pong 帧用于心跳检测，但浏览器的 WebSocket API 不暴露 Ping/Pong 接口。
因此在应用层实现心跳机制是常见做法：

.. code-block:: javascript

   class HeartbeatWebSocket {
     constructor(url) {
       this.url = url;
       this.heartbeatInterval = 25000;  // 25 秒
       this.heartbeatTimeout = 10000;   // 10 秒超时
       this.pingTimer = null;
       this.pongTimer = null;

       this.connect();
     }

     connect() {
       this.ws = new WebSocket(this.url);

       this.ws.onopen = () => {
         this.startHeartbeat();
       };

       this.ws.onmessage = (event) => {
         const message = JSON.parse(event.data);
         if (message.type === 'pong') {
           this.handlePong();
           return;
         }
         // 处理其他消息...
       };

       this.ws.onclose = () => {
         this.stopHeartbeat();
       };
     }

     startHeartbeat() {
       this.pingTimer = setInterval(() => {
         if (this.ws.readyState === WebSocket.OPEN) {
           this.ws.send(JSON.stringify({ type: 'ping', timestamp: Date.now() }));

           // 设置 pong 超时
           this.pongTimer = setTimeout(() => {
             console.warn('Heartbeat timeout, closing connection');
             this.ws.close(4000, 'Heartbeat timeout');
           }, this.heartbeatTimeout);
         }
       }, this.heartbeatInterval);
     }

     handlePong() {
       if (this.pongTimer) {
         clearTimeout(this.pongTimer);
         this.pongTimer = null;
       }
     }

     stopHeartbeat() {
       if (this.pingTimer) clearInterval(this.pingTimer);
       if (this.pongTimer) clearTimeout(this.pongTimer);
     }
   }


WebSocket 安全
=======================================

WSS (WebSocket Secure)
---------------------------------

WSS 是 WebSocket 的加密版本，使用 TLS (Transport Layer Security) 对通信进行加密。
在生产环境中必须使用 WSS：

.. code-block:: nginx

   # Nginx 反向代理配置 WSS
   server {
       listen 443 ssl;
       server_name signaling.example.com;

       ssl_certificate /etc/letsencrypt/live/signaling.example.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/signaling.example.com/privkey.pem;

       location /ws {
           proxy_pass http://127.0.0.1:8080;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;

           # WebSocket 超时设置
           proxy_read_timeout 86400s;
           proxy_send_timeout 86400s;
       }
   }

Origin 检查
---------------------------------

服务器应该验证 WebSocket 握手请求中的 ``Origin`` Header，防止跨站 WebSocket 劫持 (Cross-Site WebSocket Hijacking, CSWSH)：

.. code-block:: javascript

   // Node.js ws 库 - Origin 检查
   const wss = new WebSocket.Server({
     server,
     verifyClient: function(info) {
       const origin = info.origin || info.req.headers.origin;
       const allowedOrigins = [
         'https://app.example.com',
         'https://www.example.com'
       ];
       return allowedOrigins.includes(origin);
     }
   });

认证 Token
---------------------------------

WebSocket 握手是一个标准的 HTTP 请求，可以通过以下方式传递认证信息：

**方式一：URL 查询参数**

.. code-block:: javascript

   const ws = new WebSocket('wss://signaling.example.com/ws?token=eyJhbGciOiJIUzI1NiJ9...');

**方式二：首条消息认证**

.. code-block:: javascript

   ws.onopen = function() {
     ws.send(JSON.stringify({
       type: 'auth',
       token: 'eyJhbGciOiJIUzI1NiJ9...'
     }));
   };

**方式三：Sec-WebSocket-Protocol Header（不推荐）**

.. code-block:: javascript

   // 利用子协议字段传递 token（hack 方式，不推荐）
   const ws = new WebSocket('wss://signaling.example.com/ws',
     ['access_token', 'eyJhbGciOiJIUzI1NiJ9...']);

推荐使用方式一或方式二。方式一的缺点是 token 可能出现在服务器日志中。


WebSocket 扩展
=======================================

permessage-deflate 压缩
---------------------------------

``permessage-deflate`` 是 WebSocket 的一个扩展 (RFC 7692)，用于对消息进行压缩。
对于 JSON 格式的信令消息，压缩可以显著减少传输数据量。

在握手阶段协商压缩：

.. code-block:: http

   GET /ws HTTP/1.1
   Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits

   HTTP/1.1 101 Switching Protocols
   Sec-WebSocket-Extensions: permessage-deflate; server_max_window_bits=15

Node.js ws 库启用压缩：

.. code-block:: javascript

   const wss = new WebSocket.Server({
     port: 8080,
     perMessageDeflate: {
       zlibDeflateOptions: {
         chunkSize: 1024,
         memLevel: 7,
         level: 3
       },
       zlibInflateOptions: {
         chunkSize: 10 * 1024
       },
       // 低于此阈值的消息不压缩
       threshold: 1024,
       // 并发压缩限制
       concurrencyLimit: 10,
       // 是否在每条消息后重置压缩上下文
       serverNoContextTakeover: true
     }
   });

.. note::

   对于 WebRTC 信令场景，信令消息通常较小（几百字节到几 KB），
   启用压缩的收益有限，反而可能增加 CPU 开销。建议在消息较大或带宽受限时才启用压缩。


性能优化
=======================================

连接池管理
---------------------------------

在大规模部署中，单台服务器可能需要处理数万个 WebSocket 连接。以下是一些优化建议：

* **操作系统调优**: 增大文件描述符限制 (``ulimit -n``)，调整 TCP 参数
* **负载均衡**: 使用 Nginx 或 HAProxy 进行 WebSocket 负载均衡，注意使用 sticky session
* **水平扩展**: 使用 Redis Pub/Sub 或消息队列在多个信令服务器实例之间同步消息

.. code-block:: javascript

   // 使用 Redis 实现多实例消息同步
   const Redis = require('ioredis');
   const pub = new Redis();
   const sub = new Redis();

   sub.subscribe('signaling');

   sub.on('message', (channel, message) => {
     const data = JSON.parse(message);
     const targetWs = localConnections.get(data.to);
     if (targetWs) {
       targetWs.send(JSON.stringify(data.payload));
     }
   });

   // 当目标用户不在本实例时，通过 Redis 转发
   function forwardMessage(message) {
     pub.publish('signaling', JSON.stringify(message));
   }

消息序列化
---------------------------------

选择合适的消息序列化格式可以提升性能：

* **JSON**: 最常用，可读性好，浏览器原生支持。适合大多数信令场景。
* **MessagePack**: 二进制格式，比 JSON 更紧凑，解析更快。适合高频消息场景。
* **Protocol Buffers**: Google 的二进制序列化格式，需要预定义 schema。适合对性能要求极高的场景。

.. code-block:: javascript

   // 使用 MessagePack 替代 JSON
   const msgpack = require('msgpack-lite');

   // 编码
   const encoded = msgpack.encode({
     type: 'candidate',
     from: 'alice',
     to: 'bob',
     candidate: { /* ... */ }
   });
   ws.send(encoded);  // 发送 Binary Frame

   // 解码
   ws.on('message', (data) => {
     if (data instanceof Buffer) {
       const message = msgpack.decode(data);
       // 处理消息...
     }
   });

二进制 vs 文本
---------------------------------

WebSocket 支持文本帧和二进制帧两种数据帧类型：

* **文本帧 (Text Frame)**: 适合 JSON 等文本格式，浏览器自动进行 UTF-8 编解码
* **二进制帧 (Binary Frame)**: 适合 MessagePack、Protocol Buffers 等二进制格式，避免 Base64 编码开销

在 WebRTC 信令场景中，由于信令消息频率较低（通常每秒不超过几条），
JSON 文本帧已经足够满足需求。只有在需要传输大量数据（如文件传输信令）时，
才需要考虑使用二进制帧。


常见问题与排查
=======================================

* **连接频繁断开**: 检查代理服务器和负载均衡器的超时设置，确保 WebSocket 连接不会被过早关闭。Nginx 默认的 ``proxy_read_timeout`` 为 60 秒，需要增大。
* **消息丢失**: 确保在连接断开重连后重新加入房间，并重新发送必要的信令消息。
* **跨域问题**: WebSocket 不受同源策略限制，但服务器应该检查 Origin Header。
* **内存泄漏**: 确保在连接关闭时清理所有相关资源（房间成员列表、定时器等）。
* **消息顺序**: WebSocket 保证消息的有序传输，但在多实例部署中需要注意消息的全局顺序。


参考文献
=======================================

* `RFC 6455 - The WebSocket Protocol <https://tools.ietf.org/html/rfc6455>`_
* `RFC 7692 - Compression Extensions for WebSocket <https://tools.ietf.org/html/rfc7692>`_
* `MDN WebSocket API <https://developer.mozilla.org/en-US/docs/Web/API/WebSocket>`_
* `WebSocket API Living Standard (WHATWG) <https://websockets.spec.whatwg.org/>`_
* https://spring.io/guides/gs/messaging-stomp-websocket/
* https://developer.aliyun.com/article/613916
* `ws - Node.js WebSocket library <https://github.com/websockets/ws>`_
* `Python websockets library <https://websockets.readthedocs.io/>`_
* `FastAPI WebSocket documentation <https://fastapi.tiangolo.com/advanced/websockets/>`_
