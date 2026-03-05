##########################################
Open WebRTC Toolkit Media Server
##########################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ====================================
**Abstract** Open WebRTC Toolkit Media Server
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ====================================



.. contents::
   :local:

Overview
===============

Open WebRTC Toolkit (OWT) 是 Intel 开源的 WebRTC 媒体服务器和客户端 SDK 套件，
前身为 Intel Collaboration Suite for WebRTC (Intel CS for WebRTC)。
它提供了完整的实时通信解决方案，支持 MCU 和 SFU 两种媒体转发模式，
并利用 Intel 硬件加速能力 (如 Media SDK / oneVPL) 实现高效的视频处理。

项目地址: https://github.com/open-webrtc-toolkit


架构
===============

OWT 由以下核心组件构成：

::

  ┌──────────────────────────────────────────────┐
  │              OWT Client SDK                  │
  │  (JavaScript / iOS / Android / Windows / C++)│
  ├──────────────────────────────────────────────┤
  │              Management API                  │
  │         (RESTful API / Socket.IO)            │
  ├──────────────────────────────────────────────┤
  │           OWT Media Server                   │
  │  ┌────────────┐  ┌────────────┐              │
  │  │ Conference  │  │  Streaming │              │
  │  │   Agent     │  │   Agent    │              │
  │  ├────────────┤  ├────────────┤              │
  │  │  Video     │  │  Audio     │              │
  │  │  Agent     │  │  Agent     │              │
  │  ├────────────┤  ├────────────┤              │
  │  │  WebRTC    │  │  SIP       │              │
  │  │  Agent     │  │  Agent     │              │
  │  └────────────┘  └────────────┘              │
  │           Cluster Manager (Portal)           │
  └──────────────────────────────────────────────┘

核心组件说明：

* **Portal**: 信令服务器，处理客户端的 WebSocket/Socket.IO 连接
* **Conference Agent**: 会议管理，控制参与者和媒体流
* **WebRTC Agent**: 处理 WebRTC 连接的建立和媒体传输
* **Video Agent**: 视频转码、混流 (MCU 模式)
* **Audio Agent**: 音频混音
* **Streaming Agent**: RTSP/RTMP 推拉流支持
* **SIP Agent**: SIP 网关，连接传统视频会议系统


MCU 与 SFU 模式
===================

OWT 同时支持两种媒体转发架构：

**MCU (Multipoint Control Unit) 模式**:

* 服务器端解码所有参与者的视频，混合为一路画面后重新编码发送
* 优点：客户端带宽需求低，只需接收一路流
* 缺点：服务器 CPU 开销大，延迟较高
* 适用场景：大规模会议、录制

**SFU (Selective Forwarding Unit) 模式**:

* 服务器不做编解码，直接转发媒体流
* 支持 Simulcast，根据接收端带宽选择合适的层
* 优点：低延迟，服务器开销小
* 缺点：客户端需要接收多路流
* 适用场景：小规模高质量会议

.. code-block:: javascript

   // OWT Client SDK 加入会议示例
   const conference = new Owt.Conference.ConferenceClient();

   conference.join(token).then(info => {
     console.log('Joined conference:', info.id);

     // 发布本地流
     const localStream = new Owt.Base.LocalStream(
       mediaStream, {audio: true, video: true});
     conference.publish(localStream).then(publication => {
       console.log('Published stream:', publication.id);
     });

     // 订阅远端流
     info.remoteStreams.forEach(stream => {
       conference.subscribe(stream, {
         video: {resolution: {width: 640, height: 480}}
       });
     });
   });


Intel 硬件加速
===================

OWT 充分利用 Intel 平台的硬件加速能力：

* **Intel Media SDK / oneVPL**: 硬件加速的视频编解码 (H.264/H.265/VP8/VP9/AV1)
* **Intel Quick Sync Video**: 集成显卡的硬件编解码引擎
* **GPU 混流**: 使用 GPU 进行视频画面合成，降低 CPU 负载

在 MCU 模式下，硬件加速可以显著提升单台服务器支持的并发路数。


安装部署
===============

OWT 服务器的部署步骤：

.. code-block:: bash

   # 1. 安装系统依赖 (Ubuntu 20.04/22.04)
   sudo apt-get update
   sudo apt-get install -y git nodejs npm mongodb rabbitmq-server

   # 2. 克隆源码
   git clone https://github.com/open-webrtc-toolkit/owt-server.git
   cd owt-server

   # 3. 安装依赖
   scripts/installDeps.sh

   # 4. 构建
   scripts/build.js -t all --check

   # 5. 打包
   scripts/pack.js -t all

   # 6. 启动服务
   cd dist
   bin/init-all.sh
   bin/start-all.sh

关键配置文件：

* ``portal.toml``: Portal 信令服务器配置 (端口、TLS 证书)
* ``webrtc_agent.toml``: WebRTC Agent 配置 (ICE 服务器、网络接口)
* ``video_agent.toml``: 视频处理配置 (硬件加速开关、编解码器)
* ``management_api.toml``: REST API 配置

依赖服务：

* **MongoDB**: 存储房间和用户信息
* **RabbitMQ**: 各 Agent 之间的消息通信
* **Node.js**: Portal 和管理 API 的运行环境


参考资料
===============
* OWT Server: https://github.com/open-webrtc-toolkit/owt-server
* OWT Client SDK: https://github.com/open-webrtc-toolkit/owt-client-javascript
* Intel Media SDK: https://github.com/Intel-Media-SDK/MediaSDK
