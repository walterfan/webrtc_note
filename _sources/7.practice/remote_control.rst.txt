###################
Remote Control
###################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** 基于 WebRTC 的远程控制
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:


概述
========================

远程控制（Remote Desktop）允许用户通过网络操作远处的计算机。
传统方案如 VNC 和 RDP 已广泛使用，而 WebRTC 技术为远程控制带来了新的可能：

- **浏览器原生支持**：无需安装客户端
- **NAT 穿透**：ICE/TURN 自动处理复杂网络环境
- **低延迟**：端到端优化的媒体传输
- **加密传输**：DTLS/SRTP 保证安全性


传统协议对比
===================

.. list-table::
   :header-rows: 1
   :widths: 15 30 30 25

   * - 协议
     - 优势
     - 劣势
     - 场景
   * - **VNC**
     - 跨平台、开源、基于像素
     - 带宽消耗大、无音频
     - Linux 服务器管理
   * - **RDP**
     - 高效压缩、音频重定向、剪贴板同步
     - 仅 Windows 服务端
     - Windows 远程办公
   * - **WebRTC**
     - 浏览器原生、NAT 穿透、低延迟
     - 需要自建信令
     - Web 远程桌面


WebRTC 远程控制架构
========================

.. code-block:: text

   ┌─────────────────────┐                    ┌─────────────────────┐
   │   控制端 (浏览器)    │                    │   被控端 (Agent)     │
   │                     │                    │                     │
   │  显示远程画面 ◄──────── Video Track ────── 屏幕采集            │
   │  (video element)    │                    │  (getDisplayMedia   │
   │                     │                    │   或原生采集)        │
   │  键盘/鼠标事件 ──────── DataChannel ────►  解释执行            │
   │  (keydown/mousemove)│                    │  (模拟输入事件)      │
   │                     │                    │                     │
   │  音频播放 ◄──────────── Audio Track ────── 系统音频采集         │
   └─────────────────────┘                    └─────────────────────┘
               │                                       │
               └───── WebRTC P2P (ICE/DTLS/SRTP) ──────┘

核心组件：

1. **屏幕采集**：被控端捕获桌面画面作为视频流
2. **视频传输**：通过 WebRTC Video Track 实时传送
3. **输入事件传输**：控制端通过 DataChannel 发送鼠标/键盘事件
4. **输入模拟**：被控端将收到的事件转化为系统级输入


DataChannel 控制协议设计
============================

控制端通过 DataChannel 发送 JSON 格式的控制指令：

.. code-block:: javascript

   // 鼠标移动
   dataChannel.send(JSON.stringify({
       type: 'mousemove',
       x: 0.5,    // 归一化坐标 (0-1)
       y: 0.3,
       timestamp: Date.now()
   }));

   // 鼠标点击
   dataChannel.send(JSON.stringify({
       type: 'mousedown',
       button: 0,  // 0=左键, 1=中键, 2=右键
       x: 0.5,
       y: 0.3
   }));

   // 键盘事件
   dataChannel.send(JSON.stringify({
       type: 'keydown',
       key: 'a',
       code: 'KeyA',
       modifiers: { ctrl: false, shift: false, alt: false }
   }));

   // 剪贴板同步
   dataChannel.send(JSON.stringify({
       type: 'clipboard',
       text: 'copied text content'
   }));

使用归一化坐标（0-1）而非像素坐标，可以适应控制端和被控端不同的屏幕分辨率。


WebRTC 作为 VNC/RDP 网关
============================

WebRTC 也可以不替代 VNC/RDP，而是作为前端网关：

.. code-block:: text

   浏览器 ◄── WebRTC ──► Gateway ◄── VNC/RDP ──► 远程桌面

   Gateway 职责：
   ├── WebRTC 信令处理
   ├── VNC/RDP 画面 → WebRTC 视频流转码
   ├── WebRTC DataChannel 输入 → VNC/RDP 输入指令
   └── 管理多个远程桌面会话

开源实现参考：

- **noVNC**：浏览器 VNC 客户端（WebSocket，非 WebRTC）
- **Apache Guacamole**：Web 远程桌面网关（支持 VNC/RDP/SSH）
- **neko**：基于 WebRTC 的虚拟浏览器（Docker + GStreamer + Pion）


关键技术挑战
========================

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 挑战
     - 解决方案
   * - 延迟敏感
     - 使用硬件编码（NVENC/VAAPI），优先帧率而非分辨率
   * - 输入精度
     - 归一化坐标 + 被控端分辨率映射
   * - 安全性
     - 认证、权限控制、会话超时、审计日志
   * - 跨平台采集
     - Windows: DXGI/GDI，macOS: CGDisplay/AVFoundation，Linux: X11/PipeWire
   * - 高 DPI
     - 处理设备像素比（devicePixelRatio）映射


参考资料
========================

- noVNC: https://novnc.com/
- Apache Guacamole: https://guacamole.apache.org/
- neko (WebRTC virtual browser): https://github.com/m1k1o/neko
- 另见 :doc:`../8.tool/vnc`
