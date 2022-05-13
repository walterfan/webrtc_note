################
视频聊天实例
################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** 视频聊天实例
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================

.. contents::
   :local:

总体设计
================

components
----------------
1. a web application contains 
   * room name
   * user name
   * join button
   * leave button
   * open camera/mic button
   * close camera/mic button
   * roster list: attendee name, attendee video, attendee message

2. signal server
   * http service
   * websocket service
   * room management
   * roster management: accept, reject, expel attendee

3. turn server
   leverage coturn

4. media server
   * dtls and srtp service
   * switch RTP packets among the attendeess in a room