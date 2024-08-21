:orphan:

################################
GStreamer Development
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** GStreamer Development
**Category** Learning note
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


应用开发
=========================
以一个测试视频回放流程为例

1. 初始化 GStreamer:
2. 创建 pipeline
3. 创建所需的 element
4. 将 element 放到 pipeline 中，并连接它们
5. 设置好相关属性和回调
6. 设置 pipeline 状态，启动主循环

示例

.. code-block:: c

   #include <gst/gst.h>

   int
   main (int argc, char *argv[])
   {
      GstElement *pipeline, *source, *sink;
      GstBus *bus;
      GstMessage *msg;
      GstStateChangeReturn ret;

      /* Initialize GStreamer */
      gst_init (&argc, &argv);

      /* Create the elements */
      source = gst_element_factory_make ("videotestsrc", "source");
      sink = gst_element_factory_make ("autovideosink", "sink");

      /* Create the empty pipeline */
      pipeline = gst_pipeline_new ("test-pipeline");

      if (!pipeline || !source || !sink) {
         g_printerr ("Not all elements could be created.\n");
         return -1;
      }

      /* Build the pipeline */
      gst_bin_add_many (GST_BIN (pipeline), source, sink, NULL);
      if (gst_element_link (source, sink) != TRUE) {
         g_printerr ("Elements could not be linked.\n");
         gst_object_unref (pipeline);
         return -1;
      }

      /* Modify the source's properties */
      g_object_set (source, "pattern", 0, NULL);

      /* Start playing */
      ret = gst_element_set_state (pipeline, GST_STATE_PLAYING);
      if (ret == GST_STATE_CHANGE_FAILURE) {
         g_printerr ("Unable to set the pipeline to the playing state.\n");
         gst_object_unref (pipeline);
         return -1;
      }

      /* Wait until error or EOS */
      bus = gst_element_get_bus (pipeline);
      msg =
            gst_bus_timed_pop_filtered (bus, GST_CLOCK_TIME_NONE,
            GST_MESSAGE_ERROR | GST_MESSAGE_EOS);

      /* Parse message */
      if (msg != NULL) {
         GError *err;
         gchar *debug_info;

         switch (GST_MESSAGE_TYPE (msg)) {
            case GST_MESSAGE_ERROR:
               gst_message_parse_error (msg, &err, &debug_info);
               g_printerr ("Error received from element %s: %s\n",
                     GST_OBJECT_NAME (msg->src), err->message);
               g_printerr ("Debugging information: %s\n",
                     debug_info ? debug_info : "none");
               g_clear_error (&err);
               g_free (debug_info);
               break;
            case GST_MESSAGE_EOS:
               g_print ("End-Of-Stream reached.\n");
               break;
            default:
               /* We should not reach here because we only asked for ERRORs and EOS */
               g_printerr ("Unexpected message received.\n");
               break;
         }
         gst_message_unref (msg);
      }

      /* Free resources */
      gst_object_unref (bus);
      gst_element_set_state (pipeline, GST_STATE_NULL);
      gst_object_unref (pipeline);
      return 0;
   }

插件开发
=========================
以一个 filter 插件为例


.. code-block::

   git clone https://gitlab.freedesktop.org/gstreamer/gst-template.git
   cd gst-template/gst-plugin/src
   ../tools/make_element MyFilter

由模板自动生成的代码如下

.. code-block::

   #ifndef __GST_MYFILTER_H__
   #define __GST_MYFILTER_H__

   #include <gst/gst.h>

   G_BEGIN_DECLS

   /* #defines don't like whitespacey bits */
   #define GST_TYPE_MYFILTER \
   (gst_my_filter_get_type())
   #define GST_MYFILTER(obj) \
   (G_TYPE_CHECK_INSTANCE_CAST((obj),GST_TYPE_MYFILTER,GstMyFilter))
   #define GST_MYFILTER_CLASS(klass) \
   (G_TYPE_CHECK_CLASS_CAST((klass),GST_TYPE_MYFILTER,GstMyFilterClass))
   #define GST_IS_MYFILTER(obj) \
   (G_TYPE_CHECK_INSTANCE_TYPE((obj),GST_TYPE_MYFILTER))
   #define GST_IS_MYFILTER_CLASS(klass) \
   (G_TYPE_CHECK_CLASS_TYPE((klass),GST_TYPE_MYFILTER))

   typedef struct _GstMyFilter      GstMyFilter;
   typedef struct _GstMyFilterClass GstMyFilterClass;

   struct _GstMyFilter
   {
      GstElement element;

      GstPad *sinkpad, *srcpad;

      gboolean silent;
   };

   struct _GstMyFilterClass
   {
      GstElementClass parent_class;
   };

   GType gst_my_filter_get_type (void);

   G_END_DECLS

   #endif /* __GST_MYFILTER_H__ */



1. 获取插件模板
2. 设置新的 element 的属性，如名称，作者，版本号
3. 注册此插件 `_class_init`
4. 定义新的 element 所需的 pad 及其属性，类型及其所支持类型的列表
5. 实现 plugin_init 函数，在插件加载后立即调用
6. 实现



Reference
===================
* GObject 2.0 doc: https://docs.gtk.org/gobject/
* GObject ParamSpec: https://docs.gtk.org/gobject/class.ParamSpec.html
* gstparamspec: https://gstreamer.freedesktop.org/documentation/gstreamer/gstparamspec.html?gi-language=c#gst_param_spec_array
* GStreamer Doc: https://gstreamer.freedesktop.org/documentation/?gi-language=c
* Core Library API: https://gstreamer.freedesktop.org/documentation/gstreamer/gi-index.html?gi-language=c
* https://blog.csdn.net/hello_dear_you/article/details/121441608
* https://blog.csdn.net/hktkfly6/article/details/53643784
* https://blog.csdn.net/weixin_41944449/article/details/81267842
* https://gstreamer.freedesktop.org/documentation/tutorials/playback/playbin-usage.html?gi-language=c
* https://gstreamer.freedesktop.org/documentation/plugin-development/basics/boiler.html?gi-language=c