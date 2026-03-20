
################################
GStreamer Development
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** GStreamer 应用与插件开发
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:


应用开发
=========================

GStreamer 应用开发的基本步骤：

1. 初始化 GStreamer
2. 创建 pipeline
3. 创建所需的 Element
4. 将 Element 放到 pipeline 中并连接
5. 设置相关属性和回调
6. 设置 pipeline 状态，启动主循环

C 语言示例
--------------------------

以一个测试视频回放流程为例：

.. code-block:: c

   #include <gst/gst.h>

   int main(int argc, char *argv[]) {
     GstElement *pipeline, *source, *sink;
     GstBus *bus;
     GstMessage *msg;
     GstStateChangeReturn ret;

     gst_init(&argc, &argv);

     source = gst_element_factory_make("videotestsrc", "source");
     sink = gst_element_factory_make("autovideosink", "sink");
     pipeline = gst_pipeline_new("test-pipeline");

     if (!pipeline || !source || !sink) {
       g_printerr("Not all elements could be created.\n");
       return -1;
     }

     gst_bin_add_many(GST_BIN(pipeline), source, sink, NULL);
     if (gst_element_link(source, sink) != TRUE) {
       g_printerr("Elements could not be linked.\n");
       gst_object_unref(pipeline);
       return -1;
     }

     g_object_set(source, "pattern", 0, NULL);

     ret = gst_element_set_state(pipeline, GST_STATE_PLAYING);
     if (ret == GST_STATE_CHANGE_FAILURE) {
       g_printerr("Unable to set the pipeline to the playing state.\n");
       gst_object_unref(pipeline);
       return -1;
     }

     bus = gst_element_get_bus(pipeline);
     msg = gst_bus_timed_pop_filtered(bus, GST_CLOCK_TIME_NONE,
             GST_MESSAGE_ERROR | GST_MESSAGE_EOS);

     if (msg != NULL) {
       GError *err;
       gchar *debug_info;
       switch (GST_MESSAGE_TYPE(msg)) {
         case GST_MESSAGE_ERROR:
           gst_message_parse_error(msg, &err, &debug_info);
           g_printerr("Error from %s: %s\n", GST_OBJECT_NAME(msg->src), err->message);
           g_printerr("Debug: %s\n", debug_info ? debug_info : "none");
           g_clear_error(&err);
           g_free(debug_info);
           break;
         case GST_MESSAGE_EOS:
           g_print("End-Of-Stream reached.\n");
           break;
         default:
           g_printerr("Unexpected message received.\n");
           break;
       }
       gst_message_unref(msg);
     }

     gst_object_unref(bus);
     gst_element_set_state(pipeline, GST_STATE_NULL);
     gst_object_unref(pipeline);
     return 0;
   }

编译：

.. code-block:: bash

   gcc basic.c -o basic $(pkg-config --cflags --libs gstreamer-1.0)


Python 绑定
=========================

GStreamer 通过 GObject Introspection 提供 Python 绑定，非常适合快速原型开发。

安装
--------------------------

.. code-block:: bash

   # Debian/Ubuntu
   sudo apt-get install python3-gi python3-gst-1.0 gir1.2-gst-plugins-base-1.0

   # pip (通用)
   pip install PyGObject

基本示例：播放测试视频
--------------------------

.. code-block:: python

   import gi
   gi.require_version('Gst', '1.0')
   from gi.repository import Gst, GLib

   Gst.init(None)

   pipeline = Gst.parse_launch("videotestsrc ! autovideosink")
   pipeline.set_state(Gst.State.PLAYING)

   loop = GLib.MainLoop()
   try:
       loop.run()
   except KeyboardInterrupt:
       pass

   pipeline.set_state(Gst.State.NULL)

RTP 发送示例
--------------------------

.. code-block:: python

   import gi
   gi.require_version('Gst', '1.0')
   from gi.repository import Gst, GLib

   Gst.init(None)

   pipeline = Gst.parse_launch(
       "videotestsrc ! videoconvert ! "
       "x264enc tune=zerolatency bitrate=500 ! "
       "rtph264pay pt=96 ! "
       "udpsink host=127.0.0.1 port=5004"
   )

   pipeline.set_state(Gst.State.PLAYING)

   loop = GLib.MainLoop()
   try:
       loop.run()
   except KeyboardInterrupt:
       pass

   pipeline.set_state(Gst.State.NULL)

动态 Pipeline 构建
--------------------------

.. code-block:: python

   import gi
   gi.require_version('Gst', '1.0')
   from gi.repository import Gst, GLib

   Gst.init(None)

   pipeline = Gst.Pipeline.new("dynamic-pipeline")
   source = Gst.ElementFactory.make("videotestsrc", "source")
   convert = Gst.ElementFactory.make("videoconvert", "convert")
   sink = Gst.ElementFactory.make("autovideosink", "sink")

   pipeline.add(source)
   pipeline.add(convert)
   pipeline.add(sink)

   source.link(convert)
   convert.link(sink)

   source.set_property("pattern", 0)

   pipeline.set_state(Gst.State.PLAYING)

   bus = pipeline.get_bus()
   msg = bus.timed_pop_filtered(
       Gst.CLOCK_TIME_NONE,
       Gst.MessageType.ERROR | Gst.MessageType.EOS
   )

   pipeline.set_state(Gst.State.NULL)


Pipeline 状态管理
=========================

GStreamer Pipeline 有四个状态：

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - 状态
     - 说明
   * - ``NULL``
     - 初始状态，未分配资源
   * - ``READY``
     - 已分配全局资源，但未打开设备
   * - ``PAUSED``
     - 已打开设备和流，但未处理数据（可预卷）
   * - ``PLAYING``
     - 正在处理数据，时钟运行中

状态转换必须按顺序进行：``NULL → READY → PAUSED → PLAYING``，反向亦然。

.. code-block:: c

   gst_element_set_state(pipeline, GST_STATE_PLAYING);
   // ...
   gst_element_set_state(pipeline, GST_STATE_NULL);


Bus 和消息
=========================

Bus 是 GStreamer 用于从 pipeline 线程向应用线程传递消息的机制。

常见消息类型：

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 消息类型
     - 说明
   * - ``GST_MESSAGE_ERROR``
     - 发生错误，pipeline 无法继续
   * - ``GST_MESSAGE_WARNING``
     - 发生警告，pipeline 可以继续
   * - ``GST_MESSAGE_EOS``
     - 流结束
   * - ``GST_MESSAGE_STATE_CHANGED``
     - Element 状态发生变化
   * - ``GST_MESSAGE_BUFFERING``
     - 缓冲进度
   * - ``GST_MESSAGE_LATENCY``
     - 延迟发生变化
   * - ``GST_MESSAGE_QOS``
     - QoS 相关信息


Pad 探针 (Probe)
=========================

Pad 探针允许在数据流过 Pad 时插入回调，用于：

- 监控数据流
- 动态修改 pipeline
- 实现数据注入或丢弃

.. code-block:: c

   static GstPadProbeReturn
   probe_callback(GstPad *pad, GstPadProbeInfo *info, gpointer user_data) {
     GstBuffer *buffer = GST_PAD_PROBE_INFO_BUFFER(info);
     g_print("Buffer timestamp: %" GST_TIME_FORMAT "\n",
             GST_TIME_ARGS(GST_BUFFER_TIMESTAMP(buffer)));
     return GST_PAD_PROBE_OK;
   }

   // 安装探针
   GstPad *pad = gst_element_get_static_pad(element, "src");
   gst_pad_add_probe(pad, GST_PAD_PROBE_TYPE_BUFFER, probe_callback, NULL, NULL);
   gst_object_unref(pad);


插件开发
=========================

GStreamer 的扩展性完全依赖插件系统。开发自定义插件的基本步骤：

获取模板
--------------------------

.. code-block:: bash

   git clone https://gitlab.freedesktop.org/gstreamer/gst-template.git
   cd gst-template/gst-plugin/src
   ../tools/make_element MyFilter

模板会自动生成头文件和实现文件。

插件开发步骤
--------------------------

1. 定义 Element 的数据结构（状态、属性）
2. 定义 Element 的类（继承 ``GstElement`` 或 ``GstBaseTransform`` 等）
3. 定义标准宏（类型检查、类型转换）
4. 实现 ``_class_init``：注册属性、Pad 模板、信号
5. 实现 ``_init``：初始化实例
6. 实现核心功能函数（如 ``chain``、``transform`` 等）
7. 实现 ``plugin_init``：注册 Element

头文件模板
--------------------------

.. code-block:: c

   #ifndef __GST_MYFILTER_H__
   #define __GST_MYFILTER_H__

   #include <gst/gst.h>

   G_BEGIN_DECLS

   #define GST_TYPE_MYFILTER (gst_my_filter_get_type())
   #define GST_MYFILTER(obj) \
     (G_TYPE_CHECK_INSTANCE_CAST((obj), GST_TYPE_MYFILTER, GstMyFilter))

   typedef struct _GstMyFilter {
     GstElement element;
     GstPad *sinkpad, *srcpad;
     gboolean silent;
   } GstMyFilter;

   typedef struct _GstMyFilterClass {
     GstElementClass parent_class;
   } GstMyFilterClass;

   GType gst_my_filter_get_type(void);

   G_END_DECLS
   #endif

基类选择
--------------------------

根据插件类型选择合适的基类：

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - 基类
     - 适用场景
   * - ``GstElement``
     - 最通用的基类，完全自定义
   * - ``GstBaseSrc``
     - 数据源（push/pull 模式）
   * - ``GstBaseSink``
     - 数据消费者
   * - ``GstBaseTransform``
     - 1:1 数据转换（如滤镜）
   * - ``GstAudioFilter``
     - 音频滤镜
   * - ``GstVideoFilter``
     - 视频滤镜

使用 Docker 开发
--------------------------

.. code-block:: bash

   docker run --name gst_dev --rm -it \
     -v $(pwd):/workspace \
     restreamio/gstreamer:latest-dev-with-source /bin/bash


调试技巧
=========================

日志系统
--------------------------

.. code-block:: bash

   # 全局日志级别
   GST_DEBUG=3 gst-launch-1.0 ...

   # 特定模块
   GST_DEBUG=webrtcbin:5,dtlstransport:4 gst-launch-1.0 ...

   # 日志格式
   GST_DEBUG_COLOR_MODE=off GST_DEBUG_FILE=gst.log GST_DEBUG=4 gst-launch-1.0 ...

Pipeline 图形化
--------------------------

.. code-block:: bash

   export GST_DEBUG_DUMP_DOT_DIR=/tmp/dots
   gst-launch-1.0 ...

   # 转换为图片
   dot -Tpng /tmp/dots/0.00.00*.dot -o pipeline.png

内存调试
--------------------------

.. code-block:: bash

   # 检测内存泄漏
   GST_DEBUG="GST_REFCOUNTING:5" gst-launch-1.0 ...

性能分析
--------------------------

.. code-block:: bash

   # 显示 pipeline 延迟
   gst-launch-1.0 -v ... 2>&1 | grep -i latency

   # 使用 tracer
   GST_TRACERS="latency" GST_DEBUG=GST_TRACER:7 gst-launch-1.0 ...


参考
===================

- GObject 文档: https://docs.gtk.org/gobject/
- GStreamer 应用开发手册: https://gstreamer.freedesktop.org/documentation/application-development/index.html
- GStreamer 插件开发指南: https://gstreamer.freedesktop.org/documentation/plugin-development/index.html
- GStreamer Core API: https://gstreamer.freedesktop.org/documentation/gstreamer/gi-index.html
- GStreamer Python 教程: https://gstreamer.freedesktop.org/documentation/tutorials/index.html
- PyGObject API: https://lazka.github.io/pgi-docs/Gst-1.0/
