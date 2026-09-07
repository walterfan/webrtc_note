################
DTMF 与 IVR
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

IVR 按键通常走 RTP telephone-event（`RFC4733`_\ ），不是靠听 PCM 音频。

Abstract
------------

RFC 4733 取代 RFC 2833。SDP 声明 ``telephone-event``\ ，RTP payload 带 event 编号和 end bit。
FreeSWITCH 呼叫中心必须把 SIP + SDP + RTP + RFC 4733 放在一起理解。
SIP INFO 和 in-band 是遗留/兜底，新设计不要用 INFO。


Why
============

* SDP 没协商 telephone-event，IVR 就会“按了没反应”。
* 转码后把事件拆成音频再检测，按键会丢。
* 三种 DTMF 混用且不转换，WebRTC 与 PSTN 桥接时一边能按、一边不能。


How
============

RFC 4733：IVR 听的是 end bit
------------------------------

RTP 包的 payload 携带 event 编号（0–9、*、#、A–D）、音量、时长。**end bit（E）标记按键结束。IVR 通常在收到 E=1 后才认一次按键。**

.. code-block:: text

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |     event     |E|R| volume    |          duration             |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

    event  0-9 数字, 10=*, 11=#, 12-15=A-D, 16=flash
    E=0    键还按着（重复发，刷新 duration）
    E=1    键松开；RFC 4733 建议连续重发 3 次以防丢包

IVR 侧正确做法：对同一 event，**第一次看到 E=1 记一次**\ ；后面两条冗余 end 包忽略。若在 E=0 的第一包就进菜单，用户按住不放会连跳好几级。

Wireshark 过滤 ``rtpevent``\ ：看 ``Event ID`` 和 ``End=Set``\ （end=1），不要只看有没有 PT 101。

三种 DTMF 不要混用
--------------------

.. list-table:: DTMF 传输方式
   :header-rows: 1
   :widths: 24 40 36

   * - 方式
     - 说明
     - 建议
   * - RFC 4733
     - RTP 事件包
     - **首选**
   * - SIP INFO
     - 信令带 DTMF（INFO 方法见 `RFC6086`_\ ）
     - 遗留，过 NAT/转码时偶用
   * - In-band
     - 音频里的 283/697 Hz
     - 转码后易丢，仅兜底

WebRTC 浏览器走 telephone-event；PSTN 可能是 in-band。FreeSWITCH 需要在桥接时转换。
sofia 配置里这个模式仍叫 ``rfc2833``\ （历史名），语义是 RFC 4733。

INFO 抓包常见体（Cisco / 很多 PBX，不是 4733）：

.. code-block:: text

    INFO sip:ivr@192.168.1.10 SIP/2.0
    Content-Type: application/dtmf-relay

    Signal=2
    Duration=160

新设计不要走这条路；互操作时在网关转成 telephone-event。

IVR 与媒体
--------------------

IVR 不是 SIP 方法，是应用层：播放提示音 + 收 DTMF + 跳转。

.. mermaid::

   flowchart TB
     A["INVITE / 200 / ACK 建立 session"] --> B["playback welcome.wav"]
     B --> C["play_and_get_digits<br/>等 RFC 4733 的 E=1"]
     C --> D1["1 sales queue"]
     C --> D2["2 support queue"]
     C --> D3["3 billing"]

相关媒体协议：

* RTP / RTCP：:doc:`../2.transport/rtp`
* 编解码：G.711 几乎必开；Opus 见音频章节
* 转码会增加 DTMF 丢失风险，优先让 telephone-event 透传而不是解码音频再检测

实践注意
--------------------

1. SDP 没协商 101/telephone-event，IVR 就会“按了没反应”。
2. 检测时长（min/max digit timeout）是应用配置，不是 RFC。
3. 会议 / 转接后 payload type 可能变化，B2BUA 要重新映射。
4. 不要用 INFO DTMF 做新设计。


Example
============

Offer/Answer 双方都应有 101：

.. code-block:: text

    m=audio 12000 RTP/AVP 0 101
    a=rtpmap:0 PCMU/8000
    a=rtpmap:101 telephone-event/8000
    a=fmtp:101 0-16

按键 ``2`` 时，RTP 侧应类似（duration 单位是时钟滴答，8000 Hz 下 8000=1s）：

.. code-block:: text

    PT=101  event=2  E=0  duration=400
    PT=101  event=2  E=0  duration=800
    PT=101  event=2  E=1  duration=1600   ← IVR 在这里认一次 "2"
    PT=101  event=2  E=1  duration=1600   ← 冗余，不计第二次
    PT=101  event=2  E=1  duration=1600

FreeSWITCH IVR 最小可跑例子（文件路径按你的 sounds 目录改）：

.. code-block:: xml

    <extension name="ivr-dtmf">
      <condition field="destination_number" expression="^5000$">
        <action application="answer"/>
        <action application="play_and_get_digits" data="1 1 3 5000 # $${sound_prefix}/ivr/ivr-welcome.wav /invalid.wav menu_digit [1-3]"/>
        <action application="log" data="INFO pressed=${menu_digit}"/>
      </condition>
    </extension>

验证：

.. code-block:: bash

    fs_cli -x "sofia global siptrace on"
    # 拨 5000，确认 200 OK 的 m=audio 含 101
    # 按 2：Wireshark 过滤 rtpevent，event=2 且 end=1
    # fs_cli 日志出现 pressed=2

若只有 PCMU 包、没有 rtpevent：先修 SDP，再查 ``dtmf-type``\ （sofia profile）是否为 rfc2833。


Conclusion
============

* IVR 认的是 telephone-event 里 event=N 且 end=1 的那一包，不是 PCM 里的蜂音。
* 同一按键的三条 E=1 冗余包只计一次；E=0 只表示键还按着。
* 桥接时透传 telephone-event；INFO / in-band 只做互操作兜底。


Reference
============

* `RFC4733`_
* `RFC6086`_
