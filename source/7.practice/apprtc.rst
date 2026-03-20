##############
AppRTC
##############


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** AppRTC 示例应用
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
===============

AppRTC 是 Google 官方提供的 WebRTC 示例应用，也是最经典的 WebRTC Demo。
它展示了一个完整的 P2P 视频通话流程，包括信令、ICE、DTLS 握手和媒体传输。

虽然 AppRTC 的托管服务（appr.tc）已经下线，但其源码仍然是学习 WebRTC 的宝贵参考。

.. note::

   Google 推荐使用更新的示例：https://github.com/niccolosalvato/webrtc-samples
   AppRTC 代码较旧，但其架构设计仍有学习价值。


架构
===============

.. code-block:: text

   ┌──────────────┐                              ┌──────────────┐
   │   Browser A  │                              │   Browser B  │
   │              │                              │              │
   │  apprtc.js   │◄──── WebRTC P2P Media ──────►│  apprtc.js   │
   │              │                              │              │
   └──────┬───────┘                              └──────┬───────┘
          │                                             │
          │  WebSocket / Channel API                    │
          │                                             │
   ┌──────▼─────────────────────────────────────────────▼──────┐
   │                  Signaling Server                          │
   │           (Google App Engine / Python)                     │
   │                                                           │
   │  - Room management (创建/加入房间)                          │
   │  - Message relay (转发 SDP/ICE)                            │
   │  - Collider (WebSocket 服务)                               │
   └───────────────────────────────────────────────────────────┘

组件：

- **Web Client**：HTML5 + JavaScript，使用 WebRTC API
- **App Engine Server**：Python，负责房间管理和初始信令
- **Collider**：Go 编写的 WebSocket 服务，负责实时信令中继
- **TURN Server**：可选的 TURN 中继服务


信令流程
===============

.. code-block:: text

   Browser A                   Server                    Browser B
       │                         │                          │
       │── GET /join/room123 ──►│                          │
       │◄── room_config + is_initiator=true ──│            │
       │                         │                          │
       │                         │◄── GET /join/room123 ───│
       │                         │── room_config + is_initiator=false ──►│
       │                         │                          │
       │── WebSocket connect ──►│◄── WebSocket connect ───│
       │                         │                          │
       │── SDP Offer ──────────►│── SDP Offer ───────────►│
       │                         │                          │
       │◄── SDP Answer ─────── │◄── SDP Answer ──────────│
       │                         │                          │
       │◄─── ICE Candidates ──►│◄── ICE Candidates ─────►│
       │                         │                          │
       │◄════════ P2P Media (RTP/RTCP) ═══════════════════►│


本地部署
===============

虽然 AppRTC 设计为运行在 Google App Engine 上，但也可以本地部署用于学习：

.. code-block:: bash

   # 克隆源码
   git clone https://github.com/webrtc/apprtc.git
   cd apprtc

   # 安装依赖
   npm install
   pip install -r requirements.txt

   # 编译前端
   grunt build

   # 使用 Docker 一键部署（推荐）
   # 参见 https://blog.piasy.com/2017/06/17/out-of-the-box-webrtc-dev-env/

Docker 部署方式更方便，包含了 App Engine 模拟器、Collider 和 coturn：

.. code-block:: bash

   docker run -d --name apprtc \
       -p 8080:8080 -p 8089:8089 -p 3478:3478 \
       piasy/apprtc-server


学习要点
===============

从 AppRTC 源码中可以学到的关键 WebRTC 知识：

1. **完整的信令流程**：SDP Offer/Answer 交换 + ICE Candidate Trickle
2. **房间管理模型**：两人房间的创建、加入、离开
3. **PeerConnection 配置**：ICE Server、编解码器偏好、带宽限制
4. **错误处理**：ICE 连接失败回退、浏览器兼容性处理
5. **UI/UX 模式**：本地预览、远端视频显示、通话控制


参考资料
===============

- AppRTC 源码: https://github.com/webrtc/apprtc
- WebRTC 官方示例: https://webrtc.github.io/samples/
- WebRTC Samples 源码: https://github.com/niccolosalvato/webrtc-samples
