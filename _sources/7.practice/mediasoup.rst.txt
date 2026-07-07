##############
MediaSoup
##############


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** MediaSoup
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
===============

Mediasoup 是一个开源的 WebRTC SFU（Selective Forwarding Unit）项目，由 Iñaki Baz Castillo 和 José Luis Millán 创建并维护。
它的设计哲学是 **极简主义（minimalist）**：只处理媒体层（media layer），不涉及信令（signaling）、房间管理（room management）或业务逻辑。
开发者可以在 mediasoup 之上自由构建任何类型的实时通信应用。

Mediasoup is a opensource project, its server and client side libraries are designed to accomplish with the following goals:

* Be a SFU (Selective Forwarding Unit).
* Support both WebRTC and plain RTP input and output.
* Be a Node.js module in server side.
* Be a tiny JavaScript and C++ libraries in client side.
* Be minimalist: just handle the media layer.
* Be signaling agnostic: do not mandate any signaling protocol.
* Be super low level API.
* Support all existing WebRTC endpoints.
* Enable integration with well known multimedia libraries/tools.


设计哲学
--------------------------

Mediasoup 的核心设计理念可以概括为以下几点：

1. **只做媒体转发**: Mediasoup 不提供信令服务器、不管理房间、不处理用户认证。它只负责接收和转发 RTP/RTCP 媒体包。
2. **信令无关（Signaling Agnostic）**: 开发者可以使用任何信令协议（WebSocket、HTTP、Socket.IO、gRPC 等）来协调 mediasoup 的 API 调用。
3. **超低层 API**: Mediasoup 提供的是底层的媒体处理原语（primitives），而不是高层的"房间"或"会议"抽象。
4. **高性能 C++ Worker**: 媒体处理的核心逻辑由 C++ 编写的 worker 进程完成，Node.js 只负责控制面（control plane）。
5. **支持所有 WebRTC 端点**: 兼容所有标准的 WebRTC 浏览器和客户端。

**与其他 SFU 的对比**:

.. list-table::
   :header-rows: 1
   :widths: 20 20 20 20 20

   * - 特性
     - Mediasoup
     - Janus
     - Jitsi (JVB)
     - Pion (Go)
   * - 语言
     - Node.js + C++
     - C
     - Java
     - Go
   * - 信令
     - 无（自行实现）
     - 内置
     - 内置 (XMPP)
     - 无（自行实现）
   * - 插件系统
     - 无
     - 有
     - 有
     - 无
   * - API 层级
     - 极低层
     - 中层
     - 高层
     - 极低层
   * - Simulcast
     - ✓
     - ✓
     - ✓
     - ✓
   * - SVC
     - ✓
     - 部分
     - ✓
     - 部分
   * - DataChannel
     - ✓
     - ✓
     - ✓
     - ✓


架构详解
===============

Mediasoup 采用 **Node.js + C++ Worker** 的混合架构。Node.js 进程负责控制面（API 调用、信令交互），
C++ Worker 进程负责数据面（RTP/RTCP 包的接收、转发、处理）。

整体架构
--------------------------

.. code-block:: text

   ┌─────────────────────────────────────────────────────────┐
   │                    Node.js Application                   │
   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
   │  │  Signaling   │  │   Room      │  │   Auth      │     │
   │  │  Server      │  │   Manager   │  │   Module    │     │
   │  └──────┬───────┘  └──────┬──────┘  └─────────────┘     │
   │         │                 │                               │
   │  ┌──────┴─────────────────┴──────────────────────┐       │
   │  │           mediasoup Node.js Library            │       │
   │  │  ┌────────┐  ┌────────┐  ┌────────┐           │       │
   │  │  │ Worker  │  │ Router │  │Transport│          │       │
   │  │  │ Manager │  │ Manager│  │ Manager │          │       │
   │  │  └────┬───┘  └────┬───┘  └────┬────┘          │       │
   │  └───────┼────────────┼──────────┼────────────────┘       │
   └──────────┼────────────┼──────────┼────────────────────────┘
              │ (IPC)      │          │
   ┌──────────┼────────────┼──────────┼────────────────────────┐
   │  ┌───────┴────────────┴──────────┴────────────────┐       │
   │  │           C++ Worker Process #1                 │       │
   │  │  ┌────────────────────────────────────┐        │       │
   │  │  │            Router                   │        │       │
   │  │  │  ┌──────────┐  ┌──────────┐        │        │       │
   │  │  │  │ Producer │  │ Consumer │        │        │       │
   │  │  │  │  (Audio) │  │  (Audio) │        │        │       │
   │  │  │  └──────────┘  └──────────┘        │        │       │
   │  │  │  ┌──────────┐  ┌──────────┐        │        │       │
   │  │  │  │ Producer │  │ Consumer │        │        │       │
   │  │  │  │  (Video) │  │  (Video) │        │        │       │
   │  │  │  └──────────┘  └──────────┘        │        │       │
   │  │  └────────────────────────────────────┘        │       │
   │  └────────────────────────────────────────────────┘       │
   │                                                           │
   │  ┌────────────────────────────────────────────────┐       │
   │  │           C++ Worker Process #2                 │       │
   │  │  ┌────────────────────────────────────┐        │       │
   │  │  │            Router                   │        │       │
   │  │  │           ...                       │        │       │
   │  │  └────────────────────────────────────┘        │       │
   │  └────────────────────────────────────────────────┘       │
   └───────────────────────────────────────────────────────────┘

核心对象
--------------------------

Mediasoup 的核心对象模型如下：

**Worker**

Worker 是一个独立的 C++ 子进程，负责处理媒体数据。每个 Worker 运行在一个 CPU 核心上。
通常创建的 Worker 数量等于 CPU 核心数。

.. code-block:: javascript

   const mediasoup = require('mediasoup');

   // 创建一个 Worker
   const worker = await mediasoup.createWorker({
     logLevel: 'warn',
     logTags: ['info', 'ice', 'dtls', 'rtp', 'srtp', 'rtcp'],
     rtcMinPort: 10000,
     rtcMaxPort: 59999
   });

   worker.on('died', (error) => {
     console.error('mediasoup Worker died:', error);
     // 需要重新创建 Worker 和其上的所有资源
   });

**Router**

Router 是媒体路由器，负责在 Producer 和 Consumer 之间路由 RTP 包。
一个 Router 对应一个 Worker 进程，可以理解为一个"媒体房间"。
同一个 Router 内的 Producer 和 Consumer 可以互相通信。

.. code-block:: javascript

   // 创建 Router，指定支持的媒体编解码器
   const mediaCodecs = [
     {
       kind: 'audio',
       mimeType: 'audio/opus',
       clockRate: 48000,
       channels: 2
     },
     {
       kind: 'video',
       mimeType: 'video/VP8',
       clockRate: 90000,
       parameters: {
         'x-google-start-bitrate': 1000
       }
     },
     {
       kind: 'video',
       mimeType: 'video/VP9',
       clockRate: 90000,
       parameters: {
         'profile-id': 2,
         'x-google-start-bitrate': 1000
       }
     },
     {
       kind: 'video',
       mimeType: 'video/H264',
       clockRate: 90000,
       parameters: {
         'packetization-mode': 1,
         'profile-level-id': '4d0032',
         'level-asymmetry-allowed': 1,
         'x-google-start-bitrate': 1000
       }
     }
   ];

   const router = await worker.createRouter({ mediaCodecs });

**Transport**

Transport 是媒体传输通道，负责在 mediasoup 和端点之间传输 RTP/RTCP 数据。
Mediasoup 提供四种 Transport 类型：

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Transport 类型
     - 说明
   * - WebRtcTransport
     - 用于与 WebRTC 端点通信，支持 ICE、DTLS、SRTP
   * - PlainTransport
     - 用于与非 WebRTC 端点通信（如 FFmpeg、GStreamer），使用 plain RTP/RTCP
   * - PipeTransport
     - 用于在不同 Router 之间（同一 Worker 或不同 Worker/服务器）传输媒体
   * - DirectTransport
     - 用于在 Node.js 应用和 Router 之间直接传输数据（不经过网络）

**Producer**

Producer 代表一个媒体源（发送端）。当客户端向 mediasoup 发送音频或视频时，
在服务端会创建一个对应的 Producer 对象。

**Consumer**

Consumer 代表一个媒体接收端。当客户端需要接收某个 Producer 的媒体时，
在服务端会创建一个对应的 Consumer 对象。Consumer 从 Router 获取 Producer 的 RTP 包并转发给客户端。

**DataProducer / DataConsumer**

类似于 Producer/Consumer，但用于 DataChannel 数据传输（SCTP over DTLS）。

**对象关系图**:

.. code-block:: text

   Worker
   ├── Router
   │   ├── WebRtcTransport (for User A)
   │   │   ├── Producer (audio)    ← User A sends audio
   │   │   ├── Producer (video)    ← User A sends video
   │   │   ├── Consumer (audio)    ← User A receives B's audio
   │   │   └── Consumer (video)    ← User A receives B's video
   │   │
   │   ├── WebRtcTransport (for User B)
   │   │   ├── Producer (audio)    ← User B sends audio
   │   │   ├── Producer (video)    ← User B sends video
   │   │   ├── Consumer (audio)    ← User B receives A's audio
   │   │   └── Consumer (video)    ← User B receives A's video
   │   │
   │   └── PlainTransport (for recording)
   │       └── Consumer (audio+video) → FFmpeg
   │
   └── Router (another room)
       └── ...


安装与配置
===============

环境要求
--------------------------

Mediasoup 的服务端是一个 Node.js 模块，但其核心 Worker 是 C++ 编写的，因此安装时需要编译 C++ 代码。

**系统要求**:

* Node.js >= 16（推荐 18 LTS 或 20 LTS）
* Python 3（用于 node-gyp 构建）
* make
* gcc/g++ >= 8 或 clang >= 8（支持 C++17）
* Linux、macOS 或 Windows（WSL2）

**Ubuntu/Debian 安装依赖**:

.. code-block:: bash

   # 安装 Node.js (使用 nvm 推荐)
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
   source ~/.bashrc
   nvm install 20
   nvm use 20

   # 安装 C++ 编译工具链
   sudo apt-get update
   sudo apt-get install -y build-essential python3 python3-pip

**macOS 安装依赖**:

.. code-block:: bash

   # 安装 Xcode Command Line Tools
   xcode-select --install

   # 安装 Node.js
   brew install node@20

**CentOS/RHEL 安装依赖**:

.. code-block:: bash

   # 安装开发工具
   sudo yum groupinstall -y "Development Tools"
   sudo yum install -y python3

   # 安装 Node.js
   curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
   sudo yum install -y nodejs

安装 mediasoup
--------------------------

.. code-block:: bash

   # 创建项目目录
   mkdir my-mediasoup-app
   cd my-mediasoup-app
   npm init -y

   # 安装 mediasoup
   npm install mediasoup

   # 安装过程会自动编译 C++ Worker
   # 如果编译失败，检查 C++ 编译器版本和 Python 版本

   # 验证安装
   node -e "const ms = require('mediasoup'); console.log('mediasoup version:', ms.version);"

配置参数
--------------------------

Mediasoup 的配置通过 API 调用时传入参数来完成，没有独立的配置文件。
以下是常用的配置参数：

.. code-block:: javascript

   // config.js - 推荐的配置文件结构
   module.exports = {
     // Worker 配置
     mediasoup: {
       // Worker 数量（通常等于 CPU 核心数）
       numWorkers: require('os').cpus().length,

       // Worker 设置
       workerSettings: {
         logLevel: 'warn',           // 日志级别: debug, warn, error, none
         logTags: [
           'info',
           'ice',
           'dtls',
           'rtp',
           'srtp',
           'rtcp',
           'rtx',
           'bwe',                    // 带宽估计
           'score',                  // 质量评分
           'simulcast',
           'svc',
           'sctp'
         ],
         rtcMinPort: 10000,          // RTC 最小端口
         rtcMaxPort: 59999           // RTC 最大端口
       },

       // Router 设置（支持的媒体编解码器）
       routerOptions: {
         mediaCodecs: [
           {
             kind: 'audio',
             mimeType: 'audio/opus',
             clockRate: 48000,
             channels: 2
           },
           {
             kind: 'video',
             mimeType: 'video/VP8',
             clockRate: 90000
           },
           {
             kind: 'video',
             mimeType: 'video/VP9',
             clockRate: 90000,
             parameters: { 'profile-id': 2 }
           },
           {
             kind: 'video',
             mimeType: 'video/H264',
             clockRate: 90000,
             parameters: {
               'packetization-mode': 1,
               'profile-level-id': '4d0032',
               'level-asymmetry-allowed': 1
             }
           }
         ]
       },

       // WebRtcTransport 设置
       webRtcTransportOptions: {
         listenIps: [
           {
             ip: '0.0.0.0',
             announcedIp: '203.0.113.1'  // 公网 IP（必须配置）
           }
         ],
         initialAvailableOutgoingBitrate: 1000000,
         minimumAvailableOutgoingBitrate: 600000,
         maxSctpMessageSize: 262144,
         maxIncomingBitrate: 1500000,
         enableUdp: true,
         enableTcp: true,
         preferUdp: true
       }
     }
   };


服务端开发
===============

以下是一个完整的 mediasoup 服务端示例，展示了如何创建 Worker、Router、Transport、Producer 和 Consumer。

创建 Worker 和 Router
--------------------------

.. code-block:: javascript

   const mediasoup = require('mediasoup');
   const config = require('./config');

   // Worker 池
   const workers = [];
   let nextWorkerIdx = 0;

   /**
    * 创建所有 Worker
    */
   async function createWorkers() {
     const { numWorkers, workerSettings } = config.mediasoup;

     for (let i = 0; i < numWorkers; i++) {
       const worker = await mediasoup.createWorker(workerSettings);

       worker.on('died', (error) => {
         console.error(`Worker ${worker.pid} died: ${error.message}`);
         // 生产环境中应该重启 Worker
         setTimeout(() => process.exit(1), 2000);
       });

       workers.push(worker);
       console.log(`Worker ${worker.pid} created`);
     }
   }

   /**
    * 获取下一个 Worker（轮询负载均衡）
    */
   function getNextWorker() {
     const worker = workers[nextWorkerIdx];
     nextWorkerIdx = (nextWorkerIdx + 1) % workers.length;
     return worker;
   }

   /**
    * 创建 Router（一个"房间"对应一个 Router）
    */
   async function createRouter() {
     const worker = getNextWorker();
     const router = await worker.createRouter(config.mediasoup.routerOptions);
     console.log(`Router created [id:${router.id}]`);
     return router;
   }

创建 WebRtcTransport
--------------------------

每个参与者需要两个 Transport：一个用于发送（sendTransport），一个用于接收（recvTransport）。

.. code-block:: javascript

   /**
    * 创建 WebRtcTransport
    */
   async function createWebRtcTransport(router) {
     const transport = await router.createWebRtcTransport(
       config.mediasoup.webRtcTransportOptions
     );

     // 设置最大入站比特率
     if (config.mediasoup.webRtcTransportOptions.maxIncomingBitrate) {
       try {
         await transport.setMaxIncomingBitrate(
           config.mediasoup.webRtcTransportOptions.maxIncomingBitrate
         );
       } catch (error) {
         console.warn('setMaxIncomingBitrate() failed:', error);
       }
     }

     transport.on('dtlsstatechange', (dtlsState) => {
       if (dtlsState === 'failed' || dtlsState === 'closed') {
         console.warn(`Transport dtls state changed to ${dtlsState}`);
       }
     });

     transport.on('icestatechange', (iceState) => {
       console.log(`Transport ICE state changed to ${iceState}`);
     });

     transport.on('@close', () => {
       console.log('Transport closed');
     });

     return {
       transport,
       params: {
         id: transport.id,
         iceParameters: transport.iceParameters,
         iceCandidates: transport.iceCandidates,
         dtlsParameters: transport.dtlsParameters,
         sctpParameters: transport.sctpParameters
       }
     };
   }

连接 Transport
--------------------------

客户端创建 Transport 后，需要通过信令将 DTLS 参数发送到服务端来完成连接：

.. code-block:: javascript

   /**
    * 连接 Transport（处理客户端发来的 connectTransport 信令）
    */
   async function connectTransport(transport, dtlsParameters) {
     await transport.connect({ dtlsParameters });
     console.log(`Transport connected [id:${transport.id}]`);
   }

创建 Producer
--------------------------

.. code-block:: javascript

   /**
    * 创建 Producer（处理客户端发来的 produce 信令）
    */
   async function createProducer(transport, kind, rtpParameters, appData) {
     const producer = await transport.produce({
       kind,            // 'audio' 或 'video'
       rtpParameters,   // 客户端的 RTP 参数
       appData          // 自定义应用数据
     });

     producer.on('transportclose', () => {
       console.log(`Producer transport closed [id:${producer.id}]`);
     });

     producer.on('score', (score) => {
       console.log(`Producer score [id:${producer.id}]:`, score);
     });

     console.log(`Producer created [id:${producer.id}, kind:${kind}]`);
     return producer;
   }

创建 Consumer
--------------------------

.. code-block:: javascript

   /**
    * 创建 Consumer（当客户端需要接收某个 Producer 的媒体时）
    */
   async function createConsumer(router, transport, producer, rtpCapabilities) {
     // 检查 Router 是否可以消费该 Producer
     if (!router.canConsume({
       producerId: producer.id,
       rtpCapabilities
     })) {
       console.error('Cannot consume');
       return null;
     }

     const consumer = await transport.consume({
       producerId: producer.id,
       rtpCapabilities,
       paused: true  // 创建时暂停，等客户端准备好后再恢复
     });

     consumer.on('transportclose', () => {
       console.log(`Consumer transport closed [id:${consumer.id}]`);
     });

     consumer.on('producerclose', () => {
       console.log(`Consumer's producer closed [id:${consumer.id}]`);
     });

     consumer.on('score', (score) => {
       console.log(`Consumer score [id:${consumer.id}]:`, score);
     });

     consumer.on('layerschange', (layers) => {
       console.log(`Consumer layers changed [id:${consumer.id}]:`, layers);
     });

     return {
       consumer,
       params: {
         id: consumer.id,
         producerId: producer.id,
         kind: consumer.kind,
         rtpParameters: consumer.rtpParameters,
         appData: producer.appData
       }
     };
   }


客户端开发
===============

Mediasoup 提供了 ``mediasoup-client`` 库用于浏览器端开发，以及 ``libmediasoupclient`` 用于原生 C++ 客户端。

安装 mediasoup-client
--------------------------

.. code-block:: bash

   npm install mediasoup-client

Device 初始化
--------------------------

``Device`` 是 mediasoup-client 的核心对象，代表一个端点设备。
首先需要用 Router 的 RTP Capabilities 来加载 Device：

.. code-block:: javascript

   import { Device } from 'mediasoup-client';

   // 创建 Device
   const device = new Device();

   // 从服务端获取 Router 的 RTP Capabilities
   // （通过信令获取 router.rtpCapabilities）
   const routerRtpCapabilities = await signaling.request(
     'getRouterRtpCapabilities'
   );

   // 加载 Device
   await device.load({ routerRtpCapabilities });

   console.log('Device loaded');
   console.log('Can produce audio:', device.canProduce('audio'));
   console.log('Can produce video:', device.canProduce('video'));

创建 Send Transport
--------------------------

.. code-block:: javascript

   // 从服务端创建 Transport 并获取参数
   const transportParams = await signaling.request('createWebRtcTransport', {
     producing: true,
     consuming: false
   });

   // 在客户端创建 sendTransport
   const sendTransport = device.createSendTransport(transportParams);

   // 当 Transport 需要连接时触发
   sendTransport.on('connect', async ({ dtlsParameters }, callback, errback) => {
     try {
       await signaling.request('connectTransport', {
         transportId: sendTransport.id,
         dtlsParameters
       });
       callback();
     } catch (error) {
       errback(error);
     }
   });

   // 当 Transport 需要发送新的 Producer 时触发
   sendTransport.on('produce', async ({ kind, rtpParameters, appData }, callback, errback) => {
     try {
       const { id } = await signaling.request('produce', {
         transportId: sendTransport.id,
         kind,
         rtpParameters,
         appData
       });
       callback({ id });
     } catch (error) {
       errback(error);
     }
   });

创建 Recv Transport
--------------------------

.. code-block:: javascript

   // 从服务端创建 Transport 并获取参数
   const recvTransportParams = await signaling.request('createWebRtcTransport', {
     producing: false,
     consuming: true
   });

   // 在客户端创建 recvTransport
   const recvTransport = device.createRecvTransport(recvTransportParams);

   // 当 Transport 需要连接时触发
   recvTransport.on('connect', async ({ dtlsParameters }, callback, errback) => {
     try {
       await signaling.request('connectTransport', {
         transportId: recvTransport.id,
         dtlsParameters
       });
       callback();
     } catch (error) {
       errback(error);
     }
   });

发送媒体（Produce）
--------------------------

.. code-block:: javascript

   // 获取本地媒体流
   const stream = await navigator.mediaDevices.getUserMedia({
     audio: true,
     video: {
       width: { ideal: 1280 },
       height: { ideal: 720 },
       frameRate: { ideal: 30 }
     }
   });

   // 发送音频
   const audioTrack = stream.getAudioTracks()[0];
   const audioProducer = await sendTransport.produce({
     track: audioTrack,
     codecOptions: {
       opusStereo: true,
       opusDtx: true
     }
   });

   // 发送视频（带 Simulcast）
   const videoTrack = stream.getVideoTracks()[0];
   const videoProducer = await sendTransport.produce({
     track: videoTrack,
     encodings: [
       { maxBitrate: 100000, scaleResolutionDownBy: 4 },   // 低质量层
       { maxBitrate: 300000, scaleResolutionDownBy: 2 },   // 中质量层
       { maxBitrate: 900000, scaleResolutionDownBy: 1 }    // 高质量层
     ],
     codecOptions: {
       videoGoogleStartBitrate: 1000
     }
   });

接收媒体（Consume）
--------------------------

.. code-block:: javascript

   // 当服务端通知有新的 Producer 可以消费时
   signaling.on('newConsumer', async (data) => {
     const {
       peerId,
       producerId,
       id,
       kind,
       rtpParameters,
       appData
     } = data;

     // 在 recvTransport 上创建 Consumer
     const consumer = await recvTransport.consume({
       id,
       producerId,
       kind,
       rtpParameters
     });

     // 获取媒体轨道
     const { track } = consumer;

     // 将轨道添加到页面上的 <video> 或 <audio> 元素
     if (kind === 'video') {
       const videoElement = document.getElementById(`video-${peerId}`);
       videoElement.srcObject = new MediaStream([track]);
       await videoElement.play();
     } else {
       const audioElement = document.getElementById(`audio-${peerId}`);
       audioElement.srcObject = new MediaStream([track]);
       await audioElement.play();
     }

     // 通知服务端恢复 Consumer
     await signaling.request('resumeConsumer', { consumerId: id });
   });


信令设计
===============

Mediasoup 不提供信令服务器，开发者需要自行实现。以下是一个典型的信令消息设计：

信令消息列表
--------------------------

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - 消息名称
     - 方向
     - 说明
   * - getRouterRtpCapabilities
     - C → S
     - 获取 Router 的 RTP 能力
   * - createWebRtcTransport
     - C → S
     - 请求创建 WebRtcTransport
   * - connectTransport
     - C → S
     - 连接 Transport（发送 DTLS 参数）
   * - produce
     - C → S
     - 请求创建 Producer
   * - consume
     - C → S
     - 请求创建 Consumer
   * - resumeConsumer
     - C → S
     - 恢复暂停的 Consumer
   * - pauseConsumer
     - C → S
     - 暂停 Consumer
   * - closeProducer
     - C → S
     - 关闭 Producer
   * - newConsumer
     - S → C
     - 通知客户端有新的 Consumer 可用
   * - consumerClosed
     - S → C
     - 通知客户端 Consumer 已关闭
   * - producerScore
     - S → C
     - 通知 Producer 质量评分变化
   * - consumerScore
     - S → C
     - 通知 Consumer 质量评分变化
   * - consumerLayersChanged
     - S → C
     - 通知 Consumer 的 Simulcast/SVC 层变化

WebSocket 信令示例
--------------------------

.. code-block:: javascript

   // 服务端 - 使用 ws 库
   const WebSocket = require('ws');
   const wss = new WebSocket.Server({ port: 8443 });

   wss.on('connection', (ws) => {
     ws.on('message', async (message) => {
       const { method, data, requestId } = JSON.parse(message);

       let response;
       switch (method) {
         case 'getRouterRtpCapabilities':
           response = router.rtpCapabilities;
           break;

         case 'createWebRtcTransport':
           const { transport, params } = await createWebRtcTransport(router);
           // 保存 transport 到用户会话
           response = params;
           break;

         case 'connectTransport':
           await connectTransport(
             getTransport(data.transportId),
             data.dtlsParameters
           );
           response = { connected: true };
           break;

         case 'produce':
           const producer = await createProducer(
             getTransport(data.transportId),
             data.kind,
             data.rtpParameters,
             data.appData
           );
           response = { id: producer.id };
           // 通知其他参与者有新的 Producer
           broadcastNewProducer(ws, producer);
           break;

         // ... 其他消息处理
       }

       ws.send(JSON.stringify({ requestId, response }));
     });
   });


Simulcast 和 SVC 支持
=========================

Mediasoup 完整支持 Simulcast（同时发送多个分辨率/帧率的视频流）和 SVC（Scalable Video Coding，可伸缩视频编码）。

Simulcast 配置
--------------------------

Simulcast 允许发送端同时编码多个质量层（spatial layers），SFU 根据接收端的网络状况选择合适的层进行转发。

.. code-block:: javascript

   // 客户端发送 Simulcast 视频
   const videoProducer = await sendTransport.produce({
     track: videoTrack,
     encodings: [
       {
         rid: 'r0',
         maxBitrate: 100000,
         scaleResolutionDownBy: 4,
         scalabilityMode: 'S1T3'
       },
       {
         rid: 'r1',
         maxBitrate: 300000,
         scaleResolutionDownBy: 2,
         scalabilityMode: 'S1T3'
       },
       {
         rid: 'r2',
         maxBitrate: 900000,
         scaleResolutionDownBy: 1,
         scalabilityMode: 'S1T3'
       }
     ],
     codecOptions: {
       videoGoogleStartBitrate: 1000
     }
   });

   // 服务端切换 Consumer 的接收层
   // preferredLayers: { spatialLayer: 0-2, temporalLayer: 0-2 }
   await consumer.setPreferredLayers({
     spatialLayer: 2,     // 最高空间层
     temporalLayer: 2     // 最高时间层
   });

SVC 配置（VP9 SVC）
--------------------------

VP9 SVC 使用单个编码器生成多个可伸缩层，比 Simulcast 更高效：

.. code-block:: javascript

   // VP9 SVC 发送
   const videoProducer = await sendTransport.produce({
     track: videoTrack,
     encodings: [
       {
         scalabilityMode: 'S3T3_KEY'  // 3 个空间层，3 个时间层
       }
     ],
     codecOptions: {
       videoGoogleStartBitrate: 1000
     }
   });


录制
===============

Mediasoup 可以通过 PlainTransport 将媒体流转发给外部录制工具（如 FFmpeg 或 GStreamer）。

使用 PlainTransport + FFmpeg 录制
--------------------------------------

.. code-block:: javascript

   // 1. 创建 PlainTransport
   const plainTransport = await router.createPlainTransport({
     listenIp: { ip: '127.0.0.1' },
     rtcpMux: false,
     comedia: true
   });

   // 2. 在 PlainTransport 上创建 Consumer
   const audioConsumer = await plainTransport.consume({
     producerId: audioProducer.id,
     rtpCapabilities: router.rtpCapabilities,
     paused: false
   });

   const videoConsumer = await plainTransport.consume({
     producerId: videoProducer.id,
     rtpCapabilities: router.rtpCapabilities,
     paused: false
   });

   // 3. 获取 RTP 端口信息
   const audioPort = plainTransport.tuple.localPort;
   const audioRtcpPort = plainTransport.rtcpTuple.localPort;
   const videoPort = /* 另一个 PlainTransport 的端口 */;

   // 4. 生成 SDP 文件
   const sdpContent = `v=0
   o=- 0 0 IN IP4 127.0.0.1
   s=Recording
   c=IN IP4 127.0.0.1
   t=0 0
   m=audio ${audioPort} RTP/AVP 111
   a=rtpmap:111 opus/48000/2
   a=fmtp:111 minptime=10;useinbandfec=1
   m=video ${videoPort} RTP/AVP 96
   a=rtpmap:96 VP8/90000`;

   // 5. 使用 FFmpeg 录制
   // ffmpeg -protocol_whitelist file,rtp,udp -i recording.sdp -c:a aac -c:v libx264 output.mp4

**FFmpeg 录制命令**:

.. code-block:: bash

   # 使用 SDP 文件录制
   ffmpeg -protocol_whitelist file,rtp,udp \
     -i recording.sdp \
     -c:a aac -c:v libx264 \
     -preset ultrafast \
     output.mp4

   # 或者使用 GStreamer 录制
   gst-launch-1.0 \
     rtpbin name=rtpbin \
     udpsrc port=5004 caps="application/x-rtp,media=audio,encoding-name=OPUS" \
     ! rtpbin.recv_rtp_sink_0 \
     rtpbin. ! rtpopusdepay ! opusdec ! audioconvert ! wavenc ! filesink location=audio.wav


水平扩展
===============

当单个 mediasoup 服务器无法满足需求时，可以通过 PipeTransport 实现跨 Worker 和跨服务器的媒体路由。

PipeTransport 跨 Worker
--------------------------

同一台服务器上的不同 Worker（Router）之间可以通过 PipeTransport 传输媒体：

.. code-block:: javascript

   // Router A 在 Worker 1 上
   // Router B 在 Worker 2 上

   // 在 Router A 和 Router B 之间建立 Pipe
   const { pipeConsumer, pipeProducer } = await routerA.pipeToRouter({
     producerId: producerInRouterA.id,
     router: routerB
   });

   // 现在 Router B 中的 Consumer 可以消费 pipeProducer
   const consumer = await transportInRouterB.consume({
     producerId: pipeProducer.id,
     rtpCapabilities: device.rtpCapabilities
   });

PipeTransport 跨服务器
--------------------------

不同服务器之间也可以通过 PipeTransport 传输媒体：

.. code-block:: javascript

   // Server A
   const pipeTransportA = await routerA.createPipeTransport({
     listenIp: { ip: '0.0.0.0', announcedIp: 'SERVER_A_PUBLIC_IP' }
   });

   // Server B
   const pipeTransportB = await routerB.createPipeTransport({
     listenIp: { ip: '0.0.0.0', announcedIp: 'SERVER_B_PUBLIC_IP' }
   });

   // 互相连接（通过信令交换连接信息）
   await pipeTransportA.connect({
     ip: 'SERVER_B_PUBLIC_IP',
     port: pipeTransportB.tuple.localPort
   });

   await pipeTransportB.connect({
     ip: 'SERVER_A_PUBLIC_IP',
     port: pipeTransportA.tuple.localPort
   });

   // 在 pipeTransportA 上创建 Consumer，消费 Server A 的 Producer
   const pipeConsumer = await pipeTransportA.consume({
     producerId: producerOnServerA.id
   });

   // 在 pipeTransportB 上创建 Producer，将媒体注入 Server B 的 Router
   const pipeProducer = await pipeTransportB.produce({
     id: pipeConsumer.producerId,
     kind: pipeConsumer.kind,
     rtpParameters: pipeConsumer.rtpParameters
   });

负载均衡策略
--------------------------

.. code-block:: text

   ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
   │   Server 1   │     │   Server 2   │     │   Server 3   │
   │  Workers: 4  │◄───►│  Workers: 4  │◄───►│  Workers: 4  │
   │  Rooms: A,B  │     │  Rooms: C,D  │     │  Rooms: E,F  │
   └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
          │                    │                    │
          └────────────────────┼────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │   Load Balancer     │
                    │  (Room → Server)    │
                    └─────────────────────┘

常见的负载均衡策略：

1. **按房间分配**: 同一个房间的所有参与者分配到同一台服务器
2. **按 Worker 分配**: 轮询分配 Worker，每个 Worker 处理一个或多个 Router
3. **跨服务器房间**: 大型房间可以跨多台服务器，使用 PipeTransport 连接


mediasoup-demo 部署
========================

Mediasoup 官方提供了一个完整的 demo 应用，包含服务端和客户端：

.. code-block:: bash

   # 克隆 demo 仓库
   git clone https://github.com/versatica/mediasoup-demo.git
   cd mediasoup-demo
   git checkout v3

   # 安装服务端依赖
   cd server
   npm install

   # 复制配置文件
   cp config.example.js config.js
   # 编辑 config.js，配置公网 IP 等参数

   # 安装客户端依赖
   cd ../app
   npm install

   # 启动服务端
   cd ../server
   node server.js

   # 在另一个终端启动客户端（开发模式）
   cd ../app
   npx gulp live

   # 访问 https://localhost:3000

**config.js 关键配置**:

.. code-block:: javascript

   module.exports = {
     // HTTPS 配置（WebRTC 需要 HTTPS）
     https: {
       listenIp: '0.0.0.0',
       listenPort: 4443,
       tls: {
         cert: '/path/to/fullchain.pem',
         key: '/path/to/privkey.pem'
       }
     },
     // mediasoup 配置
     mediasoup: {
       numWorkers: require('os').cpus().length,
       workerSettings: { /* ... */ },
       routerOptions: { /* ... */ },
       webRtcTransportOptions: {
         listenIps: [
           { ip: '0.0.0.0', announcedIp: 'YOUR_PUBLIC_IP' }
         ]
       }
     }
   };

**Docker 部署**:

.. code-block:: bash

   # 使用 Docker Compose
   docker-compose up -d

   # 或者手动构建
   docker build -t mediasoup-demo .
   docker run -d \
     --name mediasoup-demo \
     --network host \
     -e MEDIASOUP_ANNOUNCED_IP=YOUR_PUBLIC_IP \
     mediasoup-demo


常见问题
===============

1. **编译失败**: 确保 gcc/g++ >= 8，Python 3 已安装，Node.js >= 16
2. **ICE 连接失败**: 检查 ``announcedIp`` 是否配置为正确的公网 IP
3. **DTLS 握手失败**: 检查防火墙是否开放了 RTC 端口范围（UDP）
4. **音视频卡顿**: 检查服务器带宽，调整 Simulcast 层或降低比特率
5. **Worker 崩溃**: 检查日志，可能是内存不足或端口耗尽
6. **高延迟**: 确保服务器地理位置靠近用户，使用 UDP 而非 TCP


Example
================


* https://github.com/versatica/mediasoup-demo


.. code-block:: bash

    $ git clone https://github.com/versatica/mediasoup-demo.git
    $ cd mediasoup-demo
    $ git checkout v3


Reference
===============

* `MediaSoup offical site`_

.. _MediaSoup offical site: https://mediasoup.org/

* Mediasoup GitHub 仓库

  - https://github.com/versatica/mediasoup

* Mediasoup 官方文档

  - https://mediasoup.org/documentation/v3/

* mediasoup-client 文档

  - https://mediasoup.org/documentation/v3/mediasoup-client/

* mediasoup-demo

  - https://github.com/versatica/mediasoup-demo

* libmediasoupclient（C++ 客户端）

  - https://github.com/versatica/libmediasoupclient

* Mediasoup 设计理念

  - https://mediasoup.org/documentation/v3/mediasoup/design/

* RFC 3550 - RTP: A Transport Protocol for Real-Time Applications

  - https://tools.ietf.org/html/rfc3550

* RFC 7741 - RTP Payload Format for VP8 Video

  - https://tools.ietf.org/html/rfc7741
