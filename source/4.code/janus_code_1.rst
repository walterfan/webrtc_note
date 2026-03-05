######################
Janus Code analysis 1
######################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** Janus gateway code analysis 1
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:


Overview
========================

Janus 是由 Meetecho 开发的开源 WebRTC 服务器网关，采用 C 语言编写，以高性能和灵活的插件架构著称。
它本身不提供具体的通信功能，而是通过插件系统支持各种应用场景，如视频会议、直播、SIP 网关等。

项目地址: https://github.com/meetecho/janus-gateway


架构概述
========================

Janus 的整体架构分为三层：

::

  ┌─────────────────────────────────────────┐
  │          Transport Layer                │
  │  (HTTP/HTTPS, WebSocket, RabbitMQ, ...) │
  ├─────────────────────────────────────────┤
  │          Janus Core (janus.c)           │
  │  ├── Session 管理                       │
  │  ├── Handle 管理                        │
  │  ├── ICE/DTLS/SRTP 处理                 │
  │  └── Plugin 调度                        │
  ├─────────────────────────────────────────┤
  │          Plugin Layer                   │
  │  (VideoRoom, AudioBridge, Streaming...) │
  └─────────────────────────────────────────┘

* **Transport Layer**: 负责与客户端的信令通信，支持多种传输协议
* **Janus Core**: 核心引擎，管理 WebRTC 连接的建立和媒体转发
* **Plugin Layer**: 业务逻辑层，每个插件实现特定的应用场景


核心模块 (janus.c)
========================

``janus.c`` 是 Janus 的主入口和核心调度模块，主要包含以下功能：

Session 与 Handle
--------------------

* **Session** (``janus_session``): 代表一个客户端连接，包含一个或多个 Handle
* **Handle** (``janus_ice_handle``): 代表一个 WebRTC PeerConnection，关联到一个 Plugin

.. code-block:: c

   // 核心数据结构
   struct janus_session {
     guint64 session_id;
     GHashTable *ice_handles;   // handle_id → janus_ice_handle
     janus_transport *source;   // 关联的 Transport
     volatile gint timeout;
     volatile gint destroyed;
   };

   struct janus_ice_handle {
     guint64 handle_id;
     janus_session *session;
     janus_plugin *app;         // 关联的 Plugin
     void *app_handle;          // Plugin 侧的 handle
     janus_ice_stream *stream;  // ICE stream
     // ...
   };

消息处理流程
--------------------

客户端发送的 JSON 消息经过以下流程处理：

1. Transport 层接收消息，调用 ``janus_process_incoming_request()``
2. 根据消息类型分发：``create`` (创建 Session)、``attach`` (关联 Plugin)、``message`` (转发给 Plugin)
3. Plugin 处理完成后，通过回调将结果返回给客户端


插件系统
========================

Janus 的插件系统是其最大的设计亮点。每个插件实现 ``janus_plugin`` 接口：

.. code-block:: c

   struct janus_plugin {
     // 插件元信息
     const char *(*get_name)(void);
     const char *(*get_description)(void);

     // 生命周期
     int (*init)(janus_callbacks *callback, const char *config_path);
     void (*destroy)(void);

     // 会话管理
     void (*create_session)(janus_plugin_session *handle, int *error);
     void (*destroy_session)(janus_plugin_session *handle, int *error);

     // 消息处理
     struct janus_plugin_result *(*handle_message)(
         janus_plugin_session *handle, char *transaction,
         json_t *message, json_t *jsep);

     // 媒体回调
     void (*incoming_rtp)(janus_plugin_session *handle,
                          janus_plugin_rtp *packet);
     void (*incoming_rtcp)(janus_plugin_session *handle,
                           janus_plugin_rtcp *packet);
   };

常用的官方插件：

* **janus_videoroom**: SFU 模式的视频会议室，支持 Simulcast 和 SVC
* **janus_audiobridge**: MCU 模式的音频混音桥
* **janus_streaming**: 媒体流分发 (RTP 转 WebRTC)
* **janus_sip**: SIP 网关，连接 WebRTC 和传统电话网络
* **janus_recordplay**: 媒体录制和回放


ICE 处理
========================

Janus 的 ICE 处理由 ``ice.c`` 和 ``ice.h`` 实现，基于 libnice 库：

1. **Candidate 收集**: 收集 host、srflx、relay 候选地址
2. **连通性检查**: 通过 STUN Binding Request 进行 ICE 连通性检查
3. **DTLS 握手**: ICE 连接建立后进行 DTLS-SRTP 密钥协商
4. **SRTP 加密**: 使用协商的密钥对 RTP/RTCP 进行加解密

.. code-block:: c

   // ICE 连接建立的关键回调
   static void janus_ice_cb_nice_recv(NiceAgent *agent,
       guint stream_id, guint component_id,
       guint len, gchar *buf, gpointer data) {
     // 判断是 DTLS 还是 SRTP 数据
     // DTLS: 交给 OpenSSL 处理握手
     // SRTP: 解密后转发给 Plugin
   }

媒体数据在 Janus 内部的转发路径：

::

  Client A → ICE → SRTP 解密 → Plugin (如 VideoRoom)
                                    |
                                    → 转发给其他参与者
                                    |
  Client B ← ICE ← SRTP 加密 ← Plugin


参考资料
========================
* Janus 官方文档: https://janus.conf.meetecho.com/docs/
* 源码: https://github.com/meetecho/janus-gateway
* https://github.com/murillo128/janus-gateway/pull/2
