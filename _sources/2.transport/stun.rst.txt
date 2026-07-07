################################################
STUN
################################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =========================================
**Abstract** STUN protocol
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ =========================================



.. contents::
   :local:


概述
================

STUN (Session Traversal Utilities for NAT) 是一种轻量级的网络协议，用于帮助位于 NAT (Network Address Translation) 后面的终端发现其公网地址和端口。在 WebRTC 中，STUN 是 ICE (Interactive Connectivity Establishment) 框架的核心组成部分，用于 NAT 穿越和连接建立。

STUN 最初在 RFC 3489 中定义为 "Simple Traversal of UDP through NATs"，后来在 RFC 5389 中被重新定义为 "Session Traversal Utilities for NAT"，并在 RFC 8489 中进一步更新。新版本的 STUN 不再试图作为一个完整的 NAT 穿越解决方案，而是作为其他协议（如 ICE、TURN）的工具。

STUN 的核心功能包括：

* **地址发现 (Address Discovery)**: 终端通过向 STUN 服务器发送 Binding Request，获取自己的公网 IP 地址和端口（即 server reflexive address）
* **连接性检查 (Connectivity Check)**: 在 ICE 中，STUN 用于在候选地址对之间进行连接性检查
* **保活 (Keepalive)**: 通过定期发送 STUN Binding Indication 来维持 NAT 映射
* **NAT 行为发现 (NAT Behavior Discovery)**: 检测 NAT 的类型和行为特征


STUN 相关规范
================

* RFC 3489 - "classic" STUN，最初的 STUN 规范，已被 RFC 5389 取代
* RFC 5389 - "new" STUN 基础规范，重新定义了 STUN 协议
* RFC 8489 - 最新的 STUN 规范，取代 RFC 5389，增加了对 IPv6 的更好支持
* RFC 5769 - STUN 协议测试向量，用于验证 STUN 实现的正确性
* RFC 5780 - NAT 行为发现支持，扩展了 STUN 以检测 NAT 类型
* RFC 7443 - STUN 和 TURN 的 ALPN (Application-Layer Protocol Negotiation) 支持
* RFC 7635 - oAuth 第三方 TURN/STUN 授权
* RFC 8445 - ICE (Interactive Connectivity Establishment) 规范，定义了 STUN 在 ICE 中的使用


STUN 消息结构
=============================

STUN 消息采用二进制编码，使用网络字节序（大端序，big-endian）。所有 STUN 消息由一个 20 字节的头部和零个或多个属性组成。

STUN 消息头部
-----------------------------

STUN 头部包含以下字段：

* **Message Type (消息类型)**: 14 位，标识消息的类别和方法
* **Message Length (消息长度)**: 16 位，表示 STUN 负载的总长度（不包括 20 字节头部），必须是 4 的倍数
* **Magic Cookie**: 固定值 ``0x2112A442``，用于区分新旧版本的 STUN 消息
* **Transaction ID**: 96 位（12 字节），用于关联请求和响应

.. code-block::

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

头部的前两位必须为 0，这使得 STUN 消息可以与其他协议（如 RTP、DTLS）在同一端口上进行多路复用（multiplexing）。Magic Cookie 的值 ``0x2112A442`` 是在 RFC 5389 中引入的，旧版 RFC 3489 的消息没有这个固定值。


STUN 消息类型
-----------------------------

STUN Message Type 由 14 位组成，其中包含了 method 和 class 两部分信息：

* **Method**: 标识操作类型，最常用的是 Binding (0x001)
* **Class**: 标识消息类别，包括 Request、Success Response、Error Response 和 Indication

.. code-block::

    消息类型编码:

    0x0001 : Binding Request          (请求)
    0x0101 : Binding Success Response (成功响应)
    0x0111 : Binding Error Response   (错误响应)
    0x0011 : Binding Indication       (指示，无需响应)

Message Type 的位结构如下：

.. code-block::

        0                 1
        2  3  4 5 6 7 8 9 0 1 2 3 4 5
       +--+--+-+-+-+-+-+-+-+-+-+-+-+-+
       |M |M |M|M|M|C|M|M|M|C|M|M|M|
       |11|10|9|8|7|1|6|5|4|0|3|2|1|
       +--+--+-+-+-+-+-+-+-+-+-+-+-+-+

其中 C1C0 表示 class:

* ``00`` = Request
* ``01`` = Indication
* ``10`` = Success Response
* ``11`` = Error Response

旧版 RFC 3489 还定义了 Shared Secret 相关的消息类型，但在 RFC 5389 中已被移除：

.. code-block::

    0x0002 : Shared Secret Request        (已废弃)
    0x0102 : Shared Secret Response       (已废弃)
    0x0112 : Shared Secret Error Response (已废弃)


STUN 属性
=============================

STUN 属性采用 TLV (Type-Length-Value) 编码格式。每个属性由类型、长度和值组成，并按 4 字节边界对齐。

.. code-block::

      0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |         Type                  |            Length             |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |                         Value (variable)                ....
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

核心属性
-----------------------------

**MAPPED-ADDRESS (0x0001)**

包含客户端的公网 IP 地址和端口。在 Binding Response 中返回，表示 STUN 服务器看到的客户端源地址。这是 RFC 3489 中定义的属性，在新版 STUN 中被 XOR-MAPPED-ADDRESS 取代。

**XOR-MAPPED-ADDRESS (0x0020)**

与 MAPPED-ADDRESS 类似，但地址和端口经过 XOR 运算进行了混淆。XOR 的目的是防止某些 NAT 设备对 STUN 消息中的地址进行篡改（某些 NAT 会检查并修改数据包中的 IP 地址）。

XOR 运算规则：

* 端口与 Magic Cookie 的高 16 位进行 XOR
* IPv4 地址与 Magic Cookie 进行 XOR
* IPv6 地址与 Magic Cookie 加 Transaction ID 的拼接进行 XOR

**USERNAME (0x0006)**

用于消息完整性检查的用户名。在 ICE 连接性检查中，USERNAME 的格式为 ``ufrag:ufrag``，由远端和本地的 ICE 用户名片段组成。

**MESSAGE-INTEGRITY (0x0008)**

包含消息的 HMAC-SHA1 值（20 字节），用于验证消息的完整性和认证。HMAC 的密钥取决于认证机制：

* 短期凭证 (Short-term credential): 使用 ICE password 作为密钥
* 长期凭证 (Long-term credential): 使用 MD5(username:realm:password) 作为密钥

MESSAGE-INTEGRITY 必须是消息中最后一个属性（FINGERPRINT 除外）。

**MESSAGE-INTEGRITY-SHA256 (0x001C)**

RFC 8489 中新增的属性，使用 HMAC-SHA256 替代 HMAC-SHA1，提供更强的安全性。

**FINGERPRINT (0x8028)**

包含消息的 CRC-32 校验值，经过 XOR ``0x5354554e`` 处理。用于在多路复用场景中区分 STUN 消息和其他协议的数据包。FINGERPRINT 必须是消息的最后一个属性。

**ERROR-CODE (0x0009)**

出现在 Error Response 中，包含错误码（100-699）和 UTF-8 编码的错误描述。常见错误码：

.. code-block::

    300  Try Alternate      - 客户端应尝试备用服务器
    400  Bad Request        - 请求格式错误
    401  Unauthorized       - 需要认证（长期凭证）
    420  Unknown Attribute  - 包含未知的必须理解的属性
    438  Stale Nonce        - Nonce 已过期
    500  Server Error       - 服务器内部错误
    487  Role Conflict      - ICE 角色冲突

**REALM (0x0014)**

用于长期凭证机制，标识认证域。

**NONCE (0x0015)**

用于长期凭证机制，服务器生成的一次性随机值，防止重放攻击。

其他属性
-----------------------------

* **RESPONSE-ADDRESS (0x0002)**: 已废弃，指定 Binding Response 的发送目标地址
* **CHANGE-REQUEST (0x0003)**: 已废弃，请求服务器从不同的 IP 或端口发送响应，用于 NAT 类型检测
* **SOURCE-ADDRESS (0x0004)**: 已废弃，指示响应的源地址
* **CHANGED-ADDRESS (0x0005)**: 已废弃，指示备用地址
* **PASSWORD (0x0007)**: 已废弃，被 MESSAGE-INTEGRITY 机制取代
* **REFLECTED-FROM (0x000b)**: 已废弃，用于防止 STUN 被用作 DDoS 攻击的反射器
* **SOFTWARE (0x8022)**: 包含软件版本信息的文本描述
* **ALTERNATE-SERVER (0x8023)**: 指示客户端应尝试的备用服务器地址
* **PRIORITY (0x0024)**: ICE 中使用，表示候选地址的优先级
* **USE-CANDIDATE (0x0025)**: ICE 中使用，由 controlling agent 发送，表示选择该候选对
* **ICE-CONTROLLED (0x8029)**: ICE 中使用，表示发送方是 controlled agent
* **ICE-CONTROLLING (0x802a)**: ICE 中使用，表示发送方是 controlling agent


NAT 类型与 STUN 行为
=============================

NAT 类型分类
-----------------------------

根据 RFC 3489 的分类（虽然已简化，但仍被广泛引用），NAT 可分为以下四种类型：

**1. Full Cone NAT (完全锥形 NAT)**

一旦内部地址 (iAddr:iPort) 被映射到外部地址 (eAddr:ePort)，任何外部主机都可以通过 (eAddr:ePort) 向内部主机发送数据包。这是最宽松的 NAT 类型。

.. code-block::

    内部主机 A (192.168.1.100:5000)
         |
    NAT 映射: 192.168.1.100:5000 → 203.0.113.1:8000
         |
    任何外部主机都可以向 203.0.113.1:8000 发送数据

**2. Restricted Cone NAT (受限锥形 NAT)**

只有内部主机曾经向其发送过数据包的外部主机 IP 地址，才能通过映射地址向内部主机发送数据包。端口不受限制。

.. code-block::

    内部主机 A 向外部主机 B (198.51.100.1) 发送过数据
         |
    NAT 映射: 192.168.1.100:5000 → 203.0.113.1:8000
         |
    只有 198.51.100.1 的任意端口可以向 203.0.113.1:8000 发送数据

**3. Port Restricted Cone NAT (端口受限锥形 NAT)**

与 Restricted Cone 类似，但进一步限制了端口。只有内部主机曾经向其发送过数据包的外部主机 IP 地址和端口，才能通过映射地址向内部主机发送数据包。

.. code-block::

    内部主机 A 向外部主机 B (198.51.100.1:9000) 发送过数据
         |
    NAT 映射: 192.168.1.100:5000 → 203.0.113.1:8000
         |
    只有 198.51.100.1:9000 可以向 203.0.113.1:8000 发送数据

**4. Symmetric NAT (对称 NAT)**

对于从同一内部地址发往不同目标地址的请求，NAT 会分配不同的外部映射。这意味着即使是同一个内部地址和端口，发往不同目标时会得到不同的外部端口。

.. code-block::

    内部主机 A (192.168.1.100:5000) → 目标 B → NAT 映射为 203.0.113.1:8000
    内部主机 A (192.168.1.100:5000) → 目标 C → NAT 映射为 203.0.113.1:8001
    (不同目标，不同的外部端口)

NAT 类型检测算法
-----------------------------

RFC 3489 定义了一种使用 STUN 检测 NAT 类型的算法（RFC 5780 提供了更新的方法）：

.. code-block::

    步骤 1: 向 STUN 服务器发送 Binding Request
            如果没有收到响应 → UDP 被阻止
            如果 MAPPED-ADDRESS == 本地地址 → 没有 NAT (开放互联网)

    步骤 2: 发送带有 CHANGE-REQUEST (change IP + change port) 的请求
            如果收到响应 → Full Cone NAT

    步骤 3: 向 STUN 服务器的另一个 IP 发送 Binding Request
            如果 MAPPED-ADDRESS 与步骤 1 不同 → Symmetric NAT

    步骤 4: 发送带有 CHANGE-REQUEST (change port only) 的请求
            如果收到响应 → Restricted Cone NAT
            如果没有收到响应 → Port Restricted Cone NAT

STUN 与 Symmetric NAT 的局限性
-----------------------------------------

STUN 无法穿越 Symmetric NAT，原因如下：

1. 当客户端向 STUN 服务器发送请求时，NAT 为该连接分配了一个外部端口 (ePort1)
2. STUN 服务器返回的 MAPPED-ADDRESS 包含 ePort1
3. 当客户端尝试与对端通信时，NAT 会为这个新的目标分配一个不同的外部端口 (ePort2)
4. 对端使用 ePort1 发送的数据包无法到达客户端，因为 NAT 期望的是 ePort2

在这种情况下，必须使用 TURN (Traversal Using Relays around NAT) 服务器作为中继来转发数据。


STUN 在 WebRTC ICE 中的应用
=============================

Server Reflexive 候选地址 (srflx)
-----------------------------------------

在 ICE 候选地址收集阶段，WebRTC 终端向 STUN 服务器发送 Binding Request，获取自己的 server reflexive 候选地址。这个地址代表了终端在公网上可见的 IP 和端口。

.. code-block::

    WebRTC 终端                    STUN 服务器
         |                              |
         |--- Binding Request --------->|
         |                              |
         |<-- Binding Response ---------|
         |    (XOR-MAPPED-ADDRESS:      |
         |     203.0.113.1:8000)        |
         |                              |

    收集到的候选地址:
    - host:  192.168.1.100:5000  (本地地址)
    - srflx: 203.0.113.1:8000   (server reflexive 地址)

在 SDP 中，srflx 候选地址的表示如下：

.. code-block::

    a=candidate:2 1 UDP 1694498815 203.0.113.1 8000 typ srflx raddr 192.168.1.100 rport 5000

STUN 连接性检查
-----------------------------------------

ICE 连接性检查使用 STUN Binding Request/Response 来验证候选地址对之间的连通性。与普通的 STUN 地址发现不同，连接性检查的 STUN 消息包含 ICE 凭证：

.. code-block::

    STUN Binding Request (连接性检查):
    - USERNAME: "remote_ufrag:local_ufrag"
    - ICE-CONTROLLING 或 ICE-CONTROLLED (带 tie-breaker)
    - PRIORITY: 候选地址的优先级
    - USE-CANDIDATE: (仅 controlling agent 在 nominated pair 上发送)
    - MESSAGE-INTEGRITY: 使用远端的 ICE password 计算

    STUN Binding Response (连接性检查响应):
    - XOR-MAPPED-ADDRESS: 请求的源地址
    - MESSAGE-INTEGRITY: 使用本地的 ICE password 计算

ICE 候选对测试
-----------------------------------------

ICE 将本地候选地址和远端候选地址配对，形成候选对 (candidate pair)，然后按优先级顺序进行连接性检查：

1. **Waiting**: 候选对等待被检查
2. **In-Progress**: 已发送 STUN 请求，等待响应
3. **Succeeded**: 收到成功的 STUN 响应
4. **Failed**: STUN 请求超时或收到错误响应
5. **Frozen**: 候选对被冻结，等待相关检查完成

当一个候选对的连接性检查成功后，ICE 会进行提名 (nomination)，选择最佳的候选对用于媒体传输。

STUN 保活
-----------------------------------------

在 ICE 连接建立后，WebRTC 使用 STUN Binding Indication 作为保活机制，防止 NAT 映射超时。保活间隔通常为 15-25 秒（RFC 8445 建议不超过 Tr 秒，默认 15 秒）。

.. code-block::

    STUN Binding Indication (保活):
    - 不需要响应
    - 不包含认证属性
    - 仅用于维持 NAT 绑定


STUN 与 TURN 的比较
=============================

STUN 和 TURN 都是 NAT 穿越的工具，但它们的工作方式和适用场景不同：

.. list-table:: STUN vs TURN
   :header-rows: 1
   :widths: 30 35 35

   * - 特性
     - STUN
     - TURN
   * - 功能
     - 地址发现和连接性检查
     - 媒体中继转发
   * - 数据路径
     - 点对点 (P2P)
     - 经过 TURN 服务器中继
   * - 带宽消耗
     - 仅信令，极低
     - 所有媒体数据经过服务器，高
   * - 延迟
     - 低（直连）
     - 较高（多一跳）
   * - Symmetric NAT
     - 无法穿越
     - 可以穿越
   * - 服务器成本
     - 极低
     - 高（带宽和计算资源）
   * - 使用频率
     - 约 80-90% 的连接
     - 约 10-20% 的连接

在实际的 WebRTC 部署中，建议同时配置 STUN 和 TURN 服务器：

.. code-block:: javascript

    const configuration = {
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        {
          urls: 'turn:turn.example.com:3478',
          username: 'user',
          credential: 'password'
        }
      ]
    };
    const pc = new RTCPeerConnection(configuration);


STUN 服务器部署
=============================

公共 STUN 服务器
-----------------------------------------

Google 和其他组织提供了免费的公共 STUN 服务器：

.. code-block::

    stun:stun.l.google.com:19302
    stun:stun1.l.google.com:19302
    stun:stun2.l.google.com:19302
    stun:stun3.l.google.com:19302
    stun:stun4.l.google.com:19302
    stun:stun.stunprotocol.org:3478

.. note::

    公共 STUN 服务器仅适用于开发和测试。生产环境应部署自己的 STUN/TURN 服务器。

使用 coturn 部署
-----------------------------------------

coturn 是最流行的开源 STUN/TURN 服务器实现：

.. code-block:: bash

    # 安装 coturn
    sudo apt-get install coturn

    # 编辑配置文件 /etc/turnserver.conf
    listening-port=3478
    tls-listening-port=5349
    listening-ip=0.0.0.0
    external-ip=203.0.113.1
    realm=example.com
    server-name=turn.example.com
    lt-cred-mech
    user=webrtc:password123
    fingerprint
    no-stdout-log
    log-file=/var/log/turnserver.log

    # 启动服务
    sudo systemctl start coturn


安全机制
=============================

短期凭证 (Short-term Credential)
-----------------------------------------

短期凭证机制主要用于 ICE 连接性检查。凭证（username 和 password）通过信令通道交换，生命周期与 ICE 会话相同。

.. code-block::

    认证流程:
    1. 通过 SDP 交换 ice-ufrag 和 ice-pwd
    2. STUN 请求中包含 USERNAME = "remote_ufrag:local_ufrag"
    3. MESSAGE-INTEGRITY 使用 remote ice-pwd 作为 HMAC-SHA1 密钥
    4. 接收方验证 MESSAGE-INTEGRITY

长期凭证 (Long-term Credential)
-----------------------------------------

长期凭证机制主要用于 TURN 服务器认证，采用挑战-响应 (challenge-response) 模式：

.. code-block::

    认证流程:
    1. 客户端发送请求（无认证信息）
    2. 服务器返回 401 Unauthorized，包含 REALM 和 NONCE
    3. 客户端使用 MD5(username:realm:password) 作为密钥
       重新发送请求，包含 USERNAME、REALM、NONCE 和 MESSAGE-INTEGRITY
    4. 服务器验证 MESSAGE-INTEGRITY

MESSAGE-INTEGRITY 计算
-----------------------------------------

MESSAGE-INTEGRITY 属性包含整个 STUN 消息（直到并包括 MESSAGE-INTEGRITY 属性之前的部分）的 HMAC-SHA1 值：

.. code-block::

    HMAC-SHA1(key, STUN message up to MESSAGE-INTEGRITY)

    其中:
    - 短期凭证: key = SASLprep(password)
    - 长期凭证: key = MD5(username:realm:SASLprep(password))

FINGERPRINT 属性包含 CRC-32 校验值，用于在多路复用场景中快速识别 STUN 消息：

.. code-block::

    FINGERPRINT = CRC-32(STUN message) XOR 0x5354554e


代码示例
=============================

解析 STUN 消息
-----------------------------------------

以下是一个用 Python 解析 STUN 消息的示例：

.. code-block:: python

    import struct
    import hashlib
    import hmac

    # STUN 常量
    STUN_MAGIC_COOKIE = 0x2112A442
    STUN_HEADER_SIZE = 20

    # STUN 消息类型
    STUN_BINDING_REQUEST = 0x0001
    STUN_BINDING_RESPONSE = 0x0101
    STUN_BINDING_ERROR_RESPONSE = 0x0111
    STUN_BINDING_INDICATION = 0x0011

    # STUN 属性类型
    ATTR_MAPPED_ADDRESS = 0x0001
    ATTR_USERNAME = 0x0006
    ATTR_MESSAGE_INTEGRITY = 0x0008
    ATTR_ERROR_CODE = 0x0009
    ATTR_XOR_MAPPED_ADDRESS = 0x0020
    ATTR_PRIORITY = 0x0024
    ATTR_USE_CANDIDATE = 0x0025
    ATTR_FINGERPRINT = 0x8028
    ATTR_ICE_CONTROLLED = 0x8029
    ATTR_ICE_CONTROLLING = 0x802A

    class StunMessage:
        """STUN 消息解析器"""

        def __init__(self):
            self.msg_type = 0
            self.msg_length = 0
            self.magic_cookie = 0
            self.transaction_id = b''
            self.attributes = []

        @staticmethod
        def parse(data: bytes) -> 'StunMessage':
            """解析 STUN 消息"""
            if len(data) < STUN_HEADER_SIZE:
                raise ValueError("数据太短，不是有效的 STUN 消息")

            msg = StunMessage()

            # 解析头部
            msg.msg_type, msg.msg_length, msg.magic_cookie = \
                struct.unpack('!HHI', data[0:8])
            msg.transaction_id = data[8:20]

            # 验证 Magic Cookie
            if msg.magic_cookie != STUN_MAGIC_COOKIE:
                raise ValueError(f"无效的 Magic Cookie: {msg.magic_cookie:#x}")

            # 验证前两位为 0
            if msg.msg_type & 0xC000:
                raise ValueError("STUN 消息类型的前两位必须为 0")

            # 解析属性
            offset = STUN_HEADER_SIZE
            while offset < STUN_HEADER_SIZE + msg.msg_length:
                if offset + 4 > len(data):
                    break
                attr_type, attr_length = struct.unpack('!HH', data[offset:offset+4])
                attr_value = data[offset+4:offset+4+attr_length]
                msg.attributes.append((attr_type, attr_value))
                # 属性按 4 字节对齐
                offset += 4 + attr_length + (4 - attr_length % 4) % 4

            return msg

        def get_xor_mapped_address(self):
            """提取 XOR-MAPPED-ADDRESS"""
            for attr_type, attr_value in self.attributes:
                if attr_type == ATTR_XOR_MAPPED_ADDRESS:
                    family = attr_value[1]
                    xor_port = struct.unpack('!H', attr_value[2:4])[0]
                    port = xor_port ^ (STUN_MAGIC_COOKIE >> 16)

                    if family == 0x01:  # IPv4
                        xor_addr = struct.unpack('!I', attr_value[4:8])[0]
                        addr = xor_addr ^ STUN_MAGIC_COOKIE
                        ip = f"{(addr>>24)&0xFF}.{(addr>>16)&0xFF}.{(addr>>8)&0xFF}.{addr&0xFF}"
                        return (ip, port)
            return None

        def get_message_class(self):
            """获取消息类别"""
            c0 = (self.msg_type >> 4) & 0x1
            c1 = (self.msg_type >> 8) & 0x1
            return (c1 << 1) | c0

        def get_method(self):
            """获取消息方法"""
            return (self.msg_type & 0x000F) | \
                   ((self.msg_type & 0x00E0) >> 1) | \
                   ((self.msg_type & 0x3E00) >> 2)

    # 使用示例
    # data = receive_stun_packet()
    # msg = StunMessage.parse(data)
    # addr = msg.get_xor_mapped_address()
    # print(f"Public address: {addr[0]}:{addr[1]}")


抓包分析
-----------------------------------------

使用 Wireshark 或 tcpdump 可以捕获和分析 STUN 消息：

.. code-block:: bash

    # 使用 tcpdump 捕获 STUN 流量
    tcpdump -i eth0 -n udp port 3478 -w stun_capture.pcap

    # 在 Wireshark 中使用过滤器
    # stun
    # stun.type == 0x0001  (Binding Request)
    # stun.type == 0x0101  (Binding Response)

一个典型的 STUN Binding Request/Response 交互：

.. code-block::

    Binding Request:
      Message Type: 0x0001 (Binding Request)
      Message Length: 0
      Magic Cookie: 0x2112A442
      Transaction ID: 0x7a3f5c...

    Binding Response:
      Message Type: 0x0101 (Binding Success Response)
      Message Length: 44
      Magic Cookie: 0x2112A442
      Transaction ID: 0x7a3f5c... (与请求相同)
      Attributes:
        XOR-MAPPED-ADDRESS: 203.0.113.1:8000
        SOFTWARE: "coturn-4.5.2"
        FINGERPRINT: 0x...


参考资料
=============================

* `RFC 3489 - STUN - Simple Traversal of User Datagram Protocol (UDP) Through Network Address Translators (NATs) <https://datatracker.ietf.org/doc/html/rfc3489>`_
* `RFC 5389 - Session Traversal Utilities for NAT (STUN) <https://datatracker.ietf.org/doc/html/rfc5389>`_
* `RFC 8489 - Session Traversal Utilities for NAT (STUN) <https://datatracker.ietf.org/doc/html/rfc8489>`_
* `RFC 8445 - Interactive Connectivity Establishment (ICE) <https://datatracker.ietf.org/doc/html/rfc8445>`_
* `RFC 5769 - Test Vectors for Session Traversal Utilities for NAT (STUN) <https://datatracker.ietf.org/doc/html/rfc5769>`_
* `RFC 5780 - NAT Behavior Discovery Using Session Traversal Utilities for NAT (STUN) <https://datatracker.ietf.org/doc/html/rfc5780>`_
