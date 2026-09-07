################
Verto
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

Verto 是 FreeSWITCH 给 WebRTC 网页用的信令：JSON-RPC 2.0 over WebSocket（mod_verto）。

Abstract
------------

它不替代 SIP Trunk：浏览器讲 Verto，FS 另一条腿仍讲 SIP。
SDP 仍是 JSEP 那份；方法收成 login/invite/answer/bye/modify。
配置与示例代码见 :doc:`../7.practice/freeswitch_webrtc`\ 。


Why
============

* 网页要处理完整 SIP（Via、CSeq、REGISTER 过期）成本高。
* 和 SIP-WS 选错：需要标准 REFER 却上了 Verto，或纯 Web 应用却背了整部 SIP。
* login 不是 SIP REGISTER，目录不同步会导致“网页能登、sofia 找不到用户”。


How
============

为什么不直接用 SIP
--------------------

Verto 把呼叫收成 RPC，SDP 仍是 JSEP：

主要方法（概念上对 SIP）：

.. list-table::
   :header-rows: 1
   :widths: 28 36 36

   * - Verto
     - 作用
     - 近似 SIP
   * - login
     - 鉴权、绑定 sessid
     - REGISTER（**不是**\ 同一条目录）
   * - invite / answer
     - 发 / 答 SDP
     - INVITE / 200
   * - bye
     - 挂断
     - BYE
   * - modify
     - hold、DTMF、视频降级等
     - re-INVITE / INFO / UPDATE
   * - attach / ping
     - 重连、保活
     - 无直接对应
   * - event / display
     - 服务端推送
     - NOTIFY

在架构里的位置
--------------------

.. mermaid::

   flowchart TB
     Br["浏览器 (verto.js)"] -->|"WSS + JSON-RPC"| MV[FreeSWITCH mod_verto]
     MV -->|内部 session| Apps["mod_sofia / conference / callcenter"]
     Apps -->|SIP| Pstn["SIP Phone / SIP Trunk / PSTN"]

同一通呼叫：Web 侧是 Verto dialog，PSTN 侧是 SIP dialog，FS 做 B2BUA。
ACD、录音、IVR 仍走应用层，与用哪种浏览器信令无关。

何时选 Verto，何时选 SIP-WS
----------------------------

两条都能进 FS。**要标准 SIP 方法就 SIP-WS；只要网页通话就 Verto。**

.. list-table::
   :header-rows: 1
   :widths: 28 36 36

   * -
     - Verto
     - SIP over WebSocket
   * - 报文
     - JSON-RPC
     - 标准 SIP
   * - 转接 / BLF
     - ESL / 应用层
     - REFER、Dialog Event
   * - 客户端
     - verto.js
     - SIP.js / JsSIP
   * - 适合
     - 纯 Web、点击外呼、避开 SIP 细节
     - 浏览器当 SIP 话机
   * - 本章对照
     - 本文
     - :doc:`sip_websocket`

对端是 Jitsi / XMPP 客户端 → :doc:`jingle`\ （FS 主树已不再把 dingaling 当主路径）。

实践注意
--------------------

1. Verto login 不是 SIP REGISTER，目录可能要在 sofia 另有一份，或统一 XML curl。
2. 服务端可主动 ``verto.invite`` 打给浏览器（点击外呼），这是 3PCC 在 Web 侧的形态。
3. SDP 必须是 WebRTC 那套（ICE、fingerprint、SAVPF），用 :doc:`jsep` 的 ``createOffer`` 原文。
4. 集群需要 WSS 粘滞到同一 FS 节点。
5. 不要把 Verto 端口配成 SIP ``ws-binding`` 的 URL；子协议不同，握手会失败。


Example
============

浏览器连上 ``wss://fs.example.com:8082`` 后，先 login，再 invite。
``sdp`` 不要留占位符：用 :doc:`jsep` 例子里 ``pc.localDescription.sdp``\ （对接 SIP 腿时建议等 ``iceGatheringState === complete``\ ）。

Login（一条 JSON-RPC 消息）：

.. code-block:: json

    {
      "jsonrpc": "2.0",
      "id": 1,
      "method": "login",
      "params": {
        "login": "1000@fs.example.com",
        "passwd": "your-password",
        "sessid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
      }
    }

Invite（另一条消息；``sdp`` 换成真实 Offer）：

.. code-block:: json

    {
      "jsonrpc": "2.0",
      "id": 2,
      "method": "verto.invite",
      "params": {
        "sessid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "sdp": "v=0\r\no=- ...createOffer 全文...",
        "dialogParams": {
          "callID": "11111111-2222-3333-4444-555555555555",
          "destination_number": "1001",
          "caller_id_name": "WebRTC User",
          "caller_id_number": "1000"
        }
      }
    }

验证（Web 腿是 Verto，SIP 腿才是 INVITE）：

.. code-block:: bash

    fs_cli -x "module_exists mod_verto"
    fs_cli -x "verto status"
    fs_cli -x "sofia global siptrace on"
    # login 成功后 verto status / show channels 应出现该 sessid
    # invite 1001 时，sofia siptrace 另有一条 SIP INVITE（Call-ID 与 Verto callID 不同）

完整 HTML/verto.js 示例见 :doc:`../7.practice/freeswitch_webrtc`\ 。


Conclusion
============

* Verto 缩短网页信令，不取代 SIP Trunk。
* invite 的 sdp 必须是浏览器 createOffer 的原文。
* 需要标准 SIP 话机功能时改走 SIP-WS。


Reference
============

* `RFC8829`_
* :doc:`../7.practice/freeswitch_webrtc`
* `mod_verto 文档 <https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Modules/mod_verto_3964934/>`_
* `Verto 协议说明 <https://evoluxbr.github.io/verto-docs/>`_
