########################
DTLS 协议
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** DTLS protocol
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=======================

DTLS 和 TLS 的理念几乎一样，通过不对称加密算法来交换密钥，再通过对称加密算法来加密数据

不对称加密的原理就是通过张三的公钥加密的数据，只能通过张三自己的私钥来解密

相比于 TLS , DTLS 复用了所有的 handshake 消息和流程, 不同的是有如下三个主要的改动:

1. A stateless cookie exchange has been added to prevent denial-of-service attacks.

2. Modifications to the handshake header to handle message loss, reordering, and DTLS message fragmentation
   (in order to avoid IP fragmentation).

3. Retransmission timers to handle message loss 重传计时器以处理消息丢失


具体的定义参见

* `RFC6347`_: The Datagram Transport Layer Security (DTLS) Version 1.2
* `RFC9147`_: The Datagram Transport Layer Security (DTLS) Version 1.3
* `RFC5246`_: The Transport Layer Security (TLS) Protocol Version 1.2
* `RFC5077`_: TLS Session Resumption without Server-Side State

术语
==========================



Packet structure 包结构
===========================

* UDP packet

.. code-block::

      0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |           Source Port          |        Destination port      |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |               Length           |        Checksum              |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |                                                               |
     |                        data octets ...                        |
     |                                                               |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


* TLS Record

.. code-block::


      struct {
          uint8 major;
          uint8 minor;
      } ProtocolVersion;

      enum {
          change_cipher_spec(20),
          alert(21),
          handshake(22),
          application_data(23), 
          (255)
      } ContentType;

      struct {
          ContentType type;
          ProtocolVersion version;
          uint16 length;
          opaque fragment[TLSPlaintext.length];
      } TLSPlaintext;

* DTLS Record

.. code-block::

   struct {
         ContentType type;
         ProtocolVersion version;
         uint16 epoch;                                     // New field
         uint48 sequence_number;                           // New field
         uint16 length;
         opaque fragment[DTLSPlaintext.length];
   } DTLSPlaintext;


* DTLS Packet

.. code-block::

      0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     | ContentType |        Version     |        epoch               |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |                         sequence_number                       |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |    sequence_number              |         length              |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |                                                               |
     |                     opaque fragment                           |
     |                                                               |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+




基本流程
=======================

握手
-----------------------

* Message Flights for Full Handshake

.. code-block::


      Client                                          Server
      ------                                          ------

      ClientHello             -------->                           Flight 1

                              <-------    HelloVerifyRequest      Flight 2

      ClientHello             -------->                           Flight 3

                                                ServerHello    \
                                                Certificate*     \
                                          ServerKeyExchange*      Flight 4
                                          CertificateRequest*     /
                              <--------      ServerHelloDone    /

      Certificate*                                              \
      ClientKeyExchange                                          \
      CertificateVerify*                                          Flight 5
      [ChangeCipherSpec]                                         /
      Finished                -------->                         /

                                          [ChangeCipherSpec]    \ Flight 6
                              <--------             Finished    /



* Message Flights for Session-Resuming Handshake (No Cookie Exchange)

.. code-block::

      Client                                           Server
      ------                                           ------

      ClientHello             -------->                          Flight 1

                                                ServerHello    \
                                          [ChangeCipherSpec]     Flight 2
                              <--------             Finished    /

      [ChangeCipherSpec]                                         \Flight 3
      Finished                 -------->                         /



DTLS handshake messages are grouped into a series of message flights.

A flight starts with the handshake message transmission of one peer and ends with the expected response from the other peer.

* Table 1 contains a complete list of message combinations that constitute flights.

.. code-block::

      +======+========+========+===================================+
      | Note | Client | Server | Handshake Messages                |
      +======+========+========+===================================+
      |      | x      |        | ClientHello                       |
      +------+--------+--------+-----------------------------------+
      |      |        | x      | HelloRetryRequest                 |
      +------+--------+--------+-----------------------------------+
      |      |        | x      | ServerHello, EncryptedExtensions, |
      |      |        |        | CertificateRequest, Certificate,  |
      |      |        |        | CertificateVerify, Finished       |
      +------+--------+--------+-----------------------------------+
      | 1    | x      |        | Certificate, CertificateVerify,   |
      |      |        |        | Finished                          |
      +------+--------+--------+-----------------------------------+
      | 1    |        | x      | NewSessionTicket                  |
      +------+--------+--------+-----------------------------------+


丢包的处理
-----------------------

DTLS uses a simple retransmission timer to handle packet loss.

The following figure demonstrates the basic concept, using the first phase of the DTLS handshake:


.. code-block::

         Client                                   Server
         ------                                   ------
         ClientHello           ------>

                                 X<-- HelloVerifyRequest
                                                  (lost)

         [Timer Expires]

         ClientHello           ------>
         (retransmit)



DTLS Timeout and Retransmission State Machine
----------------------------------------------------------

.. code-block::

                      +-----------+
                      | PREPARING |
                +---> |           | <--------------------+
                |     |           |                      |
                |     +-----------+                      |
                |           |                            |
                |           | Buffer next flight         |
                |           |                            |
                |          \|/                           |
                |     +-----------+                      |
                |     |           |                      |
                |     |  SENDING  |<------------------+  |
                |     |           |                   |  | Send
                |     +-----------+                   |  | HelloRequest
        Receive |           |                         |  |
           next |           | Send flight             |  | or
         flight |  +--------+                         |  |
                |  |        | Set retransmit timer    |  | Receive
                |  |       \|/                        |  | HelloRequest
                |  |  +-----------+                   |  | Send
                |  |  |           |                   |  | ClientHello
                +--)--|  WAITING  |-------------------+  |
                |  |  |           |   Timer expires   |  |
                |  |  +-----------+                   |  |
                |  |         |                        |  |
                |  |         |                        |  |
                |  |         +------------------------+  |
                |  |                Read retransmit      |
        Receive |  |                                     |
           last |  |                                     |
         flight |  |                                     |
                |  |                                     |
               \|/\|/                                    |
                                                         |
            +-----------+                                |
            |           |                                |
            | FINISHED  | -------------------------------+
            |           |
            +-----------+
                 |  /|\
                 |   |
                 |   |
                 +---+

              Read retransmit
           Retransmit last flight




Example
=======================

* openssl example

.. code-block:: bash

      // Generate a certificate
      openssl ecparam -out key.pem -name prime256v1 -genkey
      openssl req -new -sha256 -key key.pem -out server.csr
      openssl x509 -req -sha256 -days 365 -in server.csr -signkey key.pem -out cert.pem

      // Use with examples/dial/selfsign/main.go
      openssl s_server -dtls1_2 -cert cert.pem -key key.pem -accept 4444

      // Use with examples/listen/selfsign/main.go
      openssl s_client -dtls1_2 -connect 127.0.0.1:4444 -debug -cert cert.pem -key key.pem


* pion go example

.. code-block::

   git clone git@github.com:pion/dtls.git
   cd dtls

   tcpdump -n port 4444 -i lo0 -Xvnp -s0 -w /tmp/dtls_record.pcap

   # For a DTLS 1.2 Server that listens on 127.0.0.1:4444
   go run examples/listen/selfsign/main.go

   # For a DTLS 1.2 Client that connects to 127.0.0.1:4444
   go run examples/dial/selfsign/main.go


* another example

.. code-block::


      # setup a server key + certificate:
      openssl req -x509 -new -nodes -keyout key.pem -out server.pem.
      # start the server:
      openssl s_server -dtls1 -key key.pem -port 4433 -msg.
      # connect to it with a client:
      openssl s_client -dtls1 -connect localhost:4433 -msg

      sudo tcpdump udp -i lo0 -s 65535 -w handshake.pcap

* DTLS Record

.. code-block:: c++

      //DTLS record raw data structure
      typedef struct DtlsHandshakeRawData {
            u8  handshakeType; // ssl3_mt_*
            u24 len;
            u16 msgSeq;
            u24 fragOffset;
            u24 fragLen;
            u8  fragBuf[1];
      } stDtlsHandshakeRawData;

      typedef struct DtlsRecordLayerRawData {
            u8   contentType; // ssl3_rt_*
            u16  dtlsVer;
            u16  epoch;
            u16  seqNoH;
            u32  seqNoL;
            u16  len;
            stDtlsHandshakeRawData fragData;
      } stDtlsRecordLayerRawData;

Troubleshooting
========================

最后一组消息丢失问题
------------------------

DTLS messages are grouped into a series of message flights, according to the diagrams of handshake.

Although each flight of messages may consist of a number of messages, they should be viewed as monolithic for the
purpose of timeout and retransmission.

In addition, for at least twice the default MSL defined for [TCP],
when in the FINISHED state, the node that transmits the last flight
(the server in an ordinary handshake or the client in a resumed
handshake) MUST respond to a retransmit of the peer's last flight


with a retransmit of the last flight.  This avoids deadlock
conditions if the last flight gets lost.  This requirement applies to
DTLS 1.0 as well, and though not explicit in [DTLS1], it was always
required for the state machine to function correctly.  To see why
this is necessary, consider what happens in an ordinary handshake if
the server's Finished message is lost: the server believes the
handshake is complete but it actually is not.  As the client is
waiting for the Finished message, the client's retransmit timer will
fire and it will retransmit the client's Finished message.  This will
cause the server to respond with its own Finished message, completing
the handshake.  The same logic applies on the server side for the
resumed handshake.

Note that because of packet loss, it is possible for one side to be
sending application data even though the other side has not received
the first side's Finished message.  Implementations MUST either
discard or buffer all application data packets for the new epoch
until they have received the Finished message for that epoch.
Implementations MAY treat receipt of application data with a new
epoch prior to receipt of the corresponding Finished message as
evidence of reordering or packet loss and retransmit their final
flight immediately, shortcutting the retransmission timer.

.. code-block::

      title DTLS handshake failed with 20% packet loss on downlink

      participant Client as C
      participant Server as S

      #autonumber

      C -> S: ClientHello
      S -->C: Hello Verify Request
      C -> S: ClientHello with cookie
      S --> C: ServerHello, Certificate, Server Key Exchange, Certificate Request, ServerHelloDone
      C -> S: Certificate, Certificate Key Exchange, Certificate Verify, ChangeCipherSpec ...
      S --> C: NewSessionTicket, ChangeCipherSpec, ...
      note left of S: handshake is done in server side
      S -> S: cache the last flight
      note right of C: Client side found write_alert fatal unknown TLS client read_session_ticket
      C -> S: Certificate,  Certificate Key Exchange, Certificate Verify,ChangeCipherSpec ...
      #C -> S: Certificate,  Certificate Key Exchange, Certificate Verify,ChangeCipherSpec ...
      #note right of C: Client resent Certificates to Server ... more than 10 times ... 
      #C -> S: Certificate,  Certificate Key Exchange, Certificate Verify,ChangeCipherSpec ...
      #C -> S: Encrypted Alert
      #note right of C: client mark the transport's dtlsState as "Failed"
      S --> C: NewSessionTicket, ChangeCipherSpec, ...
      note right of C: handshake is done in client side
      C -> S: Application Data


Reference
========================
* `RFC6347`_: Datagram Transport Layer Security Version 1.2
* `RFC9147`_: The Datagram Transport Layer Security (DTLS) Protocol Version 1.3