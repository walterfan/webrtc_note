################
视频聊天实例
################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** 视频聊天实例
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================

.. contents::
   :local:

概述
================

视频聊天是 WebRTC 最典型的应用场景。一个完整的视频聊天系统需要解决以下核心问题：

1. **媒体采集**：获取摄像头和麦克风的音视频流
2. **信令交换**：协商连接参数（SDP Offer/Answer）和网络地址（ICE Candidate）
3. **NAT 穿越**：在各种网络环境下建立点对点或中继连接
4. **媒体传输**：实时传输加密的音视频数据
5. **媒体渲染**：解码并播放远端的音视频流

本章将从系统设计到代码实现，完整地介绍如何构建一个视频聊天应用。


总体设计
================

系统架构
----------------

一个典型的视频聊天系统包含以下组件：

::

    ┌─────────────────────────────────────────────────────┐
    │                    Web Application                   │
    │  ┌──────────┐    ┌──────────┐    ┌──────────┐      │
    │  │  Camera  │    │   Mic    │    │  Screen  │      │
    │  └────┬─────┘    └────┬─────┘    └────┬─────┘      │
    │       │               │               │             │
    │  ┌────▼───────────────▼───────────────▼─────┐      │
    │  │         RTCPeerConnection                 │      │
    │  └────────────────┬──────────────────────────┘      │
    └───────────────────┼──────────────────────────────────┘
                        │
           ┌────────────┼────────────┐
           │            │            │
    ┌──────▼──────┐ ┌───▼────┐ ┌────▼─────┐
    │   Signal    │ │  STUN  │ │   TURN   │
    │   Server    │ │ Server │ │  Server  │
    │ (WebSocket) │ │        │ │ (coturn) │
    └──────┬──────┘ └────────┘ └──────────┘
           │
    ┌──────▼──────────────────────────────────────────────┐
    │                    Web Application                   │
    │  ┌────────────────────────────────────────────┐     │
    │  │         RTCPeerConnection                  │     │
    │  └────┬───────────────┬───────────────┬───────┘     │
    │  ┌────▼─────┐    ┌────▼─────┐    ┌────▼─────┐      │
    │  │  Video   │    │  Audio   │    │  Screen  │      │
    │  │  Player  │    │  Player  │    │  Player  │      │
    │  └──────────┘    └──────────┘    └──────────┘      │
    └─────────────────────────────────────────────────────┘

组件详解
----------------

**1. Web 应用（前端）**

Web 应用是用户交互的界面，核心功能包括：

- 房间管理：创建/加入/离开房间
- 用户列表：显示房间内的参与者
- 媒体控制：开关摄像头/麦克风、切换摄像头
- 视频显示：本地预览和远端视频渲染
- 聊天消息：文字聊天（通过 DataChannel）

**2. 信令服务器（Signal Server）**

信令服务器负责在通信双方之间转发协商消息：

- HTTP 服务：提供 Web 页面和 REST API
- WebSocket 服务：实时双向通信，转发 SDP 和 ICE Candidate
- 房间管理：维护房间状态和用户列表
- 用户管理：加入、离开、踢出

信令服务器不接触媒体数据，只负责控制面（Control Plane）。

**3. TURN 服务器**

当 P2P 直连失败时（如对称 NAT 环境），TURN 服务器提供媒体中继：

- 推荐使用 coturn 开源项目
- 部署在公网，需要足够的带宽
- 支持 UDP/TCP/TLS 传输
- 详见本书 :doc:`../7.practice/coturn` 章节

**4. 媒体服务器（SFU，可选）**

多人视频聊天时，SFU（Selective Forwarding Unit）比 P2P Mesh 更高效：

- 每个客户端只需上传一路流到 SFU
- SFU 选择性转发给其他参与者
- 推荐使用 mediasoup 或 Janus
- 详见本书 :doc:`../7.practice/mediasoup` 章节


P2P 视频聊天实现
====================

对于 P2P 应用，我们只需要实现前端和信令服务器，省略 TURN 和 SFU。

我写了一个小例子 - https://github.com/walterfan/webrtc_video_chat

下面是核心代码的详细解析。

HTML 页面结构
----------------

.. code-block:: html

    <!DOCTYPE html>
    <html>
    <head>
        <title>WebRTC Video Chat</title>
        <style>
            .video-container {
                display: flex;
                gap: 10px;
                margin: 20px 0;
            }
            video {
                width: 480px;
                height: 360px;
                background: #000;
                border-radius: 8px;
            }
            #localVideo { transform: scaleX(-1); }  /* 镜像显示 */
            .controls { margin: 10px 0; }
            .controls button {
                padding: 8px 16px;
                margin: 0 4px;
                border-radius: 4px;
                cursor: pointer;
            }
        </style>
    </head>
    <body>
        <h1>WebRTC Video Chat</h1>
        <div>
            <input id="roomInput" placeholder="Room name" />
            <button id="joinBtn" onclick="joinRoom()">Join</button>
            <button id="leaveBtn" onclick="leaveRoom()" disabled>Leave</button>
        </div>
        <div class="video-container">
            <div>
                <h3>Local</h3>
                <video id="localVideo" autoplay muted playsinline></video>
            </div>
            <div>
                <h3>Remote</h3>
                <video id="remoteVideo" autoplay playsinline></video>
            </div>
        </div>
        <div class="controls">
            <button onclick="toggleCamera()">Toggle Camera</button>
            <button onclick="toggleMic()">Toggle Mic</button>
        </div>
        <script src="app.js"></script>
    </body>
    </html>

客户端 JavaScript 实现
--------------------------

.. code-block:: javascript

    // ============================================
    // WebRTC Video Chat - 客户端核心代码
    // ============================================

    const config = {
        iceServers: [
            { urls: 'stun:stun.l.google.com:19302' },
            { urls: 'stun:stun1.l.google.com:19302' }
        ]
    };

    let localStream = null;
    let peerConnection = null;
    let socket = null;
    let roomName = null;

    // ---- 1. 连接信令服务器 ----
    function connectSignaling() {
        socket = new WebSocket('wss://your-server.com/ws');

        socket.onopen = () => {
            console.log('Signaling connected');
        };

        socket.onmessage = async (event) => {
            const message = JSON.parse(event.data);
            await handleSignalingMessage(message);
        };

        socket.onclose = () => {
            console.log('Signaling disconnected');
            // 自动重连（指数退避）
            setTimeout(connectSignaling, 3000);
        };
    }

    // ---- 2. 处理信令消息 ----
    async function handleSignalingMessage(message) {
        switch (message.type) {
            case 'user-joined':
                // 新用户加入，作为 Offerer 发起连接
                console.log('User joined, creating offer...');
                await createPeerConnection();
                const offer = await peerConnection.createOffer();
                await peerConnection.setLocalDescription(offer);
                sendSignaling({
                    type: 'offer',
                    sdp: offer.sdp,
                    room: roomName
                });
                break;

            case 'offer':
                // 收到 Offer，作为 Answerer 应答
                console.log('Received offer, creating answer...');
                await createPeerConnection();
                await peerConnection.setRemoteDescription(
                    new RTCSessionDescription({ type: 'offer', sdp: message.sdp })
                );
                const answer = await peerConnection.createAnswer();
                await peerConnection.setLocalDescription(answer);
                sendSignaling({
                    type: 'answer',
                    sdp: answer.sdp,
                    room: roomName
                });
                break;

            case 'answer':
                // 收到 Answer，设置远端描述
                console.log('Received answer');
                await peerConnection.setRemoteDescription(
                    new RTCSessionDescription({ type: 'answer', sdp: message.sdp })
                );
                break;

            case 'candidate':
                // 收到 ICE Candidate
                if (peerConnection) {
                    await peerConnection.addIceCandidate(
                        new RTCIceCandidate(message.candidate)
                    );
                }
                break;

            case 'user-left':
                console.log('Remote user left');
                closePeerConnection();
                break;
        }
    }

    // ---- 3. 创建 PeerConnection ----
    async function createPeerConnection() {
        peerConnection = new RTCPeerConnection(config);

        // 添加本地媒体轨道
        localStream.getTracks().forEach(track => {
            peerConnection.addTrack(track, localStream);
        });

        // 监听远端媒体轨道
        peerConnection.ontrack = (event) => {
            console.log('Received remote track:', event.track.kind);
            document.getElementById('remoteVideo').srcObject = event.streams[0];
        };

        // 监听 ICE Candidate
        peerConnection.onicecandidate = (event) => {
            if (event.candidate) {
                sendSignaling({
                    type: 'candidate',
                    candidate: event.candidate,
                    room: roomName
                });
            }
        };

        // 监听连接状态
        peerConnection.onconnectionstatechange = () => {
            console.log('Connection state:', peerConnection.connectionState);
            if (peerConnection.connectionState === 'failed') {
                // 连接失败，尝试 ICE Restart
                restartIce();
            }
        };

        // 监听 ICE 连接状态
        peerConnection.oniceconnectionstatechange = () => {
            console.log('ICE state:', peerConnection.iceConnectionState);
        };
    }

    // ---- 4. 获取本地媒体流 ----
    async function getLocalMedia() {
        try {
            localStream = await navigator.mediaDevices.getUserMedia({
                video: {
                    width: { ideal: 1280 },
                    height: { ideal: 720 },
                    frameRate: { ideal: 30 }
                },
                audio: {
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true
                }
            });
            document.getElementById('localVideo').srcObject = localStream;
        } catch (error) {
            console.error('Failed to get media:', error);
            alert('无法访问摄像头/麦克风: ' + error.message);
        }
    }

    // ---- 5. 加入/离开房间 ----
    async function joinRoom() {
        roomName = document.getElementById('roomInput').value;
        if (!roomName) {
            alert('请输入房间名');
            return;
        }

        await getLocalMedia();
        connectSignaling();

        // 等待 WebSocket 连接建立后加入房间
        socket.addEventListener('open', () => {
            sendSignaling({ type: 'join', room: roomName });
        }, { once: true });

        document.getElementById('joinBtn').disabled = true;
        document.getElementById('leaveBtn').disabled = false;
    }

    function leaveRoom() {
        sendSignaling({ type: 'leave', room: roomName });
        closePeerConnection();

        if (localStream) {
            localStream.getTracks().forEach(track => track.stop());
            localStream = null;
        }

        if (socket) {
            socket.close();
            socket = null;
        }

        document.getElementById('localVideo').srcObject = null;
        document.getElementById('remoteVideo').srcObject = null;
        document.getElementById('joinBtn').disabled = false;
        document.getElementById('leaveBtn').disabled = true;
    }

    // ---- 6. 媒体控制 ----
    function toggleCamera() {
        if (localStream) {
            const videoTrack = localStream.getVideoTracks()[0];
            if (videoTrack) {
                videoTrack.enabled = !videoTrack.enabled;
                console.log('Camera:', videoTrack.enabled ? 'on' : 'off');
            }
        }
    }

    function toggleMic() {
        if (localStream) {
            const audioTrack = localStream.getAudioTracks()[0];
            if (audioTrack) {
                audioTrack.enabled = !audioTrack.enabled;
                console.log('Mic:', audioTrack.enabled ? 'on' : 'off');
            }
        }
    }

    // ---- 7. ICE Restart ----
    async function restartIce() {
        if (peerConnection) {
            const offer = await peerConnection.createOffer({ iceRestart: true });
            await peerConnection.setLocalDescription(offer);
            sendSignaling({
                type: 'offer',
                sdp: offer.sdp,
                room: roomName
            });
        }
    }

    // ---- 辅助函数 ----
    function sendSignaling(message) {
        if (socket && socket.readyState === WebSocket.OPEN) {
            socket.send(JSON.stringify(message));
        }
    }

    function closePeerConnection() {
        if (peerConnection) {
            peerConnection.close();
            peerConnection = null;
        }
    }

信令服务器实现 (Node.js)
----------------------------

.. code-block:: javascript

    // ============================================
    // Signal Server - Node.js + ws
    // ============================================

    const WebSocket = require('ws');
    const http = require('http');
    const express = require('express');

    const app = express();
    app.use(express.static('public'));

    const server = http.createServer(app);
    const wss = new WebSocket.Server({ server });

    // 房间管理
    const rooms = new Map();  // roomName -> Set<WebSocket>

    wss.on('connection', (ws) => {
        console.log('Client connected');
        ws.roomName = null;

        ws.on('message', (data) => {
            const message = JSON.parse(data);

            switch (message.type) {
                case 'join':
                    ws.roomName = message.room;
                    if (!rooms.has(message.room)) {
                        rooms.set(message.room, new Set());
                    }
                    const room = rooms.get(message.room);
                    room.add(ws);

                    // 通知房间内其他人
                    broadcast(message.room, ws, {
                        type: 'user-joined',
                        userId: ws._socket.remoteAddress
                    });

                    console.log(`User joined room: ${message.room} `
                        + `(${room.size} users)`);
                    break;

                case 'leave':
                    removeFromRoom(ws);
                    break;

                case 'offer':
                case 'answer':
                case 'candidate':
                    // 转发给房间内其他人
                    broadcast(message.room, ws, message);
                    break;
            }
        });

        ws.on('close', () => {
            removeFromRoom(ws);
            console.log('Client disconnected');
        });
    });

    function broadcast(roomName, sender, message) {
        const room = rooms.get(roomName);
        if (room) {
            room.forEach(client => {
                if (client !== sender
                    && client.readyState === WebSocket.OPEN) {
                    client.send(JSON.stringify(message));
                }
            });
        }
    }

    function removeFromRoom(ws) {
        if (ws.roomName && rooms.has(ws.roomName)) {
            const room = rooms.get(ws.roomName);
            room.delete(ws);

            broadcast(ws.roomName, ws, {
                type: 'user-left'
            });

            if (room.size === 0) {
                rooms.delete(ws.roomName);
            }
        }
    }

    server.listen(8080, () => {
        console.log('Server running on port 8080');
    });


P2P vs SFU vs MCU
====================

多人视频聊天有三种主要架构：

.. list-table:: 架构对比
   :header-rows: 1
   :widths: 15 28 28 29

   * - 特性
     - P2P Mesh
     - SFU
     - MCU
   * - 原理
     - 每对用户直连
     - 服务器选择性转发
     - 服务器混合后转发
   * - 上行流数
     - N-1
     - 1
     - 1
   * - 下行流数
     - N-1
     - N-1
     - 1
   * - 服务器负载
     - 无
     - 中等（转发）
     - 高（转码混合）
   * - 客户端负载
     - 高（N-1 编码）
     - 中等（1 编码）
     - 低（1 编解码）
   * - 延迟
     - 最低
     - 低
     - 较高（混合延迟）
   * - 可扩展性
     - 差（≤4人）
     - 好（数十人）
     - 好（数百人）
   * - 视频质量
     - 受限于最差链路
     - 可自适应
     - 统一质量
   * - 典型方案
     - WebRTC P2P
     - mediasoup, Janus
     - Opal, FreeSWITCH

对于大多数场景，SFU 是最佳选择：

- 2-4 人：P2P Mesh 足够
- 5-50 人：SFU 是标准方案
- 50+ 人：SFU + Simulcast，或 MCU 混合方案


关键技术点
====================

SDP Offer/Answer
--------------------

SDP 协商是 WebRTC 连接建立的核心。需要注意：

- **Offer 方**：通常是先加入房间的用户，或者收到 ``user-joined`` 事件的用户
- **Answer 方**：收到 Offer 的用户
- **Renegotiation**：添加/移除媒体轨道时需要重新协商
- **Rollback**：协商失败时可以回滚到之前的状态

.. code-block:: javascript

    // 添加新的媒体轨道（如屏幕共享）需要重新协商
    pc.onnegotiationneeded = async () => {
        try {
            const offer = await pc.createOffer();
            await pc.setLocalDescription(offer);
            signaling.send({ type: 'offer', sdp: offer.sdp });
        } catch (err) {
            console.error('Negotiation failed:', err);
        }
    };

状态监控
--------------------

实时监控连接质量对用户体验至关重要：

.. code-block:: javascript

    // 定期获取统计信息
    setInterval(async () => {
        if (!peerConnection) return;

        const stats = await peerConnection.getStats();
        stats.forEach(report => {
            if (report.type === 'inbound-rtp' && report.kind === 'video') {
                console.log('Video stats:', {
                    packetsReceived: report.packetsReceived,
                    packetsLost: report.packetsLost,
                    framesDecoded: report.framesDecoded,
                    frameWidth: report.frameWidth,
                    frameHeight: report.frameHeight,
                    framesPerSecond: report.framesPerSecond,
                    jitter: report.jitter
                });
            }
            if (report.type === 'candidate-pair' && report.nominated) {
                console.log('Network:', {
                    rtt: report.currentRoundTripTime,
                    bytesSent: report.bytesSent,
                    bytesReceived: report.bytesReceived,
                    availableOutgoingBitrate:
                        report.availableOutgoingBitrate
                });
            }
        });
    }, 3000);

错误处理
--------------------

WebRTC 应用需要处理多种错误场景：

.. code-block:: javascript

    // 1. 媒体获取失败
    try {
        stream = await navigator.mediaDevices.getUserMedia(constraints);
    } catch (err) {
        if (err.name === 'NotAllowedError') {
            // 用户拒绝了权限
            showMessage('请允许访问摄像头和麦克风');
        } else if (err.name === 'NotFoundError') {
            // 没有找到设备
            showMessage('未检测到摄像头或麦克风');
        } else if (err.name === 'OverconstrainedError') {
            // 约束条件无法满足，降级
            stream = await navigator.mediaDevices.getUserMedia({
                video: true, audio: true
            });
        }
    }

    // 2. ICE 连接失败
    pc.oniceconnectionstatechange = () => {
        if (pc.iceConnectionState === 'failed') {
            // 尝试 ICE Restart
            restartIce();
        } else if (pc.iceConnectionState === 'disconnected') {
            // 等待一段时间，可能会自动恢复
            setTimeout(() => {
                if (pc.iceConnectionState === 'disconnected') {
                    restartIce();
                }
            }, 5000);
        }
    };


移动端适配
====================

移动端视频聊天需要额外考虑：

前后摄像头切换
--------------------

.. code-block:: javascript

    let currentFacingMode = 'user';  // 'user' = 前置, 'environment' = 后置

    async function switchCamera() {
        currentFacingMode = currentFacingMode === 'user'
            ? 'environment' : 'user';

        const newStream = await navigator.mediaDevices.getUserMedia({
            video: { facingMode: currentFacingMode }
        });

        const newVideoTrack = newStream.getVideoTracks()[0];
        const sender = peerConnection.getSenders()
            .find(s => s.track && s.track.kind === 'video');

        if (sender) {
            await sender.replaceTrack(newVideoTrack);
        }

        // 更新本地预览
        const oldTrack = localStream.getVideoTracks()[0];
        localStream.removeTrack(oldTrack);
        oldTrack.stop();
        localStream.addTrack(newVideoTrack);
    }

屏幕旋转处理
--------------------

.. code-block:: javascript

    // 监听屏幕方向变化
    screen.orientation.addEventListener('change', () => {
        console.log('Orientation:', screen.orientation.type);
        // 可能需要调整视频布局
        updateVideoLayout();
    });

    // 使用 CSS 适配不同方向
    // @media (orientation: portrait) { ... }
    // @media (orientation: landscape) { ... }


部署与测试
====================

HTTPS 要求
--------------------

WebRTC 的 ``getUserMedia`` API 要求安全上下文（Secure Context）：

- **生产环境**：必须使用 HTTPS
- **本地开发**：``localhost`` 和 ``127.0.0.1`` 可以使用 HTTP
- **局域网测试**：需要自签名证书或使用 ngrok 等隧道工具

.. code-block:: bash

    # 使用 mkcert 生成本地开发证书
    brew install mkcert
    mkcert -install
    mkcert localhost 127.0.0.1 ::1

    # 使用 ngrok 暴露本地服务
    ngrok http 8080

TURN 服务器部署
--------------------

生产环境必须部署 TURN 服务器，否则约 10-15% 的用户无法建立 P2P 连接：

.. code-block:: javascript

    const config = {
        iceServers: [
            { urls: 'stun:stun.l.google.com:19302' },
            {
                urls: [
                    'turn:turn.example.com:3478?transport=udp',
                    'turn:turn.example.com:3478?transport=tcp',
                    'turns:turn.example.com:5349?transport=tcp'
                ],
                username: 'user',
                credential: 'password'
            }
        ],
        iceTransportPolicy: 'all'  // 'relay' 可强制使用 TURN
    };

测试工具
--------------------

- **chrome://webrtc-internals**：Chrome 内置的 WebRTC 调试工具，查看详细统计
- **about:webrtc**：Firefox 的 WebRTC 调试页面
- **WebRTC Test Pages**：https://webrtc.github.io/samples/
- **Trickle ICE**：https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/
- **网络模拟**：Chrome DevTools Network Throttling 模拟弱网


参考文献
====================

* WebRTC Samples - https://webrtc.github.io/samples/
* MDN WebRTC API - https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API
* RFC 8829 - JavaScript Session Establishment Protocol (JSEP)
* RFC 8445 - Interactive Connectivity Establishment (ICE)
* Getting Started with WebRTC - https://webrtc.org/getting-started/overview
* WebRTC for the Curious - https://webrtcforthecurious.com/
* walterfan/webrtc_video_chat - https://github.com/walterfan/webrtc_video_chat
