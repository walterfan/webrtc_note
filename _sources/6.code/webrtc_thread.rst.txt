##############################
WebRTC Thread Model
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC 线程模型
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
=============

WebRTC 的线程模型是其架构的核心，理解它是阅读源码的前提。
WebRTC 使用三个主要线程，每个线程有明确的职责边界和严格的调用规则。

.. code-block:: text

   ┌──────────────────────────────────────────────────────┐
   │                  应用层 (JavaScript / Native API)     │
   └──────────┬───────────────────────────────────────────┘
              │ API 调用 & 回调
   ┌──────────▼───────────────────────────────────────────┐
   │              Signaling Thread (信令线程)              │
   │  - PeerConnection 的 API 入口                        │
   │  - SDP 创建与解析                                    │
   │  - Observer 回调                                     │
   └──────┬──────────────────────────┬────────────────────┘
          │ 同步调用                  │ 同步调用
   ┌──────▼────────────┐    ┌───────▼─────────────────────┐
   │  Worker Thread    │    │   Network Thread             │
   │  (工作线程)        │    │   (网络线程)                  │
   │                   │    │                              │
   │  - 编解码          │───►│  - ICE/DTLS/SRTP             │
   │  - 媒体处理        │    │  - Socket 读写               │
   │  - 拥塞控制        │    │  - 数据收发                   │
   │  - 音频设备管理    │    │  - TURN 中继                  │
   └───────────────────┘    └──────────────────────────────┘

调用规则
==============

WebRTC 对线程间调用有严格约束，违反会触发 ``RTC_DCHECK`` 断言：

.. list-table::
   :header-rows: 1
   :widths: 25 25 50

   * - 调用方
     - 可调用
     - 说明
   * - Signaling Thread
     - Worker Thread
     - 同步调用（阻塞等待结果）
   * - Worker Thread
     - Network Thread
     - 同步调用
   * - Network Thread
     - （无）
     - 不能被其他线程阻塞，也不能同步调用其他线程
   * - 任意线程
     - 任意线程
     - 可以异步 Post 消息（非阻塞）

关键原则：**Network Thread 永远不能被阻塞**，因为它直接处理网络 I/O，
阻塞会导致丢包和连接超时。


核心类
======================

Thread
----------------------

``rtc::Thread`` 是 WebRTC 的线程基类，内部维护一个消息队列（TaskQueue）。

.. code-block:: c++

   class Thread : public TaskQueueBase {
   public:
       // 在目标线程上同步执行（阻塞当前线程）
       template <typename Functor>
       auto Invoke(const Location& posted_from, Functor&& functor);

       // 在目标线程上异步执行（不阻塞）
       void PostTask(absl::AnyInvocable<void() &&> task);

       // 延迟执行
       void PostDelayedTask(absl::AnyInvocable<void() &&> task,
                            TimeDelta delay);

       // 启动线程消息循环
       void Run();

       // 停止线程
       void Stop();

       // 获取当前线程
       static Thread* Current();
   };

- ``Invoke()``：跨线程同步调用，内部通过消息队列传递任务并等待完成
- ``PostTask()``：异步投递，不等待结果
- ``RTC_DCHECK_RUN_ON(thread)``：编译期+运行期检查当前是否在指定线程上


TaskQueue
----------------------

``TaskQueueBase`` 是更轻量的任务队列抽象，不一定绑定 OS 线程：

.. code-block:: c++

   std::unique_ptr<TaskQueueFactory> CreateDefaultTaskQueueFactory() {
       return CreateTaskQueueStdlibFactory();
   }

WebRTC 内部很多模块使用 TaskQueue 而非直接使用 Thread，
以便在不同平台选择最优的实现（POSIX、Win32、stdlib）。


Dispatcher (事件分派)
----------------------

Network Thread 内部使用事件驱动模型处理 Socket I/O：

.. code-block:: c++

   class Dispatcher {
   public:
       virtual uint32_t GetRequestedEvents() = 0;
       virtual void OnEvent(uint32_t ff, int err) = 0;
   #if defined(WEBRTC_WIN)
       virtual WSAEVENT GetWSAEvent() = 0;
       virtual SOCKET GetSocket() = 0;
   #elif defined(WEBRTC_POSIX)
       virtual int GetDescriptor() = 0;
       virtual bool IsDescriptorClosed() = 0;
   #endif
   };

- Windows：使用 ``WSAEventSelect`` + ``WSAWaitForMultipleEvents``
- POSIX：使用 ``poll()`` 或 ``epoll()``


线程安全注解
======================

WebRTC 大量使用 Clang 线程安全注解来在编译期检测错误：

.. code-block:: c++

   class VideoSendStream {
       Mutex mutex_;
       // 编译器检查：访问 config_ 前必须持有 mutex_
       Config config_ RTC_GUARDED_BY(mutex_);

       // 编译器检查：此方法只能在 worker_thread_ 上调用
       void SetSource(...) RTC_RUN_ON(worker_thread_);
   };

常用注解：

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - 注解
     - 含义
   * - ``RTC_GUARDED_BY(mu)``
     - 访问此变量前必须持有锁 ``mu``
   * - ``RTC_RUN_ON(thread)``
     - 此方法只能在指定线程上调用
   * - ``RTC_DCHECK_RUN_ON(thread)``
     - 运行时断言当前在指定线程上
   * - ``RTC_EXCLUSIVE_LOCKS_REQUIRED(mu)``
     - 调用此方法前必须持有锁


实际场景中的线程交互
=========================

以发送视频为例：

.. code-block:: text

   摄像头采集 (Capture Thread)
       │
       │ OnFrame() 回调
       ▼
   Signaling Thread
       │ 通过 VideoTrackSource 分发
       ▼
   Worker Thread
       │ VideoStreamEncoder::OnFrame()
       │ → 编码 (可能在编码器自己的线程)
       │ → PacedSender::EnqueuePackets()
       ▼
   Network Thread (Pacer 线程)
       │ → RTP 打包
       │ → SRTP 加密
       │ → Socket 发送
       ▼
   网络


FAQ
==============

如何创建 PeerConnectionFactory 并指定线程？
-----------------------------------------------------

.. code-block:: c++

   auto network_thread = rtc::Thread::CreateWithSocketServer();
   network_thread->Start();

   auto worker_thread = rtc::Thread::Create();
   worker_thread->Start();

   auto signaling_thread = rtc::Thread::Create();
   signaling_thread->Start();

   auto factory = webrtc::CreatePeerConnectionFactory(
       network_thread.get(),
       worker_thread.get(),
       signaling_thread.get(),
       /*default_adm=*/nullptr,
       webrtc::CreateBuiltinAudioEncoderFactory(),
       webrtc::CreateBuiltinAudioDecoderFactory(),
       std::make_unique<webrtc::VideoEncoderFactoryTemplate<
           webrtc::LibvpxVp8EncoderTemplateAdapter>>(),
       std::make_unique<webrtc::VideoDecoderFactoryTemplate<
           webrtc::LibvpxVp8DecoderTemplateAdapter>>(),
       /*audio_mixer=*/nullptr,
       /*audio_processing=*/nullptr);


参考资料
==============

- `rtc::Thread 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/rtc_base/thread.h>`_
- `TaskQueueBase 源码 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/api/task_queue/task_queue_base.h>`_
- `线程安全注解 <https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/rtc_base/thread_annotations.h>`_
