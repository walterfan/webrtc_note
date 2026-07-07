##########################
FreeSWITCH 会议
##########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** FreeSWITCH Conference
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:


概述
========================

FreeSWITCH 内置了强大的会议模块 ``mod_conference`` ，它支持多方音频混音、视频 MCU 合成、会议控制等功能。
与传统的 MCU 设备相比，FreeSWITCH 的会议功能完全基于软件实现，部署灵活，扩展性强。

``mod_conference`` 是 FreeSWITCH 中最常用的模块之一，广泛应用于：

* 电话会议（Audio Conference）
* 视频会议（Video Conference）
* 网络研讨会（Webinar）
* 在线教育（Online Education）
* 呼叫中心的多方通话（Multi-party Call in Contact Center）

对于 WebRTC 参与者，FreeSWITCH 可以通过 ``mod_verto`` 或 SIP over WebSocket 将浏览器端接入会议，
实现传统电话与 WebRTC 客户端的混合会议。


mod_conference 模块
========================

``mod_conference`` 是 FreeSWITCH 的核心会议模块，默认随 FreeSWITCH 一起编译安装。

模块加载
-----------

在 ``modules.conf.xml`` 中确保以下行未被注释：

.. code-block:: xml

   <load module="mod_conference"/>

模块加载后，可以在 ``fs_cli`` 中验证：

.. code-block:: bash

   freeswitch@default> module_exists mod_conference
   true


会议的基本工作原理
---------------------

``mod_conference`` 的核心功能包括：

1. **音频混音（Audio Mixing）**：将所有参与者的音频流混合在一起，每个参与者听到的是除自己之外所有人的混合音频
2. **视频合成（Video Compositing）**：支持多种视频布局，将多路视频合成为一路输出
3. **会议控制（Conference Control）**：支持静音、踢出、地板控制（Floor Control）等操作
4. **事件通知（Event Notification）**：会议状态变化时产生事件，便于外部系统集成


会议配置文件
========================

会议的配置文件位于 ``conf/autoload_configs/conference.conf.xml`` 。

基本配置结构
--------------

.. code-block:: xml

   <configuration name="conference.conf" description="Audio Conference">
     <advertise>
       <room name="3001@$${domain}" status="FreeSWITCH"/>
     </advertise>

     <caller-controls>
       <group name="default">
         <control action="mute" digits="0"/>
         <control action="deaf mute" digits="*"/>
         <control action="energy up" digits="9"/>
         <control action="energy equ" digits="8"/>
         <control action="energy dn" digits="7"/>
         <control action="vol talk up" digits="3"/>
         <control action="vol talk zero" digits="2"/>
         <control action="vol talk dn" digits="1"/>
         <control action="vol listen up" digits="6"/>
         <control action="vol listen zero" digits="5"/>
         <control action="vol listen dn" digits="4"/>
         <control action="hangup" digits="#"/>
       </group>
     </caller-controls>

     <profiles>
       <profile name="default">
         <param name="domain" value="$${domain}"/>
         <param name="rate" value="8000"/>
         <param name="interval" value="20"/>
         <param name="energy-level" value="100"/>
         <param name="caller-controls" value="default"/>
         <param name="sound-prefix" value="$${sounds_dir}/en/us/callie"/>
         <param name="muted-sound" value="conference/conf-muted.wav"/>
         <param name="unmuted-sound" value="conference/conf-unmuted.wav"/>
         <param name="alone-sound" value="conference/conf-alone.wav"/>
         <param name="enter-sound" value="tone_stream://%(200,0,500,600,700)"/>
         <param name="exit-sound" value="tone_stream://%(500,0,300,200,100,50,25)"/>
         <param name="kicked-sound" value="conference/conf-kicked.wav"/>
         <param name="locked-sound" value="conference/conf-locked.wav"/>
         <param name="is-locked-sound" value="conference/conf-is-locked.wav"/>
         <param name="is-unlocked-sound" value="conference/conf-is-unlocked.wav"/>
         <param name="pin-sound" value="conference/conf-pin.wav"/>
         <param name="bad-pin-sound" value="conference/conf-bad-pin.wav"/>
         <param name="max-members-sound" value="conference/conf-max-members.wav"/>
         <param name="caller-id-name" value="$${outbound_caller_name}"/>
         <param name="caller-id-number" value="$${outbound_caller_id}"/>
         <param name="comfort-noise" value="true"/>
       </profile>
     </profiles>
   </configuration>


会议 Profile 参数详解
-----------------------

以下是常用的 Profile 参数：

.. list-table:: 会议 Profile 常用参数
   :header-rows: 1
   :widths: 25 15 60

   * - 参数名
     - 默认值
     - 说明
   * - rate
     - 8000
     - 音频采样率，支持 8000, 16000, 32000, 48000
   * - interval
     - 20
     - 音频帧间隔（毫秒），通常为 20ms
   * - energy-level
     - 100
     - 语音活动检测（VAD）的能量阈值
   * - max-members
     - 0
     - 最大参与者数量，0 表示不限制
   * - comfort-noise
     - true
     - 是否生成舒适噪声（Comfort Noise）
   * - caller-controls
     - default
     - 参与者按键控制组名称
   * - moderator-controls
     - (none)
     - 主持人按键控制组名称
   * - pin
     - (none)
     - 会议 PIN 码
   * - moderator-pin
     - (none)
     - 主持人 PIN 码
   * - auto-record
     - (none)
     - 自动录制的文件路径模板


音频混音与视频 MCU
========================

音频混音
-----------

FreeSWITCH 的音频混音采用 N-1 混音算法，即每个参与者听到的是除自己之外所有人的混合音频。
这种方式避免了回声问题，同时保证了音频质量。

音频混音的关键参数：

* **rate**：采样率越高，音质越好，但 CPU 消耗也越大。对于电话会议，8000Hz 即可；对于高清音频会议，建议使用 48000Hz
* **interval**：帧间隔，20ms 是最常用的值
* **energy-level**：VAD 阈值，低于此值的音频被视为静音，不参与混音

.. code-block:: xml

   <profile name="wideband">
     <param name="rate" value="16000"/>
     <param name="interval" value="20"/>
     <param name="energy-level" value="200"/>
   </profile>

   <profile name="ultrawideband">
     <param name="rate" value="48000"/>
     <param name="interval" value="20"/>
     <param name="energy-level" value="100"/>
   </profile>


视频 MCU
-----------

FreeSWITCH 支持视频 MCU 功能，可以将多路视频合成为一路输出。视频布局（Video Layout）定义了各路视频在画面中的位置和大小。

视频布局配置文件位于 ``conf/autoload_configs/conference_layouts.conf.xml`` ：

.. code-block:: xml

   <layout name="2x2" auto-3d-position="true">
     <image x="0" y="0" scale="180" floor="true"
            floor-only="false" overlap="false" reservation_id=""/>
     <image x="180" y="0" scale="180"/>
     <image x="0" y="180" scale="180"/>
     <image x="180" y="180" scale="180"/>
   </layout>

   <layout name="presenter-small-audience">
     <image x="0" y="0" scale="270" floor="true"/>
     <image x="270" y="0" scale="90"/>
     <image x="270" y="90" scale="90"/>
     <image x="270" y="180" scale="90"/>
     <image x="270" y="270" scale="90"/>
   </layout>

在 Profile 中启用视频：

.. code-block:: xml

   <profile name="video-conference">
     <param name="rate" value="48000"/>
     <param name="video-mode" value="mux"/>
     <param name="video-layout-name" value="2x2"/>
     <param name="video-canvas-size" value="720x720"/>
     <param name="video-canvas-bgcolor" value="#333333"/>
     <param name="video-fps" value="15"/>
     <param name="video-codec-bandwidth" value="2mb"/>
   </profile>


会议控制
========================

Caller Controls（参与者控制）
-------------------------------

参与者可以通过 DTMF 按键执行操作：

.. code-block:: xml

   <caller-controls>
     <group name="default">
       <control action="mute" digits="0"/>
       <control action="deaf mute" digits="*"/>
       <control action="hangup" digits="#"/>
       <control action="energy up" digits="9"/>
       <control action="energy dn" digits="7"/>
       <control action="vol talk up" digits="3"/>
       <control action="vol talk dn" digits="1"/>
       <control action="vol listen up" digits="6"/>
       <control action="vol listen dn" digits="4"/>
     </group>

     <group name="moderator">
       <control action="mute" digits="0"/>
       <control action="deaf mute" digits="*"/>
       <control action="hangup" digits="#"/>
       <control action="lock" digits="78"/>
       <control action="unlock" digits="79"/>
       <control action="mute non_moderator" digits="70"/>
     </group>
   </caller-controls>


API 控制命令
--------------

通过 ``fs_cli`` 或 ESL 可以执行丰富的会议控制命令：

.. code-block:: bash

   # 列出所有会议
   conference list

   # 查看特定会议的参与者
   conference 3001 list

   # 静音某个参与者（member_id 为参与者编号）
   conference 3001 mute 1

   # 取消静音
   conference 3001 unmute 1

   # 全体静音（非主持人）
   conference 3001 mute non_moderator

   # 踢出参与者
   conference 3001 kick 2

   # 锁定会议（不允许新参与者加入）
   conference 3001 lock

   # 解锁会议
   conference 3001 unlock

   # 设置地板（Floor）给某个参与者
   conference 3001 vid-floor 1 force

   # 播放音频文件给所有参与者
   conference 3001 play /tmp/announcement.wav

   # 录制会议
   conference 3001 record /tmp/conference_3001.wav

   # 停止录制
   conference 3001 norecord /tmp/conference_3001.wav


会议事件与 CDR
========================

FreeSWITCH 会议产生丰富的事件，可用于外部系统集成和 CDR（Call Detail Record）记录。

主要会议事件
--------------

.. list-table:: 会议事件类型
   :header-rows: 1
   :widths: 35 65

   * - 事件名称
     - 说明
   * - conference::maintenance
     - 会议维护事件（加入、离开、静音等）
   * - conference::add-member
     - 参与者加入会议
   * - conference::del-member
     - 参与者离开会议
   * - conference::mute-member
     - 参与者被静音
   * - conference::unmute-member
     - 参与者取消静音
   * - conference::kick-member
     - 参与者被踢出
   * - conference::start-talking
     - 参与者开始说话
   * - conference::stop-talking
     - 参与者停止说话
   * - conference::lock
     - 会议被锁定
   * - conference::unlock
     - 会议被解锁

通过 ESL 订阅会议事件：

.. code-block:: python

   import ESL

   con = ESL.ESLconnection("127.0.0.1", "8021", "ClueCon")
   con.events("plain", "CUSTOM conference::maintenance")

   while True:
       event = con.recvEvent()
       if event:
           action = event.getHeader("Action")
           conf_name = event.getHeader("Conference-Name")
           member_id = event.getHeader("Member-ID")
           print(f"Conference: {conf_name}, Action: {action}, Member: {member_id}")


WebRTC 参与者接入会议
========================

通过 mod_verto 接入
---------------------

``mod_verto`` 是 FreeSWITCH 原生的 WebRTC 信令协议模块。WebRTC 客户端可以通过 Verto 协议加入会议：

.. code-block:: javascript

   // 使用 verto.js 加入会议
   var vertoHandle = new $.verto({
     login: "1000@example.com",
     passwd: "1234",
     socketUrl: "wss://freeswitch.example.com:8082",
     iceServers: [
       { url: "stun:stun.l.google.com:19302" }
     ]
   });

   // 拨入会议号码
   var call = vertoHandle.newCall({
     destination_number: "3001",
     caller_id_name: "WebRTC User",
     caller_id_number: "1000",
     useVideo: true,
     useStereo: true
   });


通过 SIP over WebSocket 接入
-------------------------------

也可以通过 ``mod_sofia`` 的 WebSocket 传输让 SIP.js 等 WebRTC SIP 客户端接入：

.. code-block:: xml

   <!-- sofia profile 中启用 WebSocket -->
   <param name="ws-binding" value=":5066"/>
   <param name="wss-binding" value=":7443"/>


Dialplan 配置
--------------

在 Dialplan 中配置会议接入：

.. code-block:: xml

   <extension name="conference">
     <condition field="destination_number" expression="^(3\d{3})$">
       <action application="answer"/>
       <action application="sleep" data="1000"/>
       <action application="conference" data="$1@video-conference"/>
     </condition>
   </extension>

   <!-- 带 PIN 码的会议 -->
   <extension name="conference-with-pin">
     <condition field="destination_number" expression="^(4\d{3})$">
       <action application="answer"/>
       <action application="conference" data="$1@video-conference+1234"/>
     </condition>
   </extension>

   <!-- 主持人入口（带主持人 PIN） -->
   <extension name="conference-moderator">
     <condition field="destination_number" expression="^(4\d{3})0$">
       <action application="answer"/>
       <action application="conference" data="$1@video-conference+1234+5678"/>
     </condition>
   </extension>


会议录制
========================

FreeSWITCH 支持多种会议录制方式：

自动录制
-----------

在 Profile 中配置自动录制：

.. code-block:: xml

   <profile name="recorded-conference">
     <param name="auto-record"
            value="/var/recordings/${conference_name}_${strftime(%Y%m%d_%H%M%S)}.wav"/>
   </profile>

手动录制
-----------

通过 API 命令手动控制录制：

.. code-block:: bash

   # 开始录制
   conference 3001 record /var/recordings/conf_3001.wav

   # 停止录制
   conference 3001 norecord /var/recordings/conf_3001.wav

   # 暂停录制
   conference 3001 recording pause /var/recordings/conf_3001.wav

   # 恢复录制
   conference 3001 recording resume /var/recordings/conf_3001.wav

录制格式支持 WAV、MP3（需要 ``mod_shout``）等。对于视频会议，可以录制为 MP4 格式。


PIN 保护的会议
========================

FreeSWITCH 支持为会议设置 PIN 码，分为普通参与者 PIN 和主持人 PIN：

.. code-block:: xml

   <profile name="secure-conference">
     <param name="pin" value="1234"/>
     <param name="moderator-pin" value="5678"/>
     <param name="pin-retries" value="3"/>
     <param name="pin-sound" value="conference/conf-pin.wav"/>
     <param name="bad-pin-sound" value="conference/conf-bad-pin.wav"/>
   </profile>

在 Dialplan 中也可以动态设置 PIN：

.. code-block:: xml

   <extension name="dynamic-pin-conference">
     <condition field="destination_number" expression="^(5\d{3})$">
       <action application="answer"/>
       <action application="conference" data="$1@default+${pin_from_db}"/>
     </condition>
   </extension>


大规模会议优化
========================

当会议参与者数量较多时（例如超过 100 人），需要进行性能优化：

系统层面优化
--------------

.. code-block:: bash

   # 增加文件描述符限制
   ulimit -n 65536

   # 优化内核参数
   sysctl -w net.core.rmem_max=16777216
   sysctl -w net.core.wmem_max=16777216
   sysctl -w net.core.rmem_default=65536
   sysctl -w net.core.wmem_default=65536

会议配置优化
--------------

* **降低采样率**：大规模会议使用 8000Hz 采样率以减少 CPU 消耗
* **禁用视频**：纯音频会议可以支持更多参与者
* **提高 energy-level**：减少参与混音的音频流数量
* **使用 comfort-noise**：在静音时生成舒适噪声，减少带宽消耗

.. code-block:: xml

   <profile name="large-conference">
     <param name="rate" value="8000"/>
     <param name="interval" value="20"/>
     <param name="energy-level" value="300"/>
     <param name="max-members" value="500"/>
     <param name="comfort-noise" value="true"/>
     <param name="suppress-events" value="start-talking,stop-talking"/>
     <param name="verbose-events" value="false"/>
   </profile>

架构层面优化
--------------

对于超大规模会议（数百至数千人），可以考虑：

1. **级联会议（Cascaded Conference）**：多个 FreeSWITCH 节点之间通过 SIP 互联，每个节点处理一部分参与者
2. **分离角色**：将主持人和听众分配到不同的 Profile，听众使用更轻量的配置
3. **使用 Streaming 模式**：对于大量只听不说的参与者，可以使用 RTP 广播而非混音


会议 API 命令参考
========================

.. list-table:: conference API 命令
   :header-rows: 1
   :widths: 35 65

   * - 命令
     - 说明
   * - conference list [delim <d>]
     - 列出所有活跃会议
   * - conference <name> list
     - 列出会议中的参与者
   * - conference <name> mute <id>
     - 静音参与者
   * - conference <name> unmute <id>
     - 取消静音
   * - conference <name> deaf <id>
     - 使参与者听不到声音
   * - conference <name> undeaf <id>
     - 恢复参与者听觉
   * - conference <name> kick <id>
     - 踢出参与者
   * - conference <name> hup <id>
     - 挂断参与者
   * - conference <name> lock
     - 锁定会议
   * - conference <name> unlock
     - 解锁会议
   * - conference <name> play <file>
     - 播放音频文件
   * - conference <name> stop
     - 停止播放
   * - conference <name> record <file>
     - 开始录制
   * - conference <name> norecord <file>
     - 停止录制
   * - conference <name> relate <id1> <id2> <action>
     - 设置参与者之间的关系
   * - conference <name> vid-floor <id> [force]
     - 设置视频地板
   * - conference <name> vid-layout <layout>
     - 切换视频布局
   * - conference <name> vid-banner <id> <text>
     - 设置参与者视频横幅
   * - conference <name> transfer <id> <conf>
     - 将参与者转移到另一个会议
   * - conference <name> dial <endpoint>
     - 从会议中呼出


参考资料
========================

* FreeSWITCH mod_conference 文档: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Modules/mod_conference_3965534/
* FreeSWITCH Conference Cookbook: https://freeswitch.org/confluence/display/FREESWITCH/mod_conference
* FreeSWITCH Video Conference: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Conference/
