################
SIP 会议
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

SIP 会议是焦点（focus）模型：每人与 mixer 建 dialog；状态用 Conference Event（`RFC4575`_\ ）订阅。

Abstract
------------

呼叫中心多方不只是三方通话：班长监听 / 耳语 / 强插、翻译席，都是进同一个 focus，差别只在 member flags。
`RFC5366`_ 允许 INVITE 带 URI 列表一次拉多人。
Dialog Event 描述一对一；``conference 3000 list`` 是 CLI；会场名单的 SIP 形态是 RFC 4575。


Why
============

* 没有会议焦点，班长强插只能另开一条腿，媒体无法 mute / coach。
* 用 Dialog Event 当参会名单，看不到谁在会上、谁被 mute。
* 加入方式（INVITE / REFER / 3PCC）不统一，话机和 CTI 会对不上。


How
============

场景
--------------------

.. mermaid::

   flowchart TB
     Cust[Customer] --> Agent[Agent]
     Agent --- Sup["Supervisor<br/>监听 / 耳语 / 强插"]
     Agent --- Interp["Interpreter<br/>翻译"]

架构见 `RFC4353`_\ ；状态见 `RFC4575`_\ ；一次性拉人见 `RFC5366`_\ 。

焦点模型
--------------------

每个人都和 focus 建立 **各自的** dialog，媒体在 mixer 混音：

.. mermaid::

   flowchart LR
     Agent[Agent] --> Focus["Conference Focus (mixer)"]
     Cust[Customer] --> Focus
     Interp[Interpreter] --> Focus
     Focus --> Sup[Supervisor]

加入方式：

* 直接 INVITE 到会议 URI
* REFER 把某条腿送到会议
* 3PCC 由控制器把各方 INVITE 进会议

FreeSWITCH ``conference`` 应用就是这个焦点。RFC 5850 把 mixer 当成一种 Media Intermediary，见 :doc:`sip_call_control`\ 。

班长监听 / 耳语 / 强插
------------------------

三种班长动作 **不是三种 SIP 方法**\ 。主管都 INVITE 同一个 focus；mixer 用不同 member flags / ``relate`` 决定谁能听谁、谁能说：

.. list-table:: 同一 focus，不同 flags
   :header-rows: 1
   :widths: 22 38 40

   * - 业务
     - mixer 行为
     - FreeSWITCH
   * - 监听（monitor）
     - 主管能听，不能被听到
     - 加入时 ``mute``\ ，flags 为 ``hear``
   * - 耳语（whisper / coach）
     - 主管只对坐席说话，客户听不到
     - ``relate <主管> <客户> nospeak``
   * - 强插（barge）
     - 主管能听能说，三方混音
     - 正常 ``hear|speak``\ ，不 relate

SIP 上看：主管多一条进 ``sip:3000@...`` 的 INVITE，Call-ID 与客户 / 坐席腿都不同。
不要去找一种叫 Barge 的 SIP 方法。另一种实现是 ``eavesdrop``\ （不进 conference），那是 FS 应用层旁路，不是 RFC 4575 的 focus。

Conference Event vs ``conference list``
----------------------------------------

两份名单说的是同一会场，协议不同：

.. list-table:: 会场名单的两种形态
   :header-rows: 1
   :widths: 28 72

   * - 形态
     - 用途
   * - ``conference 3000 list``
     - fs_cli / ESL，CTI 和排障首选
   * - `RFC4575`_ ``conference-info+xml``
     - 话机 / 第三方 UA ``SUBSCRIBE Event: conference``
   * - Dialog Event（`RFC4235`_\ ）
     - 一对一 dialog / BLF，**凑不出** 会场成员和 mute 状态

SUBSCRIBE/NOTIFY 提供 conference state：participant 列表、媒体、旁路状态。

.. code-block:: text

    SUBSCRIBE sip:3000@192.168.1.10
    Event: conference
    Accept: application/conference-info+xml

    NOTIFY  application/conference-info+xml

RFC 5366
--------------------

INVITE 里带 URI 列表，一次邀请多人入会。呼叫中心临时会议用得少，更常见于预定会议。
呼叫中心更常走 3PCC：对每个成员 ``originate ... &conference(3000)``\ 。

录音可以录会议混音，也可以分轨；SIPREC 见 :doc:`sip_recording`\ 。


Example
============

把 1001、1002 拉进同一会议（可立即验证）：

.. code-block:: bash

    fs_cli -x "sofia global siptrace on"
    fs_cli -x "originate user/1001 &conference(3000)"
    fs_cli -x "originate user/1002 &conference(3000)"
    fs_cli -x "conference 3000 list"

两条 INVITE 的 Request-URI / 被叫可以不同，但最终都应进 ``conference 3000``\ 。
``conference 3000 list`` 类似（字段以你的版本为准，看 member id 和 flags）：

.. code-block:: text

    1;sofia/internal/1001@192.168.1.10;<uuid-1>;hear|speak;1001
    2;sofia/internal/1002@192.168.1.10;<uuid-2>;hear|speak;1002

班长三种模式（假设主管是 1000；把 ``<id>`` 换成 list 里的编号）：

.. code-block:: bash

    # 监听：主管能听，客户/坐席听不到主管
    fs_cli -x "originate user/1000 &conference(3000@default+flags{mute})"
    # 或进会后再： conference 3000 mute <主管id>

    # 耳语：主管只对坐席(1001)说话，客户(1002)听不到
    fs_cli -x "originate user/1000 &conference(3000)"
    fs_cli -x "conference 3000 relate <主管id> <1002的id> nospeak"

    # 强插：三方都能听能说（不要 mute、不要 relate）
    fs_cli -x "originate user/1000 &conference(3000)"

SIP 上三次都是主管 INVITE 会议焦点；差别只在 list 里的 flags（``hear`` vs ``hear|speak``\ ）和 relate。

若话机支持 conference event，SUBSCRIBE 后 NOTIFY 的 ``<user>`` 数量应与 ``conference 3000 list`` 人数一致：

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>
    <conference-info xmlns="urn:ietf:params:xml:ns:conference-info"
                     entity="sip:3000@192.168.1.10"
                     state="full" version="1">
      <users>
        <user entity="sip:1001@192.168.1.10" state="full">
          <endpoint entity="sip:1001@192.168.1.20">
            <status>connected</status>
          </endpoint>
        </user>
        <user entity="sip:1002@192.168.1.10" state="full">
          <endpoint entity="sip:1002@192.168.1.21">
            <status>connected</status>
          </endpoint>
        </user>
      </users>
    </conference-info>

人数对不上：先信 ``conference 3000 list``\ （mixer 真相），再查 SUBSCRIBE 是否订到了这个 focus URI。


Conclusion
============

* 班长监听 / 耳语 / 强插 = 同一 focus，不同 member flags。
* ``conference 3000 list`` 是 CLI；名单的 SIP 形态是 RFC 4575。
* Dialog Event 描述一对一，凑不出会场名单。


Reference
============

* `RFC4575`_
* `RFC5366`_
* `RFC4353`_
* `RFC4235`_
* `RFC5850`_
