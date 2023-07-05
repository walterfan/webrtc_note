########################
TLS 协议
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** TLS protocol
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=======================

协议细节参见

* TLS v1.2 https://datatracker.ietf.org/doc/html/rfc5246
* TLS v1.3 https://datatracker.ietf.org/doc/html/rfc8446


Protocol
=======================

handshake protocol
----------------------------

SSL Handshake Steps

1. The client says hello. This “client hello” message lists cryptographic information, including the SSL version to use to communicate with each other. It also lists which encryption algorithms it supports, which are known as Cipher Suites.
2. The server responds hello. This “server hello” message contains important information, like which CipherSuite it chose, and its digital certificate. It might also request the client’s certificate.
3. The client verifies the server’s certificate. It also sends several byte strings, including one for allowing both the client and the server to compute a secret key for encrypting subsequent messages, including the “finished” messages. If the server sends a client certificate request, it will also send a byte string encrypted with its own private key and digital certificate.
4. The server verifies the client's certificate. This step only takes place if client authentication is required.
5. The client says “I’m finished.” This “finished” message indicates that the client has completed its part of the handshake.
6. The server says “I’m finished, too.” This “finished” message indicates that the sever has completed its part of the handshake.




TLS Session Resumption without Server-Side State
---------------------------------------------------------
refer to https://datatracker.ietf.org/doc/html/rfc5077

* Figure 1: Message Flow for Full Handshake Issuing New Session Ticket

.. code-block::

             Client                                               Server

         ClientHello
        (empty SessionTicket extension)-------->
                                                         ServerHello
                                     (empty SessionTicket extension)
                                                        Certificate*
                                                  ServerKeyExchange*
                                                 CertificateRequest*
                                      <--------      ServerHelloDone
         Certificate*
         ClientKeyExchange
         CertificateVerify*
         [ChangeCipherSpec]
         Finished                     -------->
                                                    NewSessionTicket
                                                  [ChangeCipherSpec]
                                      <--------             Finished
         Application Data             <------->     Application Data





What is SSL Handshake Failed?
---------------------------------
possible reason:

* The client is using the wrong date or time.
* The client is a browser and its specific configuration is causing the error.
* The connection is being intercepted by a third party on the client-side.
* The client and server do not support the same SSL version.
* The client and server are using different Cipher Suites.
* The client or server's certificate is invalid.


Alert Protocol
----------------------------

.. code-block::

    enum { warning(1), fatal(2), (255) } AlertLevel;

      enum {
          close_notify(0),
          unexpected_message(10),
          bad_record_mac(20),
          decryption_failed_RESERVED(21),
          record_overflow(22),
          decompression_failure(30),
          handshake_failure(40),
          no_certificate_RESERVED(41),
          bad_certificate(42),
          unsupported_certificate(43),
          certificate_revoked(44),
          certificate_expired(45),
          certificate_unknown(46),
          illegal_parameter(47),
          unknown_ca(48),
          access_denied(49),
          decode_error(50),
          decrypt_error(51),
          export_restriction_RESERVED(60),
          protocol_version(70),
          insufficient_security(71),
          internal_error(80),
          user_canceled(90),
          no_renegotiation(100),
          unsupported_extension(110),
          (255)
      } AlertDescription;

      struct {
          AlertLevel level;
          AlertDescription description;
      } Alert;


Reference
=========================
* High Performance Browser Networking

  https://www.oreilly.com/library/view/high-performance-browser/9781449344757/ch04.html