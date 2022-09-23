#################
Devtools
#################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** devtools
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Webrtc internals
===================

* `webrtc-internals`_: and getstats parameters – a detailed view of webrtc-internals and the getstats() parameters it collects
* `active connections`:_ in webrtc-internals – an explanation of how to find the active connection in webrtc-internals – and how to wrap back from there to find the ICE candidates of the active connection
* `webrtc-internals API trace`_: API trace – a guide on what to expect in the API trace for a successful WebRTC session, along with some typical failure cases


.. _webrtc-internals: https://testrtc.com/webrtc-internals-parameters/
.. _active connections: https://testrtc.com/find-webrtc-active-connection/
.. _webrtc-internals API trace: https://testrtc.com/webrtc-api-trace/


Chome Devtools
====================
* `Analyze runtime performance`_
  
.. _Analyze runtime performance: https://developer.chrome.com/docs/devtools/evaluate-performance/

RTP Log Analyzer
====================
* `RTP log analyzer`_

.. _RTP log analyzer: https://webrtc.googlesource.com/src/+/refs/heads/lkgr/rtc_tools/py_event_log_analyzer/README.md


Video Replay
====================
* `Video Replay`_

.. code-block::

   mkdir webrtc-checkout
   cd webrtc-checkout/
   fetch --nohooks webrtc
   gclient sync
   cd src
   gn gen out/Default
   ninja -C out/Default video_replay

   out/Default/video_replay -input_file received-video.rtpdump -codec VP9 -media_payload_type 98 -red_payload_type 102 -ssrc 4075734755

.. _Video Replay: https://webrtchacks.com/video_replay/