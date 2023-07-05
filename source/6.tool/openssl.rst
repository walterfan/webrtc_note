##########
OpenSSL
##########


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** OpenSSL
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
==============


Snippets
===============

* ssl3.h

.. code-block:: c++


    # define SSL3_RT_CHANGE_CIPHER_SPEC      20
    # define SSL3_RT_ALERT                   21
    # define SSL3_RT_HANDSHAKE               22
    # define SSL3_RT_APPLICATION_DATA        23

    # define SSL3_MT_HELLO_REQUEST                   0
    # define SSL3_MT_CLIENT_HELLO                    1
    # define SSL3_MT_SERVER_HELLO                    2
    # define SSL3_MT_NEWSESSION_TICKET               4
    # define SSL3_MT_END_OF_EARLY_DATA               5
    # define SSL3_MT_ENCRYPTED_EXTENSIONS            8
    # define SSL3_MT_CERTIFICATE                     11
    # define SSL3_MT_SERVER_KEY_EXCHANGE             12
    # define SSL3_MT_CERTIFICATE_REQUEST             13
    # define SSL3_MT_SERVER_DONE                     14
    # define SSL3_MT_CERTIFICATE_VERIFY              15
    # define SSL3_MT_CLIENT_KEY_EXCHANGE             16
    # define SSL3_MT_FINISHED                        20
    # define SSL3_MT_CERTIFICATE_URL                 21
    # define SSL3_MT_CERTIFICATE_STATUS              22
    # define SSL3_MT_SUPPLEMENTAL_DATA               23
    # define SSL3_MT_KEY_UPDATE                      24
    # ifndef OPENSSL_NO_NEXTPROTONEG
    #  define SSL3_MT_NEXT_PROTO                     67
    # endif
    # define SSL3_MT_MESSAGE_HASH                    254
    # define DTLS1_MT_HELLO_VERIFY_REQUEST           3


* set SSLInfoCallback to dump the internal state

.. code-block:: c++


    SSL_CTX_set_info_callback(mCTX, SSLInfoCallback);


    void SSLInfoCallback(const SSL* s, int where, int value) {
        std::string type;
        bool info_log = false;
        bool alert_log = false;
        switch (where) {
            case SSL_CB_EXIT:
                info_log = true;
                type = "exit";
                break;
            case SSL_CB_ALERT:
                alert_log = true;
                type = "alert";
                break;
            case SSL_CB_READ_ALERT:
                alert_log = true;
                type = "read_alert";
                break;
            case SSL_CB_WRITE_ALERT:
                alert_log = true;
                type = "write_alert";
                break;
            case SSL_CB_ACCEPT_LOOP:
                info_log = true;
                type = "accept_loop";
                break;
            case SSL_CB_ACCEPT_EXIT:
                info_log = true;
                type = "accept_exit";
                break;
            case SSL_CB_CONNECT_LOOP:
                info_log = true;
                type = "connect_loop";
                break;
            case SSL_CB_CONNECT_EXIT:
                info_log = true;
                type = "connect_exit";
                break;
            case SSL_CB_HANDSHAKE_START:
                info_log = true;
                type = "handshake_start";
                break;
            case SSL_CB_HANDSHAKE_DONE:
                info_log = true;
                type = "handshake_done";
                break;
            case SSL_CB_LOOP:
            case SSL_CB_READ:
            case SSL_CB_WRITE:
            default:
                break;
        }

        if (info_log) {
            RTC_LOG(LS_INFO) << type << " " << SSL_state_string_long(s);

        }

        if (alert_log) {
            RTC_LOG(LS_INFO) << "type: " << type << " " << SSL_alert_type_string_long(value)
                                << " " << SSL_alert_desc_string_long(value) << " "
                                << SSL_state_string_long(s);
        }
    }



BIO
==============


What is OpenSSL BIO?
-------------------------
BIO 也就是  Basic Input Output 的缩写, 是 openssl 所封装的 API, 提供基本的输入输出功能.


A BIO is an I/O abstraction, it hides many of the underlying I/O details from an application.
If an application uses a BIO for its I/O it can transparently handle SSL connections, unencrypted network connections and file I/O.

There are two type of BIO, a source/sink BIO and a filter BIO.


* SSL_read() read unencrypted data which is stored in the input BIO.
* SSL_write() write unencrypted data into the output BIO.
* BIO_write() write encrypted data into the input BIO.
* BIO_read() read encrypted data from the output BIO.



Use BIO_write() to store encrypted data you receive from e.g. a tcp/udp socket.
Once you've written to an input BIO, you use SSL_read() to get the unencrypted data, but only after the handshake is ready.

Use BIO_read() to check if there is any data in the output BIO.
The output BIO will be filled by openSSL when it's handling the handshake or when you call SSL_write().
When there is data in your output BIO, use BIO_read to get the data and send it to

e.g. a client. Use BIO_ctrl_pending() to check how many bytes there are stored in the output bio.


The BIO_METHOD type is a structure used for the implementation of new BIO types.
It provides a set of functions used by OpenSSL for the implementation of the various BIO capabilities.


BIO_meth_new() creates a new BIO_METHOD structure.
It should be given a unique integer type and a string that represents its name.
Use BIO_get_new_index() to get the value for type.



What is a filter BIO, source BIO and sink BIO?
---------------------------------------------------------------
An OpenSSL filter BIO is a BIO that takes data, processes it and passes it to another BIO.

An OpenSSL source BIO is a BIO that doesn't take data from another BIO but takes it from somewhere else
(from a file, network, etc.).

An OpenSSL sink BIO is a BIO that doesn't pass data to another BIO but transfers it to somewhere else
(to a file, network, etc.).


If you put data to a filter using the BIO_write function, you can't get processed data by simply calling the BIO_read function on the BIO. Filter BIOs work in a different way.

A filter BIO may avoid storing processed data in a buffer. It may just take the input data, process it and immediately pass it to the next BIO in the chain using the same BIO_write function you used to put your data to the BIO.

The next BIO, in turn, may, after processing, write the data to the next BIO in the chain. The process stops if either some BIO stores the data in its internal buffer (if it doesn't have enough data to generate output for the next BIO) or if the data reaches the sink.

If you need just run data through a filter BIO without sending it over network or without writing it to a file, you can attach the filter BIO to an OpenSSL memory BIO (i.e. make the following chain: filter bio <-> memory bio).

A memory BIO is a source-sink BIO, but it doesn't send data to anywhere, it just stores the data in a memory buffer.

After writing the data to the filter BIO, the data will be written to the memory BIO which will store it in the memory buffer.

A memory BIO has special interface to get the data directly from the buffer (though you can use BIO_read to get the data that was written to a memory BIO, see below).

Reading from a filter BIO works in an opposite way. If you request to read data from a filter BIO, the filter BIO may, in turn, request to read data from the next BIO in the chain.
The process stops if either some BIO has enough buffered data to return or if the process reaches the source BIO.
A single call to the BIO_read function on a filter BIO may result in multiple calls to the BIO_read function inside the filter BIO to get data from the next BIO.
A filter BIO will continue to call BIO_read until it gets enough data to generate processed result.


The situation is more complicated if the source-sink BIO of a chain works in non-blocking mode.

For example, non-blocking sockets are used or memory BIO is used (memory BIOs are non-blocking by nature).

Also note that reading from a filter BIO does reversed data processing as compared to processing done when writing to that BIO.

For example, if you use a cipher BIO, then writing to the BIO will encipher the written data, but reading from that BIO will decipher the input data.
This allows to make a such chain: your code <-> cipher BIO <-> socket BIO.

You write unencrypted data to the cipher BIO which encrypts it and sends it to the socket.

When you read from the cipher BIO it, at first, gets encrypted data from the socket, then decrypts it and return unencrypted data to you.

This allows you to set up encrypted channel through network. You just use BIO_write and BIO_read and all encryption/decryption is done automatically by the BIO chain.

In general a BIO chain looks like on the following diagram:

.. code-block::

    /------\                 /--------\                 /---------\                 /-------------\
    | your | -- BIO_write -> | filter | -- BIO_write -> | another | -- BIO_write -> | source/sink |
    |      |                 |        |                 |  filter |                 |             |
    | code | <- BIO_read  -- |  BIO   | <- BIO_read  -- |   BIO   | <- BIO_read  -- |     BIO     |
    \------/                 \--------/                 \---------/                 \-------------/

BIO usage in openssl
------------------------------------

OpenSSL uses BIOs for communicating with the remote side when operating SSL/TLS protocol.

The SSL_set_bio function is used to set up BIOs for communicating in a concrete instance of an SSL/TLS link. You can use socket BIO, for example, to run SSL/TLS protocol via network connection.

But you may also develop your own BIO (yes, it is possible) or use memory BIO to run SSL/TLS protocol via your own type of link.

You can also wrap an instance of an SSL/TLS link as a BIO itself (BIO_f_ssl). Calling BIO_write on an SSL BIO will result in calling SSL_write. Calling BIO_read will result in calling SSL_read.

Although SSL BIO is a filter BIO, it is a little different from other filter BIOs. Calling BIO_write on SSL BIO may result in series of both BIO_read and BIO_write calls on the next BIO in the chain. Because SSL_write (that is used inside of BIO_write of SSL BIO) not only sends data, but also provides operating SSL/TLS protocol which may require multiple data exchanging steps between sides to perform some negotiation. The same is true for BIO_read of SSL BIO. That is how SSL BIOs are different from ordinary filter BIOs.

Also note, that you are not required to use SSL BIO. You can still use SSL_read and SSL_write directly.

Here is examples of source-sink BIOs that OpenSSL provides:

* A file BIO (BIO_s_file). It is a wrapper around stdio's FILE* object. It used for writing to and reading from a file.

* A file descriptor BIO (BIO_s_fd). It is similar to file BIO but works with POSIX file descriptors instead stdio files.

* A socket BIO (BIO_s_socket). It is a wrapper around POSIX sockets. It is used for communicating over network.

* A null BIO (BIO_s_null). It is similar to the /dev/null device in POSIX systems. Writing to this BIO just discards data, reading from it results in EOF (end of file).

* A memory BIO (BIO_s_mem ). It is a loopback BIO in essence. Reading from this type of BIO returns the data that was previously written to the BIO. But the data can also be extracted from (or placed to) internal buffer by calling functions that are specific to this type of BIO (every type of BIO has functions that are specific only for this type of BIO).

* A "bio" BIO (BIO_s_bio). It is a pipe-like BIO. A pair of such BIOs can be created. Data written to one BIO in the pair will be placed for reading to the second BIO in the pair. And vice versa. It is similar to memory BIO, but memory BIO places data to itself and pipe BIO places data to the BIO which it is paired with.


And here is examples of filter BIOs:

* A base64 BIO (BIO_f_base64). BIO_write through this BIO encodes data to base64 format. BIO_read through this BIO decodes data from base64 format.

* A cipher BIO (BIO_f_cipher). It encrypts/decrypts data passed through it. Different cryptographic algorithms can be used.

* A digest calculation BIO (BIO_f_md). It doesn't modify data passed through it. It only calculates digest of data that flows through it, leaving the data itself unchanged. Different digest calculation algorithms can be used. The calculated digest can be retrieved using special functions.

* A buffering BIO (BIO_f_buffer). It also doesn't change data passed through it. Data written to this BIO is buffered and therefore not every write operation to this BIO results in writing the data to the next BIO. As for reading, it is a similar situation. This allows to reduce number of IO operations on BIOs that are located behind buffering IO.

* An SSL BIO (BIO_f_ssl). This type of BIO was described above. It wraps SSL link inside.


BIO methods
-------------------------

.. code-block:: c++


    #include <openssl/bio.h>

    //All other functions return either the amount of data successfully read or written
    //(if the return value is positive)
    //or that no data was successfully read or written if the result is 0 or -1.
    //If the return value is -2 then the operation is not implemented in the specific BIO type.

    int BIO_read_ex(BIO *b, void *data, size_t dlen, size_t *readbytes);
    int BIO_write_ex(BIO *b, const void *data, size_t dlen, size_t *written);

    //BIO_read() attempts to read len bytes from BIO b and places the data in buf.
    int BIO_read(BIO *b, void *data, int dlen);

    int BIO_gets(BIO *b, char *buf, int size);
    int BIO_get_line(BIO *b, char *buf, int size);

    //BIO_write() attempts to write len bytes from buf to BIO b.
    //BIO_write() returns -2 if the "write" operation is not implemented by the BIO or -1 on other errors.
    //Otherwise it returns the number of bytes written. This may be 0 if the BIO b is NULL or dlen <= 0.
    int BIO_write(BIO *b, const void *data, int dlen);

    int BIO_puts(BIO *b, const char *buf);

Example
-------------------------

.. code-block::

	SSL_CTX* mContext;
	SSL *mSsl;
	BIO *mInBio;
	BIO *mOutBio;

    mInBio = BIO_new(BIO_s_mem());
    mOutBio = BIO_new(BIO_s_mem());

    BIO_puts(mOutBio, "Hello World\n");

Reference
==================
* https://stackoverflow.com/questions/51672133/what-are-openssl-bios-how-do-they-work-how-are-bios-used-in-openssl
* https://datatracker.ietf.org/doc/rfc9147/
* https://developer.ibm.com/tutorials/l-openssl/