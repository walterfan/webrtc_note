################
呼叫身份
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

SIP 里主叫身份分三层，抓包时要分开读：**From（声明）**\ 、**P-Asserted-Identity（可信网断言）**\ 、**Identity / `RFC8224`_（密码学认证）**\ 。三者可以同时出现，含义不同，不必相同。

Abstract
------------

`RFC3325`_ 的 PAI 只在 trusted 域传递，RFC 5411 也指出它部署极广。
`RFC4916`_ Connected Identity 告诉主叫实际接听的是谁。
STIR/SHAKEN 解决 PSTN 侧“这个号码是不是呼叫者拥有的”，与 PAI 不是同一层。


Why
============

* 弹屏、计费、呼出显示若用 From，会被话机随意填写，导致找错客户或主叫被运营商拦截。
* 把 PAI 和 STIR 混为一谈：内网断言过了，出 PSTN 仍可能被当诈骗号码。
* 出网不剥 PAI、不尊重 Privacy，会把内部身份泄到不可信 UA。


How
============

三层对照（不要混）
--------------------

.. list-table:: 同一条 INVITE 里的三层身份
   :header-rows: 1
   :widths: 18 22 22 38

   * - 层
     - Header
     - 谁写、凭什么信
     - 抓包时用来做什么
   * - 声明
     - ``From``
     - UA 自己填，无认证
     - 话机屏幕上的显示名 / URI；**不可**\ 作计费或防伪
   * - 断言
     - ``P-Asserted-Identity``
     - 可信 Proxy / SBC / 网关在入网时插入
     - 弹屏、CDR、Trunk 主叫号码；只在 trusted 域有效
   * - 认证
     - ``Identity``
     - 认证服务签 PASSporT（JWT）
     - 出 PSTN / 互联时判断号码是否被伪造（STIR/SHAKEN）

.. code-block:: text

    From                 声明身份（可被终端随便填）
    P-Asserted-Identity  可信网络内的断言身份
    Identity (RFC 8224)  密码学认证的主叫身份（STIR/SHAKEN）

读一条 INVITE：先看 From（显示），再看 PAI（内网认谁），再看有没有 ``Identity``\ （出网能不能证明）。缺哪一层，就缺哪一种结论。

P-Asserted-Identity
--------------------

`RFC3325`_ 定义在 **可信网络** 中传递断言身份。典型部署点：SIP Trunk、运营商、PSTN 网关、SBC、FreeSWITCH、PBX。

规则直觉：

* 只在 **trusted** 域里传，出网到不可信 UA 时应删掉，改用 ``P-Preferred-Identity`` 或普通 From
* 常与 ``Privacy``\ （`RFC3323`_\ ）一起：``Privacy: id`` 表示不要把 PAI 暴露给不可信下游
* From 可以显示“客户姓名”，PAI 才是运营商认的主叫号码
* 一条消息里可以有两个 PAI：一个 ``sip:``\ ，一个 ``tel:``\ （E.164）

呼叫中心用途：呼入弹屏用 PAI；呼出时 SBC 按 PAI / 配置号码送 PSTN；CDR / 计费以 PAI 为准。

Connected Identity
--------------------

`RFC4916`_ 允许在对话中更新已连接身份，例如转接到另一人、总机应答后再接分机。
常见实现：200 OK 或 UPDATE 里更新 PAI，或刷新 From 的 id（实现各异）。很多系统用应用层事件代替。

STIR / SHAKEN 与 RFC 8224
--------------------------

PAI 只在可信 SIP 网里有意义。一旦到 PSTN / 不可信互联，主叫号码可以被伪造。
`RFC8224`_ 已取代 RFC 4474。核心是 SIP ``Identity`` header 携带 PASSporT（JWT）。

STIR 是 SIP 身份签名框架；SHAKEN 是北美电话网的部署规范（Attestation A/B/C）。

.. code-block:: text

    P-Asserted-Identity  →  Trusted SIP network 里的断言
    RFC 8224 / STIR      →  密码学认证的主叫身份

    attest A  已认证用户，且确认其有权用该号码
    attest B  已认证用户，号码权属未完全确认
    attest C  网关穿越，几乎未认证

涉及美国外呼、SIP Trunk、被运营商拦截时，不能只停留在 RFC 3325。
同一 INVITE 里 PAI 与 ``Identity`` 可以并存：PAI 回答“内网断言是谁”，JWT 回答“签名是否覆盖这个 orig.tn”。冲突时，出 PSTN 以签名为准判断“是否伪造”。

实践注意
--------------------

1. FreeSWITCH 可用 ``sip_h_P-Asserted-Identity`` 读写。呼出前确认 Trunk 要的是 PAI、Remote-Party-ID 还是 From（老设备还在用 RPID）。
2. Remote-Party-ID 是非标准遗留，和 PAI 类似，对接老 PBX 时仍会遇到。
3. 显示名（display name）和号码是两回事：防诈骗看号码认证，弹屏看号码 + CRM。
4. WebRTC 浏览器没有 PAI；网关入 SIP 网时由 FreeSWITCH / SBC 插入。


Example
============

Trunk 呼入 INVITE 应类似（用 siptrace 对照真实号码）：

.. code-block:: text

    INVITE sip:+18005551212@192.168.1.10:5080 SIP/2.0
    From: "Alice" <sip:+14155551212@trunk.example.com>;tag=a
    To: <sip:+18005551212@192.168.1.10>
    P-Asserted-Identity: "Alice" <sip:+14155551212@trunk.example.com>
    P-Asserted-Identity: <tel:+14155551212>
    Privacy: none
    Call-ID: 1h23@trunk
    CSeq: 1 INVITE

对照这一条：

.. code-block:: text

    From display-name = Alice              → 屏幕显示，不可信
    From URI          = +14155551212       → 声明号码，话机可改
    PAI sip / tel     = +14155551212       → 弹屏 / CDR 用这个
    Identity          = （本例没有）       → 不能据此判断 PSTN 侧真伪
    Privacy           = none               → 允许把身份传给可信下游

呼出到 Trunk 时在 dialplan 设置后再抓：

.. code-block:: xml

    <action application="set" data="sip_h_P-Asserted-Identity=&lt;sip:+14155550000@fs.example.com&gt;"/>

带 ``Privacy: id`` 的呼叫，出网到不可信 UA 后不应再出现 PAI；From 常变成匿名：

.. code-block:: text

    From: "Anonymous" <sip:anonymous@anonymous.invalid>;tag=a
    Privacy: id
    # 此处不应再有 P-Asserted-Identity

若有 STIR，INVITE 另有 ``Identity``\ ，形态是 compact JWT + 参数（不要拿占位 JWT 去验签，用真实抓包解码）：

.. code-block:: text

    Identity: <header>.<payload>.<signature>;info=<https://cert.example.com/passport.cer>;alg=ES256;ppt=shaken

验证：

* 弹屏 / CDR 用 PAI 的 ``+14155551212``\ ，不要用 From 显示名
* 带 ``Privacy: id`` 的呼叫，出网 INVITE 不应再出现 PAI
* 解码 PASSporT payload：``orig.tn`` 应对上 PAI/From 号码，``dest.tn`` 对上被叫，``attest`` 为 A/B/C；与 PAI 同时存在时以签名为准判断“是否伪造”

.. code-block:: bash

    fs_cli -x "sofia profile external siptrace on"


Conclusion
============

* 弹屏和计费读 PAI 的 tel/sip 号码；From 的 display-name 只是显示。
* 同一条 INVITE 有 PAI、没有 Identity，只能信内网断言，不能信 PSTN 主叫真伪。
* Privacy: id 出可信网后不应再出现 P-Asserted-Identity。


Reference
============

* `RFC3325`_
* `RFC3323`_
* `RFC4916`_
* `RFC8224`_
* `RFC5411`_
