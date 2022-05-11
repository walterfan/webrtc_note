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

公钥从哪里来？
--------------------------------------
一般是通过服务器上下载下来的证书中获取的



在 WebRTC 中，DTLS 主要用来传输 SRTP 密钥， 以及传输用于 Datat Channel 的 SCTP 消息


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





Reference
========================
* `RFC6347`_: Datagram Transport Layer Security Version 1.2
* `RFC9147`_: The Datagram Transport Layer Security (DTLS) Protocol Version 1.3