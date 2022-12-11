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
--------------------------------------
HTTP Live Streaming (also known as HLS) is an HTTP-based adaptive bitrate streaming communications protocol developed by Apple Inc. and released in 2009. Support for the protocol is widespread in media players, web browsers, mobile devices, and streaming media servers. As of 2019, an annual video industry survey has consistently found it to be the most popular streaming format.[2]

HLS resembles MPEG-DASH in that it works by breaking the overall stream into a sequence of small HTTP-based file downloads, each downloading one short chunk of an overall potentially unbounded transport stream. A list of available streams, encoded at different bit rates, is sent to the client using an extended M3U playlist.

Based on standard HTTP transactions, HTTP Live Streaming can traverse any firewall or proxy server that lets through standard HTTP traffic, unlike UDP-based protocols such as RTP. This also allows content to be offered from conventional HTTP servers and delivered over widely available HTTP-based content delivery networks. The standard also includes a standard encryption mechanism[5] and secure-key distribution using HTTPS, which together provide a simple DRM system. Later versions of the protocol also provide for trick-mode fast-forward and rewind and for integration of subtitle


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