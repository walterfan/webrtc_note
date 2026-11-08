#################
SIP Session Timer
#################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

Session Timer（`RFC4028`_\ ）给 SIP session 一个租约，到期前用 UPDATE 或 re-INVITE 刷新，确认会话还活着。

Abstract
------------

长通话中 NAT、防火墙、SBC、Proxy 状态可能丢失，双方仍以为对方在线。
关键 header：``Session-Expires``\ 、``Min-SE``\ 、``refresher=uac|uas``\ 。
它检测的是 SIP 会话，不是 RTP。


Why
============

* 呼叫中心通话常达数十分钟到数小时，中间设备掉状态会造成“幽灵通话”或计费拖死。
* SBC 与 FreeSWITCH 的 timer 不一致，会出现“莫名其妙被踢”。
* 刷新失败若不单独记 CDR，会和用户主动挂机混在一起。


How
============

机制
--------------------

* ``Session-Expires`` —— 会话租约时长（秒）。绝对值下限 90；`RFC4028`_ **建议 1800**
* ``Min-SE`` —— 可接受的最小租约；缺省 90
* ``refresher`` —— ``uac`` 或 ``uas`` 谁负责刷新

刷新手段：UPDATE（`RFC3311`_\ ，首选，尤其 early dialog）或 re-INVITE。

到期前 refresher 必须发 UPDATE/re-INVITE。对端回 200 则租约重启；失败或超时则拆掉会话。RFC 4028 建议在租约 **过半** 时刷新（1800s → 约 900s 发一次 UPDATE）。

.. code-block:: text

    t=0      INVITE  Session-Expires: 1800;refresher=uac
    t≈900    UPDATE  刷新成功 → 租约重新起算
    t=1800   若一直没刷成功 → 拆 dialog（BYE）

SIP alive ≠ RTP alive
-----------------------

Session Timer 证明的是：**SIP dialog 还能路由到对端，对方还能回 200**\ 。
它 **不** 证明麦克风、RTP、NAT 绑定还在。

.. list-table:: 两种“还活着”
   :header-rows: 1
   :widths: 28 36 36

   * - 机制
     - 抓包里看到
     - 证明什么 / 不证明什么
   * - Session Timer
     - 周期性 UPDATE/re-INVITE + ``Session-Expires``
     - SIP 对话还在；**RTP 可以已经是 0 包**
   * - 媒体超时
     - RTP/RTCP 停、FS ``media_timeout`` / hangup ``MEDIA_TIMEOUT``
     - 媒体断了；此时 UPDATE 仍可能在刷
   * - ICE consent（RFC 7675）
     - WebRTC 侧 STUN consent
     - 浏览器媒体许可；经网关时和 SIP timer 是两套

因此：RTP 已断但 SIP 还在刷 UPDATE 的情况存在，需要 RTCP / 媒体超时一起看。FreeSWITCH 文档有时建议“用 session timer 代替媒体超时”——对幽灵 SIP 对话有用，**不能**\ 代替 RTP 存活检测。

呼叫中心为何在意
--------------------

* 长通话：售后、催收、远程协助
* 坐席侧 NAT 后的软电话
* SBC 有自己的 session timer，和 FreeSWITCH 不一致会导致异常拆线
* 刷新失败应记入 CDR（区别于用户主动挂机）

实践注意
--------------------

1. 两端 Min-SE 谈不拢会 422 Session Interval Too Small。
2. 有的终端不支持 timer，只能靠 Proxy 插入 refresher。
3. 刷新间隔不要过短，否则 UPDATE 风暴；1800s 是常见起点，按 NAT 绑定寿命调整。
4. WebRTC 侧更依赖 ICE consent freshness（RFC 7675），经网关时两边保活机制都要开。
5. FreeSWITCH sofia：``enable-timer``\ 、``session-timeout``\ （写入 ``Session-Expires``\ ）、``minimum-session-expires``\ （``Min-SE``\ ）。媒体侧用 ``media_timeout``\ （毫秒），不要和 session-timeout 当成同一个旋钮。


Example
============

INVITE 与 200 协商 timer 后，在租约过半应看到 UPDATE。siptrace 对照：

.. code-block:: text

    INVITE sip:1002@192.168.1.10 SIP/2.0
    Supported: timer
    Session-Expires: 1800;refresher=uac
    Min-SE: 90
    CSeq: 1 INVITE

    SIP/2.0 200 OK
    Require: timer
    Session-Expires: 1800;refresher=uac
    CSeq: 1 INVITE

    UPDATE sip:1002@192.168.1.10 SIP/2.0
    Session-Expires: 1800;refresher=uac
    Supported: timer
    CSeq: 2 UPDATE

    SIP/2.0 200 OK
    Session-Expires: 1800;refresher=uac
    CSeq: 2 UPDATE

验证 SIP 租约（profile 里常见写法，与 :doc:`../7.practice/freeswitch_sip` 一致）：

.. code-block:: xml

    <param name="enable-timer" value="true"/>
    <param name="session-timeout" value="1800"/>
    <param name="minimum-session-expires" value="90"/>

.. code-block:: bash

    fs_cli -x "sofia global siptrace on"
    # 建立通话后等待约 Session-Expires/2
    # 应周期性出现 UPDATE，而不是 BYE
    # 同时开 Wireshark：rtp && !rtpevent 仍应有音频包
    # 若只有 UPDATE 200、RTP 已停 → SIP 活着、媒体死了

若看到 ``422 Session Interval Too Small``\ ，比较双方 Min-SE，抬高或降低到交集。

刷新失败拆线时，CDR 应能和用户 BYE（Q.850 16）区分开。


Conclusion
============

* 周期性 UPDATE + Session-Expires 只证明 SIP dialog 还在。
* RTP 停了仍可能看到 UPDATE 200；媒体死活用 media_timeout / RTCP，不是 Session Timer。
* 422 看 Min-SE；刷新失败的拆线不要记成用户挂机。


Reference
============

* `RFC4028`_
* `RFC3311`_
