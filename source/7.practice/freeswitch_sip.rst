.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============================================
FreeSWITCH SIP 配置与实践
============================================

.. list-table:: 文档信息
   :widths: 30 70

   * - 作者
     - Walter Fan
   * - 状态
     - 更新中
   * - 更新日期
     - 2024-03-18
   * - 关键词
     - FreeSWITCH, SIP, VoIP, sofia, WebRTC

.. contents::
   :local:

概述
============

FreeSWITCH 是一个开源的软交换平台，广泛应用于 VoIP、视频会议和 WebRTC 网关等场景。
其核心的 SIP 协议栈由 **mod_sofia** 模块提供，该模块基于 Sofia-SIP 库实现了完整的
SIP UA（User Agent）和 SIP Proxy 功能。

mod_sofia 简介
-----------------

mod_sofia 是 FreeSWITCH 中最重要的端点模块之一，负责处理所有 SIP 相关的信令。
它支持以下核心功能：

- **SIP 注册服务器**: 接受 SIP 终端的注册请求，管理用户在线状态
- **SIP 代理**: 在不同 SIP 端点之间转发呼叫
- **SIP Trunk 网关**: 与外部 ITSP（Internet Telephony Service Provider）对接
- **TLS/SRTP 加密**: 提供信令和媒体层面的安全保障
- **WebSocket 传输**: 支持 WebRTC 客户端通过 WSS 连接

FreeSWITCH 的 SIP 架构采用 Profile 的概念来组织不同的 SIP 监听接口。
每个 Profile 可以绑定不同的 IP 地址和端口，拥有独立的配置参数，
从而实现内部通信和外部通信的隔离。

典型的部署架构如下::

    +-------------------+
    |   SIP 终端/话机    |
    +--------+----------+
             |  SIP (UDP/TCP/TLS)
             v
    +--------+----------+
    |  FreeSWITCH       |
    |  +--------------+ |
    |  | mod_sofia    | |
    |  | - internal   | |  <-- 内部 Profile (端口 5060)
    |  | - external   | |  <-- 外部 Profile (端口 5080)
    |  +--------------+ |
    +--------+----------+
             |  SIP Trunk
             v
    +--------+----------+
    |   ITSP / PSTN GW  |
    +-------------------+


SIP Profile 配置
====================

FreeSWITCH 使用 Profile 来定义 SIP 监听接口。默认安装包含两个 Profile：

- **internal**: 用于内部 SIP 终端注册和通信，默认监听端口 5060
- **external**: 用于与外部 SIP Trunk 和 ITSP 对接，默认监听端口 5080

sofia.conf.xml 核心参数
--------------------------

Profile 的配置文件位于 ``conf/sip_profiles/`` 目录下。以下是 internal profile
的关键配置参数：

.. code-block:: xml

    <profile name="internal">
      <settings>
        <!-- 监听地址与端口 -->
        <param name="sip-ip" value="$${local_ip_v4}"/>
        <param name="sip-port" value="5060"/>
        <param name="rtp-ip" value="$${local_ip_v4}"/>

        <!-- 传输协议 -->
        <param name="sip-transport" value="udp,tcp"/>

        <!-- 用户代理标识 -->
        <param name="user-agent-string" value="FreeSWITCH"/>

        <!-- 编解码器协商 -->
        <param name="inbound-codec-prefs" value="$${global_codec_prefs}"/>
        <param name="outbound-codec-prefs" value="$${global_codec_prefs}"/>

        <!-- 认证相关 -->
        <param name="challenge-realm" value="auto_from"/>
        <param name="accept-blind-reg" value="false"/>

        <!-- DTMF 模式 -->
        <param name="dtmf-type" value="rfc2833"/>

        <!-- 会话超时 -->
        <param name="session-timeout" value="1800"/>

        <!-- 上下文绑定 -->
        <param name="context" value="public"/>
        <param name="dialplan" value="XML"/>
      </settings>
    </profile>

TLS 监听配置
--------------

若需启用 TLS 加密传输，需要在 Profile 中添加以下参数：

.. code-block:: xml

    <param name="tls" value="true"/>
    <param name="tls-bind-params" value="transport=tls"/>
    <param name="tls-sip-port" value="5061"/>
    <param name="tls-cert-dir" value="$${base_dir}/conf/ssl"/>
    <param name="tls-version" value="tlsv1.2"/>
    <param name="tls-passphrase" value=""/>

WebSocket 支持
-----------------

为了支持 WebRTC 客户端通过 WebSocket 连接，需要额外配置：

.. code-block:: xml

    <param name="ws-binding" value=":5066"/>
    <param name="wss-binding" value=":7443"/>
    <param name="apply-candidate-acl" value="localnet.auto"/>

WebRTC 客户端通常使用 WSS（WebSocket Secure）协议连接到 FreeSWITCH，
然后通过 SIP over WebSocket 进行信令交互。


用户目录与注册
====================

FreeSWITCH 使用 XML 格式的用户目录（Directory）来管理 SIP 用户账户。
用户目录文件通常位于 ``conf/directory/`` 目录下。

用户目录 XML 结构
--------------------

每个用户的配置文件遵循以下结构：

.. code-block:: xml

    <include>
      <user id="1001">
        <params>
          <!-- 认证密码 -->
          <param name="password" value="Abc@12345"/>
          <!-- 语音信箱密码 -->
          <param name="vm-password" value="1001"/>
        </params>
        <variables>
          <!-- 来电显示号码 -->
          <variable name="effective_caller_id_number" value="1001"/>
          <!-- 来电显示名称 -->
          <variable name="effective_caller_id_name" value="Extension 1001"/>
          <!-- 用户所属上下文 -->
          <variable name="user_context" value="default"/>
          <!-- 允许的编解码器 -->
          <variable name="codec_prefs" value="OPUS,PCMU,PCMA"/>
        </variables>
      </user>
    </include>

用户注册流程
--------------

SIP 终端注册到 FreeSWITCH 的流程如下：

1. 终端发送 ``REGISTER`` 请求到 FreeSWITCH
2. FreeSWITCH 返回 ``401 Unauthorized``，携带 ``WWW-Authenticate`` 头
3. 终端使用用户名和密码计算摘要认证（Digest Authentication）响应
4. 终端重新发送带有 ``Authorization`` 头的 ``REGISTER`` 请求
5. FreeSWITCH 验证凭据，成功则返回 ``200 OK``

注册过期与刷新
-----------------

注册的有效期由以下参数控制：

.. code-block:: xml

    <!-- 最小注册过期时间（秒） -->
    <param name="min-reg-expires" value="60"/>
    <!-- 最大注册过期时间（秒） -->
    <param name="max-reg-expires" value="3600"/>
    <!-- 强制注册过期时间 -->
    <param name="force-register-expires" value="600"/>

终端需要在注册过期之前发送刷新注册请求，否则 FreeSWITCH 会将该终端标记为离线。
可以通过 ``sofia_contact`` 函数查询用户的注册状态。

批量用户管理
--------------

对于大规模部署，可以使用 ``mod_xml_curl`` 模块从外部 HTTP 服务器动态获取用户目录，
或者使用 ``mod_ldap`` 从 LDAP 目录服务中查询用户信息，避免维护大量静态 XML 文件。


Dialplan 基础
====================

FreeSWITCH 的 Dialplan（拨号计划）定义了呼叫的路由逻辑。
默认使用 XML 格式的 Dialplan，配置文件位于 ``conf/dialplan/`` 目录下。

XML Dialplan 结构
--------------------

Dialplan 由以下层次结构组成：

- **Context（上下文）**: 最外层容器，用于隔离不同的路由域
- **Extension（分机）**: 一组匹配条件和动作的集合
- **Condition（条件）**: 基于正则表达式的匹配规则
- **Action（动作）**: 条件匹配成功时执行的操作
- **Anti-Action（反动作）**: 条件匹配失败时执行的操作

基本结构示例：

.. code-block:: xml

    <context name="default">
      <extension name="internal_call">
        <condition field="destination_number" expression="^(10[01][0-9])$">
          <action application="set" data="dialed_extension=$1"/>
          <action application="bridge" data="user/$1@${domain_name}"/>
          <anti-action application="playback"
                       data="ivr/ivr-invalid_extension.wav"/>
        </condition>
      </extension>
    </context>

常用 Condition 字段
-----------------------

Dialplan 中可以匹配多种字段：

.. list-table::
   :widths: 30 70
   :header-rows: 1

   * - 字段名
     - 说明
   * - destination_number
     - 被叫号码
   * - caller_id_number
     - 主叫号码
   * - caller_id_name
     - 主叫名称
   * - network_addr
     - 来源 IP 地址
   * - ${sip_from_user}
     - SIP From 头中的用户部分
   * - time_of_day
     - 当前时间（HH:MM-HH:MM 格式）
   * - day_of_week
     - 星期几（1-7）

常用 Action 应用
-------------------

.. list-table::
   :widths: 30 70
   :header-rows: 1

   * - 应用名
     - 说明
   * - bridge
     - 桥接呼叫到目标端点
   * - transfer
     - 转移呼叫到另一个 extension
   * - playback
     - 播放音频文件
   * - answer
     - 应答呼叫
   * - hangup
     - 挂断呼叫
   * - set
     - 设置通道变量
   * - export
     - 导出变量到对端通道
   * - sleep
     - 暂停指定毫秒数
   * - record_session
     - 录制整个会话


NAT 穿越
============

在实际部署中，FreeSWITCH 服务器通常位于 NAT 后面或需要处理位于 NAT 后面的终端。
正确配置 NAT 穿越对于保证 SIP 信令和 RTP 媒体的正常传输至关重要。

STUN 配置
-----------

FreeSWITCH 可以使用 STUN 服务器来发现自身的公网地址：

.. code-block:: xml

    <param name="ext-rtp-ip" value="stun:stun.freeswitch.org"/>
    <param name="ext-sip-ip" value="stun:stun.freeswitch.org"/>

也可以直接指定公网 IP 地址：

.. code-block:: xml

    <param name="ext-rtp-ip" value="203.0.113.10"/>
    <param name="ext-sip-ip" value="203.0.113.10"/>

或者使用 autonat 自动检测：

.. code-block:: xml

    <param name="ext-rtp-ip" value="autonat:203.0.113.10"/>
    <param name="ext-sip-ip" value="autonat:203.0.113.10"/>

NDLB 设置
-----------

NDLB（Network Device Load Balancing）相关设置用于处理各种 NAT 场景下的兼容性问题：

.. code-block:: xml

    <!-- 强制使用 rport -->
    <param name="NDLB-force-rport" value="true"/>
    <!-- 修复 NAT 后的联系地址 -->
    <param name="NDLB-broken-auth-hash" value="true"/>
    <!-- 接收到的 SIP 消息中使用实际来源地址 -->
    <param name="aggressive-nat-detection" value="true"/>

ACL 配置
----------

为了安全地处理 NAT 穿越，建议配置 ACL（Access Control List）：

.. code-block:: xml

    <param name="apply-nat-acl" value="nat.auto"/>
    <param name="apply-inbound-acl" value="domains"/>
    <param name="local-network-acl" value="localnet.auto"/>

当 FreeSWITCH 检测到来自 NAT 后面的终端时，会自动调整 SDP 中的媒体地址，
确保 RTP 流能够正确传输。


TLS/SRTP 安全配置
====================

在生产环境中，对 SIP 信令和 RTP 媒体进行加密是保障通信安全的基本要求。
特别是在 WebRTC 场景下，SRTP 是强制要求的。

证书生成
----------

FreeSWITCH 提供了一个脚本用于生成自签名证书：

.. code-block:: bash

    # 进入 FreeSWITCH 安装目录
    cd /usr/local/freeswitch

    # 生成 CA 证书和服务器证书
    ./bin/gentls_cert setup -cn your.domain.com -alt DNS:your.domain.com -org "Your Org"
    ./bin/gentls_cert create_server -cn your.domain.com -alt DNS:your.domain.com -org "Your Org"

对于生产环境，建议使用 Let's Encrypt 等 CA 签发的正式证书：

.. code-block:: bash

    # 合并证书和私钥
    cat /etc/letsencrypt/live/your.domain.com/fullchain.pem \
        /etc/letsencrypt/live/your.domain.com/privkey.pem \
        > /usr/local/freeswitch/conf/ssl/agent.pem

    # 复制 CA 证书
    cp /etc/letsencrypt/live/your.domain.com/chain.pem \
       /usr/local/freeswitch/conf/ssl/cafile.pem

TLS Profile 配置
-------------------

在 SIP Profile 中启用 TLS：

.. code-block:: xml

    <param name="tls" value="true"/>
    <param name="tls-bind-params" value="transport=tls"/>
    <param name="tls-sip-port" value="5061"/>
    <param name="tls-cert-dir" value="$${base_dir}/conf/ssl"/>
    <param name="tls-version" value="tlsv1.2"/>
    <param name="tls-ciphers" value="HIGH:!DSS:!aNULL@STRENGTH"/>

SRTP 配置
-----------

SRTP（Secure Real-time Transport Protocol）用于加密 RTP 媒体流：

.. code-block:: xml

    <!-- 在 SIP Profile 中设置 -->
    <!-- 可选值: mandatory（强制）, optional（可选）, forbidden（禁止） -->
    <param name="rtp-secure-media" value="mandatory"/>

也可以在 Dialplan 中针对特定呼叫启用 SRTP：

.. code-block:: xml

    <action application="set" data="rtp_secure_media=true"/>
    <action application="set" data="rtp_secure_media_suites=AEAD_AES_256_GCM_8,AES_CM_256_HMAC_SHA1_80,AES_CM_128_HMAC_SHA1_80"/>

对于 WebRTC 呼叫，SRTP 是强制要求的，FreeSWITCH 会自动处理 DTLS-SRTP 密钥协商。


SIP Trunk 配置
====================

SIP Trunk 用于将 FreeSWITCH 与外部 ITSP 或 PSTN 网关连接，实现外呼和接收来电。

Gateway 定义
--------------

Gateway（网关）配置文件位于 ``conf/sip_profiles/external/`` 目录下：

.. code-block:: xml

    <include>
      <gateway name="my_itsp">
        <!-- ITSP 服务器地址 -->
        <param name="realm" value="sip.itsp-provider.com"/>
        <!-- 认证用户名 -->
        <param name="username" value="your_account"/>
        <!-- 认证密码 -->
        <param name="password" value="your_password"/>
        <!-- 注册到 ITSP -->
        <param name="register" value="true"/>
        <!-- 注册过期时间 -->
        <param name="expire-seconds" value="3600"/>
        <!-- 重试间隔 -->
        <param name="retry-seconds" value="30"/>
        <!-- 来电上下文 -->
        <param name="context" value="public"/>
        <!-- 主叫号码 -->
        <param name="caller-id-in-from" value="true"/>
        <!-- 传输协议 -->
        <param name="register-transport" value="udp"/>
        <!-- 代理服务器（可选） -->
        <param name="proxy" value="sip.itsp-provider.com"/>
      </gateway>
    </include>

出站路由
----------

在 Dialplan 中配置通过 SIP Trunk 外呼的路由规则：

.. code-block:: xml

    <extension name="outbound_via_trunk">
      <condition field="destination_number" expression="^0(\d{10,11})$">
        <action application="set" data="effective_caller_id_number=02112345678"/>
        <action application="set" data="effective_caller_id_name=My Company"/>
        <action application="bridge"
                data="sofia/gateway/my_itsp/$1"/>
      </condition>
    </extension>

入站 DID 路由
----------------

处理从 SIP Trunk 接收到的来电，根据 DID（Direct Inward Dialing）号码路由：

.. code-block:: xml

    <context name="public">
      <extension name="inbound_did">
        <condition field="destination_number" expression="^(02112345678)$">
          <action application="set" data="domain_name=$${domain}"/>
          <action application="transfer" data="1001 XML default"/>
        </condition>
      </extension>

      <extension name="inbound_did_ivr">
        <condition field="destination_number" expression="^(02187654321)$">
          <action application="answer"/>
          <action application="sleep" data="1000"/>
          <action application="ivr" data="main_ivr"/>
        </condition>
      </extension>
    </context>


呼叫路由示例
====================

以下是几个完整的呼叫路由配置示例，涵盖常见的使用场景。

内部分机互拨
--------------

.. code-block:: xml

    <extension name="local_extension">
      <condition field="destination_number" expression="^(10[01][0-9])$">
        <action application="export" data="dialed_extension=$1"/>
        <action application="set" data="ringback=${us-ring}"/>
        <action application="set" data="transfer_ringback=$${hold_music}"/>
        <action application="set" data="call_timeout=30"/>
        <!-- 先尝试桥接到注册的终端 -->
        <action application="bridge"
                data="user/${dialed_extension}@${domain_name}"/>
        <!-- 无应答则转语音信箱 -->
        <action application="answer"/>
        <action application="voicemail" data="default ${domain_name} ${dialed_extension}"/>
      </condition>
    </extension>

通过 Trunk 外呼
------------------

.. code-block:: xml

    <extension name="domestic_call">
      <condition field="destination_number" expression="^0([1-9]\d{6,10})$">
        <action application="set" data="effective_caller_id_number=02112345678"/>
        <action application="set" data="hangup_after_bridge=true"/>
        <action application="set" data="continue_on_fail=true"/>
        <!-- 主用 Trunk -->
        <action application="bridge"
                data="sofia/gateway/primary_itsp/$1"/>
        <!-- 备用 Trunk（主用失败时） -->
        <action application="bridge"
                data="sofia/gateway/backup_itsp/$1"/>
      </condition>
    </extension>

DID 入站路由
--------------

.. code-block:: xml

    <context name="public">
      <extension name="inbound_sales">
        <condition field="destination_number" expression="^(4001234567)$">
          <action application="answer"/>
          <action application="set" data="domain_name=$${domain}"/>
          <!-- 播放欢迎语 -->
          <action application="playback" data="ivr/welcome.wav"/>
          <!-- 转接到销售组 -->
          <action application="bridge"
                  data="user/1001@${domain_name},user/1002@${domain_name},user/1003@${domain_name}"/>
        </condition>
      </extension>
    </context>

基于时间的路由
-----------------

.. code-block:: xml

    <extension name="time_based_routing">
      <condition field="destination_number" expression="^(4001234567)$"/>
      <!-- 工作时间: 周一至周五 9:00-18:00 -->
      <condition wday="2-6" time-of-day="09:00-18:00">
        <action application="transfer" data="1001 XML default"/>
        <!-- 非工作时间 -->
        <anti-action application="answer"/>
        <anti-action application="playback"
                     data="ivr/after_hours.wav"/>
        <anti-action application="voicemail"
                     data="default ${domain_name} 1001"/>
      </condition>
    </extension>

会议室呼叫
--------------

.. code-block:: xml

    <extension name="conference_room">
      <condition field="destination_number" expression="^(3\d{3})$">
        <action application="answer"/>
        <action application="conference" data="$1@default+1234"/>
      </condition>
    </extension>


SIP 调试
============

在开发和运维过程中，SIP 调试是排查问题的关键手段。FreeSWITCH 提供了丰富的调试工具。

fs_cli 基本使用
------------------

``fs_cli`` 是 FreeSWITCH 的命令行客户端，用于连接到运行中的 FreeSWITCH 实例：

.. code-block:: bash

    # 连接到本地 FreeSWITCH
    fs_cli

    # 连接到远程 FreeSWITCH
    fs_cli -H 192.168.1.100 -P 8021 -p ClueCon

sofia 常用命令
-----------------

以下是常用的 sofia 调试命令：

.. code-block:: bash

    # 查看所有 Profile 状态
    sofia status

    # 查看指定 Profile 的详细信息
    sofia status profile internal

    # 查看已注册的用户
    sofia status profile internal reg

    # 查看指定用户的注册信息
    sofia status profile internal user 1001

    # 查看 Gateway 状态
    sofia status gateway my_itsp

    # 开启全局 SIP 消息跟踪
    sofia global siptrace on

    # 关闭全局 SIP 消息跟踪
    sofia global siptrace off

    # 仅跟踪指定 Profile 的 SIP 消息
    sofia profile internal siptrace on

    # 重新加载 Profile（不中断现有呼叫）
    sofia profile internal rescan

    # 重启 Profile（会中断现有呼叫）
    sofia profile internal restart

    # 刷新指定 Gateway 的注册
    sofia profile external killgw my_itsp
    sofia profile external rescan

SIP 消息分析
--------------

开启 siptrace 后，可以在 fs_cli 中看到完整的 SIP 消息。以下是一个典型的
INVITE 消息示例::

    INVITE sip:1002@192.168.1.100:5060 SIP/2.0
    Via: SIP/2.0/UDP 192.168.1.50:5060;branch=z9hG4bK-abcdef
    From: "User 1001" <sip:1001@192.168.1.100>;tag=xyz123
    To: <sip:1002@192.168.1.100>
    Call-ID: unique-call-id@192.168.1.50
    CSeq: 1 INVITE
    Contact: <sip:1001@192.168.1.50:5060>
    Content-Type: application/sdp
    Max-Forwards: 70
    Content-Length: 256

    v=0
    o=- 12345 12345 IN IP4 192.168.1.50
    s=-
    c=IN IP4 192.168.1.50
    t=0 0
    m=audio 10000 RTP/AVP 0 8 101
    a=rtpmap:0 PCMU/8000
    a=rtpmap:8 PCMA/8000
    a=rtpmap:101 telephone-event/8000

日志级别调整
--------------

可以动态调整日志级别以获取更详细的调试信息：

.. code-block:: bash

    # 设置控制台日志级别
    console loglevel debug

    # 设置 sofia 模块的日志级别
    sofia loglevel all 9

    # 查看当前活跃通道
    show channels

    # 查看当前活跃呼叫
    show calls

    # 查看特定通道的详细信息
    uuid_dump <uuid>

抓包分析
----------

除了 FreeSWITCH 内置的 siptrace，还可以使用外部工具进行抓包分析：

.. code-block:: bash

    # 使用 tcpdump 抓取 SIP 数据包
    tcpdump -i eth0 -s 0 -w sip_capture.pcap port 5060 or port 5080

    # 使用 ngrep 实时查看 SIP 消息
    ngrep -W byline -d eth0 port 5060

    # 使用 sngrep 进行交互式 SIP 分析
    sngrep -d eth0 port 5060

抓取的 pcap 文件可以使用 Wireshark 打开，利用其 SIP/RTP 分析功能进行深入排查。
推荐使用 ``sngrep`` 工具，它提供了基于终端的交互式 SIP 消息流可视化界面。


参考资料
============

- `FreeSWITCH 官方文档 <https://freeswitch.org/confluence/>`_
- `FreeSWITCH 权威指南 <https://www.packtpub.com/product/freeswitch-1-8/9781785889134>`_
- `Sofia-SIP 库文档 <https://sofia-sip.sourceforge.net/>`_
- `RFC 3261 - SIP: Session Initiation Protocol <https://tools.ietf.org/html/rfc3261>`_
- `RFC 3711 - The Secure Real-time Transport Protocol (SRTP) <https://tools.ietf.org/html/rfc3711>`_
- `RFC 5246 - The Transport Layer Security (TLS) Protocol <https://tools.ietf.org/html/rfc5246>`_
- `RFC 7118 - The WebSocket Protocol as a Transport for SIP <https://tools.ietf.org/html/rfc7118>`_
- `FreeSWITCH GitHub 仓库 <https://github.com/signalwire/freeswitch>`_
- `mod_sofia 配置参考 <https://freeswitch.org/confluence/display/FREESWITCH/Sofia+Configuration+Files>`_
- `FreeSWITCH NAT 穿越指南 <https://freeswitch.org/confluence/display/FREESWITCH/NAT+Traversal>`_
