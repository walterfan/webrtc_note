################################
FreeSWITCH 故障排查
################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ====================================
**Abstract** FreeSWITCH Troubleshooting
**Authors**  Walter Fan
**Status**   v1
**Updated**  |date|
============ ====================================



.. contents::
   :local:

概述
=========================

FreeSWITCH 作为一个复杂的通信平台，故障排查需要系统化的方法。本章介绍常用的调试工具、日志分析方法和常见问题的解决方案。

排查的基本思路：

1. **确认现象**：明确问题的具体表现（无法注册、单向音频、通话质量差等）
2. **查看日志**：通过 fs_cli 或日志文件获取错误信息
3. **抓包分析**：使用 SIP trace 或 tcpdump 分析信令和媒体流
4. **定位原因**：根据日志和抓包结果定位问题根因
5. **验证修复**：修改配置后验证问题是否解决


fs_cli 调试命令
=========================

``fs_cli`` 是 FreeSWITCH 的命令行客户端，是最常用的调试工具。

连接与基本操作
--------------------------

.. code-block:: bash

   # 连接到本地 FreeSWITCH
   fs_cli

   # 连接到远程 FreeSWITCH
   fs_cli -H 192.168.1.100 -P 8021 -p ClueCon

   # 执行单条命令
   fs_cli -x "sofia status"

常用调试命令
--------------------------

.. list-table:: fs_cli 常用命令
   :header-rows: 1
   :widths: 35 65

   * - 命令
     - 说明
   * - ``sofia status``
     - 查看所有 SIP profile 状态
   * - ``sofia status profile internal``
     - 查看 internal profile 详细状态
   * - ``sofia status profile internal reg``
     - 查看 internal profile 的注册用户
   * - ``show channels``
     - 显示当前活跃通道
   * - ``show calls``
     - 显示当前通话
   * - ``show registrations``
     - 显示所有注册信息
   * - ``show codec``
     - 显示已加载的编解码器
   * - ``status``
     - 显示系统状态（运行时间、会话数等）
   * - ``sofia global siptrace on``
     - 开启全局 SIP 消息跟踪
   * - ``sofia global siptrace off``
     - 关闭全局 SIP 消息跟踪
   * - ``sofia loglevel all 9``
     - 设置 sofia 日志级别为最详细
   * - ``uuid_debug_media <uuid> both on``
     - 开启指定通道的媒体调试
   * - ``reloadxml``
     - 重新加载 XML 配置
   * - ``reload mod_sofia``
     - 重新加载 sofia 模块
   * - ``console loglevel debug``
     - 设置控制台日志级别为 debug


日志配置
=========================

日志级别
--------------------------

FreeSWITCH 支持以下日志级别（从高到低）：

.. list-table:: 日志级别
   :header-rows: 1
   :widths: 15 15 70

   * - 级别
     - 数值
     - 说明
   * - CONSOLE
     - 0
     - 控制台输出
   * - ALERT
     - 1
     - 需要立即处理的告警
   * - CRIT
     - 2
     - 严重错误
   * - ERR
     - 3
     - 一般错误
   * - WARNING
     - 4
     - 警告信息
   * - NOTICE
     - 5
     - 重要通知
   * - INFO
     - 6
     - 一般信息
   * - DEBUG
     - 7
     - 调试信息

配置文件
--------------------------

日志配置在 ``autoload_configs/switch.conf.xml`` 中：

.. code-block:: xml

   <settings>
     <!-- 日志文件路径 -->
     <param name="log-file" value="freeswitch.log"/>
     <!-- 最大日志文件大小 -->
     <param name="max-log-file-size" value="104857600"/>
     <!-- 日志级别 -->
     <param name="loglevel" value="debug"/>
     <!-- 彩色日志 -->
     <param name="colorize-console" value="true"/>
   </settings>

日志轮转配置在 ``autoload_configs/logfile.conf.xml`` 中：

.. code-block:: xml

   <configuration name="logfile.conf">
     <settings>
       <param name="rotate-on-hup" value="true"/>
     </settings>
     <profiles>
       <profile name="default">
         <settings>
           <param name="logfile" value="freeswitch.log"/>
           <param name="rollover" value="10485760"/>  <!-- 10MB -->
           <param name="maximum-rotate" value="32"/>
         </settings>
         <mappings>
           <map name="all" value="debug,info,notice,warning,err,crit,alert"/>
         </mappings>
       </profile>
     </profiles>
   </configuration>


SIP 抓包分析
=========================

使用 sofia siptrace
--------------------------

.. code-block:: bash

   # 开启全局 SIP trace
   sofia global siptrace on

   # 只对特定 profile 开启
   sofia profile internal siptrace on

   # 关闭
   sofia global siptrace off

开启后，所有 SIP 消息会输出到 fs_cli 控制台和日志文件。

使用 tcpdump/tshark
--------------------------

.. code-block:: bash

   # 抓取 SIP 信令（端口 5060）
   tcpdump -i eth0 -n -s 0 port 5060 -w sip_capture.pcap

   # 抓取 SIP + RTP
   tcpdump -i eth0 -n -s 0 '(port 5060 or portrange 16384-32768)' -w full_capture.pcap

   # 使用 tshark 实时分析 SIP
   tshark -i eth0 -f "port 5060" -Y "sip" -T fields -e sip.Method -e sip.Status-Code

使用 sngrep
--------------------------

``sngrep`` 是一个基于终端的 SIP 消息流可视化工具：

.. code-block:: bash

   # 实时抓取
   sngrep -d eth0

   # 分析 pcap 文件
   sngrep -I sip_capture.pcap

sngrep 可以直观地显示 SIP 对话的消息流（INVITE → 100 → 180 → 200 → ACK），非常适合快速定位信令问题。


RTP 调试
=========================

.. code-block:: bash

   # 开启指定通道的媒体调试
   uuid_debug_media <channel-uuid> both on

   # 查看 RTP 统计
   uuid_debug_media <channel-uuid> read on
   uuid_debug_media <channel-uuid> write on

使用 Wireshark 分析 RTP：

1. 打开 pcap 文件
2. 菜单 Telephony → RTP → RTP Streams
3. 查看丢包率、抖动、序列号间隙
4. 可以播放 RTP 流听音频质量


常见问题排查
=========================

注册失败
--------------------------

**现象**：SIP 客户端无法注册到 FreeSWITCH

**排查步骤**：

.. code-block:: bash

   # 1. 检查 sofia profile 是否运行
   sofia status

   # 2. 查看注册尝试的日志
   sofia global siptrace on

   # 3. 检查用户目录配置
   xml_locate directory

**常见原因**：

- 用户名/密码错误：检查 ``directory/default/`` 下的用户配置
- 网络不通：检查防火墙是否放行 SIP 端口（5060/5061）
- DNS 解析失败：检查 SIP profile 中的 ``sip-ip`` 配置
- TLS 证书问题：检查证书路径和有效期

单向音频
--------------------------

**现象**：通话建立后只有一方能听到声音

**排查步骤**：

.. code-block:: bash

   # 1. 检查 SDP 中的媒体地址
   sofia global siptrace on
   # 查看 INVITE/200 OK 中的 c= 和 m= 行

   # 2. 检查 RTP 流
   uuid_debug_media <uuid> both on

   # 3. 检查 NAT 配置
   sofia status profile internal

**常见原因**：

- **NAT 问题**：最常见的原因。检查 ``ext-rtp-ip`` 和 ``ext-sip-ip`` 配置
- **防火墙**：RTP 端口范围（默认 16384-32768）未放行
- **编解码器不匹配**：双方没有共同支持的编解码器
- **对称 RTP**：某些 NAT 设备需要启用 ``NDLB-force-rport``

编解码器不匹配
--------------------------

**现象**：通话无法建立，日志显示 codec negotiation failure

.. code-block:: bash

   # 检查已加载的编解码器
   show codec

   # 检查 profile 的编解码器配置
   sofia status profile internal

**解决方案**：

- 确保双方至少有一个共同的编解码器
- 在 dialplan 中设置编解码器偏好：``<action application="set" data="absolute_codec_string=PCMU,PCMA,opus"/>``
- 如需转码，确保 FreeSWITCH 已加载对应的编解码器模块

通话质量差
--------------------------

**现象**：通话中有杂音、断续、回声

**排查步骤**：

1. 检查网络质量（丢包、抖动、延迟）
2. 检查编解码器选择（低带宽下使用 Opus 或 G.729）
3. 检查 Jitter Buffer 配置
4. 检查是否启用了回声消除

.. code-block:: xml

   <!-- 调整 Jitter Buffer -->
   <action application="set" data="jitterbuffer_msec=60:200:20"/>

   <!-- 启用回声消除 -->
   <action application="set" data="echo_cancel=true"/>


NAT 相关问题
=========================

NAT 是 VoIP 中最常见的问题来源。FreeSWITCH 提供了多种 NAT 穿越机制：

SIP Profile NAT 配置
--------------------------

.. code-block:: xml

   <profile name="internal">
     <settings>
       <!-- 外部 SIP 地址（公网 IP 或 STUN） -->
       <param name="ext-sip-ip" value="autonat:stun.freeswitch.org"/>
       <!-- 外部 RTP 地址 -->
       <param name="ext-rtp-ip" value="autonat:stun.freeswitch.org"/>
       <!-- 强制 rport -->
       <param name="NDLB-force-rport" value="true"/>
       <!-- 修复 NAT 后的 SDP -->
       <param name="apply-nat-acl" value="rfc1918.auto"/>
     </settings>
   </profile>

常见 NAT 场景
--------------------------

- **FreeSWITCH 在 NAT 后面**：配置 ``ext-sip-ip`` 和 ``ext-rtp-ip`` 为公网 IP
- **客户端在 NAT 后面**：启用 ``NDLB-force-rport`` 和 ``apply-nat-acl``
- **双重 NAT**：两端都在 NAT 后面，可能需要 TURN 服务器
- **对称 NAT**：最难处理，通常需要 TURN


TLS/证书问题
=========================

.. code-block:: bash

   # 生成自签名证书
   openssl req -x509 -nodes -days 365 \
     -newkey rsa:2048 \
     -keyout /etc/freeswitch/tls/wss.key \
     -out /etc/freeswitch/tls/wss.crt

   # 合并为 PEM（FreeSWITCH 需要）
   cat /etc/freeswitch/tls/wss.crt /etc/freeswitch/tls/wss.key > \
     /etc/freeswitch/tls/wss.pem

   # 使用 Let's Encrypt
   certbot certonly --standalone -d sip.example.com
   cat /etc/letsencrypt/live/sip.example.com/fullchain.pem \
       /etc/letsencrypt/live/sip.example.com/privkey.pem > \
     /etc/freeswitch/tls/wss.pem

常见证书问题：

- 证书过期：检查 ``openssl x509 -in wss.pem -noout -dates``
- 证书链不完整：确保包含中间证书
- 权限问题：FreeSWITCH 进程需要读取证书文件的权限
- WSS 端口未监听：检查 ``sofia status`` 中 WSS 端口是否 RUNNING


性能监控
=========================

.. code-block:: bash

   # 系统状态概览
   status

   # 当前通道数
   show channels count

   # 内存使用
   memory

   # CPU 使用（需要 mod_commands）
   show timer

关键性能指标
--------------------------

.. list-table:: 性能监控指标
   :header-rows: 1
   :widths: 30 70

   * - 指标
     - 说明
   * - 并发通道数
     - ``show channels count``，关注是否接近系统上限
   * - 每秒呼叫数（CPS）
     - 通过日志统计 INVITE 频率
   * - 内存使用
     - ``memory`` 命令，关注是否持续增长（内存泄漏）
   * - CPU 使用率
     - 系统级监控，转码会显著增加 CPU 负载
   * - 注册用户数
     - ``show registrations count``
   * - 失败呼叫比例
     - 通过 CDR 统计 4xx/5xx 响应比例


诊断命令速查表
=========================

.. list-table:: 诊断命令速查
   :header-rows: 1
   :widths: 40 60

   * - 命令
     - 用途
   * - ``sofia status``
     - SIP profile 状态总览
   * - ``sofia status profile <name>``
     - 特定 profile 详情
   * - ``sofia status profile <name> reg``
     - 注册用户列表
   * - ``sofia global siptrace on/off``
     - SIP 消息跟踪
   * - ``sofia loglevel all 9``
     - 最详细的 sofia 日志
   * - ``show channels``
     - 活跃通道列表
   * - ``show calls``
     - 当前通话列表
   * - ``show registrations``
     - 注册信息
   * - ``show codec``
     - 已加载编解码器
   * - ``uuid_debug_media <uuid> both on``
     - 媒体流调试
   * - ``uuid_kill <uuid>``
     - 强制挂断通道
   * - ``uuid_dump <uuid>``
     - 导出通道变量
   * - ``uuid_getvar <uuid> <var>``
     - 获取通道变量
   * - ``reloadxml``
     - 重载 XML 配置
   * - ``reload mod_<name>``
     - 重载指定模块
   * - ``status``
     - 系统状态
   * - ``memory``
     - 内存使用
   * - ``xml_locate directory``
     - 查找用户目录配置
   * - ``eval $${local_ip_v4}``
     - 查看系统变量


参考资料
=========================

- `FreeSWITCH 官方文档 <https://freeswitch.org/confluence/>`_
- `FreeSWITCH Debugging <https://freeswitch.org/confluence/display/FREESWITCH/Debugging>`_
- `Sofia SIP Stack <https://freeswitch.org/confluence/display/FREESWITCH/Sofia+SIP+Stack>`_
- `NAT Traversal <https://freeswitch.org/confluence/display/FREESWITCH/NAT+Traversal>`_
- `FreeSWITCH Explained <https://www.packtpub.com/product/freeswitch-1-8/9781785889134>`_ — Packt Publishing
- `sngrep <https://github.com/irontec/sngrep>`_ — SIP Messages Flow Viewer
