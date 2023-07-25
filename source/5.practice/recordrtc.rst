###################
Record RTC Tool
###################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Record RTC Tool
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


Overview
========================
通过 WebRTC 所提供的音视频捕捉和音视频录制功能, 我们可以很容易地在浏览器端录制音视频流



录制远程的媒体流
------------------------------------------------
* 创建一个新的媒体流, 加入来自远程的音频视频流轨(audio/video track)
* 创建一个新的 RecordRTC 实例, 参数为这个新的媒体流和指定的参数

.. code-block:: javascript

    const options = {
        bufferSize: 16384,
        type: 'video',
        mimeType: 'video/webm'
    }
    //Start and Stop the recording when needed:
    recording.startRecording();
    recording.stopRecording();
    //Once the recording is done, the next step is to save the recording.
    var file = new File([recording.getBlob()], '<filename>.webm', {
    type: 'video/webm'
    });

    invokeSaveAsDialog(file, file.name);



The above functionality works when we want to record only a single media stream like local users' audio and video or remote users' audio and video but not both. In order to record multiple stream, we need to use MultiStreamRecorder.



MultiStreamRecorder
-----------------------------
创建两个媒体流, 一个为本地流(包含本地音频和视频媒体流轨 track), 另一个为远程流(包含远程音频和视频媒体流轨 track)
然后, 创建一个 `MultiStreamRecorder` 的实例, 参数为上述的媒体流列表和配置


.. code-block:: javascript

    localStream = new MediaStream()
    localStream.addTrack(meeting.mediaProperties.audioTrack)
    localStream.addTrack(meeting.mediaProperties.videoTrack)

    remoteStream = new MediaStream()
    remoteStream.addTrack(meeting.mediaProperties.remoteAudioTrack)

    recorder = new MultiStreamRecorder([localStream, remoteStream], {
        bufferSize: 16384,
        type: 'video',
        mimeType: 'video/webm\;codecs=h264',
        video: {
            width: 1280,
            height: 720,
        },
        frameInterval: 30,
    });

    recorder.record()

    recorder.stop(function (blob) {
        return blob;
    })

    var file = new File([recorder.blob], 'test.webm', {
        type: 'video/webm'
    });

    invokeSaveAsDialog(file, file.name);

Example
------------------------
https://www.webrtc-experiment.com/msr/MultiStreamRecorder.html

Reference
========================
* https://recordrtc.org/
* https://github.com/muaz-khan/RecordRTC