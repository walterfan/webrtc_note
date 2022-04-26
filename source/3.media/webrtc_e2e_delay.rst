################################
WebRTC E2E Delay
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** WebRTC E2E Delay
**Category** Learning note
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:


概述
===========================   


在网上会议中，张三和李四在会议中进行视频聊天。 张三的声音从麦克风中传入，视频从摄像头中传入，李四要过一段时间才能听到声音，看到图像，这个时间差是视频会议中的关键指标。我们称为端到端延迟。

`e2e_delay = receiver_playout_time - sender_capture_time`


参考
==========================
* https://github.com/w3ctag/design-reviews/issues/493
* https://github.com/w3c/webrtc-extensions/blob/main/explainer.md
* https://github.com/w3c/webrtc-stats/pull/538/files
* https://janus.conf.meetecho.com/docs/rtp_8h.html#a55faec3441b03350eec0f9b39e8b79bf