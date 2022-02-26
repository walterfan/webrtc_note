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

.. |date| date::

.. contents::
   :local:

Overview
=============

demo steps:

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


main class
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


main flow
-------------------------

1. conect the signal server - peerconnection server
2. start to login into the signal server
3. get the peer list and connect to a peer
4. capture media stream track from local camera
5. create offer and do SDP negotiation
6. collect ICE candidate and do connection checking
7. send local media stream via the peer connection
8. got remote media stream and render 

