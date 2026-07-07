##############################
RTP Keepalive
##############################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** RTP Keepalive
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
==========================

在实时通信中，RTP/RTCP 流通常需要穿越 NAT (Network Address Translation) 设备。NAT 设备会为每个通过它的 UDP 流维护一个映射表项 (binding)，将内部地址和端口映射到外部地址和端口。然而，这些映射表项并非永久存在——如果在一段时间内没有数据包通过该映射，NAT 设备会将其删除，导致后续的数据包无法正确路由，从而造成通信中断。

**RTP Keepalive** 机制的核心目的就是：在媒体流暂时静默（例如音频静音、视频暂停）时，定期发送少量数据包以维持 NAT 映射的活跃状态，防止 NAT binding 超时。

RFC 6263 "Application Mechanism for Keeping Alive the NAT Mappings Associated with RTP / RTP Control Protocol (RTCP) Flows" 专门定义了用于维持 RTP/RTCP 相关 NAT 映射的应用层 keepalive 机制。

为什么需要 Keepalive
--------------------------

在以下场景中，RTP keepalive 尤为重要：

1. **音频静音期 (Silence Suppression)**: 当使用 VAD (Voice Activity Detection) 进行静音抑制时，发送方在检测到静音后会停止发送 RTP 包。如果静音持续时间超过 NAT binding 超时时间，NAT 映射将被删除。

2. **视频暂停 (Video Pause)**: 当用户暂停视频发送（例如关闭摄像头）时，RTP 流停止，NAT 映射面临超时风险。

3. **Hold 状态**: 在 VoIP 通话中，当一方将通话置于保持 (hold) 状态时，媒体流停止。

4. **单向媒体流**: 在某些场景下（如单向直播），接收方不发送 RTP 数据，仅依赖 RTCP 来维持 NAT 映射，但 RTCP 的发送间隔可能过长。

5. **ICE 连接维护**: 即使 ICE 连接已建立，如果没有持续的数据流，NAT 映射仍可能超时。

.. code-block::

    典型的 NAT binding 超时场景:

    时间线:
    t=0s     发送方发送最后一个 RTP 包
    t=0s     发送方进入静音状态 (VAD 检测到静音)
    ...      (无 RTP 包发送)
    t=30s    NAT 设备开始考虑回收该 binding
    t=60s    NAT binding 被删除 ✗
    t=65s    发送方恢复发送 RTP 包
             → 包被 NAT 丢弃，接收方收不到
             → 通信中断！

    使用 Keepalive 后:
    t=0s     发送方发送最后一个 RTP 包
    t=0s     发送方进入静音状态
    t=15s    发送 keepalive 包 → NAT binding 刷新 ✓
    t=30s    发送 keepalive 包 → NAT binding 刷新 ✓
    t=45s    发送 keepalive 包 → NAT binding 刷新 ✓
    t=65s    发送方恢复发送 RTP 包
             → NAT binding 仍然有效，包正常转发 ✓


NAT 映射超时问题
==========================

UDP NAT Binding 超时
--------------------------

NAT 设备对 UDP 流的 binding 超时时间因设备类型和配置而异。RFC 4787 "Network Address Translation (NAT) Behavioral Requirements for Unicast UDP" 对此进行了规范。

.. list-table:: 常见 NAT 设备的 UDP Binding 超时时间
   :header-rows: 1
   :widths: 30 20 50

   * - NAT 设备类型
     - 典型超时时间
     - 说明
   * - 家用路由器 (Consumer Router)
     - 30s - 120s
     - 不同品牌差异较大，部分低端设备仅 30 秒
   * - 企业级防火墙 (Enterprise Firewall)
     - 60s - 300s
     - 通常可配置，默认值较长
   * - 运营商级 NAT (Carrier-Grade NAT, CGN)
     - 120s - 300s
     - RFC 4787 推荐至少 120 秒
   * - 移动网络 NAT (Mobile Network)
     - 20s - 60s
     - 移动运营商为节省资源，超时时间通常较短
   * - 云服务商 NAT (Cloud NAT)
     - 30s - 300s
     - AWS、GCP、Azure 各有不同默认值
   * - 对称 NAT (Symmetric NAT)
     - 30s - 60s
     - 最严格的 NAT 类型，超时通常较短

.. note::

    RFC 4787 建议 NAT 设备的 UDP binding 超时时间不应少于 **2 分钟 (120 秒)**，但实际上许多设备并未遵循此建议。因此，keepalive 间隔通常设置为远小于 120 秒的值。

TCP vs UDP NAT Binding 差异
--------------------------

TCP 和 UDP 在 NAT binding 方面有显著差异：

.. list-table:: TCP vs UDP NAT Binding 对比
   :header-rows: 1
   :widths: 20 40 40

   * - 特性
     - TCP
     - UDP
   * - 连接状态
     - 有状态 (stateful)，NAT 可跟踪 SYN/FIN
     - 无状态 (stateless)，NAT 仅基于超时
   * - 典型超时
     - 数小时 (通常 2h+)
     - 30s - 300s
   * - Keepalive 机制
     - TCP keepalive (内置)
     - 需要应用层实现
   * - Binding 创建
     - SYN 包触发
     - 首个 UDP 包触发
   * - Binding 删除
     - FIN/RST 或超时
     - 仅超时
   * - 对 RTP 的影响
     - RTP over TCP 较少受 NAT 超时影响
     - RTP over UDP 必须考虑 keepalive

由于 WebRTC 中 RTP 主要通过 UDP 传输（即使使用 DTLS-SRTP，底层仍是 UDP），NAT binding 超时是一个必须解决的问题。


Keepalive 机制详解 (RFC 6263)
=======================================

RFC 6263 定义了多种维持 NAT 映射的方法。以下逐一介绍各种方法及其优缺点。

方法 1: 发送空 RTP 包 (Empty RTP Packet)
--------------------------------------------

这是 RFC 6263 推荐的主要方法。发送一个没有负载（或负载为零长度）的 RTP 包，使用与当前媒体流相同的 SSRC 和递增的序列号。

.. code-block::

    空 RTP 包的结构:

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |V=2|P|  X=0  |M|     PT        |       sequence number         |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           timestamp                           |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                              SSRC                             |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    (无负载数据)

    总大小: 12 字节 (RTP 头部) + 0 字节 (负载) = 12 字节

关于 Payload Type 的选择：

* **使用 Comfort Noise (CN, PT=13)**: 对于音频流，可以使用 comfort noise payload type。接收方会将其视为舒适噪声，不会产生异常行为。
* **使用当前媒体的 PT**: 使用与正在进行的媒体流相同的 payload type，但负载为空或最小。
* **使用 PT=0 (PCMU)**: 某些实现使用 PT=0 作为 keepalive 包的 payload type。

.. note::

    发送空 RTP 包时，序列号应递增，但时间戳不应改变（或使用与静音期一致的时间戳），以避免接收方的 jitter buffer 产生混乱。

方法 2: 发送 RTCP 包 (SR/RR)
-----------------------------------------

利用 RTCP 报文（Sender Report 或 Receiver Report）作为 keepalive 机制。由于 RTCP 本身就需要定期发送，这种方法不需要额外的协议支持。

.. code-block::

    RTCP 作为 Keepalive 的工作方式:

    发送方                                    接收方
      |                                         |
      |--- RTP (媒体数据) --------------------->|
      |--- RTP (媒体数据) --------------------->|
      |                                         |
      | (进入静音期，停止发送 RTP)               |
      |                                         |
      |--- RTCP SR --------------------------->| ← 维持 NAT binding
      |                                         |
      |<-- RTCP RR -----------------------------|  ← 维持反向 NAT binding
      |                                         |
      |--- RTCP SR --------------------------->| ← 再次维持
      |                                         |

**局限性**: RTCP 的发送间隔由 RTCP bandwidth 规则控制（RFC 3550），最小间隔通常为 5 秒，但在参与者较多的会话中，间隔可能远大于 NAT 超时时间。此外，如果 RTP 和 RTCP 使用不同的端口（非 RTCP-mux），RTCP 只能维持 RTCP 端口的 NAT binding，无法维持 RTP 端口的 binding。

方法 3: 发送 STUN Binding Indication
-----------------------------------------

在 ICE (Interactive Connectivity Establishment) 框架下，使用 STUN Binding Indication 消息作为 keepalive。这是 WebRTC 中最常用的 keepalive 方法。

.. code-block::

    STUN Binding Indication 格式:

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |0 0|     STUN Message Type     |         Message Length        |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                         Magic Cookie                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                                                               |
    |                     Transaction ID (96 bits)                  |
    |                                                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

    STUN Message Type = 0x0011 (Binding Indication)
    总大小: 20 字节 (STUN 头部)

    特点:
    - Binding Indication 是一个 "fire-and-forget" 消息
    - 不需要响应 (与 Binding Request 不同)
    - 开销小，仅 20 字节
    - 不影响 RTP/RTCP 的序列号和时间戳

方法 4: 发送 STUN Binding Request
-----------------------------------------

与 Binding Indication 类似，但使用 STUN Binding Request，对端需要回复 Binding Response。这种方法不仅能维持 NAT binding，还能检测连接的活跃性 (liveness check)。

.. code-block::

    STUN Binding Request/Response 流程:

    端点 A                                    端点 B
      |                                         |
      |--- STUN Binding Request --------------->|
      |                                         |
      |<-- STUN Binding Response ---------------|
      |                                         |

    优点: 可以确认对端仍然可达
    缺点: 需要对端响应，开销略大

各方法优缺点对比
--------------------------

.. list-table:: Keepalive 方法对比
   :header-rows: 1
   :widths: 18 15 15 15 15 22

   * - 方法
     - 包大小
     - 需要响应
     - 维持 RTP 端口
     - 维持 RTCP 端口
     - 适用场景
   * - 空 RTP 包
     - 12 字节
     - 否
     - ✓
     - ✗
     - 音频静音期
   * - RTCP SR/RR
     - ~100 字节
     - 否 (SR→RR)
     - ✗ (非 mux)
     - ✓
     - RTCP-mux 场景
   * - STUN Binding Indication
     - 20 字节
     - 否
     - ✓
     - ✓ (mux)
     - WebRTC (推荐)
   * - STUN Binding Request
     - 20+ 字节
     - 是
     - ✓
     - ✓ (mux)
     - 需要 liveness check


Keepalive 间隔
==========================

推荐间隔
--------------------------

RFC 6263 推荐的 keepalive 间隔为 **15 秒**。这个值的选择基于以下考虑：

.. code-block::

    Keepalive 间隔的选择依据:

    1. NAT binding 最短超时时间: ~30 秒 (部分设备)
    2. 安全余量: 间隔应远小于最短超时时间
    3. 带宽开销: 间隔不宜过短，避免浪费带宽
    4. 移动网络: 某些移动网络 NAT 超时仅 20 秒

    推荐值: 15 秒
    - 远小于大多数 NAT 的 30 秒最短超时
    - 即使一个 keepalive 包丢失，下一个 (30 秒后) 仍在超时前到达
    - 带宽开销极小: 20 字节 / 15 秒 ≈ 10.7 bps

与 NAT 超时的关系
--------------------------

.. code-block::

    Keepalive 间隔与 NAT 超时的关系:

    NAT 超时 (T_nat)    推荐 Keepalive 间隔 (T_ka)
    ─────────────────    ──────────────────────────
    20s (移动网络)       ≤ 10s (更激进)
    30s (家用路由器)     ≤ 15s (标准)
    60s (企业防火墙)     ≤ 15s (标准)
    120s (CGN)           ≤ 15s (标准，无需更长)
    300s (宽松配置)      ≤ 15s (标准，无需更长)

    一般原则:
    T_ka ≤ T_nat / 2

    考虑丢包:
    如果 keepalive 包可能丢失，应确保:
    2 * T_ka < T_nat
    即连续丢失一个 keepalive 包后，下一个仍能在超时前到达

自适应间隔
--------------------------

某些高级实现会根据网络环境动态调整 keepalive 间隔：

.. code-block::

    自适应 Keepalive 间隔算法:

    初始间隔: T_ka = 15s

    1. 检测 NAT 类型:
       if NAT_type == "symmetric":
           T_ka = min(T_ka, 10s)  # 对称 NAT 通常超时更短

    2. 检测网络类型:
       if network_type == "mobile":
           T_ka = min(T_ka, 10s)  # 移动网络超时更短

    3. 检测连接中断:
       if connection_lost_after_silence:
           T_ka = T_ka * 0.7  # 缩短间隔
           T_ka = max(T_ka, 5s)  # 但不低于 5 秒


WebRTC 中的实现
==========================

ICE Keepalive (STUN Binding Indication)
--------------------------------------------

RFC 8445 (ICE) 规定，ICE agent 应该在选定的候选对 (selected candidate pair) 上发送 keepalive 以维持 NAT binding。WebRTC 实现中，这通常通过 STUN Binding Indication 完成。

.. code-block::

    ICE Keepalive 的工作流程:

    1. ICE 连接建立完成，选定候选对
    2. 启动 keepalive 定时器 (默认 15 秒)
    3. 每次定时器触发:
       a. 检查是否有最近的数据包发送
       b. 如果在过去 T_ka 秒内没有发送任何包:
          → 发送 STUN Binding Indication
       c. 如果有数据包发送:
          → 跳过本次 keepalive (数据包已刷新 NAT binding)
    4. 重置定时器

    伪代码:
    class IceKeepalive:
        def __init__(self, interval=15.0):
            self.interval = interval
            self.last_sent_time = time.time()

        def on_packet_sent(self):
            """任何包发送时调用"""
            self.last_sent_time = time.time()

        def on_timer(self):
            """定时器触发时调用"""
            elapsed = time.time() - self.last_sent_time
            if elapsed >= self.interval:
                self.send_stun_binding_indication()
                self.last_sent_time = time.time()

RFC 8445 Section 11 明确指出：

    "An agent MUST keep the candidate pair alive. The agent MUST use
    STUN Binding Indications for keepalives as described in Section 11."

RTCP 作为隐式 Keepalive
--------------------------

在 RTCP-mux (RFC 5761) 场景下，RTP 和 RTCP 共享同一端口。此时，定期发送的 RTCP 报文（SR/RR）可以作为隐式的 keepalive，帮助维持 NAT binding。

.. code-block::

    RTCP-mux 下的隐式 Keepalive:

    端口 5004 (RTP + RTCP 复用)
    ─────────────────────────────
    t=0.0s   RTP 包 (媒体数据)
    t=0.02s  RTP 包 (媒体数据)
    ...
    t=5.0s   最后一个 RTP 包 (进入静音)
    t=10.0s  RTCP SR/RR → 刷新 NAT binding ✓
    t=15.0s  STUN Binding Indication → 刷新 NAT binding ✓
    t=20.0s  RTCP SR/RR → 刷新 NAT binding ✓
    t=25.0s  STUN Binding Indication → 刷新 NAT binding ✓
    ...

    在 RTCP-mux 模式下，RTCP 和 STUN keepalive 共同维持 NAT binding，
    提供了双重保障。

然而，仅依赖 RTCP 作为 keepalive 是不够的，原因包括：

* RTCP 发送间隔可能大于 NAT 超时时间（特别是在多参与者会话中）
* RTCP 发送时间具有随机性，可能出现较长的间隔
* 在非 RTCP-mux 场景下，RTCP 无法维持 RTP 端口的 NAT binding

媒体静默期的处理
--------------------------

WebRTC 中处理媒体静默期的策略：

**音频静音 (Audio Mute / Silence Suppression)**:

.. code-block::

    音频静音期的 Keepalive 策略:

    方案 1: 发送 Comfort Noise (CN) 包
    - 使用 PT=13 (Comfort Noise)
    - 包含舒适噪声参数
    - 接收方播放背景噪声，用户体验更好
    - 同时维持 NAT binding

    方案 2: 发送空 RTP 包
    - 使用当前音频 PT，负载为空
    - 接收方忽略空负载
    - 仅用于维持 NAT binding

    方案 3: 依赖 STUN Keepalive
    - 不发送任何 RTP 包
    - 由 ICE 层的 STUN Binding Indication 维持 NAT binding
    - WebRTC 中最常用的方案

**视频暂停 (Video Pause)**:

.. code-block::

    视频暂停期的 Keepalive 策略:

    1. 用户关闭摄像头:
       - 停止发送视频 RTP 包
       - ICE keepalive (STUN) 维持 NAT binding
       - 可选: 发送 RTCP BYE 通知接收方

    2. 带宽不足导致视频暂停:
       - 拥塞控制算法决定暂停视频
       - 仅发送音频 RTP 包
       - 音频包同时维持视频端口的 NAT binding (BUNDLE 模式下)

    3. 视频 hold:
       - 发送方发送 SDP re-INVITE 将视频设为 inactive
       - ICE keepalive 维持 NAT binding
       - 恢复时重新协商 SDP


DTLS Keepalive
==========================

DTLS Heartbeat Extension (RFC 6520)
--------------------------------------------

WebRTC 使用 DTLS-SRTP 进行密钥协商和媒体加密。DTLS 本身也提供了 keepalive 机制——Heartbeat Extension (RFC 6520)。

.. code-block::

    DTLS Heartbeat 消息格式:

    struct {
        HeartbeatMessageType type;  // 1 = heartbeat_request
                                    // 2 = heartbeat_response
        uint16 payload_length;
        opaque payload[HeartbeatMessage.payload_length];
        opaque padding[padding_length];
    } HeartbeatMessage;

    工作流程:
    端点 A                                    端点 B
      |                                         |
      |--- Heartbeat Request ------------------>|
      |                                         |
      |<-- Heartbeat Response ------------------|
      |                                         |

    特点:
    - 双向确认，可检测连接活跃性
    - 在 DTLS 层工作，独立于 RTP/RTCP
    - 可用于 DTLS 连接的 keepalive

.. warning::

    DTLS Heartbeat 曾因 Heartbleed 漏洞 (CVE-2014-0160) 而广为人知。该漏洞允许攻击者通过构造恶意的 heartbeat 请求读取服务器内存。现代 DTLS 实现已修复此漏洞，但部分实现出于安全考虑默认禁用了 heartbeat 扩展。

在 WebRTC 中，DTLS heartbeat 通常不作为主要的 keepalive 机制，因为 ICE 层的 STUN keepalive 已经足够。但在某些特殊场景下（如 DTLS 连接需要独立维护时），heartbeat 仍然有用。

DTLS 与 ICE Keepalive 的关系
--------------------------

.. code-block::

    WebRTC 协议栈中的 Keepalive 层次:

    ┌─────────────────────────────────┐
    │  应用层 (Application)            │
    ├─────────────────────────────────┤
    │  SRTP/SRTCP (加密媒体)           │  ← RTP keepalive (空包)
    ├─────────────────────────────────┤
    │  DTLS (密钥协商)                 │  ← DTLS heartbeat
    ├─────────────────────────────────┤
    │  ICE (连接管理)                  │  ← STUN Binding Indication ★
    ├─────────────────────────────────┤
    │  UDP (传输层)                    │
    └─────────────────────────────────┘

    在 WebRTC 中:
    - ICE keepalive (STUN) 是主要的 keepalive 机制 ★
    - RTCP 提供隐式 keepalive
    - DTLS heartbeat 通常不使用
    - 空 RTP 包在某些实现中作为补充


多路复用场景
==========================

BUNDLE 下的 Keepalive 策略
--------------------------

WebRTC 中广泛使用 BUNDLE (RFC 8843) 将多个媒体流复用到同一传输通道上。在 BUNDLE 模式下，所有音频和视频 RTP/RTCP 流共享同一个 UDP 端口。

.. code-block::

    BUNDLE 模式下的端口复用:

    非 BUNDLE 模式:
    ┌──────────────┐     端口 5000: 音频 RTP
    │              │     端口 5001: 音频 RTCP
    │   WebRTC     │     端口 5002: 视频 RTP
    │   端点       │     端口 5003: 视频 RTCP
    │              │     → 需要维持 4 个 NAT binding
    └──────────────┘

    BUNDLE + RTCP-mux 模式:
    ┌──────────────┐     端口 5000: 音频 RTP + RTCP + 视频 RTP + RTCP
    │   WebRTC     │     → 只需维持 1 个 NAT binding ✓
    │   端点       │     → 一个 keepalive 包即可维持所有流
    └──────────────┘

BUNDLE 模式下的 keepalive 策略：

1. **单一 keepalive 即可**: 由于所有流共享同一端口，一个 STUN Binding Indication 即可维持所有流的 NAT binding。

2. **任何流的数据包都能刷新 binding**: 即使视频暂停，音频 RTP 包仍然在发送，自然维持了 NAT binding。

3. **简化管理**: 不需要为每个媒体流单独管理 keepalive 定时器。

.. code-block::

    BUNDLE 模式下的 Keepalive 逻辑:

    class BundleKeepalive:
        def __init__(self, interval=15.0):
            self.interval = interval
            self.last_activity = time.time()

        def on_any_packet_sent(self):
            """任何媒体流的包发送时调用"""
            self.last_activity = time.time()

        def check_keepalive(self):
            """定期检查是否需要发送 keepalive"""
            if time.time() - self.last_activity >= self.interval:
                # 所有流都静默，发送 keepalive
                self.send_stun_binding_indication()
                self.last_activity = time.time()

    # 在 BUNDLE 模式下:
    # - 音频 RTP 包会刷新 last_activity
    # - 视频 RTP 包会刷新 last_activity
    # - RTCP 包会刷新 last_activity
    # - 只有当所有流都静默时才需要显式 keepalive

非 BUNDLE 模式的注意事项
--------------------------

在非 BUNDLE 模式下（虽然在现代 WebRTC 中较少见），每个媒体流使用独立的端口，需要分别维持各自的 NAT binding：

.. code-block::

    非 BUNDLE 模式下的 Keepalive:

    音频端口 (5000):
    - 音频 RTP 包持续发送 → 自然维持 binding
    - 静音期: 需要 keepalive

    视频端口 (5002):
    - 视频 RTP 包持续发送 → 自然维持 binding
    - 视频暂停: 需要 keepalive

    RTCP 端口 (5001, 5003):
    - RTCP 定期发送 → 通常足够维持 binding
    - 但间隔可能过长，需要额外 keepalive

    → 需要为每个端口独立管理 keepalive 定时器


常见问题
==========================

对称 NAT 下的 Keepalive 失效
-----------------------------------------

对称 NAT (Symmetric NAT) 为每个不同的目标地址创建不同的映射。这意味着：

.. code-block::

    对称 NAT 的问题:

    内部端点 A (192.168.1.100:5000)
        |
        | → 发送到 STUN 服务器 (1.2.3.4:3478)
        |   NAT 映射: 192.168.1.100:5000 → 203.0.113.1:10000
        |
        | → 发送到 端点 B (5.6.7.8:6000)
        |   NAT 映射: 192.168.1.100:5000 → 203.0.113.1:10001 (不同!)
        |
        | → 发送到 TURN 服务器 (9.10.11.12:3478)
        |   NAT 映射: 192.168.1.100:5000 → 203.0.113.1:10002 (又不同!)

    问题:
    - Keepalive 必须发送到正确的目标地址
    - 发送到 STUN 服务器的 keepalive 无法维持到端点 B 的映射
    - 必须在每个活跃的候选对上分别发送 keepalive

在对称 NAT 环境下，WebRTC 通常需要使用 TURN relay 来建立连接，keepalive 需要在 TURN allocation 上进行。

移动网络 NAT 超时更短
--------------------------

移动网络（3G/4G/5G）的 NAT 设备通常配置了更短的超时时间，以节省有限的公网 IP 地址资源：

.. code-block::

    移动网络的特殊挑战:

    1. NAT 超时更短:
       - 某些运营商的 NAT 超时仅 20 秒
       - 需要更频繁的 keepalive (如 10 秒间隔)

    2. 网络切换:
       - Wi-Fi → 4G 切换时，NAT binding 完全改变
       - 需要 ICE restart 重新建立连接
       - Keepalive 无法解决网络切换问题

    3. 省电模式:
       - 移动设备进入省电模式时，可能暂停网络活动
       - Keepalive 定时器可能不准确
       - 需要使用平台特定的后台任务 API

    4. 运营商级 NAT (CGN):
       - 移动运营商通常使用 CGN
       - 双重 NAT: 设备 NAT + 运营商 NAT
       - 超时时间取决于两层 NAT 中较短的那个

VPN/防火墙对 Keepalive 的影响
-----------------------------------------

企业 VPN 和防火墙可能对 keepalive 机制产生影响：

.. code-block::

    VPN/防火墙的影响:

    1. 深度包检测 (DPI):
       - 某些防火墙会检测 STUN 包并阻止
       - 解决方案: 使用 TURN over TLS (端口 443)

    2. UDP 阻断:
       - 某些企业网络完全阻断 UDP
       - Keepalive 包 (STUN/RTP) 无法通过
       - 解决方案: 使用 TURN over TCP/TLS

    3. VPN 隧道:
       - VPN 隧道内的 NAT binding 由 VPN 网关管理
       - VPN 自身的 keepalive 可能与 RTP keepalive 冲突
       - 某些 VPN 会修改 UDP 包的源端口

    4. 状态防火墙:
       - 状态防火墙跟踪 UDP "连接" 状态
       - 超时时间可能与 NAT 不同
       - 需要同时满足 NAT 和防火墙的超时要求


Wireshark 抓包分析
==========================

如何识别 Keepalive 包
--------------------------

使用 Wireshark 可以方便地识别和分析各种 keepalive 包：

.. code-block::

    Wireshark 过滤器:

    1. 过滤 STUN Binding Indication:
       stun.type == 0x0011

    2. 过滤所有 STUN 包:
       stun

    3. 过滤空 RTP 包 (长度为 12 字节的 RTP):
       rtp && udp.length == 20
       (UDP 头部 8 字节 + RTP 头部 12 字节 = 20 字节)

    4. 过滤 RTCP SR/RR:
       rtcp.pt == 200 || rtcp.pt == 201

    5. 过滤 DTLS Heartbeat:
       dtls.heartbeat_message

    6. 综合过滤 (所有可能的 keepalive):
       stun.type == 0x0011 ||
       (rtp && udp.length == 20) ||
       dtls.heartbeat_message

分析 Keepalive 间隔
--------------------------

.. code-block::

    在 Wireshark 中分析 Keepalive 间隔:

    1. 应用过滤器: stun.type == 0x0011
    2. 查看 "Time" 列，观察相邻 keepalive 包的时间差
    3. 使用 Statistics → I/O Graphs 绘制 keepalive 频率图

    典型的 Wireshark 输出:

    No.  Time      Source          Dest            Protocol  Info
    1    0.000     192.168.1.100   203.0.113.50    STUN      Binding Indication
    2    15.003    192.168.1.100   203.0.113.50    STUN      Binding Indication
    3    30.001    192.168.1.100   203.0.113.50    STUN      Binding Indication
    4    45.005    192.168.1.100   203.0.113.50    STUN      Binding Indication

    间隔: ~15 秒 (符合 RFC 6263 推荐值)

    如果观察到间隔不规律或过长，可能存在以下问题:
    - Keepalive 定时器实现有误
    - 系统负载过高导致定时器延迟
    - 其他数据包 (RTP/RTCP) 替代了 keepalive

识别 NAT Binding 超时
--------------------------

.. code-block::

    识别 NAT Binding 超时的迹象:

    1. 单向媒体中断:
       - 一方能发送但对方收不到
       - 抓包显示包已发出但对端无响应

    2. STUN Binding Request 超时:
       - 连续多个 STUN request 无 response
       - Wireshark 过滤: stun.type == 0x0001 && !stun.type == 0x0101

    3. RTCP RR 报告突然丢包率 100%:
       - 接收方报告完全丢包
       - 可能是 NAT binding 已失效

    4. ICE 连接状态变化:
       - ICE 状态从 "connected" 变为 "disconnected"
       - 触发 ICE restart


libwebrtc 中的实现
==========================

在 Google 的 libwebrtc (WebRTC Native) 实现中，keepalive 主要通过 ICE 层的 STUN Binding Indication 实现。

.. code-block:: cpp

    // libwebrtc 中 keepalive 相关的关键代码路径:

    // 1. P2PTransportChannel 中的 keepalive 定时器
    // 文件: p2p/base/p2p_transport_channel.cc

    // 默认 keepalive 间隔 (毫秒)
    static const int STUN_KEEPALIVE_INTERVAL = 10000;  // 10 秒 (比 RFC 推荐更短)

    // 稳定连接后的 keepalive 间隔
    static const int STABLE_KEEPALIVE_INTERVAL = 25000;  // 25 秒

    void P2PTransportChannel::OnCheckAndPing() {
        // 检查是否需要发送 keepalive
        auto now = rtc::TimeMillis();
        auto selected = selected_connection_;

        if (selected) {
            // 计算距离上次发送的时间
            auto last_sent = selected->last_ping_sent();
            auto interval = GetKeepaliveInterval();

            if (now - last_sent >= interval) {
                // 发送 STUN Binding Request (也用作 keepalive)
                selected->Ping(now);
            }
        }
    }

    // 2. Connection 类中的 Ping 实现
    // 文件: p2p/base/connection.cc

    void Connection::Ping(int64_t now) {
        // 构造 STUN Binding Request
        auto request = new StunBindingRequest(this);
        // 发送请求
        SendStunBindingRequest(request);
        last_ping_sent_ = now;
    }

.. note::

    libwebrtc 实际使用 STUN Binding Request（而非 Indication）作为 keepalive，这样可以同时检测连接的活跃性。如果连续多个 Binding Request 没有收到响应，ICE 会认为连接已断开。


最佳实践
==========================

.. code-block::

    RTP Keepalive 最佳实践总结:

    1. 使用 BUNDLE + RTCP-mux:
       - 减少需要维持的 NAT binding 数量
       - 简化 keepalive 管理

    2. 使用 STUN Binding Indication 作为主要 keepalive:
       - 开销小 (20 字节)
       - 不影响 RTP/RTCP 状态
       - WebRTC 标准推荐

    3. 设置合理的 keepalive 间隔:
       - 默认 15 秒
       - 移动网络可缩短到 10 秒
       - 不要超过 25 秒

    4. 智能 keepalive:
       - 如果有数据包发送，跳过 keepalive
       - 避免不必要的带宽浪费

    5. 监控 NAT binding 状态:
       - 使用 STUN Binding Request 检测连接活跃性
       - 检测到 binding 失效时触发 ICE restart

    6. 考虑移动网络:
       - 更短的 keepalive 间隔
       - 处理网络切换 (Wi-Fi ↔ 移动网络)
       - 使用平台后台任务 API 维持 keepalive

    7. 准备 fallback:
       - 如果 UDP keepalive 失败，考虑 TURN over TCP/TLS
       - 实现 ICE restart 机制


参考文献
==========================

* `RFC 6263 - Application Mechanism for Keeping Alive the NAT Mappings Associated with RTP / RTCP Flows <https://datatracker.ietf.org/doc/html/rfc6263>`_
* `RFC 8445 - Interactive Connectivity Establishment (ICE) <https://datatracker.ietf.org/doc/html/rfc8445>`_
* `RFC 6520 - Transport Layer Security (TLS) and Datagram Transport Layer Security (DTLS) Heartbeat Extension <https://datatracker.ietf.org/doc/html/rfc6520>`_
* `RFC 4787 - Network Address Translation (NAT) Behavioral Requirements for Unicast UDP <https://datatracker.ietf.org/doc/html/rfc4787>`_
* `RFC 5761 - Multiplexing RTP Data and Control Packets on a Single Port <https://datatracker.ietf.org/doc/html/rfc5761>`_
* `RFC 8843 - Negotiating Media Multiplexing Using the Session Description Protocol (SDP) <https://datatracker.ietf.org/doc/html/rfc8843>`_
* `RFC 5389 - Session Traversal Utilities for NAT (STUN) <https://datatracker.ietf.org/doc/html/rfc5389>`_
* `RFC 5766 - Traversal Using Relays around NAT (TURN) <https://datatracker.ietf.org/doc/html/rfc5766>`_
* `RFC 3550 - RTP: A Transport Protocol for Real-Time Applications <https://datatracker.ietf.org/doc/html/rfc3550>`_
