##########################
Automatic Gain Control
##########################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Automatic Gain Control
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

概述
===================

自动增益控制（AGC）是指当直放站工作于最大增益且输出为最大功率时，增加输入信号电平，提高直放站对输出信号电平控制的能力。

自动增益控制主要用于调整音量幅值。

正常人交谈的音量在40~60dB之间，低于25dB的声音听起来很吃力，超过100dB的声音会让人不适。AGC的作用就是将音量调整到人接受的范围。

AGC的调整分为模拟部分(AAGC)和数字部分(DAGC)，模拟部分是麦克风的采集增益，数字部分是音频数据的数字电平调整。

.. figure:: ../_static/agc_flow.png
   :alt: AGC flow


* Calculate the short-term mean and variance, describe the instantaneous change of the voice envelope, which can accurately reflect the voice envelope,

* Calculate the long-term mean and variance, describe the overall slow change trend of the signal, outline the "center of gravity" of the signal, and it is more smooth to use the threshold as the detection condition, such as Figure 2 left blue curve ;

* Calculate the standard score and describe the deviation of the short-term average from the "center of gravity". The part above the center can be considered as having a great possibility of voice activity;



原理
=====================

自动增益控制是指使放大电路的增益自动地随信号强度而调整的自动控制方法。实现这种功能的电路简称AGC环。
AGC环是闭环电子电路，是一个负反馈系统，它可以分成增益受控放大电路和控制电压形成电路两部分。

增益受控放大电路位于正向放大通路，其增益随控制电压而改变。控制电压形成电路的基本部件是 AGC 检波器和低通平滑滤波器，有时也包含门电路和直流放大器等部件。放大电路的输出信号u0 经检波并经滤波器滤除低频调制分量和噪声后，产生用以控制增益受控放大器的电压uc 。当输入信号ui增大时，u0和uc亦随之增大。uc 增大使放大电路的增益下降，从而使输出信号的变化量显著小于输入信号的变化量，达到自动增益控制的目的。


放大电路增益的控制方法有：
①改变晶体管的直流工作状态，以改变晶体管的电流放大系数β。
②在放大器各级间插入电控衰减器。
③用电控可变电阻作放大器负载等。

AGC电路广泛用于各种接收机 ，录音机和测量仪器中，它常被用来使系统的输出电平保持在一定范围内 ，因而也称自动电平控制； 用于话音放大器或收音机时，称为自动音量控制。


Glossary
=====================
audio level
--------------------


single talk
--------------------

multiple talk
--------------------

boost volume
--------------------


Key points
====================
AAGC/DAGC supported by  



WebRTC Implementation
=========================

* Legacy AGC
* AGC
* AGC2



Parameters
---------------------------
targetDbFs
compressionGainDb
agcMode
limiterEnabled


AGC Mode
--------------------------
* Fixed Digital: for embeded devices
* Adaptive Analog: device provided in analog domain
* Adaptive Digital: in digital domain


Legacy AGC
----------------------------
* Calculate Gain Table





Reference
===================
* https://testing.googleblog.com/2015/10/audio-testing-automatic-gain-control.html
* https://testing.googleblog.com/2013/11/webrtc-audio-quality-testing.html
  
* 详解 WebRTC 高音质低延时的背后 — AGC（自动增益控制): https://segmentfault.com/a/1190000040072259