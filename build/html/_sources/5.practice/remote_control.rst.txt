###################
Remote Control
###################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Remote Control
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


Overview
========================

远程控制最经典的应用大概就是 Windows 的远程桌面了, 还有大名鼎鼎的 VNC 和 RDP 协议

* VNC (Virtual Network Computing)
* RDP (Remote Desktop Protocol)


Methods
===================
总体来讲, 我们需要在控制者和被控制者之间建立一条连接, 被控制者这一方需要仔细考虑权限, 隐私和安全保护.
在被控制者一方, 需要解释来自远程的命令, 解释执行后, 将执行结果或者将其所看到的桌面分享给远程的控制者


也可以通过 WebRTC 技术为已有的 VNC 或 RDP 来做一个网关

* Set up a WebRTC-based signaling mechanism:

  Establish a signaling mechanism using WebRTC to facilitate communication between the controlling client
  and the remote desktop client.

  This allows the clients to exchange session description protocols (SDPs) and ICE candidates.

* Implement a gateway or bridge:

  Create a server-side component that acts as a bridge between the WebRTC protocol and the VNC or RDP protocol.
  This component will receive control commands from the controlling client over the WebRTC data channel
  and convert them into corresponding VNC or RDP commands.

* Establish VNC or RDP connection:

  Once the control commands are received by the server-side component, it establishes a VNC or RDP connection
  with the remote desktop using the appropriate protocol.

  This connection allows the server-side component to send control commands to the remote desktop and receive screen updates.

* Transmit screen updates via WebRTC:

  As the remote desktop client sends screen updates to the server-side component over VNC or RDP,
  the component can convert those updates into video frames and transmit them as a WebRTC video stream to the controlling client.

  The controlling client can render these video frames to display the remote desktop's screen content.

* Handle input events:

  On the controlling client side, capture user input events such as mouse movements and keyboard inputs.
  Send these events to the server-side component over the WebRTC data channel.

  The server-side component converts the input events into corresponding VNC or RDP commands and sends them to the remote desktop client.
