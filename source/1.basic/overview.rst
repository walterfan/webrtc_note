######################
WebRTC 概论
######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC 概论
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================

.. contents::
   :local:


WebRTC 简介
=======================

一句话，WebRTC 用浏览器来进行实时通信的一套基于 Web 进行实时通信的标准和参考实现, 它也是一个开源项目，最初由 google 发起并交由开源社区，各大浏览器厂商在其各自的产品中亦有部分的采用。

借助WebRTC，你可以在基于开放标准的应用程序中添加实时通信功能。 它支持在节点之间发送视频，语音和通用数据，从而使开发人员能够构建功能强大的语音和视频通信解决方案。 该技术可在所有现代浏览器以及所有主要平台的本机客户端上使用。 

WebRTC背后的技术被实现为一个开放的Web标准，并在所有主要浏览器中均以常规JavaScript API的形式提供。 对于本机客户端（例如Android和iOS应用程序），可以使用提供相同功能的库。 

.. image:: ../_static/webrtc-architecture.png

什么是 WebRTC?
---------------------------------

WebRTC 意味着两个东西：

1. 它是一套浏览器的实时通信规范，包括：

 * 网络实时通讯标准
 * W3C 和 IETF 正在标准化的规范
 * 通过简单的 JavaScript API 启用Web 浏览器中的音频、视频和屏幕共享功能
 * 无需安装
 * 可以做点对点通讯，也可以用于音视频会议
 * 具有与现有语音和视频系统的互操作性
  
2. 这也是一个开源项目，包括：
   
 * 最初由 Google 贡献
 * 由 C++ 实现，可跨平台
 * 代码很多来自于 Google 对 Global IP Solutions 的收购
 * 大多数新视频公司都是基于这个项目

WebRTC 是一个开放的网络框架，可在浏览器中启用实时通信，包括如下功能

* 媒体设备的访问 MediaDevices
* 媒体流的捕获 Media Stream Capture
* 对等连接 Peer connection
* 本地和远程媒体流 Local and Remote Stream
* 数据通道 Data Channel
* 中转服务器 Turn Server

多媒体通信相关的技术
------------------------------
* 音频: 回声消除 Echo Cancellation, 静音检测 Silence Detection, 噪声消除 Noise Removal, G.711 及 Opus 等编码，防抖动缓冲等
* 视频: H264, VP8 等视频编码的支持， 防抖动缓冲
* 传输: 基于 RTP, RTCP， SRTP 和 DTLS 的实时传输和多路利用
* 信令: 基于 SDP 和 SIP, Jingle, ROAP, RESTful 等协议的多媒体媒体通信参数协商
* 网络 - 通过 ICE, TURN, STUN 的 NAT 穿透与连接


三大任务
------------------------------
* 获取音视频流 audio and video
* 音视频媒体流的通信
* 任意数据的通信


三个主要的 JS APIs
------------------------------
* 媒体流 MediaStream
* 对等连接 RTCPeerConnection
* 数据通道 RTCDataChannel 


WebRTC 应用模型
===============================



Browser Model 浏览器模型
---------------------------------------

.. code-block::


                     +------------------------+  On-the-wire
                     |                        |  Protocols
                     |      Servers           |--------->
                     |                        |
                     |                        |
                     +------------------------+
                                 ^
                                 |
                                 |
                                 | HTTPS/
                                 | WebSockets
                                 |
                                 |
                   +----------------------------+
                   |    JavaScript/HTML/CSS     |
                   +----------------------------+
                Other  ^                 ^ RTC
                APIs   |                 | APIs
                   +---|-----------------|------+
                   |   |                 |      |
                   |                 +---------+|
                   |                 | Browser ||  On-the-wire
                   | Browser         | RTC     ||  Protocols
                   |                 | Function|----------->
                   |                 |         ||
                   |                 |         ||
                   |                 +---------+|
                   +---------------------|------+
                                         |
                                         V
                                    Native OS Services


Browser RTC Trapezoid 浏览器实时通信三角
------------------------------------------------------

.. code-block::

           +-----------+                  +-----------+
           |   Web     |                  |   Web     |
           |           |                  |           |
           |           |------------------|           |
           |  Server   |  Signaling Path  |  Server   |
           |           |                  |           |
           +-----------+                  +-----------+
                /                                \
               /                                  \ Application-defined
              /                                    \ over
             /                                      \ HTTPS/WebSockets
            /  Application-defined over              \
           /   HTTPS/WebSockets                       \
          /                                            \
    +-----------+                                +-----------+
    |JS/HTML/CSS|                                |JS/HTML/CSS|
    +-----------+                                +-----------+
    +-----------+                                +-----------+
    |           |                                |           |
    |           |                                |           |
    |  Browser  |--------------------------------|  Browser  |
    |           |          Media Path            |           |
    |           |                                |           |
    +-----------+                                +-----------+

WebRTC 应用的核心功能
===================================
* 用户管理 User management
* 会话管理 Session management
* 信令管理 Signal management
* 连接管理 Connection management
* 设备管理 Device management
* 媒体流管理 Media Stream/Track management
* 媒体统计和度量 Media statistics and metrics


Data transport
----------------------
例如，TCP 和 UDP，以及在实体之间安全地建立连接的手段，以及决定何时发送数据的功能：拥塞管理、带宽估计等。


相关协议:

* RFC8835: Transports for WebRTC

Data framing
----------------------

RTP、流控制传输协议 (SCTP)、DTLS 和其他用作容器的数据格式，以及它们用于数据机密性和完整性的功能。

Data formats
----------------------

系统之间传递的数据的编解码器规范、格式规范和功能规范。 音频和视频编解码器以及用于数据和文档共享的格式都属于这一类。
为了使用数据格式，需要一种描述它们的方法（例如，会话描述 SDP ）。

Connection management
------------------------------

例如，建立连接、就数据格式达成一致、在通话期间更改数据格式。 SDP、SIP 和Jingle/XMPP 属于这一类。

Presentation and control
-----------------------------

为了确保交互以一种意料之中的方式进行，所需要的功能包括 floor control, screen layout, voice-activated image
switching 和其他此类功能，其中部分系统需要各方之间的合作。 集中式会议 Centralized Conferencing (XCON) [RFC6501] 和 Cisco/Tandberg 的 Telepresence
Interoperability Protocol (TIP) 是规范此类功能的一些尝试。

许多应用程序是在没有针对这些功能的标准化接口的情况下构建的。

Local system support functions
--------------------------------------------

一些不需要统一指定的功能，因为每个参与者都可以根据自己的选择实现这些功能，而不会以其他人必须认识到的方式影响线上传输的数据。 例如回声消除（以它的某些形式）、本地身份验证和授权机制、操作系统访问控制以及对对话进行本地记录的能力。


参考资料
===============================
* `RFC8825`_: Overview: Real-Time Protocols for Browser-Based Applications

* `WebRTC 实时通信`_

* https://www.html5rocks.com/en/tutorials/webrtc/basics/
* https://www.html5rocks.com/en/tutorials/webrtc/infrastructure/
* https://codelabs.developers.google.com/codelabs/webrtc-web

.. _WebRTC 实时通信: * https://a-wing.github.io/webrtc-book-cn


