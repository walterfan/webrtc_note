######################
coturn
######################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** coturn
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ =============================



.. contents::
   :local:


概述
========================

coturn 是一个开源的 TURN（Traversal Using Relays around NAT）和 STUN（Session Traversal Utilities for NAT）服务器实现。在 WebRTC 通信中，当两个端点无法通过直接的 P2P 连接进行通信时（例如双方都在对称型 NAT 后面，或者有防火墙阻止 UDP 流量），TURN 服务器作为中继（Relay）转发媒体流，确保通信的连通性。

coturn 项目最初由 Oleg Oleg Moskalenko 开发，是目前最成熟、使用最广泛的开源 TURN/STUN 服务器实现。
它完整实现了 RFC 5389（STUN）、RFC 5766（TURN）以及更新的 RFC 8656（TURN Relay Extensions to STUN）等标准。

为什么 WebRTC 需要 TURN
--------------------------

WebRTC 的核心理念是 P2P（Peer-to-Peer）通信，即两个端点直接交换媒体数据，不经过中间服务器。
然而，在实际的互联网环境中，大多数设备都位于 NAT（Network Address Translation）或防火墙之后，
直接的 P2P 连接并不总是可行的。

ICE（Interactive Connectivity Establishment）框架定义了一套完整的 NAT 穿越策略：

1. **首先尝试直连（Host Candidate）**: 使用本地 IP 地址直接连接
2. **然后尝试 STUN（Server Reflexive Candidate）**: 通过 STUN 服务器获取公网映射地址
3. **最后使用 TURN（Relay Candidate）**: 当前两种方式都失败时，通过 TURN 服务器中继

在实际的网络环境中，大约 10-20% 的 WebRTC 连接需要通过 TURN 服务器中继。以下情况需要 TURN：

* **对称型 NAT（Symmetric NAT）**: 对称型 NAT 为每个目标地址分配不同的映射端口，STUN 无法穿透，必须使用 TURN 中继
* **严格的防火墙**: 企业防火墙可能阻止所有入站 UDP 流量
* **UDP 被阻止**: 某些网络环境（如酒店、机场 WiFi）完全阻止 UDP 流量，需要 TURN over TCP/TLS
* **双重 NAT**: 多层 NAT 嵌套的网络环境
* **VPN 环境**: 某些 VPN 配置会干扰 P2P 连接


NAT 穿越原理
========================

NAT 类型
--------------------------

NAT（Network Address Translation）是将私有 IP 地址映射为公网 IP 地址的技术。
根据映射规则和过滤规则的不同，NAT 可以分为以下四种类型：

**1. Full Cone NAT（完全锥形 NAT）**

一旦内部主机 ``(iAddr:iPort)`` 被映射为 ``(eAddr:ePort)``，
任何外部主机都可以通过 ``(eAddr:ePort)`` 向内部主机发送数据。

.. code-block:: text

   内部主机 (192.168.1.100:5000)
       │
       │ 映射为 (203.0.113.1:40000)
       ▼
   NAT ──── 任何外部主机都可以发送到 203.0.113.1:40000
       │
       ▼
   外部主机 A (任意 IP:Port) ✓ 可以访问
   外部主机 B (任意 IP:Port) ✓ 可以访问

**2. Address Restricted Cone NAT（地址限制锥形 NAT）**

只有内部主机之前向其发送过数据的外部 IP 地址，才能通过映射地址向内部主机发送数据。

.. code-block:: text

   内部主机 → 外部主机 A (1.2.3.4:80)
   映射为 (203.0.113.1:40000)

   外部主机 A (1.2.3.4:任意端口) ✓ 可以访问（IP 匹配）
   外部主机 B (5.6.7.8:任意端口) ✗ 不可以访问（IP 不匹配）

**3. Port Restricted Cone NAT（端口限制锥形 NAT）**

只有内部主机之前向其发送过数据的外部 IP:Port，才能通过映射地址向内部主机发送数据。

.. code-block:: text

   内部主机 → 外部主机 A (1.2.3.4:80)
   映射为 (203.0.113.1:40000)

   外部主机 A (1.2.3.4:80)    ✓ 可以访问（IP:Port 匹配）
   外部主机 A (1.2.3.4:8080)  ✗ 不可以访问（端口不匹配）
   外部主机 B (5.6.7.8:80)    ✗ 不可以访问（IP 不匹配）

**4. Symmetric NAT（对称型 NAT）**

对于每个不同的目标地址 ``(destAddr:destPort)``，NAT 都会分配一个不同的映射端口。
这是最严格的 NAT 类型，STUN 无法穿透。

.. code-block:: text

   内部主机 → 外部主机 A (1.2.3.4:80)   → 映射为 (203.0.113.1:40000)
   内部主机 → 外部主机 B (5.6.7.8:80)   → 映射为 (203.0.113.1:40001)  ← 不同的端口！

   STUN 服务器看到的映射端口与实际通信时的映射端口不同，
   因此 STUN 获取的地址无法用于 P2P 通信。

**NAT 类型与穿透能力**:

.. list-table::
   :header-rows: 1
   :widths: 25 20 20 35

   * - NAT 类型
     - STUN 穿透
     - P2P 可能性
     - 说明
   * - Full Cone NAT
     - ✓
     - 高
     - 任何外部主机都可以通过映射地址访问
   * - Address Restricted Cone
     - ✓
     - 中
     - 只有之前通信过的 IP 可以访问
   * - Port Restricted Cone
     - ✓
     - 中
     - 只有之前通信过的 IP:Port 可以访问
   * - Symmetric NAT
     - ✗
     - 低（需要 TURN）
     - 每个目标地址使用不同的映射端口

**两端 NAT 类型组合的穿透可能性**:

.. list-table::
   :header-rows: 1
   :widths: 25 20 20 20 20

   * - 
     - Full Cone
     - Addr Restricted
     - Port Restricted
     - Symmetric
   * - Full Cone
     - ✓
     - ✓
     - ✓
     - ✓
   * - Addr Restricted
     - ✓
     - ✓
     - ✓
     - ✓
   * - Port Restricted
     - ✓
     - ✓
     - ✓
     - ✗ (需要 TURN)
   * - Symmetric
     - ✓
     - ✓
     - ✗ (需要 TURN)
     - ✗ (需要 TURN)


STUN 协议
========================

STUN（Session Traversal Utilities for NAT，RFC 5389 / RFC 8489）是一个轻量级协议，
用于帮助 NAT 后面的端点发现自己的公网映射地址。

STUN 消息格式
--------------------------

STUN 消息由 20 字节的头部和可变长度的属性（Attributes）组成：

.. code-block:: text

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |0 0|     STUN Message Type     |         Message Length        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                         Magic Cookie                         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                                                               |
   |                     Transaction ID (96 bits)                  |
   |                                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

* **Message Type（消息类型）**: 14 位，包含方法（Method）和类别（Class）
* **Message Length（消息长度）**: 不包含 20 字节头部的消息体长度
* **Magic Cookie**: 固定值 ``0x2112A442``，用于区分 STUN 和其他协议
* **Transaction ID**: 96 位随机值，用于匹配请求和响应

Binding Request/Response
--------------------------

STUN 最基本的操作是 Binding（绑定），客户端发送 Binding Request，
服务器返回 Binding Response，其中包含客户端的公网映射地址。

.. code-block:: text

   Client (192.168.1.100:5000)          NAT              STUN Server
     |                                   |                    |
     |--- Binding Request ------------->|--- (映射为         |
     |    (src: 192.168.1.100:5000)     |  203.0.113.1:40000)|
     |                                   |--- Binding Req --->|
     |                                   |    (src: 203.0.113.1:40000)
     |                                   |                    |
     |                                   |<-- Binding Resp ---|
     |<-- Binding Response -------------|    XOR-MAPPED-ADDRESS:
     |    XOR-MAPPED-ADDRESS:           |    203.0.113.1:40000
     |    203.0.113.1:40000             |
     |                                   |
     |  现在客户端知道自己的公网地址是 203.0.113.1:40000

XOR-MAPPED-ADDRESS 属性
--------------------------

XOR-MAPPED-ADDRESS 是 STUN Binding Response 中最重要的属性，
包含客户端的公网映射地址。地址经过 XOR 编码以避免某些 NAT 设备修改消息中的 IP 地址。

.. code-block:: text

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |x x x x x x x x|    Family     |         X-Port              |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                X-Address (32 bits for IPv4)                   |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

* **X-Port** = Port XOR (Magic Cookie >> 16)
* **X-Address** = Address XOR Magic Cookie（IPv4）

STUN 检测 NAT 类型
--------------------------

通过向 STUN 服务器的不同 IP 和端口发送多次 Binding Request，
可以判断 NAT 的类型（RFC 3489 定义的经典检测算法）：

.. code-block:: text

   测试 1: 向 STUN 服务器的主地址发送请求
           → 获取映射地址 (eAddr:ePort)
           → 如果 eAddr:ePort == 本地地址，则没有 NAT

   测试 2: 请求 STUN 服务器从不同的 IP 和端口回复
           → 如果收到回复，则是 Full Cone NAT

   测试 3: 请求 STUN 服务器从不同的端口（相同 IP）回复
           → 如果收到回复，则是 Address Restricted Cone NAT
           → 如果没收到，则是 Port Restricted Cone NAT

   测试 4: 向 STUN 服务器的备用地址发送请求
           → 获取映射地址 (eAddr2:ePort2)
           → 如果 ePort2 != ePort，则是 Symmetric NAT

**ICE 连接建立流程**:

.. code-block:: text

   1. 收集候选地址 (Candidate Gathering):
      - Host candidate: 本地 IP 地址
      - Server Reflexive candidate: 通过 STUN 获取的公网映射地址
      - Relay candidate: 通过 TURN 分配的中继地址

   2. 连通性检查 (Connectivity Check):
      - 优先尝试 Host candidate (最低延迟)
      - 然后尝试 Server Reflexive candidate
      - 最后使用 Relay candidate (最高延迟，但保证连通)

   3. 选择最优路径


TURN 协议
========================

TURN（Traversal Using Relays around NAT，RFC 5766 / RFC 8656）是 STUN 的扩展，
当 STUN 无法穿透 NAT 时，TURN 提供中继（Relay）服务来转发媒体数据。

TURN 工作原理
--------------------------

TURN 服务器为客户端分配一个中继地址（Relay Address），
所有发往该中继地址的数据都会被转发给客户端，反之亦然。

.. code-block:: text

                        ┌──────────────────┐
                        │                  │
                        │   TURN Server    │
                        │                  │
   Client A ◄──────────►  Relay Address   ◄──────────► Client B
   (NAT 后面)           │  203.0.113.1:   │            (NAT 后面)
                        │  49152           │
                        │                  │
                        └──────────────────┘

   Client A 的数据路径:
   A → A's NAT → TURN Server → B's NAT → B

   延迟 = A→TURN + TURN→B（比 P2P 多一跳）

Allocate（分配）
--------------------------

客户端首先向 TURN 服务器发送 Allocate 请求，服务器分配一个中继地址（Relay Address）。

.. code-block:: text

   Client                    TURN Server
     |                           |
     |--- Allocate Request ----->|  (无认证，服务器返回 401)
     |<-- 401 Unauthorized ------|  (包含 realm 和 nonce)
     |                           |
     |--- Allocate Request ----->|  (带认证信息)
     |<-- Allocate Success ------|  (返回 Relay Address 和 Mapped Address)
     |                           |
     |  Relay Address: 203.0.113.1:49152 (TURN 服务器分配的中继地址)
     |  Mapped Address: 198.51.100.1:12345 (客户端的公网映射地址)

**Allocate Request 的关键属性**:

* **REQUESTED-TRANSPORT**: 请求的传输协议（通常是 UDP，值为 17）
* **LIFETIME**: 请求的分配生命周期（秒）
* **DONT-FRAGMENT**: 请求不分片（可选）

**Allocate Response 的关键属性**:

* **XOR-RELAYED-ADDRESS**: 分配的中继地址
* **XOR-MAPPED-ADDRESS**: 客户端的公网映射地址
* **LIFETIME**: 实际的分配生命周期

Refresh（刷新）
--------------------------

分配有生命周期（默认 600 秒），客户端需要定期发送 Refresh 请求来保持分配。
发送 Lifetime=0 的 Refresh 请求可以主动释放分配。

.. code-block:: text

   Client                    TURN Server
     |                           |
     |--- Refresh Request ------>|  (Lifetime: 600)
     |<-- Refresh Success -------|  (Lifetime: 600)
     |                           |
     |  ... 每隔 ~300 秒刷新一次 ...
     |                           |
     |--- Refresh Request ------>|  (Lifetime: 0，释放分配)
     |<-- Refresh Success -------|

CreatePermission（创建权限）
-------------------------------

在通过中继地址发送或接收数据之前，客户端需要为对端创建权限。
权限基于对端的 IP 地址（不包含端口），有效期为 300 秒，需要定期刷新。

.. code-block:: text

   Client                    TURN Server                    Peer
     |                           |                           |
     |--- CreatePermission ----->|                           |
     |    (Peer: 192.0.2.1)     |                           |
     |<-- Success Response ------|                           |
     |                           |                           |
     |  现在可以通过中继地址与 192.0.2.1 通信                  |

Send/Data Indication
--------------------------

创建权限后，客户端可以通过 Send Indication 向对端发送数据，
TURN 服务器通过 Data Indication 将对端的数据转发给客户端。

.. code-block:: text

   Client                    TURN Server                    Peer
     |                           |                           |
     |--- Send Indication ------>|--- UDP Data ------------->|
     |    (Peer: 192.0.2.1:5000,|                           |
     |     Data: ...)            |                           |
     |                           |                           |
     |<-- Data Indication -------|<-- UDP Data --------------|
     |    (Peer: 192.0.2.1:5000,|                           |
     |     Data: ...)            |                           |

ChannelBind（通道绑定）
--------------------------

ChannelBind 为特定的对端地址创建一个通道号（Channel Number，0x4000-0x7FFF），
后续数据传输使用更紧凑的 ChannelData 消息格式，减少开销。

.. code-block:: text

   Client                    TURN Server                    Peer
     |                           |                           |
     |--- ChannelBind ---------->|                           |
     |    (Channel: 0x4001,      |                           |
     |     Peer: 192.0.2.1:5000)|                           |
     |<-- Success Response ------|                           |
     |                           |                           |
     |=== ChannelData =========>|=== UDP Data =============>|
     |    (4 bytes header)       |                           |
     |<== ChannelData ==========|<== UDP Data ==============|

**ChannelData 消息格式**:

.. code-block:: text

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |         Channel Number        |            Length             |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                                                               |
   /                       Application Data                        /
   /                                                               /
   |                                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

**Send/Data Indication vs ChannelData 对比**:

.. list-table::
   :header-rows: 1
   :widths: 30 35 35

   * - 特性
     - Send/Data Indication
     - ChannelData
   * - 头部开销
     - 36+ bytes（STUN 消息格式）
     - 4 bytes（Channel Number + Length）
   * - 需要 ChannelBind
     - 否（只需 CreatePermission）
     - 是
   * - 适用场景
     - 少量数据、初始阶段
     - 大量媒体数据传输
   * - 性能
     - 较低
     - 较高


coturn 功能特性
========================

coturn 是目前最成熟、使用最广泛的开源 TURN/STUN 服务器，主要特性包括：

* 完整的 TURN 和 STUN 协议实现
* 支持 UDP、TCP、TLS、DTLS 传输
* 支持 TURN over TCP 和 TURN over TLS（用于穿透严格防火墙）
* 支持 IPv4 和 IPv6
* 支持长期凭证（Long-Term Credentials）和 REST API 时限凭证
* 支持多种数据库后端：SQLite、PostgreSQL、MySQL/MariaDB、Redis、MongoDB
* 支持 TURN REST API（与 Opal 兼容的时限凭证）
* 支持带宽限制和配额管理
* 支持 ALPN（Application-Layer Protocol Negotiation）
* 支持 STUN/TURN 多路复用（同一端口同时处理 STUN 和 TURN）
* 内置管理 CLI 和 telnet 接口
* 支持日志记录和统计


Installation
========================

包管理器安装
--------------------------

**Ubuntu/Debian**:

.. code-block:: bash

   sudo apt-get update
   sudo apt-get install -y coturn

   # 启用 coturn 服务
   sudo sed -i 's/#TURNSERVER_ENABLED=1/TURNSERVER_ENABLED=1/' /etc/default/coturn

**CentOS/RHEL**:

.. code-block:: bash

   sudo yum install -y epel-release
   sudo yum install -y coturn

Docker 安装
--------------------------

使用 Docker 是最简单的部署方式：

.. code-block:: bash

   docker run -d \
     --name coturn \
     --network host \
     coturn/coturn \
     -n \
     --log-file=stdout \
     --listening-port=3478 \
     --tls-listening-port=5349 \
     --realm=example.com \
     --user=myuser:mypassword \
     --lt-cred-mech \
     --external-ip='$(detect-external-ip)' \
     --min-port=49152 \
     --max-port=65535

源码编译安装
--------------------------

* 参考 https://github.com/coturn/coturn/blob/master/INSTALL

.. code-block:: bash

   git clone https://github.com/coturn/coturn.git
   cd coturn

* 安装依赖

.. code-block:: bash

   # Ubuntu/Debian
   sudo apt-get install -y build-essential libssl-dev libevent-dev \
     libsqlite3-dev libpq-dev libmysqlclient-dev libhiredis-dev

   # CentOS/RHEL
   sudo yum install -y openssl-devel sqlite sqlite-devel \
     libevent libevent-devel
   # 可选数据库支持
   # yum install postgresql-devel
   # yum install mysql-devel
   # yum install hiredis hiredis-devel

* 配置和编译

.. code-block:: bash

   ./configure
   make
   sudo make install


配置详解
========================

coturn 的主要配置文件是 ``turnserver.conf``，通常位于 ``/etc/turnserver.conf`` 或 ``/usr/local/etc/turnserver.conf``。

.. code-block:: bash

   $ cp /usr/local/etc/turnserver.conf.default /usr/local/etc/turnserver.conf
   $ vi /usr/local/etc/turnserver.conf

监听端口配置
--------------------------

.. code-block:: bash

   # STUN/TURN 监听端口（默认 3478）
   listening-port=3478

   # TLS/DTLS 监听端口（默认 5349）
   tls-listening-port=5349

   # 备用监听端口（某些 NAT 需要）
   alt-listening-port=3479
   alt-tls-listening-port=5350

   # 监听的网卡
   listening-device=eth0

   # 监听的 IP 地址（可指定多个）
   listening-ip=0.0.0.0
   listening-ip=::

   # 使用 443 端口作为备用（穿透更多防火墙）
   # 注意：需要确保 443 端口未被其他服务占用
   # alt-listening-port=443

Realm 和认证配置
--------------------------

coturn 支持三种认证方式：

**1. 长期凭证机制（Long-Term Credential Mechanism）**

最简单的认证方式，用户名和密码存储在配置文件或数据库中：

.. code-block:: bash

   # Realm（域名，用于认证）
   realm=example.com

   # 使用长期凭证机制
   lt-cred-mech

   # 静态用户（用户名:密码）
   user=walter:pass1234
   user=alice:secret456

   # 或者使用 turnadmin 命令创建用户
   # turnadmin -a -u walter -p pass1234 -r example.com

**2. REST API 时限凭证（推荐用于生产环境）**

生成有时间限制的临时凭证，避免长期凭证泄露的风险：

.. code-block:: bash

   # 启用 REST API 时限凭证
   use-auth-secret

   # 共享密钥（用于生成时限凭证）
   static-auth-secret=my_super_secret_key_12345

   # 凭证有效期（秒，默认 86400 = 24 小时）
   # 通过 REST API 参数控制

**3. 短期凭证机制（Short-Term Credential Mechanism）**

主要用于 STUN Binding 请求的认证，较少使用：

.. code-block:: bash

   # 启用短期凭证
   # st-cred-mech

**时限凭证生成算法**:

.. code-block:: python

   import hashlib
   import hmac
   import base64
   import time

   def generate_turn_credentials(secret, username, ttl=86400):
       """生成 TURN 时限凭证

       算法:
       1. username = "{timestamp}:{original_username}"
          其中 timestamp = 当前时间 + TTL（凭证过期时间）
       2. password = Base64(HMAC-SHA1(secret, username))
       """
       timestamp = int(time.time()) + ttl
       turn_username = f"{timestamp}:{username}"
       turn_password = base64.b64encode(
           hmac.new(
               secret.encode(),
               turn_username.encode(),
               hashlib.sha1
           ).digest()
       ).decode()
       return turn_username, turn_password

   # 使用示例
   username, password = generate_turn_credentials("my_super_secret_key_12345", "user1")
   print(f"Username: {username}")
   print(f"Password: {password}")

**Node.js 版本的凭证生成**:

.. code-block:: javascript

   const crypto = require('crypto');

   function generateTurnCredentials(secret, username, ttl = 86400) {
     const timestamp = Math.floor(Date.now() / 1000) + ttl;
     const turnUsername = `${timestamp}:${username}`;
     const turnPassword = crypto
       .createHmac('sha1', secret)
       .update(turnUsername)
       .digest('base64');
     return { username: turnUsername, credential: turnPassword };
   }

   // Express API 示例
   app.get('/api/turn-credentials', (req, res) => {
     const credentials = generateTurnCredentials(
       'my_super_secret_key_12345',
       req.user.id
     );
     res.json({
       ...credentials,
       urls: [
         'stun:turn.example.com:3478',
         'turn:turn.example.com:3478?transport=udp',
         'turn:turn.example.com:3478?transport=tcp',
         'turns:turn.example.com:5349?transport=tcp'
       ]
     });
   });

**在 WebRTC 客户端中使用**:

.. code-block:: javascript

   // 从应用服务器获取时限凭证
   const response = await fetch('/api/turn-credentials');
   const { username, credential, urls } = await response.json();

   const pc = new RTCPeerConnection({
     iceServers: [
       { urls: 'stun:turn.example.com:3478' },
       {
         urls: [
           'turn:turn.example.com:3478?transport=udp',
           'turn:turn.example.com:3478?transport=tcp',
           'turns:turn.example.com:5349?transport=tcp'
         ],
         username: username,
         credential: credential
       }
     ]
   });

TLS 证书配置
--------------------------

TURN over TLS（TURNS）需要配置 TLS 证书，用于穿透阻止 UDP 的严格防火墙：

.. code-block:: bash

   # TLS 证书和私钥
   cert=/etc/letsencrypt/live/turn.example.com/fullchain.pem
   pkey=/etc/letsencrypt/live/turn.example.com/privkey.pem

   # CA 证书（可选）
   CA-file=/etc/letsencrypt/live/turn.example.com/chain.pem

   # 密码套件（可选，限制使用的加密算法）
   cipher-list="ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256"

   # DH 参数文件（可选，增强安全性）
   dh-file=/etc/ssl/dhparams.pem

   # 最低 TLS 版本
   no-tlsv1
   no-tlsv1_1

**使用 Let's Encrypt 获取免费证书**:

.. code-block:: bash

   # 安装 certbot
   sudo apt-get install -y certbot

   # 获取证书（需要域名指向服务器 IP）
   sudo certbot certonly --standalone -d turn.example.com

   # 证书路径
   # /etc/letsencrypt/live/turn.example.com/fullchain.pem
   # /etc/letsencrypt/live/turn.example.com/privkey.pem

   # 设置自动续期
   sudo crontab -e
   # 添加: 0 0 1 * * certbot renew --quiet && systemctl restart coturn

IP 地址配置
--------------------------

.. code-block:: bash

   # 外部 IP（公网 IP，必须配置）
   # 如果服务器在 NAT 后面，需要同时指定内网和外网 IP
   external-ip=203.0.113.1/192.168.1.100

   # 如果服务器有公网 IP，直接指定
   external-ip=203.0.113.1

   # 中继 IP（用于分配中继地址）
   relay-ip=192.168.1.100

安全配置
--------------------------

.. code-block:: bash

   # 允许的对端 IP 范围（限制中继可以连接的目标）
   # 默认允许所有，建议限制为私有网络
   allowed-peer-ip=10.0.0.0-10.255.255.255
   allowed-peer-ip=172.16.0.0-172.31.255.255
   allowed-peer-ip=192.168.0.0-192.168.255.255

   # 拒绝的对端 IP（阻止中继到特定 IP）
   # 防止 TURN 服务器被用作 SSRF 攻击工具
   denied-peer-ip=0.0.0.0-0.255.255.255
   denied-peer-ip=127.0.0.0-127.255.255.255
   denied-peer-ip=169.254.0.0-169.254.255.255

   # 禁止多播中继
   no-multicast-peers

   # 指纹验证（RFC 5389）
   fingerprint

   # 启用 Mobility ICE（RFC 8016）
   mobility

   # 禁止 loopback 对端
   no-loopback-peers

带宽限制
--------------------------

.. code-block:: bash

   # 每个会话的最大带宽（bps）
   max-bps=1000000

   # 总带宽限制（bps）
   total-quota=100000000

   # 每个用户的配额（字节）
   user-quota=0

   # 每个会话的配额（字节）
   bps-capacity=0

日志配置
--------------------------

.. code-block:: bash

   # 日志文件路径
   log-file=/var/log/turn.log

   # 或者输出到 stdout（适合 Docker）
   # log-file=stdout

   # 详细日志
   verbose

   # 不记录会话信息（减少日志量）
   # no-stdout-log

   # Syslog 输出
   # syslog

   # 日志绑定（记录每个绑定请求）
   # log-binding

数据库后端配置
--------------------------

coturn 支持多种数据库后端来存储用户凭证和会话信息：

**SQLite（默认）**:

.. code-block:: bash

   # SQLite 数据库路径
   userdb=/var/lib/turn/turndb

   # 使用 turnadmin 管理用户
   turnadmin -a -u walter -p pass1234 -r example.com -b /var/lib/turn/turndb

**PostgreSQL**:

.. code-block:: bash

   psql-userdb="host=localhost dbname=coturn user=coturn password=secret"

   # 创建数据库和表
   # psql -U postgres -c "CREATE DATABASE coturn;"
   # psql -U postgres -d coturn -f /usr/share/coturn/schema.sql

**MySQL/MariaDB**:

.. code-block:: bash

   mysql-userdb="host=localhost dbname=coturn user=coturn password=secret"

   # 创建数据库和表
   # mysql -u root -e "CREATE DATABASE coturn;"
   # mysql -u root coturn < /usr/share/coturn/schema.sql

**Redis**:

.. code-block:: bash

   redis-userdb="ip=127.0.0.1 dbname=0 password=secret connect_timeout=30"
   redis-statsdb="ip=127.0.0.1 dbname=1 password=secret connect_timeout=30"

   # Redis 适合存储动态的会话统计信息
   # 用户凭证建议存储在 SQLite/PostgreSQL/MySQL 中

中继端口范围
--------------------------

.. code-block:: bash

   # 中继端口范围（默认 49152-65535）
   min-port=49152
   max-port=65535

完整配置文件示例
--------------------------

以下是一个生产环境推荐的完整配置文件：

.. code-block:: bash

   # /etc/turnserver.conf - 生产环境配置

   # === 网络配置 ===
   listening-port=3478
   tls-listening-port=5349
   listening-ip=0.0.0.0
   listening-ip=::
   external-ip=YOUR_PUBLIC_IP/YOUR_PRIVATE_IP
   relay-ip=YOUR_PRIVATE_IP
   min-port=49152
   max-port=65535

   # === 域名和服务器名 ===
   realm=example.com
   server-name=turn.example.com

   # === 认证配置 ===
   use-auth-secret
   static-auth-secret=YOUR_STRONG_SECRET_KEY

   # === TLS 配置 ===
   cert=/etc/letsencrypt/live/turn.example.com/fullchain.pem
   pkey=/etc/letsencrypt/live/turn.example.com/privkey.pem
   no-tlsv1
   no-tlsv1_1
   cipher-list="ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256"

   # === 安全配置 ===
   fingerprint
   no-multicast-peers
   no-loopback-peers
   denied-peer-ip=0.0.0.0-0.255.255.255
   denied-peer-ip=10.0.0.0-10.255.255.255
   denied-peer-ip=100.64.0.0-100.127.255.255
   denied-peer-ip=127.0.0.0-127.255.255.255
   denied-peer-ip=169.254.0.0-169.254.255.255
   denied-peer-ip=172.16.0.0-172.31.255.255
   denied-peer-ip=192.0.0.0-192.0.0.255
   denied-peer-ip=192.0.2.0-192.0.2.255
   denied-peer-ip=192.88.99.0-192.88.99.255
   denied-peer-ip=192.168.0.0-192.168.255.255
   denied-peer-ip=198.18.0.0-198.19.255.255
   denied-peer-ip=198.51.100.0-198.51.100.255
   denied-peer-ip=203.0.113.0-203.0.113.255
   denied-peer-ip=240.0.0.0-255.255.255.255

   # === 带宽限制 ===
   max-bps=1500000
   total-quota=0

   # === 数据库 ===
   userdb=/var/lib/turn/turndb

   # === 日志 ===
   log-file=/var/log/turn.log
   verbose

   # === 进程 ===
   proc-user=turnserver
   proc-group=turnserver
   pidfile=/var/run/turnserver.pid


TURN over TCP 和 TLS
========================

当 UDP 被防火墙阻止时，TURN 可以使用 TCP 或 TLS 作为传输层：

**TURN over TCP**: 客户端通过 TCP 连接到 TURN 服务器的 3478 端口

**TURN over TLS（TURNS）**: 客户端通过 TLS 连接到 TURN 服务器的 5349 端口。从防火墙的角度看，这与普通的 HTTPS 流量无异，因此几乎可以穿透所有防火墙。

**TURN over DTLS**: 类似于 TURN over TLS，但使用 DTLS（基于 UDP 的 TLS），保持 UDP 的低延迟特性。

.. code-block:: javascript

   // WebRTC 客户端配置多种 TURN 传输方式
   const pc = new RTCPeerConnection({
     iceServers: [{
       urls: [
         'turn:turn.example.com:3478?transport=udp',   // 优先: UDP
         'turn:turn.example.com:3478?transport=tcp',   // 备选: TCP
         'turns:turn.example.com:5349?transport=tcp'   // 最后: TLS (穿透严格防火墙)
       ],
       username: 'user',
       credential: 'pass'
     }]
   });

**各传输方式对比**:

.. list-table::
   :header-rows: 1
   :widths: 20 15 15 15 35

   * - 传输方式
     - 延迟
     - 穿透能力
     - 加密
     - 适用场景
   * - TURN/UDP
     - 最低
     - 中
     - SRTP
     - 默认首选
   * - TURN/TCP
     - 中
     - 高
     - SRTP
     - UDP 被阻止时
   * - TURNS/TCP
     - 中
     - 最高
     - TLS + SRTP
     - 严格防火墙环境
   * - TURN/DTLS
     - 低
     - 中
     - DTLS + SRTP
     - 需要加密的 UDP 场景


运行与管理
========================

.. code-block:: bash

   # 前台运行（调试模式）
   turnserver -v -a -r example.com

   # 后台运行
   turnserver -o -a -f -v -r example.com

   # 使用配置文件运行
   turnserver -c /etc/turnserver.conf

   # 作为系统服务运行
   sudo systemctl start coturn
   sudo systemctl enable coturn

**常用命令行参数**:

.. code-block:: bash

   -o          # 后台运行（daemon 模式）
   -a          # 使用长期凭证机制
   -f          # 使用指纹（fingerprint）
   -v          # 详细日志
   -r realm    # 指定 realm
   -c file     # 指定配置文件
   --log-file  # 指定日志文件路径

systemd 服务管理
--------------------------

.. code-block:: bash

   # 启动/停止/重启
   sudo systemctl start coturn
   sudo systemctl stop coturn
   sudo systemctl restart coturn

   # 查看状态
   sudo systemctl status coturn

   # 开机自启
   sudo systemctl enable coturn

   # 查看日志
   sudo journalctl -u coturn -f

**自定义 systemd 服务文件**:

.. code-block:: ini

   # /etc/systemd/system/coturn.service
   [Unit]
   Description=coturn TURN/STUN server
   After=network.target

   [Service]
   Type=simple
   User=turnserver
   Group=turnserver
   ExecStart=/usr/bin/turnserver -c /etc/turnserver.conf
   Restart=on-failure
   RestartSec=5
   LimitNOFILE=100000

   [Install]
   WantedBy=multi-user.target

turnadmin 用户管理
--------------------------

.. code-block:: bash

   # 添加用户
   turnadmin -a -u walter -p pass1234 -r example.com

   # 删除用户
   turnadmin -d -u walter -r example.com

   # 列出所有用户
   turnadmin -l -r example.com

   # 设置共享密钥
   turnadmin -s my_secret_key -r example.com

   # 指定数据库
   turnadmin -a -u walter -p pass1234 -r example.com -b /var/lib/turn/turndb


测试
========================

使用 Trickle ICE 在线测试
-------------------------------

Trickle ICE 是一个在线工具，可以测试 STUN/TURN 服务器的连通性：

1. 打开 https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/
2. 添加 STUN/TURN 服务器地址
3. 点击 "Gather candidates"
4. 检查是否成功获取到 Server Reflexive 和 Relay 候选地址

使用 turnutils_uclient 测试
-------------------------------

coturn 自带测试工具 ``turnutils_uclient``：

.. code-block:: bash

   # 测试 STUN 绑定
   turnutils_uclient -t turn.example.com

   # 测试 TURN 分配（UDP）
   turnutils_uclient -T -u walter -w pass1234 turn.example.com

   # 测试 TURN over TCP
   turnutils_uclient -T -t -u walter -w pass1234 turn.example.com

   # 测试 TURN over TLS
   turnutils_uclient -T -S -u walter -w pass1234 turn.example.com -p 5349

   # 带宽测试
   turnutils_uclient -T -u walter -w pass1234 -b 1000000 turn.example.com

   # 使用 REST API 时限凭证测试
   turnutils_uclient -T -W my_super_secret_key_12345 turn.example.com

使用 turnutils_peer 测试
-------------------------------

``turnutils_peer`` 作为对端（peer）配合 ``turnutils_uclient`` 进行测试：

.. code-block:: bash

   # 在一台机器上启动 peer
   turnutils_peer -L 0.0.0.0 -p 3480

   # 在另一台机器上启动 client，指定 peer 地址
   turnutils_uclient -T -u walter -w pass1234 \
     -e PEER_IP -r 3480 \
     turn.example.com

日志分析
--------------------------

.. code-block:: bash

   # 查看 coturn 日志
   tail -f /var/log/turn.log

   # 关键日志信息
   # - Allocation 创建和销毁
   # - 认证成功和失败
   # - 中继流量统计
   # - 错误和警告

   # 使用 grep 过滤特定信息
   grep "401" /var/log/turn.log          # 认证失败
   grep "allocation" /var/log/turn.log   # 分配相关
   grep "error" /var/log/turn.log        # 错误信息

Prometheus 监控
--------------------------

coturn 支持通过 Prometheus 导出指标：

.. code-block:: bash

   # 启用 Prometheus 指标导出
   prometheus

   # 指标端点（默认 9641 端口）
   # http://localhost:9641/metrics

   # 常用指标:
   # - turn_total_allocations: 总分配数
   # - turn_active_allocations: 活跃分配数
   # - turn_total_traffic_rcvp: 接收包数
   # - turn_total_traffic_sntp: 发送包数
   # - turn_total_traffic_rcvb: 接收字节数
   # - turn_total_traffic_sntb: 发送字节数


性能优化
========================

端口范围配置
--------------------------

每个 TURN 分配（Allocation）需要一个中继端口。端口范围决定了服务器可以同时处理的最大分配数。

.. code-block:: bash

   # 扩大端口范围以支持更多并发连接
   min-port=10000
   max-port=65535
   # 可用端口数: 65535 - 10000 = 55535

多线程/多进程
--------------------------

coturn 支持多线程处理，可以利用多核 CPU：

.. code-block:: bash

   # 设置 relay 线程数（默认为 0，即自动检测 CPU 核心数）
   relay-threads=0

   # 或者手动指定
   relay-threads=4

最大分配数
--------------------------

.. code-block:: bash

   # 每个用户的最大分配数
   max-allocate-lifetime=3600

   # 默认分配生命周期（秒）
   # 客户端需要定期刷新（Refresh）以保持分配

连接数限制
--------------------------

.. code-block:: bash

   # 最大总分配数
   # total-quota=0  # 0 表示不限制

   # 每个用户的最大分配数
   # user-quota=0   # 0 表示不限制

   # 每个 IP 的最大分配数（防止单个 IP 滥用）
   # max-allocate-timeout=60

内核参数优化
--------------------------

对于高并发场景，需要调整 Linux 内核参数：

.. code-block:: bash

   # /etc/sysctl.conf

   # 增大 UDP 缓冲区
   net.core.rmem_max=26214400
   net.core.wmem_max=26214400
   net.core.rmem_default=26214400
   net.core.wmem_default=26214400

   # 增大连接跟踪表
   net.netfilter.nf_conntrack_max=1000000

   # 增大文件描述符限制
   fs.file-max=1000000

   # 增大 UDP 内存
   net.ipv4.udp_mem=8388608 12582912 16777216

   # 应用配置
   sudo sysctl -p

.. code-block:: bash

   # /etc/security/limits.conf
   # 增大进程文件描述符限制
   *  soft  nofile  1000000
   *  hard  nofile  1000000


安全加固
========================

防火墙规则
--------------------------

.. code-block:: bash

   # iptables 规则示例
   # 允许 STUN/TURN 端口
   iptables -A INPUT -p udp --dport 3478 -j ACCEPT
   iptables -A INPUT -p tcp --dport 3478 -j ACCEPT
   iptables -A INPUT -p tcp --dport 5349 -j ACCEPT

   # 允许中继端口范围
   iptables -A INPUT -p udp --dport 49152:65535 -j ACCEPT

   # 允许 Prometheus 指标端口（仅内网）
   iptables -A INPUT -p tcp --dport 9641 -s 10.0.0.0/8 -j ACCEPT

   # UFW 规则示例
   sudo ufw allow 3478/udp
   sudo ufw allow 3478/tcp
   sudo ufw allow 5349/tcp
   sudo ufw allow 49152:65535/udp

限制 Peer 地址
--------------------------

防止 TURN 服务器被用作 SSRF（Server-Side Request Forgery）攻击工具：

.. code-block:: bash

   # 拒绝中继到所有私有地址和特殊地址
   denied-peer-ip=0.0.0.0-0.255.255.255
   denied-peer-ip=10.0.0.0-10.255.255.255
   denied-peer-ip=100.64.0.0-100.127.255.255
   denied-peer-ip=127.0.0.0-127.255.255.255
   denied-peer-ip=169.254.0.0-169.254.255.255
   denied-peer-ip=172.16.0.0-172.31.255.255
   denied-peer-ip=192.0.0.0-192.0.0.255
   denied-peer-ip=192.0.2.0-192.0.2.255
   denied-peer-ip=192.168.0.0-192.168.255.255
   denied-peer-ip=198.18.0.0-198.19.255.255
   denied-peer-ip=240.0.0.0-255.255.255.255

防止 TURN Relay 滥用
--------------------------

TURN 中继会消耗大量带宽，需要防止滥用：

1. **使用时限凭证**: 避免凭证泄露后被长期滥用
2. **带宽限制**: 设置 ``max-bps`` 限制每个会话的带宽
3. **配额管理**: 设置 ``total-quota`` 和 ``user-quota``
4. **IP 白名单**: 如果可能，限制允许连接的客户端 IP
5. **监控告警**: 监控异常的流量模式和分配数量

安全最佳实践总结
--------------------------

1. **使用时限凭证**: 避免使用静态长期凭证，使用 REST API 时限凭证（``use-auth-secret``）
2. **凭证轮换**: 定期更换 ``static-auth-secret``
3. **IP 过滤**: 配置 ``denied-peer-ip`` 阻止中继到内网地址（防止 SSRF 攻击）
4. **TLS 加密**: 启用 TURNS（TLS）并使用有效的证书
5. **速率限制**: 配置带宽限制（``max-bps``）防止滥用
6. **最小权限**: 以非 root 用户运行 coturn
7. **防火墙规则**: 只开放必要的端口（3478, 5349, 49152-65535）
8. **日志监控**: 启用日志并监控异常行为
9. **定期更新**: 及时更新 coturn 版本以修复安全漏洞


Docker 部署示例
========================

以下是一个完整的 Docker Compose 部署示例：

.. code-block:: yaml

   # docker-compose.yml
   version: '3.8'

   services:
     coturn:
       image: coturn/coturn:latest
       container_name: coturn
       restart: unless-stopped
       network_mode: host
       volumes:
         - ./turnserver.conf:/etc/turnserver.conf:ro
         - ./certs:/etc/letsencrypt:ro
         - turn-data:/var/lib/turn
       command: ["-c", "/etc/turnserver.conf"]

   volumes:
     turn-data:

对应的配置文件：

.. code-block:: bash

   # turnserver.conf
   listening-port=3478
   tls-listening-port=5349
   listening-ip=0.0.0.0

   external-ip=YOUR_PUBLIC_IP

   realm=example.com
   server-name=turn.example.com

   use-auth-secret
   static-auth-secret=YOUR_SECRET_KEY

   cert=/etc/letsencrypt/live/turn.example.com/fullchain.pem
   pkey=/etc/letsencrypt/live/turn.example.com/privkey.pem

   min-port=49152
   max-port=65535

   fingerprint
   no-multicast-peers
   no-tlsv1
   no-tlsv1_1

   log-file=stdout
   verbose


云部署注意事项
========================

AWS 部署
--------------------------

* 使用 EC2 实例，选择网络优化型实例（如 c5n 系列）
* 安全组需要开放：UDP 3478, TCP 3478, TCP 5349, UDP 49152-65535
* ``external-ip`` 配置为 Elastic IP
* 如果使用 NLB（Network Load Balancer），需要配置 UDP 监听器

.. code-block:: bash

   # AWS 安全组规则
   # 入站规则:
   # UDP 3478      0.0.0.0/0    STUN/TURN
   # TCP 3478      0.0.0.0/0    TURN over TCP
   # TCP 5349      0.0.0.0/0    TURNS (TLS)
   # UDP 49152-65535  0.0.0.0/0  Relay 端口

   # external-ip 配置
   # external-ip=<Elastic IP>/<Private IP>
   # 例如: external-ip=54.123.45.67/172.31.0.100

GCP 部署
--------------------------

* 使用 Compute Engine 实例
* 防火墙规则需要允许相应端口
* ``external-ip`` 配置为静态外部 IP
* 可以使用 Cloud NAT，但需要注意端口映射

.. code-block:: bash

   # GCP 防火墙规则
   gcloud compute firewall-rules create allow-coturn \
     --allow udp:3478,tcp:3478,tcp:5349,udp:49152-65535 \
     --source-ranges 0.0.0.0/0 \
     --target-tags coturn

阿里云部署
--------------------------

* 使用 ECS 实例
* 安全组需要开放相应端口
* ``external-ip`` 配置为弹性公网 IP（EIP）
* 注意：阿里云 ECS 的公网 IP 是通过 NAT 映射的，需要配置 ``external-ip=<公网IP>/<内网IP>``

.. code-block:: bash

   # 阿里云安全组规则
   # 入方向:
   # UDP 3478      0.0.0.0/0
   # TCP 3478      0.0.0.0/0
   # TCP 5349      0.0.0.0/0
   # UDP 49152-65535  0.0.0.0/0

   # external-ip 配置
   # external-ip=<EIP>/<内网IP>

通用建议
--------------------------

* 选择靠近用户的区域部署，降低中继延迟
* 使用多个区域部署多个 TURN 服务器，客户端配置多个 ICE 服务器
* 监控带宽使用量，TURN 中继流量成本较高
* 考虑使用 TCP 443 端口作为备用监听端口（穿透更多防火墙）
* 使用弹性 IP（Elastic IP / EIP），避免实例重启后 IP 变化
* 配置健康检查和自动恢复机制


Reference
========================

* RFC 5389 - Session Traversal Utilities for NAT (STUN)

  - https://tools.ietf.org/html/rfc5389

* RFC 8489 - Session Traversal Utilities for NAT (STUN) (更新版)

  - https://tools.ietf.org/html/rfc8489

* RFC 5766 - Traversal Using Relays around NAT (TURN)

  - https://tools.ietf.org/html/rfc5766

* RFC 8656 - Traversal Using Relays around NAT (TURN): Relay Extensions to STUN (更新版)

  - https://tools.ietf.org/html/rfc8656

* RFC 8445 - Interactive Connectivity Establishment (ICE)

  - https://tools.ietf.org/html/rfc8445

* RFC 8016 - Mobility with Traversal Using Relays around NAT (TURN)

  - https://tools.ietf.org/html/rfc8016

* coturn GitHub 仓库

  - https://github.com/coturn/coturn

* coturn Docker 镜像

  - https://hub.docker.com/r/coturn/coturn

* WebRTC ICE 详解

  - https://webrtcforthecurious.com/

* TURN REST API 规范

  - https://datatracker.ietf.org/doc/html/draft-uberti-behave-turn-rest-00

* Trickle ICE 在线测试工具

  - https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/
