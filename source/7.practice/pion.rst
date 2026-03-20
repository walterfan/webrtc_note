###################
Pion
###################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Pion WebRTC
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:


概述
========================

Pion 是一个用纯 Go 语言编写的 WebRTC 实现，不依赖 C/C++ 的 libwebrtc。
它是目前 Go 生态中最成熟的 WebRTC 库，广泛用于 SFU、录制、转码、实时通信后端等场景。

核心特点：

- **纯 Go 实现**：无 CGO 依赖，交叉编译方便，部署简单
- **模块化设计**：WebRTC、ICE、DTLS、SRTP、SCTP、RTP 等协议分别独立为子包
- **Interceptor 框架**：可插拔的 RTP/RTCP 中间件，支持 NACK、TWCC、报告生成等
- **活跃社区**：GitHub 12k+ stars，持续维护

项目地址: https://github.com/pion/webrtc


模块组成
========================

Pion 不是单一仓库，而是一组模块化的 Go 包：

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 模块
     - 说明
   * - ``pion/webrtc``
     - 核心 WebRTC API，对标 W3C WebRTC 规范
   * - ``pion/ice``
     - ICE 协议实现（候选收集、连通性检查、Trickle ICE）
   * - ``pion/dtls``
     - DTLS 1.2 实现
   * - ``pion/srtp``
     - SRTP/SRTCP 加解密
   * - ``pion/sctp``
     - SCTP 协议实现（用于 DataChannel）
   * - ``pion/rtp``
     - RTP 包解析和构造
   * - ``pion/rtcp``
     - RTCP 包解析（SR、RR、NACK、PLI、REMB、TWCC 等）
   * - ``pion/sdp``
     - SDP 解析和生成
   * - ``pion/interceptor``
     - RTP/RTCP 中间件框架
   * - ``pion/mediadevices``
     - 摄像头/麦克风采集（跨平台）
   * - ``pion/turn``
     - TURN 服务端和客户端实现


安装
========================

.. code-block:: bash

   go get github.com/pion/webrtc/v4


基本用法示例
========================

P2P 视频通话
--------------------------

.. code-block:: go

   package main

   import (
       "fmt"
       "github.com/pion/webrtc/v4"
   )

   func main() {
       // 创建 PeerConnection
       config := webrtc.Configuration{
           ICEServers: []webrtc.ICEServer{
               {URLs: []string{"stun:stun.l.google.com:19302"}},
           },
       }
       pc, err := webrtc.NewPeerConnection(config)
       if err != nil {
           panic(err)
       }
       defer pc.Close()

       // 监听 ICE 连接状态
       pc.OnICEConnectionStateChange(func(state webrtc.ICEConnectionState) {
           fmt.Printf("ICE 状态: %s\n", state.String())
       })

       // 监听远端轨道
       pc.OnTrack(func(track *webrtc.TrackRemote, receiver *webrtc.RTPReceiver) {
           fmt.Printf("收到远端轨道: %s (codec: %s)\n",
               track.Kind().String(), track.Codec().MimeType)

           // 读取 RTP 包
           buf := make([]byte, 1500)
           for {
               n, _, readErr := track.Read(buf)
               if readErr != nil {
                   return
               }
               fmt.Printf("收到 %d 字节 RTP 数据\n", n)
           }
       })

       // 创建 Offer（实际场景中通过信令交换）
       offer, err := pc.CreateOffer(nil)
       if err != nil {
           panic(err)
       }
       pc.SetLocalDescription(offer)
       fmt.Println("SDP Offer:\n", offer.SDP)
   }

DataChannel 示例
--------------------------

.. code-block:: go

   // 发送端
   dc, err := pc.CreateDataChannel("chat", nil)
   dc.OnOpen(func() {
       dc.SendText("Hello from Go!")
   })

   // 接收端
   pc.OnDataChannel(func(dc *webrtc.DataChannel) {
       dc.OnMessage(func(msg webrtc.DataChannelMessage) {
           fmt.Printf("收到消息: %s\n", string(msg.Data))
       })
   })


Interceptor 框架
========================

Interceptor 是 Pion 的 RTP/RTCP 中间件机制，可以在包发送/接收路径上插入处理逻辑：

.. code-block:: text

   应用层
     │
     ▼
   ┌─────────────────────────┐
   │   Interceptor Chain     │
   │  ┌───────────────────┐  │
   │  │  TWCC Interceptor │  │  ← 生成 TWCC 反馈
   │  ├───────────────────┤  │
   │  │  NACK Interceptor │  │  ← 处理 NACK 请求和重传
   │  ├───────────────────┤  │
   │  │  Report Interceptor│ │  ← 生成 SR/RR 报告
   │  └───────────────────┘  │
   └─────────────────────────┘
     │
     ▼
   SRTP/网络层

内置 Interceptor：

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Interceptor
     - 功能
   * - ``nack``
     - 根据 NACK 请求自动重传丢失的 RTP 包
   * - ``twcc``
     - Transport-Wide CC：发送端记录包发送时间，接收端生成 TWCC 反馈
   * - ``report``
     - 自动生成 RTCP Sender Report 和 Receiver Report
   * - ``flexfec``
     - FlexFEC 前向纠错（实验性）

使用方法：

.. code-block:: go

   import "github.com/pion/interceptor"
   import "github.com/pion/interceptor/pkg/nack"
   import "github.com/pion/interceptor/pkg/twcc"

   m := &webrtc.MediaEngine{}
   m.RegisterDefaultCodecs()

   i := &interceptor.Registry{}
   // 注册 NACK
   responder, _ := nack.NewResponderInterceptor()
   i.Add(responder)
   generator, _ := nack.NewGeneratorInterceptor()
   i.Add(generator)
   // 注册 TWCC
   twccSender, _ := twcc.NewSenderInterceptor()
   i.Add(twccSender)

   api := webrtc.NewAPI(
       webrtc.WithMediaEngine(m),
       webrtc.WithInterceptorRegistry(i),
   )
   pc, _ := api.NewPeerConnection(config)


SFU 开发要点
========================

Pion 非常适合构建 SFU（Selective Forwarding Unit），核心模式：

.. code-block:: go

   // SFU 核心：将一个发送者的轨道转发给所有接收者
   func forwardTrack(src *webrtc.TrackRemote, receivers []*webrtc.PeerConnection) {
       // 创建本地轨道（用于转发）
       localTrack, _ := webrtc.NewTrackLocalStaticRTP(
           src.Codec().RTPCodecCapability, src.ID(), src.StreamID())

       // 将本地轨道添加到所有接收者
       for _, pc := range receivers {
           pc.AddTrack(localTrack)
       }

       // 从源读取 RTP 并写入本地轨道
       buf := make([]byte, 1500)
       for {
           n, _, err := src.Read(buf)
           if err != nil {
               return
           }
           localTrack.Write(buf[:n])
       }
   }

基于 Pion 的 SFU 项目：

- **ion-sfu**: https://github.com/pion/ion-sfu — Pion 官方 SFU 实现
- **Livekit**: https://github.com/livekit/livekit — 基于 Pion 的商业级 SFU
- **lazy-rabbit-meeting**: 本教程作者的 SFU 实践项目，参见 :doc:`lazy_rabbit_meeting`


官方示例
========================

Pion 仓库包含丰富的示例代码：

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - 示例
     - 说明
   * - ``save-to-disk``
     - 将 WebRTC 音视频录制为 WebM/Ogg 文件
   * - ``play-from-disk``
     - 从文件读取并通过 WebRTC 发送
   * - ``data-channels``
     - DataChannel 双向通信
   * - ``simulcast``
     - Simulcast 多层编码接收
   * - ``rtp-forwarder``
     - 将 WebRTC 轨道转发为 RTP 流
   * - ``insertable-streams``
     - 端到端加密
   * - ``stats``
     - 获取 WebRTC 统计信息

运行示例：

.. code-block:: bash

   git clone https://github.com/pion/webrtc.git
   cd webrtc/examples/save-to-disk
   go run .


参考资料
========================

- Pion WebRTC: https://github.com/pion/webrtc
- Pion Interceptor: https://github.com/pion/interceptor
- Pion 示例: https://github.com/pion/webrtc/tree/master/examples
- Pion MediaDevices: https://github.com/pion/mediadevices
- Pion TURN Server: https://github.com/pion/turn
- ion-sfu: https://github.com/pion/ion-sfu
