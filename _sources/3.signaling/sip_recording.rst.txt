################
SIPREC 通话录音
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

SIPREC（`RFC7866`_\ ）用 SIP/SDP 把通话媒体和元数据送给录音服务器。

Abstract
------------

SRC（Session Recording Client）在通话路径上（呼叫中心常是 FreeSWITCH/SBC）；SRS 负责存储和索引。
不只录 RTP，还带 recording metadata、indication、preferences。
元数据格式见 `RFC7865`_\ 。


Why
============

* 企业呼叫中心几乎必须录音；没有标准接口就和质检/合规平台绑死在本地文件上。
* 只录 RTP 不分轨、不带元数据，转接后质检会对不上人。
* 不提示“正在录音”可能违反各地告知义务（法律本身待业务确认）。


How
============

架构：SRC / SRS
--------------------

.. mermaid::

   flowchart TB
     Cust[Customer] --- FS["FreeSWITCH<br/>SRC"]
     FS --- Agent[Agent]
     FS -->|"SIPREC Recording Session<br/>另一条 SIP dialog"| SRS["Recording Server (SRS)"]

* **SRC**\ ：把媒体和元数据送给 SRS（呼叫中心里几乎总是 FreeSWITCH 或 SBC，不是话机、更不是浏览器）
* **SRS**\ ：接收、存储、索引

有两条 SIP 会话，不要当成一条：

.. mermaid::

   flowchart TB
     subgraph CS["CS Communication Session Call-ID cs-..."]
       C[Customer] --- F1[FS] --- A[Agent]
     end
     subgraph RS["RS Recording Session Call-ID rec-..."]
       F2["FS SRC"] -->|"另一条 INVITE"| SRS[SRS]
     end

规范覆盖：Recorded Media、Recording Metadata、Recording Indications、Recording Preferences、SIP handling、SDP handling。
录音会话通常是 SRC 向 SRS 发 INVITE，SDP 里用 ``a=label`` / metadata 把混音或 customer/agent 分轨关联起来。CS 侧 SDP 可能出现 ``a=record:on``\ （indication）。

SIPREC vs record_session
--------------------------

FreeSWITCH 也可以 ``record_session`` 直接写文件，不走 SIPREC。

.. list-table:: 录音方式
   :header-rows: 1
   :widths: 24 76

   * - 方式
     - 特点
   * - 本地 ``record_session``
     - 简单，和 FS 绑定，集群要自己同步文件；**没有** SRC/SRS dialog，挂机后只剩 wav
   * - SIPREC
     - 标准、可对接专业 SRS、元数据完整、便于合规；抓包应看到对 SRS 的第二条 INVITE
   * - 分叉 RTP（非标准）
     - SBC 直接复制 RTP，信令弱，索引靠外部关联

合规要求高（金融、医疗、质检平台）时，SIPREC 更值得做成标准接口。单机试用、没有 SRS 时，先把 ``record_session`` 跑通，不要用假 SRS URL 占位。

转接后必须更新 metadata
--------------------------

`RFC7865`_ 的 metadata（常见 ``Content-Type: application/rs-metadata+xml``\ ）描述 CS 里有哪些 participant / stream。
转接（见 :doc:`sip_refer`\ ）之后坐席换了，Call-ID 在 B2BUA 两侧本就不同；若 SRC 不把新坐席写进 RS 的 metadata 快照，质检会把转接前后当成两通无关的电话，或一直显示转接前的工号。

`RFC7866`_ 允许 SRC 用 INFO 或 UPDATE/re-INVITE 向 SRS 发送更新后的 metadata。抓 RS 这条 dialog：转接完成后应再出现带 ``rs-metadata`` 的请求，participant 从 Agent A 变成 Agent B。

实践注意
--------------------

1. 是否给用户放提示音属于法律/业务；SIPREC 提供 indication 机制。
2. 转接后 SRC 要更新 metadata，否则质检会把转接前后当成两通无关的电话。
3. 立体声（坐席/客户分轨）比混音更利于质检和 ASR。
4. WebRTC 经 FS 网关时，SRC 仍在 FS 侧，浏览器无感知。


Example
============

本地录音（可立即验证，不依赖 SRS）：

.. code-block:: xml

    <action application="record_session" data="/tmp/${uuid}.wav"/>

.. code-block:: bash

    fs_cli -x "uuid_record <uuid> start /tmp/${uuid}.wav"
    # 挂机后：
    soxi /tmp/<uuid>.wav

SIPREC 则是 SRC→SRS 的第二条 INVITE（Call-ID 与客户腿不同）。对 SRS 的 INVITE ``Content-Type`` 常是 ``multipart/mixed``\ ，里面同时有 SDP 和 metadata（``application/rs-metadata+xml``\ ；SDP 属性以 `RFC7866`_ 与你的 SRS 为准）。

抓包对照：

.. code-block:: text

    # CS：客户 / 坐席腿
    INVITE sip:1001@192.168.1.30 SIP/2.0
    Call-ID: cs-customer-agent@fs

    # RS：SRC → SRS（另一个 Call-ID，不要用客户腿的 Call-ID 去 SRS 上找）
    INVITE sip:recorder@srs.example.com SIP/2.0
    Call-ID: rec-uuid@fs
    Content-Type: multipart/mixed;boundary=...
    #  part: application/sdp          ← 录音 RTP
    #  part: application/rs-metadata+xml

转接后再看 **同一条 RS dialog**\ （同一个 rec Call-ID）是否出现 INFO 或 UPDATE，体里 participant 是否换成新坐席。无 SRS 时不要用假 URL 占位；先把本地 record 跑通，再对接 SRS。


Conclusion
============

* 本地 wav 是 record_session；对 SRS、且 Call-ID 与通话腿不同的那条 INVITE 才是 SIPREC。
* 元数据和分轨比“有没有 wav”更重要；转接后 SRC 必须更新 rs-metadata。
* SRC 在 FreeSWITCH/SBC，SRS 只收媒体+元数据；浏览器不是 SRC。


Reference
============

* `RFC7866`_
* `RFC7865`_
