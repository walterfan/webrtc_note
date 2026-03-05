##########################
Audio Process pipeline
##########################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Audio Process pipeline
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
===================

.. image:: ../_static/audio_basic_pipeline.png

WebRTC 的音频处理流水线是一条完整的端到端链路，从麦克风采集到扬声器播放，经历多个关键阶段。
整体流程如下：

::

  采集 → 预处理(AEC/AGC/ANS) → 编码 → RTP 打包 → 网络传输 → RTP 解包 → 解码 → 后处理 → 播放


音频采集
===================

音频采集由 ``AudioDeviceModule`` (ADM) 负责，它是平台相关的抽象层：

* **Windows**: 使用 WASAPI (Windows Audio Session API)
* **macOS/iOS**: 使用 Core Audio
* **Android**: 使用 OpenSL ES 或 AAudio
* **Linux**: 使用 ALSA 或 PulseAudio

采集参数通常为：采样率 48kHz 或 16kHz，单声道或双声道，每帧 10ms 的 PCM 数据。

.. code-block:: cpp

   // AudioDeviceModule 的核心接口
   class AudioDeviceModule {
     virtual int32_t RecordingIsAvailable(bool* available) = 0;
     virtual int32_t InitRecording() = 0;
     virtual int32_t StartRecording() = 0;
     // 通过回调将采集到的 PCM 数据传递给上层
     virtual int32_t RegisterAudioCallback(AudioTransport* cb) = 0;
   };


音频预处理 (APM)
===================

``AudioProcessing`` 模块 (APM) 是 WebRTC 音频质量的核心，包含以下子模块：

AEC - 回声消除
-----------------

Acoustic Echo Cancellation 用于消除扬声器播放的声音被麦克风重新采集所产生的回声。
WebRTC 提供了 AEC3 算法，基于自适应滤波器，通过估计回声路径来消除回声信号。

* 线性部分：使用自适应 FIR 滤波器估计回声路径
* 非线性部分：抑制残余回声
* 需要远端参考信号 (render signal) 作为输入

AGC - 自动增益控制
--------------------

Automatic Gain Control 自动调节音频信号的增益，使输出音量保持在合适的范围内。

* **AGC1**: 传统的模拟/数字增益控制
* **AGC2**: 基于 RNN 的自适应数字增益控制，效果更好

ANS - 噪声抑制
-----------------

Audio Noise Suppression 用于抑制背景噪声，如风扇声、键盘声等。

* 传统方法：基于频谱减法和维纳滤波
* 新方法：基于 RNN 的噪声抑制，在 WebRTC M87+ 中引入

.. code-block:: cpp

   // APM 配置示例
   AudioProcessing::Config config;
   config.echo_canceller.enabled = true;
   config.echo_canceller.mobile_mode = false;
   config.gain_controller2.enabled = true;
   config.noise_suppression.enabled = true;
   config.noise_suppression.level = NoiseSuppression::kHigh;

   auto apm = AudioProcessingBuilder().SetConfig(config).Create();


音频编码与解码
===================

WebRTC 支持多种音频编解码器：

* **Opus**: 默认编解码器，支持 6kbps~510kbps，适用于语音和音乐
* **G.711**: 传统电话编解码器 (PCMU/PCMA)，64kbps 固定码率
* **G.722**: 宽带语音编解码器，提供更好的语音质量

Opus 编解码器的关键特性：

* 支持 CBR 和 VBR 模式
* 支持 FEC (Forward Error Correction) 前向纠错
* 支持 DTX (Discontinuous Transmission) 不连续传输，在静音时降低码率
* 采样率支持 8kHz ~ 48kHz

.. code-block:: cpp

   // Opus 编码器配置
   AudioEncoderOpus::Config opus_config;
   opus_config.frame_size_ms = 20;
   opus_config.num_channels = 1;
   opus_config.bitrate_bps = 32000;
   opus_config.fec_enabled = true;
   opus_config.dtx_enabled = true;


网络传输
===================

编码后的音频数据通过 RTP/RTCP 协议传输：

* 每个 RTP 包通常包含 20ms 的音频数据
* RTCP 提供丢包率、RTT 等反馈信息
* NetEQ 模块在接收端负责抖动缓冲和丢包隐藏


音频后处理与播放
===================

接收端的处理流程：

1. **Jitter Buffer (NetEQ)**: 缓冲接收到的 RTP 包，平滑网络抖动
2. **解码**: 将压缩数据还原为 PCM
3. **丢包隐藏 (PLC)**: 对丢失的包进行插值补偿
4. **混音 (AudioMixer)**: 将多路音频流混合为一路输出
5. **播放**: 通过 ADM 将 PCM 数据送到扬声器

NetEQ 是 WebRTC 音频接收端的核心模块，它综合了 Jitter Buffer、解码器管理和 PLC 功能，
能够根据网络状况动态调整缓冲延迟，在低延迟和流畅播放之间取得平衡。


参考资料
===================
* WebRTC Audio Processing Module: https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/
* NetEQ: https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_coding/neteq/
