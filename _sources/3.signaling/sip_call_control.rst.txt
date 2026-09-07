########################
SIP Call Control 框架
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

`RFC5359`_ 用完整 call flow 演示电话业务；`RFC5850`_ 说明这些 SIP primitive 该怎样组合成多方呼叫控制。

Abstract
------------

学完 REFER、Replaces、3PCC 之后，问题变成：同一个功能可以用不同组合实现。
RFC 5359 是电话业务的 SIP 剧本（Hold、Transfer、Conference、Park、Pickup、Click-to-Dial）。
RFC 5850 引入 Media Intermediary（mixer、queue、IVR），并警告互操作成本。


Why
============

* 只读单个 header RFC，看不到“按键如何变成信令组合”。
* 同一转接在 A 厂用 REFER、B 厂用 3PCC，两端都“符合 SIP”却不通。
* 不把 Queue/Mixer/IVR 当成媒体中介，会误把应用层功能当成缺失的 SIP 方法。


How
============

RFC 5359：用例子学业务
------------------------

不要把它当成又一个 header 规范。至少对照：

.. list-table:: RFC 5359 中与呼叫中心相关的例子
   :header-rows: 1
   :widths: 28 72

   * - 业务
     - SIP 机制
   * - Call Hold
     - re-INVITE / UPDATE + sendonly
   * - Blind Transfer
     - REFER
   * - Attended Transfer
     - REFER + Replaces
   * - 3-way Conference
     - INVITE 到会议焦点 + Join / REFER
   * - Call Park / Pickup
     - REFER 到 park URI，再 INVITE 取回
   * - Click-to-Dial
     - 3PCC

读 RFC 5359 比单独读 RFC 3515 更快建立“这些 primitive 怎样变成电话键”的直觉。

RFC 5850：多方与媒体中介
--------------------------

复杂呼叫 = 若干 UA + 若干 **Media Intermediary**\ ：

.. mermaid::

   flowchart TB
     MI[Media Intermediary]
     MI --> Mixer[Mixer<br/>会议混音]
     MI --> TC["Transcoder<br/>Opus ↔ G.711"]
     MI --> MR["Media Relay<br/>中继 / NAT"]
     MI --> QS[Queue Server<br/>排队音]
     MI --> PP[Parking Place<br/>呼叫驻留]
     MI --> Ann["Announcement / Voice Dialog<br/>IVR"]

这已经非常接近现代呼叫中心：

.. mermaid::

   flowchart TB
     App[SIP Application]
     App --> Queue[Queue]
     App --> Mixer[Mixer]
     App --> IVR[IVR]
     Queue --> Agent[Agent]
     Mixer --> Conf[Conference]
     IVR --> ASR[ASR/TTS]

FreeSWITCH 里，这些中介大多是同一进程里的不同 session / 应用（playback、conference、fifo、callcenter），对外仍是 SIP B2BUA。
排队不是一种 SIP 方法：客户腿停在 Queue Server 上听 MOH，ACD 再 3PCC 出一条坐席腿。会议焦点见 :doc:`sip_conference`\ 。

为什么“都符合 SIP 却不通”
----------------------------

同一个 Call Control feature 可以用不同 SIP primitives 组合实现。例如“把 A 转给 B”可以是：

1. A 发 REFER 给 Customer
2. A 发 REFER 给 B，带 Replaces
3. CTI 做 3PCC，分别 INVITE
4. 应用层 hangup A，originate B，bridge

对端若只实现了其中一种，互通就失败。呼叫中心作为 B2BUA 的价值之一，就是把内部统一成一种实现，对外适配多种话机 / Trunk 行为。

和本章其他文档的关系
--------------------

* 转接细节：:doc:`sip_refer`
* 第三方控制：:doc:`sip_3pcc`
* 会议：:doc:`sip_conference`
* 端到端业务地图：:doc:`sip_call_center`
* SIP RFC 导航：`RFC5411`_


Example
============

对照 RFC 5359 的 Hold：通话已建立后，保持方发 **同一 dialog** 的 re-INVITE，SDP 方向改为 ``a=sendonly``\ 。
在 FS 上用 ``uuid_hold`` 可复现（比“按 Hold 键”更可重复）：

.. code-block:: bash

    fs_cli -x "sofia global siptrace on"
    fs_cli -x "show channels"
    fs_cli -x "uuid_hold <uuid-of-1001>"

应看到类似（CSeq 比原 INVITE 大，Call-ID / tags 不变）：

.. code-block:: text

    INVITE sip:1002@192.168.1.21:5060 SIP/2.0
    Via: SIP/2.0/UDP 192.168.1.10:5060;branch=z9hG4bK-hold
    From: <sip:1001@192.168.1.10>;tag=aaa
    To: <sip:1002@192.168.1.10>;tag=bbb
    Call-ID: dlg-1-2@192.168.1.10
    CSeq: 2 INVITE
    Contact: <sip:1001@192.168.1.10:5060>
    Content-Type: application/sdp
    Content-Length: 138

    v=0
    o=FreeSWITCH 1 2 IN IP4 192.168.1.10
    s=-
    c=IN IP4 192.168.1.10
    t=0 0
    m=audio 12000 RTP/AVP 0
    a=rtpmap:0 PCMU/8000
    a=sendonly

    SIP/2.0 200 OK
    From: <sip:1001@192.168.1.10>;tag=aaa
    To: <sip:1002@192.168.1.10>;tag=bbb
    Call-ID: dlg-1-2@192.168.1.10
    CSeq: 2 INVITE
    Content-Type: application/sdp

    v=0
    o=- 8 9 IN IP4 192.168.1.21
    s=-
    c=IN IP4 192.168.1.21
    t=0 0
    m=audio 13000 RTP/AVP 0
    a=rtpmap:0 PCMU/8000
    a=recvonly

200 OK 应对 ``recvonly`` 或 ``sendrecv``\ （实现各异，但方向必须配对）。
取消保持：

.. code-block:: bash

    fs_cli -x "uuid_hold off <uuid-of-1001>"

再发一条 re-INVITE，``a=sendrecv``\ ，CSeq 再加一。
有的 UA 用 UPDATE 而不是 re-INVITE，语义相同，见 :doc:`sip_sdp`\ 。
转接例子见 :doc:`sip_refer`\ ；Click-to-Dial 见 :doc:`sip_3pcc`\ 。完整报文以 RFC 5359 原文为准。


Conclusion
============

* 同一业务至少有 REFER / 3PCC / ESL 三条路，对端只实现一条就会不通。
* Hold 是 re-INVITE 改 ``a=sendonly``\ ，不是新 SIP 方法。
* Queue / Mixer / IVR 是媒体中介，不是缺失的 SIP 方法。


Reference
============

* `RFC5359`_
* `RFC5850`_
* `RFC5411`_
