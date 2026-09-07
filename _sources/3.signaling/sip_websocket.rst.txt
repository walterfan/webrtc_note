########################
SIP over WebSocket
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

`RFC7118`_ 把完整 SIP 报文放进 WebSocket 帧，让浏览器讲标准 SIP。

Abstract
------------

浏览器不能开 UDP 5060。子协议是 ``sip``\ ；Via/Contact 使用 ``transport=ws`` 或 ``wss``\ 。
媒体仍是 ICE + DTLS-SRTP，不走 WebSocket。
FreeSWITCH 用 mod_sofia 的 ``ws-binding`` / ``wss-binding``\ ；客户端常见 SIP.js、JsSIP。


Why
============

* 要把已有 SIP 话机逻辑（REGISTER、REFER、BLF）带进浏览器，不能只用自定义 JSON。
* 只加密 WSS 却用明文 RTP，不符合 WebRTC。
* 负载均衡不粘滞 WebSocket，REGISTER 在 A 节点、INVITE 打到 B 会 404。
* 和 Verto 选错：纯 Web 应用却背了整部 SIP，或需要标准 REFER 却上了 JSON-RPC。


How
============

协议要点
--------------------

* URL 形如 ``wss://fs.example.com:7443``
* ``Sec-WebSocket-Protocol: sip``
* 每个 WS 消息是一条完整 SIP 请求或响应（CRLF 分隔行，与 UDP/TCP SIP 相同）
* 媒体仍是 ICE + DTLS-SRTP，**不**\ 走这条 WebSocket

.. code-block:: text

    浏览器 (SIP.js)                 FreeSWITCH (mod_sofia)
         |  WS Upgrade, protocol=sip        |
         |  REGISTER (SIP over WS)          |
         |  INVITE + SDP (JSEP offer)       |
         |  ACK                             |
         |  ======= DTLS-SRTP / RTP ======  |

何时选 SIP-WS，何时选 Verto
----------------------------

两条都能把浏览器接到 FreeSWITCH。按**要不要标准 SIP 方法**\ 选，不要按“哪个更新”选。

.. list-table::
   :header-rows: 1
   :widths: 28 36 36

   * -
     - SIP over WebSocket
     - Verto
   * - 报文
     - 标准 SIP（INVITE/REGISTER/REFER）
     - JSON-RPC（``verto.invite`` 等）
   * - 客户端
     - SIP.js / JsSIP / 硬话机逻辑复用
     - verto.js
   * - 转接 / BLF
     - 可走 REFER、Dialog Event
     - 应用层或 FS 命令，不是 RFC 3515 原文
   * - 与 SIP Trunk
     - 同一套 header / dialog 语义
     - 内部再翻译成 SIP
   * - 适合
     - 已有 SIP 知识、要复用话机功能
     - 纯 Web 应用、想避开 Via/CSeq
   * - 不适合
     - 团队不想在 JS 里处理 SIP 事务
     - 必须让浏览器直接发 REFER/SUBSCRIBE

**选 SIP-WS**\ ：浏览器要当 SIP 话机（REGISTER、REFER、BLF、Expires）。
**选 Verto**\ ：网页只想 login / invite / bye，PBX 功能全放在 FS。细节对照 :doc:`verto`\ 。

FreeSWITCH
--------------------

.. code-block:: xml

    <param name="ws-binding" value=":5066"/>
    <param name="wss-binding" value=":7443"/>

证书、ICE、SRTP 见 :doc:`../7.practice/freeswitch_sip`\ 、:doc:`../7.practice/freeswitch_webrtc`\ 。
REGISTER 的 Contact 必须是 WS 可达地址；NAT 后靠 WSS 长连接保活。

实践注意
--------------------

1. 媒体必须 DTLS-SRTP，SDP 里是 ``UDP/TLS/RTP/SAVPF``\ （JSEP 那份，见 :doc:`jsep`\ ）。
2. 负载均衡要 WebSocket 粘滞到同一 sofia 节点。
3. 调试看 WS 帧 + 文本 INVITE，sngrep 默认解的是 5060，不一定能解 WS。
4. 不要和 Verto 端口混用同一 URL；子协议分别是 ``sip`` 与 Verto 自己的。


Example
============

sofia profile 加上面两条 binding 并加载证书后：

.. code-block:: bash

    fs_cli -x "sofia status profile internal"
    # 输出里应出现 ws-binding :5066 和/或 wss-binding :7443
    # 浏览器或命令行（子协议必须是 sip）：
    # wscat -s sip -c wss://127.0.0.1:7443

连上后发送**一整条** SIP OPTIONS（行末 CRLF，最后空行；Contact/Via 的 transport=wss）：

.. code-block:: text

    OPTIONS sip:127.0.0.1 SIP/2.0
    Via: SIP/2.0/WSS df7jal23ls0d.invalid;branch=z9hG4bK1
    From: <sip:1001@127.0.0.1>;tag=a
    To: <sip:127.0.0.1>
    Call-ID: opt-1@web
    CSeq: 1 OPTIONS
    Max-Forwards: 70
    Content-Length: 0

应收到 ``SIP/2.0 200 OK``\ （或 401，视 profile 而定）。这证明：**运输是 WebSocket，语义仍是 SIP**\ 。
完整呼叫用 SIP.js 的 ``UserAgent`` 注册 1001 再 INVITE；sdp 必须是 :doc:`jsep` 里 ``pc.localDescription.sdp``\ ，不要手写 ``m=audio`` 而不含 ICE/fingerprint。
Wireshark：过滤 ``websocket``\ ，跟进包含 ``OPTIONS`` / ``INVITE`` 的文本帧；不要过滤 ``sip.port == 5060``\ 。


Conclusion
============

* SIP-WS 只换运输，SIP 语义不变。
* 要标准 REFER/BLF 进浏览器就走这条，不要 Verto。
* WSS 粘滞和 DTLS-SRTP 缺一不可。


Reference
============

* `RFC7118`_
* `RFC6455`_
* `RFC8829`_
* :doc:`verto`
* :doc:`jsep`
