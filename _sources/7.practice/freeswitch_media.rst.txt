.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============================================
FreeSWITCH 媒体处理
============================================

.. list-table::
   :widths: 30 70

   * - **文档创建日期**
     - 2024-03-18
   * - **作者**
     - Walter Fan
   * - **关键词**
     - FreeSWITCH, Media, Codec, RTP, Transcoding, WebRTC
   * - **状态**
     - v1.0
   * - **摘要**
     - 本章详细介绍 FreeSWITCH 中的媒体处理机制，包括音视频编解码器支持、
       编解码器协商与转码、媒体代理与绕行模式、录音回放、DTMF 处理、
       音频处理以及 RTP 配置与优化等核心内容。

.. contents::
   :local:

概述
============================================

FreeSWITCH 是一个开源的软交换平台，其核心能力之一就是强大的媒体处理功能。
在 WebRTC 通信场景中，FreeSWITCH 常常扮演媒体服务器（Media Server）或
会话边界控制器（SBC）的角色，负责处理音视频流的接收、转发、转码和录制等任务。

FreeSWITCH 的媒体处理架构主要包含以下几个层次：

- **信令层（Signaling Layer）**: 通过 mod_sofia 模块处理 SIP 信令，完成会话的建立、
  修改和拆除，其中 SDP（Session Description Protocol）协商是媒体参数确定的关键环节。
- **媒体层（Media Layer）**: 负责 RTP/RTCP 包的收发、编解码器的编解码处理、
  以及各种媒体操作（如混音、录音、播放等）。
- **应用层（Application Layer）**: 提供丰富的拨号计划（Dialplan）应用，
  如 bridge、record、playback、conference 等，供用户灵活编排媒体处理流程。

FreeSWITCH 的媒体引擎（Media Engine）采用模块化设计，通过加载不同的编解码器模块
（如 mod_opus、mod_av 等）来扩展其编解码能力。其内部使用 L16（线性 16 位 PCM）
作为核心音频格式，所有编解码器的输入输出都会经过 L16 的转换，这使得不同编解码器
之间的转码变得透明和统一。

.. code-block:: text

   +-------------------+
   |   Application     |  (bridge, record, playback, conference ...)
   +-------------------+
   |   Media Engine    |  (codec encode/decode, mixing, processing)
   +-------------------+
   |   RTP/RTCP Stack  |  (packet send/recv, jitter buffer, DTMF)
   +-------------------+
   |   Network I/O     |  (UDP sockets, ICE, DTLS-SRTP for WebRTC)
   +-------------------+


支持的音频编解码器
============================================

FreeSWITCH 支持丰富的音频编解码器，涵盖了从传统电话网络到现代 WebRTC 通信的各种需求。
以下是主要支持的音频编解码器及其特性：

.. list-table:: FreeSWITCH 支持的音频编解码器
   :header-rows: 1
   :widths: 15 15 15 15 15 25

   * - 编解码器
     - 采样率 (Hz)
     - 比特率 (kbps)
     - 帧长 (ms)
     - 音质评级
     - 说明
   * - G.711 PCMU
     - 8000
     - 64
     - 20
     - 中等
     - ITU-T 标准，μ-law 编码，北美和日本广泛使用
   * - G.711 PCMA
     - 8000
     - 64
     - 20
     - 中等
     - ITU-T 标准，A-law 编码，欧洲和国际广泛使用
   * - G.722
     - 16000
     - 64
     - 20
     - 较高
     - 宽带编解码器，提供 50-7000Hz 频率响应
   * - Opus
     - 8000-48000
     - 6-510
     - 2.5-60
     - 极高
     - WebRTC 必选编解码器，支持语音和音乐，自适应比特率
   * - iLBC
     - 8000
     - 13.3/15.2
     - 30/20
     - 中等
     - 对丢包有良好的容错性，适合网络不稳定场景
   * - GSM
     - 8000
     - 13
     - 20
     - 较低
     - 移动通信标准编解码器，压缩率高
   * - Speex
     - 8000/16000/32000
     - 2.15-44.2
     - 20
     - 中高
     - 开源编解码器，已被 Opus 取代，但仍广泛部署
   * - SILK
     - 8000-24000
     - 6-40
     - 20
     - 较高
     - Skype 开发，适合语音通话，低延迟

**G.711 (PCMU/PCMA)**

G.711 是最基础也是兼容性最好的音频编解码器，几乎所有 VoIP 设备都支持。
PCMU（μ-law）主要在北美使用，PCMA（A-law）在欧洲和其他地区使用。
虽然比特率较高（64kbps），但由于其极低的计算复杂度，在转码场景中几乎不消耗 CPU 资源。

.. code-block:: xml

   <!-- 在 vars.xml 中设置全局编解码器偏好 -->
   <X-PRE-PROCESS cmd="set" data="global_codec_prefs=PCMU,PCMA"/>
   <X-PRE-PROCESS cmd="set" data="outbound_codec_prefs=PCMU,PCMA"/>

**Opus**

Opus 是 WebRTC 的必选音频编解码器，也是 FreeSWITCH 中处理 WebRTC 呼叫的关键。
通过 mod_opus 模块提供支持，它具有以下优势：

- 支持 8kHz 到 48kHz 的采样率，自适应切换
- 支持 CBR（恒定比特率）和 VBR（可变比特率）模式
- 内置前向纠错（FEC）机制，增强抗丢包能力
- 支持 DTX（不连续传输），节省带宽

.. code-block:: xml

   <!-- opus.conf.xml 配置示例 -->
   <configuration name="opus.conf">
     <settings>
       <param name="use-vbr" value="1"/>
       <param name="use-dtx" value="1"/>
       <param name="complexity" value="10"/>
       <param name="packet-loss-percent" value="15"/>
       <param name="keep-fec-enabled" value="1"/>
       <param name="use-jb-lookahead" value="1"/>
       <param name="maxaveragebitrate" value="64000"/>
       <param name="maxplaybackrate" value="48000"/>
       <param name="sprop-maxcapturerate" value="16000"/>
       <param name="adjust-bitrate" value="1"/>
     </settings>
   </configuration>


支持的视频编解码器
============================================

FreeSWITCH 对视频编解码器的支持主要通过 mod_av（基于 FFmpeg/libav）和
mod_openh264（基于 Cisco OpenH264）两个模块实现。

**VP8**

VP8 是 WebRTC 的必选视频编解码器之一，由 Google 开发并开源。FreeSWITCH 通过
mod_av 模块提供 VP8 的编解码支持。VP8 的主要特点包括：

- 免专利费，适合开源项目
- 良好的错误恢复能力
- 支持时间可伸缩性（Temporal Scalability）

**H.264**

H.264 是目前最广泛使用的视频编解码器，FreeSWITCH 提供两种方式支持：

1. **mod_av**: 基于 FFmpeg/libav 库，提供完整的 H.264 编解码能力，
   支持多种 profile（Baseline, Main, High）和 level。
2. **mod_openh264**: 基于 Cisco 开源的 OpenH264 库，仅支持 Baseline Profile，
   但免专利费（Cisco 已支付相关费用）。

.. code-block:: xml

   <!-- 在 vars.xml 中启用视频编解码器 -->
   <X-PRE-PROCESS cmd="set"
     data="global_codec_prefs=OPUS,PCMU,PCMA,VP8,H264"/>
   <X-PRE-PROCESS cmd="set"
     data="outbound_codec_prefs=OPUS,PCMU,PCMA,VP8,H264"/>

**H.265 (HEVC) 支持状态**

截至目前，FreeSWITCH 对 H.265/HEVC 的支持仍处于实验阶段。由于 H.265 的专利许可
问题较为复杂，且 WebRTC 标准尚未将其列为必选编解码器，因此在生产环境中使用
H.265 需要谨慎评估。未来随着 AV1 编解码器的成熟，FreeSWITCH 可能会优先支持 AV1
而非 H.265。

.. list-table:: FreeSWITCH 视频编解码器对比
   :header-rows: 1
   :widths: 15 20 20 20 25

   * - 编解码器
     - 提供模块
     - 专利状态
     - WebRTC 支持
     - 备注
   * - VP8
     - mod_av
     - 免费
     - 必选
     - Google 开源，兼容性好
   * - H.264
     - mod_av / mod_openh264
     - 需授权（OpenH264 免费）
     - 广泛支持
     - 最通用的视频编解码器
   * - H.265
     - 实验性
     - 需授权
     - 尚未标准化
     - 不建议生产使用
   * - VP9
     - mod_av（部分）
     - 免费
     - 可选
     - 压缩效率优于 VP8


编解码器协商与转码
============================================

编解码器协商是 VoIP 通信中的关键环节，它决定了通话双方使用哪种编解码器进行
媒体传输。FreeSWITCH 提供了灵活的协商机制和强大的转码能力。

**SDP 中的编解码器协商**

在 SIP 会话建立过程中，编解码器协商通过 SDP（Session Description Protocol）
的 Offer/Answer 模型完成：

1. 主叫方在 INVITE 请求中携带 SDP Offer，列出其支持的编解码器列表
2. FreeSWITCH 根据配置的偏好顺序，从 Offer 中选择匹配的编解码器
3. 被叫方收到 FreeSWITCH 转发的 Offer 后，返回 SDP Answer
4. 最终确定双方使用的编解码器

**编解码器偏好顺序**

FreeSWITCH 支持多个层级的编解码器偏好设置：

.. code-block:: xml

   <!-- 全局偏好（vars.xml） -->
   <X-PRE-PROCESS cmd="set"
     data="global_codec_prefs=OPUS,G722,PCMU,PCMA,VP8,H264"/>

   <!-- SIP Profile 级别偏好（sip_profiles/internal.xml） -->
   <param name="inbound-codec-prefs" value="OPUS,G722,PCMU,PCMA"/>
   <param name="outbound-codec-prefs" value="OPUS,G722,PCMU,PCMA"/>

   <!-- 拨号计划中针对单个呼叫设置 -->
   <action application="set"
     data="absolute_codec_string=OPUS,PCMU"/>
   <action application="export"
     data="absolute_codec_string=OPUS,PCMU"/>

**延迟协商（Late Negotiation）**

默认情况下，FreeSWITCH 在收到 INVITE 时立即进行编解码器协商（Early Negotiation）。
启用延迟协商后，FreeSWITCH 会等到呼叫被应答或桥接时才确定编解码器，
这样可以让两个通话端直接协商，减少不必要的转码。

.. code-block:: xml

   <!-- 在 SIP Profile 中启用延迟协商 -->
   <param name="inbound-late-negotiation" value="true"/>

**转码的 CPU 开销**

转码是指将一种编解码器的媒体流转换为另一种编解码器的过程。这是一个计算密集型操作，
尤其是视频转码。以下是一些经验数据：

.. list-table:: 转码 CPU 开销估算（单核参考）
   :header-rows: 1
   :widths: 30 30 40

   * - 转码类型
     - 单核并发路数
     - 说明
   * - G.711 ↔ G.711
     - 数千路
     - 几乎无 CPU 开销
   * - G.711 ↔ Opus
     - 200-500 路
     - 中等 CPU 开销
   * - G.711 ↔ G.729
     - 100-300 路
     - 较高 CPU 开销
   * - VP8 ↔ H.264
     - 5-20 路
     - 极高 CPU 开销，应尽量避免

.. note::

   在生产环境中，应尽量通过合理的编解码器协商策略来避免不必要的转码，
   特别是视频转码。使用延迟协商和编解码器透传是减少转码的有效手段。


媒体代理与媒体绕行
============================================

FreeSWITCH 提供了三种媒体处理模式，适用于不同的应用场景：

**默认模式（Media Proxy）**

在默认模式下，所有 RTP 媒体流都经过 FreeSWITCH。FreeSWITCH 完全参与媒体处理，
可以进行转码、录音、播放提示音等操作。

.. code-block:: text

   终端 A  <--RTP-->  FreeSWITCH  <--RTP-->  终端 B
                    (完全媒体处理)

**代理媒体模式（Proxy Media）**

在代理媒体模式下，RTP 流仍然经过 FreeSWITCH，但 FreeSWITCH 不对媒体内容进行
解码或处理，仅做透明转发。这种模式保留了 NAT 穿越能力，同时降低了 CPU 开销。

.. code-block:: xml

   <!-- 在拨号计划中启用代理媒体 -->
   <action application="set" data="proxy_media=true"/>
   <action application="bridge" data="sofia/gateway/provider/$1"/>

.. code-block:: text

   终端 A  <--RTP-->  FreeSWITCH  <--RTP-->  终端 B
                    (透明转发，不解码)

**媒体绕行模式（Bypass Media）**

在绕行模式下，RTP 流直接在两个终端之间传输，完全不经过 FreeSWITCH。
FreeSWITCH 仅处理 SIP 信令。这种模式最大程度地降低了服务器负载和媒体延迟，
但失去了录音、转码等媒体处理能力。

.. code-block:: xml

   <!-- 在拨号计划中启用媒体绕行 -->
   <action application="set" data="bypass_media=true"/>
   <action application="bridge" data="sofia/gateway/provider/$1"/>

.. code-block:: text

   终端 A  <------------ RTP ------------>  终端 B
                FreeSWITCH (仅信令)

.. list-table:: 三种媒体模式对比
   :header-rows: 1
   :widths: 20 20 20 20 20

   * - 特性
     - 默认模式
     - 代理媒体
     - 媒体绕行
     - 说明
   * - RTP 经过 FS
     - 是
     - 是
     - 否
     - 绕行模式 RTP 直连
   * - 转码能力
     - 支持
     - 不支持
     - 不支持
     - 仅默认模式可转码
   * - 录音能力
     - 支持
     - 不支持
     - 不支持
     - 需要媒体经过 FS
   * - NAT 穿越
     - 支持
     - 支持
     - 需端到端可达
     - 代理模式保留 NAT 穿越
   * - CPU 开销
     - 高
     - 低
     - 极低
     - 绕行模式几乎无开销
   * - 媒体延迟
     - 较高
     - 中等
     - 最低
     - 减少一跳降低延迟


录音与回放
============================================

FreeSWITCH 提供了强大的录音和回放功能，广泛应用于通话录音、IVR 系统、
语音信箱等场景。

**录音功能（mod_record）**

FreeSWITCH 支持多种录音方式和格式：

.. code-block:: xml

   <!-- 在拨号计划中启动录音 -->
   <action application="record_session" data="/recordings/${uuid}.wav"/>

   <!-- 录制立体声（双声道，每个通话方一个声道） -->
   <action application="set" data="RECORD_STEREO=true"/>
   <action application="record_session"
     data="/recordings/${uuid}-stereo.wav"/>

   <!-- 使用 record 应用录制单段音频 -->
   <action application="record" data="/recordings/msg.wav 60 200 5"/>
   <!-- 参数: 文件路径 最大秒数 静音阈值 静音超时秒数 -->

**支持的录音格式**

.. list-table:: 录音格式支持
   :header-rows: 1
   :widths: 20 20 30 30

   * - 格式
     - 扩展名
     - 所需模块
     - 说明
   * - WAV (PCM)
     - .wav
     - 内置
     - 无损格式，文件较大
   * - MP3
     - .mp3
     - mod_shout
     - 有损压缩，文件较小
   * - OGG Vorbis
     - .ogg
     - mod_ogg
     - 开源有损压缩格式

**回放功能**

.. code-block:: xml

   <!-- 播放音频文件 -->
   <action application="playback" data="/sounds/welcome.wav"/>

   <!-- 播放并等待 DTMF 输入 -->
   <action application="play_and_get_digits"
     data="1 4 3 5000 # /sounds/enter_pin.wav
           /sounds/invalid.wav pin_result \d+"/>

   <!-- 使用 say 应用进行 TTS 式播报 -->
   <action application="say" data="zh NUMBER PRONOUNCED 12345"/>

**通话录音的最佳实践**

在生产环境中进行通话录音时，建议注意以下几点：

1. 使用立体声录音以便区分通话双方
2. 选择合适的录音格式平衡质量和存储空间
3. 合理规划录音文件的存储路径和命名规则
4. 定期清理过期的录音文件，避免磁盘空间耗尽
5. 注意录音的法律合规要求


DTMF 处理
============================================

DTMF（Dual-Tone Multi-Frequency，双音多频）信号在 VoIP 通信中有三种传输方式，
FreeSWITCH 全部支持并可在它们之间进行转换。

**RFC 2833 (telephone-event)**

这是 VoIP 中最常用的 DTMF 传输方式，将 DTMF 信号编码为特殊的 RTP 事件包
（通常使用 payload type 101）。

.. code-block:: text

   RTP Header | Payload Type: 101 | Event: 1 | Duration: 800 |

**带内 DTMF（In-band DTMF）**

将 DTMF 音调直接编码在音频流中。这种方式兼容性最好，但在使用低比特率编解码器
（如 G.729）时可能导致 DTMF 检测失败。

**SIP INFO**

通过 SIP INFO 消息在信令通道中传输 DTMF 信息。这种方式不依赖 RTP 流，
但可能受到信令延迟的影响。

.. code-block:: text

   SIP INFO sip:user@host
   Content-Type: application/dtmf-relay

   Signal=1
   Duration=250

**DTMF 模式配置**

.. code-block:: xml

   <!-- 在 SIP Profile 中设置 DTMF 模式 -->
   <param name="dtmf-type" value="rfc2833"/>
   <!-- 可选值: rfc2833, info, none -->

   <!-- 在拨号计划中动态切换 DTMF 模式 -->
   <action application="set" data="dtmf_type=rfc2833"/>

   <!-- 启用带内 DTMF 检测 -->
   <action application="start_dtmf"/>

   <!-- 生成 DTMF 音调 -->
   <action application="send_dtmf" data="1234#"/>

**DTMF 检测与应用**

FreeSWITCH 提供了丰富的 DTMF 检测和处理机制：

.. code-block:: xml

   <!-- 绑定 DTMF 按键到动作 -->
   <action application="bind_digit_action"
     data="my_digits,~^\d{4}#$,exec:execute_extension,
           check_pin XML default"/>

   <!-- 在 IVR 中收集 DTMF 输入 -->
   <action application="play_and_get_digits"
     data="4 4 3 10000 # /sounds/enter_pin.wav
           /sounds/error.wav digits_result \d{4}"/>


音频处理
============================================

FreeSWITCH 提供了丰富的音频处理功能，满足各种通信场景的需求。

**音调生成（mod_tone_stream）**

mod_tone_stream 模块可以生成各种标准音调，如忙音、回铃音、拨号音等：

.. code-block:: xml

   <!-- 播放北美标准回铃音 -->
   <action application="playback"
     data="tone_stream://%(2000,4000,440,480)"/>

   <!-- 播放忙音 -->
   <action application="playback"
     data="tone_stream://%(500,500,480,620);loops=-1"/>

   <!-- 播放自定义频率音调 -->
   <action application="playback"
     data="tone_stream://%(1000,0,800)"/>

**等待音乐（Music on Hold）**

FreeSWITCH 通过 mod_local_stream 模块提供高效的等待音乐功能：

.. code-block:: xml

   <!-- local_stream.conf.xml 配置 -->
   <configuration name="local_stream.conf" description="Stream Files">
     <directory name="moh/8000" path="$${sounds_dir}/music/8000">
       <param name="rate" value="8000"/>
       <param name="shuffle" value="true"/>
       <param name="channels" value="1"/>
       <param name="interval" value="20"/>
       <param name="timer-name" value="soft"/>
     </directory>
   </configuration>

   <!-- 在拨号计划中使用等待音乐 -->
   <action application="set" data="hold_music=local_stream://moh/8000"/>

**静音检测（Silence Detection）**

静音检测用于识别通话中的静默期，常用于语音信箱和录音场景：

.. code-block:: xml

   <!-- 启用静音检测，200 为静音阈值，500ms 为超时 -->
   <action application="set" data="silence_hits=500"/>
   <action application="detect_silence" data="200 500"/>

**舒适噪声（Comfort Noise）**

在静音期间生成舒适噪声（CN），避免通话中出现"死寂"的感觉：

.. code-block:: xml

   <!-- 启用舒适噪声生成 -->
   <param name="comfort-noise" value="true"/>

   <!-- 在 SDP 中协商 CN -->
   <!-- payload type 13 通常用于 CN -->


RTP 配置与优化
============================================

RTP（Real-time Transport Protocol）是 FreeSWITCH 媒体传输的基础协议。
合理的 RTP 配置对通话质量至关重要。

**RTP 端口范围**

.. code-block:: xml

   <!-- switch.conf.xml 中配置 RTP 端口范围 -->
   <param name="rtp-start-port" value="16384"/>
   <param name="rtp-end-port" value="32768"/>

   <!-- 确保防火墙开放对应的 UDP 端口范围 -->

端口范围的大小决定了 FreeSWITCH 能同时处理的最大媒体流数量。
每个媒体流需要两个端口（一个用于 RTP，一个用于 RTCP），因此可用端口数除以 2
即为最大并发媒体流数。

**RTP 定时器**

FreeSWITCH 支持多种 RTP 定时器实现：

.. code-block:: xml

   <!-- 使用软定时器（默认） -->
   <param name="rtp-timer-name" value="soft"/>

   <!-- 定时器间隔（毫秒） -->
   <param name="rtp-timeout-sec" value="300"/>
   <param name="rtp-hold-timeout-sec" value="1800"/>

**抖动缓冲区（Jitter Buffer）**

抖动缓冲区用于平滑网络抖动对音频质量的影响：

.. code-block:: xml

   <!-- 启用抖动缓冲区 -->
   <action application="set"
     data="jitterbuffer_msec=60:200:20"/>
   <!-- 参数: 初始大小:最大大小:最大漂移 (毫秒) -->

   <!-- 视频抖动缓冲区 -->
   <action application="set"
     data="rtp_video_jitterbuffer_msec=200:1000:50"/>

**RTCP 配置**

RTCP（RTP Control Protocol）提供媒体流的质量反馈信息：

.. code-block:: xml

   <!-- 启用 RTCP -->
   <param name="rtcp-audio-interval-msec" value="5000"/>
   <param name="rtcp-video-interval-msec" value="2000"/>

**对称 RTP（Symmetric RTP）**

对称 RTP 有助于 NAT 穿越，使 FreeSWITCH 将 RTP 包发送到接收 RTP 包的同一地址：

.. code-block:: xml

   <!-- 在 SIP Profile 中启用对称 RTP -->
   <param name="rtp-ip" value="$${local_ip_v4}"/>
   <param name="ext-rtp-ip" value="auto-nat"/>

**WebRTC 相关的 RTP 配置**

在处理 WebRTC 呼叫时，需要额外配置 DTLS-SRTP 和 ICE：

.. code-block:: xml

   <!-- 在 SIP Profile 中启用 WebRTC 支持 -->
   <param name="tls" value="true"/>
   <param name="wss-binding" value=":7443"/>

   <!-- 在拨号计划中为 WebRTC 呼叫设置媒体参数 -->
   <action application="set" data="rtp_secure_media=true"/>
   <action application="set"
     data="rtp_secure_media_suites=
           AEAD_AES_256_GCM_8|
           AEAD_AES_128_GCM_8|
           AES_CM_256_HMAC_SHA1_80|
           AES_CM_128_HMAC_SHA1_80"/>

**RTP 优化建议**

1. **端口范围**: 根据预期并发量合理设置端口范围，避免端口耗尽
2. **抖动缓冲区**: 根据网络质量调整抖动缓冲区大小，过大会增加延迟，过小会导致丢包
3. **RTCP**: 启用 RTCP 以便监控通话质量，及时发现和定位问题
4. **对称 RTP**: 在 NAT 环境中务必启用对称 RTP
5. **QoS 标记**: 配置 DSCP 标记以确保 RTP 包在网络中获得优先处理

.. code-block:: xml

   <!-- 设置 RTP 包的 DSCP/TOS 值 -->
   <param name="rtp-tos-value" value="184"/>
   <!-- 184 = 0xB8 = EF (Expedited Forwarding) -->


参考资料
============================================

1. FreeSWITCH 官方文档: https://freeswitch.org/confluence/
2. FreeSWITCH 权威指南（The Definitive Guide to FreeSWITCH）
3. RFC 3550 - RTP: A Transport Protocol for Real-Time Applications
4. RFC 2833 - RTP Payload for DTMF Digits, Telephony Tones and Telephony Signals
5. RFC 6716 - Definition of the Opus Audio Codec
6. RFC 7742 - WebRTC Video Processing and Codec Requirements
7. RFC 7874 - WebRTC Audio Codec and Processing Requirements
8. FreeSWITCH mod_opus 文档: https://freeswitch.org/confluence/display/FREESWITCH/mod_opus
9. FreeSWITCH Codec Negotiation: https://freeswitch.org/confluence/display/FREESWITCH/Codec+Negotiation
10. WebRTC 与 FreeSWITCH 集成最佳实践
