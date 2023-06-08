######################
Video Process
######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** video process
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=========

视频处理首先是图像处理，可以调整亮度，对比度以及饱和度。可以参考 Photoshop 中的众多滤镜，锐化，钝化，
更高级的是修图及美颜功能，例如美白，去红眼等功能，这也需要参考不同人种的面部及身体特征


* Transcode
* Compositing
* Transform
* Inject

常用的操作有颜色空间的转换, 图像像素的重新采样(上采样,下采样), 各种滤镜的应用

* Histogram equalization
* Color correction
* video filter apply
* face recogtion and beauty


Example
=====================
add a watermark to a WebRTC video stream
-----------------------------------------------

We can use the Canvas API to overlay an image on top of the video stream.

例如:

Get the video element: Use JavaScript to get a reference to the video element in your HTML page.

.. code-block:: javascript

   const video = document.querySelector('video');

Create a canvas element: Use JavaScript to create a new canvas element and set its size to match the video element.

.. code-block:: javascript

   const canvas = document.createElement('canvas');
   canvas.width = video.videoWidth;
   canvas.height = video.videoHeight;

* Get the canvas context: Use JavaScript to get a reference to the 2D rendering context of the canvas element.

.. code-block:: javascript

   const ctx = canvas.getContext('2d');

* Draw the video frame: Use JavaScript to draw the current video frame onto the canvas.

.. code-block:: javascript

   ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

* Add the watermark: Use JavaScript to draw the watermark image onto the canvas.

.. code-block:: javascript

   const watermark = new Image();
   watermark.src = 'path/to/watermark.png';
   watermark.onload = () => {
      ctx.drawImage(watermark, 0, 0, canvas.width, canvas.height);
   };

* Replace the video element with the canvas element: Use JavaScript to replace the video element with the canvas element.

.. code-block:: javascript

   video.parentNode.replaceChild(canvas, video);

This code will replace the video element with a canvas element that has the video frame and the watermark image overlaid on top. You can customize the position and opacity of the watermark by adjusting the parameters of the drawImage function.


Library
==============
* opencv
* Scikit-video