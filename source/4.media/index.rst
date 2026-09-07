################
4. 媒体技术
################

本章涵盖音频与视频：语音/视频编解码、处理流水线（AEC/AGC/ANS/VAD、Simulcast/SVC）、Web Audio API、屏幕共享与流媒体。

.. toctree::
   :maxdepth: 1
   :caption: 音频

   media_overview
   audio_basic
   webrtc_audio

   audio_codec_overview
   audio_codec_g711
   audio_codec_g722
   audio_codec_g729
   audio_codec_amr
   audio_codec_aac
   audio_codec_evs
   audio_codec_opus
   audio_codec_comparison

   audio_process
   audio_aec
   audio_agc
   audio_ans
   audio_vad

   audio_level
   audio_api
   audio_worklet
   audio_analysis
   audio_quality
   audio_qos

.. toctree::
   :maxdepth: 1
   :caption: 视频

   video_basic
   webrtc_video
   yuv

   video_codec
   video_codec_h264
   video_codec_av1
   video_process
   video_pipeline
   video_adaptation
   video_lip_sync
   video_quality

   webrtc_simulcast
   webrtc_svc
   webrtc_temporal_scalability
   webrtc_sharing

   streaming
   hls
   insertable_stream
   web_codec
