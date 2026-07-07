##############
aiortc
##############


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Python WebRTC 库 aiortc
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
===============

aiortc 是一个纯 Python 实现的 WebRTC 和 ORTC 库，基于 ``asyncio`` 异步框架构建。
它的 API 紧密对应 JavaScript WebRTC API，同时使用 Python 风格的语法：

- Promise → ``async/await`` 协程
- Event → ``pyee.EventEmitter``

aiortc 非常适合以下场景：

- 服务器端 WebRTC（媒体录制、转码、AI 处理）
- 自动化测试（模拟 WebRTC 客户端）
- 快速原型验证


主要特性
---------------

- SDP 生成与解析
- ICE 连接建立（支持 half-trickle 和 mDNS）
- DTLS 密钥生成与握手
- SRTP 加解密
- 纯 Python SCTP 实现
- DataChannel
- 音频编解码（Opus / PCMU / PCMA）
- 视频编解码（VP8 / H.264）
- RTCP 反馈（NACK / PLI）


安装
========================

.. code-block:: bash

   pip install aiortc

   # 带视频处理支持
   pip install aiortc opencv-python

   # 带 Web 服务器支持（用于信令）
   pip install aiortc aiohttp


基本用法
========================

建立 P2P 连接（Offer 端）
-----------------------------

.. code-block:: python

   import asyncio
   from aiortc import RTCPeerConnection, RTCSessionDescription
   from aiortc.contrib.media import MediaPlayer

   async def run():
       pc = RTCPeerConnection()

       # 添加本地媒体轨道
       player = MediaPlayer('/dev/video0', format='v4l2',
                             options={'video_size': '640x480'})
       if player.audio:
           pc.addTrack(player.audio)
       if player.video:
           pc.addTrack(player.video)

       # 创建 Offer
       offer = await pc.createOffer()
       await pc.setLocalDescription(offer)

       # 将 offer.sdp 发送给对端...
       # 收到 answer 后：
       # await pc.setRemoteDescription(
       #     RTCSessionDescription(sdp=answer_sdp, type='answer'))

       # 保持运行
       await asyncio.sleep(3600)

   asyncio.run(run())


接收远端轨道
-----------------------------

.. code-block:: python

   from aiortc.contrib.media import MediaRecorder

   recorder = MediaRecorder('output.mp4')

   @pc.on('track')
   async def on_track(track):
       if track.kind == 'video':
           recorder.addTrack(track)
           await recorder.start()

   # 结束时
   await recorder.stop()


DataChannel
-----------------------------

.. code-block:: python

   # 创建 DataChannel
   channel = pc.createDataChannel('chat')

   @channel.on('open')
   def on_open():
       channel.send('Hello from Python!')

   @channel.on('message')
   def on_message(message):
       print(f'Received: {message}')

   # 接收对端创建的 DataChannel
   @pc.on('datachannel')
   def on_datachannel(channel):
       @channel.on('message')
       def on_message(message):
           channel.send(f'echo: {message}')


视频处理示例
========================

结合 OpenCV 对接收的视频帧进行处理：

.. code-block:: python

   from aiortc import VideoStreamTrack
   from av import VideoFrame
   import cv2
   import numpy as np

   class VideoTransformTrack(VideoStreamTrack):
       """对收到的视频帧进行边缘检测"""

       def __init__(self, track):
           super().__init__()
           self.track = track

       async def recv(self):
           frame = await self.track.recv()
           img = frame.to_ndarray(format='bgr24')

           # OpenCV 边缘检测
           edges = cv2.Canny(img, 100, 200)
           edges_bgr = cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)

           new_frame = VideoFrame.from_ndarray(edges_bgr, format='bgr24')
           new_frame.pts = frame.pts
           new_frame.time_base = frame.time_base
           return new_frame

   # 将处理后的轨道发回对端
   @pc.on('track')
   async def on_track(track):
       if track.kind == 'video':
           pc.addTrack(VideoTransformTrack(track))


架构说明
========================

.. code-block:: text

   aiortc 内部结构：

   RTCPeerConnection
   ├── RTCDtlsTransport     ← DTLS 握手与密钥导出
   │   └── RTCIceTransport  ← ICE 连通性检查
   ├── RTCRtpSender         ← RTP 发送（编码 + SRTP）
   ├── RTCRtpReceiver       ← RTP 接收（SRTP + 解码）
   ├── RTCSctpTransport     ← SCTP over DTLS
   │   └── RTCDataChannel   ← 数据通道
   └── SDP 协商逻辑

aiortc 的所有网络 I/O 都通过 ``asyncio`` 事件循环驱动，
单线程即可处理多个并发连接。


参考资料
=======================

- 源码: https://github.com/aiortc/aiortc
- 文档: https://aiortc.readthedocs.io/en/latest/
- 示例: https://github.com/aiortc/aiortc/tree/main/examples
- PyPI: https://pypi.org/project/aiortc/
