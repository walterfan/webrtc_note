
######################
FAQ
######################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** FAQ
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:


How to disable SRTP?
=======================================
以 WebRTC 所带的 peerconnection_client 例程

.. code-block:: cpp

    webrtc::PeerConnectionFactoryInterface::Options options;
    options.disable_encryption = this->disable_srtp_;
    peer_connection_factory_->SetOptions(options);


step 1
--------------------
change C:\webrtc-checkout\src\examples\peerconnection\client\flag_defs.h

.. code-block:: cpp

    ABSL_FLAG(bool, disable_srtp, false, "disable srtp or not: false-enable srtp, true-disable srtp");


step 2
--------------------
change C:\webrtc-checkout\src\examples\peerconnection\client\conductor.h

.. code-block:: cpp

    class Conductor : public webrtc::PeerConnectionObserver,
                    public webrtc::CreateSessionDescriptionObserver,
                    public PeerConnectionClientObserver,
                    public MainWndCallback {
    public:
    void DisableSrtp(bool flag);
    
    bool disable_srtp_;
    };


    void Conductor::DisableSrtp(bool flag) {
    this->disable_srtp_ = flag;
    }



step 3
-------------------------
change C:\webrtc-checkout\src\examples\peerconnection\client\conductor.cc

.. code-block:: cpp

    bool Conductor::InitializePeerConnection() {
    RTC_DCHECK(!peer_connection_factory_);
    RTC_DCHECK(!peer_connection_);

    if (!signaling_thread_.get()) {
        signaling_thread_ = rtc::Thread::CreateWithSocketServer();
        signaling_thread_->Start();
    }
    peer_connection_factory_ = webrtc::CreatePeerConnectionFactory(
        nullptr /* network_thread */, nullptr /* worker_thread */,
        signaling_thread_.get(), nullptr /* default_adm */,
        webrtc::CreateBuiltinAudioEncoderFactory(),
        webrtc::CreateBuiltinAudioDecoderFactory(),
        webrtc::CreateBuiltinVideoEncoderFactory(),
        webrtc::CreateBuiltinVideoDecoderFactory(), nullptr /* audio_mixer */,
        nullptr /* audio_processing */);

    if (!peer_connection_factory_) {
        main_wnd_->MessageBox("Error", "Failed to initialize PeerConnectionFactory",
                            true);
        DeletePeerConnection();
        return false;
    }

    webrtc::PeerConnectionFactoryInterface::Options options;
    options.disable_encryption = this->disable_srtp_;
    peer_connection_factory_->SetOptions(options);

    if (!CreatePeerConnection()) {
        main_wnd_->MessageBox("Error", "CreatePeerConnection failed", true);
        DeletePeerConnection();
    }

    if (videoSourceType_ != VideoSourceType::NOSEND) {
        AddTracks();
    } else {
        main_wnd_->SwitchToStreamingUI();
    }

    return peer_connection_ != nullptr;
    }
    

Step 4
---------------------
change C:\webrtc-checkout\src\examples\peerconnection\client\main.cc

.. code-block:: cpp

  bool disable_srtp = absl::GetFlag(FLAGS_disable_srtp);
  conductor->DisableSrtp(disable_srtp);
  
