##################################
FreeSWITCH 集群与高可用
##################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** FreeSWITCH Cluster & HA
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:


概述
========================

在生产环境中，单节点的 FreeSWITCH 往往无法满足高可用性（High Availability）和大规模并发的需求。
当业务规模增长时，需要考虑以下问题：

* **单点故障（Single Point of Failure）**：单节点宕机将导致所有通话中断
* **容量限制（Capacity Limitation）**：单节点的并发通话数受限于 CPU、内存和网络带宽
* **地理分布（Geographic Distribution）**：用户分布在不同地区，需要就近接入
* **维护窗口（Maintenance Window）**：升级和维护时需要不中断服务

本章介绍 FreeSWITCH 集群部署的各种方案，包括负载均衡、故障转移、数据库共享等技术。


单节点的局限性
========================

一个典型的 FreeSWITCH 单节点在现代硬件上的性能参考：

.. list-table:: 单节点性能参考
   :header-rows: 1
   :widths: 30 35 35

   * - 场景
     - 并发通话数
     - 瓶颈
   * - 纯 SIP 代理（无媒体）
     - 5000-10000
     - CPU / 内存
   * - 音频转码（G.711 ↔ Opus）
     - 500-1000
     - CPU
   * - 音频会议（8kHz 混音）
     - 200-500 参与者
     - CPU
   * - 视频转码
     - 50-100
     - CPU（非常密集）
   * - 视频会议（MCU 合成）
     - 20-50 参与者
     - CPU / 内存

当业务需求超过单节点容量时，就需要考虑集群方案。


集群架构方案
========================

FreeSWITCH 集群有多种架构方案，根据业务需求选择合适的方案：

方案一：SIP Proxy + FreeSWITCH 集群
--------------------------------------

这是最常见的集群方案。使用 Kamailio 或 OpenSIPS 作为 SIP Proxy，将请求分发到多个 FreeSWITCH 节点：

::

                        ┌──────────────┐
                        │   SIP Proxy  │
                        │  (Kamailio)  │
                        └──────┬───────┘
                   ┌───────────┼───────────┐
                   │           │           │
            ┌──────┴──────┐ ┌──┴───────┐ ┌─┴──────────┐
            │ FreeSWITCH  │ │FreeSWITCH│ │ FreeSWITCH │
            │   Node 1    │ │  Node 2  │ │   Node 3   │
            └─────────────┘ └──────────┘ └────────────┘
                   │           │           │
                   └───────────┼───────────┘
                        ┌──────┴───────┐
                        │  Shared DB   │
                        │ (PostgreSQL) │
                        └──────────────┘


方案二：DNS SRV 负载均衡
--------------------------

通过 DNS SRV 记录实现简单的负载均衡：

.. code-block:: bash

   # DNS SRV 记录配置
   _sip._udp.sip.example.com. 86400 IN SRV 10 50 5060 fs1.example.com.
   _sip._udp.sip.example.com. 86400 IN SRV 10 50 5060 fs2.example.com.
   _sip._udp.sip.example.com. 86400 IN SRV 20 0  5060 fs3.example.com.

方案三：主备模式（Active-Standby）
-------------------------------------

使用 Keepalived 或 Pacemaker 实现主备切换，通过虚拟 IP（VIP）实现故障转移：

.. code-block:: bash

   # Keepalived 配置示例
   vrrp_script check_freeswitch {
       script "/usr/local/bin/check_fs.sh"
       interval 2
       weight -20
   }

   vrrp_instance VI_1 {
       state MASTER
       interface eth0
       virtual_router_id 51
       priority 100
       advert_int 1

       authentication {
           auth_type PASS
           auth_pass secret123
       }

       virtual_ipaddress {
           192.168.1.100/24
       }

       track_script {
           check_freeswitch
       }
   }

健康检查脚本：

.. code-block:: bash

   #!/bin/bash
   # /usr/local/bin/check_fs.sh
   fs_cli -x "status" > /dev/null 2>&1
   exit $?


mod_sofia 多 Profile 配置
=========================

在集群环境中，``mod_sofia`` 的多 Profile 配置非常重要。
每个 Profile 可以绑定不同的 IP 和端口，用于不同的用途：

.. code-block:: xml

   <!-- 内部 Profile：用于注册用户 -->
   <profile name="internal">
     <settings>
       <param name="sip-ip" value="$${local_ip_v4}"/>
       <param name="sip-port" value="5060"/>
       <param name="rtp-ip" value="$${local_ip_v4}"/>
       <param name="ext-rtp-ip" value="$${external_rtp_ip}"/>
       <param name="ext-sip-ip" value="$${external_sip_ip}"/>
       <param name="context" value="public"/>
       <param name="inbound-codec-prefs" value="OPUS,PCMU,PCMA"/>
       <param name="outbound-codec-prefs" value="OPUS,PCMU,PCMA"/>
       <!-- WebSocket 支持 -->
       <param name="ws-binding" value=":5066"/>
       <param name="wss-binding" value=":7443"/>
       <param name="tls-cert-dir" value="/etc/freeswitch/tls/"/>
     </settings>
   </profile>

   <!-- 外部 Profile：用于与其他 FreeSWITCH 节点或 SIP Proxy 通信 -->
   <profile name="external">
     <settings>
       <param name="sip-ip" value="$${local_ip_v4}"/>
       <param name="sip-port" value="5080"/>
       <param name="rtp-ip" value="$${local_ip_v4}"/>
       <param name="ext-rtp-ip" value="$${external_rtp_ip}"/>
       <param name="ext-sip-ip" value="$${external_sip_ip}"/>
       <param name="context" value="public"/>
     </settings>

     <!-- 与其他节点的 Gateway -->
     <gateways>
       <gateway name="fs-node2">
         <param name="realm" value="192.168.1.12"/>
         <param name="register" value="false"/>
         <param name="caller-id-in-from" value="true"/>
       </gateway>
       <gateway name="fs-node3">
         <param name="realm" value="192.168.1.13"/>
         <param name="register" value="false"/>
         <param name="caller-id-in-from" value="true"/>
       </gateway>
     </gateways>
   </profile>


数据库复制
========================

在集群环境中，多个 FreeSWITCH 节点需要共享注册信息、CDR 等数据。
FreeSWITCH 支持使用 PostgreSQL 或 MySQL 作为后端数据库。

PostgreSQL 配置
-----------------

首先，配置 FreeSWITCH 使用 PostgreSQL 存储核心数据：

.. code-block:: xml

   <!-- conf/autoload_configs/switch.conf.xml -->
   <param name="core-db-dsn"
          value="pgsql://host=db.example.com dbname=freeswitch user=fsuser password=secret"/>

Sofia Profile 使用 ODBC：

.. code-block:: xml

   <profile name="internal">
     <settings>
       <param name="odbc-dsn"
              value="pgsql://host=db.example.com dbname=freeswitch user=fsuser password=secret"/>
     </settings>
   </profile>

PostgreSQL 流复制配置
-----------------------

为了实现数据库高可用，可以配置 PostgreSQL 流复制（Streaming Replication）：

.. code-block:: bash

   # 主库 postgresql.conf
   wal_level = replica
   max_wal_senders = 5
   wal_keep_segments = 64
   synchronous_commit = on

   # 主库 pg_hba.conf
   host replication replicator 192.168.1.0/24 md5

   # 从库 recovery.conf
   standby_mode = 'on'
   primary_conninfo = 'host=192.168.1.10 port=5432 user=replicator password=secret'
   trigger_file = '/tmp/postgresql.trigger'


共享注册
========================

在集群环境中，用户可能注册到任意一个 FreeSWITCH 节点。
当呼叫到达时，需要找到用户注册的节点并路由呼叫。

使用 ODBC 共享注册
---------------------

所有节点使用同一个数据库存储注册信息：

.. code-block:: xml

   <!-- 所有节点的 sofia profile 使用相同的 ODBC DSN -->
   <profile name="internal">
     <settings>
       <param name="odbc-dsn"
              value="pgsql://host=db.example.com dbname=freeswitch user=fsuser password=secret"/>
       <param name="manage-shared-appearance" value="true"/>
     </settings>
   </profile>

使用 mod_db 查找注册
-----------------------

.. code-block:: xml

   <!-- Dialplan 中查找用户注册位置 -->
   <extension name="find-user">
     <condition field="destination_number" expression="^(1\d{3})$">
       <!-- 先尝试本地 -->
       <action application="bridge"
               data="user/$1@${domain_name}"/>
       <!-- 本地未注册，查询数据库找到注册节点 -->
       <action application="bridge"
               data="sofia/external/$1@${registered_node}"/>
     </condition>
   </extension>


使用 Kamailio 负载均衡
========================

Kamailio 是一个高性能的 SIP Proxy 服务器，常用于 FreeSWITCH 集群的前端负载均衡。

Kamailio 基本配置
--------------------

.. code-block:: c

   /* kamailio.cfg - FreeSWITCH 负载均衡配置 */

   #!define WITH_MYSQL
   #!define WITH_AUTH
   #!define WITH_DISPATCHER

   loadmodule "dispatcher.so"

   /* Dispatcher 模块配置 */
   modparam("dispatcher", "db_url",
            "mysql://kamailio:secret@localhost/kamailio")
   modparam("dispatcher", "ds_ping_interval", 10)
   modparam("dispatcher", "ds_ping_method", "OPTIONS")
   modparam("dispatcher", "ds_probing_mode", 1)

   /* 路由逻辑 */
   route {
       /* 处理 REGISTER 请求 */
       if (is_method("REGISTER")) {
           if (!ds_select_dst("1", "4")) {
               send_reply("503", "Service Unavailable");
               exit;
           }
           t_relay();
           exit;
       }

       /* 处理 INVITE 请求 */
       if (is_method("INVITE")) {
           if (!ds_select_dst("1", "4")) {
               send_reply("503", "Service Unavailable");
               exit;
           }
           t_on_failure("MANAGE_FAILURE");
           t_relay();
           exit;
       }
   }

   /* 故障转移路由 */
   failure_route[MANAGE_FAILURE] {
       if (t_is_canceled()) exit;

       if (ds_next_dst()) {
           t_relay();
           exit;
       }
   }

Dispatcher 数据库配置
-----------------------

.. code-block:: sql

   -- Kamailio dispatcher 表
   INSERT INTO dispatcher (setid, destination, flags, priority, attrs, description)
   VALUES
     (1, 'sip:192.168.1.11:5060', 0, 0, 'weight=50', 'FreeSWITCH Node 1'),
     (1, 'sip:192.168.1.12:5060', 0, 0, 'weight=50', 'FreeSWITCH Node 2'),
     (1, 'sip:192.168.1.13:5060', 0, 0, 'weight=30', 'FreeSWITCH Node 3');

Kamailio 支持的负载均衡算法：

.. list-table:: Dispatcher 负载均衡算法
   :header-rows: 1
   :widths: 15 30 55

   * - 算法 ID
     - 名称
     - 说明
   * - 0
     - Hash over callid
     - 基于 Call-ID 的哈希，同一通话的请求发往同一节点
   * - 4
     - Round-Robin
     - 轮询分发
   * - 8
     - Priority
     - 按优先级分发
   * - 9
     - Weight
     - 按权重分发
   * - 10
     - Call Load
     - 基于呼叫负载分发
   * - 12
     - Random
     - 随机分发


故障转移策略
========================

SIP 层面的故障转移
---------------------

通过 Kamailio 的 ``failure_route`` 实现 SIP 层面的故障转移。
当一个 FreeSWITCH 节点无响应时，自动将请求转发到其他节点。

媒体层面的故障转移
---------------------

媒体流的故障转移比较复杂，因为 RTP 流是有状态的。常见的策略包括：

1. **呼叫重建（Call Re-establishment）**：检测到节点故障后，通过 SIP RE-INVITE 将媒体流切换到新节点
2. **媒体代理（Media Proxy）**：使用独立的 RTP Proxy（如 RTPEngine）处理媒体流，与信令节点解耦

.. code-block:: bash

   # RTPEngine 配置
   rtpengine --interface=192.168.1.20 \
             --listen-ng=127.0.0.1:2223 \
             --port-min=30000 \
             --port-max=40000 \
             --log-level=6


Docker/Kubernetes 部署
========================

Docker 部署
--------------

FreeSWITCH 的 Docker 镜像可以简化部署和管理：

.. code-block:: dockerfile

   # Dockerfile
   FROM debian:bullseye-slim

   RUN apt-get update && apt-get install -y \
       gnupg2 wget lsb-release

   # 添加 SignalWire 仓库
   RUN wget -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg \
       https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg

   RUN echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] \
       https://freeswitch.signalwire.com/repo/deb/debian-release/ \
       $(lsb_release -sc) main" > /etc/apt/sources.list.d/freeswitch.list

   RUN apt-get update && apt-get install -y freeswitch-meta-all

   EXPOSE 5060/udp 5060/tcp 5080/udp 5080/tcp
   EXPOSE 5066/tcp 7443/tcp 8021/tcp 8082/tcp
   EXPOSE 16384-32768/udp

   CMD ["freeswitch", "-nonat", "-nc"]

Docker Compose 配置：

.. code-block:: yaml

   # docker-compose.yml
   version: '3.8'

   services:
     freeswitch:
       build: .
       network_mode: host
       volumes:
         - ./conf:/etc/freeswitch
         - ./recordings:/var/recordings
         - ./logs:/var/log/freeswitch
       environment:
         - FREESWITCH_DOMAIN=sip.example.com
         - FREESWITCH_EXTERNAL_IP=203.0.113.10
       restart: unless-stopped

     postgres:
       image: postgres:14
       environment:
         POSTGRES_DB: freeswitch
         POSTGRES_USER: fsuser
         POSTGRES_PASSWORD: secret
       volumes:
         - pgdata:/var/lib/postgresql/data
       ports:
         - "5432:5432"

   volumes:
     pgdata:

Kubernetes 部署
-----------------

在 Kubernetes 中部署 FreeSWITCH 需要注意 RTP 端口范围的处理：

.. code-block:: yaml

   # freeswitch-deployment.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: freeswitch
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: freeswitch
     template:
       metadata:
         labels:
           app: freeswitch
       spec:
         hostNetwork: true
         containers:
         - name: freeswitch
           image: freeswitch:latest
           ports:
           - containerPort: 5060
             protocol: UDP
           - containerPort: 5060
             protocol: TCP
           - containerPort: 8021
             protocol: TCP
           resources:
             requests:
               cpu: "2"
               memory: "4Gi"
             limits:
               cpu: "4"
               memory: "8Gi"
           livenessProbe:
             exec:
               command:
               - fs_cli
               - -x
               - status
             initialDelaySeconds: 30
             periodSeconds: 10
           readinessProbe:
             exec:
               command:
               - fs_cli
               - -x
               - "sofia status"
             initialDelaySeconds: 15
             periodSeconds: 5

.. note::

   在 Kubernetes 中部署 FreeSWITCH 时，由于 RTP 需要大量 UDP 端口，
   通常需要使用 ``hostNetwork: true`` 模式。这限制了每个节点只能运行一个 FreeSWITCH Pod。


监控与健康检查
========================

FreeSWITCH 提供了多种监控手段：

fs_cli 监控命令
-----------------

.. code-block:: bash

   # 查看系统状态
   freeswitch@default> status

   # 查看活跃通道
   freeswitch@default> show channels count

   # 查看活跃通话
   freeswitch@default> show calls count

   # 查看 Sofia 状态
   freeswitch@default> sofia status

Prometheus 监控集成
---------------------

通过 ESL 采集 FreeSWITCH 指标并暴露给 Prometheus：

.. code-block:: python

   # freeswitch_exporter.py
   from prometheus_client import start_http_server, Gauge
   import ESL
   import time

   active_channels = Gauge('freeswitch_active_channels',
                           'Number of active channels')
   active_calls = Gauge('freeswitch_active_calls',
                        'Number of active calls')

   def collect_metrics():
       con = ESL.ESLconnection("127.0.0.1", "8021", "ClueCon")
       if con.connected():
           result = con.api("show", "channels count")
           active_channels.set(parse_count(result.getBody()))
           result = con.api("show", "calls count")
           active_calls.set(parse_count(result.getBody()))

   if __name__ == '__main__':
       start_http_server(9724)
       while True:
           collect_metrics()
           time.sleep(15)


性能调优
========================

操作系统层面
--------------

.. code-block:: bash

   # /etc/security/limits.conf
   freeswitch soft nofile 65536
   freeswitch hard nofile 65536
   freeswitch soft core unlimited
   freeswitch hard core unlimited

   # /etc/sysctl.conf
   net.core.rmem_max = 16777216
   net.core.wmem_max = 16777216
   net.core.rmem_default = 65536
   net.core.wmem_default = 65536
   net.ipv4.ip_local_port_range = 1024 65535

FreeSWITCH 层面
------------------

.. code-block:: xml

   <!-- switch.conf.xml -->
   <settings>
     <param name="max-sessions" value="10000"/>
     <param name="sessions-per-second" value="100"/>
     <param name="rtp-start-port" value="16384"/>
     <param name="rtp-end-port" value="32768"/>
     <param name="loglevel" value="WARNING"/>
   </settings>


参考资料
========================

* FreeSWITCH Enterprise Deployment: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Enterprise-Deployment/
* Kamailio 文档: https://www.kamailio.org/wikidocs/
* Kamailio Dispatcher 模块: https://kamailio.org/docs/modules/stable/modules/dispatcher.html
* PostgreSQL Streaming Replication: https://www.postgresql.org/docs/current/warm-standby.html
* FreeSWITCH Docker: https://hub.docker.com/r/signalwire/freeswitch
