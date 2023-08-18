######################
Video Quality
######################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** Video Quality
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:


Overview
========================
在 WebRTC 应用中， 用户会经历视频的卡顿, 模糊, 花屏, 绿屏等等问题。
原因是接收方对于视频帧不能正确及时的解码并播放。

大多数是由于网络不稳定所引起的，对应的方法有：

* Simulcast
* FEC
* RTX
* Congestion Control


在视频编码本身也可以做一些质量参数的调整

Tools
========================
* https://mediaarea.net/en/MediaInfo
* https://docs.agora.io/en/All/faq/web-native_video_issues
* https://github.com/muaz-khan/RecordRTC/issues/725
* https://bugs.chromium.org/p/chromium/issues/detail?id=1156408