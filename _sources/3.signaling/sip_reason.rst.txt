#################
Reason 与挂断原因
#################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

Reason（`RFC3326`_\ ）把挂断/取消原因显式放进 SIP 消息，可携带 SIP 状态码或 Q.850 cause。

Abstract
------------

486/480/487/503 只是一跳的协议结果。跨 PSTN、B2BUA、转接时需要把原因继续往后带。
CANCEL 和 BYE 都可以带 Reason。分析 CDR 时要分层看 SIP 响应、Reason、Q.850、应用层。


Why
============

* 没有 Reason，487 分不清是主叫放弃、排队超时还是坐席拒接。
* PSTN 的 Q.850 若不映射进 SIP，报表只能看到笼统的 480/503。
* 假设各家 hangup cause 表一致，跨 SBC 对账会对不上。


How
============

487 本身没有原因
--------------------

``487 Request Terminated`` 只说明 **这条 INVITE 事务被取消了**\ 。它几乎总是 CANCEL（或等价的拆线）的结果，**不告诉你为什么取消**\ 。

真正的信号在 **那条 CANCEL（有时是 BYE）上的 Reason**\ 。CANCEL 没有 Reason 时，487 是歧义的：主叫挂机、排队超时拆振铃、另一路已接通（Call completed elsewhere）在 SIP 上看起来一样。

.. list-table:: 对着抓包读 487
   :header-rows: 1
   :widths: 42 58

   * - 你看到的
     - 能得出的结论
   * - INVITE → 487，CANCEL **无** Reason
     - 只能记“振铃被取消”，不能写进 CDR 原因
   * - CANCEL ``Reason: SIP;cause=200`` / ``Call completed elsewhere``
     - 另一腿已接听，本腿被拆
   * - CANCEL ``Reason: SIP;cause=408`` 或 ``Q.850;cause=19``
     - 无应答 / 排队超时取消振铃
   * - CANCEL ``Reason: SIP;cause=486`` 或 ``Q.850;cause=17``
     - 忙
   * - BYE ``Reason: Q.850;cause=16``
     - PSTN 正常拆线，不是 487 场景

两种 protocol
--------------------

.. code-block:: text

    Reason: SIP;cause=486;text="Busy Here"
    Reason: Q.850;cause=16;text="Normal call clearing"

* ``SIP`` —— 用 SIP 状态码
* ``Q.850`` —— PSTN / ISUP 的 cause code

常见组合：

* 主叫放弃：CANCEL 常 **不带** Reason；有的实现会写 ``SIP;cause=487`` 或 Q.850 cause 16。没有 Reason 就不要猜。
* 被叫忙：486 + Q.850 17
* 无应答：480 / 408 + Q.850 19
* 另一路接通：CANCEL 上 ``SIP;cause=200``\ （RFC 3326 的经典例子）

Q.850 cause 速查
--------------------

.. list-table:: 常用 Q.850 cause
   :header-rows: 1
   :widths: 12 40 48

   * - Cause
     - 含义
     - 典型 SIP
   * - 16
     - Normal call clearing
     - BYE / 200
   * - 17
     - User busy
     - 486
   * - 18
     - No user responding
     - 408 / 480
   * - 19
     - No answer from user
     - 480
   * - 21
     - Call rejected
     - 603
   * - 31
     - Normal, unspecified
     - 480 / BYE
   * - 34
     - No circuit / channel available
     - 503

不同运营商、SBC、FreeSWITCH hangup cause 的映射表并不完全一致。
生产系统应建立 **内部 hangup cause → SIP → Q.850** 的对照，而不是假设全局统一。

分析失败呼叫
--------------------

1. **SIP 最终响应**\ ：486 是对端说忙，503 可能是自己过载或网关不足；**487 只是“被取消”**
2. **Reason**\ ：CANCEL 上的 Reason 往往比 487 本身更有信息
3. **Q.850**\ ：PSTN 侧真正原因（空号、线路拥塞）
4. **应用层**\ ：排队超时、坐席拒接、IVR 挂机 —— 这些 SIP 不一定能完整表达

FreeSWITCH 的 ``hangup_cause`` / ``proto_specific_hangup_cause`` 是查问题的入口，再对照 SIP 抓包里的 Reason。


Example
============

主叫放弃振铃时，INVITE 事务以 487 结束；若 CANCEL **没有** Reason，从 487 读不出“谁取消、为何取消”：

.. code-block:: text

    CANCEL sip:1001@192.168.1.30:5060 SIP/2.0
    From: <sip:+14155551212@trunk.example.com>;tag=a
    To: <sip:1001@192.168.1.10>
    Call-ID: 1h23@trunk
    CSeq: 1 CANCEL
    Content-Length: 0

    SIP/2.0 487 Request Terminated

同一 Call-ID / 同一 INVITE CSeq 上，**Call completed elsewhere** 的信号在 CANCEL 的 Reason，不在 487：

.. code-block:: text

    CANCEL sip:1001@192.168.1.30:5060 SIP/2.0
    From: <sip:+14155551212@trunk.example.com>;tag=a
    To: <sip:1001@192.168.1.10>
    Call-ID: 1h23@trunk
    CSeq: 1 CANCEL
    Reason: SIP;cause=200;text="Call completed elsewhere"

    SIP/2.0 487 Request Terminated

排队超时拆振铃时，CANCEL 上应能看到 408 / Q.850 19 一类 Reason（应用层自己写进去，不会自动出现）：

.. code-block:: text

    CANCEL sip:1001@192.168.1.30:5060 SIP/2.0
    Reason: SIP;cause=408;text="Request Timeout"

PSTN 正常挂机的 BYE：

.. code-block:: text

    BYE sip:1001@192.168.1.30:5060 SIP/2.0
    Reason: Q.850;cause=16;text="Normal call clearing"

验证：

.. code-block:: bash

    fs_cli -x "sofia global siptrace on"
    fs_cli -x "show calls"
    # 挂机后：
    fs_cli -x "eval ${hangup_cause}"
    fs_cli -x "eval ${proto_specific_hangup_cause}"

对照抓包里的 Reason 与 CDR。Q.850 在 SIP 中的携带见 `RFC6432`_\ 。


Conclusion
============

* 487 只说明 INVITE 被取消；原因在对应 CANCEL（或 BYE）的 Reason。
* CANCEL 没有 Reason 时，487 分不清主叫放弃、排队超时还是 CCE。
* 跨 PSTN 先对 Q.850 cause，再对 SIP 状态码；应用层原因要自己写入 Reason。


Reference
============

* `RFC3326`_
* `RFC6432`_
