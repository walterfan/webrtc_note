
################################
GStreamer WebRTC
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** GStreamer WebRTC 开发
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:


概述
======================================

GStreamer 通过 ``webrtcbin`` 插件提供完整的 WebRTC 支持，可以用于：

- 与浏览器建立 WebRTC 连接
- 构建 WebRTC 服务端（SFU、MCU、录制服务器等）
- 发送和接收音视频流
- DataChannel 数据传输

``webrtcbin`` 内部集成了 ICE（通过 libnice）、DTLS、SRTP、SCTP 等 WebRTC 必需的协议栈。


安装
======================================

.. code-block:: bash

   # Debian/Ubuntu
   sudo apt-get install -y \
     gstreamer1.0-tools \
     gstreamer1.0-nice \
     gstreamer1.0-plugins-bad \
     gstreamer1.0-plugins-good \
     gstreamer1.0-plugins-ugly \
     gstreamer1.0-libav \
     libgstreamer1.0-dev \
     libgstreamer-plugins-bad1.0-dev \
     libglib2.0-dev \
     libsoup2.4-dev \
     libjson-glib-dev

验证安装：

.. code-block:: bash

   gst-inspect-1.0 webrtcbin


webrtcbin 类层次
======================================

.. code-block:: text

   GInitiallyUnowned
     └── GstObject
           └── GstElement
                 └── GstBin
                       └── GstWebRTCBin

``webrtcbin`` 是一个 Bin，内部封装了 ICE agent、DTLS transport、RTP/RTCP 处理等组件。

**Pad**：

- ``GstWebRTCBinSinkPad``：接收本地媒体数据（发送给远端）
- ``GstWebRTCBinSrcPad``：输出远端媒体数据（接收自远端）

Sink Pad 通过请求（request）方式创建，命名格式为 ``sink_%u``。
Source Pad 在远端媒体到达时自动创建（sometimes pad）。


核心信号
======================================

``webrtcbin`` 通过信号（signals）与应用代码交互：

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - 信号
     - 说明
   * - ``on-negotiation-needed``
     - 需要重新协商时触发（如添加了新的 Track），应在此创建 Offer
   * - ``on-ice-candidate``
     - 收集到新的 ICE Candidate 时触发，需发送给远端
   * - ``on-new-transceiver``
     - 新的 transceiver 被创建时触发
   * - ``on-data-channel``
     - 远端创建的 DataChannel 到达时触发
   * - ``prepare-data-channel``
     - DataChannel 准备就绪时触发（本地或远端）

**信号回调签名**：

.. code-block:: c

   // on-negotiation-needed
   void on_negotiation_needed(GstElement *webrtcbin, gpointer user_data);

   // on-ice-candidate
   void on_ice_candidate(GstElement *webrtcbin, guint mline_index,
                         gchar *candidate, gpointer user_data);

   // on-data-channel
   void on_data_channel(GstElement *webrtcbin, GstWebRTCDataChannel *channel,
                        gpointer user_data);


Action 信号
======================================

Action 信号用于主动调用 ``webrtcbin`` 的功能：

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Action 信号
     - 说明
   * - ``create-offer``
     - 创建 SDP Offer
   * - ``create-answer``
     - 创建 SDP Answer
   * - ``set-local-description``
     - 设置本地 SDP
   * - ``set-remote-description``
     - 设置远端 SDP
   * - ``add-ice-candidate``
     - 添加远端 ICE Candidate
   * - ``get-stats``
     - 获取 WebRTC 统计信息
   * - ``add-transceiver``
     - 添加 transceiver
   * - ``create-data-channel``
     - 创建 DataChannel


核心属性
======================================

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - 属性
     - 说明
   * - ``stun-server``
     - STUN 服务器地址，如 ``stun://stun.l.google.com:19302``
   * - ``turn-server``
     - TURN 服务器地址，如 ``turn://user:pass@turn.example.com:3478``
   * - ``bundle-policy``
     - BUNDLE 策略：``none``, ``balanced``, ``max-compat``, ``max-bundle``
   * - ``ice-transport-policy``
     - ICE 传输策略：``all``, ``relay``
   * - ``connection-state``
     - 当前连接状态（只读）
   * - ``ice-connection-state``
     - ICE 连接状态（只读）
   * - ``ice-gathering-state``
     - ICE 收集状态（只读）
   * - ``signaling-state``
     - 信令状态（只读）
   * - ``local-description``
     - 本地 SDP（只读）
   * - ``remote-description``
     - 远端 SDP（只读）


连接流程
======================================

使用 ``webrtcbin`` 建立 WebRTC 连接的典型流程：

.. code-block:: text

   应用层                    webrtcbin                      远端
     │                          │                            │
     │  add media elements      │                            │
     │─────────────────────────►│                            │
     │                          │                            │
     │  on-negotiation-needed   │                            │
     │◄─────────────────────────│                            │
     │                          │                            │
     │  create-offer             │                            │
     │─────────────────────────►│                            │
     │  set-local-description   │                            │
     │─────────────────────────►│                            │
     │                          │                            │
     │  send offer via signaling │───────────────────────────►│
     │                          │                            │
     │  receive answer          │◄───────────────────────────│
     │  set-remote-description  │                            │
     │─────────────────────────►│                            │
     │                          │                            │
     │  on-ice-candidate        │                            │
     │◄─────────────────────────│                            │
     │  send candidate          │───────────────────────────►│
     │                          │                            │
     │  receive candidate       │◄───────────────────────────│
     │  add-ice-candidate       │                            │
     │─────────────────────────►│                            │
     │                          │                            │
     │                    ICE connected, DTLS handshake       │
     │                    Media flowing                       │


发送端示例 (C)
======================================

以下示例展示如何用 ``webrtcbin`` 发送测试视频和音频。信令部分需要自行实现（WebSocket、HTTP 等）。

.. code-block:: c

   #include <gst/gst.h>
   #include <gst/webrtc/webrtc.h>

   static GstElement *webrtcbin;

   static void on_negotiation_needed(GstElement *element, gpointer user_data) {
     GstPromise *promise = gst_promise_new_with_change_func(
       on_offer_created, user_data, NULL);
     g_signal_emit_by_name(webrtcbin, "create-offer", NULL, promise);
   }

   static void on_ice_candidate(GstElement *element, guint mline_index,
                                gchar *candidate, gpointer user_data) {
     // Send candidate to remote peer via signaling
     send_ice_candidate_to_peer(mline_index, candidate);
   }

   int main(int argc, char *argv[]) {
     gst_init(&argc, &argv);

     GstElement *pipeline = gst_parse_launch(
       "videotestsrc pattern=ball ! videoconvert ! vp8enc deadline=1 ! "
       "rtpvp8pay pt=96 ! "
       "webrtcbin name=sendrecv stun-server=stun://stun.l.google.com:19302",
       NULL);

     webrtcbin = gst_bin_get_by_name(GST_BIN(pipeline), "sendrecv");

     g_signal_connect(webrtcbin, "on-negotiation-needed",
                      G_CALLBACK(on_negotiation_needed), NULL);
     g_signal_connect(webrtcbin, "on-ice-candidate",
                      G_CALLBACK(on_ice_candidate), NULL);

     gst_element_set_state(pipeline, GST_STATE_PLAYING);

     // Run main loop (with signaling server connection)
     GMainLoop *loop = g_main_loop_new(NULL, FALSE);
     g_main_loop_run(loop);

     gst_element_set_state(pipeline, GST_STATE_NULL);
     gst_object_unref(pipeline);
     return 0;
   }


发送端示例 (Python)
======================================

.. code-block:: python

   import gi
   gi.require_version('Gst', '1.0')
   gi.require_version('GstWebRTC', '1.0')
   gi.require_version('GstSdp', '1.0')
   from gi.repository import Gst, GstWebRTC, GstSdp, GLib

   Gst.init(None)

   PIPELINE = """
     videotestsrc pattern=ball ! videoconvert ! vp8enc deadline=1 !
     rtpvp8pay pt=96 !
     webrtcbin name=sendrecv stun-server=stun://stun.l.google.com:19302
   """

   pipe = Gst.parse_launch(PIPELINE)
   webrtc = pipe.get_by_name('sendrecv')

   def on_negotiation_needed(element):
       promise = Gst.Promise.new_with_change_func(on_offer_created, element, None)
       element.emit('create-offer', None, promise)

   def on_offer_created(promise, element, _):
       promise.wait()
       reply = promise.get_reply()
       offer = reply.get_value('offer')
       promise2 = Gst.Promise.new()
       element.emit('set-local-description', offer, promise2)
       promise2.interrupt()
       # Send offer.sdp.as_text() to remote peer via signaling
       send_sdp_offer(offer.sdp.as_text())

   def on_ice_candidate(element, mline_index, candidate):
       # Send candidate to remote peer via signaling
       send_ice_candidate(mline_index, candidate)

   webrtc.connect('on-negotiation-needed', on_negotiation_needed)
   webrtc.connect('on-ice-candidate', on_ice_candidate)

   pipe.set_state(Gst.State.PLAYING)

   loop = GLib.MainLoop()
   try:
       loop.run()
   except KeyboardInterrupt:
       pass

   pipe.set_state(Gst.State.NULL)


接收端处理
======================================

当远端发送媒体过来时，``webrtcbin`` 会创建新的 source pad。通过 ``pad-added`` 信号处理：

.. code-block:: python

   def on_incoming_stream(element, pad):
       if pad.direction != Gst.PadDirection.SRC:
           return

       decodebin = Gst.ElementFactory.make('decodebin')
       decodebin.connect('pad-added', on_decoded_pad)
       pipe.add(decodebin)
       decodebin.sync_state_with_parent()
       pad.link(decodebin.get_static_pad('sink'))

   def on_decoded_pad(decodebin, pad):
       caps = pad.get_current_caps()
       name = caps.to_string()
       if name.startswith('video'):
           q = Gst.ElementFactory.make('queue')
           conv = Gst.ElementFactory.make('videoconvert')
           sink = Gst.ElementFactory.make('autovideosink')
           pipe.add(q, conv, sink)
           q.sync_state_with_parent()
           conv.sync_state_with_parent()
           sink.sync_state_with_parent()
           pad.link(q.get_static_pad('sink'))
           q.link(conv)
           conv.link(sink)
       elif name.startswith('audio'):
           q = Gst.ElementFactory.make('queue')
           conv = Gst.ElementFactory.make('audioconvert')
           sink = Gst.ElementFactory.make('autoaudiosink')
           pipe.add(q, conv, sink)
           q.sync_state_with_parent()
           conv.sync_state_with_parent()
           sink.sync_state_with_parent()
           pad.link(q.get_static_pad('sink'))
           q.link(conv)
           conv.link(sink)

   webrtc.connect('pad-added', on_incoming_stream)


设置远端 SDP 和 ICE Candidate
======================================

收到远端的 Answer 或 Offer 后：

.. code-block:: python

   from gi.repository import GstSdp, GstWebRTC

   def set_remote_description(sdp_text, sdp_type='answer'):
       if sdp_type == 'answer':
           t = GstWebRTC.WebRTCSDPType.ANSWER
       else:
           t = GstWebRTC.WebRTCSDPType.OFFER

       _, sdpmsg = GstSdp.SDPMessage.new_from_text(sdp_text)
       answer = GstWebRTC.WebRTCSessionDescription.new(t, sdpmsg)
       promise = Gst.Promise.new()
       webrtc.emit('set-remote-description', answer, promise)
       promise.interrupt()

   def add_ice_candidate(mline_index, candidate):
       webrtc.emit('add-ice-candidate', mline_index, candidate)


DataChannel
======================================

创建 DataChannel
--------------------------

.. code-block:: python

   channel = webrtc.emit('create-data-channel', 'my-channel', None)

   def on_open(channel):
       channel.emit('send-string', 'Hello from GStreamer!')

   def on_message_string(channel, message):
       print(f'Received: {message}')

   channel.connect('on-open', on_open)
   channel.connect('on-message-string', on_message_string)

接收远端 DataChannel
--------------------------

.. code-block:: python

   def on_data_channel(webrtcbin, channel):
       channel.connect('on-message-string', on_message_string)

   webrtc.connect('on-data-channel', on_data_channel)


常用 Pipeline 模式
======================================

发送摄像头 + 麦克风
--------------------------

.. code-block:: bash

   gst-launch-1.0 \
     v4l2src ! videoconvert ! vp8enc deadline=1 ! rtpvp8pay pt=96 ! \
     webrtcbin name=sendrecv stun-server=stun://stun.l.google.com:19302 \
     autoaudiosrc ! audioconvert ! opusenc ! rtpopuspay pt=111 ! sendrecv.

发送屏幕共享 (Linux)
--------------------------

.. code-block:: bash

   gst-launch-1.0 \
     ximagesrc ! video/x-raw,framerate=15/1 ! videoconvert ! \
     vp8enc deadline=1 target-bitrate=1000000 ! rtpvp8pay pt=96 ! \
     webrtcbin name=sendrecv stun-server=stun://stun.l.google.com:19302

录制 WebRTC 接收的流
--------------------------

.. code-block:: text

   webrtcbin → decodebin → videoconvert → x264enc → mp4mux → filesink
                         → audioconvert → opusenc ↗


调试
======================================

.. code-block:: bash

   # 开启 WebRTC 相关的详细日志
   GST_DEBUG=webrtc*:5,dtls*:5,nice*:4,sctp*:4 gst-launch-1.0 ...

   # 导出 pipeline 图
   GST_DEBUG_DUMP_DOT_DIR=/tmp/dots gst-launch-1.0 ...

   # 查看 webrtcbin 的所有属性
   gst-inspect-1.0 webrtcbin


官方示例
======================================

GStreamer 提供了完整的 WebRTC 示例，包括 C、Python、JavaScript、Rust 版本：

.. code-block:: bash

   git clone https://gitlab.freedesktop.org/gstreamer/gst-examples.git
   cd gst-examples/webrtc

示例包括：

- ``sendrecv/``：1:1 音视频通话（C、Python、JavaScript）
- ``multiparty-sendrecv/``：多人通话
- ``signalling/``：Python 信令服务器

社区示例：

- https://github.com/nickoala/aspect：Python + asyncio + WebSocket 的完整示例
- https://github.com/niccokunzmann/gstreamer-webrtc-tutorial：入门教程


参考
===========================

- webrtcbin 文档: https://gstreamer.freedesktop.org/documentation/webrtc/
- GStreamer WebRTC 示例: https://gitlab.freedesktop.org/gstreamer/gst-examples/-/tree/master/webrtc
- libnice (ICE): https://libnice.freedesktop.org/
- Pion WebRTC (Go 替代方案): https://github.com/pion/webrtc
