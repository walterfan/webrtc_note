################
SIP 与 SDP
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

SDP 描述媒体；SIP 用 Offer/Answer（`RFC3264`_\ ）交换这份描述。

Abstract
------------

格式见 `RFC4566`_\ （及其后继）。INVITE 带 offer，200 OK 带 answer；delayed offer 则 200 带 offer、ACK 带 answer。
re-INVITE / UPDATE 改已有 session，183 可带早期媒体。
WebRTC 侧 SDP 细节见 :doc:`../1.basic/webrtc_sdp`\ ；本章讲 **SIP 呼叫里 SDP 怎么走**\ 。


Why
============

* codec 没交集 → 488 Not Acceptable Here，电话响了但没有声音。
* 没协商 telephone-event → IVR 按键无反应。
* Hold / 早期媒体 / 排队音改错 SDP → 客户听到静音或对端拒保持。


How
============

Offer/Answer 绑在哪条 SIP 消息上
----------------------------------

.. list-table:: Offer/Answer 绑定
   :header-rows: 1
   :widths: 24 38 38

   * - 消息
     - 经典
     - Delayed offer
   * - INVITE
     - **offer**
     - 无 SDP
   * - 183
     - 可带早期媒体 SDP
     - 可带早期媒体 SDP
   * - 200 OK
     - **answer**
     - **offer**
   * - ACK
     - 通常无 SDP
     - **answer**
   * - re-INVITE / UPDATE
     - 已有 session 上的新 offer
     - 同左

抓包时先问：这条消息该带 offer 还是 answer？带错了，后面的 RTP 地址、codec、DTMF 全会错。

* 经典：INVITE = offer，200 OK = answer，ACK 通常无 SDP
* Delayed offer：INVITE 不带 SDP，200 OK 带 offer，ACK 带 answer。FreeSWITCH / 网关对接时偶尔会遇到
* re-INVITE / UPDATE：改 codec、端口、Hold、ICE restart、Session Timer 刷新
* 早期媒体：183 Session Progress 可带 SDP（排队音、彩铃）；需要 PRACK（100rel，`RFC3262`_\ ）时临时响应必须可靠确认

Hold 常见写法：``a=sendonly`` / ``a=inactive``\ 。旧设备还有 ``c=0.0.0.0``\ 。`RFC5359`_ 给了推荐 flow。

UPDATE 与 re-INVITE
--------------------

* **re-INVITE**\ ：会刷新 dialog 目标，可能改变 Contact；有事务 glare（双方同时 re-INVITE）
* **UPDATE（`RFC3311`_）**\ ：可在 early dialog 更新 SDP，不改变 dialog 路由；Session Timer 刷新更常用 UPDATE

呼叫中心建议：纯媒体参数更新优先 UPDATE；需要改目标或兼容老 UA 再用 re-INVITE。

SDP 最小结构
--------------------

.. code-block:: text

    v=0
    o=- 123 456 IN IP4 192.0.2.1
    s=-
    c=IN IP4 192.0.2.1
    t=0 0
    m=audio 12000 RTP/AVP 0 8 101
    a=rtpmap:0 PCMU/8000
    a=rtpmap:8 PCMA/8000
    a=rtpmap:101 telephone-event/8000
    a=fmtp:101 0-16
    a=sendrecv

呼叫中心音频侧最常见：

* G.711 PCMU/PCMA（payload 0/8）—— PSTN / SIP Trunk 几乎必有
* telephone-event —— DTMF，见 :doc:`sip_dtmf`
* Opus —— WebRTC 侧；经 FreeSWITCH 时经常要转码到 G.711

电话 SDP vs WebRTC SDP
------------------------

.. list-table::
   :header-rows: 1
   :widths: 28 36 36

   * - 项目
     - 传统 SIP
     - WebRTC
   * - 传输
     - RTP/AVP、RTP/SAVP
     - UDP/TLS/RTP/SAVPF
   * - 地址
     - ``c=`` / ``m=`` 端口是真实地址
     - 常为 9 / 0.0.0.0，真正路径靠 ICE
   * - 安全
     - 可选 SDES 或明文
     - 强制 DTLS-SRTP + fingerprint
   * - ICE
     - 可选
     - 必须
   * - BUNDLE / rtcp-mux
     - 传统电话常 RTP/RTCP 分端口
     - 几乎总是 mux + bundle
   * - DTMF
     - RFC 4733 或 SIP INFO
     - RFC 4733 telephone-event

FreeSWITCH 做 WebRTC 网关时，本质就是两边 SDP 的翻译 + 媒体转码。实践见 :doc:`../7.practice/freeswitch_sip`\ 。

呼叫中心里 SDP 容易出的问题
------------------------------

同一条 INVITE，两种完全不同的失败，抓包签名也不一样：

.. code-block:: text

    488  —— 根本没有 200
    Offer:  m=audio ... 96 101          WebRTC Opus + telephone-event
    对端:  只认 0 / 8                   SIP Trunk G.711
              ↓
         488 Not Acceptable Here
    siptrace：INVITE 的 m= 与对端 codec 无交集
    处理：FS 转码，不要把 WebRTC SDP 原样转给 Trunk

    DTMF 死 —— 有 200，IVR 按键无反应
    Offer:  m=audio ... 0 8 101
    Answer: m=audio ... 0 8             ← 101 被吃掉
              ↓
         没有 RTP telephone-event
    Wireshark：rtp.p_type == 101 为空
    处理：answer 必须保留 101 和 a=fmtp:101 0-16

其余常见坑：

1. **Codec 谈不拢 → 488**\ ：Trunk 只开 G.711，WebRTC 只出 Opus，中间必须有转码器。
2. **DTMF 未协商 telephone-event**\ ：IVR 收不到按键。
3. **Hold 实现不统一**\ ：有的用 ``a=sendonly``\ ，有的改 ``c=0.0.0.0``\ 。
4. **早期媒体和录音/排队音抢 SDP**\ ：B2BUA 要对 Caller 播放 queue music，对 Agent 另建 session，不能当成透明转发。
5. **p-time / maxptime 不一致**\ ：PSTN 侧常 20 ms；设错会造成声音卡顿。


Example
============

IVR 侧 200 OK 必须仍包含 telephone-event，否则按键无效。用 siptrace 核对 answer：

.. code-block:: bash

    fs_cli -x "sofia global siptrace on"

Answer 里应类似：

.. code-block:: text

    SIP/2.0 200 OK
    From: <sip:customer@trunk.example.com>;tag=a
    To: <sip:8000@192.168.1.10>;tag=b
    Call-ID: 1h23@trunk
    CSeq: 1 INVITE
    Content-Type: application/sdp

    v=0
    o=- 2 2 IN IP4 192.168.1.10
    s=-
    c=IN IP4 192.168.1.10
    t=0 0
    m=audio 20000 RTP/AVP 0 8 101
    a=rtpmap:0 PCMU/8000
    a=rtpmap:8 PCMA/8000
    a=rtpmap:101 telephone-event/8000
    a=fmtp:101 0-16
    a=sendrecv

对照同一条 INVITE 的两种失败：

* **488**\ ：200 根本没回来。把 INVITE 的 ``m=`` 行与对端能力对一下，没有 payload 交集就是谈不拢。
* **200 有了但 IVR 无按键**\ ：answer 的 ``m=`` 行没有 ``101``\ ，或 ``a=rtpmap:101`` 被吃掉。

验证 DTMF：Wireshark 过滤 ``rtpevent``\ （或 ``rtp.p_type == 101``\ ），按 2 应看到 event=2 的包，end bit 置位后再认键。
不要靠听 PCMU 里的 941+1336 Hz。Hold 时再抓一次 re-INVITE，``a=`` 应变为 ``sendonly`` 或 ``inactive``\ 。


Conclusion
============

* 488 先对 INVITE 与应答的 ``m=`` 行：没有 payload 交集就谈不拢，再问要不要转码。
* Answer 丢掉 101，IVR 就收不到 RFC 4733；Wireshark 滤 ``rtp.p_type == 101``\ 。
* WebRTC SDP 不能原样转给 SIP Trunk；Hold 看 ``a=sendonly``\ ，排队音看 183。


Reference
============

* `RFC3264`_
* `RFC4566`_
* `RFC3311`_
* `RFC3262`_
* `RFC5359`_
* :doc:`../1.basic/webrtc_sdp`
