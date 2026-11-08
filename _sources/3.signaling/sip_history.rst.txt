################
呼叫历史与改向
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

History-Info（`RFC7044`_\ ）记录请求被 retarget 的历史；老系统用 Diversion（`RFC5806`_\ ），互操作见 `RFC7544`_\ 。

Abstract
------------

Agent 若只有 From/To，不知道电话为什么来到这里。ACD 溢出、前转、语音信箱都会改写目标。
RFC 4244 已被 7044 取代；4244/7131 的例子直接包含 Automatic Call Distribution。
新系统用 History-Info；对接老运营商保留 Diversion 映射。


Why
============

* 没有路由历史，弹屏和报表会把溢出当成直达，质检无法解释“为什么进了银牌队列”。
* 用 From/To 推断历史不可行：B2BUA 会改写它们。
* 只实现 History-Info、不映射 Diversion，和老 PBX/运营商会丢改向原因。


How
============

两类 header
--------------------

* **History-Info**\ （`RFC7044`_\ ，取代 RFC 4244）—— 新系统应该用这个
* **Diversion**\ （`RFC5806`_\ ，Historic）—— 老运营商 / PBX 仍大量存在
* **`RFC7544`_** —— 两者互操作映射

.. code-block:: text

    新系统:          History-Info (RFC 7044)
    老运营商 / PBX:  Diversion
    互操作:          RFC 7544

History-Info 与 ACD 溢出
--------------------------

典型路径：

.. code-block:: text

    Customer → 8000 → Sales Queue → Gold Queue → Silver / Agent

Agent 应能知道 original target、中间队列、以及为什么 retarget。
`RFC7131`_ 第 3.4 节就是 Automatic Call Distribution overflow：Gold 忙则改向 Silver，坐席靠 History-Info 判断“这是一通 Gold 客户”。

没有 History-Info，坐席和质检只能看到最后一跳。有了它：

* 弹屏显示“销售热线溢出到银牌队列”
* 报表区分“直达” vs “溢出”
* IVR 可以根据原始被叫播放不同提示音
* 防止把 overflow 误统计成二次呼入

怎么读 index
--------------------

``index`` 是一棵树，不是数组下标。``1`` 永远是原始目标；每次 retarget 在末位加一段。

.. list-table:: ACD 溢出 → History-Info（对照坐席 INVITE）
   :header-rows: 1
   :widths: 16 28 56

   * - index
     - 这一跳
     - 怎么读
   * - ``1``
     - 原始被叫（8000 / Gold）
     - 客户真正拨的号；报表的“原始目标”
   * - ``1.1``
     - 第一跳队列 / ACD 服务器
     - ``rc=`` 指向上一跳；URI 里 ``Reason=...cause=408`` 表示本跳超时才溢出
   * - ``1.2``
     - 溢出后的下一队列
     - ``mp=1`` 表示 mapped-from 原始目标（RFC 7131 Gold→Silver 写法）
   * - ``1.3`` / ``1.2.1.1``
     - 最终坐席
     - To / Request-URI 已经是分机，历史只能靠这些 hi-entry

`RFC7131`_ 的 Gold 溢出示例（抓包形态）：

.. code-block:: text

    History-Info: <sip:Gold@example.com>;index=1
    History-Info: <sip:Gold@gold.example.com?Reason=SIP%3Bcause%3D302>;rc=1;index=1.1
    History-Info: <sip:Silver@example.com>;index=1.2;mp=1
    History-Info: <sip:Silver@silver.example.com>;index=1.2.1;rc=1.2
    History-Info: <sip:Silver@192.0.2.7>;index=1.2.1.1;rc=1.2.1

读法：``mp=1`` 指回 index=1 → 这通仍是 Gold 客户；后面几跳只是溢出路径。``rc`` 是 received-from，``mp`` 是 mapped-from，不要和 index 本身当成同一件事。

队列超时溢出常用 ``Reason=SIP;cause=408``\ （无应答）；RFC 7131 示例用 302 表示 ACD 主动改向。抓包时看 URI 里转义后的 ``?Reason=SIP%3Bcause%3D...``\ 。

Diversion 是遗留
--------------------

.. code-block:: text

    Diversion: <sip:sales@example.com>;reason=unconditional;counter=1

告诉下游：从谁改向来的、为什么改向。常见于 Call Forward、Voicemail、老 ACD。
RFC 5806 现在是 Historic，不建议新系统把它当标准方案。老网关往往只给这一行，没有树形 index：``counter`` 只是改向次数，还原不了 Gold→Silver→坐席这种链。

实践建议
--------------------

1. FreeSWITCH 入局时同时看 ``History-Info`` 和 ``Diversion``\ ，归一成内部“原始被叫 / 改向原因”。
2. 出局到只懂 Diversion 的网关，按 RFC 7544 做映射。
3. 应用层（fifo / callcenter）的队列名不一定会出现在 SIP header 里——若希望坐席侧 SIP 话机也能看到，需要主动写入 History-Info 或自定义 header。
4. 不要用 From/To 推断路由历史，B2BUA 会改写它们。


Example
============

溢出后打到坐席的 INVITE 应能看到多级 History-Info（index 递增）。对照 siptrace：

.. code-block:: text

    INVITE sip:1001@192.168.1.30:5060 SIP/2.0
    From: <sip:+14155551212@trunk.example.com>;tag=a
    To: <sip:1001@192.168.1.10>
    History-Info: <sip:8000@fs.example.com>;index=1
    History-Info: <sip:sales@fs.example.com?Reason=SIP%3Bcause%3D408>;index=1.1
    History-Info: <sip:gold@fs.example.com?Reason=SIP%3Bcause%3D408>;index=1.2
    History-Info: <sip:1001@fs.example.com>;index=1.3

按 index 还原：

.. code-block:: text

    1     8000          客户拨的接入号
    1.1   sales         销售队列，408 超时溢出
    1.2   gold          金牌队列，408 超时溢出
    1.3   1001          坐席。To 已经是 1001，不能据此说客户打的是 1001

老网关可能只有 Diversion（遗留，没有 index 树）：

.. code-block:: text

    Diversion: <sip:8000@fs.example.com>;reason=user-busy;counter=2;privacy=off

验证：

.. code-block:: bash

    fs_cli -x "sofia profile internal siptrace on"
    # 让 8000 排队溢出到 1001，看坐席 INVITE 是否带 History-Info 或你写入的 X-header

若 header 缺失：在 dialplan 用 ``sip_h_History-Info`` / ``sip_h_Diversion`` 显式补（具体变量名以当前 FS 版本为准，待确认也可抓到后再回写）。


Conclusion
============

* 坐席 INVITE 用 History-Info 的 index 还原溢出链：index=1 是原始被叫。
* 只有 Diversion、没有 History-Info，对接的是遗留网关，按 RFC 7544 互译。
* To / From 已被 B2BUA 改成坐席分机，不能当路由历史。


Reference
============

* `RFC7044`_
* `RFC4244`_
* `RFC7131`_
* `RFC5806`_
* `RFC7544`_
