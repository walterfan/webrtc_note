##########
Kitty
##########


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ===============================
**Abstract** Kitty 模糊测试框架
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ===============================



.. contents::
   :local:


概述
================

Kitty 是 Cisco 开源的一个模块化、可扩展的模糊测试（fuzzing）框架，用 Python 编写，灵感来自 Sulley 和 Peach Fuzzer。

Kitty **不是** 一个开箱即用的 fuzzer，它也不包含任何特定协议的实现。
它是一个框架，你可以用它来构建针对各种目标（包括私有协议、非 TCP/IP 通信通道等）的自定义 fuzzer。

在 WebRTC 开发中，Kitty 可以用于：

- 对信令协议（WebSocket、SDP）进行模糊测试
- 对 RTP/RTCP 包的字段进行变异测试
- 对 STUN/TURN 消息进行安全测试
- 发现协议实现中的边界条件和崩溃问题


安装
================

.. code-block:: bash

   pip install kittyfuzzer

配套的协议实现库：

.. code-block:: bash

   pip install katnip


框架架构
================

.. code-block:: text

   Fuzzer ─── Model ─── Template ─── Field
     │
     ├─── Target ─── Controller
     │            └── Monitor(s)
     │
     └─── Interface (Web UI)

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - 模块
     - 职责
   * - **Data Model**
     - 定义消息结构：字段类型（字符串、整数、校验和、长度等）、字段关系、消息顺序
   * - **Target**
     - 管理被测目标的交互，分为 ``ServerTarget``（测试服务端）和 ``ClientTarget``（测试客户端）
   * - **Controller**
     - 控制被测目标的状态（启动、重启、重置等），确保每次测试前目标处于正确状态
   * - **Monitor**
     - 监控被测目标的行为（网络流量、内存消耗、串口输出、崩溃信号等），支持多个 Monitor 并行
   * - **Fuzzer**
     - 驱动整个模糊测试流程：从 Model 获取变异负载 → 通过 Target 发送 → 收集报告
   * - **Interface**
     - 用户界面（内置 Web UI），用于监控测试进度和结果


核心概念
================

数据模型
--------------------------

数据模型是 Kitty 的核心，用于定义消息的结构和变异策略：

.. code-block:: python

   from kitty.model import Template, String, UInt32, Static

   # 定义一个简单的消息模板
   hello_template = Template(
       name='hello',
       fields=[
           Static(name='magic', value=b'\x00\x01'),
           UInt32(name='length', value=10),
           String(name='payload', value='hello'),
       ]
   )

Kitty 支持丰富的字段类型：

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 字段类型
     - 说明
   * - ``String``
     - 字符串，支持各种变异（空串、超长、特殊字符等）
   * - ``UInt8/16/32``
     - 无符号整数，支持边界值变异
   * - ``Static``
     - 固定值，不参与变异
   * - ``BitField``
     - 位域
   * - ``Checksum``
     - 校验和，根据其他字段自动计算
   * - ``Size``
     - 长度字段，根据其他字段的大小自动计算
   * - ``RandomBytes``
     - 随机字节序列
   * - ``Group``
     - 一组预定义值的枚举

有状态的多消息模糊
--------------------------

Kitty 支持多阶段的有状态模糊测试，例如先通过认证阶段再测试后续功能：

.. code-block:: python

   from kitty.model import GraphModel, Template, String

   auth_template = Template(name='auth', fields=[
       String(name='username', value='admin'),
       String(name='password', value='password'),
   ])

   command_template = Template(name='command', fields=[
       String(name='cmd', value='GET /resource'),
   ])

   model = GraphModel()
   model.connect(auth_template)
   model.connect(auth_template, command_template)


Server Fuzzing 示例
================

测试一个 TCP 服务端：

.. code-block:: python

   from kitty.fuzzers import ServerFuzzer
   from kitty.model import GraphModel, Template, String
   from kitty.interfaces import WebInterface
   from katnip.targets.tcp import TcpTarget

   target = TcpTarget(
       name='target',
       host='127.0.0.1',
       port=8080,
       timeout=2
   )

   model = GraphModel()
   model.connect(Template(
       name='request',
       fields=[
           String(name='method', value='GET'),
           String(name='path', value='/api/test'),
       ]
   ))

   fuzzer = ServerFuzzer()
   fuzzer.set_target(target)
   fuzzer.set_model(model)
   fuzzer.set_interface(WebInterface(port=26000))
   fuzzer.start()

启动后访问 ``http://localhost:26000`` 可以在 Web 界面中监控测试进度。


Client Fuzzing 示例
================

测试一个客户端应用（fuzzer 作为服务端，向客户端发送变异响应）：

.. code-block:: python

   from kitty.fuzzers import ClientFuzzer
   from kitty.model import GraphModel, Template, String, UInt32
   from katnip.targets.tcp import TcpTarget

   model = GraphModel()
   model.connect(Template(
       name='response',
       fields=[
           UInt32(name='status_code', value=200),
           String(name='body', value='{"result": "ok"}'),
       ]
   ))

   fuzzer = ClientFuzzer()
   fuzzer.set_model(model)
   # ... configure target and start


WebRTC 相关应用场景
============================

Kitty 框架可以应用于 WebRTC 协议栈的多个层面：

SDP 模糊测试
--------------------------

对 SDP 消息的各个字段进行变异，测试 SDP 解析器的健壮性：

.. code-block:: python

   from kitty.model import Template, String, Static, Group

   sdp_template = Template(
       name='sdp_offer',
       fields=[
           Static(name='version', value='v=0\r\n'),
           String(name='origin', value='o=- 123456 2 IN IP4 127.0.0.1\r\n'),
           String(name='session', value='s=-\r\n'),
           String(name='timing', value='t=0 0\r\n'),
           String(name='media', value='m=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'),
           String(name='codec', value='a=rtpmap:111 opus/48000/2\r\n'),
           String(name='candidate',
                  value='a=candidate:1 1 udp 2130706431 192.168.1.1 5004 typ host\r\n'),
       ]
   )

STUN 消息模糊测试
--------------------------

.. code-block:: python

   from kitty.model import Template, Static, UInt16, UInt32, RandomBytes

   stun_template = Template(
       name='stun_binding_request',
       fields=[
           Static(name='msg_type', value=b'\x00\x01'),
           UInt16(name='msg_length', value=0),
           Static(name='magic_cookie', value=b'\x21\x12\xa4\x42'),
           RandomBytes(name='transaction_id', value=b'\x00' * 12, min_length=12, max_length=12),
       ]
   )


Katnip：协议实现库
============================

Katnip 是 Kitty 的配套库，提供常用的 Target、Controller 和 Monitor 实现：

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - 组件
     - 说明
   * - ``TcpTarget``
     - TCP 连接目标
   * - ``SslTarget``
     - TLS/SSL 连接目标
   * - ``UdpTarget``
     - UDP 连接目标
   * - ``SerialTarget``
     - 串口连接目标
   * - ``LocalProcessController``
     - 本地进程控制器
   * - ``ProcessMonitor``
     - 进程监控器

安装：

.. code-block:: bash

   pip install katnip


参考
========================

- Kitty 源码: https://github.com/cisco-sas/kitty
- Kitty 文档: https://kitty.readthedocs.io/
- Katnip 源码: https://github.com/cisco-sas/katnip
- Kitty Server Fuzzing 教程: https://kitty.readthedocs.io/en/latest/tutorials/server_fuzzing.html
- Kitty Client Fuzzing 教程: https://kitty.readthedocs.io/en/latest/tutorials/client_fuzzing.html
