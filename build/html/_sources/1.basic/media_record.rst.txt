################################
WebRTC API 之 Media Record
################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Media Record
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
    :local:

Overview
==========================

既然现在的笔记本电脑，平板，手机都有摄像头和麦克风，那么录音和录像就是一件非常容易的事情了，但是如果不用别人写好的录音录像程序，让你自己来实现一个录音和录像应用，其实也没那么简单。

但是有了 WebRTC 和支持它的浏览器， 事情就变得简单多了

现代浏览器不仅支持 audio 和 video 两个新的元素，还支持了MediaStream 和 MediaRecorder 这样的媒体 API 

第一步：创建一个供演示的 HTML  文件
===================================


* 源码在此 `record_demo.html <https://github.com/walterfan/webrtc_primer/blob/main/examples/record_demo.html>`_

这个 html 文件很简单，就是如下四个按钮


.. image:: https://upload-images.jianshu.io/upload_images/1598924-8cda83479a5b1c27.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :target: https://upload-images.jianshu.io/upload_images/1598924-8cda83479a5b1c27.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :alt: 


再加上一个 HTML5 支持的 video 元素

.. code-block::

   <video autoplay></video>

第二步：处理这四个按键的的 click 事件
=====================================

源码见 `record_demo.js <https://github.com/walterfan/webrtc_primer/blob/main/examples/js/record_demo.js>`_

1. 打开媒体 “open media” 按键的处理 - 获取本地媒体流
----------------------------------------------------

.. code-block::


   var localStream = null;
   var mediaRecorder = null;
   var recordChunks = [];
   var recordElement = document.querySelector('video');
   var recordMediaType = 'video/webm';

   var mediaConstraints = {
       audio:  {
           echoCancellation: {exact: true}
         },
       video: {
           width: 640, 
           height: 480
       }
   };

   async function openMedia(e, constraints) {
       if (mediaButton.textContent === 'Close Media') {
           closeMedia(e);
           return;
       }

       try {
           const stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
           handleSuccess(stream);
           mediaButton.textContent = 'Close Media';    
           console.log('openMedia success ');
       } catch (ex) {
           handleError(ex);
       }
   }

   function handleSuccess(stream) {
       localStream = stream;
       recordElement.srcObject = stream;
   }

上述代码获取本地用户的 audio 和 video 媒体流，async 和 await 关键字是ES7 提供的异步支持，await 就是先返回，等异步操作完成再回来执行下一步语句， async 代表函数是异步的。
当媒体流获取后，就赋予本地的

2. 开始录制 “start record” 的处理 - 录制本地媒体流
--------------------------------------------------

MediaRecorder API 就是录制媒体流的核心


.. image:: https://upload-images.jianshu.io/upload_images/1598924-17c1cf6ef5e39e66.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :target: https://upload-images.jianshu.io/upload_images/1598924-17c1cf6ef5e39e66.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :alt: image.png


.. code-block::

   function startRecord() {
       if(!localStream) {
           console.error("stream is not created.");
           return;
       }

       if (recordButton.textContent === 'Stop Record') {
           stopRecord();
           return;
       } 

       var options = {mimeType: recordMediaType};
       mediaRecorder = new MediaRecorder(localStream, options);
       mediaRecorder.start();

       recordButton.textContent = 'Stop Record';
       playButton.disabled = true;
       downButton.disabled = true;

       console.log("recorder started");

       mediaRecorder.ondataavailable = function(e) {
           console.log("data available", e.data);
           recordChunks.push(e.data);
       }

       mediaRecorder.onstop = function(e) {
           console.log('onstop fired');
           var blob = new Blob(recordChunks, { 'type' : recordMediaType });
           var blobURL = URL.createObjectURL(blob);
           const a = document.createElement('a');
           a.style.display = 'none';
           a.href = blobURL;
           a.download = 'test.webm';
           document.body.appendChild(a);
       };
   }

上述代码很简单，关键的地方就是创建 MediaRecorder 对象，传入媒体流，然后开始录制

.. code-block::

   var options = {mimeType: recordMediaType};
   mediaRecorder = new MediaRecorder(localStream, options);
   mediaRecorder.start();

为了能播放和下载所录制的媒体文件，需要将录制的内容存贮下来
``var recordChunks = [];``\ 是一个字节数组， 在录制停止时一起存入本地的 blob 对象中

.. code-block::

       mediaRecorder.ondataavailable = function(e) {
           console.log("data available", e.data);
           recordChunks.push(e.data);
       }

       mediaRecorder.onstop = function(e) {
           console.log('onstop fired');
           var blob = new Blob(recordChunks, { 'type' : recordMediaType });
           var blobURL = URL.createObjectURL(blob);
           const a = document.createElement('a');
           a.style.display = 'none';
           a.href = blobURL;
           a.download = 'test.webm';
           document.body.appendChild(a);
       };

3. 播放 “Plan Record” 的处理 - 播放本地存储的媒体文件
-----------------------------------------------------

它由录制时保存下来的 blob 数组创建出来

.. code-block::

   function playRecord() {
       const blob = new Blob(recordChunks, {type: recordMediaType});
       recordElement.src = null;
       recordElement.srcObject = null;
       recordElement.src = window.URL.createObjectURL(blob);
       recordElement.controls = true;
       recordElement.play();
   }

4. 下载 “Download Record ” 的处理 -  下载本地存储的媒体文件
-----------------------------------------------------------

.. code-block::


   function downRecord() {
       const blob = new Blob(recordChunks, {type: recordMediaType});
       const url = window.URL.createObjectURL(blob);
       const a = document.createElement('a');
       a.style.display = 'none';
       a.href = url;
       a.download = 'test.webm';
       document.body.appendChild(a);
       a.click();
       setTimeout(() => {
         document.body.removeChild(a);
         window.URL.revokeObjectURL(url);
       }, 100);
   }

可点击https://www.fanyamin.com/webrtc/examples/record_demo.html 看最终的效果：


.. image:: https://upload-images.jianshu.io/upload_images/1598924-fb4ccdf3c4b167fb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :target: https://upload-images.jianshu.io/upload_images/1598924-fb4ccdf3c4b167fb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
   :alt: 


参考资料
==================

* `MDN WebRTC API`_
* `W3C Media Capture and Streams Spec`_