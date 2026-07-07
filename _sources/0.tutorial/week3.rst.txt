################################
第三周：音视频处理
################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==============================
**摘要**     WebRTC 简明教程 · 第三周
**作者**     Walter Fan
**状态**     持续更新中
**更新日期** |date|
============ ==============================

.. contents::
    :local:

学习目标
==========================

本周结束后，你应该能够：

- ✅ 理解音频编解码器（Opus/G.711）的基本原理
- ✅ 了解音频处理流水线（AEC/AGC/ANS/VAD）
- ✅ 掌握视频编解码器（H.264/VP8/AV1）的核心概念
- ✅ 理解 Simulcast 和 SVC 的多流机制

.. tip::

   本周同时涉及音频和视频两大领域，信息量较大。建议先抓住核心脉络（编解码原理、处理流水线、多流机制），
   再根据兴趣深入某个方向。初学者可以把本周拉长到两周，分别聚焦音频和视频。


每日计划
==========================

Day 1：音频基础与编解码
--------------------------

**目标**：理解数字音频和语音编解码的基本原理

**学习内容**：

- 声音的物理特性：频率、振幅、采样率、位深
- PCM 编码和常见音频格式
- 语音编解码器概览：G.711、G.722、Opus
- Opus 编解码器详解 — WebRTC 的默认音频编解码器

**动手练习**：

- 用 FFmpeg 查看一个音频文件的编码信息：``ffmpeg -i audio.wav``
- 用 SoX 生成不同频率的测试音频

**学习提示**：

- 把采样率、位深、码率和实际听感联系起来理解
- 重点了解 Opus 为什么是 WebRTC 的首选音频编解码器

**参考阅读**：:doc:`../3.audio/audio_basic` · :doc:`../3.audio/audio_codec_overview` · :doc:`../3.audio/audio_codec_opus` · :doc:`../3.audio/audio_codec_g711`


Day 2：音频处理流水线
--------------------------

**目标**：了解 WebRTC 的音频处理模块

**学习内容**：

- 回声消除（AEC）— 消除扬声器到麦克风的回声
- 自动增益控制（AGC）— 自动调节音量
- 噪声抑制（ANS）— 过滤背景噪声
- 语音活动检测（VAD）— 判断是否有人在说话
- 音频电平（Audio Level）

**动手练习**：

- 在 ``getUserMedia`` 的约束中开启/关闭 AEC、AGC、ANS，对比效果
- 用 Web Audio API 实现一个简单的音量指示器

**学习提示**：

- 这些模块的效果适合亲自"听"差异，比纯看文档收获更大
- 理解这些处理发生在采集之后、编码之前

**参考阅读**：:doc:`../3.audio/audio_process` · :doc:`../3.audio/audio_aec` · :doc:`../3.audio/audio_agc` · :doc:`../3.audio/audio_ans` · :doc:`../3.audio/audio_vad` · :doc:`../3.audio/audio_level`


Day 3：Web Audio API
--------------------------

**目标**：掌握浏览器中的音频处理能力

**学习内容**：

- Web Audio API 的节点图模型
- AudioWorklet — 自定义音频处理
- 音频分析和可视化
- 音频质量评估方法

**动手练习**：

- 用 Web Audio API 实现一个音频频谱可视化
- 用 AudioWorklet 实现一个简单的音频效果（如变声）

**参考阅读**：:doc:`../3.audio/audio_api` · :doc:`../3.audio/audio_worklet` · :doc:`../3.audio/audio_analysis` · :doc:`../3.audio/audio_quality`


Day 4：视频基础与编解码
--------------------------

**目标**：理解视频编解码的核心概念

**学习内容**：

- 视频基础：分辨率、帧率、色彩空间（YUV）
- 视频压缩原理：帧内预测、帧间预测、变换编码
- H.264/AVC — 最广泛使用的视频编解码器
- VP8/VP9 和 AV1 — 开源编解码器

**动手练习**：

- 用 FFmpeg 查看视频的编码信息和关键帧分布
- 用不同编码参数压缩同一个视频，对比质量和大小

**学习提示**：

- 理解分辨率、帧率、码率三者之间的权衡关系
- WebRTC 场景中低延迟往往比极致画质更重要

**参考阅读**：:doc:`../4.video/video_basic` · :doc:`../4.video/yuv` · :doc:`../4.video/video_codec` · :doc:`../4.video/video_codec_h264` · :doc:`../4.video/video_codec_av1`


Day 5：视频处理与多流
--------------------------

**目标**：掌握 WebRTC 的视频处理和多流技术

**学习内容**：

- 视频处理流水线
- 视频自适应（分辨率和帧率调整）
- Simulcast — 同时发送多个分辨率的视频流
- SVC（Scalable Video Coding）— 可伸缩视频编码
- 时域可伸缩性（Temporal Scalability）

**动手练习**：

- 在 ``RTCPeerConnection`` 中配置 Simulcast
- 观察不同网络条件下的视频质量切换

**学习提示**：

- Simulcast 和 SVC 是多人会议场景的关键技术，理解它们能帮助你更好地理解第四周的 SFU 架构

**参考阅读**：:doc:`../4.video/video_pipeline` · :doc:`../4.video/video_adaptation` · :doc:`../4.video/webrtc_simulcast` · :doc:`../4.video/webrtc_svc` · :doc:`../4.video/webrtc_temporal_scalability`


Day 6-7：实战 — 带特效的视频通话
--------------------------------------

**目标**：完成本周的里程碑项目 🎯

**实战任务**：

在第一周的 P2P 视频通话基础上，加入媒体处理能力：

1. 用 Canvas API 对视频帧添加实时滤镜（如灰度、模糊、美颜）
2. 用 Insertable Streams 或 Web Codecs 处理编码后的媒体数据
3. 实现屏幕共享 + 摄像头画中画
4. （可选）用 AudioWorklet 实现变声功能

**参考阅读**：:doc:`../4.video/insertable_stream` · :doc:`../4.video/web_codec` · :doc:`../4.video/webrtc_sharing`

**检查清单**：

- [ ] 能对本地视频添加实时滤镜
- [ ] 滤镜效果能传输给对方
- [ ] 能在视频通话中切换屏幕共享
- [ ] 理解 Insertable Streams 的工作原理

.. tip::

   如果时间有限，优先完成 Canvas 滤镜（最容易看到效果），其余作为进阶练习。


常见卡点
==========================

**现象：概念太多，混淆"编码"、"处理"、"渲染"**

- 把媒体链路分为四段理解：采集 → 处理 → 编码 → 传输
- 弄清楚你的操作发生在哪一段

**现象：编解码文档太深**

- 第一轮重点理解为什么需要压缩、分辨率/帧率/码率如何权衡
- 编码算法细节（运动估计、变换编码等）可以作为进阶内容

**现象：Simulcast 配置困难**

- 先理解 Simulcast 的概念和使用场景
- 实际配置可以参照现成示例，在第四周的 SFU 实战中再深入实践


详细参考
==========================

本周的学习内容对应手册的 :doc:`../3.audio/index` 和 :doc:`../4.video/index` 章节：

**音频技术**

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - 主题
     - 说明
   * - :doc:`../3.audio/audio_basic`
     - 音频基础知识
   * - :doc:`../3.audio/audio_codec_overview`
     - 语音编解码器概览
   * - :doc:`../3.audio/audio_codec_opus`
     - Opus 编解码器
   * - :doc:`../3.audio/audio_process`
     - 音频处理流水线
   * - :doc:`../3.audio/audio_aec`
     - 回声消除
   * - :doc:`../3.audio/audio_agc`
     - 自动增益控制
   * - :doc:`../3.audio/audio_ans`
     - 噪声抑制
   * - :doc:`../3.audio/audio_api`
     - Web Audio API
   * - :doc:`../3.audio/audio_worklet`
     - AudioWorklet

**视频技术**

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - 主题
     - 说明
   * - :doc:`../4.video/video_basic`
     - 视频基础知识
   * - :doc:`../4.video/video_codec`
     - 视频编解码概览
   * - :doc:`../4.video/video_codec_h264`
     - H.264 编解码器
   * - :doc:`../4.video/video_pipeline`
     - 视频处理流水线
   * - :doc:`../4.video/webrtc_simulcast`
     - Simulcast 多流
   * - :doc:`../4.video/webrtc_svc`
     - SVC 可伸缩编码
   * - :doc:`../4.video/insertable_stream`
     - Insertable Streams
   * - :doc:`../4.video/web_codec`
     - Web Codecs
