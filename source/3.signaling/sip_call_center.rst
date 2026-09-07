##########################
呼叫中心 SIP 协议地图
##########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

把一通呼入从进线到 CDR 串起来，每一步标出 SIP 消息、Header、RFC 和 FreeSWITCH 机制。

Abstract
------------

单独读 RFC 很慢；按业务路径对照抓包会快得多。
SIP 是呼叫控制语言，不是完整的 Contact Center 协议。Queue / Skill / Agent State / ACD 在应用层。


Why
============

* 按 RFC 编号学，进线、转接、录音对不上号。
* 把 ACD 当成“某个 SIP 方法”，会在标准里找不到东西。
* 不分层对照，抓包时不知道缺的是 PAI 还是 History-Info 还是 REFER。


How
============

端到端流程
--------------------

.. mermaid::

   flowchart LR
     A[Inbound] --> B[IVR] --> C[Queue] --> D[ACD] --> E[Agent Ring]
     E --> F[Answer] --> G[Talk] --> H["Transfer / Conference"]
     H --> I["Supervisor Barge/Whisper"] --> J[Recording]
     J --> K[Hangup] --> L[CDR]

FreeSWITCH 是 B2BUA：**每条腿一个 SIP dialog、一个 Call-ID**\ 。用地图里的 PAI / History-Info / FS uuid 关联，不要拿 Trunk 的 Call-ID 去对坐席腿。

逐步对照
--------------------

**1. Inbound（进线）**

.. list-table::
   :header-rows: 1
   :widths: 22 38 40

   * - 项目
     - 内容
     - 参考
   * - SIP
     - Trunk INVITE 到接入号（8000 / DID）
     - :doc:`sip_core`
   * - Header
     - From、PAI、Privacy、History-Info / Diversion
     - :doc:`sip_identity` :doc:`sip_history`
   * - SDP
     - G.711、telephone-event
     - :doc:`sip_sdp` :doc:`sip_dtmf`
   * - FreeSWITCH
     - sofia external profile → dialplan
     -
   * - 验证
     - siptrace 有 INVITE；PAI 有值；``m=`` 含 101
     - ``sofia global siptrace on``

**2. IVR**

.. list-table::
   :header-rows: 1
   :widths: 22 38 40

   * - 项目
     - 内容
     - 参考
   * - SIP
     - 已建立 dialog；可能 183 早期媒体
     - :doc:`sip_sdp`
   * - 媒体
     - playback + RFC 4733 DTMF
     - :doc:`sip_dtmf`
   * - 应用
     - 菜单、身份校验、语言选择
     - FS IVR / lua / ESL
   * - Header
     - 可写入后续路由用的 History-Info / 自定义 X-header
     - :doc:`sip_history`
   * - 验证
     - 仍是 Trunk 那条 Call-ID；按 1 后 log 有 dtmf/rtpevent
     - ``show channels``

**3. Queue / ACD**

.. list-table::
   :header-rows: 1
   :widths: 22 38 40

   * - 项目
     - 内容
     - 参考
   * - SIP
     - 对主叫保持 session，放排队音（early 或已接通）
     - B2BUA 媒体中介
   * - Header
     - 溢出时追加 History-Info
     - :doc:`sip_history` `RFC7131`_
   * - 应用
     - fifo / mod_callcenter：技能、优先级、SLA
     - **非 SIP**
   * - 坐席侧
     - 此时 Agent 可能尚无 SIP dialog
     -
   * - 验证
     - 队列里有人；1001 还没有第二条 INVITE
     - ``callcenter_config queue list`` / ``fifo list``

**4. Agent Ring / Answer**

.. list-table::
   :header-rows: 1
   :widths: 22 38 40

   * - 项目
     - 内容
     - 参考
   * - SIP
     - FS originate / INVITE 坐席；200 + ACK 后 bridge
     - :doc:`sip_3pcc`
   * - Header
     - 弹屏：PAI、History-Info、UUI / 自定义
     - :doc:`sip_identity`
   * - Dialog Event
     - 可选 SUBSCRIBE 看坐席是否振铃/通话
     - :doc:`sip_events`
   * - 应用
     - Agent state: Available → Ringing → Talking
     - 不要用 dialog 代替
   * - 验证
     - 第二条 INVITE（To: 1001），Call-ID ≠ Trunk 腿
     - ``show calls``

**5. Talk（通话中）**

.. list-table::
   :header-rows: 1
   :widths: 22 38 40

   * - 项目
     - 内容
     - 参考
   * - 媒体
     - RTP / SRTP，可能转码
     - :doc:`../2.transport/rtp`
   * - 保活
     - Session-Expires UPDATE
     - :doc:`sip_session_timer`
   * - 录音
     - SRC INVITE SRS（SIPREC）或本地 record
     - :doc:`sip_recording`
   * - DTMF
     - 通话中二次收号（验证码等）
     - :doc:`sip_dtmf`
   * - 验证
     - 两腿 bridged；SIPREC 则第三条 INVITE 到 SRS
     - ``show channels`` / ``uuid_dump <uuid>``

**6. Transfer**

.. list-table::
   :header-rows: 1
   :widths: 22 38 40

   * - 项目
     - 内容
     - 参考
   * - 盲转
     - REFER 或 FS transfer 应用
     - :doc:`sip_refer`
   * - 咨询转
     - 先咨询 INVITE，再 REFER + Replaces
     - RFC 3891
   * - CTI 转
     - ESL 控制 3PCC，话机不发 REFER
     - :doc:`sip_3pcc`
   * - 历史
     - 更新 History-Info / Referred-By
     - :doc:`sip_history`
   * - 验证
     - 盲转：REFER 或 ``uuid_transfer``\ ；咨询转：Replaces
     - siptrace 搜 REFER / Replaces

**7. Supervisor Barge / Whisper**

.. list-table::
   :header-rows: 1
   :widths: 22 38 40

   * - 项目
     - 内容
     - 参考
   * - 机制
     - 把通话迁入 conference；主管以 mute/coach/hear 加入
     - :doc:`sip_conference`
   * - SIP
     - 主管 INVITE 会议焦点；客户/坐席可能 re-INVITE 改媒体
     - RFC 4575 / 5850
   * - 应用
     - eavesdrop / conference member flags
     - FS 应用层
   * - 验证
     - 会议里 ≥3 成员，或 eavesdrop 通道
     - ``conference list``

**8. Hangup → CDR**

.. list-table::
   :header-rows: 1
   :widths: 22 38 40

   * - 项目
     - 内容
     - 参考
   * - SIP
     - BYE 或 4xx/5xx/CANCEL
     - :doc:`sip_core`
   * - Reason
     - SIP cause + Q.850
     - :doc:`sip_reason`
   * - 应用
     - Agent → ACW / Available；写 CDR / 录音索引
     - hangup_cause
   * - 分析
     - 区分用户挂机、排队放弃、坐席拒接、网关失败
     -
   * - 验证
     - BYE/CANCEL 带 Reason；CDR ``hangup_cause`` 能对上
     - csv/xml CDR 或 ``show`` 挂断日志

一张总图
--------------------

.. mermaid::

   flowchart TB
     CC[Contact Center]
     CC --> ACD[ACD]
     CC --> CTI[CTI]
     CC --> Sup[Supervisor]
     ACD --> Ctrl[Call Control]
     CTI --> Ctrl
     Sup --> Ctrl
     Ctrl --> SIP[SIP]
     Ctrl --> SDP[SDP]
     Ctrl --> RTP[RTP]
     SIP --> INVITE[INVITE]
     SIP --> REFER[REFER]
     SIP --> Ev[Events]
     REFER --> Repl[Replaces]
     SIP --> HI[History-Info]
     SIP --> PAI[PAI]
     SIP --> Reason[Reason]
     SIP --> SIPREC[SIPREC]
     SDP --> Codec[Codec/Media]
     RTP --> VV[Voice/Video]
     Ctrl --> FS[FreeSWITCH]
     FS --> Phone[SIP Phone]
     FS --> Trunk[SIP Trunk]
     FS --> Web[WebRTC]

学习路径回顾
--------------------

按阶段而不是按编号，详见 :doc:`overview`\ ：

1. SIP 基础：3261 / 3264 / 4566
2. Call Control：3515 / 3891 / 3892 / 3725
3. Routing 信息：7044 / 4235 / 3325 / 3326
4. Media / IVR：4733 + RTP
5. Recording / Conference：7866 / 4575 / 5850
6. PSTN：PAI、Q.850、STIR/SHAKEN、SBC

配合实践章节：:doc:`../7.practice/freeswitch_overview`\ 、:doc:`../7.practice/freeswitch_sip`\ 、:doc:`../7.practice/freeswitch_ivr`\ 。


Example
============

号码换成你的 DID / 分机。先开跟踪，再打一通完整路径：

.. code-block:: bash

    fs_cli -x "sofia global siptrace on"
    fs_cli -x "console loglevel debug"
    # 可选：sngrep -d any port 5060
    # 路径：Trunk → 8000 → IVR 按 1 → 排队 → 1001 接听 → 转 1002 → 挂机

按 8 步勾选（缺哪步只读该步的表，不要重读全部 RFC）：

**1. Inbound**

.. code-block:: bash

    # siptrace 应出现 Trunk INVITE
    # 必看：P-Asserted-Identity 有 E.164；SDP 含 a=rtpmap:101 telephone-event

**2. IVR**

.. code-block:: bash

    fs_cli -x "show channels"
    # 仍是 Trunk 那条 Call-ID（尚未 originate 坐席）
    # 按 1 后 console 有 dtmf 或 RTP payload 101（RFC 4733），不是 SIP INFO（除非你配了）

**3. Queue / ACD**

.. code-block:: bash

    fs_cli -x "callcenter_config queue list"
    # 或：fs_cli -x "fifo list"
    # 队列 members/waiting ≥ 1；此时 grep INVITE 不应出现 To: sip:1001（坐席尚未振铃）

**4. Agent Ring / Answer**

.. code-block:: bash

    fs_cli -x "show calls"
    # siptrace：第二条 INVITE，Request-URI/To 是 1001
    # Call-ID 与步骤 1 不同（B2BUA）；弹屏 PAI 应与进线一致

**5. Talk**

.. code-block:: bash

    fs_cli -x "show channels"
    # 两腿 bridged；若开 SIPREC，第三条 INVITE 打向 SRS（Content-Type: multipart/mixed）
    # 若配了 Session Timer，应看到 UPDATE 或 re-INVITE 带 Session-Expires

**6. Transfer**

.. code-block:: bash

    # 盲转：siptrace 搜 REFER，或 ESL uuid_transfer
    # 咨询转：先有打向 1002 的 INVITE，再 REFER 且头域含 Replaces
    # CTI 转：话机腿可以没有 REFER，FS 自己 originate + bridge

**7. Supervisor（若测 barge/whisper）**

.. code-block:: bash

    fs_cli -x "conference list"
    # 会议焦点有客户、坐席、主管；whisper 则主管 member flags 含 mute 或 coach

**8. Hangup → CDR**

.. code-block:: bash

    # BYE 或 CANCEL 上有 Reason（SIP + 可选 Q.850）
    # CDR hangup_cause 对照：
    #   用户挂机     NORMAL_CLEARING
    #   排队放弃     ORIGINATOR_CANCEL
    #   坐席拒接     USER_BUSY / CALL_REJECTED
    #   网关失败     NO_ROUTE_DESTINATION / RECOVERY_ON_TIMER_EXPIRE

关联键：Trunk Call-ID ≠ Agent Call-ID。用 ``show channels`` 的 uuid、PAI、History-Info 把 8 步串起来。


Conclusion
============

* 先按这 8 步抓包，再按表回查 RFC。
* ACD / Agent State 永远在应用层。
* B2BUA 每条腿一个 dialog，用 PAI / History-Info / uuid 关联。


Reference
============

* `RFC5411`_
* `RFC5359`_
* `RFC5850`_
* `RFC7131`_
