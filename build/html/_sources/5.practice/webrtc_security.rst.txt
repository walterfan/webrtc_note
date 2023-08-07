###################
WebRTC Security
###################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Security
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


Overview
===============================
WebRTC 的安全需要满足三个基本需求
* Authentication 用户访问需要认证
* Authorization 用户访问需要授权
* Audit 用户的访问应该可被追踪和审查


其中前两项也可以归结为 CIA

1. Confidentiality 机密性：信息需要保密， 访问权限也需要控制
2. Integrity 完整性：信息需要保持完整，在存储和传输过程不被未授权，未预期或无意地篡改或销毁，或者可以快速检测到被篡改
3. Availablity 可用性： 信息可被合法用户访问并向其提供所需的功能和特性，例如拒绝服务攻击就是对可用性的破坏


WebRTC 的安全在 "RFC8826 Security Considerations for WebRTC" 有较为详细的阐述。


以一个简单的 WebRTC 应用为例, 我们需要考虑浏览器在客户端的安全及隐私，通信和传输的安全

.. code-block::

                          +----------------+
                          |                |
                          |   Web Server   |
                          |                |
                          +----------------+
                              ^        ^
                             /          \
                    HTTPS   /            \   HTTPS
                      or   /              \   or
               WebSockets /                \ WebSockets
                         v                  v
                      JS API              JS API
                +-----------+            +-----------+
                |           |    Media   |           |
                |  Browser  |<---------->|  Browser  |
                |           |            |           |
                +-----------+            +-----------+
                    Alice                     Bob


遵循浏览器的安全模型
==========================

由于 WebRTC 基于浏览器来进行实时通信，浏览器作为客户端需要保证用户数据的安全，所以 WebRTC 在客户端依赖于浏览器的安全模型。
而现在流行的几大浏览器都遵循着浏览器的安全规范，例如沙箱模型(sandbox)，同源策略SOP(Same Origin Policy)，等等

沙箱机制将脚本彼此隔离，并与用户的计算机隔离。 一般来说，脚本只允许与来自同一域的资源交互 - 或者更具体地说，与相同“来源 Origin”的资源交互。
一个 Origin 由 URI scheme, hostname, 和 port number 所组成。

SOP 的限制保证了基本的安全，对于网络应用来说，如果双方都同意，跨越一个源的通信也是可以接受的。
跨源资源共享 Cross-Origin Resource Sharing (CORS) 就是允许浏览器使用已同意的目标服务器的脚本。

实际应用中，WebRTC 应用会通过 HTTPS(https://host), Secure WebSocket(wss://host) 与其他服务器进行通讯，

例如 Web 客户端发送一个请求到一个与自身域名不同的服务器 (host domain: bar.other)
其自身来自源 foo.example, 这个请求中包含 HTTP 头域 "Origin: http://foo.example"

.. code-block::

    GET /resources/public-data/ HTTP/1.1
    Host: bar.other
    User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1b3pre) Gecko/20081130 Minefield/3.1b3pre
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: en-us,en;q=0.5
    Accept-Encoding: gzip,deflate
    Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
    Connection: keep-alive
    Referer: http://foo.example/examples/access-control/simpleXSInvocation.html
    Origin: http://foo.example

    [Request Body]

然后 bar.other 这台服务器会检查 HTTP 请求头字段 Orgin 与自己的配置信息，发送回如下响应

.. code-block::

    HTTP/1.1 200 OK
    Date: Mon, 01 Dec 2008 00:23:53 GMT
    Server: Apache/2.0.61
    Keep-Alive: timeout=2, max=100
    Connection: Keep-Alive
    Transfer-Encoding: chunked
    Content-Type: application/xml
    Access-Control-Allow-Origin: *

    [Response Body]

Web 服务器发送回 HTTP 响应头字段 Access-Control-Allow-Origin 通知 Web 客户端允许的域。
该响应头字段可以包含 "*" 以指示允许所有域，也可以包含指定域以指示指定的允许域。


对本地媒体资源的授权访问
---------------------------
WebRTC 客户端的麦克风，摄像头以及桌面屏幕都是涉及用户的隐私的高度机密的资源，需要获取用户的充分授权，并在捕获本地音频和视频流时显示明示的标识，例如“红点”，让用户知晓。

WebRTC 应用的安全
==========================

通信一致性的验证
---------------------------


通信的安全
---------------------------
* SRTP [RFC3711],
* DTLS [RFC6347], and
* DTLS-SRTP [RFC5763]

SDP
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

    a=setup: <role>

每个  ‘m=’ line 中都会有这样一个属性，前提是其需要用 DTLS-SRTP 加密
其中的  <role> 是下面的属性:

* active: Offerer 将充当 DLTS 连接的客户端。
* passive: Offerer 将充当 DTLS 连接的服务器。
* actpass: Offerer 可以充当 DTLS 连接的客户端或发送者。
* holdconn: 不建立DTLS连接。

隐私考虑
---------------------------

参考资料
==========================
* `Webrtc security <https://telecom.altanai.com/2015/04/24/webrtc-security/>`_
* `RFC8826 Security Considerations for WebRTC <https://datatracker.ietf.org/doc/html/rfc8826>`_
* `RFC3552 Guidelines for Writing RFC Text on Security Considerations <https://datatracker.ietf.org/doc/html/rfc3552>`_
* `RFC6973 Privacy Considerations for Internet Protocols <https://datatracker.ietf.org/doc/html/rfc6973>`_
* `RFC7675 Session Traversal Utilities for NAT (STUN) Usage for Consent Freshness <https://datatracker.ietf.org/doc/html/rfc7675>`_