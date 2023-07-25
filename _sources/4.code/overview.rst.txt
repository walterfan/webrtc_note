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



.. contents:: Contents
   :local:


Overview
=============

WebRTC release notes are posted to the discuss-webrtc mailing list before the release:
https://webrtc.googlesource.com/src/+/refs/heads/main/docs/release-notes.md


Domain object
====================

Call
--------------------
A Call represents a two-way connection carrying zero or more outgoing and incoming media streams, transported over one or more RTP transports.

A Call instance can contain several send and/or receive streams.

All streams are assumed to have the same remote endpoint and will share bitrate estimates etc.

When using the PeerConnection API, there is an one to one relationship between the PeerConnection and the Call.

Stream
--------------------
* AudioSendStream
* AudioReceiveStream
* VideoSendStream
* VideoReceiveStream



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


Import Interfaces
========================
* LossNotificationSender,
* RecoveredPacketReceiver,

* KeyFrameRequestSender,
* NackSender,
* OnDecryptedFrameCallback,
* OnDecryptionStatusChangeCallback,
* RtpVideoFrameReceiver

* RtpPacketSinkInterface,

.. code-block:: cpp

   void OnRtpPacket(const RtpPacketReceived& packet) override;


.. code-block:: cpp


    class PacketReceiver {
    public:
        enum DeliveryStatus {
          DELIVERY_OK,
          DELIVERY_UNKNOWN_SSRC,
          DELIVERY_PACKET_ERROR,
        };

        virtual DeliveryStatus DeliverPacket(MediaType media_type,
                                            rtc::CopyOnWriteBuffer packet,
                                            int64_t packet_time_us) = 0;

    protected:
        virtual ~PacketReceiver() {}
    };



Treasure in code
========================

* `overuse_frame_detector`_
  - webrtc/video/adaptation

* `congestion control`_
  - webrtc/modules/congestion_controller/

* remote_bitrate_estimator
  - webrtc/modules/remote_bitrate_estimator/


Contribution
========================
The detailed stpes refer to https://webrtc.org/support/contributing
There is an example: https://webrtc-review.googlesource.com/c/src/+/278682

preparation
-------------------------

1) Check out and build the code

2) Fill in the Contributor agreement

3) If you’ve never submitted code before, you must add your name and contact info to the AUTHORS file
Go to https://webrtc.googlesource.com/new-password and login with your email account. This should be the same account as returned by git config user.email

4) Then, run: git cl creds-check. If you get any errors, ask for help on discuss-webrtc

You will not have to repeat the above. After all that, you’re ready to upload:


upload patch
-------------------------

* Assuming you're on the main branch:

.. code-block::

  git checkout -b my-work-branch

* Make changes, build locally, run tests locally

.. code-block::

  git commit -am "Changed x, and it is working"
  git cl upload


Reference
========================
* `Chromium Code Search`_
* `Webrtc video framerate/resolution 自适应 <https://xie.infoq.cn/article/50b7931b8a023f8ca7f25d4e9>`_

.. _Chromium Code Search: https://source.chromium.org/chromium/chromium/src
.. _overuse_frame_detector: ./webrtc_overuse_frame_decoder.html
.. _congestion control: ./webrtc_cc.html