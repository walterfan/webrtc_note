#################
WebRTC 源码概览
#################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Source
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents:: Contents
   :local:


Overview
=============



Modules
=============

* async_audio_processing
* audio_coding
* audio_device
* audio_mixer
* audio_processing
* congestion_controller
* desktop_capture
* include
* pacing
* remote_bitrate_estimator
* rtp_rtcp
* third_party
  - fft
  - g711
  - g722
  - portaudio
* utility
* video_capture
* video_coding
* video_processing


Treasure in code
========================

* `overuse_frame_detector`_
  - webrtc/video/adaptation

* `congestion control`_
  - webrtc/modules/congestion_controller/

* remote_bitrate_estimator
  - webrtc/modules/remote_bitrate_estimator/





Reference
====================
* `Chromium Code Search`_
* `Webrtc video framerate/resolution 自适应 <https://xie.infoq.cn/article/50b7931b8a023f8ca7f25d4e9>`_
* https://webrtc.googlesource.com/src/+/refs/heads/master/docs/native-code/index.md
* https://ninja-build.org/manual.html


.. _Chromium Code Search: https://source.chromium.org/chromium/chromium/src
.. _ninja-tool: https://ninja-build.org/
.. _webrtc-prerequisite-sw: https://webrtc.googlesource.com/src/+/main/docs/native-code/development/prerequisite-sw/index.md
.. _webrtc-depot-tools: https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up

.. _overuse_frame_detector: ./webrtc_overuse_frame_decoder.html
.. _congestion control: ./webrtc_cc.html