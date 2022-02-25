####################
WebRTC test suite
####################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC test suite
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

Overview
=============

Chrome testing
=====================


/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --enable-logging --v=1


/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary  --enable-logging --v=1


Load local vide file as a virtual camear
--------------------------------------------

* MacOS
  
.. code-block::

   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --use-fake-device-for-media-stream \
   --use-file-for-fake-video-capture=/Users/yafan/Downloads/station2_1080p25.y4m

* Windows

.. code-block::

   "C:\Program Files\Google\Chrome\Application\chrome.exe" --use-fake-device-for-media-stream \
   --use-file-for-fake-video-capture="C:\Users\yafan\Downloads\rush_hour_1080p25.y4m"



.. code-block::

   cd /Applications/Google\ Chrome\ Canary.app/Contents/MacOS/
   ./Google\ Chrome\ Canary --disable-webrtc-encryption



参考资料
==============
* `WebRTC test suite`_
* `The web-platform-tests Project`_ 

.. _The web-platform-tests Project: https://github.com/web-platform-tests/wpt
.. _WebRTC test suite: https://github.com/web-platform-tests/wpt/tree/master/webrtc/