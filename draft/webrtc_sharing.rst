简介
====

网络会议中常用的屏幕共享功能使用 WebRTC 提供的 `getDisplayMedia`_ API
就能轻松实现，接口如下

::

   var promise = navigator.mediaDevices.getDisplayMedia(constraints);

MediaDevices 接口的 ``getDisplayMedia``
方法提示用户选择并授予将显示屏幕或其部分（如浏览器窗口和标签页）的内容捕获为
MediaStream 的权限。然后，可以使用媒体流录制 API 录制， 或作为 WebRTC
会话的一部分传输所生成的媒体流。这个媒体流传输到网络的对端，这样就可以共享屏幕的内容了。

例如

::

   async function startCapture(displayMediaOptions) {
     let captureStream = null;

     try {
       captureStream = await navigator.mediaDevices.getDisplayMedia(displayMediaOptions);
     } catch(err) {
       console.error("Error: " + err);
     }
     return captureStream;
   }

示例1
=====

.. image:: https://upload-images.jianshu.io/upload_images/1598924-3b094b70f234c64d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240

-  HTML 文件

::

   <!DOCTYPE html>
   <html xmlns="http://www.w3.org/1999/xhtml">
   <!-- 省略引入的 JS 和 CSS -->
   <body>

   <!-- <a href="https://github.com/walterfan/webrtc-primer"><img style="position: absolute; top: 0; left: 0; border: 0; z-index: 1001;" src="https://s3.amazonaws.com/github/ribbons/forkme_left_darkblue_121621.png" alt="Fork me on GitHub"></a>
    -->
   <nav class="navbar navbar-default navbar-static-top">
   </nav>

   <div class="container">
       <div class="row">
           <div class="col-lg-12">
               <div class="page-header">
                   <h1>WebRTC example of Desktop Sharing </h1>
               </div>
               <div class="container" id="details">
             <div class="row">

                 <div class="col-lg-12">

                   <p>Click the button to open or close connection</p>
                   <div>

                       <button class="btn btn-default" autocomplete="off" id="startButton">Share Something</button>
                   </div>
                   <br/>
                 </div>
                 <div class="col-lg-12">
                       <div class="col-lg-6">
                           <video id="localVideo" autoplay playsinline muted></video>
                       </div>
                  </div>
             </div>
       <hr>
       <div class="footer">
       </div>
   </div>
   <script type="text/javascript" src="js/desktop_sharing_demo.js"></script>
   </body>
   </html>

-  JS 文件

::

   'use strict';

   // Polyfill in Firefox.
   // See https://blog.mozilla.org/webrtc/getdisplaymedia-now-available-in-adapter-js/
   if (adapter.browserDetails.browser == 'firefox') {
     adapter.browserShim.shimGetDisplayMedia(window, 'screen');
   }

   const gdmOptions = {
     video: {
       cursor: "always"
     },
     audio: {
       echoCancellation: true,
       noiseSuppression: true,
       sampleRate: 44100
     }
   }

   function handleSuccess(stream) {
     startButton.disabled = true;
     const video = document.querySelector('video');
     video.srcObject = stream;

     // demonstrates how to detect that the user has stopped
     // sharing the screen via the browser UI.
     stream.getVideoTracks()[0].addEventListener('ended', () => {
       errorMsg('The user has ended sharing the screen');
       startButton.disabled = false;
     });
   }

   function handleError(error) {
     errorMsg(`getDisplayMedia error: ${error.name}`, error);
   }

   function errorMsg(msg, error) {
     const errorElement = document.querySelector('#errorMsg');
     errorElement.innerHTML += `<p>${msg}</p>`;
     if (typeof error !== 'undefined') {
       console.error(error);
     }
   }

   const startButton = document.getElementById('startButton');
   startButton.addEventListener('click', () => {
     navigator.mediaDevices.getDisplayMedia(gdmOptions)
         .then(handleSuccess, handleError);
   });

   if ((navigator.mediaDevices && 'getDisplayMedia' in navigator.mediaDevices)) {
     startButton.disabled = false;
   } else {
     errorMsg('getDisplayMedia is not supported');
   }

测试
----

点击 share 按键，可以选择 为文本 还是
运动共享，后者的帧率会高点。然后再选择屏幕，应用或标签页。

示例2
=====

服务器端
--------

使用 nodejs + socket.io 充当web服务器，并用来传递 sdp

代码：https://github.com/walterfan/webrtc_remote_sharing

启动命令

::

   node screen_share_server.js
   [2021-04-21T20:18:41.018] [INFO] screen_share - screen shares server listen on https://localhost:8183

客户端还是 html + JavaScript
----------------------------

详细代码： \*
https://github.com/walterfan/webrtc_primer/blob/main/examples/screen_share_demo.html
\*
https://github.com/walterfan/webrtc_primer/blob/main/examples/js/screen_share_client.js

.. _测试-1:

测试
----

将 getDisplayMedia 得到的媒体流 MediaStream 通过 PeerConnection
传送给对方

.. image:: https://upload-images.jianshu.io/upload_images/1598924-aeeb665e6267b758.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240

1) 张三进入会议室 “Join room”
2) 李四进入会议室 “Join room”
3) 张三分享屏幕 “start share”

.. figure:: https://upload-images.jianshu.io/upload_images/1598924-68b28dc7f3ae82c4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :alt: 本地屏幕

   本地屏幕

4) 李四就会看到分享的屏幕内容

.. figure:: https://upload-images.jianshu.io/upload_images/1598924-d5eef15f0b31f35d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :alt: 远端屏幕

   远端屏幕

注意我们需要观察 RTP 包的荷载内容，所以要关掉 SRTP ，只用 RTP 来传输
出于测试目的， Chrome Canary 及 Chrome Developer 有一个选项
``--disable-webrtc-encryption`` 可以关掉 SRTP

在我的 macbook 上步骤如下：

::

   cd /Applications/Google\ Chrome\ Canary.app/Contents/MacOS/
   ./Google\ Chrome\ Canary --disable-webrtc-encryption

于是在创建 RTP 连接时的 SDP 就从:

::

   m=video 9 RTP/SAVPF 96 97 98 99 100 101 102 121 127 120 125 107 108 109 35 36 124 119 123 118 114 115 116

就变成了

::

   m=video 9 RTP/AVPF 96 97 98 99 100 101 102 121 127 120 125 107 108 109 35 36 124 119 123 118 114 115 116

完整sdp如下

-  offer sdp 消息：

::

   {
     type: 'offer',
     sdp: 'v=0\r\n' +
       'o=- 2151254633287699884 2 IN IP4 127.0.0.1\r\n' +
       's=-\r\n' +
       't=0 0\r\n' +
       'a=group:BUNDLE 0 1\r\n' +
       'a=extmap-allow-mixed\r\n' +
       'a=msid-semantic: WMS VLvw0Ec4NwiXKVzTZyzl1m5aSLGW9EPe50Mz\r\n' +
       'm=audio 9 UDP/TLS/RTP/SAVPF 111 103 104 9 0 8 106 105 13 110 112 113 126\r\n' +
       'c=IN IP4 0.0.0.0\r\n' +
       'a=rtcp:9 IN IP4 0.0.0.0\r\n' +
       'a=ice-ufrag:wkaf\r\n' +
       'a=ice-pwd:2PI01Rh/wf4JKpfM0pr6LJ+d\r\n' +
       'a=ice-options:trickle\r\n' +
       'a=fingerprint:sha-256 86:BC:0B:F2:AB:2F:A2:A0:7F:FC:5B:5E:16:B8:61:62:E6:E6:18:FF:B6:85:6C:F0:DD:65:01:72:C1:16:88:E8\r\n' +
       'a=setup:actpass\r\n' +
       'a=mid:0\r\n' +
       'a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\r\n' +
       'a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\r\n' +
       'a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\r\n' +
       'a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\r\n' +
       'a=extmap:5 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id\r\n' +
       'a=extmap:6 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id\r\n' +
       'a=sendrecv\r\n' +
       'a=msid:VLvw0Ec4NwiXKVzTZyzl1m5aSLGW9EPe50Mz cd1c92ae-7d05-4ee8-9e21-3e2993c1c254\r\n' +
       'a=rtcp-mux\r\n' +
       'a=rtpmap:111 opus/48000/2\r\n' +
       'a=rtcp-fb:111 transport-cc\r\n' +
       'a=fmtp:111 minptime=10;useinbandfec=1\r\n' +
       'a=rtpmap:103 ISAC/16000\r\n' +
       'a=rtpmap:104 ISAC/32000\r\n' +
       'a=rtpmap:9 G722/8000\r\n' +
       'a=rtpmap:0 PCMU/8000\r\n' +
       'a=rtpmap:8 PCMA/8000\r\n' +
       'a=rtpmap:106 CN/32000\r\n' +
       'a=rtpmap:105 CN/16000\r\n' +
       'a=rtpmap:13 CN/8000\r\n' +
       'a=rtpmap:110 telephone-event/48000\r\n' +
       'a=rtpmap:112 telephone-event/32000\r\n' +
       'a=rtpmap:113 telephone-event/16000\r\n' +
       'a=rtpmap:126 telephone-event/8000\r\n' +
       'a=ssrc:3060416220 cname:C9N45apy7vfT4Waq\r\n' +
       'a=ssrc:3060416220 msid:VLvw0Ec4NwiXKVzTZyzl1m5aSLGW9EPe50Mz cd1c92ae-7d05-4ee8-9e21-3e2993c1c254\r\n' +
       'a=ssrc:3060416220 mslabel:VLvw0Ec4NwiXKVzTZyzl1m5aSLGW9EPe50Mz\r\n' +
       'a=ssrc:3060416220 label:cd1c92ae-7d05-4ee8-9e21-3e2993c1c254\r\n' +
       'm=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 102 121 127 120 125 107 108 109 124 119 123 118 114 115 116\r\n' +
       'c=IN IP4 0.0.0.0\r\n' +
       'a=rtcp:9 IN IP4 0.0.0.0\r\n' +
       'a=ice-ufrag:wkaf\r\n' +
       'a=ice-pwd:2PI01Rh/wf4JKpfM0pr6LJ+d\r\n' +
       'a=ice-options:trickle\r\n' +
       'a=fingerprint:sha-256 86:BC:0B:F2:AB:2F:A2:A0:7F:FC:5B:5E:16:B8:61:62:E6:E6:18:FF:B6:85:6C:F0:DD:65:01:72:C1:16:88:E8\r\n' +
       'a=setup:actpass\r\n' +
       'a=mid:1\r\n' +
       'a=extmap:14 urn:ietf:params:rtp-hdrext:toffset\r\n' +
       'a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\r\n' +
       'a=extmap:13 urn:3gpp:video-orientation\r\n' +
       'a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\r\n' +
       'a=extmap:12 http://www.webrtc.org/experiments/rtp-hdrext/playout-delay\r\n' +
       'a=extmap:11 http://www.webrtc.org/experiments/rtp-hdrext/video-content-type\r\n' +
       'a=extmap:7 http://www.webrtc.org/experiments/rtp-hdrext/video-timing\r\n' +
       'a=extmap:8 http://www.webrtc.org/experiments/rtp-hdrext/color-space\r\n' +
       'a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\r\n' +
       'a=extmap:5 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id\r\n' +
       'a=extmap:6 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id\r\n' +
       'a=sendrecv\r\n' +
       'a=msid:VLvw0Ec4NwiXKVzTZyzl1m5aSLGW9EPe50Mz 95173d41-de5c-4864-8745-a8573f23f3d8\r\n' +
       'a=rtcp-mux\r\n' +
       'a=rtcp-rsize\r\n' +
       'a=rtpmap:102 H264/90000\r\n' +
       'a=rtcp-fb:102 goog-remb\r\n' +
       'a=rtcp-fb:102 transport-cc\r\n' +
       'a=rtcp-fb:102 ccm fir\r\n' +
       'a=rtcp-fb:102 nack\r\n' +
       'a=rtcp-fb:102 nack pli\r\n' +
       'a=fmtp:102 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42001f\r\n' +
       'a=rtpmap:121 rtx/90000\r\n' +
       'a=fmtp:121 apt=102\r\n' +
       'a=rtpmap:127 H264/90000\r\n' +
       'a=rtcp-fb:127 goog-remb\r\n' +
       'a=rtcp-fb:127 transport-cc\r\n' +
       'a=rtcp-fb:127 ccm fir\r\n' +
       'a=rtcp-fb:127 nack\r\n' +
       'a=rtcp-fb:127 nack pli\r\n' +
       'a=fmtp:127 level-asymmetry-allowed=1;packetization-mode=0;profile-level-id=42001f\r\n' +
       'a=rtpmap:120 rtx/90000\r\n' +
       'a=fmtp:120 apt=127\r\n' +
       'a=rtpmap:125 H264/90000\r\n' +
       'a=rtcp-fb:125 goog-remb\r\n' +
       'a=rtcp-fb:125 transport-cc\r\n' +
       'a=rtcp-fb:125 ccm fir\r\n' +
       'a=rtcp-fb:125 nack\r\n' +
       'a=rtcp-fb:125 nack pli\r\n' +
       'a=fmtp:125 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f\r\n' +
       'a=rtpmap:107 rtx/90000\r\n' +
       'a=fmtp:107 apt=125\r\n' +
       'a=rtpmap:108 H264/90000\r\n' +
       'a=rtcp-fb:108 goog-remb\r\n' +
       'a=rtcp-fb:108 transport-cc\r\n' +
       'a=rtcp-fb:108 ccm fir\r\n' +
       'a=rtcp-fb:108 nack\r\n' +
       'a=rtcp-fb:108 nack pli\r\n' +
       'a=fmtp:108 level-asymmetry-allowed=1;packetization-mode=0;profile-level-id=42e01f\r\n' +
       'a=rtpmap:109 rtx/90000\r\n' +
       'a=fmtp:109 apt=108\r\n' +
       'a=rtpmap:124 H264/90000\r\n' +
       'a=rtcp-fb:124 goog-remb\r\n' +
       'a=rtcp-fb:124 transport-cc\r\n' +
       'a=rtcp-fb:124 ccm fir\r\n' +
       'a=rtcp-fb:124 nack\r\n' +
       'a=rtcp-fb:124 nack pli\r\n' +
       'a=fmtp:124 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=4d0032\r\n' +
       'a=rtpmap:119 rtx/90000\r\n' +
       'a=fmtp:119 apt=124\r\n' +
       'a=rtpmap:123 H264/90000\r\n' +
       'a=rtcp-fb:123 goog-remb\r\n' +
       'a=rtcp-fb:123 transport-cc\r\n' +
       'a=rtcp-fb:123 ccm fir\r\n' +
       'a=rtcp-fb:123 nack\r\n' +
       'a=rtcp-fb:123 nack pli\r\n' +
       'a=fmtp:123 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640032\r\n' +
       'a=rtpmap:118 rtx/90000\r\n' +
       'a=fmtp:118 apt=123\r\n' +
       'a=rtpmap:114 red/90000\r\n' +
       'a=rtpmap:115 rtx/90000\r\n' +
       'a=fmtp:115 apt=114\r\n' +
       'a=rtpmap:116 ulpfec/90000\r\n' +
       'a=ssrc-group:FID 3194951553 658670364\r\n' +
       'a=ssrc:3194951553 cname:C9N45apy7vfT4Waq\r\n' +
       'a=ssrc:3194951553 msid:VLvw0Ec4NwiXKVzTZyzl1m5aSLGW9EPe50Mz 95173d41-de5c-4864-8745-a8573f23f3d8\r\n' +
       'a=ssrc:3194951553 mslabel:VLvw0Ec4NwiXKVzTZyzl1m5aSLGW9EPe50Mz\r\n' +
       'a=ssrc:3194951553 label:95173d41-de5c-4864-8745-a8573f23f3d8\r\n' +
       'a=ssrc:658670364 cname:C9N45apy7vfT4Waq\r\n' +
       'a=ssrc:658670364 msid:VLvw0Ec4NwiXKVzTZyzl1m5aSLGW9EPe50Mz 95173d41-de5c-4864-8745-a8573f23f3d8\r\n' +
       'a=ssrc:658670364 mslabel:VLvw0Ec4NwiXKVzTZyzl1m5aSLGW9EPe50Mz\r\n' +
       'a=ssrc:658670364 label:95173d41-de5c-4864-8745-a8573f23f3d8\r\n'
   }

-  Answer SDP 消息

::


    {
     type: 'answer',
     sdp: 'v=0\r\n' +
       'o=- 6808421739235470893 2 IN IP4 127.0.0.1\r\n' +
       's=-\r\n' +
       't=0 0\r\n' +
       'a=group:BUNDLE 0 1\r\n' +
       'a=extmap-allow-mixed\r\n' +
       'a=msid-semantic: WMS\r\n' +
       'm=audio 9 UDP/TLS/RTP/SAVPF 111 103 104 9 0 8 106 105 13 110 112 113 126\r\n' +
       'c=IN IP4 0.0.0.0\r\n' +
       'a=rtcp:9 IN IP4 0.0.0.0\r\n' +
       'a=ice-ufrag:8fbZ\r\n' +
       'a=ice-pwd:r/ZnPQzn6uh8LIKW1gfaacu6\r\n' +
       'a=ice-options:trickle\r\n' +
       'a=fingerprint:sha-256 3A:5E:40:E4:BD:31:64:74:86:41:5A:62:1B:CA:0A:0A:4A:A4:0D:59:68:D5:47:15:B6:53:FE:BE:0F:3C:8D:D6\r\n' +
       'a=setup:active\r\n' +
       'a=mid:0\r\n' +
       'a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\r\n' +
       'a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\r\n' +
       'a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\r\n' +
       'a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\r\n' +
       'a=extmap:5 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id\r\n' +
       'a=extmap:6 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id\r\n' +
       'a=recvonly\r\n' +
       'a=rtcp-mux\r\n' +
       'a=rtpmap:111 opus/48000/2\r\n' +
       'a=rtcp-fb:111 transport-cc\r\n' +
       'a=fmtp:111 minptime=10;useinbandfec=1\r\n' +
       'a=rtpmap:103 ISAC/16000\r\n' +
       'a=rtpmap:104 ISAC/32000\r\n' +
       'a=rtpmap:9 G722/8000\r\n' +
       'a=rtpmap:0 PCMU/8000\r\n' +
       'a=rtpmap:8 PCMA/8000\r\n' +
       'a=rtpmap:106 CN/32000\r\n' +
       'a=rtpmap:105 CN/16000\r\n' +
       'a=rtpmap:13 CN/8000\r\n' +
       'a=rtpmap:110 telephone-event/48000\r\n' +
       'a=rtpmap:112 telephone-event/32000\r\n' +
       'a=rtpmap:113 telephone-event/16000\r\n' +
       'a=rtpmap:126 telephone-event/8000\r\n' +
       'm=video 9 UDP/TLS/RTP/SAVPF 102 121 127 120 125 107 108 109 124 119 123 118 114 115 116\r\n' +
       'c=IN IP4 0.0.0.0\r\n' +
       'a=rtcp:9 IN IP4 0.0.0.0\r\n' +
       'a=ice-ufrag:8fbZ\r\n' +
       'a=ice-pwd:r/ZnPQzn6uh8LIKW1gfaacu6\r\n' +
       'a=ice-options:trickle\r\n' +
       'a=fingerprint:sha-256 3A:5E:40:E4:BD:31:64:74:86:41:5A:62:1B:CA:0A:0A:4A:A4:0D:59:68:D5:47:15:B6:53:FE:BE:0F:3C:8D:D6\r\n' +
       'a=setup:active\r\n' +
       'a=mid:1\r\n' +
       'a=extmap:14 urn:ietf:params:rtp-hdrext:toffset\r\n' +
       'a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\r\n' +
       'a=extmap:13 urn:3gpp:video-orientation\r\n' +
       'a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\r\n' +
       'a=extmap:12 http://www.webrtc.org/experiments/rtp-hdrext/playout-delay\r\n' +
       'a=extmap:11 http://www.webrtc.org/experiments/rtp-hdrext/video-content-type\r\n' +
       'a=extmap:7 http://www.webrtc.org/experiments/rtp-hdrext/video-timing\r\n' +
       'a=extmap:8 http://www.webrtc.org/experiments/rtp-hdrext/color-space\r\n' +
       'a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\r\n' +
       'a=extmap:5 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id\r\n' +
       'a=extmap:6 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id\r\n' +
       'a=recvonly\r\n' +
       'a=rtcp-mux\r\n' +
       'a=rtcp-rsize\r\n' +
       'a=rtpmap:102 H264/90000\r\n' +
       'a=rtcp-fb:102 goog-remb\r\n' +
       'a=rtcp-fb:102 transport-cc\r\n' +
       'a=rtcp-fb:102 ccm fir\r\n' +
       'a=rtcp-fb:102 nack\r\n' +
       'a=rtcp-fb:102 nack pli\r\n' +
       'a=fmtp:102 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42001f\r\n' +
       'a=rtpmap:121 rtx/90000\r\n' +
       'a=fmtp:121 apt=102\r\n' +
       'a=rtpmap:127 H264/90000\r\n' +
       'a=rtcp-fb:127 goog-remb\r\n' +
       'a=rtcp-fb:127 transport-cc\r\n' +
       'a=rtcp-fb:127 ccm fir\r\n' +
       'a=rtcp-fb:127 nack\r\n' +
       'a=rtcp-fb:127 nack pli\r\n' +
       'a=fmtp:127 level-asymmetry-allowed=1;packetization-mode=0;profile-level-id=42001f\r\n' +
       'a=rtpmap:120 rtx/90000\r\n' +
       'a=fmtp:120 apt=127\r\n' +
       'a=rtpmap:125 H264/90000\r\n' +
       'a=rtcp-fb:125 goog-remb\r\n' +
       'a=rtcp-fb:125 transport-cc\r\n' +
       'a=rtcp-fb:125 ccm fir\r\n' +
       'a=rtcp-fb:125 nack\r\n' +
       'a=rtcp-fb:125 nack pli\r\n' +
       'a=fmtp:125 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f\r\n' +
       'a=rtpmap:107 rtx/90000\r\n' +
       'a=fmtp:107 apt=125\r\n' +
       'a=rtpmap:108 H264/90000\r\n' +
       'a=rtcp-fb:108 goog-remb\r\n' +
       'a=rtcp-fb:108 transport-cc\r\n' +
       'a=rtcp-fb:108 ccm fir\r\n' +
       'a=rtcp-fb:108 nack\r\n' +
       'a=rtcp-fb:108 nack pli\r\n' +
       'a=fmtp:108 level-asymmetry-allowed=1;packetization-mode=0;profile-level-id=42e01f\r\n' +
       'a=rtpmap:109 rtx/90000\r\n' +
       'a=fmtp:109 apt=108\r\n' +
       'a=rtpmap:124 H264/90000\r\n' +
       'a=rtcp-fb:124 goog-remb\r\n' +
       'a=rtcp-fb:124 transport-cc\r\n' +
       'a=rtcp-fb:124 ccm fir\r\n' +
       'a=rtcp-fb:124 nack\r\n' +
       'a=rtcp-fb:124 nack pli\r\n' +
       'a=fmtp:124 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=4d0015\r\n' +
       'a=rtpmap:119 rtx/90000\r\n' +
       'a=fmtp:119 apt=124\r\n' +
       'a=rtpmap:123 H264/90000\r\n' +
       'a=rtcp-fb:123 goog-remb\r\n' +
       'a=rtcp-fb:123 transport-cc\r\n' +
       'a=rtcp-fb:123 ccm fir\r\n' +
       'a=rtcp-fb:123 nack\r\n' +
       'a=rtcp-fb:123 nack pli\r\n' +
       'a=fmtp:123 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640015\r\n' +
       'a=rtpmap:118 rtx/90000\r\n' +
       'a=fmtp:118 apt=123\r\n' +
       'a=rtpmap:114 red/90000\r\n' +
       'a=rtpmap:115 rtx/90000\r\n' +
       'a=fmtp:115 apt=114\r\n' +
       'a=rtpmap:116 ulpfec/90000\r\n'
   }

Wireshark 抓包
==============

1.首先安装wireshark软件，这个地球人都知道

2.用wireshark抓取H264视频码流，最好过滤掉其他码流

3.右键点击H264的udp包，选择”Decode
as…“，再选择Transport中的rtp选项，就解析成rtp包了

4.查看rtp包的payload type，比如说type是
102，那么在wireshark工具栏选择Edit->preferences->protocols->H264, 把H264
dynamic payload types设成 102

-  RTP 流

.. image:: https://upload-images.jianshu.io/upload_images/1598924-a6755f3106366cf1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240

-  RTP 包 |image1|

-  H.264 荷载

1) SPS

.. image:: https://upload-images.jianshu.io/upload_images/1598924-42b1134893d8cb04.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240

2) FU-A

.. image:: https://upload-images.jianshu.io/upload_images/1598924-a9a9a57386cb5a1f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240

.. _getDisplayMedia: https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getDisplayMedia

.. |image1| image:: https://upload-images.jianshu.io/upload_images/1598924-4da42c2d2bbacf10.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
