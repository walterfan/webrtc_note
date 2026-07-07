########################
TLS 协议
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** TLS protocol
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=======================

TLS (Transport Layer Security) 是一种广泛使用的安全协议，用于在两个通信方之间提供隐私和数据完整性保护。TLS 是 SSL (Secure Sockets Layer) 的后继者，目前已经发展到 TLS 1.3 版本。

在 WebRTC 中，TLS 及其变体 DTLS (Datagram TLS) 扮演着至关重要的角色：

* **DTLS** 用于保护媒体传输通道，并为 SRTP 提供密钥协商
* **TLS** 用于保护信令通道（如 WebSocket over TLS）
* **DTLS-SRTP** 是 WebRTC 强制要求的媒体加密方案

TLS 版本演进
-----------------------

.. list-table:: TLS 版本历史
   :header-rows: 1
   :widths: 15 15 40 30

   * - 版本
     - 年份
     - 主要特点
     - 状态
   * - SSL 3.0
     - 1996
     - SSL 的最后版本
     - 已废弃 (RFC 7568)
   * - TLS 1.0
     - 1999
     - RFC 2246，基于 SSL 3.0
     - 已废弃 (RFC 8996)
   * - TLS 1.1
     - 2006
     - RFC 4346，修复 CBC 攻击
     - 已废弃 (RFC 8996)
   * - TLS 1.2
     - 2008
     - RFC 5246，支持 AEAD，灵活的密码套件
     - 广泛使用
   * - TLS 1.3
     - 2018
     - RFC 8446，1-RTT 握手，移除弱密码
     - 推荐使用


TLS 1.2 握手协议
=======================

TLS 1.2 的握手过程需要 2 个 RTT (Round-Trip Time) 才能完成，建立安全连接后才能传输应用数据。

完整握手流程
-----------------------

.. code-block::

    Client                                               Server

    ClientHello                  -------->
                                                    ServerHello
                                                   Certificate*
                                             ServerKeyExchange*
                                            CertificateRequest*
                                 <--------      ServerHelloDone
    Certificate*
    ClientKeyExchange
    CertificateVerify*
    [ChangeCipherSpec]
    Finished                     -------->
                                             [ChangeCipherSpec]
                                 <--------             Finished

    Application Data             <------->     Application Data

各步骤详解：

**1. ClientHello**

客户端发起握手，包含以下信息：

* 支持的 TLS 版本
* 客户端随机数 (Client Random, 32 字节)
* Session ID（用于会话恢复）
* 支持的密码套件列表 (Cipher Suites)
* 支持的压缩方法
* 扩展 (Extensions)，如 SNI、supported_groups、signature_algorithms

**2. ServerHello**

服务器响应，选择参数：

* 选定的 TLS 版本
* 服务器随机数 (Server Random, 32 字节)
* Session ID
* 选定的密码套件
* 选定的压缩方法

**3. Certificate**

服务器发送其 X.509 证书链，客户端用于验证服务器身份。

**4. ServerKeyExchange**

当使用 DHE 或 ECDHE 密钥交换时，服务器发送临时公钥参数。

**5. CertificateRequest (可选)**

服务器请求客户端证书，用于双向认证 (mutual TLS)。

**6. ServerHelloDone**

标志服务器 Hello 阶段结束。

**7. ClientKeyExchange**

客户端发送密钥交换参数。对于 RSA，发送用服务器公钥加密的 Pre-Master Secret；对于 ECDHE，发送客户端的临时公钥。

**8. ChangeCipherSpec**

通知对方后续消息将使用协商好的密码套件加密。

**9. Finished**

包含所有握手消息的哈希值，用于验证握手过程的完整性。

密钥推导
-----------------------

TLS 1.2 的密钥推导过程：

.. code-block::

    Pre-Master Secret
         |
         v
    Master Secret = PRF(pre_master_secret,
                        "master secret",
                        ClientHello.random + ServerHello.random)
         |
         v
    Key Block = PRF(master_secret,
                    "key expansion",
                    ServerHello.random + ClientHello.random)
         |
         v
    +-- client_write_MAC_key
    +-- server_write_MAC_key
    +-- client_write_key
    +-- server_write_key
    +-- client_write_IV
    +-- server_write_IV

会话恢复
-----------------------

TLS 1.2 支持两种会话恢复机制，避免完整握手的开销：

**Session ID 恢复**

.. code-block::

    Client                                               Server

    ClientHello
    (with Session ID)            -------->
                                                    ServerHello
                                            (with same Session ID)
                                             [ChangeCipherSpec]
                                 <--------             Finished
    [ChangeCipherSpec]
    Finished                     -------->

    Application Data             <------->     Application Data

**Session Ticket 恢复 (RFC 5077)**

服务器将会话状态加密后作为 ticket 发送给客户端，客户端在后续连接中携带该 ticket，服务器无需维护会话状态。

.. code-block::

    Client                                               Server

    ClientHello
    (empty SessionTicket extension)-------->
                                                    ServerHello
                                (empty SessionTicket extension)
                                                   Certificate*
                                             ServerKeyExchange*
                                            CertificateRequest*
                                 <--------      ServerHelloDone
    Certificate*
    ClientKeyExchange
    CertificateVerify*
    [ChangeCipherSpec]
    Finished                     -------->
                                               NewSessionTicket
                                             [ChangeCipherSpec]
                                 <--------             Finished
    Application Data             <------->     Application Data


TLS 1.3 改进
=======================

TLS 1.3 (RFC 8446) 是 TLS 协议的重大升级，在安全性和性能方面都有显著改进。

1-RTT 握手
-----------------------

TLS 1.3 将握手缩短为 1 个 RTT：

.. code-block::

    Client                                               Server

    ClientHello
    + key_share
    + signature_algorithms
    + psk_key_exchange_modes
    + pre_shared_key            -------->
                                                    ServerHello
                                                    + key_share
                                               + pre_shared_key
                                           {EncryptedExtensions}
                                           {CertificateRequest*}
                                                  {Certificate*}
                                            {CertificateVerify*}
                                                      {Finished}
                                 <--------
    {Certificate*}
    {CertificateVerify*}
    {Finished}                   -------->

    [Application Data]           <------->  [Application Data]

关键改进：客户端在 ClientHello 中就发送了 key_share（密钥交换参数），服务器可以立即计算共享密钥，无需额外的往返。

0-RTT 恢复 (Early Data)
-----------------------

TLS 1.3 支持 0-RTT 恢复，客户端可以在第一个消息中就发送应用数据：

.. code-block::

    Client                                               Server

    ClientHello
    + early_data
    + key_share
    + psk_key_exchange_modes
    + pre_shared_key
    (Application Data)           -------->
                                                    ServerHello
                                               + pre_shared_key
                                           {EncryptedExtensions}
                                                  + early_data*
                                                      {Finished}
                                 <--------
    {EndOfEarlyData}
    {Finished}                   -------->

    [Application Data]           <------->  [Application Data]

.. warning::

    0-RTT 数据不具备前向安全性 (forward secrecy)，且容易受到重放攻击 (replay attack)。应仅用于幂等操作。

移除的弱密码和特性
-----------------------

TLS 1.3 移除了以下不安全的特性：

* **RSA 密钥交换**: 不提供前向安全性
* **CBC 模式密码**: 容易受到 padding oracle 攻击
* **RC4 流密码**: 已被证明不安全
* **SHA-1 哈希**: 已被碰撞攻击
* **静态 DH 密钥交换**: 不提供前向安全性
* **压缩**: 容易受到 CRIME 攻击
* **重协商 (Renegotiation)**: 安全隐患

TLS 1.3 仅保留以下密码套件：

.. code-block::

    TLS_AES_128_GCM_SHA256
    TLS_AES_256_GCM_SHA384
    TLS_CHACHA20_POLY1305_SHA256
    TLS_AES_128_CCM_SHA256
    TLS_AES_128_CCM_8_SHA256


DTLS — WebRTC 的安全基石
=======================

为什么使用 DTLS 而不是 TLS
-----------------------------------------

WebRTC 的媒体传输基于 UDP，而 TLS 设计用于可靠的 TCP 传输。DTLS (Datagram TLS) 是 TLS 的 UDP 适配版本，解决了以下问题：

* **数据包丢失**: DTLS 实现了自己的重传机制，不依赖 TCP 的可靠传输
* **数据包乱序**: DTLS 使用显式的序列号来处理乱序
* **数据包重复**: DTLS 可以检测和丢弃重复的数据包
* **无连接**: UDP 是无连接的，DTLS 在其上建立安全的"连接"

DTLS 版本对应关系：

.. list-table::
   :header-rows: 1

   * - DTLS 版本
     - 对应 TLS 版本
     - RFC
   * - DTLS 1.0
     - TLS 1.1
     - RFC 4347
   * - DTLS 1.2
     - TLS 1.2
     - RFC 6347
   * - DTLS 1.3
     - TLS 1.3
     - RFC 9147

DTLS 握手
-----------------------------------------

DTLS 握手与 TLS 类似，但增加了以下机制来适应 UDP：

**HelloVerifyRequest (Cookie 交换)**

防止 DoS 攻击，服务器在正式握手前要求客户端回显一个 cookie：

.. code-block::

    Client                                               Server

    ClientHello                  -------->
                                 <-------- HelloVerifyRequest
                                            (with cookie)
    ClientHello
    (with cookie)                -------->
                                                    ServerHello
                                                   Certificate*
                                             ServerKeyExchange*
                                            CertificateRequest*
                                 <--------      ServerHelloDone
    Certificate*
    ClientKeyExchange
    CertificateVerify*
    [ChangeCipherSpec]
    Finished                     -------->
                                             [ChangeCipherSpec]
                                 <--------             Finished

    Application Data             <------->     Application Data

**重传机制**

DTLS 使用定时器驱动的重传机制。每个握手消息都有一个 message_seq 编号，接收方可以检测丢失和乱序：

.. code-block::

    struct {
        ContentType type;
        ProtocolVersion version;
        uint16 epoch;              // DTLS 特有：密钥变更计数
        uint48 sequence_number;    // DTLS 特有：显式序列号
        uint16 length;
        opaque fragment[DTLSPlaintext.length];
    } DTLSPlaintext;

**消息分片**

DTLS 握手消息可能超过 UDP MTU，因此支持分片：

.. code-block::

    struct {
        HandshakeType msg_type;
        uint24 length;
        uint16 message_seq;        // DTLS 特有
        uint24 fragment_offset;    // DTLS 特有
        uint24 fragment_length;    // DTLS 特有
        select (HandshakeType) {
            ...
        } body;
    } Handshake;

DTLS-SRTP 密钥推导
-----------------------------------------

DTLS-SRTP (RFC 5764) 是 WebRTC 中用于保护 RTP/RTCP 媒体流的机制。DTLS 握手完成后，双方使用协商的密钥材料推导 SRTP 密钥。

密钥推导过程：

.. code-block::

    DTLS 握手完成
         |
         v
    使用 TLS exporter (RFC 5705) 导出密钥材料:
    key_material = TLS-Exporter("EXTRACTOR-dtls_srtp",
                                 client_random + server_random,
                                 2 * (SRTPSecurityParams.master_key_len +
                                      SRTPSecurityParams.master_salt_len))
         |
         v
    分割密钥材料:
    +-- client_write_SRTP_master_key
    +-- server_write_SRTP_master_key
    +-- client_write_SRTP_master_salt
    +-- server_write_SRTP_master_salt

SRTP protection profile 在 DTLS 握手中通过 ``use_srtp`` 扩展协商：

.. code-block::

    常用的 SRTP protection profiles:
    SRTP_AES128_CM_HMAC_SHA1_80  (0x0001) - 最常用
    SRTP_AES128_CM_HMAC_SHA1_32  (0x0002)
    SRTP_AEAD_AES_128_GCM        (0x0007)
    SRTP_AEAD_AES_256_GCM        (0x0008)

SDP 中的 DTLS 指纹
-----------------------------------------

WebRTC 使用 SDP 中的 ``a=fingerprint`` 属性来验证 DTLS 证书的真实性。信令通道（通常通过 HTTPS/WSS 保护）传递证书指纹，DTLS 握手时验证对端证书的指纹是否匹配。

.. code-block::

    SDP 中的相关属性:

    a=fingerprint:sha-256 4A:AD:B9:B1:3F:82:18:3B:54:02:12:DF:3E:...
    a=setup:actpass
    a=dtls-id:abc123

``a=setup`` 属性指定 DTLS 角色：

* ``actpass``: 可以作为客户端或服务器（通常在 offer 中使用）
* ``active``: 作为 DTLS 客户端（发起握手）
* ``passive``: 作为 DTLS 服务器（等待握手）


证书管理
=======================

WebRTC 中的自签名证书
-----------------------------------------

WebRTC 使用自签名证书 (self-signed certificate) 进行 DTLS 握手，不依赖传统的 CA (Certificate Authority) 体系。安全性通过信令通道传递的证书指纹来保证。

.. code-block:: javascript

    // 浏览器自动生成证书
    const pc = new RTCPeerConnection();

    // 或者手动生成证书
    const certificate = await RTCPeerConnection.generateCertificate({
      name: 'ECDSA',
      namedCurve: 'P-256'
    });

    const pc = new RTCPeerConnection({
      certificates: [certificate]
    });

证书生命周期：

1. ``RTCPeerConnection`` 创建时生成（或使用预生成的证书）
2. 证书指纹通过 SDP offer/answer 交换
3. DTLS 握手时验证对端证书指纹
4. 连接关闭后证书可以丢弃

指纹验证流程
-----------------------------------------

.. code-block::

    Alice                    信令服务器                    Bob
      |                          |                          |
      |-- SDP Offer ----------->|                          |
      |   (a=fingerprint:       |-- SDP Offer ----------->|
      |    sha-256 AA:BB:...)   |   (a=fingerprint:       |
      |                          |    sha-256 AA:BB:...)   |
      |                          |                          |
      |                          |<-- SDP Answer ----------|
      |<-- SDP Answer ----------|   (a=fingerprint:       |
      |   (a=fingerprint:       |    sha-256 CC:DD:...)   |
      |    sha-256 CC:DD:...)   |                          |
      |                          |                          |
      |                                                     |
      |<========= DTLS 握手 (直接 P2P) ==================>|
      |  Alice 验证 Bob 的证书指纹 == CC:DD:...            |
      |  Bob 验证 Alice 的证书指纹 == AA:BB:...            |
      |                                                     |


WebRTC 中的密码套件
=======================

WebRTC 实现通常支持以下密码套件：

**密钥交换算法**

* **ECDHE (Elliptic Curve Diffie-Hellman Ephemeral)**: 提供前向安全性，使用椭圆曲线（如 P-256、X25519）

**对称加密算法**

* **AES-128-GCM**: 高性能 AEAD 加密，硬件加速支持广泛
* **AES-256-GCM**: 更高安全级别的 AEAD 加密
* **ChaCha20-Poly1305**: 在没有 AES 硬件加速的平台上性能更好

**哈希算法**

* **SHA-256**: 用于密钥推导和消息认证
* **SHA-384**: 用于更高安全级别的场景

常见的 DTLS 密码套件组合：

.. code-block::

    TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
    TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
    TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
    TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256


SRTP 密钥推导详解
=======================

DTLS 握手完成后，SRTP 密钥的推导过程如下：

.. code-block::

    1. DTLS 握手协商 SRTP protection profile
       (通过 use_srtp 扩展)

    2. 使用 TLS exporter 导出密钥材料
       总长度 = 2 * (master_key_len + master_salt_len)

       对于 SRTP_AES128_CM_HMAC_SHA1_80:
       master_key_len = 16 bytes
       master_salt_len = 14 bytes
       总长度 = 2 * (16 + 14) = 60 bytes

    3. 密钥材料分割:
       bytes  0-15:  client_write_SRTP_master_key  (16 bytes)
       bytes 16-31:  server_write_SRTP_master_key  (16 bytes)
       bytes 32-45:  client_write_SRTP_master_salt (14 bytes)
       bytes 46-59:  server_write_SRTP_master_salt (14 bytes)

    4. SRTP 使用这些密钥加密/解密 RTP 和 RTCP 数据包

SRTP 数据包加密过程：

.. code-block::

    原始 RTP 数据包:
    +----+----------+
    | RTP|  Payload  |
    | Hdr|           |
    +----+----------+

    SRTP 加密后:
    +----+----------+------+----+
    | RTP| Encrypted | SRTP | Auth|
    | Hdr|  Payload  | MKI* | Tag |
    +----+----------+------+----+

    * MKI (Master Key Identifier) 是可选的


mTLS (双向 TLS)
=======================

mTLS (mutual TLS) 要求客户端和服务器都提供证书进行身份验证。在 WebRTC 中，DTLS 握手本质上就是双向认证的——双方都发送自己的证书，并验证对方的证书指纹。

mTLS 的典型应用场景：

* **WebRTC**: DTLS 握手中双方交换自签名证书
* **API 安全**: 微服务之间的安全通信
* **零信任网络**: 每个连接都需要双向认证

.. code-block::

    标准 TLS (单向认证):
    客户端验证服务器证书 ✓
    服务器不验证客户端   ✗

    mTLS (双向认证):
    客户端验证服务器证书 ✓
    服务器验证客户端证书 ✓


常见 TLS/DTLS 问题
=======================

在 WebRTC 开发中，常见的 TLS/DTLS 相关问题包括：

证书错误
-----------------------------------------

* **指纹不匹配**: SDP 中的 fingerprint 与实际 DTLS 证书不一致，通常是因为 SDP 被修改或证书被重新生成
* **证书过期**: 自签名证书通常有较短的有效期
* **不支持的签名算法**: 双方支持的签名算法不兼容

DTLS 超时
-----------------------------------------

* **握手超时**: DTLS 握手在 UDP 上进行，丢包会导致重传和延迟。默认重传定时器从 1 秒开始，指数退避
* **ICE 与 DTLS 的时序**: DTLS 握手必须在 ICE 连接建立之后进行
* **防火墙阻止**: 某些防火墙可能阻止 DTLS 流量

版本不匹配
-----------------------------------------

* **DTLS 版本协商失败**: 双方支持的 DTLS 版本不兼容
* **密码套件不匹配**: 没有共同支持的密码套件

调试技巧
-----------------------------------------

.. code-block:: bash

    # 使用 openssl 测试 DTLS
    openssl s_client -dtls1_2 -connect server:4433

    # 使用 Wireshark 过滤 DTLS 流量
    # dtls
    # dtls.handshake.type == 1  (ClientHello)
    # dtls.handshake.type == 2  (ServerHello)

    # Chrome 浏览器查看 WebRTC 内部状态
    # chrome://webrtc-internals/

SSL 握手失败的常见原因
-----------------------------------------

* 客户端使用了错误的日期或时间
* 浏览器的特定配置导致错误
* 连接被客户端侧的第三方拦截
* 客户端和服务器不支持相同的 SSL/TLS 版本
* 客户端和服务器使用不同的密码套件
* 客户端或服务器的证书无效


Alert 协议
=======================

TLS Alert 协议用于通知对方发生了错误或连接即将关闭：

.. code-block::

    enum { warning(1), fatal(2), (255) } AlertLevel;

      enum {
          close_notify(0),
          unexpected_message(10),
          bad_record_mac(20),
          decryption_failed_RESERVED(21),
          record_overflow(22),
          decompression_failure(30),
          handshake_failure(40),
          no_certificate_RESERVED(41),
          bad_certificate(42),
          unsupported_certificate(43),
          certificate_revoked(44),
          certificate_expired(45),
          certificate_unknown(46),
          illegal_parameter(47),
          unknown_ca(48),
          access_denied(49),
          decode_error(50),
          decrypt_error(51),
          export_restriction_RESERVED(60),
          protocol_version(70),
          insufficient_security(71),
          internal_error(80),
          user_canceled(90),
          no_renegotiation(100),
          unsupported_extension(110),
          (255)
      } AlertDescription;

      struct {
          AlertLevel level;
          AlertDescription description;
      } Alert;

在 WebRTC 中，常见的 DTLS alert 包括：

* ``close_notify``: 正常关闭连接
* ``handshake_failure``: 握手失败，通常是密码套件不匹配
* ``bad_certificate``: 证书验证失败
* ``certificate_expired``: 证书已过期


参考资料
=========================

* `RFC 5246 - The Transport Layer Security (TLS) Protocol Version 1.2 <https://datatracker.ietf.org/doc/html/rfc5246>`_
* `RFC 8446 - The Transport Layer Security (TLS) Protocol Version 1.3 <https://datatracker.ietf.org/doc/html/rfc8446>`_
* `RFC 6347 - Datagram Transport Layer Security Version 1.2 <https://datatracker.ietf.org/doc/html/rfc6347>`_
* `RFC 9147 - The Datagram Transport Layer Security (DTLS) Protocol Version 1.3 <https://datatracker.ietf.org/doc/html/rfc9147>`_
* `RFC 5764 - Datagram Transport Layer Security (DTLS) Extension to Establish Keys for the Secure Real-time Transport Protocol (SRTP) <https://datatracker.ietf.org/doc/html/rfc5764>`_
* `RFC 5077 - Transport Layer Security (TLS) Session Resumption without Server-Side State <https://datatracker.ietf.org/doc/html/rfc5077>`_
* `RFC 5705 - Keying Material Exporters for Transport Layer Security (TLS) <https://datatracker.ietf.org/doc/html/rfc5705>`_
* `High Performance Browser Networking - TLS <https://www.oreilly.com/library/view/high-performance-browser/9781449344757/ch04.html>`_
