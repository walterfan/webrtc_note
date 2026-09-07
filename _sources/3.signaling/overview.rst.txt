######################
信令协议概论
######################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

一张地图：实时通信有哪些信令协议、呼叫中心该先读哪些 SIP RFC、FreeSWITCH 各 Endpoint 对应哪一章。

Abstract
------------

信令管呼叫控制，不管 RTP 里的声音。主线是 SIP（`RFC3261`_\ ）；浏览器侧是 JSEP；FreeSWITCH 还会碰到 Verto、SIP over WebSocket、Skinny、H.323。
`RFC5411`_ 是 SIP RFC 的导航，不是新协议。
没有单独的“Call Center Protocol”，能力由 SIP primitive 组合而成。


Why
============

* RFC 数量巨大，按编号读会把时间耗在呼叫中心用不到的扩展上。
* 把 Agent 状态、ACD、录音当成“某个 SIP RFC”去找，会找错层。
* 只认 SIP、不认 JSEP/Verto/H.323，网关和对端会看起来“都叫 VoIP、就是不通”。


How
============

10 秒分流：先认信封，再点章
--------------------------------

对着抓包的**端口 / 子协议**\ 选章，不要从 RFC 3261 逐页往下翻：

.. list-table:: 抓到什么 → 打开哪章
   :header-rows: 1
   :widths: 34 22 44

   * - 抓到
     - 本章
     - 一句话
   * - UDP/TCP 5060、INVITE 文本
     - 下面 RFC 表
     - 扫「打开它当」列
   * - 浏览器 ``createOffer``\ ，线上无 SIP
     - :doc:`jsep`
     - JSEP 不是线上协议
   * - WebSocket 子协议 ``sip``
     - :doc:`sip_websocket`
     - 完整 SIP 进浏览器
   * - WebSocket JSON-RPC ``verto.*``
     - :doc:`verto`
     - FS 给网页的短信封
   * - TCP **1720** / UDP 1719，无 INVITE
     - :doc:`h323`
     - H.225，不是 SIP
   * - TCP **2000**\ ，话机无 INVITE
     - :doc:`skinny`
     - SCCP；SIP 在另一条腿
   * - XMPP IQ 里的 ``<jingle>``
     - :doc:`jingle`
     - IQ 信封 + RTP 描述

呼叫中心业务（转接、PAI、录音）一律走 RFC 表，不走上面这些“换信封”章。

信令不止 SIP
--------------------

1990 年代 ITU 用 H.32x 按网络切标准：H.320 跑 ISDN，H.323 跑分组网，H.324 跑普通电话线。
H.323 是一套完整电话局（终端、Gatekeeper、MCU、Gateway），消息 ASN.1 二进制，呼叫走 H.225.0 + H.245。
IETF 的 SIP（RFC 2543，1999；现行 `RFC3261`_\ ）是文本、像 HTTP。媒体交给 SDP + RTP。

结果大致是：SIP 赢了新生代心智入口；H.323 仍留在会议室和存量网关；视频压缩（H.261→H.264）赢了但那是编码；T.120 是数据协作不是呼叫信令。

.. list-table:: H.323 vs SIP vs Jingle（信封不同，媒体都是 RTP）
   :header-rows: 1
   :widths: 18 28 28 26

   * -
     - H.323
     - SIP
     - Jingle
   * - 出身
     - ITU / 电信
     - IETF / 互联网
     - XMPP 生态
   * - 信封
     - ASN.1；H.225 Setup
     - 文本 INVITE
     - XMPP IQ
   * - 媒体描述
     - H.245 能力集
     - SDP
     - Jingle content XML
   * - 登记
     - RAS / Gatekeeper
     - REGISTER
     - XMPP 绑定 / roster
   * - 今天
     - 会议室、存量网关
     - Trunk、PBX、呼叫中心
     - Jitsi 等
   * - 本章
     - :doc:`h323`
     - :doc:`sip_core` 起
     - :doc:`jingle`

WebRTC 强制 ICE / DTLS-SRTP / RTP，**不规定** 线上信令。浏览器只履行 JSEP。SDP 怎么送到对端由应用选：

.. list-table:: WebRTC 常见信令承载
   :header-rows: 1
   :widths: 28 72

   * - 方式
     - 说明
   * - 自定义 JSON over WebSocket
     - 最常见，见 :doc:`../1.basic/webrtc_signal`
   * - JSEP 本身
     - 浏览器状态机，不是线上协议，见 :doc:`jsep`
   * - SIP over WebSocket
     - RFC 7118，SIP.js / JsSIP，见 :doc:`sip_websocket`
   * - Verto
     - FreeSWITCH JSON-RPC，见 :doc:`verto`
   * - Jingle over XMPP
     - Jitsi 等，见 :doc:`jingle`
   * - WHIP / WHEP
     - HTTP 推流/拉流，见 :doc:`../2.transport/whip`

XMPP 用 Jingle（XEP-0166）在 IQ 上协商 RTP/ICE/DTLS，信封是 XML。用 JSON 替换 XML（JMPP）只是格式，不是另一套呼叫模型。

为什么 SIP 难学
--------------------

Rosenberg 在 RFC 5411 里写清了：3261 是核心；大量 RFC 做 extension；SDP、Events 各有框架；P-header 来自运营商生态；不同业务要不同扩展。
看起来 RFC 3261、3262、3264、3515、3891… 很长，**绝大部分呼叫中心项目不需要全部掌握**\ 。

呼叫中心的 SIP 协议栈
----------------------

六层，从上往下读。缺能力时先认层，再进 RFC 表：

.. mermaid::

   flowchart TB
     L1["1 Contact Center Application<br/>Queue / ACD / Agent / Supervisor / IVR / Recording<br/>CTI / Transfer / Conference / Monitoring / Analytics"]
     L2["2 Call Control<br/>REFER / Replaces / Join / 3PCC / Dialog<br/>RFC 3515 / 3891 / 3911 / 3725 / 4235"]
     L3["3 Call Information<br/>PAI / History-Info / Reason"]
     L4["4 SIP Session<br/>INVITE ACK BYE CANCEL UPDATE PRACK<br/>REGISTER OPTIONS SUBSCRIBE NOTIFY INFO"]
     L5["5 SDP<br/>Offer/Answer RFC 3264 / 4566"]
     L6["6 Media<br/>RTP / RTCP / SRTP / DTMF / Codec"]
     L1 --> L2 --> L3 --> L4 --> L5 --> L6

第 1 层 Application 通常不属于 SIP 标准。SIP Dialog Event 能告诉你“这个 UA 有没有通话”，但不能表达 Available / Wrap-up / ACW。
第 5、6 层经常被写成一行；排障时要分开：488 是 SDP，无声是 RTP。

能力组合图
--------------------

.. mermaid::

   flowchart TB
     CC[Call Center]
     CC --> ACD[ACD]
     CC --> Agent[Agent]
     CC --> Sup[Supervisor]
     ACD --> HI[History-Info]
     Agent --> DE[Dialog Event]
     Sup --> Conf[Conference]
     HI --> SCC[SIP Call Control]
     DE --> SCC
     Conf --> SCC
     SCC --> REFER[REFER]
     SCC --> Repl[Replaces]
     SCC --> TPCC[3PCC]
     REFER --> SIP[SIP]
     Repl --> SIP
     TPCC --> SIP
     SIP --> SDP[SDP]
     SIP --> RTP[RTP]
     SIP --> DTMF[DTMF]

这也解释了为什么不同厂商“都符合 SIP，但就是不通”：同一 feature 可用不同 primitive 组合。`RFC5850`_ 专门讨论这个问题。

FreeSWITCH 上的信令
--------------------

内部统一成 session，对外用不同 Endpoint：

.. list-table:: FreeSWITCH 信令 Endpoint
   :header-rows: 1
   :widths: 22 28 22 28

   * - 协议
     - 模块
     - 重要性
     - 本章
   * - SIP
     - mod_sofia
     - ⭐⭐⭐⭐⭐ 主路径
     - :doc:`sip_core` 起
   * - SIP over WebSocket
     - mod_sofia ``ws-binding``
     - ⭐⭐⭐⭐ WebRTC SIP 话机
     - :doc:`sip_websocket`
   * - Verto
     - mod_verto
     - ⭐⭐⭐⭐ 原生 WebRTC
     - :doc:`verto`
   * - Skinny / SCCP
     - mod_skinny
     - ⭐⭐⭐ Cisco 话机
     - :doc:`skinny`
   * - H.323
     - mod_h323 / mod_opal
     - ⭐⭐ 会议室 / 存量网关
     - :doc:`h323`
   * - Jingle / XMPP
     - 历史上 mod_dingaling
     - ⭐⭐ 对端若是 Jitsi 等
     - :doc:`jingle`

配置与排障：:doc:`../7.practice/freeswitch_sip`\ 、:doc:`../7.practice/freeswitch_webrtc`\ 。

必学 RFC 表
--------------------

重要性：⭐⭐⭐⭐⭐ 必须 / ⭐⭐⭐⭐ 强烈建议 / ⭐⭐⭐ 按需 / ⭐⭐ 了解或遗留。

对着抓包或缺的能力扫 **「打开它当」**\ ，10 秒内点进一章。不要按 RFC 编号通读。

.. list-table:: Call Center SIP RFC
   :header-rows: 1
   :widths: 12 38 16 34

   * - RFC
     - 打开它当
     - 重要性
     - 本章
   * - `RFC3261`_
     - 报文结构、事务、Dialog 对不上
     - ⭐⭐⭐⭐⭐
     - :doc:`sip_core`
   * - `RFC3264`_
     - Offer/Answer 乱序、488
     - ⭐⭐⭐⭐⭐
     - :doc:`sip_sdp`
   * - `RFC4566`_
     - 读不懂 ``m=`` / ``a=``
     - ⭐⭐⭐⭐⭐
     - :doc:`sip_sdp`
   * - `RFC4733`_
     - IVR 收不到按键
     - ⭐⭐⭐⭐⭐
     - :doc:`sip_dtmf`
   * - `RFC3325`_
     - 弹屏主叫不对、缺 PAI
     - ⭐⭐⭐⭐⭐
     - :doc:`sip_identity`
   * - `RFC3515`_
     - 转接（盲转 / REFER）
     - ⭐⭐⭐⭐⭐
     - :doc:`sip_refer`
   * - `RFC3891`_
     - 咨询转、Replaces
     - ⭐⭐⭐⭐⭐
     - :doc:`sip_refer`
   * - `RFC4235`_
     - BLF / 谁在通话
     - ⭐⭐⭐⭐⭐
     - :doc:`sip_events`
   * - `RFC7044`_
     - 排队溢出路径对不上
     - ⭐⭐⭐⭐⭐
     - :doc:`sip_history`
   * - `RFC3326`_
     - 挂机原因、Q.850
     - ⭐⭐⭐⭐⭐
     - :doc:`sip_reason`
   * - `RFC7866`_
     - 录音腿 / SIPREC
     - ⭐⭐⭐⭐⭐
     - :doc:`sip_recording`
   * - `RFC5359`_
     - Hold / Park / Pickup 剧本
     - ⭐⭐⭐⭐⭐
     - :doc:`sip_call_control`
   * - `RFC4028`_
     - 通话中途“无声死掉”
     - ⭐⭐⭐⭐
     - :doc:`sip_session_timer`
   * - `RFC3725`_
     - CTI 外呼、话机不发 INVITE
     - ⭐⭐⭐⭐
     - :doc:`sip_3pcc`
   * - `RFC3892`_
     - 转接发起方身份
     - ⭐⭐⭐⭐
     - :doc:`sip_refer`
   * - `RFC4916`_
     - 接通后“实际接听者”
     - ⭐⭐⭐⭐
     - :doc:`sip_identity`
   * - `RFC8224`_
     - STIR/SHAKEN、主叫签名
     - ⭐⭐⭐⭐
     - :doc:`sip_identity`
   * - `RFC6665`_
     - SUBSCRIBE/NOTIFY 框架
     - ⭐⭐⭐⭐
     - :doc:`sip_events`
   * - `RFC5850`_
     - 同一功能多种组合、互通失败
     - ⭐⭐⭐⭐
     - :doc:`sip_call_control`
   * - `RFC4575`_
     - 会议成员列表
     - ⭐⭐⭐
     - :doc:`sip_conference`
   * - `RFC5806`_
     - 老网关 Diversion（Historic）
     - ⭐⭐
     - :doc:`sip_history`
   * - `RFC7544`_
     - Diversion ↔ History-Info
     - ⭐⭐⭐
     - :doc:`sip_history`

RFC 5359 尤其值得先读：直接给出 Hold、Transfer、Conference、Park、Pickup、Click-to-Dial 的完整 flow。
端到端 8 步地图：:doc:`sip_call_center`\ 。

建议学习顺序
--------------------

不要按 RFC 编号。面向 FreeSWITCH Call Center：

1. **SIP 基础**\ ：3261、3264、4566；REGISTER/INVITE/ACK/BYE/CANCEL；Transaction/Dialog/Session
2. **Call Control**\ ：3515、3891、3892、3725；盲转/咨询转/Click-to-Dial
3. **Routing**\ ：7044、4235、3325、3326；Caller → IVR → Queue → Agent
4. **Media / IVR**\ ：4733、RTP、Codec
5. **Recording / Conference**\ ：7866、4575、5850
6. **PSTN**\ ：PAI、Q.850、STIR/SHAKEN、SIP Trunk、SBC

和 WebRTC 的关系
--------------------

.. mermaid::

   flowchart TB
     CC[Contact Center] --> Ctrl[Call Control]
     Ctrl --> SIP[SIP]
     Ctrl --> SDP[SDP]
     Ctrl --> RTP[RTP]
     SIP --> FS[FreeSWITCH]
     SDP --> FS
     RTP --> FS
     FS --> Phone["SIP Phone<br/>Skinny/H.323"]
     FS --> Trunk[SIP Trunk]
     FS --> Web["WebRTC<br/>Verto / SIP-WS / JSEP"]

SIP 是呼叫控制语言，不是完整 Contact Center 协议。媒体见 :doc:`../2.transport/overview`\ 。


Example
============

呼入一通 8000，用抓包对表，而不是翻全部 SIP RFC：

.. code-block:: bash

    fs_cli -x "sofia global siptrace on"
    # 或：sngrep -d any port 5060
    # 端口不是 5060：tcpdump tcp port 1720（H.323）或 tcp port 2000（Skinny）

进线 INVITE 至少应能解释这些字段：

.. code-block:: text

    INVITE sip:8000@fs.example.com SIP/2.0
    From: <sip:+14155551212@trunk.example.com>;tag=a
    P-Asserted-Identity: <sip:+14155551212@trunk.example.com>
    To: <sip:8000@fs.example.com>
    Call-ID: 1h23@trunk
    CSeq: 1 INVITE
    Content-Type: application/sdp
    # SDP 含 PCMU 和 telephone-event → IVR 可收 DTMF（RFC 4733）

缺什么读哪章（对着 RFC 表「打开它当」列核）：无 PAI → :doc:`sip_identity`\ ；溢出无历史 → :doc:`sip_history`\ ；转接 → :doc:`sip_refer`\ ；挂断原因 → :doc:`sip_reason`\ 。端到端清单见 :doc:`sip_call_center`\ 。


Conclusion
============

* 先认层（1 应用 / 2 控制 / 3 信息 / 4 会话 / 5 SDP / 6 RTP），再扫 RFC 表「打开它当」。
* 呼叫中心必读：3261、3515、3891、3325、3326、7044、4733、7866、5359。
* WebRTC 进 FS：JSEP 出 SDP，线上 Verto 或 SIP-WS；1720/2000 上没有 INVITE。


Reference
============

* `RFC5411`_
* `RFC3261`_
* `RFC5359`_
* `RFC5850`_
* `RFC8829`_
* `RFC7118`_
* `ITU-T H.323`_
* :doc:`../7.practice/freeswitch_overview`
