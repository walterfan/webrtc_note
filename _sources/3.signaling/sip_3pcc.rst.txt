################
第三方呼叫控制
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

3PCC（`RFC3725`_\ ）是第三方控制呼叫：控制器向两个 endpoint 各发 INVITE，自己不一定出媒体。

Abstract
------------

它不是一个新 SIP 方法，而是 SDP 时序和谁先被呼的约定。
REFER 是“请某个 UA 自己去发起呼叫”；3PCC 是“控制器自己向双方发 INVITE”——抓包就是两条 INVITE，没有 REFER。
FreeSWITCH 的 originate / bridge / ESL 本质上就是 3PCC。


Why
============

* Click-to-Dial、预测式外呼、CRM 点号，不能指望话机去发 REFER。
* SDP 时序错了会出现“坐席先接通却听不到人”或“客户先接通却没有坐席”。
* 和 REFER 混用却不区分路径，排障时会在话机上找根本不存在的 REFER。


How
============

角色
--------------------

.. mermaid::

   flowchart TB
     CRM["CRM / CTI"] -->|"Call Customer"| CCS["Call Control Server<br/>FreeSWITCH"]
     CCS -->|INVITE| Agent[Agent]
     CCS -->|INVITE| Cust[Customer]

两条 INVITE，没有 REFER
------------------------

.. list-table:: 同一“把 A 和 B 接通”的两条路
   :header-rows: 1
   :widths: 22 38 40

   * - 对比
     - REFER（:doc:`sip_refer`\ ）
     - 3PCC（本章）
   * - 谁发起
     - 已在通话中的 UA
     - CTI / FreeSWITCH
   * - 信令
     - 一条 REFER + NOTIFY sipfrag
     - **两条 INVITE**\ ，Call-ID 各不相同
   * - 话机上
     - 能抓到 REFER
     - **没有 REFER**
   * - 典型入口
     - 话机转接键
     - ``originate`` / ESL / CRM 点号

典型场景
--------------------

* Click-to-Dial：坐席在 CRM 点客户号码
* Preview / Predictive Dialing：外呼活动先呼客户，接通再桥坐席
* Agent-assisted dialing：系统拨号，坐席只接听
* 咨询后由 CTI 完成转接，而不是话机发 REFER

Flow I：先呼坐席再呼客户（Click-to-Dial）
------------------------------------------

`RFC3725`_ 的 Flow I 用 **delayed offer** 避免过早锁定媒体：先给坐席发无 SDP 的 INVITE，用坐席 200 里的 offer 去呼客户，再把客户的 answer ACK 回坐席。

.. mermaid::

   sequenceDiagram
     participant Ctrl as Controller
     participant Agent as Agent
     participant Cust as Customer

     Ctrl->>Agent: INVITE (no SDP)
     Agent->>Ctrl: 200 (offer)
     Ctrl->>Cust: INVITE (offer)
     Cust->>Ctrl: 200
     Ctrl->>Agent: ACK (answer)
     Ctrl->>Cust: ACK
     Agent<<->>Cust: RTP

RFC 3725 还讨论了先带占位 SDP、再 re-INVITE 的变体。核心难点不变：

* 先向哪一方发 INVITE
* 第一段 200 OK 的 SDP 如何作为第二段的 offer
* 如何避免“坐席先接通却听不到人”或“客户先接通却没有坐席”

外呼活动里，通常 **先呼客户**\ （节省坐席时间），接通后再 INVITE 坐席；Click-to-Dial 则常 **先呼坐席**\ （保证坐席已摘机）。

SDP 时序陷阱
--------------------

1. **无 SDP 的 INVITE**\ （delayed offer）老 UA / 部分网关可能直接 488 或忽略。FreeSWITCH 默认 originate 常常是 **带 SDP 的 offer**\ ，和 RFC 3725 Flow I 字面不完全一样，但“先 200 的那条腿提供 SDP”这条约束一样。
2. 第一段若放 ``c=0.0.0.0`` / ``a=inactive`` 当占位，有的终端会直接拒绝。
3. **客户已 200、坐席尚未接**\ ：必须给客户放回铃音 / MOH（re-INVITE ``sendonly``\ ），或超时放弃（abandon）。先 ACK 客户再干等坐席，客户会听到静音，还占着 PSTN 腿。
4. 把客户的 answer 当成给坐席的 offer（方向反了），两边 ``a=`` 对不上，接通后无声。
5. 控制器必须是 B2BUA，两边 dialog 独立，媒体在 FreeSWITCH 桥接或绕开（bypass media）。

和 FreeSWITCH 的对应
--------------------

.. code-block:: text

    originate user/1001 &bridge(sofia/gateway/pstn/14085551212)
        → 先 INVITE 1001，200 后再 INVITE PSTN     （Click-to-Dial）

    originate sofia/gateway/pstn/14085551212 &bridge(user/1001)
        → 先 INVITE 客户，200 后再 INVITE 1001     （预测式外呼）

应用层（ESL、mod_callcenter、自研 CTI）发出 originate，SIP 层看到的是两个 INVITE。话机可能完全不发 REFER。

* 话机转接 → 常走 REFER（:doc:`sip_refer`\ ）
* CRM / 预测式外呼 → 常走 3PCC
* 两者可以在同一个呼叫中心并存

完整 Click-to-Dial 剧本见 `RFC5359`_\ ；互操作成本见 `RFC5850`_\ 。


Example
============

在已注册分机 1001、且 gateway ``pstn`` 可用时执行（先呼坐席）：

.. code-block:: bash

    fs_cli -x "sofia global siptrace on"
    fs_cli -x "originate user/1001 &bridge(sofia/gateway/pstn/14085551212)"

siptrace 中应先后出现两条 **Call-ID 不同** 的 INVITE，**没有 REFER**\ ：

.. code-block:: text

    INVITE sip:1001@192.168.1.20:5060 SIP/2.0
    From: <sip:14085551212@192.168.1.10>;tag=leg-a
    To: <sip:1001@192.168.1.10>
    Call-ID: orig-1001-aaaa@192.168.1.10
    CSeq: 1 INVITE
    Content-Type: application/sdp

    v=0
    o=FreeSWITCH 1 1 IN IP4 192.168.1.10
    s=-
    c=IN IP4 192.168.1.10
    t=0 0
    m=audio 16000 RTP/AVP 0 101
    a=rtpmap:0 PCMU/8000
    a=rtpmap:101 telephone-event/8000

    INVITE sip:14085551212@pstn.example.com SIP/2.0
    From: <sip:1001@192.168.1.10>;tag=leg-b
    To: <sip:14085551212@pstn.example.com>
    Call-ID: orig-pstn-bbbb@192.168.1.10
    CSeq: 1 INVITE
    Content-Type: application/sdp

第二条 INVITE 出现的时机：必须在 1001 的 **200 OK** 之后（&bridge 才开始）。
若 1001 未接，PSTN 腿不应出现；若 PSTN 先 200、1001 还在振铃，客户会无声——这就是 SDP 时序陷阱。

核对清单：

1. FS → 1001 的 INVITE，以及 1001 的 180/200
2. FS → gateway 的第二条 INVITE（另一个 Call-ID）
3. 两条腿各自 ACK 后 RTP 被 bridge
4. 话机侧 **没有** REFER、没有 ``Event: refer`` 的 NOTIFY

ESL 等价：

.. code-block:: text

    api originate {origination_caller_id_number=14085550000}user/1001 &bridge(sofia/gateway/pstn/14085551212)

先呼客户再桥坐席（预测式）把 originate 两端对调即可。
Click-to-Dial 的完整 SIP 剧本见 `RFC5359`_\ 。


Conclusion
============

* 3PCC 是两条 INVITE，话机上没有 REFER。
* 先 200 的那条腿的 SDP，才能当第二条 INVITE 的 offer。
* originate 失败要拆两条腿看，不要合成一个原因。


Reference
============

* `RFC3725`_
* `RFC5359`_
* `RFC5850`_
