###############
Audio QoS
###############

.. contents::
   :local:

Overview
===============
Audio Quality of Service (QoS) refers to the techniques and mechanisms used to ensure that audio data is transmitted and delivered with consistent and reliable quality, especially in real-time communication applications. Here are some steps to implement Audio QoS:

1. Identify QoS requirements: Determine the specific quality parameters that are important for your audio application.

   This could include metrics such as latency, packet loss, jitter, and audio quality.

2. Prioritize audio traffic: Assign a higher priority to audio packets over other types of network traffic.

   This can be done by setting the appropriate Differentiated Services Code Point (DSCP) or Quality of Service (QoS) markings in the IP headers of the audio packets.

3. Traffic shaping and bandwidth allocation: Implement traffic shaping techniques to manage the flow of audio packets.

   This involves controlling the rate at which packets are transmitted to match the available bandwidth and minimize congestion. Allocate sufficient bandwidth to prioritize audio traffic and ensure a smooth and consistent audio stream.

4. Buffer management: Use a buffer to compensate for network delays and fluctuations.

   The buffer size should be carefully optimized to balance latency and jitter. A larger buffer can absorb variations in packet arrival times but introduces additional latency. Monitor the buffer occupancy and adjust its size dynamically based on network conditions.

5. Error resilience mechanisms:

   Implement error resilience techniques to handle packet loss or corruption. This can include forward error correction (FEC), where redundant data is added to the audio packets to enable recovery from lost or damaged packets. Retransmission mechanisms can also be employed to request retransmission of lost packets.

6. Congestion control:

   Use congestion control mechanisms to prevent network congestion and ensure the smooth transmission of audio packets. This can involve techniques such as congestion window management, packet pacing, or adaptive bitrate control.

7. Network monitoring and measurement:

   Continuously monitor the network conditions and measure key QoS parameters such as latency, packet loss, and jitter. Use this information to adapt the QoS mechanisms and optimize the audio transmission.

8. Quality assessment and feedback:

   Implement mechanisms to assess the perceived audio quality at the receiver's end. This can involve techniques such as calculating the Mean Opinion Score (MOS) or using objective quality metrics like the Perceptual Evaluation of Speech Quality (PESQ). Use the quality assessment results to provide feedback and make further improvements to the QoS mechanisms.

9.  Test and optimize:

    Thoroughly test your Audio QoS implementation under various network conditions to ensure its effectiveness and reliability. Measure and fine-tune parameters such as buffer size, traffic shaping algorithms, and error resilience mechanisms.

10.  Interoperability and standards compliance:

    Ensure that your implementation complies with relevant audio and network standards to ensure compatibility and interoperability with other systems and devices.



3A
===============

AGC
---------------

语音增强是为了解决噪声污染干扰的一种预处理手段。
理论基础是语音特性，噪声特性以及人耳的感知特性。


AEC
---------------

回声抵消

回声有

* 电学回声（线路回声）： 标准方法为  G.165
* 声学回声: 延时长，噪声干扰严重，语音信号动态范围大


线路回声抵消
~~~~~~~~~~~~~~~~~


声学回声抵消
~~~~~~~~~~~~~~~~~

方法有

1. 麦克风阵列
2. 频移的方法
3. 回声抑制器


ANS
---------------

`Noise reduction`_ is the process of removing noise from a signal.

Audio noise reduction is for audio noise.

Noise reduction techniques exist for audio and images. Noise reduction algorithms may distort the signal to some degree.


.. _Noise reduction: https://en.wikipedia.org/wiki/Noise_reduction

差错检测与恢复
================

纠错码
* 线性分组码
* 卷积码
* Turbo 码
* RS 码
* RCPC 码
* LDPC 码


抗丢包方案
------------------------

1. 语音算法本身的丢包健壮性
2. 多描述语音编码 MDSC(Multiple Description Speech Coding)
3. 滑动窗算法
4. 交织及前身纠错技术
5. 丢包隐藏技术


Audio PLC
------------------------
For the most part, audio packets are decoded frame-by-frame and usually also packet-by-packet.
If one is lost, we can try various ways to solve that. There are the most common approaches:

* Play nothing, causing ugly robotic/metallic tint to the audio
* Duplicate the previous audio frame, sometimes reducing its volume level
* Try to predict what the lost frame sounds like.
  Today, using machine learning, maybe with something like Google’s proprietary WaveNetEQ algorithm
