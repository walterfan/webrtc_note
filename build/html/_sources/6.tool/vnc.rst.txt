########################
VNC vs. RDP
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Linux Traffic Control
**Authors**  Walter Fan
**Status**   v1
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:


Overview
=========================

RDP
-------------------------
Remote Desktop Protocol, or RDP, is a proprietary protocol that allows its users to graphically control a remote computer. 

RDP is usually intended for 1:1 usage, and many remote computers can share the resources of a main computer through different profiles. Being Microsoft’s proprietary protocol, RDP  works only with Windows systems, although the client is available for nearly all operating systems such as Mac, Android, and Linux.  

VNC
-------------------------
Virtual Network Computing, or VNC, is a graphical desktop sharing system that lets its users remotely control a computer while the main user can interact and watch. It is pixel-based, which means it is more flexible than RDP. 

VNC is platform-independent, which means it can easily be used across Mac, Windows, Linux, Raspberry Pi, and other platforms to share a desktop across different computers, and there are no limits in using VNC applications to connect to different computers on different platforms.  



Reference
=========================
* https://serverspace.io/support/help/install-tightvnc-server-on-ubuntu-20-04/
* https://discover.realvnc.com/blog/vnc-vs-rdp-which-remote-desktop-tool-is-best