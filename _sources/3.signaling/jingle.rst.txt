################
Jingle 与 XMPP
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

Jingle（XEP-0166）在 XMPP IQ 上做会话协商，媒体仍走 RTP / ICE / DTLS：XML 信封里的 SIP+SDP。

Abstract
------------

XMPP（`RFC6120`_\ ）先解决 IM 和 Presence：Message、Presence、IQ，地址是 JID。
Jitsi、Conversations、早期 Google Talk 走 Jingle；WebRTC 出现后内容对上了 ICE 和 DTLS-SRTP。
用 JSON 替换 XML（JMPP）只换信封，不换呼叫模型。


Why
============

* 对端已是 XMPP 客户端时，只开 SIP/Verto 接不上。
* 把 Presence 当成 Agent Available，路由会错（同 :doc:`sip_events`\ ）。
* XML 冗长不等于“没有会话模型”；丢掉 Jingle 语义去重造 JSON 会失去 ICE/DTLS 对齐。


How
============

XMPP 只提供信封
--------------------

三种 stanza，Jingle **只住在 IQ** 里：

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - 类型
     - 作用
   * - message
     - 聊天、群聊（MUC）
   * - presence
     - 在线、忙碌、离开
   * - iq
     - 请求-响应；``<jingle action="session-initiate">`` 相当于 INVITE

连接一般是 TCP + TLS + SASL。浏览器侧用 XMPP over WebSocket（`RFC7395`_\ ）或 BOSH。

IQ 信封 vs SIP INVITE
----------------------

同一层信息，拆法不同。抓包时先找到 IQ，再读里面的 ``<jingle>``\ ：

.. mermaid::

   flowchart LR
     subgraph sipSide[SIP]
       S1["INVITE sip:bob"]
       S2["From / To / Call-ID / CSeq"]
       S3["Content-Type: application/sdp"]
       S4["v=0 / m=audio / a=rtpmap"]
       S5["a=ice-ufrag / a=candidate"]
       S6["a=fingerprint"]
     end
     subgraph jingleSide[Jingle]
       J1["iq type=set to bob"]
       J2["sid ≈ Call-ID"]
       J3["jingle action=session-initiate"]
       J4["description payload-type"]
       J5["transport ICE-UDP"]
       J6["fingerprint DTLS"]
     end
     S1 --- J1
     S2 --- J2
     S3 --- J3
     S4 --- J4
     S5 --- J5
     S6 --- J6

``action`` 常用：``session-initiate`` / ``session-accept`` / ``session-terminate``\ ；``transport-info`` 是 Trickle ICE；``content-add`` / ``content-remove`` 加减媒体。

.. list-table::
   :header-rows: 1
   :widths: 22 78

   * - XEP
     - 内容
   * - 0166
     - Jingle 核心
   * - 0167
     - RTP 会话（相当于 SDP m= 行）
   * - 0176
     - ICE-UDP
   * - 0320
     - DTLS-SRTP
   * - 0353
     - Jingle Message Initiation（用 message 振铃）

和 SIP / JSEP 对照
--------------------

.. list-table::
   :header-rows: 1
   :widths: 22 26 26 26

   * -
     - SIP
     - Jingle
     - JSEP
   * - 信封
     - SIP 文本
     - XMPP IQ
     - 无（应用自选）
   * - 会话描述
     - SDP
     - Jingle content/description
     - SDP
   * - 传输协商
     - 可选 ICE
     - ICE-UDP XEP
     - 强制 ICE
   * - 典型实现
     - FS sofia、话机
     - Jitsi、Conversations
     - 所有浏览器

网关要做 **Jingle 描述 ↔ SDP** 互译。

FreeSWITCH 与呼叫中心
----------------------

历史上有 ``mod_dingaling`` 对接 Google Talk / Jingle，现已不是主路径。
今天更常见：浏览器 ↔ FS 用 Verto 或 SIP-WS；Jitsi 内部用 Jingle / Colibri，与 FS 并列。
呼叫中心不必把 Jingle 当 ACD 信令。

JMPP：只换信封
--------------------

XML stanza 冗长是 XMPP 在移动 IM 上被专有协议取代的原因之一。
JMPP 用 JSON 表达 **同一套** Message / Presence / IQ，可减带宽。呼叫模型仍是 Jingle：谁发起、怎么协商媒体、ICE 怎么 Trickle。

.. code-block:: text

    XMPP:  <iq type="set"> <jingle action="session-initiate" .../> </iq>
    JMPP:  { "iq": { "type": "set", "jingle": { "action": "session-initiate", ... } } }

    变了：XML → JSON
    没变：IQ 请求-响应、Jingle action、ICE/DTLS 字段含义
    不会因此多出：REFER、History-Info、SIPREC

Web 侧若已有 WebSocket，多数项目会直接上自定义 JSON 或 Verto，而不是再实现一套 JMPP Jingle。
笔记：`JMPP 让 XMPP 协议老树开新花 <https://www.jianshu.com/p/915428d8c75b>`_\ 。

实践注意
--------------------

1. Jingle 没有 SIP 那么完整的 REFER / History-Info / SIPREC 生态。
2. MUC（XEP-0045）是聊天室，不是 SIP 会议焦点。
3. 抓包看 5222（c2s）或 443 上的 XMPP-WS；Jingle 藏在 IQ 里，过滤 ``jingle`` 或 ``session-initiate``\ 。
4. 与 WebRTC 互通必须对齐 ICE 和 DTLS fingerprint。


Example
============

``session-initiate`` 可与 SIP INVITE+SDP 对照验证（把 fingerprint/ufrag 换成 :doc:`jsep` 里的真实值）。注意最外层是 **IQ**\ ，不是 ``<message>``\ ：

.. code-block:: xml

    <iq type="set" from="alice@example.com/phone" to="bob@example.com/phone" id="1">
      <jingle xmlns="urn:xmpp:jingle:1" action="session-initiate" sid="abcd">
        <content creator="initiator" name="audio">
          <description xmlns="urn:xmpp:jingle:apps:rtp:1" media="audio">
            <payload-type id="111" name="opus" clockrate="48000"/>
          </description>
          <transport xmlns="urn:xmpp:jingle:transports:ice-udp:1" ufrag="4ZcD" pwd="7P3n3jR5aK">
            <fingerprint xmlns="urn:xmpp:jingle:apps:dtls:0" hash="sha-256">
              7F:05:B2:C9:4F:0E:53:0A:B1:A4:7D:6B:0C:1E:88:2F:AA:3C:91:D4:6E:70:12:8B:5A:33:C0:9F:E1:4D:27:18
            </fingerprint>
          </transport>
        </content>
      </jingle>
    </iq>

验证：用 Conversations 或 Gajim 打给支持 Jingle 的对端，Wireshark 过滤 ``xmpp`` 或 WebSocket 文本里的 ``session-initiate``\ ；对端 ``session-accept`` 后应有 ICE 连通。
若只看到 ``<presence>`` 或 ``<message>`` 而没有 ``<iq>...<jingle>``\ ，那是聊天/在线状态，不是呼叫信令。
JMPP 聊天室示例（非 Jingle 呼叫）见上述简书文的 FastAPI 代码，可单独跑通 presence/message —— 那只能证明信封换成了 JSON，不能证明转接/录音标准变了。
FS 侧 ``module_exists mod_dingaling`` 若为 false，不要假设主树仍支持 Jingle 终结。


Conclusion
============

* Jingle = XMPP IQ 信封 + 与 SDP 同构的媒体描述。
* 呼叫中心主路径仍是 SIP/Verto；Jingle 做边缘网关。
* 换 JSON 信封（JMPP）不产生新的转接/录音标准。


Reference
============

* `RFC6120`_
* `XEP-0166 Jingle <https://xmpp.org/extensions/xep-0166.html>`_
* `XEP-0167 Jingle RTP Sessions <https://xmpp.org/extensions/xep-0167.html>`_
* `XEP-0176 Jingle ICE-UDP <https://xmpp.org/extensions/xep-0176.html>`_
* `XEP-0320 Jingle DTLS <https://xmpp.org/extensions/xep-0320.html>`_
* `RFC7395`_
* `JMPP 让 XMPP 协议老树开新花 <https://www.jianshu.com/p/915428d8c75b>`_
* :doc:`jsep`
* :doc:`sip_core`
