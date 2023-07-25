##############################
WebRTC DTLS
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Pacer
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
===============


API of openssl/boringssl
===================================

* SSL_do_handshake
* DTLSv1_handle_timeout


refer to https://boringssl.googlesource.com/boringssl/+/master/include/openssl/ssl.h

.. code-block:: c++

  // SSL contexts.
  //
  // |SSL_CTX| objects manage shared state and configuration between multiple TLS
  // or DTLS connections. Whether the connections are TLS or DTLS is selected by
  // an |SSL_METHOD| on creation.
  //
  // |SSL_CTX| are reference-counted and may be shared by connections across
  // multiple threads. Once shared, functions which change the |SSL_CTX|'s
  // configuration may not be used.

  // TLS_method is the |SSL_METHOD| used for TLS connections.
  OPENSSL_EXPORT const SSL_METHOD *TLS_method(void);

  // DTLS_method is the |SSL_METHOD| used for DTLS connections.
  OPENSSL_EXPORT const SSL_METHOD *DTLS_method(void);



* SSL_do_handshake

.. code-block:: c++

  // SSL_do_handshake continues the current handshake. If there is none or the
  // handshake has completed or False Started, it returns one. Otherwise, it
  // returns <= 0. The caller should pass the value into |SSL_get_error| to
  // determine how to proceed.
  //
  // In DTLS, the caller must drive retransmissions. Whenever |SSL_get_error|
  // signals |SSL_ERROR_WANT_READ|, use |DTLSv1_get_timeout| to determine the
  // current timeout. If it expires before the next retry, call
  // |DTLSv1_handle_timeout|. Note that DTLS handshake retransmissions use fresh
  // sequence numbers, so it is not sufficient to replay packets at the transport.
  //
  // TODO(davidben): Ensure 0 is only returned on transport EOF.
  // https://crbug.com/466303.
  OPENSSL_EXPORT int SSL_do_handshake(SSL *ssl);


* SSL_shutdown

.. code-block:: c++

  // SSL_shutdown shuts down |ssl|. It runs in two stages. First, it sends
  // close_notify and returns zero or one on success or -1 on failure. Zero
  // indicates that close_notify was sent, but not received, and one additionally
  // indicates that the peer's close_notify had already been received.
  //
  // To then wait for the peer's close_notify, run |SSL_shutdown| to completion a
  // second time. This returns 1 on success and -1 on failure. Application data
  // is considered a fatal error at this point. To process or discard it, read
  // until close_notify with |SSL_read| instead.
  //
  // In both cases, on failure, pass the return value into |SSL_get_error| to
  // determine how to proceed.
  //
  // Most callers should stop at the first stage. Reading for close_notify is
  // primarily used for uncommon protocols where the underlying transport is
  // reused after TLS completes. Additionally, DTLS uses an unordered transport
  // and is unordered, so the second stage is a no-op in DTLS.
  OPENSSL_EXPORT int SSL_shutdown(SSL *ssl);

* SSL_set_bio

.. code-block:: C++

  // SSL_set_bio configures |ssl| to read from |rbio| and write to |wbio|. |ssl|
  // takes ownership of the two |BIO|s. If |rbio| and |wbio| are the same, |ssl|
  // only takes ownership of one reference.
  //
  // In DTLS, |rbio| must be non-blocking to properly handle timeouts and
  // retransmits.
  //
  // If |rbio| is the same as the currently configured |BIO| for reading, that
  // side is left untouched and is not freed.
  //
  // If |wbio| is the same as the currently configured |BIO| for writing AND |ssl|
  // is not currently configured to read from and write to the same |BIO|, that
  // side is left untouched and is not freed. This asymmetry is present for
  // historical reasons.
  //
  // Due to the very complex historical behavior of this function, calling this
  // function if |ssl| already has |BIO|s configured is deprecated. Prefer
  // |SSL_set0_rbio| and |SSL_set0_wbio| instead.
  OPENSSL_EXPORT void SSL_set_bio(SSL *ssl, BIO *rbio, BIO *wbio);


classes
===============
* OpenSSLAdapter

  rtc_base/openssl_adapter.cc

* OpenSSLStreamAdapter

  openssl_stream_adapter.cc

* DtlsTransport

  dtls_transport.cc

SSLStreamAdapter
-------------------------
SSLStreamAdapter : A StreamInterfaceAdapter that does SSL/TLS.

After SSL has been started, the stream will only open on successful SSL verification of certificates,
and the communication is encrypted of course.

This class was written with SSLAdapter as a starting point.
It offers a similar interface, with two differences: there is no support for a restartable SSL connection,
and this class has a peer-to-peer mode.

The SSL library requires initialization and cleanup. Static method for doing this are in SSLAdapter.
They should possibly be moved out to a neutral class.

Snippets
================

.. code-block:: c++


    enum SSLRole { SSL_CLIENT, SSL_SERVER };
    enum SSLMode { SSL_MODE_TLS, SSL_MODE_DTLS };


    enum SSLProtocolVersion {
        SSL_PROTOCOL_NOT_GIVEN = -1,
        SSL_PROTOCOL_TLS_10 = 0,
        SSL_PROTOCOL_TLS_11,
        SSL_PROTOCOL_TLS_12,
        SSL_PROTOCOL_DTLS_10 = SSL_PROTOCOL_TLS_11,
        SSL_PROTOCOL_DTLS_12 = SSL_PROTOCOL_TLS_12,
    };

    enum class SSLPeerCertificateDigestError {
        NONE,
        UNKNOWN_ALGORITHM,
        INVALID_LENGTH,
        VERIFICATION_FAILED,
    };

    enum SSLState {
        SSL_NONE,
        SSL_WAIT,
        SSL_CONNECTING,
        SSL_CONNECTED,
        SSL_ERROR
    };

    // client handshake state
    enum ssl_client_hs_state_t {
        state_start_connect = 0,
        state_enter_early_data,
        state_early_reverify_server_certificate,
        state_read_hello_verify_request,
        state_read_server_hello,
        state_tls13,
        state_read_server_certificate,
        state_read_certificate_status,
        state_verify_server_certificate,
        state_reverify_server_certificate,
        state_read_server_key_exchange,
        state_read_certificate_request,
        state_read_server_hello_done,
        state_send_client_certificate,
        state_send_client_key_exchange,
        state_send_client_certificate_verify,
        state_send_client_finished,
        state_finish_flight,
        state_read_session_ticket, // read session ticket
        state_process_change_cipher_spec,
        state_read_server_finished,
        state_finish_client_handshake,
        state_done,
    };

    // server handshake state
    //refer to https://source.chromium.org/chromium/chromium/src/+/main:third_party/boringssl/src/ssl/handshake_client.cc;l=1720?q=handshake_client.cc
    enum tls12_server_hs_state_t {
      state12_start_accept = 0,
      state12_read_client_hello,
      state12_read_client_hello_after_ech,
      state12_select_certificate,
      state12_tls13,
      state12_select_parameters,
      state12_send_server_hello,
      state12_send_server_certificate,
      state12_send_server_key_exchange,
      state12_send_server_hello_done,
      state12_read_client_certificate,
      state12_verify_client_certificate,
      state12_read_client_key_exchange,
      state12_read_client_certificate_verify,
      state12_read_change_cipher_spec,
      state12_process_change_cipher_spec,
      state12_read_next_proto,
      state12_read_channel_id,
      state12_read_client_finished,
      state12_send_server_finished,
      state12_finish_server_handshake,
      state12_done,
    };


* ssl_client_handshake 方法负责进行客户端的 SSL 握手

  webrtc-checkout/src/third_party/boringssl/src/ssl/handshake_client.cc

  https://source.chromium.org/chromium/chromium/src/+/main:third_party/boringssl/src/ssl/handshake_client.cc;l=1720?q=do_read_session_ticket&sq=&ss=chromium

.. code-block:: c++

    enum ssl_hs_wait_t ssl_client_handshake(SSL_HANDSHAKE *hs) {
      while (hs->state != state_done) {
        enum ssl_hs_wait_t ret = ssl_hs_error;
        enum ssl_client_hs_state_t state =
            static_cast<enum ssl_client_hs_state_t>(hs->state);
        switch (state) {
          case state_start_connect:
            ret = do_start_connect(hs);
            break;
          case state_enter_early_data:
            ret = do_enter_early_data(hs);
            break;
          case state_early_reverify_server_certificate:
            ret = do_early_reverify_server_certificate(hs);
            break;
          case state_read_hello_verify_request:
            ret = do_read_hello_verify_request(hs);
            break;
          case state_read_server_hello:
            ret = do_read_server_hello(hs);
            break;
          case state_tls13:
            ret = do_tls13(hs);
            break;
          case state_read_server_certificate:
            ret = do_read_server_certificate(hs);
            break;
          case state_read_certificate_status:
            ret = do_read_certificate_status(hs);
            break;
          case state_verify_server_certificate:
            ret = do_verify_server_certificate(hs);
            break;
          case state_reverify_server_certificate:
            ret = do_reverify_server_certificate(hs);
            break;
          case state_read_server_key_exchange:
            ret = do_read_server_key_exchange(hs);
            break;
          case state_read_certificate_request:
            ret = do_read_certificate_request(hs);
            break;
          case state_read_server_hello_done:
            ret = do_read_server_hello_done(hs);
            break;
          case state_send_client_certificate:
            ret = do_send_client_certificate(hs);
            break;
          case state_send_client_key_exchange:
            ret = do_send_client_key_exchange(hs);
            break;
          case state_send_client_certificate_verify:
            ret = do_send_client_certificate_verify(hs);
            break;
          case state_send_client_finished:
            ret = do_send_client_finished(hs);
            break;
          case state_finish_flight:
            ret = do_finish_flight(hs);
            break;
          case state_read_session_ticket:
            ret = do_read_session_ticket(hs);
            break;
          case state_process_change_cipher_spec:
            ret = do_process_change_cipher_spec(hs);
            break;
          case state_read_server_finished:
            ret = do_read_server_finished(hs);
            break;
          case state_finish_client_handshake:
            ret = do_finish_client_handshake(hs);
            break;
          case state_done:
            ret = ssl_hs_ok;
            break;
        }

        if (hs->state != state) {
          ssl_do_info_callback(hs->ssl, SSL_CB_CONNECT_LOOP, 1);
        }

        if (ret != ssl_hs_ok) {
          return ret;
        }
      }

      ssl_do_info_callback(hs->ssl, SSL_CB_HANDSHAKE_DONE, 1);
      return ssl_hs_ok;
    }

logs
---------------------

.. code-block::

    [38367:49923:0619/142328.887408:INFO:openssl_stream_adapter.cc(828)] DTLS retransmission
    [38367:49923:0619/142328.887456:INFO:openssl_adapter.cc(833)] connect_exit TLS client read_session_ticket

    [38367:49923:0619/142917.365608:INFO:openssl_stream_adapter.cc(830)] DTLSv1_handle_timeout() return -1
    [38367:49923:0619/142917.365738:WARNING:openssl_stream_adapter.cc(952)] OpenSSLStreamAdapter::Error(DTLSv1_handle_timeout, -1, 255)
    [38367:49923:0619/142917.365838:WARNING:openssl_adapter.cc(836)] write_alert fatal unknown TLS client read_session_ticket
    [38367:49923:0619/142917.365904:INFO:dtls_transport.cc(733)] DtlsTransport[1|1|__]: DTLS transport error, code=-1
    [38367:49923:0619/142917.365939:VERBOSE1:dtls_transport.cc(840)] DtlsTransport[1|1|__]: set_dtls_state from:1 to 4