################
JSEP
################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

.. contents::
   :local:


What
============

JSEP（`RFC8829`_\ ）是浏览器里 Offer/Answer 的契约，不是网上能抓到的信令报文。

Abstract
------------

WebRTC 不规定线上用 SIP、XMPP 还是自研 JSON。它规定 ``createOffer`` / ``createAnswer`` / ``setLocalDescription`` / ``setRemoteDescription`` 时 PeerConnection 做什么。
网上走的仍是 SIP-WS、Verto、Jingle 或自定义信令。Offer/Answer 模型本身是 `RFC3264`_\ 。


Why
============

* 把 JSEP 当成“一种协议”去找端口，会找不到东西。
* 信令丢了 Offer 而本地已 setLocalDescription，浏览器卡在 have-local-offer。
* 网关乱改 ICE ufrag / fingerprint，DTLS 会失败。
* Trickle ICE 先发无 candidate 的 Offer，对端若按 Vanilla SIP 等齐再 INVITE，两边会对不上。


How
============

浏览器 vs 信令服务器
--------------------

JSEP 停在浏览器进程里。``tcpdump`` / sngrep **抓不到 JSEP**\ ，只能抓到应用后来选用的信封（WS 文本、SIP INVITE、Verto JSON）。

.. mermaid::

   sequenceDiagram
     participant App as 网页应用
     participant Sig as 信令通道
     participant Peer as 对端

     App->>App: createOffer()
     App->>App: setLocalDescription(offer)
     App->>Sig: send(offer)
     Sig->>Peer: 任意协议转发
     Peer->>Peer: setRemoteDescription
     Peer->>Peer: createAnswer
     Peer->>Sig: send(answer)
     Sig->>App: answer
     App->>App: setRemoteDescription(answer)

浏览器负责：收集编解码器、ICE、DTLS fingerprint，生成 SDP；维护 signalingState；ICE 连通后做 DTLS-SRTP。
应用 / 服务器负责：把 Offer、Answer、ICE candidate 送到对端；房间、鉴权、多方路由 —— JSEP 不管。

状态机细节见 :doc:`../2.transport/overview`\ ；API 见 :doc:`../1.basic/webrtc_signal`\ 。

和 SIP 的关系
--------------------

.. list-table::
   :header-rows: 1
   :widths: 24 38 38

   * -
     - SIP UA
     - WebRTC / JSEP
   * - 谁生成 SDP
     - 协议栈
     - 浏览器 PeerConnection
   * - 怎么传 SDP
     - INVITE / 200 / ACK
     - 未规定
   * - ICE / DTLS
     - 可选
     - 强制
   * - 临时应答
     - 18x + PRACK
     - pranswer，实际很少用
   * - ICE 时机
     - 多为 Vanilla（candidate 写进 SDP 再发）
     - 默认 Trickle（Offer 可先走，candidate 后到）

FreeSWITCH 做 WebRTC 网关时，必须把 JSEP SDP 翻译成 sofia 能懂的 SIP SDP（或走 Verto，内部仍是同一套媒体）。

Trickle ICE vs Vanilla ICE
----------------------------

这是网关最容易踩的差异，不是“两种 JSEP”。

.. list-table::
   :header-rows: 1
   :widths: 22 39 39

   * -
     - Trickle ICE（JSEP 默认）
     - Vanilla ICE（传统 SIP）
   * - Offer 何时发
     - ``setLocalDescription`` 后立刻
     - 等 ``iceGatheringState === complete``
   * - candidate 在哪
     - 随后 ``addIceCandidate`` / 信令逐条
     - 全部写在 SDP 的 ``a=candidate``
   * - 刚 setLocal 时
     - SDP 常 **0 条** candidate，但已有 ufrag / fingerprint
     - SDP 已含 host/srflx/relay
   * - 首包延迟
     - 低（Offer 先走）
     - 高（等 STUN/TURN 完）
   * - SIP 对接
     - 对端要懂增量 candidate，否则 488/无媒体
     - 直接塞进 INVITE，兼容老 PBX

对接策略（选一个，写进网关设计，不要混用）：

1. **等齐再发 SIP INVITE**\ （Vanilla）：浏览器等 ``complete``\ ，把 ``pc.localDescription.sdp`` 整段放进 INVITE。简单，首响慢。SIP.js 对接 sofia 时常见。
2. **Trickle 全程**\ ：Offer 先走，candidate 用后续信令推。Verto / 自研 JSON 好做；SIP 侧要额外机制，不是每台 PBX 都有。
3. **FS 侧收齐再桥**\ ：浏览器 Trickle 给 FS，FS 等候选稳定后再向 SIP Trunk 发 Vanilla INVITE。

实践注意
--------------------

1. 信令丢了 Offer 而本地已经 setLocalDescription，要靠 rollback 或重建 PC。
2. Perfect negotiation（polite/impolite）解决 glare，SIP 用 491。
3. 不要在信令里改 SDP 的 ICE ufrag / fingerprint，除非你在做网关改写。
4. 刚 ``createOffer`` 完就复制 SDP 去发 SIP INVITE，对端可能永远收不到 candidate。


Example
============

浏览器控制台可跑（需摄像头/麦克风权限）。这段同时验证：**JSEP 无端口**\ 、以及 Trickle vs Vanilla 的 candidate 数量差。

.. code-block:: javascript

    const pc = new RTCPeerConnection({
      iceServers: [{ urls: "stun:stun.l.google.com:19302" }]
    });
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    stream.getTracks().forEach((t) => pc.addTrack(t, stream));

    pc.onicecandidate = (e) => {
      if (e.candidate) console.log("trickle", e.candidate.candidate);
      else console.log("gathering complete");
    };

    const offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    console.log(pc.signalingState);  // "have-local-offer"
    const sdpNow = pc.localDescription.sdp;
    console.log(sdpNow);             // 应含 ice-ufrag, fingerprint, UDP/TLS/RTP/SAVPF
    console.log("candidates now", (sdpNow.match(/^a=candidate/gm) || []).length);
    // Trickle：这里经常是 0。此时发出去的是“半成品 Offer”。

    await new Promise((resolve) => {
      if (pc.iceGatheringState === "complete") return resolve();
      pc.addEventListener("icegatheringstatechange", () => {
        if (pc.iceGatheringState === "complete") resolve();
      });
    });
    console.log("Vanilla candidate count",
      (pc.localDescription.sdp.match(/^a=candidate/gm) || []).length);
    // 对接 SIP Trunk / 等齐再 INVITE：用这一份 sdp。

把 ``pc.localDescription.sdp`` 贴进信令发出去；对端 ``setRemoteDescription`` + ``createAnswer`` 后再回来 ``setRemoteDescription(answer)``\ ，状态应回到 ``stable``\ 。
对接 FreeSWITCH 时，这份 SDP 走 Verto ``verto.invite`` 或 SIP INVITE（:doc:`verto`\ 、:doc:`sip_websocket`\ ）。
Wireshark 里你看到的是 WS/SIP 帧，过滤不到名为 JSEP 的协议。


Conclusion
============

* JSEP 是浏览器状态机，线上协议另选，没有 5060 可抓。
* 与 SIP 共享 Offer/Answer，不共享 INVITE 信封。
* Trickle 先发 Offer；Vanilla 等 candidate 齐了再 INVITE —— 网关必须显式选边。


Reference
============

* `RFC8829`_
* `RFC3264`_
* `RFC8445`_
* `RFC8838`_
* :doc:`sip_websocket`
* :doc:`verto`
