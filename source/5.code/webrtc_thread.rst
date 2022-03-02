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
线程模型
----------------------------------



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