############################
FreeSWITCH 与 WebRTC
############################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** FreeSWITCH WebRTC
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
========================

FreeSWITCH 从较早的版本就开始支持 WebRTC，主要通过 mod_verto 模块实现。
与其他 WebRTC 服务器（如 Janus、Opal）不同，FreeSWITCH 的 WebRTC 支持是建立在其强大的电话交换能力之上的，
这意味着 WebRTC 客户端可以无缝地与传统 SIP/PSTN 网络互通。

FreeSWITCH 的 WebRTC 支持包括以下关键组件：

* **mod_verto** - Verto 协议模块，提供 WebSocket 信令通道
* **DTLS-SRTP** - 媒体加密，满足 WebRTC 的安全要求
* **ICE/STUN/TURN** - NAT 穿越支持
* **Opus/VP8 编解码器** - WebRTC 推荐的音视频编解码器
* **WSS（WebSocket Secure）** - 安全的 WebSocket 连接


Verto 协议
========================

Verto 是 FreeSWITCH 专门为 WebRTC 设计的信令协议，全称为 "VER-to"（Vertical To）。
它基于 JSON-RPC 2.0 规范，运行在 WebSocket（或 WebSocket Secure）之上。

与直接使用 SIP over WebSocket 相比，Verto 协议具有以下优势：

* **更轻量** - JSON 格式比 SIP 文本协议更简洁
* **更灵活** - 支持自定义方法和参数扩展
* **更适合 Web** - 天然适配 JavaScript 开发环境
* **双向通信** - 支持服务器主动推送消息

协议格式
------------------------------

Verto 使用标准的 JSON-RPC 2.0 格式：

**请求消息：**

.. code-block:: json

    {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "verto.invite",
        "params": {
            "sessid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "sdp": "<SDP offer>",
            "dialogParams": {
                "callID": "unique-call-id",
                "destination_number": "1001",
                "caller_id_name": "WebRTC User",
                "caller_id_number": "1000"
            }
        }
    }

**响应消息：**

.. code-block:: json

    {
        "jsonrpc": "2.0",
        "id": 1,
        "result": {
            "method": "verto.invite",
            "sessid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "sdp": "<SDP answer>"
        }
    }

主要方法
------------------------------

Verto 协议定义了以下主要方法：

.. list-table:: Verto 协议方法
   :header-rows: 1
   :widths: 30 70

   * - 方法
     - 说明
   * - ``verto.login``
     - 用户认证登录
   * - ``verto.invite``
     - 发起呼叫（携带 SDP Offer）
   * - ``verto.answer``
     - 应答呼叫（携带 SDP Answer）
   * - ``verto.bye``
     - 结束呼叫
   * - ``verto.modify``
     - 修改会话（如 hold/unhold）
   * - ``verto.info``
     - 发送会话内信息（如 DTMF）
   * - ``verto.display``
     - 服务器推送显示信息
   * - ``verto.media``
     - 媒体协商相关
   * - ``verto.subscribe``
     - 订阅事件
   * - ``verto.unsubscribe``
     - 取消订阅
   * - ``verto.broadcast``
     - 广播消息

呼叫流程
------------------------------

一个典型的 Verto 呼叫流程如下：

.. code-block:: text

    浏览器 (verto.js)                    FreeSWITCH (mod_verto)
         |                                      |
         |--- WSS 连接建立 ------------------->|
         |                                      |
         |--- verto.login ------------------>  |
         |<-- login result (200 OK) ---------- |
         |                                      |
         |--- verto.invite (SDP Offer) ------>  |
         |                                      |--- 路由到目标 --->
         |<-- verto.media (early media) ------- |
         |                                      |<-- 目标应答 ------
         |<-- verto.answer (SDP Answer) ------- |
         |                                      |
         |=== 双向媒体流 (SRTP) ============== |
         |                                      |
         |--- verto.bye --------------------->  |
         |<-- verto.bye result --------------- |
         |                                      |


SRTP/DTLS 配置
========================

WebRTC 强制要求使用加密的媒体传输。FreeSWITCH 通过 DTLS-SRTP 来满足这一要求。

DTLS（Datagram Transport Layer Security）用于在 UDP 上建立安全通道，
然后通过 DTLS 握手协商 SRTP（Secure Real-time Transport Protocol）的密钥。

TLS 证书配置
------------------------------

FreeSWITCH 需要有效的 TLS 证书来支持 WSS 和 DTLS：

.. code-block:: bash

    # 生成自签名证书（仅用于测试）
    cd /etc/freeswitch/tls

    # 生成 CA 证书
    openssl req -new -x509 -days 3650 -nodes \
        -out ca.pem -keyout cakey.pem \
        -subj "/C=CN/ST=Beijing/O=MyOrg/CN=FreeSWITCH CA"

    # 生成服务器证书
    openssl req -new -nodes \
        -out agent.csr -keyout agent.key \
        -subj "/C=CN/ST=Beijing/O=MyOrg/CN=freeswitch.example.com"

    openssl x509 -req -days 3650 \
        -in agent.csr -CA ca.pem -CAkey cakey.pem \
        -CAcreateserial -out agent.crt

    # 合并为 agent.pem
    cat agent.crt agent.key > agent.pem

    # 复制 CA 文件
    cp ca.pem cafile.pem

    # 生成 wss.pem（用于 WebSocket Secure）
    cat agent.crt agent.key > wss.pem

.. note::

    在生产环境中，建议使用 Let's Encrypt 等 CA 签发的正式证书，
    以避免浏览器的安全警告。

vars.xml 中的相关配置
------------------------------

.. code-block:: xml

    <!-- 启用内部 TLS -->
    <X-PRE-PROCESS cmd="set" data="internal_ssl_enable=true"/>
    <X-PRE-PROCESS cmd="set" data="internal_ssl_dir=$${base_dir}/tls"/>

    <!-- 外部 RTP IP（用于 ICE candidate） -->
    <X-PRE-PROCESS cmd="set" data="external_rtp_ip=YOUR_PUBLIC_IP"/>
    <X-PRE-PROCESS cmd="set" data="external_sip_ip=YOUR_PUBLIC_IP"/>


ICE/STUN/TURN 集成
========================

WebRTC 使用 ICE（Interactive Connectivity Establishment）框架来建立点对点的媒体连接。
FreeSWITCH 支持完整的 ICE 协商流程。

STUN 配置
------------------------------

在 ``vars.xml`` 中配置 STUN 服务器：

.. code-block:: xml

    <X-PRE-PROCESS cmd="set" data="external_rtp_ip=stun:stun.freeswitch.org"/>
    <X-PRE-PROCESS cmd="set" data="external_sip_ip=stun:stun.freeswitch.org"/>

TURN 配置
------------------------------

对于复杂的 NAT 环境，可能需要配置 TURN 服务器。在 ``verto.conf.xml`` 中：

.. code-block:: xml

    <param name="ice-candidates" value="true"/>
    <param name="stun-server" value="stun:stun.freeswitch.org"/>

在客户端 JavaScript 中配置 TURN：

.. code-block:: javascript

    var vertoHandle = new $.verto({
        login: "1000@freeswitch.example.com",
        passwd: "1234",
        socketUrl: "wss://freeswitch.example.com:8082",
        iceServers: [
            { urls: "stun:stun.freeswitch.org" },
            {
                urls: "turn:turn.example.com:3478",
                username: "turnuser",
                credential: "turnpass"
            }
        ]
    });

SIP Profile 中的 ICE 配置
------------------------------

在 ``sip_profiles/internal.xml`` 中启用 ICE 支持：

.. code-block:: xml

    <!-- 启用 ICE -->
    <param name="local-network-acl" value="localnet.auto"/>
    <param name="apply-nat-acl" value="nat.auto"/>


编解码器协商
========================

WebRTC 客户端通常支持 Opus（音频）和 VP8/H.264（视频）编解码器。
FreeSWITCH 需要正确配置编解码器以与 WebRTC 客户端协商。

Opus 配置
------------------------------

Opus 是 WebRTC 的必选音频编解码器，在 ``vars.xml`` 中配置：

.. code-block:: xml

    <!-- 全局编解码器偏好设置 -->
    <X-PRE-PROCESS cmd="set"
        data="global_codec_prefs=OPUS,G722,PCMU,PCMA,H264,VP8"/>
    <X-PRE-PROCESS cmd="set"
        data="outbound_codec_prefs=OPUS,G722,PCMU,PCMA,H264,VP8"/>

Opus 编解码器的详细配置在 ``autoload_configs/opus.conf.xml`` 中：

.. code-block:: xml

    <configuration name="opus.conf">
      <settings>
        <param name="use-vbr" value="1"/>
        <param name="use-dtx" value="1"/>
        <param name="complexity" value="10"/>
        <param name="packet-loss-percent" value="15"/>
        <param name="keep-fec-enabled" value="1"/>
        <param name="use-jb-lookahead" value="1"/>
        <param name="maxaveragebitrate" value="64000"/>
        <param name="maxplaybackrate" value="48000"/>
        <param name="sprop-maxcapturerate" value="48000"/>
        <param name="adjust-bitrate" value="1"/>
      </settings>
    </configuration>

视频编解码器
------------------------------

对于视频通话，需要加载 mod_av 模块并配置 VP8 或 H.264：

.. code-block:: xml

    <!-- modules.conf.xml 中加载视频编解码器模块 -->
    <load module="mod_av"/>
    <load module="mod_vlc"/>


SDP 处理
========================

FreeSWITCH 在处理 WebRTC 的 SDP（Session Description Protocol）时，
需要特别注意以下几点：

WebRTC SDP 的特殊要求
------------------------------

* **必须使用 DTLS-SRTP** - ``a=fingerprint`` 和 ``a=setup`` 属性
* **必须支持 ICE** - ``a=ice-ufrag``、``a=ice-pwd``、``a=candidate`` 属性
* **必须使用 RTCP-MUX** - ``a=rtcp-mux`` 属性
* **Bundle 支持** - ``a=group:BUNDLE`` 属性

一个典型的 WebRTC SDP Offer 示例：

.. code-block:: text

    v=0
    o=- 1234567890 2 IN IP4 0.0.0.0
    s=-
    t=0 0
    a=group:BUNDLE 0 1
    a=msid-semantic: WMS stream1
    m=audio 9 UDP/TLS/RTP/SAVPF 111 103 104 9 0 8
    c=IN IP4 0.0.0.0
    a=rtcp:9 IN IP4 0.0.0.0
    a=ice-ufrag:abcd
    a=ice-pwd:efghijklmnopqrstuvwxyz
    a=fingerprint:sha-256 AA:BB:CC:DD:...
    a=setup:actpass
    a=mid:0
    a=sendrecv
    a=rtcp-mux
    a=rtpmap:111 opus/48000/2
    a=fmtp:111 minptime=10;useinbandfec=1
    m=video 9 UDP/TLS/RTP/SAVPF 96 97
    c=IN IP4 0.0.0.0
    a=rtcp:9 IN IP4 0.0.0.0
    a=ice-ufrag:abcd
    a=ice-pwd:efghijklmnopqrstuvwxyz
    a=fingerprint:sha-256 AA:BB:CC:DD:...
    a=setup:actpass
    a=mid:1
    a=sendrecv
    a=rtcp-mux
    a=rtpmap:96 VP8/90000
    a=rtcp-fb:96 ccm fir
    a=rtcp-fb:96 nack
    a=rtcp-fb:96 nack pli
    a=rtcp-fb:96 goog-remb


mod_verto 配置
========================

mod_verto 的配置文件位于 ``autoload_configs/verto.conf.xml``：

.. code-block:: xml

    <configuration name="verto.conf" description="HTML5 Verto Endpoint">
      <settings>
        <param name="debug" value="10"/>
        <param name="enable-fs-dtmf" value="true"/>
        <param name="enable-3pcc" value="true"/>
      </settings>

      <profiles>
        <profile name="default-v4">
          <param name="bind-local" value="0.0.0.0:8081"/>
          <param name="bind-local" value="0.0.0.0:8082" secure="true"/>
          <param name="force-register-domain" value="$${domain}"/>
          <param name="secure-combined" value="$${base_dir}/tls/wss.pem"/>
          <param name="secure-chain" value="$${base_dir}/tls/wss.pem"/>
          <param name="userauth" value="true"/>
          <param name="context" value="default"/>
          <param name="dialplan" value="XML"/>
          <param name="mcast-ip" value="224.1.1.1"/>
          <param name="mcast-port" value="1337"/>
          <param name="rtp-ip" value="$${local_ip_v4}"/>
          <param name="ext-rtp-ip" value="$${external_rtp_ip}"/>
          <param name="local-network" value="localnet.auto"/>
          <param name="outbound-codec-string"
                 value="opus,vp8,h264"/>
          <param name="inbound-codec-string"
                 value="opus,vp8,h264"/>
          <param name="apply-candidate-acl" value="localnet.auto"/>
          <param name="apply-candidate-acl" value="wan_v4.auto"/>
          <param name="timer-name" value="soft"/>
        </profile>
      </profiles>
    </configuration>

关键配置参数说明：

* ``bind-local`` - 监听地址和端口，``secure="true"`` 表示 WSS
* ``secure-combined`` - WSS 使用的 TLS 证书文件
* ``userauth`` - 是否启用用户认证
* ``rtp-ip`` - RTP 媒体绑定的本地 IP
* ``ext-rtp-ip`` - 对外公布的 RTP IP（用于 NAT 环境）
* ``outbound-codec-string`` - 出站编解码器偏好


JavaScript 客户端示例
========================

FreeSWITCH 提供了 verto.js 客户端库，用于在浏览器中实现 WebRTC 通信。

基本使用
------------------------------

.. code-block:: html

    <!DOCTYPE html>
    <html>
    <head>
        <title>Verto WebRTC Demo</title>
        <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
        <script src="verto-min.js"></script>
    </head>
    <body>
        <div>
            <video id="webcam" autoplay playsinline></video>
            <button id="callBtn" onclick="makeCall()">呼叫</button>
            <button id="hangupBtn" onclick="hangUp()">挂断</button>
        </div>

        <script>
        var verto;
        var currentCall;

        // 初始化 Verto
        $(document).ready(function() {
            verto = new $.verto({
                login: "1000@freeswitch.example.com",
                passwd: "1234",
                socketUrl: "wss://freeswitch.example.com:8082",
                tag: "webcam",
                deviceParams: {
                    useCamera: "any",
                    useMic: "any",
                    useSpeak: "any"
                },
                iceServers: [
                    { urls: "stun:stun.freeswitch.org" }
                ],

                // 回调函数
                onWSLogin: onWSLogin,
                onWSClose: onWSClose,
                onDialogState: onDialogState
            });
        });

        function onWSLogin(verto, success) {
            if (success) {
                console.log("登录成功");
            } else {
                console.error("登录失败");
            }
        }

        function onWSClose(verto, success) {
            console.log("WebSocket 连接关闭");
        }

        function onDialogState(d) {
            switch (d.state.name) {
                case "ringing":
                    console.log("振铃中...");
                    break;
                case "trying":
                    console.log("尝试连接...");
                    break;
                case "early":
                    console.log("早期媒体...");
                    break;
                case "active":
                    console.log("通话已建立");
                    break;
                case "hangup":
                    console.log("通话结束");
                    break;
                case "destroy":
                    currentCall = null;
                    break;
            }
        }

        function makeCall() {
            currentCall = verto.newCall({
                destination_number: "1001",
                caller_id_name: "WebRTC User",
                caller_id_number: "1000",
                useVideo: true,
                useStereo: true
            });
        }

        function hangUp() {
            if (currentCall) {
                currentCall.hangup();
            }
        }
        </script>
    </body>
    </html>

会议室示例
------------------------------

使用 verto.js 加入 FreeSWITCH 会议室：

.. code-block:: javascript

    // 加入会议室
    function joinConference(confNumber) {
        currentCall = verto.newCall({
            destination_number: confNumber,
            caller_id_name: "Conference User",
            caller_id_number: "1000",
            useVideo: true,
            useStereo: true,
            // 会议相关参数
            dedEnc: true,
            mirrorInput: false
        });
    }

    // 订阅会议事件
    verto.subscribe("conference.info", {
        handler: function(verto, dialog, event) {
            var participants = event.data.participants;
            console.log("会议参与者:", participants);
        }
    });


与 Janus 的对比
========================

FreeSWITCH 和 Janus 都可以作为 WebRTC 网关使用，但它们的定位和特点有所不同：

.. list-table:: FreeSWITCH vs Janus WebRTC 对比
   :header-rows: 1
   :widths: 25 35 35

   * - 特性
     - FreeSWITCH
     - Janus
   * - 定位
     - 通信平台（PBX + WebRTC）
     - 通用 WebRTC 服务器
   * - 信令协议
     - Verto（JSON-RPC over WSS）
     - 自定义 JSON API
   * - SIP 互通
     - 原生支持（mod_sofia）
     - 通过插件（janus.plugin.sip）
   * - PSTN 互通
     - 原生支持
     - 需要外部网关
   * - 视频会议
     - MCU 模式（混流）
     - SFU 模式（转发）
   * - 编解码器转码
     - 支持
     - 不支持（透传）
   * - 录制
     - 原生支持
     - 插件支持
   * - 扩展方式
     - 模块 + ESL + 脚本
     - 插件 + HTTP API
   * - 适用场景
     - 企业通信、呼叫中心
     - 视频会议、直播、IoT

选择建议：

* 如果需要与传统电话网络互通，选择 **FreeSWITCH**
* 如果需要纯 WebRTC 的 SFU 架构，选择 **Janus**
* 如果需要编解码器转码，选择 **FreeSWITCH**
* 如果需要轻量级的 WebRTC 网关，选择 **Janus**


常见问题排查
========================

WebSocket 连接失败
------------------------------

.. code-block:: bash

    # 检查 mod_verto 是否加载
    fs_cli -x "module_exists mod_verto"

    # 检查 WSS 端口是否监听
    netstat -tlnp | grep 8082

    # 检查证书文件
    ls -la /etc/freeswitch/tls/wss.pem

    # 查看 verto 日志
    fs_cli -x "verto status"

ICE 协商失败
------------------------------

.. code-block:: bash

    # 检查防火墙是否开放 UDP 端口范围
    # FreeSWITCH 默认 RTP 端口范围: 16384-32768
    sudo iptables -A INPUT -p udp --dport 16384:32768 -j ACCEPT

    # 检查 external_rtp_ip 配置
    fs_cli -x "global_getvar external_rtp_ip"

    # 启用 ICE 调试日志
    fs_cli -x "sofia loglevel all 9"


小结
========================

FreeSWITCH 的 WebRTC 支持通过 mod_verto 模块实现，提供了完整的 WebRTC 通信能力。
Verto 协议基于 JSON-RPC over WebSocket，简洁高效，配合 verto.js 客户端库，
可以快速构建基于浏览器的实时通信应用。

FreeSWITCH 作为 WebRTC 网关的最大优势在于其与传统电话网络的无缝互通能力，
这使得它特别适合需要 WebRTC-to-SIP/PSTN 桥接的企业通信场景。


参考资料
========================

* mod_verto 文档: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Modules/mod_verto_3964934/
* Verto 协议规范: https://evoluxbr.github.io/verto-docs/
* verto.js 源码: https://github.com/nickcalyx/verto
* WebRTC 与 FreeSWITCH 集成指南: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Configuration/WebRTC/
