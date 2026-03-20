############################
Lazy Rabbit Meeting
############################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =====================================
**Abstract** 基于 Pion 的轻量级多人会议系统
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ =====================================



.. contents::
   :local:


概述
========================

Lazy Rabbit Meeting 是一个轻量级的自托管多人视频会议系统，基于 Go + Vue.js + Pion WebRTC 构建。
它实现了完整的 SFU（Selective Forwarding Unit）架构，支持多人音视频通话、屏幕共享、文字聊天和服务端录制。

项目采用分层架构，从领域模型到 SFU 引擎再到前端 UI，层次清晰，适合作为学习 WebRTC SFU 开发的参考实现。

**项目地址**：https://github.com/walterfan/lazy-rabbit-meeting

.. list-table:: 核心特性
   :header-rows: 1
   :widths: 25 75

   * - 特性
     - 说明
   * - SFU 多人会议
     - 基于 Pion 的 SFU 架构，支持多方音视频
   * - 屏幕共享
     - 一键屏幕共享，支持互斥控制
   * - 实时聊天
     - 会议内文字聊天，带消息历史
   * - 服务端录制
     - 录制为 OGG（音频）+ IVF（视频）文件
   * - 房间管理
     - 创建、加入、离开、关闭房间，支持容量限制
   * - JWT 认证
     - 用户注册、登录、Token 鉴权
   * - 暗色主题
     - 现代化响应式 Vue.js 前端，使用 Element Plus


技术栈
========================

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - 层
     - 技术
   * - 后端
     - Go 1.24 + Gin + GORM（SQLite / MySQL）
   * - WebRTC
     - Pion WebRTC v4 + Pion Interceptor + Pion TURN
   * - 信令
     - Gorilla WebSocket + 自定义 JMPP 协议
   * - 认证
     - JWT（golang-jwt）+ bcrypt
   * - 前端
     - Vue 3 + Pinia + Vue Router + Element Plus + TypeScript
   * - 构建
     - Vite 6 + Makefile + Docker


架构
========================

.. code-block:: text

   ┌─────────────────────────────────────────────────────────┐
   │                    Vue.js Frontend                       │
   │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │
   │  │LoginView │  │LobbyView │  │PreJoinView│  │Meeting │ │
   │  │          │  │          │  │          │  │  View  │ │
   │  └──────────┘  └──────────┘  └──────────┘  └────────┘ │
   │  ┌──────────────────────────────────────────────────┐  │
   │  │  useWebSocket  │  useWebRTC  │  useMediaDevices  │  │
   │  └──────────────────────────────────────────────────┘  │
   └───────────────────────┬─────────────────────────────────┘
                           │ HTTP REST + WebSocket (JMPP) + WebRTC
   ┌───────────────────────┴─────────────────────────────────┐
   │                    Go Backend                            │
   │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │
   │  │  Auth    │  │  Room    │  │  Chat    │  │  WS    │ │
   │  │ Handler  │  │ Handler  │  │ Service  │  │Handler │ │
   │  └──────────┘  └──────────┘  └──────────┘  └────────┘ │
   │  ┌──────────────────────────────────────────────────┐  │
   │  │  SFU Engine  │  Recorder  │  Signaling Service   │  │
   │  └──────────────────────────────────────────────────┘  │
   │  ┌──────────────────────────────────────────────────┐  │
   │  │  GORM Repositories (SQLite / MySQL)              │  │
   │  └──────────────────────────────────────────────────┘  │
   └─────────────────────────────────────────────────────────┘

**三条通信通道**：

- **HTTP REST**：用于认证、房间管理、录制文件下载
- **WebSocket（JMPP 协议）**：用于信令（SDP/ICE 交换）、聊天、状态同步
- **WebRTC 媒体流**：用于音视频和屏幕共享的实时传输


JMPP 信令协议
========================

项目使用自定义的 JMPP（JSON Meeting Presence Protocol）协议，通过 WebSocket 传输所有实时信令消息：

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - 消息类型
     - 方向
     - 说明
   * - ``join`` / ``leave``
     - Client → Server
     - 加入 / 离开房间
   * - ``offer`` / ``answer`` / ``candidate``
     - 双向
     - WebRTC SDP 和 ICE 信令
   * - ``chat``
     - Client → Server → Room
     - 文字消息广播
   * - ``mute_audio`` / ``unmute_audio``
     - Client → Server → Room
     - 音频静音切换
   * - ``mute_video`` / ``unmute_video``
     - Client → Server → Room
     - 视频开关切换
   * - ``screen_share_start`` / ``stop``
     - Client → Server → Room
     - 屏幕共享控制
   * - ``start_record`` / ``stop_record``
     - Client → Server
     - 录制控制
   * - ``room_state``
     - Server → Client
     - 加入时下发完整房间状态
   * - ``user_joined`` / ``user_left``
     - Server → Room
     - 成员变化通知


SFU 引擎实现
========================

SFU 引擎是整个项目的核心，位于 ``backend/internal/webrtc/`` 目录下：

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - 文件
     - 职责
   * - ``sfu.go``
     - SFU 引擎入口：创建 PeerConnection、ICE 配置、端口范围
   * - ``room_session.go``
     - 每个房间一个 Session，管理参与者和 Track 转发
   * - ``peer.go``
     - 每个用户一个 Peer，封装 Pion PeerConnection
   * - ``recorder.go``
     - 服务端录制：音频写入 OGG，视频写入 IVF
   * - ``track_forwarder.go``
     - 将一个参与者的 Track 转发给房间内其他参与者

**SFU 媒体转发流程**：

1. 用户加入房间，通过 JMPP 发送 ``join`` 消息
2. 服务端为该用户创建 Pion PeerConnection
3. 通过 WebSocket 交换 SDP Offer/Answer 和 ICE Candidate
4. 用户的音视频 Track 到达服务端后，SFU 将其转发给房间内其他 Peer
5. 使用 Pion Interceptor 框架处理 TWCC、NACK 等 RTP/RTCP 拦截


关键源码
========================

**后端**：

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - 文件
     - 职责
   * - ``backend/cmd/server/main.go``
     - 入口：Gin 路由、数据库、WebSocket Hub、SFU 初始化
   * - ``backend/internal/handler/ws_handler.go``
     - WebSocket 升级和 JMPP 消息路由
   * - ``backend/internal/handler/auth_handler.go``
     - 用户注册和登录
   * - ``backend/internal/handler/room_handler.go``
     - 房间 CRUD 和消息查询
   * - ``backend/internal/service/signaling_service.go``
     - SFU Join / Answer / ICE Candidate 处理
   * - ``backend/internal/service/room_service.go``
     - 房间生命周期管理
   * - ``backend/internal/ws/hub.go``
     - WebSocket Hub：维护 userID → Client 映射
   * - ``backend/internal/message/jmpp.go``
     - JMPP 消息类型定义

**前端**：

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - 文件
     - 职责
   * - ``frontend/src/composables/useWebSocket.ts``
     - WebSocket 连接和 JMPP 消息收发
   * - ``frontend/src/composables/useWebRTC.ts``
     - PeerConnection 管理、SDP/ICE 处理
   * - ``frontend/src/composables/useMediaDevices.ts``
     - 音视频设备管理
   * - ``frontend/src/views/MeetingView.vue``
     - 会议主界面：多路视频、控制栏、聊天


安装与运行
========================

**前置条件**：

- Go 1.23+
- Node.js 20+
- （可选）Docker & Docker Compose

**本地开发**：

.. code-block:: bash

   # 克隆项目
   git clone https://github.com/walterfan/lazy-rabbit-meeting.git
   cd lazy-rabbit-meeting

   # 构建前端和后端
   make build

   # 使用 SQLite 启动（从项目根目录运行）
   ./bin/server -sqlite -f config/config.yaml

   # 浏览器访问
   open http://localhost:9070

**Docker 部署**：

.. code-block:: bash

   # SQLite 模式
   make docker-up

   # MySQL 模式
   make docker-up-mysql

**配置文件** ``config/config.yaml``：

.. code-block:: yaml

   server_port: 9070
   log_level: info

   jwt:
     secret: "your-secret-key"
     expire: "24h"

   webrtc:
     ice_servers:
       - urls: ["stun:stun.l.google.com:19302"]
     port_range:
       min: 50000
       max: 50100

   recording:
     enabled: true
     output_dir: "recordings"
     max_duration: 7200


REST API
========================

**认证**：

.. list-table::
   :header-rows: 1
   :widths: 15 35 50

   * - 方法
     - 端点
     - 说明
   * - POST
     - ``/api/v1/auth/register``
     - 注册新用户
   * - POST
     - ``/api/v1/auth/login``
     - 登录，返回 JWT

**房间管理**：

.. list-table::
   :header-rows: 1
   :widths: 15 35 50

   * - 方法
     - 端点
     - 说明
   * - GET
     - ``/api/v1/rooms``
     - 列出活跃房间
   * - POST
     - ``/api/v1/rooms``
     - 创建房间
   * - GET
     - ``/api/v1/rooms/:id``
     - 获取房间详情
   * - DELETE
     - ``/api/v1/rooms/:id``
     - 关闭房间（仅创建者）
   * - GET
     - ``/api/v1/rooms/:id/messages``
     - 获取聊天历史

**录制**：

.. list-table::
   :header-rows: 1
   :widths: 15 35 50

   * - 方法
     - 端点
     - 说明
   * - GET
     - ``/api/v1/rooms/:id/recordings``
     - 列出房间的录制文件
   * - GET
     - ``/api/v1/recordings/:id/download``
     - 下载录制文件


WebRTC 相关要点
========================

这个项目展示了 SFU 开发中的多个关键实践：

**SFU 转发模型**

每个参与者与 SFU 建立一个 PeerConnection。SFU 接收每个参与者的 Track，然后转发给房间内其他所有参与者。
相比 Mesh 模式（N*(N-1) 条连接），SFU 只需要 N 条上行 + N*(N-1) 条下行，显著降低了客户端的带宽和 CPU 开销。

**Pion Interceptor**

项目使用 Pion 的 Interceptor 框架来处理 TWCC 反馈和 NACK 重传等 RTP/RTCP 层面的功能，
这些在生产级 SFU 中是必不可少的 QoS 机制。

**WebSocket 信令**

使用 JMPP 自定义协议在 WebSocket 上完成所有信令交互，包括 SDP 交换、ICE Candidate 传递和房间状态同步。
这是 WebRTC 应用中最常见的信令实现方式之一。

**服务端录制**

通过 Pion 的 ``OnTrack`` 回调获取 RTP 包，直接写入 OGG（音频）和 IVF（视频）容器文件，
实现了不依赖浏览器的服务端录制能力。


测试
========================

项目包含完整的分层测试：

.. code-block:: bash

   # 运行所有测试
   go test ./... -count=1

   # 运行特定迭代的验收测试
   go test ./test/ -run "TestAC_7" -v

测试覆盖：领域模型、Repository、Service、WebSocket 消息处理、SFU Peer 管理、录制生命周期、端到端验收测试。


参考
========================

- 项目源码：https://github.com/walterfan/lazy-rabbit-meeting
- Pion WebRTC：https://github.com/pion/webrtc
- Pion Interceptor：https://github.com/pion/interceptor
- Gin Web Framework：https://github.com/gin-gonic/gin
- GORM：https://gorm.io/
- Element Plus：https://element-plus.org/
