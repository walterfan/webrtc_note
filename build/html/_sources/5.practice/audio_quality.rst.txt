######################
Audio Quality
######################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** Audio Quality
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:


Overview
========================
在 WebRTC 应用中， 用户会经历音频的停顿，噪声和回声干扰，音量太大或太小等问题。
对应的解决方法有：
* 声音断断续续,有卡顿, 可以用Jitter Buffer, 丢包恢复和丢包隐藏技术改善
* 声音太小或太大, 可以用 AGC 改善
* 声音不清晰, 有杂音或回声, 可以用声学回声消除 AEC(Acoustic Echo Canceller) 和背景噪声消除 BNR (Background Noise Removal) 加以改善