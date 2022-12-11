#################################
WebRTC PeerConnection Channel
#################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC PeerConnection Example
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============


BaseChannel
--------------------------

BaseChannel contains logic common to voice and video, including enable,marshaling calls to a worker and network threads, and connection and media
monitors.

BaseChannel assumes signaling and other threads are allowed to make synchronous calls to the worker thread, the worker thread makes synchronous
calls only to the network thread, and the network thread can't be blocked by other threads.

* methods with _n suffix must be called on network thread,
* methods with _w suffix on worker thread
* methods with _s suffix on signaling thread.

Network and worker threads may be the same thread.

VideoChannel
----------------------------




VoiceChannel
----------------------------



SSRC generator
--------------------------

* ssrc 是 UniqueRandomIdGenerator随机生成的 32 位数，WebRTC library 的 ssrc generator 用的方法应该是不会产生 0 作为 ssrc 的

.. code-block:: c++

    uint32_t UniqueRandomIdGenerator::GenerateId() {
    webrtc::MutexLock lock(&mutex_);

    RTC_CHECK_LT(known_ids_.size(), std::numeric_limits<uint32_t>::max() - 1);
    while (true) {
        auto pair = known_ids_.insert(CreateRandomNonZeroId());
        if (pair.second) {
        return *pair.first;
        }
    }
    }