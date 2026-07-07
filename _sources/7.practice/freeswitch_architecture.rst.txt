########################
FreeSWITCH 架构
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** FreeSWITCH Architecture
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
========================

FreeSWITCH 采用事件驱动（Event-Driven）的模块化架构设计，其核心思想是将所有功能解耦为独立的模块，
通过统一的事件系统进行通信。这种设计使得 FreeSWITCH 具有极高的灵活性和可扩展性。

与传统的电话交换系统不同，FreeSWITCH 的架构更接近于现代的微内核操作系统设计：
核心引擎只负责最基本的功能（会话管理、事件分发、模块加载），
而所有具体的协议处理、编解码、业务逻辑都由可插拔的模块来实现。


核心架构
========================

FreeSWITCH 的核心架构可以分为以下几个层次：

.. code-block:: text

    +------------------------------------------------------------------+
    |                        外部接口层                                  |
    |  fs_cli | ESL | mod_xml_rpc | mod_event_socket                   |
    +------------------------------------------------------------------+
    |                        应用层                                      |
    |  mod_conference | mod_voicemail | mod_callcenter | mod_ivr        |
    +------------------------------------------------------------------+
    |                        拨号计划层                                   |
    |  mod_dialplan_xml | mod_dialplan_asterisk | mod_dialplan_lua      |
    +------------------------------------------------------------------+
    |                        核心引擎                                    |
    |  Session Manager | Event System | State Machine | Codec Engine   |
    +------------------------------------------------------------------+
    |                        终端层                                      |
    |  mod_sofia (SIP) | mod_verto (WebRTC) | mod_skinny | mod_portaudio|
    +------------------------------------------------------------------+
    |                        基础设施层                                   |
    |  APR (Memory/Thread) | SQLite/PostgreSQL | Logging | XML Parser  |
    +------------------------------------------------------------------+

事件驱动模型
------------------------------

FreeSWITCH 的事件驱动模型是其架构的基石。系统中的每一个状态变化都会产生一个事件（Event），
这些事件通过内部的事件总线（Event Bus）分发给所有订阅者。

事件的生命周期如下：

1. **事件产生** - 某个模块或核心组件检测到状态变化，创建事件对象
2. **事件填充** - 向事件对象中添加头部（Header）和正文（Body）信息
3. **事件分发** - 事件被投递到事件总线
4. **事件消费** - 订阅了该事件类型的模块接收并处理事件

常见的事件类型包括：

.. code-block:: text

    CHANNEL_CREATE      - 通道创建
    CHANNEL_ANSWER      - 通道应答
    CHANNEL_HANGUP      - 通道挂断
    CHANNEL_BRIDGE      - 通道桥接
    CHANNEL_STATE       - 通道状态变化
    DTMF                - DTMF 按键事件
    CODEC               - 编解码器事件
    CUSTOM              - 自定义事件
    HEARTBEAT           - 心跳事件
    RE_SCHEDULE         - 重新调度事件
    API                 - API 调用事件


模块系统
========================

FreeSWITCH 的模块系统是其最重要的扩展机制。每个模块都是一个动态链接库（.so 文件），
在启动时由核心引擎加载。模块通过标准的接口与核心引擎交互。

模块的加载配置在 ``autoload_configs/modules.conf.xml`` 中定义：

.. code-block:: xml

    <configuration name="modules.conf" description="Modules">
      <modules>
        <!-- Endpoints -->
        <load module="mod_sofia"/>
        <load module="mod_verto"/>

        <!-- Applications -->
        <load module="mod_conference"/>
        <load module="mod_voicemail"/>
        <load module="mod_callcenter"/>

        <!-- Codecs -->
        <load module="mod_opus"/>
        <load module="mod_g722"/>

        <!-- Dialplan -->
        <load module="mod_dialplan_xml"/>

        <!-- Event Consumers -->
        <load module="mod_event_socket"/>

        <!-- Languages -->
        <load module="mod_lua"/>
      </modules>
    </configuration>

Endpoint 模块
------------------------------

Endpoint 模块负责处理不同通信协议的终端接入。每个 Endpoint 模块实现了一组标准接口，
使得核心引擎可以统一管理不同协议的通话。

主要的 Endpoint 模块：

* **mod_sofia** - SIP 协议实现，基于 Sofia-SIP 库，是最常用的 Endpoint 模块
* **mod_verto** - WebRTC 协议实现，使用 JSON-RPC over WebSocket
* **mod_skinny** - Cisco Skinny/SCCP 协议支持
* **mod_portaudio** - 本地音频设备接入
* **mod_rtmp** - RTMP 协议支持（用于 Flash 客户端）
* **mod_gsmopen** - GSM 调制解调器接入

Endpoint 模块的核心接口：

.. code-block:: c

    typedef struct {
        switch_io_routines_t *io_routines;       /* I/O 操作 */
        switch_state_handler_table_t *state_handler; /* 状态处理 */
        switch_endpoint_interface_t *interface;  /* 终端接口 */
    } switch_endpoint_module_t;

Codec 模块
------------------------------

Codec 模块提供音视频编解码功能。FreeSWITCH 支持在不同编解码器之间进行实时转码。

主要的 Codec 模块：

* **mod_opus** - Opus 编解码器（WebRTC 推荐）
* **mod_g722** - G.722 宽带音频编解码器
* **mod_g729** - G.729 编解码器（需要许可证）
* **mod_ilbc** - iLBC 编解码器
* **mod_speex** - Speex 编解码器
* **mod_av** - 基于 FFmpeg 的视频编解码器（VP8、H.264 等）
* **mod_b64** - G.711 PCMU/PCMA 编解码器

Application 模块
------------------------------

Application 模块实现具体的业务逻辑，在拨号计划中被调用。

主要的 Application 模块：

* **mod_conference** - 音视频会议
* **mod_voicemail** - 语音信箱
* **mod_callcenter** - 呼叫中心 ACD（Automatic Call Distribution）
* **mod_fifo** - 呼叫队列
* **mod_dptools** - 拨号计划工具集（bridge、transfer、playback 等）
* **mod_commands** - API 命令集
* **mod_db** - 数据库操作
* **mod_httapi** - HTTP 应用接口

Dialplan 模块
------------------------------

Dialplan 模块负责解析拨号计划，决定呼叫的路由和处理流程。

* **mod_dialplan_xml** - XML 格式的拨号计划（默认）
* **mod_dialplan_asterisk** - 兼容 Asterisk 格式的拨号计划
* **mod_dialplan_lua** - 使用 Lua 脚本编写拨号计划

Event Consumer 模块
------------------------------

Event Consumer 模块允许外部系统订阅和处理 FreeSWITCH 的事件。

* **mod_event_socket** - 通过 TCP Socket 暴露事件接口（ESL）
* **mod_erlang_event** - Erlang 事件接口
* **mod_amqp** - AMQP 消息队列事件接口
* **mod_json_cdr** - 将 CDR 以 JSON 格式发送到外部系统


会话与通道模型
========================

会话（Session）
------------------------------

会话是 FreeSWITCH 中最核心的概念之一。每一路通话都对应一个会话对象，
会话管理着通话的整个生命周期。

会话包含以下关键信息：

* **UUID** - 全局唯一标识符
* **Channel** - 通道对象，包含通话的详细信息
* **Codec** - 当前使用的编解码器
* **State** - 当前状态
* **Variables** - 通道变量（Channel Variables）

通道（Channel）
------------------------------

通道是会话的具体实现，代表一条通信链路。通道有一个明确的状态机：

.. code-block:: text

    CS_NEW          → 新建
    CS_INIT         → 初始化
    CS_ROUTING      → 路由中
    CS_SOFT_EXECUTE → 软执行
    CS_EXECUTE      → 执行中
    CS_EXCHANGE_MEDIA → 媒体交换
    CS_PARK         → 驻留
    CS_CONSUME_MEDIA → 媒体消费
    CS_HIBERNATE    → 休眠
    CS_RESET        → 重置
    CS_HANGUP       → 挂断
    CS_REPORTING    → 报告
    CS_DESTROY      → 销毁

通道桥接（Channel Bridge）
------------------------------

当两个通道需要通话时，FreeSWITCH 会将它们桥接在一起。桥接后，
两个通道之间的媒体流直接交换。

.. code-block:: text

    通道 A (Caller)                    通道 B (Callee)
    +----------+                      +----------+
    | Session  |  <--- 媒体流 --->    | Session  |
    | UUID: a1 |                      | UUID: b1 |
    +----------+                      +----------+
         |                                  |
         +------------ Bridge --------------+

桥接可以通过拨号计划中的 ``bridge`` 应用来实现：

.. code-block:: xml

    <action application="bridge" data="sofia/internal/1001@${domain_name}"/>


事件系统（ESL）
========================

ESL（Event Socket Library）是 FreeSWITCH 提供的外部控制接口，
允许外部程序通过 TCP 连接来控制 FreeSWITCH。

ESL 支持两种工作模式：

Inbound 模式
------------------------------

外部程序主动连接到 FreeSWITCH 的 Event Socket 端口（默认 8021）：

.. code-block:: python

    import ESL

    # 连接到 FreeSWITCH
    con = ESL.ESLconnection("127.0.0.1", "8021", "ClueCon")

    # 订阅所有事件
    con.events("plain", "all")

    # 发送 API 命令
    result = con.api("status")
    print(result.getBody())

    # 接收事件
    while True:
        event = con.recvEvent()
        if event:
            print(event.getHeader("Event-Name"))
            print(event.serialize())

Outbound 模式
------------------------------

FreeSWITCH 在处理呼叫时主动连接到外部程序：

.. code-block:: xml

    <!-- 拨号计划中配置 Outbound ESL -->
    <action application="socket" data="127.0.0.1:9090 async full"/>

外部程序监听指定端口，等待 FreeSWITCH 的连接：

.. code-block:: python

    import SocketServer
    import ESL

    class ESLRequestHandler(SocketServer.BaseRequestHandler):
        def handle(self):
            con = ESL.ESLconnection(self.request.fileno())
            info = con.getInfo()
            uuid = info.getHeader("Unique-ID")

            con.execute("answer", "", uuid)
            con.execute("playback", "/sounds/welcome.wav", uuid)
            con.execute("hangup", "", uuid)

    server = SocketServer.TCPServer(("0.0.0.0", 9090), ESLRequestHandler)
    server.serve_forever()

ESL 配置
------------------------------

ESL 的配置文件位于 ``autoload_configs/event_socket.conf.xml``：

.. code-block:: xml

    <configuration name="event_socket.conf" description="Socket Client">
      <settings>
        <param name="nat-map" value="false"/>
        <param name="listen-ip" value="0.0.0.0"/>
        <param name="listen-port" value="8021"/>
        <param name="password" value="ClueCon"/>
        <param name="apply-inbound-acl" value="loopback.auto"/>
      </settings>
    </configuration>


数据库后端
========================

FreeSWITCH 使用数据库来存储运行时数据，包括注册信息、通道状态、CDR 等。

SQLite（默认）
------------------------------

SQLite 是 FreeSWITCH 的默认数据库后端，适用于中小规模部署。
数据库文件存储在 ``/var/lib/freeswitch/db/`` 目录下：

* ``core.db`` - 核心数据（通道、注册等）
* ``sofia_reg_internal.db`` - 内部 SIP Profile 注册信息
* ``sofia_reg_external.db`` - 外部 SIP Profile 注册信息
* ``call_limit.db`` - 呼叫限制数据
* ``fifo.db`` - FIFO 队列数据

PostgreSQL
------------------------------

对于大规模部署，建议使用 PostgreSQL 作为数据库后端。配置方法如下：

.. code-block:: xml

    <!-- switch.conf.xml -->
    <param name="core-db-dsn"
           value="pgsql://hostaddr=127.0.0.1 dbname=freeswitch user=freeswitch password=secret"/>

使用 PostgreSQL 的优势：

* 支持更高的并发访问
* 更好的数据持久性
* 支持远程数据库，便于集群部署
* 更丰富的查询和分析功能


媒体处理管道
========================

FreeSWITCH 的媒体处理管道负责音视频数据的接收、处理和发送。

.. code-block:: text

    接收端                                    发送端
    +--------+    +---------+    +--------+    +--------+
    | RTP    | -> | Jitter  | -> | Decode | -> | App    |
    | Recv   |    | Buffer  |    | (Codec)|    | Process|
    +--------+    +---------+    +--------+    +--------+
                                                   |
    +--------+    +---------+    +--------+    +--------+
    | RTP    | <- | Packe-  | <- | Encode | <- | Mix/   |
    | Send   |    | tizer   |    | (Codec)|    | Route  |
    +--------+    +---------+    +--------+    +--------+

媒体处理的关键步骤：

1. **RTP 接收** - 从网络接收 RTP 数据包
2. **Jitter Buffer** - 抖动缓冲，平滑网络抖动
3. **解码** - 将压缩的音视频数据解码为原始数据
4. **应用处理** - 混音、录制、播放等业务处理
5. **编码** - 将原始数据编码为目标格式
6. **RTP 发送** - 将 RTP 数据包发送到网络


线程模型
========================

FreeSWITCH 采用多线程模型，每个会话都有自己的线程来处理状态机和媒体流。

主要的线程类型：

* **主线程（Main Thread）** - 负责模块加载、信号处理
* **会话线程（Session Thread）** - 每个活跃会话一个线程，处理状态机
* **媒体线程（Media Thread）** - 处理 RTP 收发和编解码
* **事件线程（Event Thread）** - 处理事件分发
* **定时器线程（Timer Thread）** - 提供精确的定时服务
* **数据库线程（DB Thread）** - 异步数据库操作

FreeSWITCH 使用 APR（Apache Portable Runtime）提供的线程和同步原语，
确保跨平台的兼容性。线程池机制避免了频繁创建和销毁线程的开销。


目录结构与配置文件
========================

FreeSWITCH 的默认安装目录结构如下（以 ``/etc/freeswitch`` 为例）：

.. code-block:: text

    /etc/freeswitch/
    ├── freeswitch.xml              # 主配置文件入口
    ├── vars.xml                    # 全局变量定义
    ├── autoload_configs/           # 模块配置目录
    │   ├── modules.conf.xml        # 模块加载配置
    │   ├── sofia.conf.xml          # SIP 模块配置
    │   ├── verto.conf.xml          # WebRTC 模块配置
    │   ├── event_socket.conf.xml   # ESL 配置
    │   ├── conference.conf.xml     # 会议模块配置
    │   └── ...
    ├── dialplan/                   # 拨号计划目录
    │   ├── default.xml             # 默认拨号计划
    │   ├── public.xml              # 公共拨号计划（外部来电）
    │   └── features.xml            # 功能码拨号计划
    ├── directory/                  # 用户目录
    │   └── default/                # 默认域的用户
    │       ├── 1000.xml            # 分机 1000
    │       ├── 1001.xml            # 分机 1001
    │       └── ...
    ├── sip_profiles/               # SIP Profile 配置
    │   ├── internal.xml            # 内部 Profile
    │   └── external.xml            # 外部 Profile
    └── tls/                        # TLS 证书目录
        ├── agent.pem
        ├── cafile.pem
        └── tls.pem

主配置文件
------------------------------

``freeswitch.xml`` 是配置文件的入口，它通过 ``X-PRE-PROCESS`` 指令包含其他配置文件：

.. code-block:: xml

    <?xml version="1.0"?>
    <document type="freeswitch/xml">
      <X-PRE-PROCESS cmd="include" data="vars.xml"/>

      <section name="configuration" description="Various Configuration">
        <X-PRE-PROCESS cmd="include" data="autoload_configs/*.xml"/>
      </section>

      <section name="dialplan" description="Regex/XML Dialplan">
        <X-PRE-PROCESS cmd="include" data="dialplan/*.xml"/>
      </section>

      <section name="directory" description="User Directory">
        <X-PRE-PROCESS cmd="include" data="directory/*.xml"/>
      </section>
    </document>

全局变量
------------------------------

``vars.xml`` 中定义了全局变量，可以在其他配置文件中引用：

.. code-block:: xml

    <include>
      <X-PRE-PROCESS cmd="set" data="default_password=1234"/>
      <X-PRE-PROCESS cmd="set" data="domain=$${local_ip_v4}"/>
      <X-PRE-PROCESS cmd="set" data="domain_name=$${domain}"/>
      <X-PRE-PROCESS cmd="set" data="hold_music=local_stream://moh"/>
      <X-PRE-PROCESS cmd="set" data="external_sip_ip=auto-nat"/>
      <X-PRE-PROCESS cmd="set" data="external_rtp_ip=auto-nat"/>
      <X-PRE-PROCESS cmd="set" data="internal_ssl_enable=true"/>
    </include>


小结
========================

FreeSWITCH 的架构设计体现了现代软件工程的最佳实践：

* **模块化** - 功能解耦，按需加载
* **事件驱动** - 松耦合的组件通信
* **状态机** - 清晰的通道生命周期管理
* **可扩展** - 通过 ESL 和脚本语言轻松扩展

理解 FreeSWITCH 的架构是有效使用和定制它的基础。在后续章节中，
我们将基于这些架构知识，深入探讨 WebRTC 集成、SIP 配置和媒体处理等具体主题。


参考资料
========================

* FreeSWITCH 架构文档: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/
* FreeSWITCH 模块索引: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Modules/
* Event Socket Library: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Client-and-Developer-Interfaces/Event-Socket-Library/
* 《FreeSWITCH 权威指南》 - Anthony Minessale 等著
