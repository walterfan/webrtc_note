##############################
WebRTC Thread Model
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Thread Model
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

Overview
=============

一个线程通常会有一个对应的任务队列，在线程的运行方法中会执行一个循环，不断地检查这个任务队列中是否有任务

如果有任务的话，从队头取出任务执行，如果没有的话，阻塞等待有新的任务追加到这个任务队列尾部。

在 WebRTC library 中一般分为

1. 网络线程：在这个线程中处理连接和收发数据的事件，通常会使用 reactor 或 proactor 模式
2. 工作线程：在这个线程中通常会处理业务网络


main classes
======================
Thread
----------------------

* Get() will process I/O until:
  1) A message is available (returns true)
  2) cmsWait seconds have elapsed (returns false)
  3) Stop() is called (returns false)

* Stop():
  Tells the thread to stop and waits until it is joined.
  Never call Stop on the current thread.  Instead use the inherited Quit function which will exit the base Thread without terminating the underlying OS thread.

* Run():
  By default, Thread::Run() calls ProcessMessages(kForever).  To do other work, override Run().  
  To receive and dispatch messages, call rocessMessages occasionally.
  

事件分派
-----------------------------------

.. code-block:: cpp

    class Dispatcher {
    public:
        virtual ~Dispatcher() {}
        virtual uint32_t GetRequestedEvents() = 0;
        virtual void OnEvent(uint32_t ff, int err) = 0;
        #if defined(WEBRTC_WIN)
        virtual WSAEVENT GetWSAEvent() = 0;
        virtual SOCKET GetSocket() = 0;
        virtual bool CheckSignalClose() = 0;
        #elif defined(WEBRTC_POSIX)
        virtual int GetDescriptor() = 0;
        virtual bool IsDescriptorClosed() = 0;
        #endif
    };


FAQ
==============

How to wait an event and wakeup by an event?
-------------------------------------------------

windows platform
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* main classes
  - WSAEVENT
  - WSAEventSelect
  - WSAWaitForMultipleEvents
  - WSAEnumNetworkEvents
  - WSANETWORKEVENTS

* Event type: FD_READ、FD_WRITE、FD_ACCEPT、FD_CONNECT、FD_CLOSE