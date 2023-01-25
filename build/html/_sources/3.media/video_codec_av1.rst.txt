###############
视频编码 AV1
###############

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Video Codec AV1
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=========

AOMedia Video 1 (AV1) is an open, royalty-free video coding format initially designed for video transmissions over the Internet.

It was developed as a successor to VP9 by the Alliance for Open Media (AOMedia), a consortium founded in 2015 that includes semiconductor firms, video on demand providers, video content producers, software development companies and web browser vendors.


现状
===========
* Netflix and yutube already support AV1
* 相比 H264, VP9, H265, AV1 在相同码率下 VMAF 和 MOS 值都是最高的，也是就质量最高



Statistic Performance Controller

cpu frequency



The AV1 library source code is stored in the Alliance for Open Media Git repository:


.. code-block::
    
    $ git clone https://aomedia.googlesource.com/aom
    # By default, the above command stores the source in the aom directory:
    $ cd aom



Reference
================
* https://en.wikipedia.org/wiki/AV1
* https://source.chromium.org/chromium/chromium/src/+/main:third_party/libaom/source/libaom/