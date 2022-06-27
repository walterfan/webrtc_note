######################
video quality
######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Video Quality
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=========

指标
=========
* Peak signal-to-noise ratio (PSNR)
* structural similarity index measure (SSIM) 


码率控制
==========

在在线视频应用中, 卡顿和花屏是最常见的两个问题，多数原因是由于网络的不稳定，除了应用一些丢包补偿和恢复技术 ( 例如 FEC, RTX, NACK, PLI 等)
以及调整接收缓冲区 (Adjust Jitter Buffer), 我们还可以对视频编码进行一些码率控制，这对视频质量或许有些影响，但利大于弊。

经典的码率控制算法有

* MPEG-2 使用的 TM5
* H263 使用的 TMN8
* MPEG-4 使用的 VM8






Reference
================
* https://en.wikipedia.org/wiki/Peak_signal-to-noise_ratio
* https://en.wikipedia.org/wiki/Structural_similarity