################
REFER 与呼叫转接
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

REFER（`RFC3515`_\ ）请对端代发一个新请求；和 Replaces（`RFC3891`_\ ）、Referred-By（`RFC3892`_\ ）一起构成 SIP 转接。

Abstract
------------

盲转主要靠 REFER；咨询转靠 REFER + Replaces。
转接成没成，看 NOTIFY 的 ``message/sipfrag`` 状态行，不看第一条腿的 BYE。
FreeSWITCH 作为 B2BUA 时，常常是自己去 INVITE 目标，而不是让客户 UA 真的发 INVITE。


Why
============

* 呼叫中心没有转接就做不成排队溢出后的人工接力、销售转接、升级专家。
* 只实现盲转、不认 Replaces，咨询转会变成“两腿都在、客户进不去”。
* 转接失败只看 BYE、不看 NOTIFY sipfrag，会把“A 已挂机”误判成“已经转走”。


How
============

三件套
--------------------

* `RFC3515`_ — “请另外一个 UA 帮我发起一个新请求”
* `RFC3891`_ — 用新 dialog 替换旧 dialog（Attended Transfer 的关键）
* `RFC3892`_ — 标明是谁发起的转接

建议把 ``REFER`` / ``Replaces`` / ``Referred-By`` 放在一起理解。

NOTIFY sipfrag 是排障钥匙
----------------------------

REFER 被 202 接受后，会在**同一 dialog** 上隐式订阅 ``Event: refer``\ 。
执行进度用 NOTIFY 推送，``Content-Type: message/sipfrag``\ ，body 就是目标呼叫的 SIP 状态行：

.. list-table:: sipfrag 怎么读
   :header-rows: 1
   :widths: 28 72

   * - sipfrag
     - 含义
   * - ``SIP/2.0 100 Trying``
     - 已向目标发出 INVITE
   * - ``SIP/2.0 180 Ringing``
     - 目标在振铃
   * - ``SIP/2.0 200 OK``
     - 目标接通，转接成功；随后 ``Subscription-State: terminated``
   * - ``SIP/2.0 486/480/404``
     - 忙 / 无人接 / 不存在——转接失败
   * - 始终没有 NOTIFY
     - 对端没实现 refer 订阅（很多硬话机）

BYE 只说明 **Agent A 这条腿拆了**\ 。A 按转接键后 FS 常会马上 BYE A，此时 sipfrag 可能还是 180，甚至已经 486。
排障顺序：先对上 REFER 的 Call-ID，再读最后一条 NOTIFY 的 sipfrag。

Blind Transfer（盲转）
------------------------

Agent A 不咨询，直接把客户转给 Agent B：

.. mermaid::

   flowchart TB
     Cust[Customer] -->|Call| A[Agent A]
     A -->|REFER| B[Agent B]

典型机制：A 对 **Customer 这条腿** 发 REFER，``Refer-To`` 只有 B 的 URI，没有 Replaces。
随后 A 通过 NOTIFY 收到 sipfrag（100/180/200）。

FreeSWITCH 作为 B2BUA 时，往往是 **FreeSWITCH 自己去 INVITE B**\ ，对外仍表现为转接，对内是两条腿的替换。

盲转 call flow（B2BUA）
------------------------

.. mermaid::

   sequenceDiagram
     participant Cust as Customer
     participant FS as FreeSWITCH
     participant A as Agent A
     participant B as Agent B

     Cust->>FS: INVITE
     FS->>A: INVITE
     A->>FS: 200/ACK
     A->>FS: REFER
     FS->>A: 202
     FS->>A: NOTIFY sipfrag 100
     FS->>B: INVITE
     FS->>A: NOTIFY sipfrag 180
     B->>FS: 200
     FS->>A: NOTIFY sipfrag 200
     FS->>A: BYE
     Cust<<->>B: RTP

Attended Transfer（咨询转）
----------------------------

A 先和 B 建立咨询通话，再把 Customer 交给 B：

.. mermaid::

   flowchart TB
     subgraph consult["咨询阶段"]
       C1[Customer] --- A1[A]
       A1 --- B1[B]
     end
     subgraph done["转接完成"]
       C2[Customer] --- B2[B]
     end
     consult --> done

1. A 与 Customer 有 dialog-1（``Call-ID`` / From-tag / To-tag）
2. A 与 B 有 dialog-2（咨询）
3. A 让 Customer（或 FS）向 B 发 INVITE，``Refer-To`` 里带 ``Replaces``\ ，指向 **dialog-2**
4. B 接受后挂掉与 A 的咨询通话，Customer 与 B 连通
5. A 退出

``Replaces`` 的语义：请用这个新 INVITE 替换我已经有的那个 dialog。
目标 dialog 不存在——三元组错一个——通常回 **481** 或 603。
RFC 3891 明确把 attended transfer 作为典型使用场景。

咨询转 call flow（B2BUA）
--------------------------

.. mermaid::

   sequenceDiagram
     participant Cust as Customer
     participant FS as FreeSWITCH
     participant A as Agent A
     participant B as Agent B

     Note over Cust,A: dialog-1
     FS->>B: dialog-2 咨询
     A->>FS: REFER
     Note right of FS: Refer-To B?Replaces=dialog-2
     FS->>B: INVITE + Replaces
     B->>FS: 200
     FS->>B: BYE (dialog-2)
     FS->>A: BYE
     Note over Cust,B: dialog-1' 媒体到 B

Refer-To 里的 Replaces
------------------------

话机发出的是 **URI 转义后的 Refer-To**\ ；真正打到 B 的 INVITE 才有独立的 ``Replaces`` header。
两者必须指向**同一个**\ 咨询 dialog：

.. code-block:: text

    Refer-To  (A → FS，query 已转义)
      <sip:1002@192.168.1.10?Replaces=dlg-a-b%3Bto-tag%3Dbbb%3Bfrom-tag%3Daaa>

    解码后
      Replaces=dlg-a-b;to-tag=bbb;from-tag=aaa

    落地 INVITE (FS → B)
      Replaces: dlg-a-b;to-tag=bbb;from-tag=aaa

``%3B`` 是 ``;``\ ，``%3D`` 是 ``=``\ 。抓包时先 URL-decode 再和 B 侧 INVITE 对照。
``Call-ID``\ 、``to-tag``\ 、``from-tag`` 必须是 **A↔B 咨询腿** 的三元组，不是客户腿的。

Referred-By
--------------------

让被转接方知道“是谁把这个电话转过来的”：弹屏、CDR 转接链、质检关联。可带签名，实际部署较少。
B 侧 INVITE 上应能看到 ``Referred-By: <sip:1001@...>``\ 。

和其他机制的关系
--------------------

* **Join（RFC 3911）**\ ：把一个 dialog 加入另一个，用于会议式转接，没有 Replaces 那么常见
* **3PCC（`RFC3725`_）**\ ：CTI 自己发两条 INVITE，话机上 **没有 REFER**\ 。见 :doc:`sip_3pcc`
* **`RFC5359`_**\ ：Hold / Transfer / Call Park 的完整例子。见 :doc:`sip_call_control`

同一业务（转接）至少有 REFER、3PCC、应用层 ESL 三条实现路径。这正是 RFC 5850 说的：SIP 灵活，但互操作成本高。

实践注意
--------------------

1. 很多硬话机对 REFER 支持不完整：不发 NOTIFY、不认 Replaces、或只支持盲转。
2. WebRTC 浏览器通常不懂 REFER；FreeSWITCH 必须在服务端完成转接，浏览器只看到自己这条腿被 hangup / 重新 INVITE。
3. 转接失败要看最后一条 NOTIFY 的 sipfrag，不要只看第一条腿的 BYE。
4. 录音 / 质检需要知道转接后 Call-ID 变了（B2BUA 两侧本来就不同）。History-Info 可以保留路由痕迹，见 :doc:`sip_history`\ 。


Example
============

盲转：在 siptrace 里应对上 **同一 dialog** 的 REFER → 202 → NOTIFY(sipfrag)。
把 URI 换成你的分机后可直接对照：

.. code-block:: text

    REFER sip:customer@192.168.1.10:5060 SIP/2.0
    Via: SIP/2.0/UDP 192.168.1.30:5060;branch=z9hG4bK-ref
    From: <sip:1001@192.168.1.10>;tag=aaa
    To: <sip:customer@192.168.1.10>;tag=ccc
    Call-ID: dlg-customer-a@192.168.1.10
    CSeq: 3 REFER
    Refer-To: <sip:1002@192.168.1.10>
    Referred-By: <sip:1001@192.168.1.10>
    Contact: <sip:1001@192.168.1.30:5060>
    Content-Length: 0

    SIP/2.0 202 Accepted
    From: <sip:1001@192.168.1.10>;tag=aaa
    To: <sip:customer@192.168.1.10>;tag=ccc
    Call-ID: dlg-customer-a@192.168.1.10
    CSeq: 3 REFER

    NOTIFY sip:1001@192.168.1.30:5060 SIP/2.0
    Via: SIP/2.0/UDP 192.168.1.10:5060;branch=z9hG4bK-n1
    From: <sip:customer@192.168.1.10>;tag=ccc
    To: <sip:1001@192.168.1.10>;tag=aaa
    Call-ID: dlg-customer-a@192.168.1.10
    CSeq: 1 NOTIFY
    Event: refer
    Subscription-State: active;expires=60
    Content-Type: message/sipfrag
    Content-Length: 20

    SIP/2.0 100 Trying

    NOTIFY sip:1001@192.168.1.30:5060 SIP/2.0
    Via: SIP/2.0/UDP 192.168.1.10:5060;branch=z9hG4bK-n2
    From: <sip:customer@192.168.1.10>;tag=ccc
    To: <sip:1001@192.168.1.10>;tag=aaa
    Call-ID: dlg-customer-a@192.168.1.10
    CSeq: 2 NOTIFY
    Event: refer
    Subscription-State: terminated;reason=noresource
    Content-Type: message/sipfrag
    Content-Length: 16

    SIP/2.0 200 OK

咨询转：``Refer-To`` 必须带 Replaces；随后打到 1002 的 INVITE 也必须带：

.. code-block:: text

    REFER sip:customer@192.168.1.10:5060 SIP/2.0
    From: <sip:1001@192.168.1.10>;tag=aaa
    To: <sip:customer@192.168.1.10>;tag=ccc
    Call-ID: dlg-customer-a@192.168.1.10
    CSeq: 4 REFER
    Refer-To: <sip:1002@192.168.1.10?Replaces=dlg-a-b%3Bto-tag%3Dbbb%3Bfrom-tag%3Daaa>
    Referred-By: <sip:1001@192.168.1.10>
    Content-Length: 0

    INVITE sip:1002@192.168.1.10 SIP/2.0
    From: <sip:customer@192.168.1.10>;tag=xfer
    To: <sip:1002@192.168.1.10>
    Call-ID: dlg-customer-b@192.168.1.10
    CSeq: 1 INVITE
    Replaces: dlg-a-b;to-tag=bbb;from-tag=aaa
    Referred-By: <sip:1001@192.168.1.10>
    Content-Type: application/sdp

验证：

.. code-block:: bash

    fs_cli -x "sofia global siptrace on"
    # 盲转：1001 通话中 transfer 到 1002
    #   1) REFER 与 NOTIFY 的 Call-ID 相同
    #   2) 最后一条 sipfrag 是 200，而不是只看到对 1001 的 BYE
    # 咨询转：1001 先打 1002，再转接
    #   3) Refer-To 含 Replaces=...%3Bto-tag%3D...
    #   4) 1002 的 INVITE 有明文 Replaces 头，三元组对上咨询腿
    #   5) 三元组错了：1002 回 481

FreeSWITCH 侧也可用 ``uuid_transfer`` / ESL，SIP 上仍应能看到第二条腿的 INVITE。
CTI 不发 REFER、只 originate 第二条腿，那是 3PCC，见 :doc:`sip_3pcc`\ 。


Conclusion
============

* sipfrag 不是 200，转接就没成——BYE 只能说明 A 挂了。
* Replaces 三元组错一个，B 回 481。
* 浏览器不发 REFER；WebRTC 转接必须 FS 自己 INVITE。


Reference
============

* `RFC3515`_
* `RFC3891`_
* `RFC3892`_
* `RFC5359`_
