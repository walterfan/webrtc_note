######################################
FreeSWITCH IVR 与语音应用
######################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** FreeSWITCH IVR
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:


概述
========================

IVR（Interactive Voice Response，交互式语音应答）是电话系统中最常见的应用之一。
用户通过电话拨入后，系统播放语音提示，用户通过 DTMF 按键或语音输入进行交互，
系统根据用户的输入执行相应的操作，如转接电话、查询信息、留言等。

FreeSWITCH 提供了多种方式来构建 IVR 应用：

1. **Dialplan XML**：通过 XML 配置文件定义简单的 IVR 流程
2. **mod_ivr**：内置的 IVR 模块，提供菜单、输入收集等功能
3. **脚本语言**：通过 Lua、JavaScript、Python 等脚本语言实现复杂的 IVR 逻辑
4. **ESL（Event Socket Library）**：通过外部程序控制 IVR 流程

在 WebRTC 场景中，IVR 同样适用。WebRTC 客户端通过 ``mod_verto`` 或 SIP over WebSocket 接入后，
可以与 IVR 系统进行交互，实现 Web 端的语音自助服务。


mod_ivr 基础
========================

``mod_ivr`` 是 FreeSWITCH 的核心 IVR 模块，提供了以下基本功能：

* **play_and_get_digits**：播放提示音并收集 DTMF 输入
* **ivr_menu**：多级菜单系统
* **read**：读取用户输入
* **play_and_detect_speech**：播放提示音并进行语音识别

IVR 菜单配置
--------------

IVR 菜单在 ``conf/autoload_configs/ivr.conf.xml`` 中配置：

.. code-block:: xml

   <configuration name="ivr.conf" description="IVR menus">
     <menus>
       <menu name="main_menu"
             greet-long="ivr/ivr-welcome.wav"
             greet-short="ivr/ivr-menu.wav"
             invalid-sound="ivr/ivr-invalid.wav"
             exit-sound="ivr/ivr-exit.wav"
             confirm-macro=""
             confirm-key=""
             tts-engine="flite"
             tts-voice="slt"
             confirm-attempts="3"
             timeout="10000"
             inter-digit-timeout="2000"
             max-failures="3"
             max-timeouts="3"
             digit-len="4">

         <entry action="menu-exec-app"
                digits="1"
                param="transfer 1001 XML default"/>
         <entry action="menu-exec-app"
                digits="2"
                param="transfer 1002 XML default"/>
         <entry action="menu-sub"
                digits="3"
                param="support_menu"/>
         <entry action="menu-exec-app"
                digits="9"
                param="voicemail default ${domain_name} 1001"/>
         <entry action="menu-top"
                digits="*"/>
         <entry action="menu-exit-app"
                digits="#"
                param="hangup"/>
       </menu>

       <menu name="support_menu"
             greet-long="ivr/ivr-support-menu.wav"
             greet-short="ivr/ivr-support-short.wav"
             invalid-sound="ivr/ivr-invalid.wav"
             exit-sound="ivr/ivr-exit.wav"
             timeout="10000"
             max-failures="3">

         <entry action="menu-exec-app"
                digits="1"
                param="transfer 2001 XML default"/>
         <entry action="menu-exec-app"
                digits="2"
                param="transfer 2002 XML default"/>
         <entry action="menu-top"
                digits="*"/>
       </menu>
     </menus>
   </configuration>

在 Dialplan 中调用 IVR 菜单：

.. code-block:: xml

   <extension name="main-ivr">
     <condition field="destination_number" expression="^5000$">
       <action application="answer"/>
       <action application="sleep" data="1000"/>
       <action application="ivr" data="main_menu"/>
     </condition>
   </extension>


基于 Dialplan 的 IVR
========================

对于简单的 IVR 流程，可以直接在 Dialplan 中使用 ``play_and_get_digits`` 等 Application 实现：

.. code-block:: xml

   <extension name="simple-ivr">
     <condition field="destination_number" expression="^6000$">
       <action application="answer"/>
       <action application="sleep" data="500"/>

       <!-- 播放欢迎语并收集 1 位数字 -->
       <action application="play_and_get_digits"
               data="1 1 3 5000 # ivr/ivr-welcome.wav ivr/ivr-invalid.wav
                     selection \d 10000"/>

       <!-- 根据输入转接 -->
       <action application="transfer"
               data="handle_selection_${selection} XML default"/>
     </condition>
   </extension>

   <extension name="handle_selection_1">
     <condition field="destination_number" expression="^handle_selection_1$">
       <action application="playback" data="ivr/ivr-transferring.wav"/>
       <action application="transfer" data="1001 XML default"/>
     </condition>
   </extension>

   <extension name="handle_selection_2">
     <condition field="destination_number" expression="^handle_selection_2$">
       <action application="playback" data="ivr/ivr-transferring.wav"/>
       <action application="transfer" data="1002 XML default"/>
     </condition>
   </extension>

``play_and_get_digits`` 参数说明：

.. list-table:: play_and_get_digits 参数
   :header-rows: 1
   :widths: 20 80

   * - 参数位置
     - 说明
   * - min_digits
     - 最少收集的数字位数
   * - max_digits
     - 最多收集的数字位数
   * - tries
     - 最大尝试次数
   * - timeout
     - 等待输入的超时时间（毫秒）
   * - terminators
     - 终止符（如 #）
   * - file
     - 播放的提示音文件
   * - invalid_file
     - 输入无效时播放的文件
   * - var_name
     - 存储输入结果的变量名
   * - regexp
     - 输入验证的正则表达式
   * - digit_timeout
     - 数字间超时时间（毫秒）


Lua 脚本实现 IVR
========================

Lua 是 FreeSWITCH 中最推荐的脚本语言，通过 ``mod_lua`` 模块加载。
Lua 脚本可以实现复杂的 IVR 逻辑，包括数据库查询、HTTP 请求、条件分支等。

基本 Lua IVR 示例
--------------------

.. code-block:: lua

   -- /usr/local/freeswitch/scripts/ivr_main.lua

   -- 接听电话
   session:answer()
   session:sleep(1000)

   -- 设置 TTS 引擎
   session:set_tts_params("flite", "slt")

   -- 播放欢迎语
   session:streamFile("ivr/ivr-welcome.wav")

   -- 主菜单循环
   local max_retries = 3
   local retry = 0

   while session:ready() and retry < max_retries do
       -- 收集用户输入
       local digits = session:playAndGetDigits(
           1, 1,           -- min, max digits
           3,              -- tries
           5000,           -- timeout ms
           "#",            -- terminators
           "ivr/ivr-menu.wav",      -- prompt
           "ivr/ivr-invalid.wav",   -- invalid prompt
           "input",        -- variable name
           "\\d",          -- regex
           10000           -- digit timeout
       )

       if digits == "1" then
           session:streamFile("ivr/ivr-transferring.wav")
           session:transfer("1001", "XML", "default")
       elseif digits == "2" then
           session:streamFile("ivr/ivr-transferring.wav")
           session:transfer("1002", "XML", "default")
       elseif digits == "3" then
           -- 子菜单
           handle_support_menu(session)
       elseif digits == "9" then
           -- 留言
           session:transfer("*99 XML default")
       elseif digits == "0" then
           -- 转人工
           session:streamFile("ivr/ivr-please-hold.wav")
           session:transfer("operator XML default")
       else
           retry = retry + 1
           if retry >= max_retries then
               session:streamFile("ivr/ivr-exit.wav")
           end
       end
   end

   -- 子菜单函数
   function handle_support_menu(session)
       local digits = session:playAndGetDigits(
           1, 1, 3, 5000, "#",
           "ivr/ivr-support-menu.wav",
           "ivr/ivr-invalid.wav",
           "support_input", "\\d", 10000
       )

       if digits == "1" then
           session:transfer("2001", "XML", "default")
       elseif digits == "2" then
           session:transfer("2002", "XML", "default")
       end
   end

在 Dialplan 中调用 Lua 脚本：

.. code-block:: xml

   <extension name="lua-ivr">
     <condition field="destination_number" expression="^6001$">
       <action application="lua" data="ivr_main.lua"/>
     </condition>
   </extension>


带数据库查询的 Lua IVR
-------------------------

.. code-block:: lua

   -- 查询订单状态的 IVR
   local dbh = freeswitch.Dbh("odbc://mydb:user:pass")

   session:answer()
   session:sleep(500)

   -- 收集订单号
   local order_id = session:playAndGetDigits(
       6, 10, 3, 10000, "#",
       "ivr/enter-order-number.wav",
       "ivr/ivr-invalid.wav",
       "order_id", "\\d+", 5000
   )

   if order_id and order_id ~= "" then
       -- 查询数据库
       local sql = string.format(
           "SELECT status, estimated_date FROM orders WHERE order_id = '%s'",
           order_id
       )

       dbh:query(sql, function(row)
           local status = row.status
           local est_date = row.estimated_date
           -- 使用 TTS 播报结果
           session:speak("Your order " .. order_id ..
                        " is currently " .. status ..
                        ". Estimated delivery date is " .. est_date)
       end)
   end

   dbh:release()


JavaScript 脚本实现 IVR
========================

FreeSWITCH 也支持通过 ``mod_v8`` 使用 JavaScript 编写 IVR：

.. code-block:: javascript

   // /usr/local/freeswitch/scripts/ivr_main.js

   var session = new Session();
   session.answer();
   session.sleep(1000);

   // 播放并收集输入
   var digits = session.playAndGetDigits(
       1, 1, 3, 5000, "#",
       "ivr/ivr-menu.wav",
       "ivr/ivr-invalid.wav",
       "input", "\\d"
   );

   switch (digits) {
       case "1":
           session.streamFile("ivr/ivr-transferring.wav");
           session.execute("transfer", "1001 XML default");
           break;
       case "2":
           session.streamFile("ivr/ivr-transferring.wav");
           session.execute("transfer", "1002 XML default");
           break;
       default:
           session.streamFile("ivr/ivr-exit.wav");
           session.hangup();
   }


TTS 集成
========================

FreeSWITCH 支持多种 TTS（Text-to-Speech）引擎：

mod_flite
-----------

``mod_flite`` 是基于 CMU Flite 的轻量级 TTS 引擎，适合英文语音合成：

.. code-block:: bash

   # 确保模块已加载
   load mod_flite

在 Dialplan 中使用：

.. code-block:: xml

   <action application="speak"
           data="flite|slt|Welcome to our service. Please press 1 for sales."/>

mod_tts_commandline
---------------------

``mod_tts_commandline`` 允许调用外部 TTS 命令行工具，灵活性最高：

.. code-block:: xml

   <!-- conf/autoload_configs/tts_commandline.conf.xml -->
   <configuration name="tts_commandline.conf" description="TTS Commandline">
     <settings>
       <param name="command"
              value="tts_tool --voice ${voice} --text '${text}' --output ${file}"/>
     </settings>
   </configuration>

集成第三方 TTS 服务（如百度、讯飞、阿里云等中文 TTS）：

.. code-block:: xml

   <configuration name="tts_commandline.conf" description="TTS Commandline">
     <settings>
       <param name="command"
              value="python3 /opt/scripts/aliyun_tts.py '${text}' ${file}"/>
     </settings>
   </configuration>

在 Lua 脚本中使用 TTS：

.. code-block:: lua

   session:set_tts_params("flite", "slt")
   session:speak("Hello, welcome to our automated service.")

   -- 或使用 tts_commandline
   session:set_tts_params("tts_commandline", "default")
   session:speak("您好，欢迎致电客服中心。")


ASR 集成
========================

ASR（Automatic Speech Recognition，自动语音识别）使 IVR 系统能够理解用户的语音输入，
而不仅仅依赖 DTMF 按键。

FreeSWITCH 支持通过以下方式集成 ASR：

mod_pocketsphinx
------------------

``mod_pocketsphinx`` 是基于 CMU PocketSphinx 的离线语音识别模块：

.. code-block:: xml

   <action application="play_and_detect_speech"
           data="ivr/ivr-say-name.wav
                 detect:pocketsphinx {start-input-timers=false}
                 builtin:grammar/boolean.gram"/>


MRCP 协议支持
========================

MRCP（Media Resource Control Protocol）是用于控制语音处理资源（如 TTS 和 ASR）的标准协议。
FreeSWITCH 通过 ``mod_unimrcp`` 模块支持 MRCPv2 协议。

安装和配置 mod_unimrcp
------------------------

.. code-block:: xml

   <!-- conf/autoload_configs/unimrcp.conf.xml -->
   <configuration name="unimrcp.conf" description="UniMRCP">
     <settings>
       <param name="default-tts-profile" value="mrcp-tts"/>
       <param name="default-asr-profile" value="mrcp-asr"/>
       <param name="log-level" value="DEBUG"/>
     </settings>

     <profiles>
       <profile name="mrcp-tts" version="2">
         <param name="server-ip" value="192.168.1.100"/>
         <param name="server-port" value="8060"/>
         <param name="resource-location" value=""/>
         <param name="speechsynth" value="speechsynthesizer"/>
         <param name="rtp-ip" value="192.168.1.50"/>
         <param name="rtp-port-min" value="4000"/>
         <param name="rtp-port-max" value="5000"/>
       </profile>

       <profile name="mrcp-asr" version="2">
         <param name="server-ip" value="192.168.1.100"/>
         <param name="server-port" value="8060"/>
         <param name="resource-location" value=""/>
         <param name="speechrecog" value="speechrecognizer"/>
         <param name="rtp-ip" value="192.168.1.50"/>
         <param name="rtp-port-min" value="4000"/>
         <param name="rtp-port-max" value="5000"/>
       </profile>
     </profiles>
   </configuration>

使用 MRCP TTS：

.. code-block:: xml

   <action application="speak"
           data="unimrcp:mrcp-tts|default|您好，请说出您要查询的业务。"/>

使用 MRCP ASR：

.. code-block:: xml

   <action application="play_and_detect_speech"
           data="ivr/ivr-speak-now.wav
                 detect:unimrcp {start-input-timers=false}
                 builtin:grammar/digits.gram"/>


语音信箱（mod_voicemail）
=========================

``mod_voicemail`` 提供了完整的语音信箱功能：

.. code-block:: xml

   <!-- 进入语音信箱 -->
   <extension name="voicemail">
     <condition field="destination_number" expression="^\*98$">
       <action application="answer"/>
       <action application="sleep" data="500"/>
       <action application="voicemail"
               data="check default ${domain_name} ${caller_id_number}"/>
     </condition>
   </extension>

   <!-- 无人接听时转语音信箱 -->
   <extension name="local-extension">
     <condition field="destination_number" expression="^(1\d{3})$">
       <action application="set" data="call_timeout=30"/>
       <action application="set"
               data="hangup_after_bridge=true"/>
       <action application="bridge"
               data="user/$1@${domain_name}"/>
       <!-- 无人接听时 -->
       <action application="answer"/>
       <action application="voicemail"
               data="default ${domain_name} $1"/>
     </condition>
   </extension>


呼叫队列与 ACD
========================

FreeSWITCH 通过 ``mod_fifo`` 和 ``mod_callcenter`` 实现呼叫队列和 ACD（Automatic Call Distribution）功能。

mod_callcenter 配置
---------------------

.. code-block:: xml

   <!-- conf/autoload_configs/callcenter.conf.xml -->
   <configuration name="callcenter.conf" description="CallCenter">
     <settings>
       <param name="odbc-dsn" value="pgsql://host=localhost dbname=freeswitch"/>
     </settings>

     <queues>
       <queue name="support@default">
         <param name="strategy" value="ring-all"/>
         <param name="moh-sound"
                value="$${hold_music}"/>
         <param name="time-base-score" value="system"/>
         <param name="max-wait-time" value="0"/>
         <param name="max-wait-time-with-no-agent" value="120"/>
         <param name="tier-rules-apply" value="false"/>
         <param name="record-template"
                value="/var/recordings/${strftime(%Y%m%d)}/${uuid}.wav"/>
       </queue>
     </queues>

     <agents>
       <agent name="agent001"
              type="callback"
              contact="user/1001@default"
              status="Available"
              max-no-answer="3"
              wrap-up-time="10"
              reject-delay-time="10"
              busy-delay-time="60"/>
       <agent name="agent002"
              type="callback"
              contact="user/1002@default"
              status="Available"
              max-no-answer="3"
              wrap-up-time="10"/>
     </agents>

     <tiers>
       <tier agent="agent001" queue="support@default" level="1" position="1"/>
       <tier agent="agent002" queue="support@default" level="1" position="2"/>
     </tiers>
   </configuration>

ACD 分配策略包括：

.. list-table:: ACD 分配策略
   :header-rows: 1
   :widths: 25 75

   * - 策略
     - 说明
   * - ring-all
     - 同时振铃所有空闲坐席
   * - longest-idle-agent
     - 分配给空闲时间最长的坐席
   * - round-robin
     - 轮询分配
   * - top-down
     - 按优先级从高到低分配
   * - agent-with-least-talk-time
     - 分配给通话时间最少的坐席
   * - agent-with-fewest-calls
     - 分配给接听次数最少的坐席
   * - sequentially-by-agent-order
     - 按坐席顺序依次分配
   * - random
     - 随机分配


示例：构建完整的 IVR 菜单
=========================

以下是一个完整的客服 IVR 系统示例，使用 Lua 脚本实现：

.. code-block:: lua

   -- /usr/local/freeswitch/scripts/customer_service_ivr.lua

   -- 工具函数：安全地播放并收集输入
   function safe_collect(session, prompt, min, max, tries, timeout)
       if not session:ready() then return nil end
       return session:playAndGetDigits(
           min, max, tries, timeout, "#",
           prompt, "ivr/ivr-invalid.wav",
           "input", "\\d+", 5000
       )
   end

   -- 主流程
   session:answer()
   session:sleep(500)

   -- 语言选择
   local lang = safe_collect(session,
       "ivr/ivr-language-select.wav", 1, 1, 2, 8000)

   if lang == "1" then
       session:setVariable("tts_voice", "slt")  -- English
   else
       session:setVariable("tts_voice", "default")  -- Chinese
   end

   -- 主菜单
   local running = true
   while session:ready() and running do
       local choice = safe_collect(session,
           "ivr/ivr-main-menu.wav", 1, 1, 3, 10000)

       if choice == "1" then
           -- 账户查询
           local account = safe_collect(session,
               "ivr/enter-account.wav", 6, 12, 3, 15000)
           if account then
               -- 查询并播报账户信息
               session:execute("set", "account_id=" .. account)
               session:execute("lua", "query_account.lua")
           end
       elseif choice == "2" then
           -- 技术支持队列
           session:streamFile("ivr/ivr-please-hold.wav")
           session:execute("callcenter", "support@default")
           running = false
       elseif choice == "3" then
           -- 留言
           session:execute("voicemail",
               "default ${domain_name} support")
           running = false
       elseif choice == "0" then
           -- 转人工
           session:streamFile("ivr/ivr-transferring.wav")
           session:transfer("operator", "XML", "default")
           running = false
       else
           session:streamFile("ivr/ivr-exit.wav")
           running = false
       end
   end

   session:hangup()


参考资料
========================

* FreeSWITCH mod_ivr 文档: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Modules/mod-ivr/
* FreeSWITCH mod_callcenter: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Modules/mod_callcenter_1049389/
* FreeSWITCH Lua API: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Languages/Lua/
* UniMRCP 项目: https://www.unimrcp.org/
* FreeSWITCH mod_voicemail: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Modules/mod_voicemail_6587070/
