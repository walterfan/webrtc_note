##############################
FreeSWITCH ESL 编程
##############################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** FreeSWITCH ESL Programming
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:


概述
========================

ESL（Event Socket Library）是 FreeSWITCH 提供的外部控制接口，
允许外部程序通过 TCP Socket 连接到 FreeSWITCH，实现呼叫控制、事件监听、系统管理等功能。

ESL 是构建 FreeSWITCH 应用的最重要的接口之一，它使得开发者可以使用任何编程语言
（Python、Node.js、Go、Java、C 等）来控制 FreeSWITCH，而不必局限于 Dialplan XML 或内置脚本语言。

ESL 的主要优势：

* **语言无关**：基于文本的 TCP 协议，任何语言都可以实现客户端
* **实时事件**：可以订阅和接收 FreeSWITCH 的各种事件
* **完全控制**：可以执行几乎所有 FreeSWITCH API 命令
* **外部进程**：应用逻辑运行在独立进程中，不影响 FreeSWITCH 核心稳定性
* **可扩展**：可以水平扩展 ESL 应用服务器


Inbound 与 Outbound 模式
========================

ESL 有两种工作模式：

Inbound 模式
--------------

外部程序主动连接到 FreeSWITCH 的 Event Socket 端口（默认 8021）。
这种模式适合全局监控、API 调用、事件订阅等场景。

::

   ┌──────────────┐         ┌──────────────┐
   │  ESL Client  │ ──TCP──→│  FreeSWITCH  │
   │  (外部程序)   │  :8021  │  (ESL Server)│
   └──────────────┘         └──────────────┘

配置文件 ``conf/autoload_configs/event_socket.conf.xml`` ：

.. code-block:: xml

   <configuration name="event_socket.conf" description="Socket Client">
     <settings>
       <param name="nat-map" value="false"/>
       <param name="listen-ip" value="0.0.0.0"/>
       <param name="listen-port" value="8021"/>
       <param name="password" value="ClueCon"/>
       <param name="apply-inbound-acl" value="lan"/>
     </settings>
   </configuration>

.. warning::

   生产环境中务必修改默认密码 ``ClueCon`` ，并通过 ACL 限制访问来源。
   建议仅允许内网 IP 访问 8021 端口。

Outbound 模式
--------------

FreeSWITCH 在处理呼叫时主动连接到外部程序。
这种模式适合对单个呼叫进行精细控制的场景，如 IVR、呼叫路由等。

::

   ┌──────────────┐         ┌──────────────┐
   │  FreeSWITCH  │ ──TCP──→│  ESL Server  │
   │  (ESL Client)│  :9090  │  (外部程序)   │
   └──────────────┘         └──────────────┘

在 Dialplan 中配置 Outbound ESL：

.. code-block:: xml

   <extension name="outbound-esl">
     <condition field="destination_number" expression="^(8\d{3})$">
       <action application="socket"
               data="127.0.0.1:9090 async full"/>
     </condition>
   </extension>

参数说明：

* ``async`` ：异步模式，允许在等待命令结果时继续接收事件
* ``full`` ：完整模式，接收所有通道变量


ESL 协议详解
========================

ESL 使用基于文本的协议，类似于 HTTP。每条消息由 Header 和可选的 Body 组成，
以空行分隔。

认证流程
-----------

连接建立后，FreeSWITCH 发送认证请求：

.. code-block:: text

   Content-Type: auth/request

客户端发送密码：

.. code-block:: text

   auth ClueCon

认证成功响应：

.. code-block:: text

   Content-Type: command/reply
   Reply-Text: +OK accepted

发送命令
-----------

API 命令格式：

.. code-block:: text

   api <command> <args>

   # 示例
   api status
   api show channels
   api originate user/1001 &echo

后台 API 命令（异步执行）：

.. code-block:: text

   bgapi <command> <args>
   Job-UUID: <uuid>

   # 示例
   bgapi originate user/1001 &echo

事件订阅
-----------

订阅事件：

.. code-block:: text

   event plain CHANNEL_CREATE CHANNEL_ANSWER CHANNEL_HANGUP

   # 订阅所有事件
   event plain ALL

   # 使用 JSON 格式
   event json ALL

事件过滤：

.. code-block:: text

   # 只接收特定通道的事件
   filter Unique-ID <uuid>

   # 只接收特定事件头的事件
   filter Event-Name CHANNEL_EXECUTE

事件消息格式
--------------

.. code-block:: text

   Content-Length: 1234
   Content-Type: text/event-plain

   Event-Name: CHANNEL_ANSWER
   Core-UUID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
   FreeSWITCH-Hostname: fs01
   Event-Date-Local: 2024-01-15 10:30:45
   Unique-ID: 12345678-abcd-ef01-2345-678901234567
   Caller-Caller-ID-Name: John Doe
   Caller-Caller-ID-Number: 1001
   Caller-Destination-Number: 1002
   Channel-State: CS_EXECUTE


Python ESL 客户端
========================

原生 ESL 模块
--------------

FreeSWITCH 提供了原生的 Python ESL 绑定：

.. code-block:: python

   import ESL

   # Inbound 连接
   con = ESL.ESLconnection("127.0.0.1", "8021", "ClueCon")

   if con.connected():
       # 执行 API 命令
       result = con.api("status")
       print(result.getBody())

       # 执行后台 API 命令
       result = con.bgapi("originate", "user/1001 &echo")
       job_uuid = result.getHeader("Job-UUID")
       print(f"Job UUID: {job_uuid}")

       # 订阅事件
       con.events("plain", "CHANNEL_CREATE CHANNEL_ANSWER CHANNEL_HANGUP")

       # 事件循环
       while True:
           event = con.recvEvent()
           if event:
               event_name = event.getHeader("Event-Name")
               unique_id = event.getHeader("Unique-ID")
               print(f"Event: {event_name}, UUID: {unique_id}")

greenswitch 库
-----------------

``greenswitch`` 是一个基于 gevent 的 Python ESL 库，支持异步操作：

.. code-block:: bash

   pip install greenswitch

.. code-block:: python

   import greenswitch

   # Inbound 模式
   fs = greenswitch.InboundESL(
       host="127.0.0.1",
       port=8021,
       password="ClueCon"
   )
   fs.connect()

   # 执行 API 命令
   result = fs.send("api status")
   print(result.data)

   # 订阅事件
   fs.send("event plain CHANNEL_CREATE CHANNEL_HANGUP")

   # 注册事件处理器
   @fs.handle_event("CHANNEL_CREATE")
   def on_channel_create(event):
       caller = event.headers.get("Caller-Caller-ID-Number")
       dest = event.headers.get("Caller-Destination-Number")
       print(f"New call: {caller} -> {dest}")

   @fs.handle_event("CHANNEL_HANGUP")
   def on_channel_hangup(event):
       uuid = event.headers.get("Unique-ID")
       cause = event.headers.get("Hangup-Cause")
       print(f"Hangup: {uuid}, Cause: {cause}")

   # 启动事件循环
   fs.process_events()

Outbound 模式示例
-------------------

.. code-block:: python

   import greenswitch

   # Outbound 模式 - 作为服务器等待 FreeSWITCH 连接
   server = greenswitch.OutboundESLServer(
       bind_address="0.0.0.0",
       bind_port=9090
   )

   def handle_call(session):
       """处理每个呼入的呼叫"""
       caller = session.get_var("Caller-Caller-ID-Number")
       dest = session.get_var("Caller-Destination-Number")
       print(f"Incoming call: {caller} -> {dest}")

       # 接听
       session.answer()
       session.sleep(500)

       # 播放提示音并收集输入
       session.execute("play_and_get_digits",
                       "1 1 3 5000 # ivr/ivr-menu.wav "
                       "ivr/ivr-invalid.wav input \\d 10000")

       digits = session.get_var("input")

       if digits == "1":
           session.execute("bridge", "user/1001@default")
       elif digits == "2":
           session.execute("bridge", "user/1002@default")
       else:
           session.execute("playback", "ivr/ivr-exit.wav")
           session.hangup()

   server.handle = handle_call
   server.start()


Node.js ESL 客户端
========================

``modesl`` 是 Node.js 中常用的 ESL 客户端库：

.. code-block:: bash

   npm install modesl

Inbound 模式
--------------

.. code-block:: javascript

   const esl = require('modesl');

   const conn = new esl.Connection('127.0.0.1', 8021, 'ClueCon', function() {
       console.log('Connected to FreeSWITCH');

       // 执行 API 命令
       conn.api('status', function(res) {
           console.log('Status:', res.getBody());
       });

       // 订阅事件
       conn.subscribe([
           'CHANNEL_CREATE',
           'CHANNEL_ANSWER',
           'CHANNEL_HANGUP'
       ]);

       // 监听事件
       conn.on('esl::event::CHANNEL_CREATE::*', function(event) {
           const caller = event.getHeader('Caller-Caller-ID-Number');
           const dest = event.getHeader('Caller-Destination-Number');
           console.log(`New call: ${caller} -> ${dest}`);
       });

       conn.on('esl::event::CHANNEL_HANGUP::*', function(event) {
           const uuid = event.getHeader('Unique-ID');
           const cause = event.getHeader('Hangup-Cause');
           console.log(`Hangup: ${uuid}, Cause: ${cause}`);
       });
   });

   conn.on('error', function(err) {
       console.error('Connection error:', err);
   });

Outbound 模式
--------------

.. code-block:: javascript

   const esl = require('modesl');

   const server = new esl.Server({port: 9090, myevents: true}, function() {
       console.log('ESL Outbound Server listening on port 9090');
   });

   server.on('connection::ready', function(conn, id) {
       console.log(`New call connected: ${id}`);

       const caller = conn.getInfo().getHeader('Caller-Caller-ID-Number');
       const dest = conn.getInfo().getHeader('Caller-Destination-Number');
       console.log(`Call from ${caller} to ${dest}`);

       // 接听并播放提示音
       conn.execute('answer', '', function() {
           conn.execute('sleep', '500', function() {
               conn.execute('playback', 'ivr/ivr-welcome.wav', function() {
                   conn.execute('play_and_get_digits',
                       '1 1 3 5000 # ivr/ivr-menu.wav ivr/ivr-invalid.wav input \\d 10000',
                       function() {
                           const digits = conn.getInfo()
                               .getHeader('variable_input');
                           handleInput(conn, digits);
                       }
                   );
               });
           });
       });
   });

   function handleInput(conn, digits) {
       switch (digits) {
           case '1':
               conn.execute('bridge', 'user/1001@default');
               break;
           case '2':
               conn.execute('bridge', 'user/1002@default');
               break;
           default:
               conn.execute('playback', 'ivr/ivr-exit.wav', function() {
                   conn.execute('hangup');
               });
       }
   }


Go ESL 客户端
========================

Go 语言中有多个 ESL 客户端库，以下使用 ``github.com/percipia/eslgo`` ：

.. code-block:: bash

   go get github.com/percipia/eslgo

.. code-block:: go

   package main

   import (
       "context"
       "fmt"
       "log"

       "github.com/percipia/eslgo"
   )

   func main() {
       conn, err := eslgo.Dial("127.0.0.1:8021", "ClueCon", func() {
           fmt.Println("Connection established")
       })
       if err != nil {
           log.Fatal("Failed to connect:", err)
       }
       defer conn.Close()

       ctx := context.Background()

       // 执行 API 命令
       result, err := conn.SendCommand(ctx, command.API{
           Command: "status",
       })
       if err == nil {
           fmt.Println("Status:", result)
       }

       // 订阅事件
       conn.SendCommand(ctx, command.Event{
           Format: "plain",
           Listen: []string{"CHANNEL_CREATE", "CHANNEL_HANGUP"},
       })

       // 事件循环
       for {
           event, err := conn.ReadEvent()
           if err != nil {
               log.Println("Error reading event:", err)
               break
           }

           eventName := event.GetHeader("Event-Name")
           switch eventName {
           case "CHANNEL_CREATE":
               caller := event.GetHeader("Caller-Caller-ID-Number")
               dest := event.GetHeader("Caller-Destination-Number")
               fmt.Printf("New call: %s -> %s\n", caller, dest)
           case "CHANNEL_HANGUP":
               uuid := event.GetHeader("Unique-ID")
               cause := event.GetHeader("Hangup-Cause")
               fmt.Printf("Hangup: %s, Cause: %s\n", uuid, cause)
           }
       }
   }


常用 ESL 命令
========================

.. list-table:: 常用 ESL 命令
   :header-rows: 1
   :widths: 25 35 40

   * - 命令
     - 语法
     - 说明
   * - auth
     - ``auth <password>``
     - 认证
   * - api
     - ``api <command> [args]``
     - 同步执行 API 命令
   * - bgapi
     - ``bgapi <command> [args]``
     - 异步执行 API 命令
   * - event
     - ``event <format> <event_types>``
     - 订阅事件
   * - noevents
     - ``noevents``
     - 取消所有事件订阅
   * - filter
     - ``filter <header> <value>``
     - 过滤事件
   * - filter delete
     - ``filter delete <header> <value>``
     - 删除事件过滤器
   * - sendevent
     - ``sendevent <event_name>``
     - 发送自定义事件
   * - sendmsg
     - ``sendmsg <uuid>``
     - 向特定通道发送消息
   * - linger
     - ``linger [seconds]``
     - 通道挂断后保持连接
   * - myevents
     - ``myevents <uuid>``
     - 只接收指定通道的事件
   * - divert_events
     - ``divert_events on``
     - 将嵌入式事件转发到 Socket
   * - log
     - ``log <level>``
     - 接收日志消息
   * - nolog
     - ``nolog``
     - 停止接收日志
   * - exit
     - ``exit``
     - 断开连接


构建呼叫控制应用
========================

以下是一个完整的呼叫控制应用示例，使用 Python 实现 Click-to-Call 功能：

.. code-block:: python

   #!/usr/bin/env python3
   """
   Click-to-Call 应用
   通过 REST API 触发呼叫，使用 ESL 控制 FreeSWITCH
   """

   from flask import Flask, request, jsonify
   import ESL

   app = Flask(__name__)

   FS_HOST = "127.0.0.1"
   FS_PORT = "8021"
   FS_PASSWORD = "ClueCon"

   def get_esl_connection():
       con = ESL.ESLconnection(FS_HOST, FS_PORT, FS_PASSWORD)
       if not con.connected():
           raise Exception("Failed to connect to FreeSWITCH")
       return con

   @app.route('/api/call', methods=['POST'])
   def make_call():
       """发起呼叫"""
       data = request.json
       caller = data.get('caller')
       callee = data.get('callee')

       if not caller or not callee:
           return jsonify({"error": "caller and callee required"}), 400

       try:
           con = get_esl_connection()
           cmd = (f"originate "
                  f"{{origination_caller_id_number={caller}}}"
                  f"user/{caller}@default "
                  f"&bridge(user/{callee}@default)")
           result = con.bgapi("originate", cmd)
           job_uuid = result.getHeader("Job-UUID")
           return jsonify({"status": "ok", "job_uuid": job_uuid})
       except Exception as e:
           return jsonify({"error": str(e)}), 500

   @app.route('/api/hangup', methods=['POST'])
   def hangup_call():
       """挂断呼叫"""
       data = request.json
       channel_uuid = data.get('uuid')

       try:
           con = get_esl_connection()
           result = con.api("uuid_kill", channel_uuid)
           return jsonify({"status": "ok", "result": result.getBody()})
       except Exception as e:
           return jsonify({"error": str(e)}), 500

   @app.route('/api/channels', methods=['GET'])
   def list_channels():
       """列出活跃通道"""
       try:
           con = get_esl_connection()
           result = con.api("show", "channels as json")
           return result.getBody(), 200, {'Content-Type': 'application/json'}
       except Exception as e:
           return jsonify({"error": str(e)}), 500

   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)


事件类型参考
========================

.. list-table:: 常用事件类型
   :header-rows: 1
   :widths: 30 70

   * - 事件名称
     - 说明
   * - CHANNEL_CREATE
     - 通道创建
   * - CHANNEL_ANSWER
     - 通道应答
   * - CHANNEL_HANGUP
     - 通道挂断
   * - CHANNEL_HANGUP_COMPLETE
     - 通道挂断完成（包含完整 CDR 信息）
   * - CHANNEL_BRIDGE
     - 通道桥接
   * - CHANNEL_UNBRIDGE
     - 通道取消桥接
   * - CHANNEL_EXECUTE
     - 通道执行 Application
   * - CHANNEL_EXECUTE_COMPLETE
     - Application 执行完成
   * - DTMF
     - 收到 DTMF 按键
   * - RECORD_START
     - 开始录音
   * - RECORD_STOP
     - 停止录音
   * - CUSTOM
     - 自定义事件（如 conference::maintenance）
   * - HEARTBEAT
     - 心跳事件（每 20 秒一次）
   * - BACKGROUND_JOB
     - 后台任务完成


ESL 应用最佳实践
========================

1. **连接池管理**：不要为每个请求创建新连接，使用连接池复用 ESL 连接
2. **异步优先**：对于耗时操作使用 ``bgapi`` 而非 ``api`` ，避免阻塞
3. **事件过滤**：只订阅需要的事件，避免接收大量无关事件造成性能问题
4. **错误处理**：妥善处理连接断开、超时等异常情况，实现自动重连
5. **日志记录**：记录关键操作和事件，便于问题排查
6. **安全加固**：修改默认密码，限制 ESL 端口的访问来源
7. **心跳检测**：定期发送 ``api status`` 检测连接是否存活
8. **优雅关闭**：应用退出时正确关闭 ESL 连接，释放资源

.. code-block:: python

   # 连接池示例
   import queue
   import ESL

   class ESLConnectionPool:
       def __init__(self, host, port, password, pool_size=5):
           self.host = host
           self.port = port
           self.password = password
           self.pool = queue.Queue(maxsize=pool_size)
           for _ in range(pool_size):
               self.pool.put(self._create_connection())

       def _create_connection(self):
           con = ESL.ESLconnection(self.host, self.port, self.password)
           if not con.connected():
               raise Exception("Failed to connect")
           return con

       def get(self):
           con = self.pool.get(timeout=5)
           if not con.connected():
               con = self._create_connection()
           return con

       def put(self, con):
           if con.connected():
               self.pool.put(con)
           else:
               self.pool.put(self._create_connection())


参考资料
========================

* FreeSWITCH Event Socket Library: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Client-and-Developer-Interfaces/Event-Socket-Library/
* FreeSWITCH Event List: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Introduction/Event-System/Event-List_7143557/
* greenswitch: https://github.com/EvoluxBR/greenswitch
* modesl (Node.js): https://github.com/nicknisi/modesl
* eslgo (Go): https://github.com/percipia/eslgo
