######################
Audio Level
######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============
**Abstract** Audio Level
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============



.. contents::
   :local:

概述
=====================
音频电平 Audio Level 就是指声音的高低，它主要是指声波的振幅，我们先了解几个概念

声压
-----------------

* 有效声压

.. math::
   :name: 有效声压

   p_x = \sqrt{ \frac{1}{T}  \sum_{n=1}^N x^2 \Delta t}

       = \sqrt{ \frac{1}{N\Delta t}  \sum_{n=1}^N x^2 \Delta t}

       = \sqrt{ \frac{1}{N}  \sum_{n=1}^N x^2}


声压级 SPL (Sound Press Level)
-------------------------------------

声音的有效声压与基准声压之比，取以10 为底的对数，再乘以 20， 即为声压级，基准声压为人耳所能听到的最小声音（20 :math:`\mu P_a` ）

* 声压级

.. math::
   :name: 声压级

    L_p = 20 lg \frac{p_e}{p_ref}


* -80分贝：核潜艇的麦克风在水下听到的100米外一只虾咀嚼食物的声音
* -30分贝：20英里外一个人的说话声
* 0分贝：10英尺（约3米）外一只蚊子在飞
* 10分贝：非常安静的房间
* 13分贝：灯泡的嗡嗡声
* 15分贝：1米外一根别针从1厘米的高度掉落下来的声音
* 20分贝：乡村的夜晚
* 30分贝：沙漠的夜晚
* 40-60分贝：正常谈话的声音
* 50-53分贝：洗衣机的工作声
* 60-80分贝：10米外经过的汽车
* 70分贝：10英尺（约3米）外的真空吸尘器；美国环保署认定的人类能忍受（不产生听力损失、睡眠障碍、焦虑、学习障碍等）的最大噪音
* 85分贝：长期作用下会引起听力损伤
* 90分贝：10英尺（约3米）外经过的公共汽车或卡车；食物搅拌机
* 100分贝：一般家用音响设备的最大音量
* 104-107分贝：开始引起疼痛的声音（在2750Hz的频率下）
* 110-140分贝：100米外的喷气式飞机引擎
* 116分贝：人体开始感觉到振动的声音（在低频率下）
* 120-130分贝：摇滚演唱会的最前排
* 127分贝：开始引起耳鸣的声音
* 128分贝：在8.2英尺（约2.5米）外测量到的人类最大的尖叫声
* 140分贝：即使声音时间很短，也会引起听力损伤
* 141分贝：开始引起恶心感觉的声音
* 168分贝：M1加兰德步枪在1米外开火
* 175.8分贝：250英尺（约75米）外1吨TNT炸药爆炸
* 192.8-194.7分贝：地球大气压理论上能传播的最大强度声音


度量单位
===============
分贝（dB）是十分之一贝尔（B）：1B = 10dB。1贝尔的两个功率量的比值是10:1，1贝尔的两个场量的比值是{\displaystyle {\sqrt {10}}:1}{\sqrt {10}}:1[1]。

使用分贝有很多便利之处：

* 分贝实际上是对数值，因此可以用常用的数量来表示非常大的比值，可以清楚地表示非常大的数量变化。
* 多部件系统的整体增益（如级联的放大器）可以直接用各部件的增益分贝相加而求得。不必把这些增益值相乘（例如log(A × B × C) = log(A) + log(B) + log(C)）。
* 人对强度的感知，如声音或者光照，更接近与强度的对数成正比而不是强度值本身，依据韦伯定理，因此分贝值可用于描述感知级别或级差。


dB与后缀的组合，指出计算比值时的参考值。例如dBm指示功率值与1毫瓦的比值的分贝数。

如果计算分贝时的参考值明确、确切地给出，那么分贝数值可以作为绝对量，如同被测量的功率量或者场量。例如，20dBm即为100毫瓦。

SI国际单位制不允许使用分贝与后缀的组合形式如dBm, dBu, dBA，等等[13]。但这种不遵从SI单位制的表示却广泛应用于很多场合。


dBV
------------
dB(VRMS) – voltage relative to 1 volt, regardless of impedance.

dB(VRMS) – 相对于 1 伏的电压，与阻抗无关。

这用于测量麦克风灵敏度，也用于指定 -10 dBV 的消费者线路电平，以降低相对于使用 +4 dBu 线路电平信号的设备的制造成本。

dBm
------------

dB(mW) – 相对于 1 毫瓦的功率。 在音频和电话中，dBm 通常以 600 Ω 阻抗为参考，对应于 0.775 伏或 775 毫伏的电压电平。


dB SPL
-------------

dB（声压级，sound pressure level）–在空气或其它气体中的声压，参考值为20微帕斯卡（μPa） = 2×10−5 Pa。

这是人能听到的最安静的声音。大致相当于3米外蚊子飞行的声音。经常被缩写为"dB"，这造成了很多误解以为"dB"是个有量纲的绝对单位。
对于水声或其它液体，参考值是 1 μPa。

1 帕斯卡的 RMS 声压对应于 94 dB SPL 的水平。

dBov
-----------

dB（过载，overload）–信号的幅值，参照于设备的最大在限幅（clipping）发生前的最大允许值。

对于人声来说，dBov 是以分贝表示的电平，参考值是人耳所能听到（忍受）的最大的声音。

一般来说， 我们用 0 dBov 来表示声音的最大值，我们所听到的声音是 -xx dBov (-127 < xx < 0), 比如著名的 Audacity 的界面

Audio Level
====================
RFC6464 中规定声音电平 audio level 以一字节扩展头的最低 7 个比特来表示，此字节的最高一位是一个标志位 "V"。

* 最低7位比特：表示 audio level 单位是 -dBov，其值从 0（最大声） 到 127（静音） ，代表着 dBov 的 0（最大声） 到 -127（静音）
* 最高1位比特：表示这个包否包含语音(voice activity), 如果在 SDP 协商中没有启用 “vad”(Voice Activity Detection) 语音活动检测，就忽略这个比特



Metrics
=================


audioLevel 
------------------------------------
type: double

Only exists for audio. Represents the audio level of the receiving track. For audio levels of tracks attached locally, see RTCAudioSourceStats instead.

The value is between 0..1 (linear), where 1.0 represents 0 dBov, 0 represents silence, and 0.5 represents approximately 6 dBSPL change in the sound pressure level from 0 dBov.

The audioLevel is averaged over some small interval, using the algorithm described under totalAudioEnergy. The interval used is implementation dependent.

totalAudioEnergy 
------------------------------------
type: double

Only exists for audio. Represents the audio energy of the receiving track. For audio energy of tracks attached locally, see RTCAudioSourceStats instead.

This value must be computed as follows: for each audio sample that is received (and thus counted by totalSamplesReceived), add the sample's value divided by the highest-intensity encodable value, squared and then multiplied by the duration of the sample in seconds. In other words, duration * Math.pow(energy/maxEnergy, 2).

This can be used to obtain a root mean square (RMS) value that uses the same units as audioLevel, as defined in [RFC6464]. It can be converted to these units using the formula Math.sqrt(totalAudioEnergy/totalSamplesDuration). This calculation can also be performed using the differences between the values of two different getStats() calls, in order to compute the average audio level over any desired time interval. In other words, do Math.sqrt((energy2 - energy1)/(duration2 - duration1)).

For example, if a 10ms packet of audio is produced with an RMS of 0.5 (out of 1.0), this should add 0.5 * 0.5 * 0.01 = 0.0025 to totalAudioEnergy. If another 10ms packet with an RMS of 0.1 is received, this should similarly add 0.0001 to totalAudioEnergy. Then, Math.sqrt(totalAudioEnergy/totalSamplesDuration) becomes Math.sqrt(0.0026/0.02) = 0.36, which is the same value that would be obtained by doing an RMS calculation over the contiguous 20ms segment of audio.

If multiple audio channels are used, the audio energy of a sample refers to the highest energy of any channel.

这个度量指标只存在于音频中。它表示接收轨道的音频能量。有关本地附加轨道的音频能量，请参阅 RTCAudioSourceStats。

该值必须按如下方式计算：

对于接收到的每个音频样本（因此按 totalSamplesReceived 计数），将样本值除以最高强度的可编码值，平方，然后乘以以秒为单位的样本持续时间。

::

    duration * Math.pow(energy/maxEnergy, 2).


这可用于获得与 audioLevel 使用相同单位的均方根 (RMS) 值，如 [RFC6464] 中所定义。可以使用公式 Math.sqrt(totalAudioEnergy/totalSamplesDuration) 将其转换为这些单位。也可以使用两个不同 getStats() 调用的值之间的差异来执行此计算，以便计算任何所需时间间隔内的平均音频电平。换句话说，做 Math.sqrt((energy2 - energy1)/(duration2 - duration1))。

例如，如果生成一个 10 毫秒的音频数据包，其 RMS 为 0.5（超出 1.0），则应将 0.5 * 0.5 * 0.01 = 0.0025 添加到 totalAudioEnergy。如果接收到另一个 RMS 为 0.1 的 10ms 数据包，这应该类似地将 0.0001 添加到 totalAudioEnergy。然后，Math.sqrt(totalAudioEnergy/totalSamplesDuration) 变为 Math.sqrt(0.0026/0.02) = 0.36，这与通过对连续 20 毫秒音频段进行 RMS 计算获得的值相同。

如果使用多个音频通道，则样本的音频能量是指任一通道的最高能量。


ASA
=============================
Active Speaker Arbitration 比较音量大小，挑选出音量较高的几个人（一般是3个）


ASN
=============================
Active Speaker Notification 将上述挑选出的列表通知给订阅者


示例代码
=============================

`RFC6464`_ 中有计算 Audio Level 的 java 代码


.. container:: toggle

    .. container:: header

        **显示/隐藏代码**

    .. code-block:: java
       :linenos:

       
            /*
            Copyright (c) 2011 IETF Trust and the persons identified
            as authors of the code.  All rights reserved.

            Redistribution and use in source and binary forms, with
            or without modification, is permitted pursuant to, and subject
            to the license terms contained in, the Simplified BSD License
            set forth in Section 4.c of the IETF Trust's Legal Provisions
            Relating to IETF Documents (http://trustee.ietf.org/license-info).
        */

        /**
            * Calculates the audio level of specific samples of a signal
            * relative to overload.
            */
        public class AudioLevelCalculator
        {

            /**
                * Calculates the audio level of a signal with specific
                * <tt>samples</tt>.
                *
                * @param samples  the samples whose audio level we need to
                * calculate.  The samples are specified as an <tt>int</tt>
                * array starting at <tt>offset</tt>, extending <tt>length</tt>
                * number of elements, and each <tt>int</tt> element in the
                * specified range representing a sample whose audio level we

                * need to calculate.  Though a sample is provided in the
                * form of an <tt>int</tt> value, the sample size in bits
                * is determined by the caller via <tt>overload</tt>.
                *
                * @param offset  the offset in <tt>samples</tt> at which the
                * samples start.
                *
                * @param length  the length of the signal specified in
                * <tt>samples<tt>, starting at <tt>offset</tt>.
                *
                * @param overload  the overload (point) of <tt>signal</tt>.
                * For example, <tt>overload</tt> can be {@link Byte#MAX_VALUE}
                * for 8-bit signed samples or {@link Short#MAX_VALUE} for
                * 16-bit signed samples.
                *
                * @return  the audio level of the specified signal.
                */
            public static int calculateAudioLevel(
                int[] samples, int offset, int length,
                int overload)
            {
                /*
                    * Calculate the root mean square (RMS) of the signal.
                    */
                double rms = 0;

                for (; offset < length; offset++)
                {
                    double sample = samples[offset];

                    sample /= overload;
                    rms += sample * sample;
                }
                rms = (length == 0) ? 0 : Math.sqrt(rms / length);

                /*
                    * The audio level is a logarithmic measure of the
                    * rms level of an audio sample relative to a reference
                    * value and is measured in decibels.
                    */
                double db;

                /*
                    * The minimum audio level permitted.
                    */
                final double MIN_AUDIO_LEVEL = -127;

                /*
                    * The maximum audio level permitted.
                    */
                final double MAX_AUDIO_LEVEL = 0;

                if (rms > 0)
                {
                    /*
                        * The "zero" reference level is the overload level,
                        * which corresponds to 1.0 in this calculation, because
                        * the samples are normalized in calculating the RMS.
                        */
                    db = 20 * Math.log10(rms);

                    /*
                        * Ensure that the calculated level is within the minimum
                        * and maximum range permitted.
                        */
                    if (db < MIN_AUDIO_LEVEL)
                        db = MIN_AUDIO_LEVEL;
                    else if (db > MAX_AUDIO_LEVEL)
                        db = MAX_AUDIO_LEVEL;
                }
                else
                {
                    db = MIN_AUDIO_LEVEL;
                }

                return (int)Math.round(db);
            }
        }


FAQ
===================

Gain 和 Volume 的区别
-----------------------
Gain是指针对输入的声音信号的增益调节放大倍数，Volume是指针对输出的音量大小。

* Gain指增益：增益就是用来增强输入进音箱电路的信号的。增益的作用就是放大信号。将输入的信号放大一定的倍数，而单位通常是我们熟悉的分贝
* Volume指音量：就是声音的响度，指音量的大小，也就是最终输出的声音大小。

Reference
===================

* `RFC6464`_: A Real-time Transport Protocol (RTP) Header Extension for Client-to-Mixer Audio Level Indication
* `RFC6465`_: A Real-time Transport Protocol (RTP) Header Extension for Mixer-to-Client Audio Level Indication