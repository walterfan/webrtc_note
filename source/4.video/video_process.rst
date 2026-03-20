######################
Video Process
######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** 视频处理
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=========

在 WebRTC 应用中，视频处理涉及从采集到编码前、以及解码后到渲染之间对视频帧的操作。
常见的处理包括：

- **预处理**：降噪、美颜、背景虚化/替换、水印叠加
- **变换**：缩放、旋转、裁剪、像素格式转换
- **分析**：人脸检测、目标追踪、质量评估
- **后处理**：颜色校正、去交错、锐化

在浏览器端主要通过 Canvas API、WebGL、Insertable Streams 实现；
在服务端则常用 FFmpeg（libavfilter）、OpenCV、GStreamer 等工具。


浏览器端视频处理
========================

Canvas API 方式
--------------------------

通过将视频帧绘制到 Canvas 上，进行像素级操作后再捕获为 MediaStream：

.. code-block:: javascript

   const video = document.querySelector('video');
   const canvas = document.createElement('canvas');
   const ctx = canvas.getContext('2d');

   // 处理循环
   function processFrame() {
       canvas.width = video.videoWidth;
       canvas.height = video.videoHeight;

       // 绘制原始帧
       ctx.drawImage(video, 0, 0);

       // 获取像素数据
       const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
       const data = imageData.data;

       // 灰度滤镜
       for (let i = 0; i < data.length; i += 4) {
           const avg = (data[i] + data[i+1] + data[i+2]) / 3;
           data[i] = avg;     // R
           data[i+1] = avg;   // G
           data[i+2] = avg;   // B
       }

       ctx.putImageData(imageData, 0, 0);
       requestAnimationFrame(processFrame);
   }

   video.onplay = processFrame;

   // 将 canvas 捕获为 MediaStream 用于 WebRTC
   const processedStream = canvas.captureStream(30);
   const sender = pc.addTrack(processedStream.getVideoTracks()[0], processedStream);

添加水印
--------------------------

.. code-block:: javascript

   const watermark = new Image();
   watermark.src = 'watermark.png';

   function addWatermark() {
       ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

       // 右下角半透明水印
       ctx.globalAlpha = 0.5;
       const wmWidth = 120, wmHeight = 40;
       ctx.drawImage(watermark,
           canvas.width - wmWidth - 10,
           canvas.height - wmHeight - 10,
           wmWidth, wmHeight);
       ctx.globalAlpha = 1.0;

       requestAnimationFrame(addWatermark);
   }

背景虚化/替换
--------------------------

使用 TensorFlow.js 的 BodyPix 或 MediaPipe Selfie Segmentation 进行人像分割：

.. code-block:: javascript

   import * as bodySegmentation from '@tensorflow-models/body-segmentation';

   const segmenter = await bodySegmentation.createSegmenter(
       bodySegmentation.SupportedModels.MediaPipeSelfieSegmentation,
       { runtime: 'tfjs' }
   );

   async function blurBackground() {
       ctx.drawImage(video, 0, 0);
       const segmentation = await segmenter.segmentPeople(video);

       // 对背景区域应用高斯模糊
       await bodySegmentation.drawBokehEffect(
           canvas, video, segmentation,
           /* foregroundThreshold */ 0.7,
           /* backgroundBlurAmount */ 7,
           /* edgeBlurAmount */ 3
       );

       requestAnimationFrame(blurBackground);
   }


Insertable Streams 方式
--------------------------

通过 WebRTC Insertable Streams（Encoded Transform）可以在编码后/解码前处理帧数据：

.. code-block:: javascript

   const sender = pc.addTrack(videoTrack, stream);
   const senderStreams = sender.createEncodedStreams();

   const transformer = new TransformStream({
       transform(encodedFrame, controller) {
           // 可以在这里对编码后的帧进行处理
           // 例如：端到端加密、添加元数据等
           const data = new Uint8Array(encodedFrame.data);

           // 示例：简单 XOR 加密
           const key = 0x42;
           for (let i = 0; i < data.length; i++) {
               data[i] ^= key;
           }
           encodedFrame.data = data.buffer;

           controller.enqueue(encodedFrame);
       }
   });

   senderStreams.readable
       .pipeThrough(transformer)
       .pipeTo(senderStreams.writable);


服务端视频处理
========================

OpenCV + Python
--------------------------

使用 OpenCV 对视频帧进行处理（人脸检测示例）：

.. code-block:: python

   import cv2
   import numpy as np

   cap = cv2.VideoCapture('input.mp4')
   face_cascade = cv2.CascadeClassifier(
       cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

   fourcc = cv2.VideoWriter_fourcc(*'VP80')
   out = cv2.VideoWriter('output.webm', fourcc, 30.0, (1280, 720))

   while cap.isOpened():
       ret, frame = cap.read()
       if not ret:
           break

       gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
       faces = face_cascade.detectMultiScale(gray, 1.3, 5)

       for (x, y, w, h) in faces:
           cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)

       out.write(frame)

   cap.release()
   out.release()

FFmpeg libavfilter
--------------------------

使用 FFmpeg 滤镜链进行视频处理：

.. code-block:: bash

   # 缩放 + 叠加水印 + 添加时间戳
   ffmpeg -i input.mp4 -i logo.png \
       -filter_complex "\
           [0:v]scale=1280:720[scaled]; \
           [scaled][1:v]overlay=W-w-10:H-h-10[overlaid]; \
           [overlaid]drawtext=text='%{pts\:hms}':fontsize=24:\
               fontcolor=white:x=10:y=10" \
       -c:v libvpx -b:v 2M output.webm

   # 视频降噪
   ffmpeg -i noisy.mp4 -vf "hqdn3d=4:3:6:4.5" denoised.mp4

   # 色彩校正（亮度+10，对比度x1.2，饱和度x1.3）
   ffmpeg -i input.mp4 -vf "eq=brightness=0.1:contrast=1.2:saturation=1.3" output.mp4


常见处理操作
========================

.. list-table::
   :header-rows: 1
   :widths: 20 40 40

   * - 操作
     - 浏览器端
     - 服务端
   * - 缩放
     - Canvas ``drawImage`` / CSS transform
     - FFmpeg ``scale`` 滤镜 / OpenCV ``resize``
   * - 旋转
     - Canvas ``rotate`` / CSS
     - FFmpeg ``transpose`` / OpenCV ``rotate``
   * - 裁剪
     - Canvas ``drawImage`` 参数
     - FFmpeg ``crop`` 滤镜 / OpenCV 切片
   * - 水印
     - Canvas 叠加绘制
     - FFmpeg ``overlay`` / OpenCV ``addWeighted``
   * - 美颜
     - WebGL shader / TensorFlow.js
     - OpenCV 双边滤波 + 肤色检测
   * - 背景虚化
     - MediaPipe / BodyPix
     - OpenCV + DNN 分割
   * - 人脸检测
     - MediaPipe Face Detection
     - OpenCV Haar/DNN / dlib
   * - 降噪
     - WebGL temporal filter
     - FFmpeg ``hqdn3d`` / OpenCV ``fastNlMeans``
   * - 颜色空间转换
     - WebGL shader
     - FFmpeg ``format`` / OpenCV ``cvtColor``
   * - 端到端加密
     - Insertable Streams
     - N/A（服务端无法访问明文帧）


性能考量
========================

在 WebRTC 实时场景中，视频处理必须在帧间隔内完成（30fps → 每帧 33ms）：

- **Canvas API**：简单但性能有限，适合简单滤镜和水印。像素级操作在高分辨率下可能超时
- **WebGL / GPU Shader**：利用 GPU 并行计算，适合复杂滤镜，但编程复杂度高
- **WebAssembly**：将 C/C++ 算法编译为 WASM，接近原生性能
- **Insertable Streams**：在编码域处理，不需要解码-处理-重编码，性能开销最小
- **Off-screen Canvas + Worker**：将处理移到 Worker 线程，避免阻塞 UI

.. code-block:: javascript

   // 使用 OffscreenCanvas 在 Worker 中处理
   const offscreen = canvas.transferControlToOffscreen();
   const worker = new Worker('video-worker.js');
   worker.postMessage({ canvas: offscreen }, [offscreen]);


常用库
==============

- `OpenCV <https://opencv.org/>`_：最广泛使用的计算机视觉库
- `MediaPipe <https://mediapipe.dev/>`_：Google 的跨平台 ML 视觉框架
- `TensorFlow.js <https://www.tensorflow.org/js>`_：浏览器端机器学习
- `FFmpeg libavfilter <https://ffmpeg.org/ffmpeg-filters.html>`_：强大的视频滤镜框架
- `GStreamer <https://gstreamer.freedesktop.org/>`_：多媒体处理管线框架
- `Scikit-video <http://www.scikit-video.org/>`_：Python 视频处理工具包
