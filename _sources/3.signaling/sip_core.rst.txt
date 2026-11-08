################
SIP Core
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

SIP（`RFC3261`_\ ）是面向会话的文本信令：协商谁和谁通话、用什么媒体、走哪条路径，不传 RTP。

Abstract
------------

风格接近 HTTP（方法 + 状态码 + header），但对象是 session 而不是网页。
后面几乎所有呼叫中心扩展都建立在它的方法、事务、对话、会话模型上。
`RFC5411`_ 是读后续 RFC 的地图，不是替代 3261。


Why
============

* 分不清 transaction / dialog / session，排障会把“事务超时”当成“通话死了”，或把 REGISTER 当成 Agent 登录。
* 不掌握 INVITE 三方握手和核心 header，抓包时无法定位卡在 180、488 还是 ACK 丢失。
* FreeSWITCH 是 B2BUA：当成透明 Proxy 去对 Call-ID / Replaces，转接和录音会全部对不上。


How
============

三个必须分清的概念
--------------------

.. code-block:: text

    Transaction  →  一次请求 + 其响应（短生命周期）
    Dialog      →  两个 UA 之间的对等关系（由 Call-ID + tags 标识）
    Session     →  媒体会话（由 SDP 描述，RTP 承载）

* **Transaction**\ ：例如一次 INVITE 及其 100/180/200，或一次 BYE 及其 200。有客户端事务和服务器事务，用 Via branch + CSeq 关联。
* **Dialog**\ ：一次成功的 INVITE 会创建 dialog。后续的 BYE、re-INVITE、UPDATE、REFER 都在这个 dialog 里发。Dialog ID = Call-ID + From-tag + To-tag。这三个里错一个，对端通常回 **481 Call/Transaction Does Not Exist**\ 。
* **Session**\ ：dialog 上协商出来的媒体，地址在 SDP 的 ``c=`` / ``m=`` 里，RTP 走那里，不走 SIP。可以有 dialog 没有 session（例如 SUBSCRIBE），也可以用 re-INVITE / UPDATE 改 session 而不拆 dialog。

呼叫中心里常见的坑：以为“dialog 结束了 = 通话结束了”，或以为“Agent 没有 SIP dialog = Agent 空闲”。后者见 :doc:`sip_events`\ 。

Dialog 三元组与 481
--------------------

200 OK 之后，这三行就是 dialog ID。后续 in-dialog 请求必须原样带上：

.. code-block:: text

    Call-ID: 1h23@192.168.1.20
    From:    ...;tag=111     ← 主叫 tag，INVITE 里就有
    To:      ...;tag=222     ← 被叫 tag，200 OK 才出现

抓包口诀：三个都对上 → 同一 dialog；**错一个 → 481**\ 。

To-tag 在 180 里可能已经出现（早期 dialog），但最终要以 200 OK 的 To-tag 为准。
把 180 的临时 tag、或 B2BUA 另一条腿的 tag 贴到 BYE 上，是 481 的典型来源：

.. mermaid::

   flowchart LR
     subgraph ok["正确 BYE（会 200）"]
       B1["From: ...;tag=111<br/>To: ...;tag=222<br/>Call-ID: 1h23@192.168.1.20"]
       R1[200 OK]
       B1 --> R1
     end
     subgraph bad["错误 BYE（会 481）"]
       B2["From: ...;tag=111<br/>To: ...;tag=WRONG<br/>Call-ID: 1h23@192.168.1.20"]
       R2["481 Call/Transaction Does Not Exist"]
       B2 --> R2
     end

sngrep 点开梯子：先对齐 200 OK 的三元组，再看这条 BYE / re-INVITE 少了谁。

核心方法
--------------------

.. list-table:: SIP 核心方法
   :header-rows: 1
   :widths: 18 42 40

   * - 方法
     - 作用
     - 呼叫中心场景
   * - REGISTER
     - UA 向 registrar 登记 Contact
     - 话机 / 软电话上线
   * - INVITE
     - 发起会话
     - 呼入、呼出、咨询呼叫
   * - ACK
     - 确认 INVITE 的最终响应
     - 三方握手的最后一步
   * - BYE
     - 结束 dialog / session
     - 挂机
   * - CANCEL
     - 取消尚未完成的 INVITE
     - 主叫放弃、排队超时取消振铃
   * - OPTIONS
     - 查询能力，也可作保活
     - 探测对端是否支持 REFER / 定时器
   * - UPDATE
     - 在 dialog 中更新会话参数
     - 早期媒体、Session Timer 刷新
   * - PRACK
     - 可靠临时响应（`RFC3262`_\ ）
     - 早期媒体、100rel
   * - SUBSCRIBE / NOTIFY
     - 事件订阅
     - Dialog Event、BLF、会议状态
   * - INFO
     - 在 dialog 中传应用信息
     - 带内 DTMF（遗留，优先用 RFC 4733）
   * - REFER
     - 请对端发起新请求
     - 转接，见 :doc:`sip_refer`
   * - MESSAGE
     - 页模式即时消息
     - 坐席聊天（较少用于呼叫控制）

核心 Header
--------------------

.. list-table:: SIP 核心 Header
   :header-rows: 1
   :widths: 22 78

   * - Header
     - 作用
   * - Via
     - 响应回程路径；branch 标识事务
   * - From / To
     - 逻辑身份。To-tag 在 dialog 建立后才有
   * - Call-ID
     - 对话标识的一部分，全局唯一
   * - CSeq
     - 序号 + 方法名，用于匹配事务、检测重传
   * - Contact
     - 后续请求应发往的 URI
   * - Route / Record-Route
     - 强制后续请求经过代理；B2BUA / SBC 常见
   * - Max-Forwards
     - 防环，默认 70
   * - Allow
     - 本端支持的方法
   * - Supported / Require
     - 扩展协商。Require 失败会 420
   * - Authorization
     - Digest 认证
   * - Content-Type / Content-Length
     - 通常 ``application/sdp``

呼叫中心还会频繁遇到这些扩展 header，后面各章单独讲：

* ``Refer-To`` / ``Replaces`` / ``Referred-By``
* ``P-Asserted-Identity`` / ``History-Info`` / ``Reason``
* ``Session-Expires`` / ``Min-SE``

INVITE 流程
--------------------

.. mermaid::

   sequenceDiagram
     participant Caller as Caller
     participant FS as Proxy / FreeSWITCH
     participant Callee as Callee

     Caller->>FS: INVITE (SDP offer)
     FS->>Caller: 100 Trying
     FS->>Callee: INVITE (SDP offer)
     Callee->>FS: 100 Trying
     Callee->>FS: 180 Ringing
     FS->>Caller: 180 Ringing
     Callee->>FS: 200 OK (answer)
     FS->>Caller: 200 OK (answer)
     Caller->>FS: ACK
     FS->>Callee: ACK
     Caller<<->>Callee: RTP / SRTP
     Caller->>FS: BYE
     FS->>Callee: BYE
     Callee->>FS: 200 OK
     FS->>Caller: 200 OK

要点：

1. INVITE 携带 SDP offer，200 OK 携带 SDP answer。这是 `RFC3264`_ Offer/Answer。
2. ACK 对 2xx 是独立事务，对 3xx–6xx 则属于 INVITE 事务。
3. 180 Ringing 可以带 early media SDP（早期媒体：彩铃、排队音）。
4. FreeSWITCH 作为 B2BUA 时，Caller 侧和 Callee 侧是两个独立 dialog，不是透明 Proxy。

事务状态机（简化）
--------------------

INVITE 客户端事务：

.. mermaid::

   stateDiagram-v2
     [*] --> Calling
     Calling --> Proceeding: 1xx
     Calling --> Completed: 3xx-6xx
     Calling --> Terminated: timeout / CANCEL
     Proceeding --> Terminated: 2xx
     Proceeding --> Completed: 3xx-6xx
     Completed --> Terminated: ACK

非 INVITE 事务更简单：Trying → Completed → Terminated。

生产环境里，事务超时、retransmit、**481 Call/Transaction Does Not Exist**\ ，是排查“电话卡住”的第一层。481 首先核对：这条 BYE/re-INVITE 的 Call-ID、From-tag、To-tag 是否仍是 200 OK 里那一组。B2BUA 两侧各有一套，不能拿 Trunk 腿的 Call-ID 去对坐席腿。

REGISTER
--------------------

话机上线：Registrar 用 200 OK 确认绑定。Expires / Contact expires 决定注册周期。
呼叫中心里 Agent “登录”通常还有一层应用状态（Available / Break），不要把 SIP REGISTER 等同于 Agent Login。

响应码速查
--------------------

.. list-table:: 常用 SIP 响应
   :header-rows: 1
   :widths: 12 30 58

   * - 码
     - 含义
     - 典型原因
   * - 180
     - Ringing
     - 对端振铃
   * - 183
     - Session Progress
     - 早期媒体
   * - 200
     - OK
     - 成功
   * - 401 / 407
     - Unauthorized / Proxy Auth
     - 需要 Digest
   * - 404
     - Not Found
     - 号码不存在
   * - 408
     - Request Timeout
     - 对端无响应
   * - 480
     - Temporarily Unavailable
     - 暂时不可达
   * - 481
     - Call/Transaction Does Not Exist
     - Dialog 三元组（Call-ID + From-tag + To-tag）对不上，或事务已结束
   * - 486
     - Busy Here
     - 忙
   * - 487
     - Request Terminated
     - CANCEL 成功
   * - 488
     - Not Acceptable Here
     - SDP / codec 谈不拢
   * - 500 / 503
     - Server Error / Unavailable
     - 过载、无可用网关

这些码和 PSTN Q.850 cause 的映射见 :doc:`sip_reason`\ 。

B2BUA 与 Proxy
--------------------

* **Proxy**\ ：转发请求，通常共享同一个 dialog（Record-Route）。
* **B2BUA（Back-to-Back User Agent）**\ ：把一通呼叫拆成两个 dialog，两端各自 INVITE。FreeSWITCH 的 mod_sofia 就是 B2BUA。

呼叫中心几乎总是 B2BUA：因为要插 IVR、排队音、录音、转接、把 WebRTC 和 SIP Trunk 桥在一起。
代价是：两端的 Call-ID 不同，Replaces / History-Info 需要 B2BUA 正确改写。


Example
============

在 FreeSWITCH 上验证一通注册 + 呼叫（号码按你的 directory 改）：

.. code-block:: bash

    fs_cli -x "sofia global siptrace on"
    # 话机 REGISTER 到 internal profile 后，从 1001 拨 1002

抓包里应对得上下面这种 INVITE（字段值会变，结构不应变）：

.. code-block:: text

    INVITE sip:1002@192.168.1.10:5060 SIP/2.0
    Via: SIP/2.0/UDP 192.168.1.20:5060;branch=z9hG4bK-a1b2
    Max-Forwards: 70
    From: "Agent A" <sip:1001@192.168.1.10>;tag=111
    To: <sip:1002@192.168.1.10>
    Call-ID: 1h23@192.168.1.20
    CSeq: 1 INVITE
    Contact: <sip:1001@192.168.1.20:5060>
    Allow: INVITE, ACK, CANCEL, BYE, OPTIONS, UPDATE, REFER
    Content-Type: application/sdp
    Content-Length: 142

    v=0
    o=- 1 1 IN IP4 192.168.1.20
    s=-
    c=IN IP4 192.168.1.20
    t=0 0
    m=audio 12000 RTP/AVP 0 8 101
    a=rtpmap:0 PCMU/8000
    a=rtpmap:8 PCMA/8000
    a=rtpmap:101 telephone-event/8000

核对：

* 100 Trying / 180 / 200 的 ``Call-ID``\ 、``CSeq: 1 INVITE`` 与 INVITE 一致
* 200 的 To 已带 ``tag=``\ ，此后 dialog 三元组齐了
* ACK 的 CSeq 仍是 ``1 ACK``\ ，Call-ID 不变
* BYE 的 CSeq 递增（例如 ``2 BYE``\ ）

200 OK 之后 dialog 三元组是这样（To-tag 以 200 为准，不要抄 180）：

.. code-block:: text

    From: "Agent A" <sip:1001@192.168.1.10>;tag=111
    To: <sip:1002@192.168.1.10>;tag=222
    Call-ID: 1h23@192.168.1.20

正确 BYE 原样复制这三行，对端回 200。若只把 To-tag 抄错（180 的临时 tag、或另一条腿）：

.. code-block:: text

    BYE sip:1002@192.168.1.20:5060 SIP/2.0
    From: "Agent A" <sip:1001@192.168.1.10>;tag=111
    To: <sip:1002@192.168.1.10>;tag=WRONG
    Call-ID: 1h23@192.168.1.20
    CSeq: 2 BYE

    SIP/2.0 481 Call/Transaction Does Not Exist

sngrep 过滤 ``481``\ ：点开那条梯子，把 BYE 的三元组叠到 200 OK 上，错的那一个就是原因。
B2BUA 先确认你在看哪一条腿——internal 与 external 的 Call-ID / tags 本来就不同。

REGISTER 示例：

.. code-block:: text

    REGISTER sip:192.168.1.10 SIP/2.0
    To: <sip:1001@192.168.1.10>
    From: <sip:1001@192.168.1.10>;tag=a
    Call-ID: reg-1001@192.168.1.20
    CSeq: 2 REGISTER
    Contact: <sip:1001@192.168.1.20:5060>;expires=3600
    Content-Length: 0

也可用 ``sngrep -d any port 5060`` 看同一条梯子。配置细节见 :doc:`../7.practice/freeswitch_sip`\ 。


Conclusion
============

* SIP 只控制会话；声音在 SDP 指出的 RTP 地址上。
* Dialog 三元组错一个，后续请求就会 481。
* FS 两侧 Call-ID 不同是 B2BUA 正常现象。


Reference
============

* `RFC3261`_
* `RFC3262`_
* `RFC3311`_
* `RFC5411`_
* `RFC6026`_
* :doc:`../7.practice/freeswitch_sip`
