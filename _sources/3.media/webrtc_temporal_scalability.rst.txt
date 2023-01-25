################################
Temporal scalability
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** Temporal scalability
**Category** Learning note
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:


概述
===========================   

在时间可伸缩性(temporal scalability)的情况下，帧序列(the sequence of frames)以某种方式编码，
以便可以在服务器中丢弃一些帧，并且仍然可以在接收器端解码得到的帧序列。


In video coding, temporal scalability is the option to decode only some of the frames in a video stream instead of the whole stream. This enables an SFU for example to reduce the bitrate sent towards viewers who doesn’t have enough bitrate or CPU to handle the whole stream. It also assists devices that miss a packet to continue decoding the stream partially until an intra-frame is received.

* Temporal scalability is one of the scalability aspects usually attributed to SVC.
* H.264 AVC also support Temporal scalability already
* It is available for WebRTC in VP8 without the implementation of SVC.


for example
* layer t1: discardable  ~ 30% 
* layer t0: cannot discardable ~ 70%


参考
==========================
* [1] “Advanced Video Coding for Generic Audiovisual Services,” ITU-T, Tech. Rep. Recommendation H.264 & ISO/IEC 14496-10 AVC, v3,2005.
* [2] J. Ostermann, J .Bormans, P. List, D. Marpe, N. Narroschke, F. Pereira,T. Stockhammer, and T. Wedi, “Video Coding with H.264/AVC: Tools, Performance and Complexity,” IEEE Circuits and Systems Magazine,vol.4, no.1,pp. 7-28, April 2004.
* [3] H. Schwarz, D .Marpe, and T. Wiegand, “Overview of the Scalable Video Coding Extension of the H.264/ AVC Standard,” IEEE Transactions on Circuits and Systems for Video Technology, vol.17,no.9, pp. 1103-1120, September 2007.
* [4] “Advanced Video Coding for Generic Audiovisual Services, Annex G,” ITU-T, Tech. Rep. Recommendation H.264 & ISO/IEC 14496-10 AVC/Amd.3 Scalable Video Coding, November 2007.