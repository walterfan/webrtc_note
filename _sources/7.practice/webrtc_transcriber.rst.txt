############################
WebRTC Transcriber
############################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =====================================
**Abstract** WebRTC 实时语音转写示例
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ =====================================



.. contents::
   :local:


概述
========================

WebRTC Transcriber 是一个基于 Pion WebRTC 构建的实时语音转写应用。
它通过浏览器采集音频，经由 WebRTC 发送到 Go 后端，再交给转写引擎（Whisper、Google、Azure 等）进行实时语音识别，
转写结果通过 DataChannel 回传给前端。

项目同时支持纯录音模式（recorder），可以只录制 WAV 文件而不做转写。

**项目地址**：https://github.com/walterfan/webrtc-transcriber

.. list-table:: 核心特性
   :header-rows: 1
   :widths: 25 75

   * - 特性
     - 说明
   * - 实时流式传输
     - 基于 Pion WebRTC 的低延迟音频采集
   * - 多厂商转写
     - 支持 Whisper（本地）、Google、Azure、百度、讯飞
   * - 隐私优先
     - 默认使用 Whisper 本地转写，音频不离开服务器
   * - 音频录制
     - 支持录制为 WAV 文件，带文件管理功能
   * - 音频可视化
     - 浏览器端实时波形显示
   * - 用户认证
     - 基于 Session Cookie 的简单登录系统


技术栈
========================

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - 层
     - 技术
   * - 后端
     - Go + Pion WebRTC v2 + Opus 解码 + Gorilla WebSocket
   * - 前端
     - Vue 3 + TypeScript + Vite + Tailwind CSS
   * - 转写引擎
     - Whisper（whisper-ctranslate2）、Google Speech、Azure Speech、百度语音、讯飞语音


架构
========================

.. code-block:: text

   ┌─────────────┐     WebRTC      ┌─────────────────┐     Audio      ┌──────────────┐
   │   Browser   │ ◄─────────────► │  Go Server      │ ─────────────► │  Whisper AI  │
   │  (Vue 3)    │                 │  (Pion WebRTC)  │                │  (or Cloud)  │
   └─────────────┘                 └─────────────────┘                └──────────────┘
          │                               │                                  │
          │    DataChannel               │                                  │
          ◄──────────────────────────────┼──────────────────────────────────┘
                 (Transcription Results)

**数据流**：

1. 浏览器通过 ``getUserMedia`` 采集音频
2. 音频通过 WebRTC（Opus 编码的 RTP）发送到 Go 后端
3. 后端将 Opus RTP 解码为 PCM
4. PCM 音频送入转写服务（Whisper / Google / Azure / 百度 / 讯飞）
5. 转写结果通过 DataChannel 以 JSON 格式回传给浏览器

**核心模块**：

.. code-block:: text

   cmd/transcribe-server    # 入口：HTTP 服务器、认证、路由
     └─► internal/session   # SDP 交换处理
           └─► internal/rtc # WebRTC 连接管理、Opus 解码
                 └─► internal/transcribe  # 转写服务接口和各厂商实现


关键源码
========================

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - 文件
     - 职责
   * - ``cmd/transcribe-server/main.go``
     - 入口：HTTP 服务、认证、路由、厂商选择
   * - ``internal/rtc/pion.go``
     - Pion WebRTC 实现：PeerConnection、ICE、Track、DataChannel
   * - ``internal/rtc/opus.go``
     - Opus RTP → PCM 解码
   * - ``internal/session/handler.go``
     - SDP Offer/Answer 交换
   * - ``internal/transcribe/service.go``
     - ``Service`` 和 ``Stream`` 接口定义
   * - ``internal/transcribe/whisper.go``
     - Whisper 本地转写实现
   * - ``internal/transcribe/gspeech.go``
     - Google Speech-to-Text 实现
   * - ``frontend/src/composables/useWebRTC.ts``
     - 前端 WebRTC 连接逻辑


安装与运行
========================

**前置条件**：

- Go 1.21+
- Node.js 18+
- Whisper（默认转写引擎）：``pip install whisper-ctranslate2``

**构建与启动**：

.. code-block:: bash

   # 构建前端和后端
   make

   # 启动服务
   ./webrtc-transcriber

   # 浏览器访问
   open http://localhost:9070

**命令行选项**：

.. code-block:: bash

   ./webrtc-transcriber [options]
     --vendor string     whisper | google | azure | baidu | xunfei | recorder (default "whisper")
     --model string      tiny | base | small | medium | large (default "small")
     --language string   en | zh | ja | auto (default "auto")
     --output string     录音输出目录 (default "recordings")
     --http.port string  HTTP 端口 (default "9070")

如需使用云端转写服务，将 ``env.example`` 复制为 ``.env`` 并填入对应的 API 密钥。


WebRTC 相关要点
========================

这个项目展示了几个重要的 WebRTC 实践模式：

**Opus 解码**

浏览器通过 WebRTC 发送的音频默认使用 Opus 编码。后端需要将 Opus RTP 包解码为 PCM 才能送入转写引擎。
项目使用 ``hraban/opus`` 库完成解码，这是服务端处理 WebRTC 音频的常见模式。

**DataChannel 回传结果**

转写结果不通过信令或 HTTP 返回，而是通过 DataChannel 直接推送给浏览器，
保持了低延迟和实时性。这是 DataChannel 的典型应用场景。

**单向媒体流**

与双向视频通话不同，这个项目只需要浏览器 → 服务器的单向音频流。
``RTCPeerConnection`` 的 ``addTransceiver`` 配置为 ``sendonly``，服务端配置为 ``recvonly``。


参考
========================

- 项目源码：https://github.com/walterfan/webrtc-transcriber
- Pion WebRTC：https://github.com/pion/webrtc
- Whisper：https://github.com/openai/whisper
- Opus 编解码库（Go）：https://github.com/hraban/opus
