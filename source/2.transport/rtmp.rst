########################
RTMP 协议
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** RTMP protocol
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:


RTMP Overview
==========================================
RTMP (Real Time Messaging Protocol) 实时消息传输协议，是 Adobe 公司的专有协议，用于 Flash 的媒体传输。
它并非是一个单独的协议，而是一组协议簇

* RTMP: 通过 TCP 传输，默认商品是 1935
* RTMPS： 通过 TLS 传输的 RTMP
* RTMPE: Adobe 私有的 RTMP 安全加密协议
* RTMPT： 使用 HTTP 封装的 RTMP, RTMPS 或 RTMPE， 用来穿越防火墙
* RTMPFP：使用 UDP 的 RTMP, 允许用户进行 P2P 连接


RTMP 连接三部走
===========================================
1. 握手 Handshake: 
------------------------------------------
客户端通常采用编码软件或硬件的形式，通过交换三个数据包来启动与它希望流式传输到的服务器的连接。

* 1) c0/s0：一个字节，说明是明文还是加密。

客户端发送的第一个数据包告诉服务器正在流式传输哪个版本的 RTMP。

* 2) c1/s1: 1536字节，4字节时间，4字节0x00，1528字节随机数

客户端在不等待任何响应的情况下立即发送的第二个数据包包括时间戳。此时，服务器会使用刚刚收到的两个数据包的回显或副本以及接收它们的时间戳进行响应。

* 3) c2/s2: 1536字节，4字节时间1，4字节时间2，1528随机数和s1相同。

建立双向通信后，客户端发送最后一个数据包，该数据包是时间戳的副本。然后服务器返回它。当服务器返回最后一个（第三个）数据包时，握手完成。
 

参见 https://ossrs.io/lts/en-us/docs/v5/doc/rtmp-handshake

2. 连接 Connection:
------------------------------------------
然后，客户端和服务器使用操作消息格式 （AMF） 编码的消息协商连接。RTMP 编码器使用 AMF 将连接请求发送到服务器，并指示连接 URL、音频编解码器和视频编解码器等详细信息。一旦服务器响应批准，流就可以开始了。

3. 流淌 Stream: 
------------------------------------------
完成握手和连接步骤后，现在可以传送流数据。用户命令（如创建流、播放、搜索和暂停）允许数据传输按指示进行


RTMP 包结构
==========================================
RTMP 消息由 Chunk 组成， 每个 Chunk 可以携带一个 Message, 多数情况下 RTMP message 由多个 Chunk 承载

RTMP Chunk 由包头 header 和 payload 组成。 对于连接和控制命令，采用 AMF 格式编码(AMF0 或 AMF3, 一般用 AMF0).
包头包括 Basic Header 和 Chunk Header, 其中 Basic Header 可被扩展为一到两个字节， Chunk Header 则含有如 Message 长度等信息

Reference
==========================================
* https://www.wowza.com/blog/rtmp-streaming-real-time-messaging-protocol
* https://cloud.tencent.com/developer/inventory/1220
* https://blog.csdn.net/adkada1/article/details/120583331
* X.509 Internet Public Key Infrastructure Online Certificate Status Protocol - OCSP