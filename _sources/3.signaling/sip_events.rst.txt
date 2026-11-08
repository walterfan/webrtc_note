#####################
SIP Events 与对话状态
#####################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

SIP Events（`RFC6665`_\ ）用 SUBSCRIBE/NOTIFY 订阅状态；呼叫中心最常用的是 Dialog Event（`RFC4235`_\ ）。

Abstract
------------

RFC 6665 取代 RFC 3265，是事件总框架。RFC 4235 订阅 INVITE dialog 状态（Idle/Trying/Early/Confirmed/Terminated）。
REFER 也隐式订阅 refer 事件包（见 :doc:`sip_refer`\ ）。
Dialog 状态不是 Contact Center 的 Agent 状态。


Why
============

* 把 Dialog Event 当成坐席 Available/ACW，路由和 SLA 会全错。
* 没有 BLF/通话监视时，班长看不到谁在通话，只能靠应用层私有接口。
* 向每台话机 SUBSCRIBE 而不做汇聚，信令负载会拖垮 registrar。


How
============

框架
--------------------

订阅本身是一条 SIP dialog（SUBSCRIBE 创建），但订阅的对象常常是 **别人的 INVITE dialog**\ 。两者不要混。

.. code-block:: text

    SUBSCRIBE  Event: dialog; Expires: 3600
         ↓  202 / 200
    NOTIFY     Subscription-State: active     ← 立刻一发，即使当前 Idle
         ↓  之后状态变就再发
    NOTIFY     ... <state>early</state>
    NOTIFY     ... <state>confirmed</state>
    NOTIFY     Subscription-State: terminated ← Expires 到或主动退订

siptrace 核对：``Event:`` 与 ``Accept: application/dialog-info+xml`` 对得上；
NOTIFY 的 ``Subscription-State`` 不是 dialog-info 的 ``<state>``\ 。

Dialog Event
--------------------

允许一个系统获取另一个用户当前的 Call/Dialog 状态：

.. code-block:: text

    Supervisor --SUBSCRIBE Event: dialog--> Agent UA / PBX
    Supervisor <--NOTIFY dialog-info+xml---- Agent UA / PBX

NOTIFY 里可以看到：

.. code-block:: text

    Idle / Trying / Proceeding / Early / Confirmed / Terminated

和呼叫中心这些能力都有关系：Agent 是否在通话、Supervisor Dashboard / BLF、电话监控、自动回拨、Call State Monitoring。
RFC 4235 的设计目标就是让分布式应用订阅 INVITE dialog 状态。

Agent State ≠ Dialog State
--------------------------------

SIP 只能告诉你：这个 AoR **当前有没有 INVITE dialog**\ 。
呼叫中心要决定的是：这个人 **能不能接下一通**\ 。这两件事只有部分时间碰巧长得像。

mod_callcenter 在 ``callcenter_config agent list`` 里其实有两列：

* **status**\ （坐席自己设）：``Logged Out`` / ``Available`` / ``Available (On Demand)`` / ``On Break``
* **state**\ （系统算的）：``Idle`` / ``Waiting`` / ``Receiving`` / ``In a queue call``

挂机后的 wrap-up（ACW）期间，status 往往仍是 ``Available``\ ，state 是 ``Idle``\ ，**这段时间不能进线**\ 。
SIP 侧同一时刻已经是 dialog ``terminated`` 或没有 dialog——看起来像空闲。

.. list-table:: dialog-info state vs callcenter agent
   :header-rows: 1
   :widths: 22 28 28 22

   * - dialog-info ``<state>``
     - SIP 含义
     - callcenter 常见样子
     - 能当路由条件吗
   * - （无 dialog）Idle
     - 没有 INVITE 会话
     - ``Logged Out`` / ``Available`` / ``On Break`` / ACW 都可能
     - **否**
   * - trying / proceeding
     - INVITE 已发出，尚未 18x/2xx
     - ``Receiving``\ ，或一条咨询腿
     - 否
   * - early
     - 振铃 / 早期媒体
     - ``Receiving``\ （振铃）
     - 仅 BLF 灯
   * - confirmed
     - 已接通
     - ``In a queue call``
     - 仅“正在通话”
   * - terminated
     - dialog 已结束
     - ``Idle`` / ``Waiting`` / ACW
     - **否**\ ：挂机后常进 wrap-up

同一秒对照（抓包时用这一段打脸）：

.. code-block:: text

    坐席 Available，排队等客
      dialog-info:  Idle（没有 <dialog>）
      agent list:   status=Available  state=Waiting
      → 可以接下一起。SIP 看起来也像空闲，这次碰巧一致。

    坐席 On Break，同样没有通话
      dialog-info:  Idle
      agent list:   status=On Break   state=Idle
      → 不能进线。SIP 与上面那条无法区分。

    刚挂机，wrap-up-time=30
      dialog-info:  terminated / Idle
      agent list:   status=Available  state=Idle
      → 也不能进线。SIP 已经说“没通话了”。

所以：**SIP Dialog Event 不是完整的 Contact Center Agent State Protocol。**
现代呼叫中心的 Agent State、Queue State、Skill、Routing、ACD、WFM 属于 **应用层**\ ，
由 FreeSWITCH mod_callcenter、Genesys、Cisco 等自己实现。

.. code-block:: text

    SIP dialog:     有没有通话
    Agent state:    能不能接下一通、在不在休息、要不要 ACW

其他常用 Event Package
------------------------

.. list-table:: 与呼叫中心相关的 Event
   :header-rows: 1
   :widths: 28 22 50

   * - Package
     - RFC
     - 用途
   * - dialog
     - 4235
     - 通话 / BLF
   * - presence
     - 3856 等
     - 在线状态（不等同 Agent state）
   * - conference
     - 4575
     - 会议成员，见 :doc:`sip_conference`
   * - refer
     - 3515
     - REFER 执行进度
   * - message-summary
     - 3842
     - 语音信箱 MWI

实践注意
--------------------

1. 向话机 SUBSCRIBE dialog 会增加信令负载；大规模 BLF 通常由 PBX 集中生成。
2. FreeSWITCH 有 presence / BLF 相关配置，但 **callcenter 坐席状态** 走的是应用事件（ESL），不是 RFC 4235。
3. WebRTC 浏览器一般不实现 dialog event；监控应打在 FreeSWITCH / CTI 上。


Example
============

订阅分机 1001 的 dialog（需对端 Allow/Supported 含 SUBSCRIBE，且 FS/话机开启 presence）：

.. code-block:: text

    SUBSCRIBE sip:1001@192.168.1.10 SIP/2.0
    From: <sip:supervisor@192.168.1.10>;tag=s1
    To: <sip:1001@192.168.1.10>
    Call-ID: blf-1001@192.168.1.40
    CSeq: 1 SUBSCRIBE
    Event: dialog
    Expires: 3600
    Accept: application/dialog-info+xml
    Contact: <sip:supervisor@192.168.1.40:5060>
    Content-Length: 0

1001 振铃后 NOTIFY 体应类似：

.. code-block:: xml

    <?xml version="1.0"?>
    <dialog-info xmlns="urn:ietf:params:xml:ns:dialog-info"
                 version="3" state="full" entity="sip:1001@192.168.1.10">
      <dialog id="id1" call-id="abc" local-tag="x" remote-tag="y" direction="recipient">
        <state>early</state>
      </dialog>
    </dialog-info>

验证：

.. code-block:: bash

    fs_cli -x "sofia global siptrace on"
    # 从支持 BLF 的话机订阅 1001，再打进 1001，看 NOTIFY 的 state 从 early → confirmed
    fs_cli -x "callcenter_config agent list"

对照 ESL：``channel_create`` / ``channel_answer`` 与 dialog-info 的 ``<state>`` 应对上；
``callcenter_config agent list`` 里的 Available / Idle 则 **不必** 与 dialog Idle 一致。
挂机后若 ``wrap-up-time`` 未到，NOTIFY 已是 ``terminated``\ ，agent list 仍可能是 ``status=Available state=Idle``\ ——这就是“Agent State ≠ Dialog State”在抓包里的样子。


Conclusion
============

* Dialog Event 只回答“有没有通话”；能不能接下一通看 callcenter / ESL。
* dialog Idle ≠ Agent Available：On Break 和 ACW 在 SIP 里也是 Idle。
* BLF 订 ``Event: dialog``\ ；REFER 进度订 ``Event: refer``\ ；两者都不是坐席状态。


Reference
============

* `RFC6665`_
* `RFC4235`_
* `RFC3515`_
