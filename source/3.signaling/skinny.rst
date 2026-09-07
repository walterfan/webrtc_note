################
Skinny / SCCP
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

SCCP（Skinny）是 Cisco IP 话机的瘦客户端信令：按键和灯由 Call Agent 下发，话机自己不发 INVITE。

Abstract
------------

不是 IETF 标准。呼叫中心只要还有 7940/7960/8800 一类话机就会碰到。
FreeSWITCH 用 ``mod_skinny`` 当这些话机的 CallManager，再在另一条腿上讲 SIP。
转接/BLF 是话机按键 + 服务器状态机，不是 REFER/Dialog Event 原文。


Why
============

* 已有 Cisco 话机库存时，只部署 SIP profile 注册不上。
* 在话机上抓 SIP INVITE 会扑空，误判“没呼叫”。
* 话机同时向 CUCM 和 FS 注册，状态机会打架。


How
============

和 SIP 的差别
--------------------

SIP 话机自己是 UA。Skinny 话机更像远程 UI：

.. mermaid::

   flowchart TB
     Phone[Cisco IP Phone]
     CA["Call Agent<br/>CUCM 或 FreeSWITCH mod_skinny"]
     Trunk["SIP Trunk / 队列 / 会议"]
     Phone -->|"TCP 2000 SCCP<br/>StationRegister / CallState / SetRinger / SoftKey<br/>无 SIP INVITE"| CA
     CA -->|"SIP INVITE"| Trunk

* 注册：``StationRegister``\ ，不是 SIP REGISTER
* 摘机、拨号、保持：一串 Skinny 消息，由服务器改呼叫状态
* 媒体：服务器告诉话机 RTP 地址，编码多为 G.711 / G.729
* 无 SDP 文本，能力在 Skinny 字段里

FS 作为 Call Agent 时，要把这些动作翻译成内部 session，再在 SIP 侧发出去。

抓包：TCP 2000 vs SIP 腿
--------------------------

.. list-table::
   :header-rows: 1
   :widths: 28 28 44

   * - 位置
     - 抓什么
     - 应看到
   * - 话机 ↔ Call Agent
     - **TCP 2000**
     - StationOffHook / KeypadButton / CallState
   * - Call Agent ↔ Trunk/分机
     - UDP/TCP **5060**\ （sofia）
     - SIP INVITE / 200 / ACK
   * - 只抓 5060 对着话机
     - —
     - 空：话机根本不讲 SIP

两条腿用 FS uuid / ``show channels`` 关联，不要用 SCCP 消息名去对 REFER。

FreeSWITCH
--------------------

``mod_skinny`` 监听 TCP（默认 2000），在目录里把设备做成 Skinny profile。
坐席可混用：Cisco 走 Skinny，软电话走 SIP，浏览器走 Verto —— ACD 仍只看见 FS session。
新部署优先 SIP 或 WebRTC。保留 Skinny 通常因为库存和侧键习惯。

实践注意
--------------------

1. Skinny 版本多，固件要匹配；FS 支持的是常见 Station 消息子集。
2. NAT 后 TCP 2000 和 RTP 都要通；没有 SIP 的 rport / Record-Route。
3. 抓包看 TCP 2000，Wireshark 解析器名是 ``skinny``\ （或 ``sccp``\ ）。
4. 不要让话机同时向 CUCM 和 FS 注册。


Example
============

两条腿一起看：话机侧 TCP 2000，SIP 侧 sofia siptrace。

.. code-block:: bash

    fs_cli -x "load mod_skinny"
    fs_cli -x "skinny status"
    fs_cli -x "sofia global siptrace on"
    sudo tcpdump -ni any tcp port 2000 -w skinny.pcap

话机指向 FS 的 Skinny 端口并注册后，``skinny status`` 应列出设备。
摘机拨 SIP 分机 1002：

1. ``skinny.pcap``\ ：StationOffHook、KeypadButton（1、0、0、2）、CallState —— **没有** ``INVITE sip:``
2. sofia siptrace：FS 向 1002 **发出** INVITE（另一条腿，Call-ID 是 SIP 的）
3. Wireshark：话机 pcap 过滤 ``skinny``\ ；不要用 ``sip`` 对着 TCP 2000

若 TCP 2000 无流量而 5060 上有 REGISTER，这台话机走的是 SIP firmware，不是 Skinny。
设备 XML 目录格式见 :doc:`../7.practice/freeswitch_architecture` 与当前 mod_skinny 文档（字段名以你的版本为准）。


Conclusion
============

* 话机侧抓 TCP 2000；SIP INVITE 在另一条腿。
* 混布时 ACD 只认 FS session，不认 SCCP 消息名。
* 新项目不要把 Skinny 当默认坐席信令。


Reference
============

* :doc:`sip_core`
* :doc:`../7.practice/freeswitch_architecture`
