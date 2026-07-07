########################
FreeSWITCH 概述
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** FreeSWITCH Overview
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
========================

FreeSWITCH 是一个开源的、跨平台的电话软交换平台（Telephony Soft Switch Platform），由 Anthony Minessale 于 2006 年创建。
它被设计为一个可扩展的、多协议的通信引擎，能够处理语音、视频、文本等多种媒体类型。

FreeSWITCH 的核心设计理念是模块化和可扩展性。它不仅仅是一个 PBX（Private Branch Exchange，专用交换机），
更是一个通用的通信平台，可以用于构建各种实时通信应用，包括：

* IP PBX 系统
* IVR（Interactive Voice Response，交互式语音应答）系统
* 会议桥（Conference Bridge）
* WebRTC 网关
* SIP 代理和 B2BUA（Back-to-Back User Agent）
* 呼叫中心平台
* VoIP 运营商级交换系统

FreeSWITCH 使用 C 语言编写，运行在 Linux、macOS、Windows 等多种操作系统上，
具有极高的性能和稳定性，单台服务器可以处理数千路并发通话。


历史与社区
========================

FreeSWITCH 项目的诞生与 Asterisk 有着密切的关系。Anthony Minessale 曾是 Asterisk 项目的核心开发者之一，
他在开发过程中发现 Asterisk 的架构存在一些根本性的限制，特别是在多线程处理和可扩展性方面。
因此，他决定从零开始设计一个全新的通信平台。

关键里程碑：

* **2006 年** - FreeSWITCH 项目启动，采用全新的模块化架构设计
* **2008 年** - 发布 1.0 版本，开始被企业级用户采用
* **2012 年** - 增加 WebRTC 支持（mod_verto）
* **2014 年** - 发布 1.4 版本，大幅改进视频会议功能
* **2016 年** - 发布 1.6 版本，增强 WebRTC 和视频支持
* **2019 年** - 发布 1.10 版本，持续改进稳定性和性能
* **2020 年至今** - SignalWire 公司持续维护和商业化支持

FreeSWITCH 拥有活跃的开源社区，主要交流渠道包括：

* 官方网站：https://freeswitch.org
* GitHub 仓库：https://github.com/signalwire/freeswitch
* Slack 频道：https://signalwire-community.slack.com
* 邮件列表和 Confluence Wiki
* 每年举办 ClueCon 大会（FreeSWITCH 开发者大会）


架构概览
========================

FreeSWITCH 采用事件驱动（Event-Driven）的模块化架构，其核心组件包括：

核心引擎（Core）
------------------------

核心引擎负责以下功能：

* **会话管理（Session Management）** - 管理所有通话会话的生命周期
* **事件系统（Event System）** - 基于发布/订阅模式的内部事件分发机制
* **线程管理（Thread Management）** - 高效的多线程调度
* **内存管理（Memory Management）** - 基于 APR（Apache Portable Runtime）的内存池
* **数据库抽象层** - 支持 SQLite 和 PostgreSQL

模块系统（Module System）
------------------------------

FreeSWITCH 的功能通过模块来扩展，主要模块类型包括：

* **Endpoint 模块** - 处理不同协议的终端接入，如 mod_sofia（SIP）、mod_verto（WebRTC）
* **Codec 模块** - 音视频编解码器，如 mod_opus、mod_h264
* **Application 模块** - 呼叫处理应用，如 mod_conference、mod_voicemail
* **Dialplan 模块** - 拨号计划处理，如 mod_dialplan_xml
* **Event Consumer 模块** - 事件消费者，如 mod_event_socket

事件系统（Event System）
------------------------------

FreeSWITCH 的事件系统是其架构的核心，所有内部状态变化都通过事件来传递。
ESL（Event Socket Library）允许外部程序通过 TCP 连接订阅和发送事件，
这使得开发者可以使用任何编程语言来控制 FreeSWITCH。

.. code-block:: text

    +---------------------------------------------------+
    |                  FreeSWITCH Core                   |
    |                                                   |
    |  +----------+  +---------+  +------------------+  |
    |  | Session  |  | Event   |  | Thread           |  |
    |  | Manager  |  | System  |  | Manager          |  |
    |  +----------+  +---------+  +------------------+  |
    |                                                   |
    |  +----------+  +---------+  +------------------+  |
    |  | Memory   |  | DB      |  | Module           |  |
    |  | Pool     |  | Layer   |  | Loader           |  |
    |  +----------+  +---------+  +------------------+  |
    +---------------------------------------------------+
           |              |               |
    +------+------+ +-----+-----+ +-------+-------+
    |  Endpoints  | | Codecs    | | Applications  |
    | mod_sofia   | | mod_opus  | | mod_conference|
    | mod_verto   | | mod_h264  | | mod_voicemail |
    | mod_skinny  | | mod_g722  | | mod_callcenter|
    +-------------+ +-----------+ +---------------+


与其他项目的比较
========================

FreeSWITCH vs Asterisk
------------------------------

.. list-table:: FreeSWITCH 与 Asterisk 对比
   :header-rows: 1
   :widths: 25 35 35

   * - 特性
     - FreeSWITCH
     - Asterisk
   * - 架构
     - 模块化、事件驱动、多线程
     - 单线程模型（较新版本有改进）
   * - 编程语言
     - C
     - C
   * - WebRTC 支持
     - 原生支持（mod_verto）
     - 通过 WebSocket + SIP
   * - 视频支持
     - 原生视频会议、转码
     - 基本视频透传
   * - 可扩展性
     - 高（支持集群）
     - 中等
   * - 协议支持
     - SIP, Verto, Skinny, H.323 等
     - SIP, IAX2, Skinny 等
   * - 配置方式
     - XML 配置文件
     - 文本配置文件（.conf）
   * - 社区规模
     - 中等
     - 大
   * - 学习曲线
     - 较陡
     - 中等

FreeSWITCH vs Opal
------------------------------

Opal（Open Phone Abstraction Library）是一个 C++ 编写的开源 VoIP 库，
主要用于构建 VoIP 客户端应用。与 FreeSWITCH 相比，Opal 更偏向于客户端库而非服务器平台。
FreeSWITCH 是一个完整的通信服务器，而 Opal 是一个可嵌入的通信库。

FreeSWITCH vs Kamailio
------------------------------

Kamailio 是一个高性能的 SIP 代理服务器，主要用于 SIP 信令路由。
与 FreeSWITCH 不同，Kamailio 不处理媒体流。在大规模部署中，
通常将 Kamailio 作为 SIP 代理前端，FreeSWITCH 作为媒体处理后端。


核心特性
========================

多协议支持
------------------------------

FreeSWITCH 支持多种通信协议：

* **SIP（Session Initiation Protocol）** - 通过 mod_sofia 模块实现，支持 UDP、TCP、TLS
* **WebRTC** - 通过 mod_verto 模块实现，支持 WebSocket Secure（WSS）
* **PSTN** - 通过 SIP Trunk 或 TDM 网关接入传统电话网络
* **Skinny/SCCP** - 思科电话协议支持
* **H.323** - 通过 mod_h323 或 mod_opal 模块支持

编解码器支持
------------------------------

FreeSWITCH 支持丰富的音视频编解码器：

* **音频编解码器** - G.711（PCMU/PCMA）、G.722、G.729、Opus、iLBC、Speex、AMR 等
* **视频编解码器** - VP8、H.264、H.263 等
* **支持实时转码** - 可以在不同编解码器之间进行实时转换

集群与高可用
------------------------------

FreeSWITCH 支持多种集群方案：

* 基于 SIP 代理（如 Kamailio）的负载均衡
* 数据库共享的多节点部署
* SignalWire Stack 提供的商业集群方案


典型应用场景
========================

IP PBX
------------------------------

FreeSWITCH 可以作为企业级 IP PBX 使用，提供：

* 分机注册和管理
* 呼叫转移、呼叫等待、三方通话
* 语音信箱
* 自动话务员（Auto Attendant）
* CDR（Call Detail Record）记录

IVR 系统
------------------------------

通过 mod_ivr 和 Lua/JavaScript 脚本，可以构建复杂的 IVR 流程：

.. code-block:: xml

    <extension name="ivr_demo">
      <condition field="destination_number" expression="^5000$">
        <action application="answer"/>
        <action application="sleep" data="1000"/>
        <action application="ivr" data="demo_ivr"/>
      </condition>
    </extension>

会议桥
------------------------------

mod_conference 模块提供强大的音视频会议功能：

* 支持数百人同时参会
* 视频会议布局（Video Layout）
* 会议录制
* 主持人控制（静音、踢出等）
* DTMF 控制

WebRTC 网关
------------------------------

FreeSWITCH 可以作为 WebRTC 网关，将浏览器客户端与传统 SIP/PSTN 网络桥接：

.. code-block:: text

    浏览器 (WebRTC) <--WSS/Verto--> FreeSWITCH <--SIP--> PSTN/SIP 网络


安装方法
========================

从源码编译
------------------------------

.. code-block:: bash

    # 安装依赖（Debian/Ubuntu）
    sudo apt-get update
    sudo apt-get install -y git-core build-essential autoconf automake libtool \
        libncurses5 libncurses5-dev make libjpeg-dev pkg-config \
        libsqlite3-dev libcurl4-openssl-dev libpcre3-dev libspeexdsp-dev \
        libldns-dev libedit-dev libavformat-dev libswscale-dev libavresample-dev \
        liblua5.2-dev libopus-dev libpq-dev libsndfile1-dev libflac-dev \
        libogg-dev libvorbis-dev

    # 克隆源码
    git clone https://github.com/signalwire/freeswitch.git
    cd freeswitch

    # 编译安装
    ./bootstrap.sh -j
    ./configure
    make -j$(nproc)
    sudo make install

    # 安装声音文件
    sudo make cd-sounds-install cd-moh-install

使用包管理器安装
------------------------------

.. code-block:: bash

    # Debian/Ubuntu
    sudo apt-get update && sudo apt-get install -y gnupg2 wget lsb-release

    wget -O - https://files.freeswitch.org/repo/deb/debian-release/fsstretch-archive-keyring.asc \
        | sudo apt-key add -

    echo "deb http://files.freeswitch.org/repo/deb/debian-release/ \
        $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/freeswitch.list

    sudo apt-get update
    sudo apt-get install -y freeswitch-meta-all

使用 Docker 安装
------------------------------

.. code-block:: bash

    # 使用官方 Docker 镜像
    docker pull signalwire/freeswitch

    # 运行 FreeSWITCH 容器
    docker run -d --name freeswitch \
        --network host \
        -v /etc/freeswitch:/etc/freeswitch \
        signalwire/freeswitch

    # 或者使用 docker-compose
    # docker-compose.yml 示例
    cat <<EOF > docker-compose.yml
    version: '3'
    services:
      freeswitch:
        image: signalwire/freeswitch
        network_mode: host
        volumes:
          - ./conf:/etc/freeswitch
          - ./logs:/var/log/freeswitch
          - ./recordings:/var/lib/freeswitch/recordings
        restart: unless-stopped
    EOF

    docker-compose up -d

启动与验证
------------------------------

.. code-block:: bash

    # 启动 FreeSWITCH
    sudo systemctl start freeswitch

    # 连接到 FreeSWITCH 控制台
    fs_cli

    # 在 fs_cli 中查看状态
    freeswitch@hostname> status
    freeswitch@hostname> sofia status
    freeswitch@hostname> show registrations

    # 查看版本信息
    freeswitch@hostname> version


小结
========================

FreeSWITCH 是一个功能强大、架构先进的开源通信平台。它的模块化设计使其能够适应各种通信场景，
从简单的 IP PBX 到复杂的 WebRTC 网关和大规模呼叫中心。虽然学习曲线相对较陡，
但其灵活性和性能使其成为构建实时通信系统的优秀选择。

在后续章节中，我们将深入探讨 FreeSWITCH 的架构细节、WebRTC 集成、SIP 配置和媒体处理等主题。


参考资料
========================

* FreeSWITCH 官方网站: https://freeswitch.org
* FreeSWITCH GitHub: https://github.com/signalwire/freeswitch
* FreeSWITCH 官方文档: https://developer.signalwire.com/freeswitch/
* 《FreeSWITCH 权威指南》 - Anthony Minessale 等著
* ClueCon 大会: https://www.cluecon.com
