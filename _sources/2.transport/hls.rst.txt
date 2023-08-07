########################
HTTP Live Streaming
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** HTTP Live Streaming
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

简介
=======================================
A streaming protocol specifically dictates how streaming media is broken up and transmitted across a network.

* HTTP Live Streaming (HLS)
* Real-Time Messaging Protocol (RTMP)
* Real-Time Streaming Protocol (RTSP)
* WebRTC
* Secure Reliable Transport (SRT)


video streaming 协议回顾
--------------------------------------
* RTMP: Adobe 公司为 Flash 播放器和服务器之间音频、视频和数据传输开发的协议。

* HTTP-FLV: Adobe 公司推出，将音视频数据封装成 flv, 然后通过 http 协议传送给客户端。

* HLS (全称：Http Live Streaming):
  采集推流端将视频流推到流媒体服务器时，服务器将收到的流信息每缓存一段时间就生成一个新的 ts 文件，同时建立一个m3u8的文件来维护几个最新的 ts 文件索引，
  会时时更新 m3u8 索引文件内容，所以当播放端获取直播时，从 m3u8 索引文件里面获取的播放 ts 视频文件片段都是最新的，保证用户在任何时间进直播都能看到较新内容，近似直播体验。

* DASH: 也叫 MEPG-DASH，是可以发送动态码率的直播技术，借助 MPD 将视频分割成多个切片，每个切片都有不同的码率;
  DASH 客户端会根据自己网络情况选择一个码率进行播放，是类似 HLS 的一种技术。

* FMP4: mp4 本身数据结构是 box 嵌套 box，所以不能只下载某个小段视频播放，因为 meta 信息不完善，依赖于外层 box 的 meta 信息，
  所以普通的 mp4 视频只能把整个索引文件下载下来然后用户才能播放，短视频还好，遇到长一些的视频，比如电视剧和电影等，索引文件特别大，导致首帧视频时常很长，给用户卡顿的感受，
  所以出了 fmp4 这种格式，然后每个小段视频格式都是独立的一个数据包，符合流的数据格式规定, 不用下载整个索引文件，只需要下载视频片段的相应小索引文件就能播放，减少了用户的等待时间


HLS
====================================================
HTTP Live Streaming（也称为HLS）是由Apple Inc.开发并于2009年发布的基于HTTP的自适应比特率流通信协议。对协议的支持在媒体播放器、Web 浏览器、移动设备和流媒体服务器中广泛存在。截至 2019 年，一项年度视频行业调查一直发现它是最受欢迎的流媒体格式。

HLS类似于MPEG-DASH，因为它通过将整个流分解为一系列基于HTTP的小型文件下载来工作，每个下载一个整体潜在无限传输流的一小块。以不同比特率编码的可用流列表使用扩展的 M3U 播放列表发送到客户端。

基于标准 HTTP 事务，HTTP 实时流可以遍历任何允许通过标准 HTTP 流量的防火墙或代理服务器，这与基于 UDP 的协议（如 RTP）不同。这也允许从传统的HTTP服务器提供内容，并通过广泛可用的基于HTTP的内容交付网络交付内容。该标准还包括一个标准的加密机制和使用HTTPS的安全密钥分发，它们共同提供了一个简单的DRM系统。该协议的更高版本还提供技巧模式快进和快退以及字幕的集成


HLS 是新一代流媒体传输协议，其基本实现原理为将一个大的媒体文件进行分片，将该分片文件资源路径记录于 m3u8 文件（即 playlist）内，其中附带一些额外描述（比如该资源的多带宽信息···）用于提供给客户端。客户端依据该 m3u8 文件即可获取对应的媒体资源，进行播放。


metadata file
----------------------------
* m3u8

.. code-block::

  #EXTM3U
  #EXT-X-TARGETDURATION:10

  #EXTINF:9.009,
  http://media.example.com/first.ts
  #EXTINF:9.009,
  http://media.example.com/second.ts
  #EXTINF:3.003,
  http://media.example.com/third.ts

media file
----------------------------
* mpeg2-ts
* fMP4


ts文件为传输流文件，视频编码主要格式h264/mpeg4，音频为acc/MP3。

ts文件分为三层：
1) ts层Transport Stream、
2) pes层 Packet Elemental Stream、
3) es层 Elementary Stream. 

es层就是音视频数据，pes层是在音视频数据上加了时间戳等对数据帧的说明信息，ts层就是在pes层加入数据流的识别和传输必须的信息

Protocols Enhancement
==========================

* LL-HLS: Low-Latency HTTP Live Streaming
* LL-DASH
* LAS: HTTP FLV

Implementation
===========================

Nginx RTMP module

Performance
==========================
HLS may have 10s above delay, need low latency HLS


mp4 --> hls.m3u8 + ts


mp4
=========================
* normal mp4
* fast start noraml mp4
* fragment mp4

Reference
=======================================
* https://en.wikipedia.org/wiki/HTTP_Live_Streaming
* https://www.dacast.com/blog/hls-streaming-protocol/
* https://developer.apple.com/documentation/http_live_streaming/preparing_audio_for_http_live_streaming
* HTTP Live Streaming: https://datatracker.ietf.org/doc/html/rfc8216
* https://segmentfault.com/a/1190000021788479