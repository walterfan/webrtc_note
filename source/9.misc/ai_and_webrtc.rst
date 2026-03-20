##################################
AI 对 WebRTC 技术发展的影响
##################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

概述
==========

人工智能（AI）正在深刻改变实时通信领域。从音视频质量增强到智能网络自适应，从虚拟背景到实时翻译，
AI 技术与 WebRTC 的融合正在催生全新的应用场景和技术范式。本文梳理 AI 在 WebRTC 各个层面的影响和应用。


音频处理中的 AI
===================

传统的音频处理依赖于信号处理算法（如 Wiener 滤波、自适应滤波），而 AI 带来了质的飞跃。

AI 降噪 (AI-based Noise Suppression)
-----------------------------------------

传统的 ANS（Adaptive Noise Suppression）基于统计模型估计噪声谱，对非平稳噪声（如键盘声、狗叫）效果有限。
基于深度学习的降噪模型可以在频域或时域上直接学习语音与噪声的分离：

- **RNNoise**: Mozilla 开源的基于 RNN 的降噪库，模型仅 85KB，可在浏览器中实时运行
- **DTLN (Dual-Signal Transformation LSTM Network)**: 双路 LSTM 网络，分别在 STFT 域和时域处理
- **PercepNet**: Google 提出的感知网络，结合传统 DSP 和深度学习，已集成到 WebRTC M94+
- **Krisp / NVIDIA Maxine**: 商业级 AI 降噪方案

WebRTC 中的集成方式：

.. code-block:: javascript

   // 使用 Web Audio API + AudioWorklet 集成 AI 降噪
   const audioContext = new AudioContext();
   await audioContext.audioWorklet.addModule('ai-denoise-processor.js');

   const source = audioContext.createMediaStreamSource(stream);
   const denoiseNode = new AudioWorkletNode(audioContext, 'ai-denoise');
   const destination = audioContext.createMediaStreamDestination();

   source.connect(denoiseNode).connect(destination);

   // 使用处理后的流进行 WebRTC 通话
   const processedStream = destination.stream;
   peerConnection.addTrack(processedStream.getAudioTracks()[0], processedStream);

AI 回声消除 (AI-based AEC)
-------------------------------

Google 在 WebRTC M125 中引入了基于神经网络的 AEC3 增强模块，相比传统自适应滤波器：

- 对非线性失真的处理能力更强
- 在双讲（double-talk）场景下表现更好
- 对延迟变化的鲁棒性更高


视频处理中的 AI
===================

虚拟背景与人像分割
-----------------------

这是 AI 在 WebRTC 中最广泛的应用之一。核心技术是 **语义分割（Semantic Segmentation）**：

- **MediaPipe Selfie Segmentation**: Google 开源，基于 MobileNetV3，可在浏览器中以 30fps 运行
- **BodyPix**: TensorFlow.js 模型，支持人体部位分割
- **背景替换/模糊**: 将分割 mask 应用于视频帧，替换或模糊背景

.. code-block:: javascript

   // 使用 MediaPipe 进行背景分割
   import { SelfieSegmentation } from '@mediapipe/selfie_segmentation';

   const segmentation = new SelfieSegmentation({
     locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/selfie_segmentation/${file}`
   });

   segmentation.setOptions({ modelSelection: 1 }); // 0: general, 1: landscape
   segmentation.onResults((results) => {
     // results.segmentationMask 是分割掩码
     drawWithBackground(results.image, results.segmentationMask, backgroundImage);
   });

AI 超分辨率 (Super Resolution)
-----------------------------------

在网络带宽受限时，发送端可以降低分辨率以减少码率，接收端使用 AI 模型恢复高分辨率画面：

- **NVIDIA Video Super Resolution**: 基于 RTX GPU 的实时超分
- **Real-ESRGAN**: 开源超分模型，可通过 WebGPU/WebNN 在浏览器中运行
- **Google Project Starline**: 结合 AI 超分和 3D 重建的沉浸式通信

这种方案可以在相同带宽下提升 **感知质量 30-50%**。

AI 视频编码优化
-------------------

AI 正在改变视频编码的多个环节：

- **感知质量优化**: 使用 CNN 预测人眼关注区域（ROI），对关注区域分配更多码率
- **帧内预测**: 用神经网络替代传统的角度预测模式
- **码率控制**: 基于强化学习的自适应码率控制，比传统 PID 控制器更精准
- **端到端神经视频编码**: 如 Google 的 SoundStream 和 Lyra（音频），未来可能扩展到视频


网络自适应中的 AI
======================

拥塞控制
-----------

WebRTC 的 GCC（Google Congestion Control）算法基于延迟梯度和丢包率估计带宽。
AI 可以显著提升拥塞控制的性能：

- **Reinforcement Learning based CC**: 使用 RL 代理替代传统的状态机，
  根据网络状态（RTT、丢包率、抖动）动态调整发送码率
- **OnRL (Online Reinforcement Learning)**: 微软研究院提出，在线学习网络特征
- **Loki**: Facebook 提出的基于 RL 的 ABR（Adaptive Bitrate）算法

.. code-block:: text

   传统 GCC 流程:
   延迟梯度 → Kalman 滤波 → 过载检测器 → AIMD 码率调整

   AI 增强流程:
   [RTT, 丢包率, 抖动, 队列延迟, 吞吐量] → 神经网络 → 最优码率决策

带宽预测
-----------

基于 LSTM/Transformer 的时序预测模型可以提前预测网络带宽变化：

- 预测未来 1-5 秒的可用带宽
- 提前调整编码参数，避免突发拥塞
- Google 已在 WebRTC 中实验性集成了基于 ML 的带宽预测模块


AI 驱动的新应用场景
=========================

实时翻译与字幕
-----------------

结合 ASR（Automatic Speech Recognition）和 NMT（Neural Machine Translation）：

1. 发送端语音 → ASR 转文字（如 Whisper、Conformer）
2. 文字 → NMT 翻译（如 NLLB、GPT）
3. 翻译文字 → TTS 合成语音（如 VITS、Bark）或显示字幕

WebRTC DataChannel 可用于传输文字和翻译结果，延迟可控制在 1-3 秒内。

.. code-block:: javascript

   // 使用 Web Speech API + DataChannel 实现实时字幕
   const recognition = new webkitSpeechRecognition();
   recognition.continuous = true;
   recognition.interimResults = true;
   recognition.lang = 'zh-CN';

   recognition.onresult = (event) => {
     const transcript = event.results[event.results.length - 1][0].transcript;
     // 通过 DataChannel 发送给对方
     dataChannel.send(JSON.stringify({
       type: 'subtitle',
       text: transcript,
       isFinal: event.results[event.results.length - 1].isFinal
     }));
   };

数字人与虚拟形象
-------------------

AI 生成的数字人（Digital Human）正在改变视频通信的形态：

- **面部驱动**: 通过摄像头捕捉面部表情，驱动 3D/2D 虚拟形象
- **语音驱动**: 仅通过语音即可驱动虚拟形象的口型和表情（Audio2Face）
- **带宽优势**: 只需传输面部关键点数据（~几KB/s），而非完整视频流（~几Mbps）

这种方案可以将视频通话带宽降低 **99%** 以上。

智能会议助手
-----------------

AI + WebRTC 在会议场景的应用：

- **说话人识别（Speaker Diarization）**: 自动识别谁在说话，生成带说话人标签的会议纪要
- **会议摘要**: 实时生成会议要点和 Action Items
- **智能降噪与增强**: 根据会议场景自动调整音频处理参数
- **手势识别**: 识别举手、点赞等手势，转化为会议交互


AI 推理的部署架构
======================

在 WebRTC 系统中部署 AI 模型有三种主要架构：

.. list-table:: AI 推理部署方式对比
   :header-rows: 1
   :widths: 20 30 25 25

   * - 部署方式
     - 优势
     - 劣势
     - 适用场景
   * - **客户端推理**
     - 低延迟、保护隐私
     - 受限于设备算力
     - 降噪、背景分割
   * - **边缘服务器推理**
     - 算力充足、延迟可控
     - 需要额外基础设施
     - 超分辨率、翻译
   * - **云端推理**
     - 算力无限、模型灵活
     - 延迟较高
     - 会议摘要、内容分析

浏览器端 AI 推理的关键技术栈：

- **WebAssembly (WASM)**: 运行 C/C++ 编译的推理引擎
- **WebGPU**: 利用 GPU 加速推理（替代 WebGL）
- **WebNN (Web Neural Network API)**: W3C 标准，直接调用硬件 AI 加速器
- **ONNX Runtime Web**: 跨平台模型推理框架
- **TensorFlow.js / MediaPipe**: Google 的浏览器端 ML 框架


未来展望
==========

AI 与 WebRTC 的融合正在加速，以下趋势值得关注：

1. **端到端神经编解码器**: 完全基于神经网络的音视频编解码，可能在 5 年内成熟
2. **语义通信（Semantic Communication）**: 不再传输像素/采样点，而是传输语义信息，带宽需求可降低 1-2 个数量级
3. **AI 原生的传输协议**: 针对 AI 数据流（如 embedding、关键点）优化的传输协议
4. **多模态实时交互**: 结合视觉、语音、手势、眼动的沉浸式通信
5. **隐私保护的联邦学习**: 在不共享原始数据的前提下，跨设备协同优化通信质量

.. note::

   AI 技术的引入也带来了新的挑战：模型大小与推理延迟的平衡、不同设备的算力差异、
   AI 生成内容的真实性验证（Deepfake 检测）、以及隐私保护等问题都需要持续关注。


参考资料
==========

- `RNNoise: Learning Noise Suppression <https://jmvalin.ca/demo/rnnoise/>`_
- `MediaPipe Solutions <https://developers.google.com/mediapipe>`_
- `WebNN API Specification <https://www.w3.org/TR/webnn/>`_
- `Reinforcement Learning for Real-Time Communications (Microsoft) <https://www.microsoft.com/en-us/research/project/reinforcement-learning-for-real-time-communications/>`_
- `Google AI Blog: Project Starline <https://blog.google/technology/research/project-starline/>`_
