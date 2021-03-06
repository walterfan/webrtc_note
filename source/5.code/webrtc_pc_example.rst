#################################
WebRTC PeerConnection Example
#################################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC PeerConnection Example
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============
在 windows 平台上编译 webrtc library 后会生成一些例子程序,其中的例子 peerconnection client and server 用来研究 WebRTC 源码, 是一份绝佳的餐前开味小菜

测试步骤:

1) start peer connection server
2) start peer connection client 1 - Alice
3) start peer connection client 2 - Bob
4) Alice click "connect" to localhost:8888
5) Bob click "connect" to localhost:8888
6) Alice select the peer of Bob, and connect


PeerConnection Server
===========================
It is a signal server that listen port 8888




main class
---------------------------
.. list-table:: CRCC Cards
  :widths: 25 25 25 25
  :header-rows: 1

  * - Class
    - Responsibility
    - Collaborators
    - Comments
  * - ListeningSocket
    - The server socket.  Accepts connections and generates DataSocket instances 
      for each new connection
    - parent: SocketBase - methods: Create(), Close()
    - methods: Listen(port), Accept()
  * - DataSocket
    - Represents an HTTP server socket what can read/send data
    - parent: SocketBase
    - methods: OnDataAvailable(socket), send(string)
  * - ChannelMember
    - Represents a single peer connected to the server
    - DataSocket
    - methods: NotifyOfOtherMember(other), ForwardRequestTopPeer(), QueryResponse
  * - PeerChannel
    - Manages all currently connected peers
    - property: vector<ChannelMember*> Members
    - methods: Lookup(ds), AddMember(ds), isTargetRequest

main flow
-----------------

1. listen port 8888
2. Accept new connection as a DataSocket
3. add the DataSocket's socket handle into a select array
4. select for interesting events: read event to callback DataSocket.OnDataAvailable
5. if it is a new peer, call AddMember
6. if it is a existed peer, lookup and forward message to that peer

PeerConnection Client
===========================


main class of pc client
---------------------------

.. list-table:: CRCC Cards
  :widths: 25 25 25 25
  :header-rows: 1

  * - Class
    - Responsibility
    - Collaborators
    - Comments
  * - MainWnd
    - the main window class of pc Client for UI render and event handler
    - parent: MainWindow, collaborators: VideoRenderer for local/remote stream
    - the Observer is  Conductor
  * - PeerConnectionClient
    - Message handler for signin, signout, hangup and message send/read
    - PeerConnectionClientObserver(OnSignedIn, OnDisconnected)
    - the Observer is  Conductor
  * - Conductor
    - create/delete PC, add/remove MediaStreamTracks, SDP negotiation, ICE candidate handle
    - parent:PeerConnectionObserver,webrtc::CreateSessionDescriptionObserver,PeerConnectionClientObserver,MainWndCallback
    - handle message from MainWnd and PeerConnectionClient, and operate the two objects

* UI

.. code-block::

   enum UI {
      CONNECT_TO_SERVER,
      LIST_PEERS,
      STREAMING,
   };

* PeerConnection Client State

.. code-block::

   enum State {
      NOT_CONNECTED,
      RESOLVING,
      SIGNING_IN,
      CONNECTED,
      SIGNING_OUT_WAITING,
      SIGNING_OUT,
  };

* Conductor callbacks


 .. code-block::

   enum CallbackID {
      MEDIA_CHANNELS_INITIALIZED = 1,
      PEER_CONNECTION_CLOSED,
      SEND_MESSAGE_TO_PEER,
      NEW_TRACK_ADDED,
      TRACK_REMOVED,
  }; 


main flow of pc client
-------------------------

1. conect the signal server - peerconnection server
2. start to login into the signal server
3. get the peer list and connect to a peer
4. capture media stream track from local camera
5. create offer and do SDP negotiation
6. collect ICE candidate and do connection checking
7. send local media stream via the peer connection
8. got remote media stream and render 

FAQ
=========================


What's PhysicalSocketServer
-------------------------------------------

PhysicalSocketServer is A socket server that provides the real sockets of the underlying OS.

It may contains  select(), epoll() or WSAWaitForMultipleEvents loop

And the SocketServer Provides the ability to wait for activity on a set of sockets.  

The Thread class provides a nice wrapper on a socket server.

The server is also a socket factory.  

The sockets it creates will be notified of asynchronous I/O from this server's Wait method.


What's AutoSocketServerThread
-------------------------------------------

AutoSocketServerThread automatically installs itself at construction and uninstalls at destruction. If a Thread object is already associated with the current OS thread, 
it is temporarily disassociated and restored by the destructor.


The rtc::Thread is extended from webrtc::TaskQueueBase

TaskQueueBase means Asynchronously executes tasks in a way that guarantees 
that they're executedin FIFO order and that tasks never overlap. 

Tasks may always execute on the same worker thread and they may not. 

To DCHECK that tasks are executing on a known task queue, use IsCurrent().

What is the difference between wWinMain and WinMain?
---------------------------------------------------------------
The only difference between WinMain and wWinMain is the command line string and you should use wWinMain in Unicode applications (and all applications created these days should use Unicode). You can of course manually call GetCommandLineW() in WinMain and parse it yourself if you really want to.