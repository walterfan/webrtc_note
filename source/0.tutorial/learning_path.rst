######################
学习路线图
######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**摘要**     WebRTC 四周学习路线图
**作者**     Walter Fan
**状态**     持续更新中
**更新日期** |date|
============ ==========================

.. contents::
   :local:

总体规划
=======================================

四周时间，从零到能独立搭建一个多人视频会议系统。听起来像不可能的任务？
咱们一步一步来，每周聚焦一个主题，完全可以做到。

.. tip::

   这份计划为有前端或网络基础的工程师设计，每天投入 1~2 小时、4 周可以完成。
   如果你是纯初学者或者每周时间有限，请不要强行压缩——把计划拉长到 8~12 周，循序渐进效果更好。

.. list-table:: 四周学习计划总览
   :header-rows: 1
   :widths: 10 20 35 35

   * - 周次
     - 主题
     - 核心内容
     - 实践目标
   * - 第一周
     - 🟢 基础入门
     - WebRTC API、信令、SDP、媒体捕获
     - 完成一个 P2P 视频通话
   * - 第二周
     - 🟡 传输协议
     - ICE/STUN/TURN、DTLS/SRTP、RTP/RTCP、DataChannel
     - 用 Wireshark 分析 WebRTC 数据包
   * - 第三周
     - 🔵 音视频处理
     - 音频编解码与处理、视频编解码与处理、Simulcast/SVC
     - 实现一个带滤镜的视频通话
   * - 第四周
     - 🔴 QoS 与实践
     - 拥塞控制、FEC/NACK、Jitter Buffer、SFU 架构
     - 搭建一个多人会议系统


建议节奏
=======================================

不同基础的读者可以选择不同的学习节奏：

.. list-table:: 三种推荐节奏
   :header-rows: 1
   :widths: 16 18 28 38

   * - 节奏
     - 每周投入
     - 适合谁
     - 预计完成时间
   * - 冲刺版
     - 8~12 小时
     - 有前端 + 网络基础的工程师
     - 4 周完成全部内容
   * - 标准版
     - 4~8 小时
     - 第一次接触 WebRTC 的开发者
     - 6~8 周完成全部内容
   * - 渐进版
     - 2~4 小时
     - 需要边学边补基础的同学
     - 10~16 周循序渐进完成

无论选择哪种节奏，教程内容和目标不变。初学者只是需要更多时间消化和练习。


学习优先级
=======================================

以下是各主题的优先级建议，帮助你在时间有限时合理取舍：

.. list-table::
   :header-rows: 1
   :widths: 18 28 54

   * - 优先级
     - 主题
     - 说明
   * - 核心
     - ``getUserMedia``、``RTCPeerConnection``、信令、SDP、ICE
     - 跑通最小 Demo 的必备知识
   * - 核心
     - ``chrome://webrtc-internals``、``getStats()``
     - 排查问题的基本工具
   * - 重要
     - RTP/RTCP、DTLS/SRTP、DataChannel、编解码基础
     - 理解传输和媒体层的关键协议
   * - 进阶
     - AudioWorklet、Insertable Streams、Simulcast、SVC
     - 媒体处理高级能力，时间充裕时深入
   * - 深入
     - GCC/TWCC 算法、NetEQ、源码级分析
     - 中级开发者的进阶方向


每日学习节奏
=======================================

推荐的每日学习节奏（1~2 小时）：

1. **阅读理论** (30 分钟) — 阅读对应章节的文档
2. **动手实践** (30 分钟) — 跑示例代码，修改参数看效果
3. **总结复习** (15 分钟) — 记录关键概念和遇到的问题
4. **拓展阅读** (可选) — 查阅 RFC 或 MDN 文档深入了解

如果你是初学者，建议在实践环节多花时间，确保每天有一个可运行的结果。


每周完成标准
=======================================

建议每周用以下三个标准自检：

.. list-table::
   :header-rows: 1
   :widths: 18 82

   * - 标准
     - 说明
   * - 看得见
     - 你能看到一个具体结果：本地预览、远端视频、统计曲线、抓包结果
   * - 说得清
     - 你能用自己的话解释本周核心概念的作用和关系
   * - 查得到
     - 遇到问题时，你知道先看哪个工具、哪段日志、哪个抓包过滤器


技术栈全景图
=======================================

.. mermaid::

   graph TB
     subgraph 应用层
       A1[WebRTC API]
       A2[信令 Signaling]
       A3[SDP Offer/Answer]
     end

     subgraph 媒体层
       M1[音频编解码<br/>Opus/G.711]
       M2[视频编解码<br/>H.264/VP8/AV1]
       M3[音频处理<br/>AEC/AGC/ANS]
       M4[视频处理<br/>Simulcast/SVC]
     end

     subgraph 传输层
       T1[RTP/RTCP]
       T2[DTLS/SRTP]
       T3[SCTP/DataChannel]
       T4[ICE/STUN/TURN]
     end

     subgraph QoS
       Q1[拥塞控制<br/>GCC/TWCC]
       Q2[丢包恢复<br/>FEC/NACK/RTX]
       Q3[Jitter Buffer]
     end

     A1 --> M1
     A1 --> M2
     A2 --> A3
     M1 --> T1
     M2 --> T1
     T1 --> T2
     T2 --> T4
     A1 --> T3
     T1 --> Q1
     Q1 --> Q2
     Q2 --> Q3


参考资源
=======================================

**官方文档**

- `WebRTC 1.0`_ — W3C WebRTC 规范
- `MDN WebRTC API`_ — Mozilla 开发者文档，最佳入门资料
- `Signaling and video calling`_ — MDN 信令教程

**推荐书籍**

- *WebRTC for the Curious* — 开源免费，讲解清晰（https://webrtcforthecurious.com）
- *Real-Time Communication with WebRTC* — O'Reilly 出版，适合系统学习

**实用工具**

- ``chrome://webrtc-internals`` — Chrome 内置的 WebRTC 调试工具
- 浏览器开发者工具 Console / Network — 第一时间看报错和信令请求
- Wireshark — 网络抓包分析
- FFmpeg — 音视频处理瑞士军刀

**开源项目**

- `Janus Gateway <https://janus.conf.meetecho.com/>`_ — 轻量级 WebRTC 服务器
- `Pion <https://github.com/pion/webrtc>`_ — Go 语言 WebRTC 实现
- `MediaSoup <https://mediasoup.org/>`_ — Node.js SFU 框架


遇到困难怎么办
=======================================

学习过程中遇到卡点是正常的，推荐的排查顺序：

1. 先确认这一步的输入是什么，输出应该是什么
2. 查看浏览器 Console、``chrome://webrtc-internals`` 或 Wireshark 抓包
3. 定位问题是在采集、信令、建连、传输还是渲染阶段
4. 最后再去补对应的协议细节

如果你是初学者，遇到某个主题一时理解不了，可以先标记跳过，继续下一步。等后面有了更多上下文再回头理解，往往会豁然开朗。
